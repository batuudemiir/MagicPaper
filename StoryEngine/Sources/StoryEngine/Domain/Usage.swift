import Foundation

/// What an AI call was for. Budgets and validators reason in these terms
/// rather than in vendor endpoints.
public enum AIOperation: String, Codable, Sendable, CaseIterable, Hashable {
    case outline
    case narrativeDraft
    case pageRefinement
    case semanticValidation
    case imageGeneration
    /// Inspecting an image that was already produced, to check it matches what
    /// was asked for. Billable, so it is an operation like any other.
    case imageValidation
}

/// The cost and shape of a single provider call.
///
/// Every provider response carries one. Nothing in the engine may call a
/// provider without recording this — that is what makes spend auditable per
/// story instead of per month.
public struct AIUsage: Codable, Sendable, Hashable {
    public let provider: String
    public let model: String
    public let operation: AIOperation
    public let inputTokens: Int
    public let outputTokens: Int
    public let imageCount: Int
    public let estimatedCostUSD: Double
    public let latency: TimeInterval
    public let requestID: String?
    public let recordedAt: Date

    public init(
        provider: String,
        model: String,
        operation: AIOperation,
        inputTokens: Int = 0,
        outputTokens: Int = 0,
        imageCount: Int = 0,
        estimatedCostUSD: Double = 0,
        latency: TimeInterval = 0,
        requestID: String? = nil,
        recordedAt: Date
    ) {
        self.provider = provider
        self.model = model
        self.operation = operation
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.imageCount = imageCount
        self.estimatedCostUSD = estimatedCostUSD
        self.latency = latency
        self.requestID = requestID
        self.recordedAt = recordedAt
    }

    /// Whether this call counts against the image ceiling rather than the
    /// language-model one. Validating an image is an inspection, not a
    /// generation, so it is budgeted with the text calls.
    public var isImageCall: Bool { operation == .imageGeneration }
}

/// Running totals for one story or one job.
public struct UsageLedger: Codable, Sendable, Hashable {
    public private(set) var records: [AIUsage]

    public init(records: [AIUsage] = []) { self.records = records }

    public mutating func record(_ usage: AIUsage) { records.append(usage) }

    public func recording(_ usage: AIUsage) -> UsageLedger {
        UsageLedger(records: records + [usage])
    }

    public var languageModelCallCount: Int { records.filter { !$0.isImageCall }.count }
    public var imageCallCount: Int { records.filter(\.isImageCall).count }
    public var totalImagesProduced: Int { records.reduce(0) { $0 + $1.imageCount } }
    public var totalInputTokens: Int { records.reduce(0) { $0 + $1.inputTokens } }
    public var totalOutputTokens: Int { records.reduce(0) { $0 + $1.outputTokens } }
    public var totalTokens: Int { totalInputTokens + totalOutputTokens }
    public var totalCostUSD: Double { records.reduce(0) { $0 + $1.estimatedCostUSD } }

    public func cost(of operation: AIOperation) -> Double {
        records.filter { $0.operation == operation }.reduce(0) { $0 + $1.estimatedCostUSD }
    }

    public func merging(_ other: UsageLedger) -> UsageLedger {
        UsageLedger(records: records + other.records)
    }
}

/// Ceilings for one story. Exceeding any of them stops generation before the
/// next provider call, never after it.
public struct GenerationBudget: Codable, Sendable, Hashable {
    public let maximumLanguageModelCalls: Int
    public let maximumImageCalls: Int
    public let maximumTokens: Int
    public let maximumCostUSD: Double

    public init(
        maximumLanguageModelCalls: Int,
        maximumImageCalls: Int,
        maximumTokens: Int,
        maximumCostUSD: Double
    ) {
        self.maximumLanguageModelCalls = maximumLanguageModelCalls
        self.maximumImageCalls = maximumImageCalls
        self.maximumTokens = maximumTokens
        self.maximumCostUSD = maximumCostUSD
    }

    /// Roomy enough for a normal illustrated book; a template's generation
    /// policy narrows it.
    public static let standard = GenerationBudget(
        maximumLanguageModelCalls: 24,
        maximumImageCalls: 16,
        maximumTokens: 200_000,
        maximumCostUSD: 2.50
    )

    /// Text only, no illustrations.
    public static let textOnly = GenerationBudget(
        maximumLanguageModelCalls: 12,
        maximumImageCalls: 0,
        maximumTokens: 80_000,
        maximumCostUSD: 0.40
    )
}

/// A caller's estimate of what a call will consume, checked before it is made.
public struct UsageEstimate: Sendable, Hashable {
    public let operation: AIOperation
    public let tokens: Int
    public let costUSD: Double
    public let imageCount: Int

    public init(operation: AIOperation, tokens: Int = 0, costUSD: Double = 0, imageCount: Int = 0) {
        self.operation = operation
        self.tokens = tokens
        self.costUSD = costUSD
        self.imageCount = imageCount
    }

    public var isImageCall: Bool { operation == .imageGeneration }
}
