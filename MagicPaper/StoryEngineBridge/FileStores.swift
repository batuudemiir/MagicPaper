import Foundation
import CharacterEngine
import StoryEngine

/// Where the engine's records live on disk.
///
/// Deliberately not UserDefaults. The app's existing story blob already logs a
/// warning past a megabyte, and an engine story carries an outline, a full
/// narrative draft, prompt snapshots and a usage ledger — several times larger.
/// These are JSON files under Documents, and the app's own store is untouched.
struct StoryEngineStorage {
    static let directoryName = "StoryEngine"

    static func directory(_ subdirectory: String) -> URL? {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let url = documents
            .appendingPathComponent(directoryName, isDirectory: true)
            .appendingPathComponent(subdirectory, isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
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
}

/// One JSON file per record, so a corrupt story cannot take the library with it.
actor FileBackedStore<Value: Codable & Sendable> {
    private let directory: URL?
    private let encoder = StoryEngineStorage.makeEncoder()
    private let decoder = StoryEngineStorage.makeDecoder()

    init(subdirectory: String) {
        self.directory = StoryEngineStorage.directory(subdirectory)
    }

    func load(id: UUID) -> Value? {
        guard let url = directory?.appendingPathComponent("\(id.uuidString).json") else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(Value.self, from: data)
    }

    func save(_ value: Value, id: UUID) throws {
        guard let url = directory?.appendingPathComponent("\(id.uuidString).json") else { return }
        try encoder.encode(value).write(to: url, options: .atomic)
    }

    func delete(id: UUID) {
        guard let url = directory?.appendingPathComponent("\(id.uuidString).json") else { return }
        try? FileManager.default.removeItem(at: url)
    }

    func loadAll() -> [Value] {
        guard let directory,
              let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        else { return [] }
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { try? Data(contentsOf: $0) }
            // A file that will not decode is skipped rather than thrown: one
            // damaged story should not hide every other book a child owns.
            .compactMap { try? decoder.decode(Value.self, from: $0) }
    }
}

/// `StoryRepository` backed by files under `Documents/StoryEngine/Stories`.
///
/// `Story` is qualified throughout: the app module declares its own `Story`,
/// and unqualified lookup inside the app prefers it over the engine's.
struct FileStoryRepository: StoryRepository {
    private let store: FileBackedStore<StoryEngine.Story>

    init() { self.store = FileBackedStore(subdirectory: "Stories") }

    func story(id: UUID) async throws -> StoryEngine.Story? { await store.load(id: id) }
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

    func job(id: UUID) async throws -> StoryGenerationJob? { await jobs.load(id: id) }
    func save(_ job: StoryGenerationJob) async throws { try await jobs.save(job, id: job.id) }
    func request(id: UUID) async throws -> StoryRequest? { await requests.load(id: id) }
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
struct FileCharacterStore: CharacterStore {
    private let store: FileBackedStore<CharacterProfile>

    init() { self.store = FileBackedStore(subdirectory: "Characters") }

    func profile(id: CharacterID) async throws -> CharacterProfile? {
        await store.load(id: id.rawValue)
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
