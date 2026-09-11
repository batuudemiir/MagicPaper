import Foundation
import CharacterEngine
import VisualSystem

/// Runs image validation over a story's illustrations and records the verdicts.
///
/// Kept separate from `StoryValidator` on purpose: this one makes provider calls
/// and costs money, while the validators are deterministic and free. The verdict
/// is written onto the asset, and `GeneratedImageValidator` later turns those
/// records into issues — so the decision about whether a book may be published
/// stays in one place and stays deterministic.
public struct ImageValidationService: Sendable {
    private let provider: ImageValidationProvider?
    private let providerName: String
    private let budget: GenerationBudgetManager
    private let policy: RetryPolicy
    private let clock: Clock
    private let idGenerator: IDGenerator
    private let cache: ProviderResultCache?
    private let limiter: GenerationConcurrencyLimiter?
    private let costEstimatePerCheck: Double

    public init(
        provider: ImageValidationProvider?,
        providerName: String = "image-validator",
        budget: GenerationBudgetManager,
        policy: RetryPolicy,
        clock: Clock,
        idGenerator: IDGenerator = RandomIDGenerator(),
        cache: ProviderResultCache? = nil,
        limiter: GenerationConcurrencyLimiter? = nil,
        costEstimatePerCheck: Double = 0.002
    ) {
        self.provider = provider
        self.providerName = providerName
        self.budget = budget
        self.policy = policy
        self.clock = clock
        self.idGenerator = idGenerator
        self.cache = cache
        self.limiter = limiter
        self.costEstimatePerCheck = costEstimatePerCheck
    }

    public struct Result: Sendable {
        public let scenes: [StoryScene]
        public let attempts: [StoryGenerationAttempt]
        public let checkedCount: Int
        public let skippedCount: Int
    }

    /// Validates every ready illustration that has not already been checked.
    public func validateImages(
        story: Story,
        template: ResolvedTemplate,
        mode: ImageValidationMode
    ) async throws -> Result {
        guard mode != .off else {
            // Explicitly recorded rather than left blank, so a later reader can
            // tell "nobody looked" from "nobody has looked yet".
            return Result(
                scenes: story.scenes.map { annotate($0, with: .skipped(reason: "validation mode is off"), mode: mode) },
                attempts: [],
                checkedCount: 0,
                skippedCount: story.scenes.reduce(0) { $0 + $1.readyAssets.count }
            )
        }

        guard let protagonist = story.characters.protagonist else {
            return Result(scenes: story.scenes, attempts: [], checkedCount: 0, skippedCount: 0)
        }
        let expectedCastIDs = story.characters.map(\.id)

        var updatedScenes: [StoryScene] = []
        var attempts: [StoryGenerationAttempt] = []
        var checked = 0
        var skipped = 0

        for scene in story.scenes {
            var sceneCopy = scene
            for asset in scene.visualAssets {
                try Task.checkCancellation()

                guard asset.isReady, let imageRef = asset.imageRef, let constraints = asset.promptSnapshot else {
                    continue
                }
                // A verdict that already describes this exact image stands.
                if asset.currentValidation != nil {
                    skipped += 1
                    continue
                }
                guard let page = story.pages.first(where: { $0.visualAssetID == asset.id }) else {
                    continue
                }

                let context = ImageValidationContext(
                    characterIdentity: protagonist.identity,
                    scene: scene,
                    page: page,
                    visualConstraints: constraints,
                    expectedCastIDs: expectedCastIDs
                )

                let outcome = await check(
                    asset: asset, imageRef: imageRef, context: context, storyID: story.id, mode: mode
                )
                attempts.append(contentsOf: outcome.attempts)

                var annotated = asset
                annotated.validation = ImageValidationRecord(
                    result: outcome.result,
                    mode: mode,
                    provider: provider == nil ? nil : providerName,
                    validatedAt: clock.now(),
                    imageLocator: imageRef.locator,
                    assetRevision: asset.revision
                )
                sceneCopy.upsert(annotated)

                if outcome.result.wasChecked { checked += 1 } else { skipped += 1 }
            }
            updatedScenes.append(sceneCopy)
        }

        return Result(scenes: updatedScenes, attempts: attempts, checkedCount: checked, skippedCount: skipped)
    }

    private struct CheckOutcome {
        let result: ImageValidationResult
        let attempts: [StoryGenerationAttempt]
    }

    private func check(
        asset: VisualAsset,
        imageRef: ImageRef,
        context: ImageValidationContext,
        storyID: UUID,
        mode: ImageValidationMode
    ) async -> CheckOutcome {
        guard let provider else {
            // No provider configured. This is the one outcome that must never
            // read as a pass: nobody looked at the picture.
            return CheckOutcome(result: .providerUnavailable(reason: "no image validation provider configured"), attempts: [])
        }

        let estimate = UsageEstimate(operation: .imageValidation, tokens: 1_500, costUSD: costEstimatePerCheck)
        guard await budget.canAfford(estimate) else {
            return CheckOutcome(result: .providerUnavailable(reason: "budget exhausted"), attempts: [])
        }

        let identity = IdempotencyKeyFactory.imageValidation(
            storyID: storyID, assetID: asset.id, imageLocator: imageRef.locator, revision: asset.revision
        )

        do {
            let outcome = try await RetryRunner(policy: policy, clock: clock, idGenerator: idGenerator)
                .run(stage: .validateImages) { () -> (ImageValidationResult, AIUsage?) in
                    let reservation = try await budget.reserve(estimate)
                    do {
                        let result: ImageValidationResult
                        if let limiter {
                            result = try await limiter.withSlot(.aiRequest) {
                                try await provider.validate(image: imageRef, context: context)
                            }
                        } else {
                            result = try await provider.validate(image: imageRef, context: context)
                        }
                        let usage = AIUsage(
                            provider: providerName,
                            model: providerName,
                            operation: .imageValidation,
                            estimatedCostUSD: costEstimatePerCheck,
                            requestID: identity.idempotencyKey,
                            recordedAt: clock.now()
                        )
                        await budget.commit(reservation, usage: usage)
                        return (result, usage)
                    } catch {
                        await budget.release(reservation)
                        throw error
                    }
                }
            return CheckOutcome(result: outcome.value, attempts: outcome.attempts)

        } catch let failure as RetryFailure {
            // A provider that errored is unavailable, not permissive.
            return CheckOutcome(
                result: .providerUnavailable(reason: failure.engineError.description),
                attempts: failure.attempts
            )
        } catch {
            return CheckOutcome(result: .providerUnavailable(reason: String(describing: error)), attempts: [])
        }
    }

    private func annotate(_ scene: StoryScene, with result: ImageValidationResult, mode: ImageValidationMode) -> StoryScene {
        var copy = scene
        copy.visualAssets = scene.visualAssets.map { asset in
            guard asset.isReady, let imageRef = asset.imageRef else { return asset }
            var annotated = asset
            annotated.validation = ImageValidationRecord(
                result: result,
                mode: mode,
                provider: nil,
                validatedAt: clock.now(),
                imageLocator: imageRef.locator,
                assetRevision: asset.revision
            )
            return annotated
        }
        return copy
    }
}
