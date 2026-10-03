import Foundation
import CharacterEngine
import StoryEngine
import VisualSystem

/// The engine's composition root.
///
/// Everything the engine needs is assembled here, once. The engine itself takes
/// its dependencies through initializers and reaches for no singletons; this is
/// the only place that knows the app uses `FileManagerService` and fal.ai, which is what makes swapping any of them a change to this file.
///
/// Nothing in this type runs automatically. The engine ships unwired: existing
/// story creation still goes through `StoryGenerationManager`, untouched.
@MainActor
final class StoryEngineContainer {

    /// Why the engine could not be built, when it could not.
    enum UnavailableReason: String, Error {
        case cloudIllustrationDisabled
        case missingFalKey
    }

    let orchestrator: StoryOrchestrator
    let characterStore: FileCharacterStore
    let characterSource: ProfileCharacterSource
    let storyRepository: FileStoryRepository
    let jobStore: FileJobStore

    /// Builds the engine, or reports why it cannot.
    ///
    /// Returns a failure rather than trapping on a missing key: a configuration
    /// problem should surface as a disabled feature, never as a launch crash.
    ///
    /// This is the cloud illustration path (fal.ai), so it refuses to build
    /// unless `CloudIllustrationAccess` is on. The text provider has no default:
    /// text stories are on-device, and nothing here picks a vendor for them.
    static func make(
        textProvider: StoryAIProvider,
        imageValidationProvider: ImageValidationProvider? = nil,
        concurrency: GenerationConcurrencyPolicy = .conservative,
        defaults: UserDefaults = .standard
    ) -> Result<StoryEngineContainer, UnavailableReason> {
        guard CloudIllustrationAccess.isEnabled(defaults: defaults) else {
            return .failure(.cloudIllustrationDisabled)
        }
        let aiProvider = textProvider
        guard let imageProvider = FalImageProvider() else { return .failure(.missingFalKey) }
        return .success(
            StoryEngineContainer(
                aiProvider: aiProvider,
                imageProvider: imageProvider,
                imageValidationProvider: imageValidationProvider,
                concurrency: concurrency
            )
        )
    }

    init(
        aiProvider: StoryAIProvider,
        imageProvider: ImageProvider,
        imageValidationProvider: ImageValidationProvider? = nil,
        concurrency: GenerationConcurrencyPolicy = .conservative
    ) {
        let characterStore = FileCharacterStore()
        let storyRepository = FileStoryRepository()
        let jobStore = FileJobStore()

        self.characterStore = characterStore
        self.characterSource = ProfileCharacterSource()
        self.storyRepository = storyRepository
        self.jobStore = jobStore

        self.orchestrator = StoryOrchestrator(
            dependencies: StoryEngineDependencies(
                aiProvider: aiProvider,
                imageProvider: imageProvider,
                // No vision-based checker in V1. Templates ship with
                // `.advisory`, so a missing provider is reported rather than
                // blocking — set a template to `.required` only once something
                // real is wired in here.
                imageValidationProvider: imageValidationProvider,
                characterEngine: CharacterResolver(store: characterStore),
                templateRepository: BuiltInTemplates.repository,
                storyRepository: storyRepository,
                jobStore: jobStore,
                characterStore: characterStore,
                assetDeleter: FileAssetDeleter(),
                visualResolver: VisualStyleResolver(),
                concurrency: concurrency,
                clock: SystemClock(),
                idGenerator: RandomIDGenerator()
            )
        )
    }

    /// Deleting a story, a character or a job, including the files behind them.
    ///
    /// Remote assets need a `RemoteAssetDeleting` before they can actually be
    /// removed; until one is wired in, a deletion reports them as unhandled
    /// rather than pretending they are gone.
    var dataLifecycle: StoryDataLifecycle {
        get async { await orchestrator.lifecycle }
    }

    // MARK: - Convenience

    /// Makes sure a character exists for a profile, and returns its id.
    ///
    /// Call this before generating: the engine resolves its cast through the
    /// Character Engine, and will refuse a cast it cannot find.
    func ensureCharacter(
        for profile: UserProfile,
        referenceLocator: String?,
        pronouns: Pronouns,
        descriptors: [CharacterDescriptor] = [],
        doNotDepict: [String] = []
    ) async throws -> CharacterID {
        let id = CharacterID(profile.id)
        if let existing = try await characterStore.profile(id: id) {
            guard referenceLocator != nil || !descriptors.isEmpty else { return existing.id }
            let updated = characterSource.updating(
                existing,
                referenceLocator: referenceLocator,
                descriptors: descriptors.isEmpty ? (existing.latestVersion?.identity.descriptors ?? []) : descriptors,
                doNotDepict: doNotDepict
            )
            try await characterStore.save(updated)
            return updated.id
        }

        let created = characterSource.makeProfile(
            from: profile,
            referenceLocator: referenceLocator,
            pronouns: pronouns,
            parentProvidedDescriptors: descriptors,
            doNotDepict: doNotDepict
        )
        try await characterStore.save(created)
        return created.id
    }

    /// Builds a request for one child. The theme is a plain string: the engine
    /// resolves it against template data and has no theme vocabulary of its own.
    func makeRequest(
        characterID: CharacterID,
        templateID: String = "adventure_01",
        themeKey: String,
        languageCode: String,
        ageYears: Int,
        pageCount: Int,
        toneKey: String? = nil,
        budget: GenerationBudget = .standard
    ) -> StoryRequest {
        StoryRequest(
            cast: CastBinding(protagonist: characterID),
            templateID: templateID,
            themeKey: themeKey,
            languageCode: languageCode,
            ageYears: ageYears,
            requestedPageCount: pageCount,
            toneKey: toneKey,
            budget: budget,
            createdAt: Date()
        )
    }

    /// Jobs left mid-flight by a previous launch.
    func interruptedJobs() async throws -> [StoryGenerationJob] {
        try await jobStore.resumableJobs()
    }
}
