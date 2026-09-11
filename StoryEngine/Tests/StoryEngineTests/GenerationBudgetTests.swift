import XCTest
@testable import StoryEngine

final class GenerationBudgetTests: XCTestCase {
    static let testStoryID = UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000002")!

    private let date = StoryFixtures.referenceDate

    private func usage(
        operation: AIOperation = .narrativeDraft,
        inputTokens: Int = 0,
        outputTokens: Int = 0,
        images: Int = 0,
        cost: Double = 0
    ) -> AIUsage {
        AIUsage(
            provider: "fake", model: "fake-1", operation: operation,
            inputTokens: inputTokens, outputTokens: outputTokens, imageCount: images,
            estimatedCostUSD: cost, recordedAt: date
        )
    }

    private func budget(
        llm: Int = 10, images: Int = 5, tokens: Int = 10_000, cost: Double = 1.0
    ) -> GenerationBudget {
        GenerationBudget(
            maximumLanguageModelCalls: llm, maximumImageCalls: images,
            maximumTokens: tokens, maximumCostUSD: cost
        )
    }

    // MARK: - Reservation arithmetic

    func testFreshBudgetReportsFullHeadroom() async {
        let manager = GenerationBudgetManager(budget: budget())
        let remaining = await manager.remaining

        XCTAssertEqual(remaining.languageModelCalls, 10)
        XCTAssertEqual(remaining.imageCalls, 5)
        XCTAssertEqual(remaining.tokens, 10_000)
        XCTAssertEqual(remaining.costUSD, 1.0, accuracy: 0.000_1)
    }

    func testReservationConsumesHeadroomBeforeTheCallHappens() async throws {
        let manager = GenerationBudgetManager(budget: budget(llm: 2))
        _ = try await manager.reserve(UsageEstimate(operation: .outline, tokens: 100, costUSD: 0.01))

        let remaining = await manager.remaining
        XCTAssertEqual(remaining.languageModelCalls, 1, "An outstanding reservation is already spent")
        XCTAssertEqual(remaining.tokens, 9_900)
    }

    func testCommitReplacesTheEstimateWithActualCost() async throws {
        let manager = GenerationBudgetManager(budget: budget())
        let reservation = try await manager.reserve(UsageEstimate(operation: .outline, tokens: 5_000, costUSD: 0.5))
        await manager.commit(reservation, usage: usage(operation: .outline, inputTokens: 10, outputTokens: 20, cost: 0.02))

        let remaining = await manager.remaining
        XCTAssertEqual(remaining.tokens, 10_000 - 30, "The estimate is released; the real usage counts")
        XCTAssertEqual(remaining.costUSD, 0.98, accuracy: 0.000_1)
        let ledger = await manager.currentLedger
        XCTAssertEqual(ledger.languageModelCallCount, 1)
    }

    func testReleaseReturnsHeadroomForACallThatNeverHappened() async throws {
        let manager = GenerationBudgetManager(budget: budget(llm: 1))
        let reservation = try await manager.reserve(UsageEstimate(operation: .outline, tokens: 100))
        await manager.release(reservation)

        let remaining = await manager.remaining
        XCTAssertEqual(remaining.languageModelCalls, 1)
        let affordable = await manager.canAfford(UsageEstimate(operation: .outline, tokens: 100))
        XCTAssertTrue(affordable)
    }

    // MARK: - Exhaustion happens before the provider call

    func testCallCeilingThrowsRatherThanReporting() async throws {
        let manager = GenerationBudgetManager(budget: budget(llm: 1))
        _ = try await manager.reserve(UsageEstimate(operation: .outline))

        do {
            _ = try await manager.reserve(UsageEstimate(operation: .outline))
            XCTFail("Expected budgetExhausted")
        } catch {
            guard case .budgetExhausted(let shortfall) = error as? StoryEngineError else {
                return XCTFail("Unexpected error \(error)")
            }
            XCTAssertEqual(shortfall.limit, .languageModelCalls)
        }
    }

    func testImageCeilingIsSeparateFromTheTextCeiling() async throws {
        let manager = GenerationBudgetManager(budget: budget(llm: 10, images: 1))
        _ = try await manager.reserve(UsageEstimate(operation: .imageGeneration, imageCount: 1))

        do {
            _ = try await manager.reserve(UsageEstimate(operation: .imageGeneration, imageCount: 1))
            XCTFail("Expected budgetExhausted")
        } catch {
            guard case .budgetExhausted(let shortfall) = error as? StoryEngineError else {
                return XCTFail("Unexpected error \(error)")
            }
            XCTAssertEqual(shortfall.limit, .imageCalls)
        }

        let canStillWrite = await manager.canAfford(UsageEstimate(operation: .outline))
        XCTAssertTrue(canStillWrite, "Running out of images must not stop the writing")
    }

    func testTokenCeilingIsReportedWithTheShortfall() async {
        let manager = GenerationBudgetManager(budget: budget(tokens: 500))
        do {
            _ = try await manager.reserve(UsageEstimate(operation: .narrativeDraft, tokens: 900))
            XCTFail("Expected budgetExhausted")
        } catch {
            guard case .budgetExhausted(let shortfall) = error as? StoryEngineError else {
                return XCTFail("Unexpected error \(error)")
            }
            XCTAssertEqual(shortfall.limit, .tokens)
            XCTAssertEqual(shortfall.requested, 900)
            XCTAssertEqual(shortfall.remaining, 500)
        }
    }

    func testCostCeilingIsReportedWithTheShortfall() async {
        let manager = GenerationBudgetManager(budget: budget(cost: 0.10))
        do {
            _ = try await manager.reserve(UsageEstimate(operation: .imageGeneration, costUSD: 0.25, imageCount: 1))
            XCTFail("Expected budgetExhausted")
        } catch {
            guard case .budgetExhausted(let shortfall) = error as? StoryEngineError else {
                return XCTFail("Unexpected error \(error)")
            }
            XCTAssertEqual(shortfall.limit, .costUSD)
            XCTAssertEqual(shortfall.requested, 0.25, accuracy: 0.000_1)
        }
    }

    func testConcurrentReservationsCannotEachSeeTheSameHeadroom() async throws {
        let manager = GenerationBudgetManager(budget: budget(llm: 3))
        _ = try await manager.reserve(UsageEstimate(operation: .outline))
        _ = try await manager.reserve(UsageEstimate(operation: .narrativeDraft))
        _ = try await manager.reserve(UsageEstimate(operation: .pageRefinement))

        let canAffordMore = await manager.canAfford(UsageEstimate(operation: .pageRefinement))
        XCTAssertFalse(canAffordMore)
    }

    // MARK: - Ledger accounting

    func testLedgerTotalsAccumulateAcrossStages() {
        var ledger = UsageLedger()
        ledger.record(usage(operation: .outline, inputTokens: 100, outputTokens: 50, cost: 0.01))
        ledger.record(usage(operation: .narrativeDraft, inputTokens: 400, outputTokens: 900, cost: 0.08))
        ledger.record(usage(operation: .imageGeneration, images: 1, cost: 0.04))
        ledger.record(usage(operation: .imageGeneration, images: 1, cost: 0.04))

        XCTAssertEqual(ledger.languageModelCallCount, 2)
        XCTAssertEqual(ledger.imageCallCount, 2)
        XCTAssertEqual(ledger.totalImagesProduced, 2)
        XCTAssertEqual(ledger.totalTokens, 1_450)
        XCTAssertEqual(ledger.totalCostUSD, 0.17, accuracy: 0.000_1)
        XCTAssertEqual(ledger.cost(of: .imageGeneration), 0.08, accuracy: 0.000_1)
    }

    func testLedgerMergePreservesEveryRecord() {
        let a = UsageLedger(records: [usage(cost: 0.01)])
        let b = UsageLedger(records: [usage(cost: 0.02), usage(cost: 0.03)])
        XCTAssertEqual(a.merging(b).records.count, 3)
        XCTAssertEqual(a.merging(b).totalCostUSD, 0.06, accuracy: 0.000_1)
    }

    func testManagerStartsFromAnExistingLedger() async {
        let existing = UsageLedger(records: [usage(operation: .outline, inputTokens: 9_000)])
        let manager = GenerationBudgetManager(budget: budget(tokens: 10_000), ledger: existing)

        let remaining = await manager.remaining
        XCTAssertEqual(remaining.tokens, 1_000, "A resumed job inherits what it already spent")
        let canAffordMore = await manager.canAfford(UsageEstimate(operation: .narrativeDraft, tokens: 2_000))
        XCTAssertFalse(canAffordMore)
    }

    func testTextOnlyBudgetForbidsImages() async {
        let manager = GenerationBudgetManager(budget: .textOnly)
        let canDrawImage = await manager.canAfford(UsageEstimate(operation: .imageGeneration, imageCount: 1))
        XCTAssertFalse(canDrawImage)
        let canWrite = await manager.canAfford(UsageEstimate(operation: .narrativeDraft, tokens: 100))
        XCTAssertTrue(canWrite)
    }

    func testImageServiceStopsAtTheImageCeiling() async throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 11)
        let scenes = try VisualPlanner(idGenerator: SequentialIDGenerator(startingAt: 400)).planAssets(
            scenes: planned.scenes, pages: planned.pages, characters: planned.characters,
            template: planned.template, storyID: UUID(), seedPolicy: .deterministic
        )
        let provider = FakeImageProvider()
        let service = ImageGenerationService(
            provider: provider,
            budget: GenerationBudgetManager(budget: budget(images: 2)),
            policy: RetryPolicy(maximumAttempts: 1),
            clock: FixedClock(autoAdvance: 1),
            idGenerator: SequentialIDGenerator(startingAt: 900)
        )

        let result = try await service.generateMissing(in: scenes, storyID: Self.testStoryID)

        XCTAssertEqual(provider.callCount, 2, "The third image is never requested")
        XCTAssertEqual(result.generatedCount, 2)
        XCTAssertFalse(result.failedAssetIDs.isEmpty, "Assets past the ceiling are recorded as failed, not silently dropped")
    }
}
