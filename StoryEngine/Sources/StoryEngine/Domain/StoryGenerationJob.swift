import Foundation

/// The stages of a full generation, in order.
///
/// Listed as data rather than as control flow so a job can say where it got to,
/// and resume there, without the orchestrator re-deriving it.
public enum JobStage: String, Codable, Sendable, Hashable, CaseIterable, Comparable {
    case resolveTemplate
    case resolveCast
    case planStory
    case planScenes
    case planPages
    case draftNarrative
    case segmentPages
    case refinePages
    case planVisuals
    case generateImages
    case validateImages
    case validate
    case assemble

    public var order: Int { JobStage.allCases.firstIndex(of: self) ?? 0 }
    public static func < (lhs: JobStage, rhs: JobStage) -> Bool { lhs.order < rhs.order }

    public var next: JobStage? {
        let index = order + 1
        return index < JobStage.allCases.count ? JobStage.allCases[index] : nil
    }

    /// Stages that spend money. Used for budget pre-flight reporting.
    public var usesProvider: Bool {
        switch self {
        case .planStory, .draftNarrative, .refinePages, .generateImages, .validateImages, .validate: return true
        case .resolveTemplate, .resolveCast, .planPages, .segmentPages, .planScenes, .planVisuals, .assemble: return false
        }
    }
}

public enum StageStatus: String, Codable, Sendable, Hashable, CaseIterable {
    case pending
    case running
    case completed
    case failed
    case skipped
}

public struct JobStageState: Codable, Sendable, Hashable {
    public let stage: JobStage
    public var status: StageStatus
    public var attempts: [StoryGenerationAttempt]
    public var startedAt: Date?
    public var finishedAt: Date?
    public var lastErrorMessage: String?

    public init(
        stage: JobStage,
        status: StageStatus = .pending,
        attempts: [StoryGenerationAttempt] = [],
        startedAt: Date? = nil,
        finishedAt: Date? = nil,
        lastErrorMessage: String? = nil
    ) {
        self.stage = stage
        self.status = status
        self.attempts = attempts
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.lastErrorMessage = lastErrorMessage
    }

    public var attemptCount: Int { attempts.count }
    public var isTerminal: Bool { status == .completed || status == .skipped }
}

public enum JobState: String, Codable, Sendable, Hashable, CaseIterable {
    case queued
    case running
    case paused
    case cancelled
    case failed
    case completed

    /// Whether `resume` will accept this job. A running job is included because
    /// a process that died mid-stage leaves one behind, and that is exactly the
    /// case resumption exists for.
    public var isResumable: Bool {
        switch self {
        case .queued, .paused, .failed, .running: return true
        case .cancelled, .completed: return false
        }
    }
}

/// A generation in flight, persisted after every stage transition.
public struct StoryGenerationJob: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public let storyID: UUID
    public let requestID: UUID
    public private(set) var state: JobState
    public private(set) var stages: [JobStageState]
    public private(set) var usage: UsageLedger
    public private(set) var lastErrorMessage: String?
    public let createdAt: Date
    public private(set) var updatedAt: Date
    public let schemaVersion: Int

    public static let currentSchemaVersion = 1

    public init(
        id: UUID,
        storyID: UUID,
        requestID: UUID,
        state: JobState = .queued,
        stages: [JobStageState]? = nil,
        usage: UsageLedger = UsageLedger(),
        lastErrorMessage: String? = nil,
        createdAt: Date,
        updatedAt: Date? = nil,
        schemaVersion: Int = StoryGenerationJob.currentSchemaVersion
    ) {
        self.id = id
        self.storyID = storyID
        self.requestID = requestID
        self.state = state
        self.stages = stages ?? JobStage.allCases.map { JobStageState(stage: $0) }
        self.usage = usage
        self.lastErrorMessage = lastErrorMessage
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.schemaVersion = schemaVersion
    }

    // MARK: - Reading progress

    public func stageState(_ stage: JobStage) -> JobStageState? {
        stages.first { $0.stage == stage }
    }

    public func status(of stage: JobStage) -> StageStatus {
        stageState(stage)?.status ?? .pending
    }

    /// Where a resume picks up: the first stage not already finished.
    public var checkpoint: JobStage? {
        stages.first { !$0.isTerminal }?.stage
    }

    public var completedStages: [JobStage] {
        stages.filter { $0.status == .completed }.map(\.stage)
    }

    public var failedStage: JobStage? {
        stages.first { $0.status == .failed }?.stage
    }

    public var allAttempts: [StoryGenerationAttempt] { stages.flatMap(\.attempts) }

    public var progressFraction: Double {
        guard !stages.isEmpty else { return 0 }
        return Double(stages.filter(\.isTerminal).count) / Double(stages.count)
    }

    // MARK: - Transitions

    public func with(state newState: JobState, at date: Date, errorMessage: String? = nil) -> StoryGenerationJob {
        var copy = self
        copy.state = newState
        copy.updatedAt = date
        if let errorMessage { copy.lastErrorMessage = errorMessage }
        if newState == .running || newState == .completed { copy.lastErrorMessage = errorMessage }
        return copy
    }

    public func starting(_ stage: JobStage, at date: Date) -> StoryGenerationJob {
        updating(stage, at: date) { state in
            state.status = .running
            state.startedAt = state.startedAt ?? date
            state.lastErrorMessage = nil
        }
    }

    public func completing(_ stage: JobStage, at date: Date) -> StoryGenerationJob {
        updating(stage, at: date) { state in
            state.status = .completed
            state.finishedAt = date
            state.lastErrorMessage = nil
        }
    }

    public func skipping(_ stage: JobStage, at date: Date) -> StoryGenerationJob {
        updating(stage, at: date) { state in
            state.status = .skipped
            state.finishedAt = date
        }
    }

    public func failing(_ stage: JobStage, at date: Date, message: String) -> StoryGenerationJob {
        var copy = updating(stage, at: date) { state in
            state.status = .failed
            state.finishedAt = date
            state.lastErrorMessage = message
        }
        copy.state = .failed
        copy.lastErrorMessage = message
        return copy
    }

    public func recording(_ attempt: StoryGenerationAttempt, at date: Date) -> StoryGenerationJob {
        var copy = updating(attempt.stage, at: date) { state in
            state.attempts.append(attempt)
        }
        if let usage = attempt.usage {
            copy.usage = copy.usage.recording(usage)
        }
        return copy
    }

    /// Clears a failed stage so it can be tried again, leaving its attempt
    /// history intact.
    public func resettingFailedStage(at date: Date) -> StoryGenerationJob {
        guard let stage = failedStage else { return self }
        var copy = updating(stage, at: date) { state in
            state.status = .pending
            state.finishedAt = nil
        }
        copy.state = .queued
        copy.lastErrorMessage = nil
        return copy
    }

    private func updating(_ stage: JobStage, at date: Date, _ transform: (inout JobStageState) -> Void) -> StoryGenerationJob {
        var copy = self
        copy.updatedAt = date
        guard let index = copy.stages.firstIndex(where: { $0.stage == stage }) else { return copy }
        transform(&copy.stages[index])
        return copy
    }
}
