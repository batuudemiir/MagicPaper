import Foundation
import EngineFoundation

/// In-memory story repository. Ships with the engine so tests, previews and
/// the orchestrator's own defaults do not need an adapter.
public actor InMemoryStoryRepository: StoryRepository {
    private var stories: [UUID: Story] = [:]
    public private(set) var saveCount = 0

    public init(_ seed: [Story] = []) {
        for story in seed { stories[story.id] = story }
    }

    public func story(id: UUID) async throws -> Story? { stories[id] }

    public func save(_ story: Story) async throws {
        stories[story.id] = story
        saveCount += 1
    }

    public func allStories() async throws -> [Story] {
        stories.values.sorted { $0.createdAt < $1.createdAt }
    }

    public func delete(id: UUID) async throws { stories.removeValue(forKey: id) }
}

/// In-memory job store.
public actor InMemoryJobStore: JobStore {
    private var jobs: [UUID: StoryGenerationJob] = [:]
    private var requests: [UUID: StoryRequest] = [:]
    public private(set) var saveCount = 0

    public init() {}

    public func job(id: UUID) async throws -> StoryGenerationJob? { jobs[id] }

    public func save(_ job: StoryGenerationJob) async throws {
        jobs[job.id] = job
        saveCount += 1
    }

    public func resumableJobs() async throws -> [StoryGenerationJob] {
        jobs.values.filter { $0.state.isResumable }.sorted { $0.createdAt < $1.createdAt }
    }

    public func request(id: UUID) async throws -> StoryRequest? { requests[id] }

    public func saveRequest(_ request: StoryRequest) async throws { requests[request.id] = request }

    public func delete(jobID: UUID) async throws { jobs.removeValue(forKey: jobID) }

    public func deleteRequest(id: UUID) async throws { requests.removeValue(forKey: id) }

    /// Every job, not only the resumable ones. Used by deletion, which has to
    /// find completed jobs too.
    public func allJobs() async throws -> [StoryGenerationJob] {
        jobs.values.sorted { $0.createdAt < $1.createdAt }
    }
}

/// A template repository backed by a fixed list. Used for the built-in
/// templates and by tests.
public struct StaticTemplateRepository: TemplateRepository {
    private let templates: [StoryTemplate]

    public init(_ templates: [StoryTemplate]) { self.templates = templates }

    public func templates(matching query: TemplateQuery) async throws -> [StoryTemplate] {
        templates.filter { template in
            if let id = query.templateID, template.id != id { return false }
            guard query.requirement.isSatisfied(by: template.version) else { return false }
            if let theme = query.themeKey, !template.supports(themeKey: theme) { return false }
            if let language = query.languageCode,
               !template.constraints.supportedLanguageCodes.contains(language) { return false }
            if let pageCount = query.pageCount,
               !template.constraints.supportedPageCounts.contains(pageCount) { return false }
            if let age = query.ageYears,
               !template.constraints.supportedAgeRange.contains(age) { return false }
            return true
        }
    }
}
