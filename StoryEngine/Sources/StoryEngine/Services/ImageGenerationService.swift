import Foundation
import VisualSystem

/// The only route from the engine to an image model.
///
/// Its most important behaviour is not generating: an asset whose fingerprint
/// still matches a `.ready` image is skipped entirely, so a book whose pages
/// mostly share scenes buys a handful of illustrations rather than one per page.
public struct ImageGenerationService: Sendable {
    private let provider: ImageProvider
    private let budget: GenerationBudgetManager
    private let policy: RetryPolicy
    private let clock: Clock
    private let idGenerator: IDGenerator
    private let costEstimatePerImage: Double
    private let cache: ProviderResultCache?
    private let limiter: GenerationConcurrencyLimiter?

    public init(
        provider: ImageProvider,
        budget: GenerationBudgetManager,
        policy: RetryPolicy,
        clock: Clock,
        idGenerator: IDGenerator = RandomIDGenerator(),
        costEstimatePerImage: Double = 0.05,
        cache: ProviderResultCache? = nil,
        limiter: GenerationConcurrencyLimiter? = nil
    ) {
        self.provider = provider
        self.budget = budget
        self.policy = policy
        self.clock = clock
        self.idGenerator = idGenerator
        self.costEstimatePerImage = costEstimatePerImage
        self.cache = cache
        self.limiter = limiter
    }

    public struct BatchResult: Sendable {
        public let scenes: [StoryScene]
        public let attempts: [StoryGenerationAttempt]
        public let generatedCount: Int
        public let skippedCount: Int
        /// Assets left `.failed`. Generation continues past these: a book with
        /// nine of ten pictures is worth more than no book at all.
        public let failedAssetIDs: [UUID]
    }

    /// Draws whatever is missing or stale across every scene.
    public func generateMissing(in scenes: [StoryScene], storyID: UUID) async throws -> BatchResult {
        var updated: [StoryScene] = []
        var attempts: [StoryGenerationAttempt] = []
        var generated = 0
        var skipped = 0
        var failed: [UUID] = []

        for scene in scenes {
            var sceneCopy = scene
            for asset in scene.visualAssets {
                try Task.checkCancellation()

                guard let constraints = asset.promptSnapshot else {
                    // Nothing to draw from; the visual planner has not run.
                    continue
                }
                guard asset.needsGeneration(against: constraints.fingerprint) else {
                    skipped += 1
                    continue
                }

                do {
                    let result = try await generate(asset: asset, constraints: constraints, storyID: storyID)
                    sceneCopy.upsert(result.asset)
                    attempts.append(contentsOf: result.attempts)
                    generated += 1
                } catch let failure as RetryFailure {
                    attempts.append(contentsOf: failure.attempts)
                    var broken = asset
                    broken.state = .failed
                    broken.failureMessage = failure.engineError.description
                    sceneCopy.upsert(broken)
                    failed.append(asset.id)
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    var broken = asset
                    broken.state = .failed
                    broken.failureMessage = String(describing: error)
                    sceneCopy.upsert(broken)
                    failed.append(asset.id)
                }
            }
            updated.append(sceneCopy)
        }

        return BatchResult(
            scenes: updated,
            attempts: attempts,
            generatedCount: generated,
            skippedCount: skipped,
            failedAssetIDs: failed
        )
    }

    public struct SingleResult: Sendable {
        public let asset: VisualAsset
        public let attempts: [StoryGenerationAttempt]
    }

    /// Draws one asset, unconditionally.
    public func generate(
        asset: VisualAsset,
        constraints: VisualConstraintSet,
        storyID: UUID
    ) async throws -> SingleResult {
        let identity = IdempotencyKeyFactory.image(storyID: storyID, asset: asset)
        let estimate = UsageEstimate(
            operation: .imageGeneration,
            costUSD: costEstimatePerImage,
            imageCount: 1
        )

        let outcome = try await RetryRunner(policy: policy, clock: clock, idGenerator: idGenerator)
            .run(stage: .generateImages) { () -> (ImageGenerationResponse, AIUsage?) in
                let reservation = try await budget.reserve(estimate)
                do {
                    // A result already recorded for this exact logical
                    // request is reused rather than re-bought. This is the
                    // lost-response case: the provider drew the picture, the
                    // reply never arrived, and the retry must not pay again.
                    if let cache, let cached = await cache.image(for: identity) {
                        await budget.release(reservation)
                        return (cached, nil)
                    }
                    let imageRequest = ImageGenerationRequest(constraints: constraints, identity: identity)
                    let response: ImageGenerationResponse
                    if let limiter {
                        response = try await limiter.withSlot(.imageRequest) {
                            try await provider.generateImage(imageRequest)
                        }
                    } else {
                        response = try await provider.generateImage(imageRequest)
                    }
                    await budget.commit(reservation, usage: response.usage)
                    await cache?.store(response, for: identity)
                    return (response, response.usage)
                } catch {
                    await budget.release(reservation)
                    throw error
                }
            }

        var updated = asset
        updated.state = .ready
        updated.imageRef = outcome.value.imageRef
        updated.fingerprint = constraints.fingerprint
        updated.promptSnapshot = constraints
        updated.failureMessage = nil
        // A fresh image has not been looked at yet.
        updated.validation = nil

        return SingleResult(asset: updated, attempts: outcome.attempts)
    }

    /// How many assets would actually be drawn. Lets a caller show a cost
    /// before committing to it.
    public func pendingAssetCount(in scenes: [StoryScene]) -> Int {
        scenes.reduce(0) { total, scene in
            total + scene.visualAssets.filter { asset in
                guard let constraints = asset.promptSnapshot else { return false }
                return asset.needsGeneration(against: constraints.fingerprint)
            }.count
        }
    }
}
