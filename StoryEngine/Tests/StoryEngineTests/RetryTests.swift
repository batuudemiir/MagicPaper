import XCTest
@testable import StoryEngine

final class RetryPolicyTests: XCTestCase {

    func testTransientAndRateLimitedAreRetried() {
        let policy = RetryPolicy(maximumAttempts: 3)
        XCTAssertTrue(policy.shouldRetry(.transient, attemptNumber: 1))
        XCTAssertTrue(policy.shouldRetry(.rateLimited, attemptNumber: 2))
    }

    func testPermanentAndCancelledAreNotRetried() {
        let policy = RetryPolicy(maximumAttempts: 5)
        XCTAssertFalse(policy.shouldRetry(.permanent, attemptNumber: 1))
        XCTAssertFalse(policy.shouldRetry(.cancelled, attemptNumber: 1))
    }

    func testAttemptCeilingStopsRetrying() {
        let policy = RetryPolicy(maximumAttempts: 3)
        XCTAssertTrue(policy.shouldRetry(.transient, attemptNumber: 2))
        XCTAssertFalse(policy.shouldRetry(.transient, attemptNumber: 3))
    }

    func testBackoffGrowsExponentiallyAndIsCapped() {
        let policy = RetryPolicy(initialBackoff: 1, multiplier: 2, maximumBackoff: 5)
        XCTAssertEqual(policy.backoff(afterAttempt: 1, errorClass: .transient), 1)
        XCTAssertEqual(policy.backoff(afterAttempt: 2, errorClass: .transient), 2)
        XCTAssertEqual(policy.backoff(afterAttempt: 3, errorClass: .transient), 4)
        XCTAssertEqual(policy.backoff(afterAttempt: 4, errorClass: .transient), 5, "Capped")
    }

    func testRateLimitingWaitsLonger() {
        let policy = RetryPolicy(initialBackoff: 1, multiplier: 2, maximumBackoff: 100, rateLimitMultiplier: 3)
        XCTAssertEqual(policy.backoff(afterAttempt: 1, errorClass: .rateLimited), 3)
        XCTAssertGreaterThan(
            policy.backoff(afterAttempt: 2, errorClass: .rateLimited),
            policy.backoff(afterAttempt: 2, errorClass: .transient)
        )
    }

    func testAtLeastOneAttemptIsAlwaysAllowed() {
        XCTAssertEqual(RetryPolicy(maximumAttempts: 0).maximumAttempts, 1)
    }

    func testPolicyIsBuiltFromTheTemplateGenerationPolicy() {
        let generation = GenerationPolicy(maximumAttemptsPerStage: 4, initialBackoff: 0.25, backoffMultiplier: 3, maximumBackoff: 9)
        let policy = RetryPolicy(policy: generation)

        XCTAssertEqual(policy.maximumAttempts, 4)
        XCTAssertEqual(policy.backoff(afterAttempt: 2, errorClass: .transient), 0.75, accuracy: 0.000_1)
    }
}

final class ErrorClassifierTests: XCTestCase {
    func testProviderErrorsKeepTheirClass() {
        for errorClass in ErrorClass.allCases {
            let error = StoryEngineError.providerFailed(operation: .outline, errorClass: errorClass, message: "x")
            XCTAssertEqual(ErrorClassifier.classify(error), errorClass)
        }
    }

    func testCancellationIsRecognised() {
        XCTAssertEqual(ErrorClassifier.classify(CancellationError()), .cancelled)
        XCTAssertEqual(ErrorClassifier.classify(StoryEngineError.cancelled(jobID: UUID())), .cancelled)
    }

    func testUnusableJSONIsWorthOneMoreTry() {
        let error = StoryEngineError.malformedProviderResponse(operation: .outline, detail: "not json")
        XCTAssertEqual(ErrorClassifier.classify(error), .transient)
    }

    func testBudgetExhaustionIsNeverRetried() {
        let error = StoryEngineError.budgetExhausted(BudgetShortfall(limit: .tokens, requested: 10, remaining: 0))
        XCTAssertEqual(ErrorClassifier.classify(error), .permanent)
    }

    func testUnknownErrorsArePermanent() {
        struct Mystery: Error {}
        XCTAssertEqual(ErrorClassifier.classify(Mystery()), .permanent)
    }
}

final class RetryRunnerTests: XCTestCase {
    private func runner(_ clock: FixedClock, attempts: Int = 3) -> RetryRunner {
        RetryRunner(
            policy: RetryPolicy(maximumAttempts: attempts, initialBackoff: 1, multiplier: 2, maximumBackoff: 8),
            clock: clock,
            idGenerator: SequentialIDGenerator()
        )
    }

    func testSuccessOnFirstTryRecordsOneAttempt() async throws {
        let clock = FixedClock(autoAdvance: 1)
        let outcome = try await runner(clock).run(stage: .planStory) { ("ok", nil) }

        XCTAssertEqual(outcome.value, "ok")
        XCTAssertEqual(outcome.attempts.count, 1)
        XCTAssertTrue(outcome.attempts[0].outcome.isSuccess)
        XCTAssertEqual(outcome.attempts[0].attemptNumber, 1)
        XCTAssertTrue(clock.sleeps.isEmpty, "No failure, no backoff")
    }

    func testTransientFailureIsRetriedToSuccess() async throws {
        let clock = FixedClock(autoAdvance: 1)
        let counter = Counter()

        let outcome = try await runner(clock).run(stage: .draftNarrative) {
            let attempt = await counter.increment()
            if attempt < 3 {
                throw StoryEngineError.providerFailed(operation: .narrativeDraft, errorClass: .transient, message: "flaky")
            }
            return ("written", nil)
        }

        XCTAssertEqual(outcome.value, "written")
        XCTAssertEqual(outcome.attempts.count, 3, "One attempt recorded per try, failures included")
        XCTAssertFalse(outcome.attempts[0].outcome.isSuccess)
        XCTAssertTrue(outcome.attempts[2].outcome.isSuccess)
        XCTAssertEqual(clock.sleeps, [1, 2], "Backoff doubles between tries")
    }

    func testPermanentFailureStopsImmediately() async {
        let clock = FixedClock(autoAdvance: 1)
        let counter = Counter()

        do {
            _ = try await runner(clock).run(stage: .planStory) { () -> (String, AIUsage?) in
                _ = await counter.increment()
                throw StoryEngineError.providerFailed(operation: .outline, errorClass: .permanent, message: "rejected")
            }
            XCTFail("Expected failure")
        } catch let failure as RetryFailure {
            XCTAssertEqual(failure.attempts.count, 1, "A rejection is not worth repeating")
            XCTAssertTrue(clock.sleeps.isEmpty)
        } catch {
            XCTFail("Unexpected error \(error)")
        }

        let calls = await counter.value
        XCTAssertEqual(calls, 1)
    }

    func testExhaustingAttemptsReportsEveryTry() async {
        let clock = FixedClock(autoAdvance: 1)
        do {
            _ = try await runner(clock, attempts: 3).run(stage: .generateImages) { () -> (String, AIUsage?) in
                throw StoryEngineError.providerFailed(operation: .imageGeneration, errorClass: .transient, message: "down")
            }
            XCTFail("Expected failure")
        } catch let failure as RetryFailure {
            XCTAssertEqual(failure.attempts.count, 3)
            XCTAssertEqual(failure.stage, .generateImages)
            guard case .retriesExhausted(let stage, let attempts, _) = failure.engineError else {
                return XCTFail("Expected retriesExhausted")
            }
            XCTAssertEqual(stage, .generateImages)
            XCTAssertEqual(attempts, 3)
            XCTAssertEqual(clock.sleeps, [1, 2], "No sleep after the final attempt")
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testUsageIsAttachedToTheAttemptThatProducedIt() async throws {
        let clock = FixedClock(autoAdvance: 1)
        let usage = AIUsage(provider: "p", model: "m", operation: .outline, inputTokens: 10, requestID: "req-1", recordedAt: clock.now())
        let outcome = try await runner(clock).run(stage: .planStory) { ("ok", usage) }

        XCTAssertEqual(outcome.attempts[0].usage, usage)
        XCTAssertEqual(outcome.attempts[0].providerRequestID, "req-1")
    }

    func testCancellationShortCircuitsRetries() async {
        let clock = FixedClock(autoAdvance: 1)
        do {
            _ = try await runner(clock).run(stage: .planStory) { () -> (String, AIUsage?) in
                throw CancellationError()
            }
            XCTFail("Expected failure")
        } catch let failure as RetryFailure {
            XCTAssertEqual(failure.attempts.count, 1)
            if case .cancelled = failure.attempts[0].outcome {} else {
                XCTFail("Attempt should be recorded as cancelled")
            }
            XCTAssertTrue(clock.sleeps.isEmpty)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testAttemptsCarryTimestamps() async throws {
        let clock = FixedClock(autoAdvance: 5)
        let outcome = try await runner(clock).run(stage: .planStory) { ("ok", nil) }
        XCTAssertEqual(outcome.attempts[0].duration, 5, accuracy: 0.001)
    }
}

/// Async-safe call counter for the retry tests.
actor Counter {
    private(set) var value = 0
    func increment() -> Int {
        value += 1
        return value
    }
}
