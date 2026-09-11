import Foundation
import EngineFoundation

/// What a caller is looking for in a template.
public struct TemplateQuery: Sendable, Hashable {
    public let templateID: String?
    public let requirement: VersionRequirement
    public let themeKey: String?
    public let languageCode: String?
    public let pageCount: Int?
    public let ageYears: Int?

    public init(
        templateID: String? = nil,
        requirement: VersionRequirement = .latest,
        themeKey: String? = nil,
        languageCode: String? = nil,
        pageCount: Int? = nil,
        ageYears: Int? = nil
    ) {
        self.templateID = templateID
        self.requirement = requirement
        self.themeKey = themeKey
        self.languageCode = languageCode
        self.pageCount = pageCount
        self.ageYears = ageYears
    }
}

public protocol TemplateRepository: Sendable {
    func templates(matching query: TemplateQuery) async throws -> [StoryTemplate]
}

public protocol StoryRepository: Sendable {
    func story(id: UUID) async throws -> Story?
    func save(_ story: Story) async throws
    func allStories() async throws -> [Story]
    func delete(id: UUID) async throws
}

public protocol JobStore: Sendable {
    func job(id: UUID) async throws -> StoryGenerationJob?
    func save(_ job: StoryGenerationJob) async throws
    func resumableJobs() async throws -> [StoryGenerationJob]
    func request(id: UUID) async throws -> StoryRequest?
    func saveRequest(_ request: StoryRequest) async throws
    /// Removes a job and its checkpoint. Deleting a job that is already gone
    /// must succeed, so a retried deletion converges.
    func delete(jobID: UUID) async throws
    func deleteRequest(id: UUID) async throws
}

/// Time, injectable.
///
/// Every timestamp the engine writes comes through here, so serialization and
/// fingerprint tests can pin dates instead of tolerating them.
public protocol Clock: Sendable {
    func now() -> Date
    /// Retry backoff. A test clock returns immediately.
    func sleep(for duration: TimeInterval) async throws
}

public struct SystemClock: Clock {
    public init() {}
    public func now() -> Date { Date() }
    public func sleep(for duration: TimeInterval) async throws {
        guard duration > 0 else { return }
        try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }
}

/// Identifier minting, injectable for the same reason as `Clock`.
public protocol IDGenerator: Sendable {
    func next() -> UUID
}

public struct RandomIDGenerator: IDGenerator {
    public init() {}
    public func next() -> UUID { UUID() }
}
