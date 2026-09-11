import Foundation
import EngineFoundation
import CharacterEngine
import VisualSystem

/// Why a provider call failed, from the engine's point of view.
///
/// This is what `RetryPolicy` switches on, so adapters must map their vendor's
/// errors onto it rather than letting a URLError leak through: whether a retry
/// is worth attempting is a decision the adapter is best placed to make.
public enum ErrorClass: String, Codable, Sendable, Hashable, CaseIterable {
    /// Worth retrying: timeouts, 5xx, dropped connections.
    case transient
    /// Worth retrying, but slowly.
    case rateLimited
    /// Never worth retrying: bad request, refusal, unparseable output.
    case permanent
    /// The caller asked to stop.
    case cancelled
}

public enum StoryEngineError: Error, Equatable, Sendable {
    case templateNotFound(String)
    case noCompatibleTemplate(id: String, requirement: VersionRequirement)
    case unsupportedPageCount(requested: Int, supported: ClosedRange<Int>)
    case unsupportedAgeBand(age: Int)
    case unsupportedLanguage(String)
    case templateHasNoBeats(String)

    case storyNotFound(UUID)
    case pageNotFound(UUID)
    case sceneNotFound(UUID)
    case visualAssetNotFound(UUID)
    case jobNotFound(UUID)

    case storyIsPublished(UUID)
    case validationFailed([String])
    /// What the parent asked for is not something this product will write.
    case unsafeInput([String])
    /// The finished book did not clear the child safety gate.
    case blockedByChildSafety([String])

    case budgetExhausted(BudgetShortfall)
    case providerFailed(operation: AIOperation, errorClass: ErrorClass, message: String)
    case retriesExhausted(stage: JobStage, attempts: Int, message: String)
    case malformedProviderResponse(operation: AIOperation, detail: String)

    case cancelled(jobID: UUID)
    case stageOutOfOrder(expected: JobStage, actual: JobStage)
    case notResumable(jobID: UUID, state: JobState)

    case character(CharacterEngineError)
    case visual(VisualSystemError)
}

/// Which ceiling a request would have crossed, and by how much.
public struct BudgetShortfall: Codable, Sendable, Hashable {
    public enum Limit: String, Codable, Sendable, Hashable {
        case languageModelCalls
        case imageCalls
        case tokens
        case costUSD
    }

    public let limit: Limit
    public let requested: Double
    public let remaining: Double

    public init(limit: Limit, requested: Double, remaining: Double) {
        self.limit = limit
        self.requested = requested
        self.remaining = remaining
    }
}

extension StoryEngineError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .templateNotFound(let id): return "No story template '\(id)'."
        case .noCompatibleTemplate(let id, let requirement):
            return "No version of template '\(id)' satisfies \(requirement)."
        case .unsupportedPageCount(let requested, let supported):
            return "Template supports \(supported.lowerBound)–\(supported.upperBound) pages, not \(requested)."
        case .unsupportedAgeBand(let age): return "Template has no guidance for age \(age)."
        case .unsupportedLanguage(let code): return "Template does not support language '\(code)'."
        case .templateHasNoBeats(let id): return "Template '\(id)' declares no narrative beats."
        case .storyNotFound(let id): return "No story \(id)."
        case .pageNotFound(let id): return "No page \(id)."
        case .sceneNotFound(let id): return "No scene \(id)."
        case .visualAssetNotFound(let id): return "No visual asset \(id)."
        case .jobNotFound(let id): return "No generation job \(id)."
        case .storyIsPublished(let id):
            return "Story \(id) is published; only explicit regeneration may change it."
        case .validationFailed(let codes): return "Validation failed: \(codes.joined(separator: ", "))."
        case .unsafeInput(let codes):
            return "The request was refused on safety grounds: \(codes.joined(separator: ", "))."
        case .blockedByChildSafety(let codes):
            return "Child safety blocked publication: \(codes.joined(separator: ", "))."
        case .budgetExhausted(let shortfall):
            return "Budget exhausted: \(shortfall.limit.rawValue) needs \(shortfall.requested), \(shortfall.remaining) left."
        case .providerFailed(let operation, let errorClass, let message):
            return "\(operation.rawValue) failed (\(errorClass.rawValue)): \(message)"
        case .retriesExhausted(let stage, let attempts, let message):
            return "Stage \(stage.rawValue) failed after \(attempts) attempts: \(message)"
        case .malformedProviderResponse(let operation, let detail):
            return "Unusable \(operation.rawValue) response: \(detail)"
        case .cancelled(let id): return "Job \(id) was cancelled."
        case .stageOutOfOrder(let expected, let actual):
            return "Expected stage \(expected.rawValue), got \(actual.rawValue)."
        case .notResumable(let id, let state):
            return "Job \(id) is \(state.rawValue) and cannot be resumed."
        case .character(let error): return error.description
        case .visual(let error): return error.description
        }
    }
}
