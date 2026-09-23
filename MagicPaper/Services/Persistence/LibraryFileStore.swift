import Foundation

/// The app's own domain records on disk, one JSON file per record.
///
/// Separate from `StoryEngineBridge/FileStores.swift` on purpose: that store
/// holds `StoryEngine.Story`, the engine's record, and this one holds the app's
/// `Story`, the thing a child's library is actually made of. They are different
/// types with different lifetimes and the bridge between them is not live yet
/// (Wave0 §4). Merging them now would mean inventing that bridge inside a
/// migration, which is the one place it must not be invented.
///
/// Rooted at an injectable URL so the migration can be tested against a
/// temporary directory rather than the simulator's Documents.
final class LibraryFileStore {

    enum Failure: Error, CustomStringConvertible {
        case rootUnavailable
        case directoryNotCreated(URL, Error)
        case notWritten(URL, Error)
        case unreadable(URL, Error)
        case undecodable(URL, Error)

        var description: String {
            switch self {
            case .rootUnavailable:
                return "Documents dizinine erişilemedi."
            case .directoryNotCreated(let url, let error):
                return "'\(url.lastPathComponent)' dizini kurulamadı: \(error)"
            case .notWritten(let url, let error):
                return "'\(url.lastPathComponent)' yazılamadı: \(error)"
            case .unreadable(let url, let error):
                return "'\(url.lastPathComponent)' okunamadı: \(error)"
            case .undecodable(let url, let error):
                return "'\(url.lastPathComponent)' çözümlenemedi: \(error)"
            }
        }
    }

    /// A set of story ids kept beside the library: favourites, parent approval.
    ///
    /// Versioned from the first write. The legacy form was a bare
    /// `[String]` under a UserDefaults key with no room to say what it was, and
    /// the next thing either list needs — per-profile scoping (Streak H2) — has
    /// nowhere to go without a version to migrate from.
    struct IDSet: Codable, Equatable {
        var version: Int = 1
        var ids: [String]

        init(ids: Set<String>) {
            self.ids = ids.sorted()
        }
    }

    enum Kind: String {
        case stories = "Stories"
        case flags = "Flags"
        case quarantine = "Quarantine"
    }

    /// Named id-set files under `Flags`.
    enum FlagList: String, CaseIterable {
        case favorites
        case approvals

        /// The UserDefaults key this list is migrated from.
        var legacyKey: String {
            switch self {
            case .favorites: return "mp_favoriteStoryIDs"
            case .approvals: return "mp_approvedStoryIDs"
            }
        }
    }

    static let rootDirectoryName = "MPLibrary"

    let root: URL

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager = FileManager.default

    /// Digests of what this process has already written, so a page turn does
    /// not rewrite the whole shelf.
    ///
    /// `saveStories()` runs on every page turn and used to re-encode one blob;
    /// naively replacing that with "write every story file" would turn one
    /// write into one per book. In-process only — `hashValue` is seeded per
    /// launch — so the first sync after a launch writes every record once and
    /// every sync after that writes only what changed.
    private var writtenDigests: [UUID: Int] = [:]

    /// The default location: `Documents/MPLibrary`.
    static func documentsRoot() -> URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(rootDirectoryName, isDirectory: true)
    }

    init(root: URL) throws {
        self.root = root

        // Dates deliberately keep Foundation's default strategy rather than
        // ISO-8601. The legacy blob was written with a plain `JSONEncoder`, so
        // its dates are full-precision reference-date doubles; ISO-8601 rounds
        // to the second. A migration whose copy is a second off from its source
        // is not a copy, and `lastReadAt` is what orders the home screen's
        // "where you left off" card.
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        self.encoder = encoder

        self.decoder = JSONDecoder()

        for kind in [Kind.stories, .flags, .quarantine] {
            try createDirectory(directory(kind))
        }
    }

    // MARK: - Layout

    func directory(_ kind: Kind) -> URL {
        root.appendingPathComponent(kind.rawValue, isDirectory: true)
    }

    private func storyURL(_ id: UUID) -> URL {
        directory(.stories).appendingPathComponent("\(id.uuidString).json")
    }

    private func flagURL(_ list: FlagList) -> URL {
        directory(.flags).appendingPathComponent("\(list.rawValue).json")
    }

    private func createDirectory(_ url: URL) throws {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: StoryEngineStorage.fileProtection]
            )
        } catch {
            throw Failure.directoryNotCreated(url, error)
        }
    }

    private func write(_ data: Data, to url: URL) throws {
        do {
            try data.write(to: url, options: [.atomic])
        } catch {
            throw Failure.notWritten(url, error)
        }
        // Set after the write: an atomic replace installs a new inode and
        // drops whatever protection the previous file carried.
        try? fileManager.setAttributes(
            [.protectionKey: StoryEngineStorage.fileProtection],
            ofItemAtPath: url.path
        )
    }

    // MARK: - Stories

    /// Writes the story unless an identical one is already on disk.
    /// Returns whether anything was written.
    @discardableResult
    func writeStory(_ story: Story) throws -> Bool {
        let data = try encoder.encode(story)
        let digest = data.hashValue
        if writtenDigests[story.id] == digest, fileManager.fileExists(atPath: storyURL(story.id).path) {
            return false
        }
        try write(data, to: storyURL(story.id))
        writtenDigests[story.id] = digest
        return true
    }

    /// The story, or `nil` **only when no file exists**.
    ///
    /// A file that is present but damaged throws. The distinction is the whole
    /// point of the exercise: `nil` means "this book was never written", and
    /// anything that answers `nil` for a damaged file invites the caller to
    /// write a replacement over it.
    func readStory(id: UUID) throws -> Story? {
        let url = storyURL(id)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data: Data
        do { data = try Data(contentsOf: url) }
        catch { throw Failure.unreadable(url, error) }
        do { return try decoder.decode(Story.self, from: data) }
        catch { throw Failure.undecodable(url, error) }
    }

    /// Every story on disk, plus the files that could not be read.
    ///
    /// Failures are returned rather than thrown: one damaged book must not hide
    /// the rest of a child's shelf. They are returned rather than dropped
    /// because a migration that cannot see them would report success over them.
    func readAllStories() -> (stories: [Story], failures: [Failure]) {
        let urls = (try? fileManager.contentsOfDirectory(
            at: directory(.stories),
            includingPropertiesForKeys: nil
        )) ?? []

        var stories: [Story] = []
        var failures: [Failure] = []

        for url in urls where url.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: url)
                do { stories.append(try decoder.decode(Story.self, from: data)) }
                catch { failures.append(.undecodable(url, error)) }
            } catch {
                failures.append(.unreadable(url, error))
            }
        }
        return (stories.sorted { $0.createdAt > $1.createdAt }, failures)
    }

    func storyIDsOnDisk() -> Set<UUID> {
        let urls = (try? fileManager.contentsOfDirectory(
            at: directory(.stories),
            includingPropertiesForKeys: nil
        )) ?? []
        return Set(urls
            .filter { $0.pathExtension == "json" }
            .compactMap { UUID(uuidString: $0.deletingPathExtension().lastPathComponent) })
    }

    func deleteStory(id: UUID) {
        try? fileManager.removeItem(at: storyURL(id))
        writtenDigests[id] = nil
    }

    // MARK: - Flag lists

    func writeFlagList(_ ids: Set<String>, as list: FlagList) throws {
        try write(try encoder.encode(IDSet(ids: ids)), to: flagURL(list))
    }

    /// The list, or `nil` when it was never written. Throws on a damaged file,
    /// for the same reason `readStory` does.
    func readFlagList(_ list: FlagList) throws -> Set<String>? {
        let url = flagURL(list)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data: Data
        do { data = try Data(contentsOf: url) }
        catch { throw Failure.unreadable(url, error) }
        do { return Set(try decoder.decode(IDSet.self, from: data).ids) }
        catch { throw Failure.undecodable(url, error) }
    }

    // MARK: - Quarantine

    /// Moves a blob out of harm's way and returns where it went.
    ///
    /// Used for data that is about to be removed from its old home and that
    /// nothing can decode — the case the app previously handled by deleting it.
    @discardableResult
    func quarantine(_ data: Data, named name: String) throws -> URL {
        let url = directory(.quarantine).appendingPathComponent(name)
        try write(data, to: url)
        return url
    }

    /// Keeps the newest `limit` quarantined blobs and removes the rest.
    ///
    /// The `stories.undecodable.*` keys were the counter-example: unbounded,
    /// never read, never cleaned, sitting inside the store whose size overflow
    /// caused the problem in the first place.
    func pruneQuarantine(keeping limit: Int) {
        let urls = (try? fileManager.contentsOfDirectory(
            at: directory(.quarantine),
            includingPropertiesForKeys: [.contentModificationDateKey]
        )) ?? []
        guard urls.count > limit else { return }
        let sorted = urls.sorted {
            let a = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let b = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return a > b
        }
        for url in sorted.dropFirst(limit) {
            try? fileManager.removeItem(at: url)
        }
    }

    func quarantinedFileNames() -> [String] {
        let urls = (try? fileManager.contentsOfDirectory(at: directory(.quarantine), includingPropertiesForKeys: nil)) ?? []
        return urls.map(\.lastPathComponent).sorted()
    }

    // MARK: - Erasure

    /// Removes everything this store holds.
    ///
    /// The counterpart of Settings' "delete all data". Until that screen calls
    /// it (it belongs to another agent this wave — see
    /// `docs/MagicPaper_Persistence_Migration.md` §6), erasure reaches these
    /// files through `LibraryMigration.reconcile`, which makes disk match the
    /// legacy store on every launch, deletions included.
    func eraseEverything() throws {
        writtenDigests.removeAll()
        if fileManager.fileExists(atPath: root.path) {
            try fileManager.removeItem(at: root)
        }
        for kind in [Kind.stories, .flags, .quarantine] {
            try createDirectory(directory(kind))
        }
    }
}
