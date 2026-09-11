import Foundation
import CharacterEngine
import VisualSystem

/// Everything the orchestrator needs, injected.
///
/// No singletons and no defaults that reach outside the engine: the host app
/// builds this once, and tests build it with fakes.
public struct StoryEngineDependencies: Sendable {
    public let aiProvider: StoryAIProvider
    public let imageProvider: ImageProvider
    /// Optional. Absent means images are never looked at, which a `.required`
    /// validation mode will then refuse to publish.
    public let imageValidationProvider: ImageValidationProvider?
    public let characterEngine: CharacterEngineContract
    public let templateRepository: TemplateRepository
    public let storyRepository: StoryRepository
    public let jobStore: JobStore
    public let characterStore: CharacterStore?
    public let assetDeleter: AssetDeleting?
    public let visualResolver: VisualStyleResolver
    public let concurrency: GenerationConcurrencyPolicy
    public let clock: Clock
    public let idGenerator: IDGenerator

    public init(
        aiProvider: StoryAIProvider,
        imageProvider: ImageProvider,
        imageValidationProvider: ImageValidationProvider? = nil,
        characterEngine: CharacterEngineContract,
        templateRepository: TemplateRepository = BuiltInTemplates.repository,
        storyRepository: StoryRepository = InMemoryStoryRepository(),
        jobStore: JobStore = InMemoryJobStore(),
        characterStore: CharacterStore? = nil,
        assetDeleter: AssetDeleting? = nil,
        visualResolver: VisualStyleResolver = VisualStyleResolver(),
        concurrency: GenerationConcurrencyPolicy = .conservative,
        clock: Clock = SystemClock(),
        idGenerator: IDGenerator = RandomIDGenerator()
    ) {
        self.aiProvider = aiProvider
        self.imageProvider = imageProvider
        self.imageValidationProvider = imageValidationProvider
        self.characterEngine = characterEngine
        self.templateRepository = templateRepository
        self.storyRepository = storyRepository
        self.jobStore = jobStore
        self.characterStore = characterStore
        self.assetDeleter = assetDeleter
        self.visualResolver = visualResolver
        self.concurrency = concurrency
        self.clock = clock
        self.idGenerator = idGenerator
    }
}

/// Drives a generation from request to finished book, and every partial
/// operation afterwards.
///
/// An actor, so the cancellation flag and the job record cannot race. Each
/// stage checkpoints to the `JobStore` the moment it finishes, which is what
/// makes resumption possible: a process that dies mid-book restarts at the
/// stage it was on rather than paying for the whole thing again.
public actor StoryOrchestrator {
    private let dependencies: StoryEngineDependencies
    private var cancelledJobs: Set<UUID> = []
    private var runningTasks: [UUID: Task<Void, Never>] = [:]
    /// Shared across every story this orchestrator runs, which is the only way
    /// the limits mean anything: a per-story limiter would let ten books issue
    /// ten times the configured work.
    private let limiter: GenerationConcurrencyLimiter
    private let resultCache: ProviderResultCache
    public let lifecycle: StoryDataLifecycleService

    public init(dependencies: StoryEngineDependencies) {
        self.dependencies = dependencies
        self.limiter = GenerationConcurrencyLimiter(policy: dependencies.concurrency)
        self.resultCache = ProviderResultCache()
        self.lifecycle = StoryDataLifecycleService(
            storyRepository: dependencies.storyRepository,
            jobStore: dependencies.jobStore,
            characterStore: dependencies.characterStore,
            assetDeleter: dependencies.assetDeleter
        )
    }

    /// Exposed for tests and for a host that wants to show what is in flight.
    public func concurrencyPeak(_ lane: ConcurrencyLane) async -> Int {
        await limiter.peakCount(lane)
    }

    public func providerCacheHits() async -> Int {
        await resultCache.hitCount
    }

    // MARK: - Full generation

    /// Creates the job and story records, then runs the pipeline.
    public func generate(_ request: StoryRequest) async throws -> StoryGenerationJob {
        let job = try await startJob(for: request)
        return try await run(jobID: job.id)
    }

    /// Creates the records without running anything. Lets a caller queue work
    /// and start it later, which is also how resumption is tested.
    @discardableResult
    public func startJob(for request: StoryRequest) async throws -> StoryGenerationJob {
        let now = dependencies.clock.now()
        let template = try await templateResolver().resolve(for: request)
        let storyID = dependencies.idGenerator.next()

        let story = Story(
            id: storyID,
            requestID: request.id,
            templateRef: template.ref,
            status: .planning,
            createdAt: now
        )
        let job = StoryGenerationJob(
            id: dependencies.idGenerator.next(),
            storyID: storyID,
            requestID: request.id,
            state: .queued,
            createdAt: now
        )

        try await dependencies.jobStore.saveRequest(request)
        try await dependencies.storyRepository.save(story)
        try await dependencies.jobStore.save(job)
        // The template resolved cleanly, so record that stage as done rather
        // than resolving it a second time on the first run.
        let checkpointed = job.completing(.resolveTemplate, at: now)
        try await dependencies.jobStore.save(checkpointed)
        return checkpointed
    }

    /// Runs a job from wherever its checkpoint says it got to.
    @discardableResult
    public func run(jobID: UUID) async throws -> StoryGenerationJob {
        guard var job = try await dependencies.jobStore.job(id: jobID) else {
            throw StoryEngineError.jobNotFound(jobID)
        }
        guard let request = try await dependencies.jobStore.request(id: job.requestID) else {
            throw StoryEngineError.jobNotFound(jobID)
        }
        guard var story = try await dependencies.storyRepository.story(id: job.storyID) else {
            throw StoryEngineError.storyNotFound(job.storyID)
        }

        // A job cancelled before it started must stay cancelled. Clearing the
        // flag here would let a stale `run` call quietly undo a cancellation
        // and spend money the user already said no to.
        guard job.state != .cancelled, !cancelledJobs.contains(jobID) else {
            throw StoryEngineError.cancelled(jobID: jobID)
        }

        job = job.with(state: .running, at: now())
        try await dependencies.jobStore.save(job)

        let template = try await templateResolver().resolve(for: request)
        let context = try makeContext(request: request, template: template)

        do {
            // Only stages still outstanding run; a resumed job skips the rest.
            while let stage = job.checkpoint {
                try checkCancellation(jobID)
                job = job.starting(stage, at: now())
                try await dependencies.jobStore.save(job)

                let outcome = try await perform(
                    stage: stage,
                    story: &story,
                    request: request,
                    template: template,
                    context: context
                )

                for attempt in outcome.attempts {
                    job = job.recording(attempt, at: now())
                }
                job = outcome.skipped
                    ? job.skipping(stage, at: now())
                    : job.completing(stage, at: now())

                try await dependencies.storyRepository.save(story)
                try await dependencies.jobStore.save(job)
            }

            job = job.with(state: .completed, at: now())
            try await dependencies.jobStore.save(job)
            return job

        } catch let error as CancellationError {
            _ = error
            job = job.with(state: .cancelled, at: now(), errorMessage: "cancelled")
            try await dependencies.jobStore.save(job)
            try await dependencies.storyRepository.save(story)
            throw StoryEngineError.cancelled(jobID: jobID)

        } catch {
            let stage = job.checkpoint ?? .assemble
            var attempts: [StoryGenerationAttempt] = []
            if let failure = error as? RetryFailure { attempts = failure.attempts }
            for attempt in attempts { job = job.recording(attempt, at: now()) }

            let message = (error as? RetryFailure)?.engineError.description
                ?? (error as? StoryEngineError)?.description
                ?? String(describing: error)

            job = job.failing(stage, at: now(), message: message)
            story = (try? story.applying(StoryMutation(.setStatus(.failed)), at: now())) ?? story
            try await dependencies.storyRepository.save(story)
            try await dependencies.jobStore.save(job)
            throw (error as? RetryFailure)?.engineError ?? error
        }
    }

    /// Picks a job back up after an interruption.
    public func resume(jobID: UUID) async throws -> StoryGenerationJob {
        guard let job = try await dependencies.jobStore.job(id: jobID) else {
            throw StoryEngineError.jobNotFound(jobID)
        }
        guard job.state.isResumable else {
            throw StoryEngineError.notResumable(jobID: jobID, state: job.state)
        }
        return try await run(jobID: jobID)
    }

    /// Clears the failed stage and runs again from there.
    public func retry(jobID: UUID) async throws -> StoryGenerationJob {
        guard let job = try await dependencies.jobStore.job(id: jobID) else {
            throw StoryEngineError.jobNotFound(jobID)
        }
        let reset = job.resettingFailedStage(at: now())
        try await dependencies.jobStore.save(reset)
        return try await run(jobID: jobID)
    }

    /// Stops a job. The checkpoint is kept, so it can be resumed later.
    public func cancel(jobID: UUID) async throws {
        cancelledJobs.insert(jobID)
        runningTasks[jobID]?.cancel()
        runningTasks.removeValue(forKey: jobID)

        guard let job = try await dependencies.jobStore.job(id: jobID) else {
            throw StoryEngineError.jobNotFound(jobID)
        }
        try await dependencies.jobStore.save(job.with(state: .cancelled, at: now(), errorMessage: "cancelled"))
    }

    public func job(id: UUID) async throws -> StoryGenerationJob? {
        try await dependencies.jobStore.job(id: id)
    }

    public func story(id: UUID) async throws -> Story? {
        try await dependencies.storyRepository.story(id: id)
    }

    // MARK: - Stages

    private struct StageOutcome {
        var attempts: [StoryGenerationAttempt] = []
        var skipped = false
    }

    private struct RunContext {
        let aiService: StoryAIService
        let imageService: ImageGenerationService
        let budget: GenerationBudgetManager
        let planner: StoryPlanner
        let drafter: NarrativeDrafter
        let segmenter: PageSegmenter
        let refiner: PageRefiner
        let pagePlanner: PagePlanner
        let scenePlanner: ScenePlanner
        let visualPlanner: VisualPlanner
        let validator: StoryValidator
        let assembler: BookAssembler
        let imageValidation: ImageValidationService
        let safetyGate: ChildSafetyGate
    }

    private func makeContext(request: StoryRequest, template: ResolvedTemplate) throws -> RunContext {
        let policy = RetryPolicy(policy: template.template.generationPolicy)
        let budget = GenerationBudgetManager(budget: request.budget)
        let aiService = StoryAIService(
            provider: dependencies.aiProvider,
            budget: budget,
            policy: policy,
            clock: dependencies.clock,
            idGenerator: dependencies.idGenerator,
            cache: resultCache,
            limiter: limiter
        )
        let imageService = ImageGenerationService(
            provider: dependencies.imageProvider,
            budget: budget,
            policy: policy,
            clock: dependencies.clock,
            idGenerator: dependencies.idGenerator,
            cache: resultCache,
            limiter: limiter
        )
        return RunContext(
            aiService: aiService,
            imageService: imageService,
            budget: budget,
            planner: StoryPlanner(aiService: aiService, idGenerator: dependencies.idGenerator),
            drafter: NarrativeDrafter(aiService: aiService, idGenerator: dependencies.idGenerator),
            segmenter: PageSegmenter(),
            refiner: PageRefiner(aiService: aiService),
            pagePlanner: PagePlanner(idGenerator: dependencies.idGenerator),
            scenePlanner: ScenePlanner(idGenerator: dependencies.idGenerator),
            visualPlanner: VisualPlanner(idGenerator: dependencies.idGenerator),
            validator: StoryValidator(clock: dependencies.clock),
            assembler: BookAssembler(
                visualPlanner: VisualPlanner(idGenerator: dependencies.idGenerator),
                scenePlanner: ScenePlanner(idGenerator: dependencies.idGenerator),
                clock: dependencies.clock
            ),
            imageValidation: ImageValidationService(
                provider: dependencies.imageValidationProvider,
                budget: budget,
                policy: policy,
                clock: dependencies.clock,
                idGenerator: dependencies.idGenerator,
                cache: resultCache,
                limiter: limiter
            ),
            safetyGate: ChildSafetyGate(policy: template.template.childSafety)
        )
    }

    private func perform(
        stage: JobStage,
        story: inout Story,
        request: StoryRequest,
        template: ResolvedTemplate,
        context: RunContext
    ) async throws -> StageOutcome {
        var outcome = StageOutcome()

        switch stage {
        case .resolveTemplate:
            break

        case .resolveCast:
            // The cheapest gate there is: refuse unsafe input before a single
            // token has been paid for.
            let inputIssues = context.safetyGate.checkInput(request: request, template: template.template)
            if context.safetyGate.shouldRefuseInput(inputIssues) {
                story = try story.applying(
                    [
                        .setValidation(
                            StoryValidationResult(
                                reports: [ValidatorReport(validatorID: ValidatorID.inputSafety, outcome: .ran, issues: inputIssues)],
                                validatedAt: now()
                            )
                        ),
                        .setStatus(.failed)
                    ],
                    at: now()
                )
                throw StoryEngineError.unsafeInput(inputIssues.map(\.code))
            }

            let characters = try await CharacterBinder(characterEngine: dependencies.characterEngine)
                .bindCast(for: request)
            story = try story.applying([.setCast(characters), .setStatus(.planning)], at: now())

        case .planStory:
            let result = try await context.planner.planOutline(
                request: request, template: template, characters: story.characters, storyID: story.id
            )
            outcome.attempts = result.attempts
            story = try story.applying(
                [.setOutline(result.outline), .setTitle(result.outline.title)],
                at: now()
            )
            try await recordUsage(into: &story, from: context)

        case .planScenes:
            guard let outline = story.outline else {
                throw StoryEngineError.stageOutOfOrder(expected: .planStory, actual: stage)
            }
            let plan = context.scenePlanner.planScenes(outline: outline, template: template.template)
            story = try story.applying([.setScenes(plan.scenes)], at: now())

        case .planPages:
            guard let outline = story.outline else {
                throw StoryEngineError.stageOutOfOrder(expected: .planStory, actual: stage)
            }
            let mapping = sceneMapping(outline: outline, scenes: story.scenes)
            let pages = try context.pagePlanner.planPages(
                outline: outline, template: template, sceneIDByBeatID: mapping
            )
            let linked = context.scenePlanner.linking(pages: pages, to: story.scenes)
            story = try story.applying([.setPages(pages), .setScenes(linked), .setStatus(.writing)], at: now())

        case .draftNarrative:
            guard let outline = story.outline else {
                throw StoryEngineError.stageOutOfOrder(expected: .planStory, actual: stage)
            }
            let result = try await context.drafter.draft(
                request: request, template: template, outline: outline,
                characters: story.characters, pages: story.pages, storyID: story.id, now: now()
            )
            outcome.attempts = result.attempts
            story = try story.applying([.setDraft(result.draft)], at: now())
            try await recordUsage(into: &story, from: context)

        case .segmentPages:
            guard let draft = story.draft else {
                throw StoryEngineError.stageOutOfOrder(expected: .draftNarrative, actual: stage)
            }
            let pages = context.segmenter.segment(draft: draft, pages: story.pages)
            story = try story.applying([.setPages(pages)], at: now())

        case .refinePages:
            guard template.template.generationPolicy.pageRefinementEnabled else {
                outcome.skipped = true
                break
            }
            for page in story.pages.sorted(by: { $0.index < $1.index }) {
                try checkCancellation(nil)
                let estimate = UsageEstimate(operation: .pageRefinement, tokens: 2_500, costUSD: 0.01)
                guard await context.aiService.canAfford(estimate) else { break }

                let refinementContext = try RefinementContext.make(
                    for: page, story: story, request: request, template: template
                )
                do {
                    let result = try await context.refiner.refine(page: page, story: refinementContext)
                    outcome.attempts.append(contentsOf: result.attempts)
                    story = try story.applying(
                        [.replacePageText(pageID: page.id, title: result.title, text: result.text)],
                        at: now()
                    )
                } catch let failure as RetryFailure {
                    // A page that will not polish keeps its segmented text.
                    // Losing the polish is survivable; losing the page is not.
                    outcome.attempts.append(contentsOf: failure.attempts)
                }
            }
            try await recordUsage(into: &story, from: context)

        case .planVisuals:
            let scenes = try context.visualPlanner.planAssets(
                scenes: story.scenes, pages: story.pages, characters: story.characters,
                template: template, storyID: story.id, seedPolicy: request.seedPolicy
            )
            let pages = context.visualPlanner.assigning(
                pages: story.pages, to: scenes, policy: template.template.sceneRules.visualPolicy
            )
            story = try story.applying([.setScenes(scenes), .setPages(pages), .setStatus(.illustrating)], at: now())

        case .generateImages:
            let result = try await context.imageService.generateMissing(in: story.scenes, storyID: story.id)
            outcome.attempts = result.attempts
            let pages = context.visualPlanner.assigning(
                pages: story.pages, to: result.scenes, policy: template.template.sceneRules.visualPolicy
            )
            story = try story.applying([.setScenes(result.scenes), .setPages(pages)], at: now())
            try await recordUsage(into: &story, from: context)

        case .validateImages:
            let mode = template.template.generationPolicy.imageValidationMode
            let result = try await context.imageValidation.validateImages(
                story: story, template: template, mode: mode
            )
            outcome.attempts = result.attempts
            outcome.skipped = mode == .off
            story = try story.applying([.setScenes(result.scenes)], at: now())
            try await recordUsage(into: &story, from: context)

        case .validate:
            story = try story.applying([.setStatus(.validating)], at: now())
            let result = await context.validator.validate(
                ValidationContext(story: story, template: template, request: request),
                aiService: context.aiService
            )
            story = try story.applying([.setValidation(result)], at: now())
            try await recordUsage(into: &story, from: context)

        case .assemble:
            story = try context.assembler.assemble(story: story, template: template)
            let result = await context.validator.validate(
                ValidationContext(story: story, template: template, request: request),
                aiService: nil
            )
            story = try story.applying([.setValidation(result)], at: now())

            // The last gate. The safety policy, not each validator's own
            // opinion, decides whether this book may be read.
            let decision = context.safetyGate.publicationDecision(for: result)
            story = try story.applying(
                [
                    .setProvenance(
                        GenerationProvenance.derive(
                            templateVersion: template.template.version,
                            ledger: story.usage,
                            seed: dominantSeed(of: story, seedPolicy: request.seedPolicy),
                            generatedAt: now()
                        )
                    ),
                    .setStatus(decision.isAllowed ? .ready : .failed)
                ],
                at: now()
            )
        }

        return outcome
    }

    // MARK: - Partial regeneration

    /// Rewrites one page against the book's established voice.
    public func regeneratePageText(storyID: UUID, pageID: UUID, instruction: String? = nil) async throws -> Story {
        let (story, request, template, context) = try await loadForRegeneration(storyID: storyID)
        guard let page = story.page(id: pageID) else { throw StoryEngineError.pageNotFound(pageID) }

        let refinementContext = try RefinementContext.make(for: page, story: story, request: request, template: template)
        let result = try await context.refiner.refine(page: page, story: refinementContext, instruction: instruction)

        var updated = try story.applying(
            StoryMutation(
                .replacePageText(pageID: pageID, title: result.title, text: result.text),
                origin: .explicitRegeneration
            ),
            at: now()
        )
        updated = try stampProvenance(updated, template: template, request: request)
        updated = try await revalidate(updated, request: request, template: template, context: context)
        try await dependencies.storyRepository.save(updated)
        return updated
    }

    /// Redraws the illustration one page shows.
    ///
    /// Under a single-asset scene policy that picture may be shared, so the
    /// result reports every page it changed.
    public func regeneratePageImage(storyID: UUID, pageID: UUID, forceNewSeed: Bool = false) async throws -> RegenerationResult {
        let (story, request, template, context) = try await loadForRegeneration(storyID: storyID)
        guard let page = story.page(id: pageID) else { throw StoryEngineError.pageNotFound(pageID) }
        guard let assetID = page.visualAssetID, let asset = story.visualAsset(id: assetID) else {
            throw StoryEngineError.visualAssetNotFound(page.visualAssetID ?? pageID)
        }
        guard let scene = story.scene(id: asset.sceneID) else {
            throw StoryEngineError.sceneNotFound(asset.sceneID)
        }

        let affected = story.pages(sharing: assetID).map(\.id)
        let updated = try await redraw(
            asset: asset, scene: scene, story: story, request: request,
            template: template, context: context, forceNewSeed: forceNewSeed
        )
        let stamped = try stampProvenance(updated, template: template, request: request)
        let revalidated = try await revalidate(stamped, request: request, template: template, context: context)
        try await dependencies.storyRepository.save(revalidated)

        return RegenerationResult(story: revalidated, affectedPageIDs: affected)
    }

    /// Redraws every illustration a scene owns.
    public func regenerateScene(storyID: UUID, sceneID: UUID, forceNewSeed: Bool = false) async throws -> RegenerationResult {
        let (story, request, template, context) = try await loadForRegeneration(storyID: storyID)
        guard let scene = story.scene(id: sceneID) else { throw StoryEngineError.sceneNotFound(sceneID) }

        var working = story
        for asset in scene.visualAssets {
            guard let currentScene = working.scene(id: sceneID) else { break }
            working = try await redraw(
                asset: asset, scene: currentScene, story: working, request: request,
                template: template, context: context, forceNewSeed: forceNewSeed
            )
        }

        let affected = working.pages.filter { $0.sceneID == sceneID }.map(\.id)
        working = try stampProvenance(working, template: template, request: request)
        working = try await revalidate(working, request: request, template: template, context: context)
        try await dependencies.storyRepository.save(working)
        return RegenerationResult(story: working, affectedPageIDs: affected)
    }

    /// Validates and freezes the book.
    ///
    /// The safety gate runs here as well as at assembly, because a story can be
    /// regenerated between the two and publication is the moment that matters.
    public func publish(storyID: UUID) async throws -> Story {
        let (story, request, template, context) = try await loadForRegeneration(storyID: storyID)
        let validated = try await revalidate(story, request: request, template: template, context: context)

        guard let validation = validated.validation else {
            throw StoryEngineError.validationFailed(["not_validated"])
        }
        let decision = context.safetyGate.publicationDecision(for: validation)
        guard decision.isAllowed else {
            try await dependencies.storyRepository.save(validated)
            throw StoryEngineError.blockedByChildSafety(decision.reasonCodes)
        }

        let published = try BookAssembler(clock: dependencies.clock).publish(story: validated)
        try await dependencies.storyRepository.save(published)
        return published
    }

    public func validate(storyID: UUID) async throws -> StoryValidationResult {
        let (story, request, template, context) = try await loadForRegeneration(storyID: storyID)
        let validated = try await revalidate(story, request: request, template: template, context: context)
        try await dependencies.storyRepository.save(validated)
        return validated.validation ?? StoryValidationResult.empty(at: now())
    }

    // MARK: - Helpers

    private func redraw(
        asset: VisualAsset,
        scene: StoryScene,
        story: Story,
        request: StoryRequest,
        template: ResolvedTemplate,
        context: RunContext,
        forceNewSeed: Bool
    ) async throws -> Story {
        let recompiled = try context.visualPlanner.recompile(
            asset: asset, scene: scene, characters: story.characters,
            template: template, storyID: story.id, seedPolicy: request.seedPolicy,
            forceNewSeed: forceNewSeed
        )
        guard let constraints = recompiled.promptSnapshot else {
            throw StoryEngineError.visualAssetNotFound(asset.id)
        }
        let result = try await context.imageService.generate(
            asset: recompiled, constraints: constraints, storyID: story.id
        )

        return try story.applying(
            StoryMutation(
                .upsertVisualAsset(sceneID: scene.id, asset: result.asset),
                origin: .explicitRegeneration
            ),
            at: now()
        )
    }

    private func revalidate(
        _ story: Story,
        request: StoryRequest,
        template: ResolvedTemplate,
        context: RunContext
    ) async throws -> Story {
        let result = await context.validator.validate(
            ValidationContext(story: story, template: template, request: request),
            aiService: nil
        )
        return try story.applying(
            StoryMutation(.setValidation(result), origin: .explicitRegeneration),
            at: now()
        )
    }

    private func loadForRegeneration(storyID: UUID) async throws -> (Story, StoryRequest, ResolvedTemplate, RunContext) {
        guard let story = try await dependencies.storyRepository.story(id: storyID) else {
            throw StoryEngineError.storyNotFound(storyID)
        }
        guard let request = try await dependencies.jobStore.request(id: story.requestID) else {
            throw StoryEngineError.storyNotFound(storyID)
        }
        // Re-resolve against the pins the story recorded, so a regenerated page
        // matches the book it belongs to rather than today's template.
        let pinnedRequest = StoryRequest(
            id: request.id,
            cast: request.cast,
            templateID: story.templateRef.templateID,
            templateRequirement: .exact(story.templateRef.templateVersion),
            themeKey: request.themeKey,
            languageCode: request.languageCode,
            ageYears: request.ageYears,
            requestedPageCount: request.requestedPageCount,
            toneKey: request.toneKey,
            budget: request.budget,
            seedPolicy: request.seedPolicy,
            createdAt: request.createdAt
        )
        let template = try await templateResolver().resolve(for: pinnedRequest)
        let context = try makeContext(request: request, template: template)
        return (story, request, template, context)
    }

    /// Records how the story stands now. A regenerated page is new provenance,
    /// not a footnote on the old record.
    private func stampProvenance(_ story: Story, template: ResolvedTemplate, request: StoryRequest) throws -> Story {
        try story.applying(
            StoryMutation(
                .setProvenance(
                    GenerationProvenance.derive(
                        templateVersion: template.template.version,
                        ledger: story.usage,
                        seed: dominantSeed(of: story, seedPolicy: request.seedPolicy),
                        generatedAt: now()
                    )
                ),
                origin: .explicitRegeneration
            ),
            at: now()
        )
    }

    /// The seed the book's illustrations were drawn from.
    ///
    /// Recorded only when generation was deterministic; a salted policy means
    /// the output is not expected to reproduce, and claiming a seed would
    /// imply otherwise.
    private func dominantSeed(of story: Story, seedPolicy: SeedPolicy) -> UInt64? {
        guard case .deterministic = seedPolicy else { return nil }
        return story.scenes
            .sorted { $0.index < $1.index }
            .flatMap(\.visualAssets)
            .compactMap { $0.promptSnapshot?.seed }
            .first
    }

    private func recordUsage(into story: inout Story, from context: RunContext) async throws {
        let ledger = await context.budget.currentLedger
        let known = Set(story.usage.records.map(\.requestID))
        for record in ledger.records where !known.contains(record.requestID) {
            story = try story.applying([.recordUsage(record)], at: now())
        }
    }

    private func sceneMapping(outline: StoryOutline, scenes: [StoryScene]) -> [UUID: UUID] {
        // Scenes were planned from the same outline, so rebuilding the map is a
        // matter of replaying the grouping over the stored scenes.
        var mapping: [UUID: UUID] = [:]
        var sceneIndex = 0
        var currentSignature: SceneSignature?

        for beat in outline.beats.sorted(by: { $0.ordinal < $1.ordinal }) {
            let signature = SceneSignature(
                settingKey: beat.settingKey, timeOfDayKey: beat.timeOfDayKey,
                moodKey: beat.moodKey, castNames: beat.castNames
            )
            if let currentSignature, currentSignature != signature, sceneIndex + 1 < scenes.count {
                sceneIndex += 1
            }
            if sceneIndex < scenes.count { mapping[beat.id] = scenes[sceneIndex].id }
            currentSignature = signature
        }
        return mapping
    }

    private func templateResolver() -> TemplateResolver {
        TemplateResolver(
            repository: dependencies.templateRepository,
            visualResolver: dependencies.visualResolver,
            clock: dependencies.clock
        )
    }

    private func now() -> Date { dependencies.clock.now() }

    private func checkCancellation(_ jobID: UUID?) throws {
        if let jobID, cancelledJobs.contains(jobID) { throw CancellationError() }
        try Task.checkCancellation()
    }
}

/// What a partial regeneration changed.
public struct RegenerationResult: Sendable {
    public let story: Story
    /// Every page the change is visible on. More than one when pages share an
    /// illustration.
    public let affectedPageIDs: [UUID]

    public init(story: Story, affectedPageIDs: [UUID]) {
        self.story = story
        self.affectedPageIDs = affectedPageIDs
    }
}
