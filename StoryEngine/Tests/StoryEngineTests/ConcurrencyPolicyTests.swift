import XCTest
@testable import StoryEngine

final class ConcurrencyPolicyTests: XCTestCase {

    func testDefaultsAreConservative() {
        let policy = GenerationConcurrencyPolicy()
        XCTAssertEqual(policy.maxConcurrentStories, 2)
        XCTAssertEqual(policy.maxConcurrentAIRequests, 3)
        XCTAssertEqual(policy.maxConcurrentImageRequests, 2)
    }

    func testZeroAndNegativeLimitsBecomeOne() {
        let policy = GenerationConcurrencyPolicy(
            maxConcurrentStories: 0, maxConcurrentAIRequests: -5, maxConcurrentImageRequests: 0
        )
        XCTAssertEqual(policy.maxConcurrentStories, 1, "A limit of zero would deadlock every generation")
        XCTAssertEqual(policy.maxConcurrentAIRequests, 1)
        XCTAssertEqual(policy.maxConcurrentImageRequests, 1)
    }

    func testPolicyRoundTrips() throws {
        let policy = GenerationConcurrencyPolicy(maxConcurrentStories: 4, maxConcurrentAIRequests: 6, maxConcurrentImageRequests: 3)
        let decoded = try JSONDecoder().decode(GenerationConcurrencyPolicy.self, from: JSONEncoder().encode(policy))
        XCTAssertEqual(decoded, policy)
    }

    // MARK: - The limit is never exceeded

    func testConcurrentWorkNeverExceedsTheLimit() async throws {
        let limiter = GenerationConcurrencyLimiter(
            policy: GenerationConcurrencyPolicy(maxConcurrentAIRequests: 3)
        )

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<25 {
                group.addTask {
                    try? await limiter.withSlot(.aiRequest) {
                        try await Task.sleep(nanoseconds: 1_000_000)
                    }
                }
            }
            await group.waitForAll()
        }

        let peak = await limiter.peakCount(.aiRequest)
        XCTAssertLessThanOrEqual(peak, 3, "25 tasks through a limit of 3 peaked at \(peak)")
        let active = await limiter.activeCount(.aiRequest)
        XCTAssertEqual(active, 0, "Every slot came back")
    }

    func testLanesAreIndependent() async throws {
        let limiter = GenerationConcurrencyLimiter(
            policy: GenerationConcurrencyPolicy(maxConcurrentAIRequests: 1, maxConcurrentImageRequests: 1)
        )

        try await limiter.acquire(.aiRequest)
        // Running out of text capacity must not stop an illustration.
        try await limiter.acquire(.imageRequest)

        let ai = await limiter.activeCount(.aiRequest)
        let image = await limiter.activeCount(.imageRequest)
        XCTAssertEqual(ai, 1)
        XCTAssertEqual(image, 1)

        await limiter.release(.aiRequest)
        await limiter.release(.imageRequest)
    }

    func testTheImageExplosionIsBounded() async throws {
        // Ten books, ten pages each: the arithmetic this exists to prevent.
        let limiter = GenerationConcurrencyLimiter(
            policy: GenerationConcurrencyPolicy(maxConcurrentImageRequests: 2)
        )

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    try? await limiter.withSlot(.imageRequest) {
                        try await Task.sleep(nanoseconds: 200_000)
                    }
                }
            }
            await group.waitForAll()
        }

        let peak = await limiter.peakCount(.imageRequest)
        XCTAssertLessThanOrEqual(peak, 2, "100 pending illustrations peaked at \(peak) in flight")
    }

    // MARK: - Capacity always comes back

    func testCapacityIsReleasedAfterSuccess() async throws {
        let limiter = GenerationConcurrencyLimiter(policy: .serial)
        try await limiter.withSlot(.aiRequest) {}
        let active = await limiter.activeCount(.aiRequest)
        XCTAssertEqual(active, 0)
    }

    func testCapacityIsReleasedAfterFailure() async throws {
        struct Boom: Error {}
        let limiter = GenerationConcurrencyLimiter(policy: .serial)

        do {
            try await limiter.withSlot(.aiRequest) { throw Boom() }
            XCTFail("Expected the error to propagate")
        } catch is Boom {
            // expected
        }

        let active = await limiter.activeCount(.aiRequest)
        XCTAssertEqual(active, 0, "A limiter that leaks a slot on the error path fails closed and silently")

        // And the freed slot is genuinely usable.
        try await limiter.withSlot(.aiRequest) {}
    }

    func testCapacityIsReleasedAfterCancellation() async throws {
        let limiter = GenerationConcurrencyLimiter(policy: .serial)

        let task = Task {
            try await limiter.withSlot(.aiRequest) {
                try await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
        // Give it time to take the slot.
        try await Task.sleep(nanoseconds: 20_000_000)
        task.cancel()
        _ = try? await task.value

        let active = await limiter.activeCount(.aiRequest)
        XCTAssertEqual(active, 0)
        try await limiter.withSlot(.aiRequest) {}
    }

    func testACancelledWaiterLeavesTheQueue() async throws {
        let limiter = GenerationConcurrencyLimiter(policy: .serial)
        try await limiter.acquire(.aiRequest)

        let waiter = Task { try await limiter.acquire(.aiRequest) }
        try await Task.sleep(nanoseconds: 20_000_000)
        let queuedBefore = await limiter.waitingCount(.aiRequest)
        XCTAssertEqual(queuedBefore, 1)

        waiter.cancel()
        _ = try? await waiter.value
        try await Task.sleep(nanoseconds: 20_000_000)

        let queuedAfter = await limiter.waitingCount(.aiRequest)
        XCTAssertEqual(queuedAfter, 0, "A cancelled story must not hold a place in the queue")
        await limiter.release(.aiRequest)
    }

    // MARK: - Fairness

    func testWaitingWorkIsServedInOrder() async throws {
        let limiter = GenerationConcurrencyLimiter(policy: .serial)
        let order = OrderRecorder()

        try await limiter.acquire(.aiRequest)

        var tasks: [Task<Void, Never>] = []
        for index in 0..<5 {
            tasks.append(Task {
                try? await limiter.withSlot(.aiRequest) {
                    await order.record(index)
                }
            })
            // Stagger, so the queue order is well defined.
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        await limiter.release(.aiRequest)
        for task in tasks { _ = await task.value }

        let recorded = await order.values
        XCTAssertEqual(recorded, [0, 1, 2, 3, 4],
                       "FIFO, so a long-running book is not starved by newer work arriving")
    }

    // MARK: - Retries do not bypass the limit

    func testRetriesGoThroughTheSameLimiter() async throws {
        let limiter = GenerationConcurrencyLimiter(policy: .serial)
        let provider = FakeStoryAIProvider(
            script: [.outline: [.transient, .transient, .success(#"{"value":1}"#)]]
        )
        let service = StoryAIService(
            provider: provider,
            budget: GenerationBudgetManager(budget: .standard),
            policy: RetryPolicy(maximumAttempts: 3, initialBackoff: 0),
            clock: FixedClock(autoAdvance: 1),
            idGenerator: SequentialIDGenerator(startingAt: 9_000),
            limiter: limiter
        )

        struct Shape: Codable, Sendable { let value: Int }
        _ = try await service.complete(
            AICompletionRequest(
                operation: .outline, modelTier: .fast, systemInstructions: [], userInstructions: [],
                languageCode: "en", identity: ProviderRequestIdentity(operation: .outline, components: ["retry"])
            ),
            stage: .planStory,
            estimate: UsageEstimate(operation: .outline),
            decoding: Shape.self
        )

        XCTAssertEqual(provider.callCount, 3)
        let peak = await limiter.peakCount(.aiRequest)
        XCTAssertEqual(peak, 1, "A retry takes a slot like any other call")
        let active = await limiter.activeCount(.aiRequest)
        XCTAssertEqual(active, 0)
    }

    // MARK: - Through the orchestrator

    func testAWholeGenerationStaysInsideItsLimits() async throws {
        let harness = OrchestratorHarness.make(pageCount: 11, concurrency: .serial)
        _ = try await harness.orchestrator.generate(harness.request(pageCount: 11))

        let aiPeak = await harness.orchestrator.concurrencyPeak(.aiRequest)
        let imagePeak = await harness.orchestrator.concurrencyPeak(.imageRequest)

        XCTAssertLessThanOrEqual(aiPeak, 1)
        XCTAssertLessThanOrEqual(imagePeak, 1)
    }
}

/// Records completion order for the fairness test.
actor OrderRecorder {
    private(set) var values: [Int] = []
    func record(_ value: Int) { values.append(value) }
}
