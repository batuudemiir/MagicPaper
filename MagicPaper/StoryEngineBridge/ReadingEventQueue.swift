import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "ReadingEventQueue")

/// Reading events waiting to be sent (FAZ 14). Sending is FAZ 16's.
///
/// `Documents/StoryEngine/ReadingEvents/queue.json`, one file for the device.
/// Each entry keeps the child's local profile id beside the event so that
/// deleting a profile takes its events with it; that id is **never** part of
/// what leaves the device (`outbound`). Bounded: when full, the oldest go.
///
/// Same file habits as `StorySeriesStore`: atomic write, the app's file
/// protection, lossy read, an unreadable file set aside rather than written
/// over. The log carries counts only.
struct ReadingEventQueue: Sendable {
    static let defaultSubdirectory = "ReadingEvents"
    static let capacity = 500

    private let subdirectory: String

    init(subdirectory: String = ReadingEventQueue.defaultSubdirectory) {
        self.subdirectory = subdirectory
    }

    private struct Entry: Codable {
        let childID: UUID
        let event: ReadingEvent
    }

    private struct File: Codable {
        var schemaVersion: Int = 1
        var entries: [Lossy]

        struct Lossy: Codable {
            let value: Entry?
            init(_ value: Entry) { self.value = value }
            init(from decoder: Decoder) throws { value = try? Entry(from: decoder) }
            func encode(to encoder: Encoder) throws { try value?.encode(to: encoder) }
        }
    }

    private var url: URL? {
        StoryEngineStorage.directory(subdirectory)?.appendingPathComponent("queue.json")
    }

    /// What FAZ 16 sends: the events alone, oldest first.
    func outbound() -> [ReadingEvent] { load().entries.map(\.event) }

    var count: Int { load().entries.count }

    func append(_ event: ReadingEvent, for childID: UUID) {
        let loaded = load()
        if !loaded.intact { setAside() }
        let entries = (loaded.entries + [Entry(childID: childID, event: event)]).suffix(Self.capacity)
        write(Array(entries))
    }

    /// When a profile is deleted: its events, nobody else's. A set-aside
    /// unreadable file cannot be sorted by child, so it goes too.
    func delete(for childID: UUID) {
        removeSetAsideFiles()
        let loaded = load()
        guard loaded.intact else { return eraseAll() }
        let kept = loaded.entries.filter { $0.childID != childID }
        guard kept.count != loaded.entries.count else { return }
        write(kept)
    }

    /// "Tüm verileri sil", and the parent turning sharing off.
    func eraseAll() {
        guard let directory = StoryEngineStorage.directory(subdirectory) else { return }
        try? FileManager.default.removeItem(at: directory)
    }

    static func eraseAll(subdirectory: String = ReadingEventQueue.defaultSubdirectory) {
        ReadingEventQueue(subdirectory: subdirectory).eraseAll()
    }

    private func load() -> (entries: [Entry], intact: Bool) {
        guard let url, FileManager.default.fileExists(atPath: url.path) else { return ([], true) }
        do {
            let file = try StoryEngineStorage.makeDecoder().decode(File.self, from: Data(contentsOf: url))
            let entries = file.entries.compactMap(\.value)
            let skipped = file.entries.count - entries.count
            if skipped > 0 {
                logger.notice("Okuma olayı: \(skipped, privacy: .public) kayıt okunamadı, atlandı")
            }
            return (entries, true)
        } catch {
            logger.error("🛑 Okuma olayı kuyruğu okunamadı")
            return ([], false)
        }
    }

    private func removeSetAsideFiles() {
        guard let directory = StoryEngineStorage.directory(subdirectory) else { return }
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        for name in names where name.hasPrefix("queue.unreadable-") {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
        }
    }

    private func setAside() {
        guard let url else { return }
        let aside = url.deletingLastPathComponent()
            .appendingPathComponent("queue.unreadable-\(Int(Date().timeIntervalSince1970)).json")
        try? FileManager.default.moveItem(at: url, to: aside)
    }

    private func write(_ entries: [Entry]) {
        guard let url else { return }
        do {
            let data = try StoryEngineStorage.makeEncoder()
                .encode(File(entries: entries.map(File.Lossy.init)))
            try StoryEngineStorage.write(data, to: url)
        } catch {
            // A lost event costs one data point; reading goes on regardless.
            logger.error("🛑 Okuma olayı yazılamadı")
        }
    }
}
