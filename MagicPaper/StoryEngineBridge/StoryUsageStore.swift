import Foundation
import OSLog
import StoryEngine

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "StoryUsageStore")

/// How a child has read each of their stories (FAZ 14). Never leaves the device.
///
/// `Documents/StoryEngine/Usage/<childUUID>.json`: per story, how many times
/// it was finished, how far it got and whether the last reading stopped early.
/// It is what the engine learns from (`UsageLearner`): the next story leans
/// toward what this child re-reads and away from what they leave.
///
/// Replaces the `read_history_<UUID>` key, which was written and never read.
struct StoryUsageStore: Sendable {
    static let defaultSubdirectory = "Usage"
    /// How many of the child's latest stories teach the engine. Old habits
    /// fade: a child who loved foxes at four need not get them at six.
    static let learningWindow = 30

    /// Pages that must have been seen before leaving counts as leaving: a
    /// third of the story, rounded up (`furthestPage` counts from 0).
    static func leavingThreshold(pageCount: Int) -> Int {
        max(1, (pageCount + 2) / 3)
    }

    struct Stats: Codable, Equatable, Sendable {
        var completions = 0
        var sessions = 0
        var furthestPage = 0
        var lastSessionFinished = false
        /// The last session was stopped by today's reading time, not by the
        /// child: the story was not left, the day ran out.
        var lastSessionInterrupted = false

        /// Left before the end, and never finished. Whether that counts
        /// against the story is the mode's call (`ModeSuccessRule`).
        var abandoned: Bool {
            sessions > 0 && completions == 0 && !lastSessionFinished && !lastSessionInterrupted
        }

        /// Abandoned, and far enough in to mean it: a child who shut the book
        /// in its first third only glanced, and a glance is not a verdict.
        func abandoned(pageCount: Int) -> Bool {
            abandoned && furthestPage + 1 >= StoryUsageStore.leavingThreshold(pageCount: pageCount)
        }

        init() {}

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            completions = try c.decodeIfPresent(Int.self, forKey: .completions) ?? 0
            sessions = try c.decodeIfPresent(Int.self, forKey: .sessions) ?? 0
            furthestPage = try c.decodeIfPresent(Int.self, forKey: .furthestPage) ?? 0
            lastSessionFinished = try c.decodeIfPresent(Bool.self, forKey: .lastSessionFinished) ?? false
            lastSessionInterrupted = try c.decodeIfPresent(Bool.self, forKey: .lastSessionInterrupted) ?? false
        }
    }

    private struct File: Codable {
        var schemaVersion: Int = 1
        var stories: [String: Stats]
    }

    private let subdirectory: String

    init(subdirectory: String = StoryUsageStore.defaultSubdirectory) {
        self.subdirectory = subdirectory
    }

    private func url(for childID: UUID) -> URL? {
        StoryEngineStorage.directory(subdirectory)?.appendingPathComponent("\(childID.uuidString).json")
    }

    func stats(for childID: UUID) -> [UUID: Stats] {
        guard let url = url(for: childID), FileManager.default.fileExists(atPath: url.path) else { return [:] }
        do {
            let file = try StoryEngineStorage.makeDecoder().decode(File.self, from: Data(contentsOf: url))
            return Dictionary(uniqueKeysWithValues: file.stories.compactMap { key, value in
                UUID(uuidString: key).map { ($0, value) }
            })
        } catch {
            // Losing what was learned only makes the next story less tailored.
            logger.error("🛑 Kullanım dosyası okunamadı")
            return [:]
        }
    }

    func stats(of storyID: UUID, for childID: UUID) -> Stats? { stats(for: childID)[storyID] }

    /// One reading session of one story ended.
    func recordSession(
        storyID: UUID, childID: UUID, completions: Int, furthestPage: Int, interrupted: Bool = false
    ) {
        var all = stats(for: childID)
        var stats = all[storyID] ?? Stats()
        stats.sessions += 1
        stats.completions += completions
        stats.furthestPage = max(stats.furthestPage, furthestPage)
        stats.lastSessionFinished = completions > 0
        stats.lastSessionInterrupted = interrupted && completions == 0
        all[storyID] = stats
        write(all, for: childID)
    }

    /// What the engine learns from: the child's latest stories that were read,
    /// as ids and outcomes. Stories without an origin say nothing.
    func usage(of stories: [Story], for childID: UUID) -> [StoryUsage] {
        let stats = stats(for: childID)
        guard !stats.isEmpty else { return [] }
        return stories
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(Self.learningWindow)
            .compactMap { story in
                guard let origin = story.origin, let read = stats[story.id], read.sessions > 0 else { return nil }
                return StoryUsage(
                    blueprintID: ContentID(origin.blueprintID),
                    companionID: ContentID(origin.companionID),
                    mode: origin.mode,
                    completions: read.completions,
                    abandoned: read.abandoned(pageCount: story.pages.count))
            }
    }

    /// When a profile is deleted.
    func delete(for childID: UUID) {
        guard let url = url(for: childID) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// "Tüm verileri sil": the whole folder.
    func eraseAll() {
        guard let directory = StoryEngineStorage.directory(subdirectory) else { return }
        try? FileManager.default.removeItem(at: directory)
    }

    static func eraseAll(subdirectory: String = StoryUsageStore.defaultSubdirectory) {
        StoryUsageStore(subdirectory: subdirectory).eraseAll()
    }

    private func write(_ all: [UUID: Stats], for childID: UUID) {
        guard let url = url(for: childID) else { return }
        let file = File(stories: Dictionary(uniqueKeysWithValues: all.map { ($0.key.uuidString, $0.value) }))
        do {
            try StoryEngineStorage.write(StoryEngineStorage.makeEncoder().encode(file), to: url)
        } catch {
            logger.error("🛑 Kullanım dosyası yazılamadı")
        }
    }
}
