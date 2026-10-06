import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "StorySeriesStore")

/// A child's series, on the device only (FAZ 13).
///
/// `Documents/StoryEngine/Series/<childUUID>.json`: one file per child, open and
/// finished series together. Same shape as `FamilyCharacterStore`: atomic
/// write, the app's file protection, lossy read (one unreadable series does not
/// take the others with it). The log carries counts and events only — never a
/// name, a title, an id or a path.
///
/// FAZ 16 syncs this file with the account; ids and dates are stable for that.
struct StorySeriesStore: Sendable {
    static let defaultSubdirectory = "Series"

    enum Failure: Error, Equatable {
        case documentsUnavailable
        case writeFailed
    }

    private let subdirectory: String

    init(subdirectory: String = StorySeriesStore.defaultSubdirectory) {
        self.subdirectory = subdirectory
    }

    private struct File: Codable {
        var schemaVersion: Int = 1
        var series: [Lossy]

        struct Lossy: Codable {
            let value: StorySeries?
            init(_ value: StorySeries) { self.value = value }
            init(from decoder: Decoder) throws { value = try? StorySeries(from: decoder) }
            func encode(to encoder: Encoder) throws { try value?.encode(to: encoder) }
        }
    }

    private func url(for childID: UUID) -> URL? {
        StoryEngineStorage.directory(subdirectory)?
            .appendingPathComponent("\(childID.uuidString).json")
    }

    /// The child's series, oldest first.
    func series(for childID: UUID) -> [StorySeries] {
        guard let url = url(for: childID), FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        do {
            let file = try StoryEngineStorage.makeDecoder()
                .decode(File.self, from: Data(contentsOf: url))
            let values = file.series.compactMap(\.value)
            let skipped = file.series.count - values.count
            if skipped > 0 {
                logger.notice("Seri: \(skipped, privacy: .public) kayıt okunamadı, atlandı")
            }
            return values
                .filter { $0.childID == childID }
                .sorted { $0.createdAt < $1.createdAt }
        } catch {
            logger.error("🛑 Seri dosyası okunamadı")
            return []
        }
    }

    /// The child's open series. At most one by the product rule; if a file
    /// ever held two, the oldest is the one that continues.
    func openSeries(for childID: UUID) -> StorySeries? {
        series(for: childID).first(where: \.isOpen)
    }

    /// Adds or replaces the series with the same id.
    func save(_ series: StorySeries) throws {
        var list = self.series(for: series.childID)
        if let index = list.firstIndex(where: { $0.id == series.id }) {
            list[index] = series
        } else {
            list.append(series)
        }
        try write(list, for: series.childID)
    }

    /// When a profile is deleted: every series of that child.
    func delete(for childID: UUID) {
        guard let url = url(for: childID) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// "Tüm verileri sil": the whole folder.
    func eraseAll() {
        guard let url = StoryEngineStorage.directory(subdirectory) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    static func eraseAll(subdirectory: String = StorySeriesStore.defaultSubdirectory) {
        StorySeriesStore(subdirectory: subdirectory).eraseAll()
    }

    private func write(_ list: [StorySeries], for childID: UUID) throws {
        guard let url = url(for: childID) else { throw Failure.documentsUnavailable }
        do {
            let data = try StoryEngineStorage.makeEncoder()
                .encode(File(series: list.map(File.Lossy.init)))
            try StoryEngineStorage.write(data, to: url)
        } catch {
            logger.error("🛑 Seri kaydedilemedi")
            throw Failure.writeFailed
        }
    }
}
