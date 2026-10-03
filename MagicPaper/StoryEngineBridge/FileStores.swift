import Foundation
import OSLog
import CharacterEngine
import StoryEngine

/// `print` reaches the shared device console verbatim. `Logger` redacts
/// interpolated values as `<private>` outside a debugger by default.
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "FileStores")

/// Where the engine's records live on disk.
///
/// Deliberately not UserDefaults. The app's existing story blob already logs a
/// warning past a megabyte, and an engine story carries an outline, a full
/// narrative draft, prompt snapshots and a usage ledger — several times larger.
/// These are JSON files under Documents, and the app's own store is untouched.
struct StoryEngineStorage {
    static let directoryName = "StoryEngine"

    /// The protection class every record in this app is written with.
    ///
    /// Until D4 all three write points were a bare `write(to:)`, which means
    /// `.completeUntilFirstUserAuthentication` — the file is readable from the
    /// moment the device boots and the passcode has been entered once, and
    /// stays readable while the device sits locked in a bag. What is in these
    /// files is a named child, their story text and the prompts built from
    /// their appearance, so that default is too weak (Principle 10).
    ///
    /// `.completeUnlessOpen` rather than `.complete`: story generation and
    /// image download continue in the background after the screen locks, and
    /// `.complete` would fail those writes outright. `.completeUnlessOpen`
    /// keeps an already-open file usable across a lock and still refuses a
    /// cold open while locked, which is the property that matters here.
    static let fileProtection: FileProtectionType = .completeUnlessOpen

    /// Why a store could not be reached or read.
    ///
    /// These used to be silences. `save` returned successfully without writing
    /// anything when Documents was unreachable, and `load` returned `nil` for a
    /// file that existed but would not decode — which the character store reads
    /// as "this child has no character yet" and answers by minting a fresh
    /// `CharacterVersionID`, permanently shifting the child's visual identity.
    enum Failure: Error, CustomStringConvertible {
        case documentsUnavailable(subdirectory: String)
        case unreadable(url: URL, underlying: Error)
        case undecodable(url: URL, underlying: Error)

        var description: String {
            switch self {
            case .documentsUnavailable(let subdirectory):
                return "Documents dizinine erişilemedi, '\(subdirectory)' açılamadı."
            case .unreadable(let url, let underlying):
                return "'\(url.lastPathComponent)' okunamadı: \(underlying)"
            case .undecodable(let url, let underlying):
                return "'\(url.lastPathComponent)' çözümlenemedi: \(underlying)"
            }
        }
    }

    static func directory(_ subdirectory: String) -> URL? {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let url = documents
            .appendingPathComponent(directoryName, isDirectory: true)
            .appendingPathComponent(subdirectory, isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: fileProtection]
            )
        }
        return url
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.withoutEscapingSlashes]
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Writes `data` to `url` with this app's protection class.
    ///
    /// `write(to:options:)` takes a protection option, but only a coarse one,
    /// and it is silently ignored on a replace. Setting the attribute after the
    /// atomic write is the only form that holds for an existing file.
    static func write(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: [.atomic])
        try? FileManager.default.setAttributes(
            [.protectionKey: fileProtection],
            ofItemAtPath: url.path
        )
    }
}

/// One JSON file per record, so a corrupt story cannot take the library with it.
actor FileBackedStore<Value: Codable & Sendable> {
    private let directory: URL?
    private let subdirectory: String
    private let encoder = StoryEngineStorage.makeEncoder()
    private let decoder = StoryEngineStorage.makeDecoder()

    /// What `loadAll` had to skip on its last run.
    ///
    /// `loadAll` still cannot throw — one damaged story must not hide every
    /// other book a child owns — but it no longer drops the file without a
    /// word. The caller can ask, and a diagnostic is logged either way.
    private(set) var lastLoadFailures: [StoryEngineStorage.Failure] = []

    init(subdirectory: String) {
        self.subdirectory = subdirectory
        self.directory = StoryEngineStorage.directory(subdirectory)
    }

    /// The record, or `nil` **only when no file exists**.
    ///
    /// Previously `try?` twice over: a file that was present but unreadable
    /// came back as `nil`, indistinguishable from a record that was never
    /// written. For `FileCharacterStore` that difference is the child's face.
    func load(id: UUID) throws -> Value? {
        guard let url = directory?.appendingPathComponent("\(id.uuidString).json") else {
            throw StoryEngineStorage.Failure.documentsUnavailable(subdirectory: subdirectory)
        }
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw StoryEngineStorage.Failure.unreadable(url: url, underlying: error)
        }
        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            throw StoryEngineStorage.Failure.undecodable(url: url, underlying: error)
        }
    }

    /// Writes the record, or throws.
    ///
    /// The `guard … else { return }` this replaces meant that when Documents
    /// was unreachable the call succeeded and wrote nothing. Every caller of
    /// this method is already `throws`; none of them were being told.
    func save(_ value: Value, id: UUID) throws {
        guard let url = directory?.appendingPathComponent("\(id.uuidString).json") else {
            throw StoryEngineStorage.Failure.documentsUnavailable(subdirectory: subdirectory)
        }
        try StoryEngineStorage.write(try encoder.encode(value), to: url)
    }

    func delete(id: UUID) {
        guard let url = directory?.appendingPathComponent("\(id.uuidString).json") else { return }
        try? FileManager.default.removeItem(at: url)
    }

    func loadAll() -> [Value] {
        loadAllReportingFailures().values
    }

    /// `loadAll`, with the skipped files named.
    func loadAllReportingFailures() -> (values: [Value], failures: [StoryEngineStorage.Failure]) {
        guard let directory,
              let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        else {
            let failure = StoryEngineStorage.Failure.documentsUnavailable(subdirectory: subdirectory)
            lastLoadFailures = [failure]
            logger.error("🛑 FileBackedStore<\(Value.self)>: \(failure)")
            return ([], [failure])
        }

        var values: [Value] = []
        var failures: [StoryEngineStorage.Failure] = []

        for url in files where url.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: url)
                do {
                    values.append(try decoder.decode(Value.self, from: data))
                } catch {
                    failures.append(.undecodable(url: url, underlying: error))
                }
            } catch {
                failures.append(.unreadable(url: url, underlying: error))
            }
        }

        lastLoadFailures = failures
        for failure in failures {
            // Not an `assertionFailure`: a damaged file is a production
            // condition, not a programmer error, and crashing the debug build
            // on it would make the damaged state impossible to inspect.
            logger.error("🛑 FileBackedStore<\(Value.self)> atladı: \(failure)")
        }
        return (values, failures)
    }
}

/// `StoryRepository` backed by files under `Documents/StoryEngine/Stories`.
///
/// `Story` is qualified throughout: the app module declares its own `Story`,
/// and unqualified lookup inside the app prefers it over the engine's.
struct FileStoryRepository: StoryRepository {
    private let store: FileBackedStore<StoryEngine.Story>

    init() { self.store = FileBackedStore(subdirectory: "Stories") }

    func story(id: UUID) async throws -> StoryEngine.Story? { try await store.load(id: id) }
    func save(_ story: StoryEngine.Story) async throws { try await store.save(story, id: story.id) }
    func delete(id: UUID) async throws { await store.delete(id: id) }

    func allStories() async throws -> [StoryEngine.Story] {
        await store.loadAll().sorted { $0.createdAt > $1.createdAt }
    }
}

/// `JobStore` backed by files, so an interrupted generation survives a relaunch.
struct FileJobStore: JobStore {
    private let jobs: FileBackedStore<StoryGenerationJob>
    private let requests: FileBackedStore<StoryRequest>

    init() {
        self.jobs = FileBackedStore(subdirectory: "Jobs")
        self.requests = FileBackedStore(subdirectory: "Requests")
    }

    func job(id: UUID) async throws -> StoryGenerationJob? { try await jobs.load(id: id) }
    func save(_ job: StoryGenerationJob) async throws { try await jobs.save(job, id: job.id) }
    func request(id: UUID) async throws -> StoryRequest? { try await requests.load(id: id) }
    func saveRequest(_ request: StoryRequest) async throws { try await requests.save(request, id: request.id) }

    func resumableJobs() async throws -> [StoryGenerationJob] {
        await jobs.loadAll()
            .filter { $0.state.isResumable }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func delete(jobID: UUID) async throws { await jobs.delete(id: jobID) }

    func deleteRequest(id: UUID) async throws { await requests.delete(id: id) }
}

/// Character profiles on disk, keyed by the app's own profile id.
///
/// This is the store the `nil`-on-corruption silence mattered most for: a
/// missing profile is answered with a newly built `CharacterVersion`, and
/// `CharacterVersionID` is a fresh UUID, so a single unreadable file used to
/// move the child's visual identity permanently. `load` now throws instead.
struct FileCharacterStore: CharacterStore {
    private let store: FileBackedStore<CharacterProfile>

    init() { self.store = FileBackedStore(subdirectory: "Characters") }

    func profile(id: CharacterID) async throws -> CharacterProfile? {
        try await store.load(id: id.rawValue)
    }

    func save(_ profile: CharacterProfile) async throws {
        try await store.save(profile, id: profile.id.rawValue)
    }

    func allProfiles(ownedBy ownerProfileID: UUID) async throws -> [CharacterProfile] {
        await store.loadAll()
            .filter { $0.ownerProfileID == ownerProfileID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func delete(id: CharacterID) async throws { await store.delete(id: id.rawValue) }
}
