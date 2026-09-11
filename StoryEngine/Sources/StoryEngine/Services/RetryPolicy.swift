import Foundation

/// Decides whether a failed call is worth trying again, and how long to wait.
///
/// Backoff is deterministic — no jitter — because a test that has to tolerate
/// randomness stops being a test of the backoff. Adapters that need jitter can
/// add it at their own layer, where it belongs.
public struct RetryPolicy: Sendable {
    public let maximumAttempts: Int
    public let initialBackoff: TimeInterval
    public let multiplier: Double
    public let maximumBackoff: TimeInterval
    /// Rate limiting is retried more patiently than a plain timeout.
    public let rateLimitMultiplier: Double

    public init(
        maximumAttempts: Int = 3,
        initialBackoff: TimeInterval = 0.5,
        multiplier: Double = 2.0,
        maximumBackoff: TimeInterval = 8.0,
        rateLimitMultiplier: Double = 3.0
    ) {
        self.maximumAttempts = max(1, maximumAttempts)
        self.initialBackoff = initialBackoff
        self.multiplier = multiplier
        self.maximumBackoff = maximumBackoff
        self.rateLimitMultiplier = rateLimitMultiplier
    }

    public init(policy: GenerationPolicy) {
        self.init(
            maximumAttempts: policy.maximumAttemptsPerStage,
            initialBackoff: policy.initialBackoff,
            multiplier: policy.backoffMultiplier,
            maximumBackoff: policy.maximumBackoff
        )
    }

    public func shouldRetry(_ errorClass: ErrorClass, attemptNumber: Int) -> Bool {
        guard attemptNumber < maximumAttempts else { return false }
        switch errorClass {
        case .transient, .rateLimited: return true
        case .permanent, .cancelled: return false
        }
    }

    /// Delay before attempt `attemptNumber + 1`.
    public func backoff(afterAttempt attemptNumber: Int, errorClass: ErrorClass) -> TimeInterval {
        guard attemptNumber >= 1 else { return 0 }
        let exponent = Double(attemptNumber - 1)
        let base = initialBackoff * pow(multiplier, exponent)
        let scaled = errorClass == .rateLimited ? base * rateLimitMultiplier : base
        return min(scaled, maximumBackoff)
    }
}

/// Classifies an error into the four cases the policy understands.
public enum ErrorClassifier {
    public static func classify(_ error: Error) -> ErrorClass {
        if error is CancellationError { return .cancelled }
        guard let engineError = error as? StoryEngineError else { return .permanent }
        switch engineError {
        case .providerFailed(_, let errorClass, _): return errorClass
        case .cancelled: return .cancelled
        case .malformedProviderResponse:
            // A model that returned unusable JSON may well return usable JSON
            // next time; this is the one parse failure worth a retry.
            return .transient
        case .budgetExhausted: return .permanent
        default: return .permanent
        }
    }
}

/// Runs an operation under a retry policy, recording one attempt per try.
public struct RetryRunner: Sendable {
    private let policy: RetryPolicy
    private let clock: Clock
    private let idGenerator: IDGenerator

    public init(policy: RetryPolicy, clock: Clock, idGenerator: IDGenerator = RandomIDGenerator()) {
        self.policy = policy
        self.clock = clock
        self.idGenerator = idGenerator
    }

    /// The result of a run: the value, plus every attempt it took.
    public struct Outcome<Value: Sendable>: Sendable {
        public let value: Value
        public let attempts: [StoryGenerationAttempt]
    }

    public func run<Value: Sendable>(
        stage: JobStage,
        operation: @Sendable () async throws -> (Value, AIUsage?)
    ) async throws -> Outcome<Value> {
        var attempts: [StoryGenerationAttempt] = []
        var attemptNumber = 0
        var lastError: Error?

        while attemptNumber < policy.maximumAttempts {
            attemptNumber += 1
            try Task.checkCancellation()
            let startedAt = clock.now()

            do {
                let (value, usage) = try await operation()
                attempts.append(
                    StoryGenerationAttempt(
                        id: idGenerator.next(),
                        stage: stage,
                        attemptNumber: attemptNumber,
                        startedAt: startedAt,
                        finishedAt: clock.now(),
                        outcome: .success,
                        usage: usage,
                        providerRequestID: usage?.requestID
                    )
                )
                return Outcome(value: value, attempts: attempts)
            } catch {
                let errorClass = ErrorClassifier.classify(error)
                lastError = error
                attempts.append(
                    StoryGenerationAttempt(
                        id: idGenerator.next(),
                        stage: stage,
                        attemptNumber: attemptNumber,
                        startedAt: startedAt,
                        finishedAt: clock.now(),
                        outcome: errorClass == .cancelled
                            ? .cancelled
                            : .failure(errorClass: errorClass, message: String(describing: error))
                    )
                )

                guard policy.shouldRetry(errorClass, attemptNumber: attemptNumber) else { break }
                try await clock.sleep(for: policy.backoff(afterAttempt: attemptNumber, errorClass: errorClass))
            }
        }

        throw RetryFailure(
            stage: stage,
            attempts: attempts,
            underlying: lastError ?? StoryEngineError.retriesExhausted(stage: stage, attempts: attemptNumber, message: "unknown")
        )
    }
}

/// Carries the attempt history out of a failed run so the job can record it.
public struct RetryFailure: Error, Sendable {
    public let stage: JobStage
    public let attempts: [StoryGenerationAttempt]
    public let underlying: Error

    public init(stage: JobStage, attempts: [StoryGenerationAttempt], underlying: Error) {
        self.stage = stage
        self.attempts = attempts
        self.underlying = underlying
    }

    public var engineError: StoryEngineError {
        if let error = underlying as? StoryEngineError, case .cancelled = error { return error }
        return .retriesExhausted(
            stage: stage,
            attempts: attempts.count,
            message: (underlying as? StoryEngineError)?.description ?? String(describing: underlying)
        )
    }
}
