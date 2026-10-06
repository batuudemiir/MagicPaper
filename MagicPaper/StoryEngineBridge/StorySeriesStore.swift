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
    func series(for childID: UUID) -> [StorySeries] { load(childID).values }

    /// When the child's file last changed; nil when there is none. Lets a
    /// reader keep what it decoded until the file changes.
    func modificationDate(for childID: UUID) -> Date? {
        guard let url = url(for: childID) else { return nil }
        return (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
    }

    /// The file's series, and whether all of it could be read. A file that
    /// could not be read whole is never written over (`save`).
    private func load(_ childID: UUID) -> (values: [StorySeries], intact: Bool) {
        guard let url = url(for: childID), FileManager.default.fileExists(atPath: url.path) else {
            return ([], true)
        }
        do {
            let file = try StoryEngineStorage.makeDecoder()
                .decode(File.self, from: Data(contentsOf: url))
            let values = file.series.compactMap(\.value)
            let skipped = file.series.count - values.count
            if skipped > 0 {
                logger.notice("Seri: \(skipped, privacy: .public) kayıt okunamadı, atlandı")
            }
            return (values
                .filter { $0.childID == childID }
                .sorted { $0.createdAt < $1.createdAt }, skipped == 0)
        } catch {
            logger.error("🛑 Seri dosyası okunamadı")
            return ([], false)
        }
    }

    /// The child's open series. At most one by the product rule; if a file
    /// ever held two, the oldest is the one that continues.
    func openSeries(for childID: UUID) -> StorySeries? {
        series(for: childID).first(where: \.isOpen)
    }

    /// Adds or replaces the series with the same id.
    func save(_ series: StorySeries) throws {
        let loaded = load(series.childID)
        // What could not be read is set aside, not overwritten: a newer
        // version's record or a damaged file must not vanish because the next
        // "Devam ettir" rewrote the list without it.
        if !loaded.intact { setAside(series.childID) }
        var list = loaded.values
        if let index = list.firstIndex(where: { $0.id == series.id }) {
            list[index] = series
        } else {
            list.append(series)
        }
        try write(list, for: series.childID)
    }

    /// When a profile is deleted: every series of that child, set-aside
    /// copies included.
    func delete(for childID: UUID) {
        guard let directory = StoryEngineStorage.directory(subdirectory) else { return }
        let prefix = childID.uuidString
        let files = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        for name in files where name.hasPrefix(prefix) {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
        }
    }

    /// Moves an unreadable file out of the way, beside it.
    private func setAside(_ childID: UUID) {
        guard let url = url(for: childID) else { return }
        let aside = url.deletingLastPathComponent()
            .appendingPathComponent("\(childID.uuidString).unreadable-\(Int(Date().timeIntervalSince1970)).json")
        if (try? FileManager.default.moveItem(at: url, to: aside)) != nil {
            logger.notice("Seri: okunamayan dosya kenara alındı")
        }
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
