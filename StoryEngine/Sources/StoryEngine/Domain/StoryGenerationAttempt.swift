import Foundation

public enum AttemptOutcome: Codable, Sendable, Hashable {
    case success
    case failure(errorClass: ErrorClass, message: String)
    case cancelled

    public var isSuccess: Bool { if case .success = self { return true } else { return false } }
}

/// One try at one stage. Recorded whether it worked or not, so a story's
/// history shows what was retried and what it cost.
public struct StoryGenerationAttempt: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public let stage: JobStage
    public let attemptNumber: Int
    public let startedAt: Date
    public let finishedAt: Date
    public let outcome: AttemptOutcome
    public let usage: AIUsage?
    public let providerRequestID: String?

    public init(
        id: UUID,
        stage: JobStage,
        attemptNumber: Int,
        startedAt: Date,
        finishedAt: Date,
        outcome: AttemptOutcome,
        usage: AIUsage? = nil,
        providerRequestID: String? = nil
    ) {
        self.id = id
        self.stage = stage
        self.attemptNumber = attemptNumber
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.outcome = outcome
        self.usage = usage
        self.providerRequestID = providerRequestID
    }

    public var duration: TimeInterval { finishedAt.timeIntervalSince(startedAt) }
}
