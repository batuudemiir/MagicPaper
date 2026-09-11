import Foundation
import CharacterEngine
import VisualSystem
@testable import StoryEngine

/// Wires an orchestrator up to fakes and keeps hold of them, so a test can ask
/// what the providers were actually called with.
struct OrchestratorHarness {
    let orchestrator: StoryOrchestrator
    let aiProvider: FakeStoryAIProvider
    let imageProvider: FakeImageProvider
    let storyRepository: InMemoryStoryRepository
    let jobStore: InMemoryJobStore
    let clock: FixedClock

    /// Default script: a well-behaved model at every stage.
    static func standardScript(pageCount: Int, settings: [String]? = nil) -> @Sendable (AICompletionRequest) -> ScriptedResult {
        let settings = settings ?? Self.defaultSettings(pageCount: pageCount)
        return { request in
            switch request.operation {
            case .outline:
                return .success(ScriptedResponses.outline(
                    beatIDs: Array(repeating: "beat", count: pageCount),
                    settings: settings
                ))
            case .narrativeDraft:
                return .success(ScriptedResponses.draft(beatCount: pageCount))
            case .pageRefinement:
                return .success(ScriptedResponses.refinement(words: 70))
            case .semanticValidation:
                return .success(ScriptedResponses.noFindings)
            case .imageGeneration, .imageValidation:
                return .failure(.permanent, "images do not come from the text provider")
            }
        }
    }

    /// Three distinct places, so scenes group rather than collapsing to one.
    static func defaultSettings(pageCount: Int) -> [String] {
        (0..<pageCount).map { index in
            switch index {
            case 0: return "home"
            case pageCount - 1: return "home at night"
            default: return index < pageCount / 2 ? "forest clearing" : "river bank"
            }
        }
    }

    static func make(
        pageCount: Int = 7,
        script: [AIOperation: [ScriptedResult]] = [:],
        fallback: (@Sendable (AICompletionRequest) -> ScriptedResult)? = nil,
        imageFailures: [ErrorClass] = [],
        templates: [StoryTemplate] = BuiltInTemplates.all,
        characters: ResolvedCast? = nil,
        imageValidationProvider: ImageValidationProvider? = nil,
        concurrency: GenerationConcurrencyPolicy = .conservative,
        characterStore: CharacterStore? = nil,
        assetDeleter: AssetDeleting? = nil
    ) -> OrchestratorHarness {
        let clock = FixedClock(autoAdvance: 1)
        let aiProvider = FakeStoryAIProvider(
            script: script,
            fallback: fallback ?? standardScript(pageCount: pageCount)
        )
        let imageProvider = FakeImageProvider(failures: imageFailures)
        let storyRepository = InMemoryStoryRepository()
        let jobStore = InMemoryJobStore()

        let dependencies = StoryEngineDependencies(
            aiProvider: aiProvider,
            imageProvider: imageProvider,
            imageValidationProvider: imageValidationProvider,
            characterEngine: StubCharacterEngine(cast: characters ?? StoryFixtures.cast()),
            templateRepository: StaticTemplateRepository(templates),
            storyRepository: storyRepository,
            jobStore: jobStore,
            characterStore: characterStore,
            assetDeleter: assetDeleter,
            visualResolver: VisualStyleResolver(),
            concurrency: concurrency,
            clock: clock,
            idGenerator: SequentialIDGenerator(startingAt: 1)
        )

        return OrchestratorHarness(
            orchestrator: StoryOrchestrator(dependencies: dependencies),
            aiProvider: aiProvider,
            imageProvider: imageProvider,
            storyRepository: storyRepository,
            jobStore: jobStore,
            clock: clock
        )
    }

    func request(pageCount: Int = 7, budget: GenerationBudget = .standard) -> StoryRequest {
        StoryFixtures.request(pageCount: pageCount, budget: budget)
    }
}
