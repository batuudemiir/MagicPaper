import Foundation

public enum ValidationSeverity: String, Codable, Sendable, Hashable, CaseIterable, Comparable {
    case info
    case warning
    case error

    private var rank: Int {
        switch self {
        case .info: return 0
        case .warning: return 1
        case .error: return 2
        }
    }
    public static func < (lhs: ValidationSeverity, rhs: ValidationSeverity) -> Bool { lhs.rank < rhs.rank }
}

/// What part of the book an issue is about.
public enum ValidationScope: Codable, Sendable, Hashable {
    case story
    case page(UUID)
    case scene(UUID)
    case visualAsset(UUID)
}

public struct ValidationIssue: Codable, Sendable, Hashable {
    public let validatorID: String
    public let code: String
    public let severity: ValidationSeverity
    public let scope: ValidationScope
    public let message: String

    public init(validatorID: String, code: String, severity: ValidationSeverity, scope: ValidationScope, message: String) {
        self.validatorID = validatorID
        self.code = code
        self.severity = severity
        self.scope = scope
        self.message = message
    }
}

/// Whether a validator actually ran.
///
/// A skipped semantic check must never be mistaken for a passed one, so this is
/// recorded explicitly rather than inferred from an empty issue list.
public enum ValidatorOutcome: Codable, Sendable, Hashable {
    case ran
    case skipped(reason: String)
    case failed(reason: String)

    public var didRun: Bool { if case .ran = self { return true } else { return false } }
}

public struct ValidatorReport: Codable, Sendable, Hashable {
    public let validatorID: String
    public let outcome: ValidatorOutcome
    public let issues: [ValidationIssue]

    public init(validatorID: String, outcome: ValidatorOutcome, issues: [ValidationIssue]) {
        self.validatorID = validatorID
        self.outcome = outcome
        self.issues = issues
    }
}

public struct StoryValidationResult: Codable, Sendable, Hashable {
    public let reports: [ValidatorReport]
    public let validatedAt: Date

    public init(reports: [ValidatorReport], validatedAt: Date) {
        self.reports = reports
        self.validatedAt = validatedAt
    }

    public var issues: [ValidationIssue] { reports.flatMap(\.issues) }
    public var errors: [ValidationIssue] { issues.filter { $0.severity == .error } }
    public var warnings: [ValidationIssue] { issues.filter { $0.severity == .warning } }

    /// Publication requires no errors. Warnings are informational.
    public var isValid: Bool { errors.isEmpty }

    public var skippedValidatorIDs: [String] {
        reports.compactMap { report in
            if case .skipped = report.outcome { return report.validatorID }
            return nil
        }
    }

    public func issues(for scope: ValidationScope) -> [ValidationIssue] {
        issues.filter { $0.scope == scope }
    }

    public static func empty(at date: Date) -> StoryValidationResult {
        StoryValidationResult(reports: [], validatedAt: date)
    }
}
