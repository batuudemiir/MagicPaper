import Foundation
import CharacterEngine
import StoryEngine

/// Where the engine's records live on disk.
///
/// Deliberately not UserDefaults. The app's existing story blob already logs a
/// warning past a megabyte, and an engine story carries an outline, a full
/// narrative draft, prompt snapshots and a usage ledger — several times larger.
/// These are JSON files under Documents, and the app's own store is untouched.
public struct StoryEngineStorage {
    public static let directoryName = "StoryEngine"

    public static func directory(_ subdirectory: String) -> URL? {
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
public actor FileBackedStore<Value: Codable & Sendable> {
    private let directory: URL?
    private let encoder = StoryEngineStorage.makeEncoder()
    private let decoder = StoryEngineStorage.makeDecoder()

    public init(subdirectory: String) {
        self.directory = StoryEngineStorage.directory(subdirectory)
    }

    public func load(id: UUID) -> Value? {
        guard let url = directory?.appendingPathComponent("\(id.uuidString).json") else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(Value.self, from: data)
    }

    public func save(_ value: Value, id: UUID) throws {
        guard let url = directory?.appendingPathComponent("\(id.uuidString).json") else { return }
        try encoder.encode(value).write(to: url, options: .atomic)
    }

    public func delete(id: UUID) {
        guard let url = directory?.appendingPathComponent("\(id.uuidString).json") else { return }
        try? FileManager.default.removeItem(at: url)
    }

    public func loadAll() -> [Value] {
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
public struct FileStoryRepository: StoryRepository {
    private let store: FileBackedStore<Story>

    public init() { self.store = FileBackedStore(subdirectory: "Stories") }

    public func story(id: UUID) async throws -> Story? { await store.load(id: id) }
    public func save(_ story: Story) async throws { try await store.save(story, id: story.id) }
    public func delete(id: UUID) async throws { await store.delete(id: id) }

    public func allStories() async throws -> [Story] {
        await store.loadAll().sorted { $0.createdAt > $1.createdAt }
    }
}

/// `JobStore` backed by files, so an interrupted generation survives a relaunch.
public struct FileJobStore: JobStore {
    private let jobs: FileBackedStore<StoryGenerationJob>
    private let requests: FileBackedStore<StoryRequest>

    public init() {
        self.jobs = FileBackedStore(subdirectory: "Jobs")
        self.requests = FileBackedStore(subdirectory: "Requests")
    }

    public func job(id: UUID) async throws -> StoryGenerationJob? { await jobs.load(id: id) }
    public func save(_ job: StoryGenerationJob) async throws { try await jobs.save(job, id: job.id) }
    public func request(id: UUID) async throws -> StoryRequest? { await requests.load(id: id) }
    public func saveRequest(_ request: StoryRequest) async throws { try await requests.save(request, id: request.id) }

    public func resumableJobs() async throws -> [StoryGenerationJob] {
        await jobs.loadAll()
            .filter { $0.state.isResumable }
            .sorted { $0.createdAt < $1.createdAt }
    }
}

/// Character profiles on disk, keyed by the app's own profile id.
public struct FileCharacterStore: CharacterStore {
    private let store: FileBackedStore<CharacterProfile>

    public init() { self.store = FileBackedStore(subdirectory: "Characters") }

    public func profile(id: CharacterID) async throws -> CharacterProfile? {
        await store.load(id: id.rawValue)
    }

    public func save(_ profile: CharacterProfile) async throws {
        try await store.save(profile, id: profile.id.rawValue)
    }

    public func allProfiles(ownedBy ownerProfileID: UUID) async throws -> [CharacterProfile] {
        await store.loadAll()
            .filter { $0.ownerProfileID == ownerProfileID }
            .sorted { $0.createdAt < $1.createdAt }
    }
}
