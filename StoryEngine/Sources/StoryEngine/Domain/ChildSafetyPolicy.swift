import Foundation

/// How strictly one stage of the pipeline is policed.
public enum SafetyLevel: String, Codable, Sendable, Hashable, CaseIterable, Comparable {
    /// No checking at this stage.
    case off
    /// Check and report; findings do not stop the book.
    case advisory
    /// Check and enforce; findings stop the book.
    case blocking

    private var rank: Int {
        switch self {
        case .off: return 0
        case .advisory: return 1
        case .blocking: return 2
        }
    }
    public static func < (lhs: SafetyLevel, rhs: SafetyLevel) -> Bool { lhs.rank < rhs.rank }

    /// The severity a finding at this level carries.
    public var severity: ValidationSeverity {
        switch self {
        case .off: return .info
        case .advisory: return .warning
        case .blocking: return .error
        }
    }
}

/// Child safety as one readable policy rather than a property of five validators.
///
/// The validators still do the work — this does not duplicate them. What it adds
/// is a single place that answers "what is this product willing to publish", so
/// that raising the bar is one edit rather than an audit of every check.
///
/// Four gates, because they fail differently: bad input should be refused before
/// a single token is paid for; bad text and bad images are caught mid-pipeline;
/// and publication is the last line, where anything still outstanding decides
/// whether a child sees the book.
public struct ChildSafetyPolicy: Codable, Sendable, Hashable {
    /// What a parent typed: theme, tone, custom prompt.
    public let inputPolicy: SafetyLevel
    /// The generated narrative and page text.
    public let textPolicy: SafetyLevel
    /// The visual prompts and the produced illustrations.
    public let imagePolicy: SafetyLevel
    /// The final gate before a book can be read.
    public let publicationPolicy: SafetyLevel

    public init(
        inputPolicy: SafetyLevel = .blocking,
        textPolicy: SafetyLevel = .blocking,
        imagePolicy: SafetyLevel = .blocking,
        publicationPolicy: SafetyLevel = .blocking
    ) {
        self.inputPolicy = inputPolicy
        self.textPolicy = textPolicy
        self.imagePolicy = imagePolicy
        self.publicationPolicy = publicationPolicy
    }

    /// The default for a children's product: everything blocks.
    public static let strict = ChildSafetyPolicy()

    /// Everything is reported, nothing is blocked. For development only — a
    /// build shipping this is a build that will publish whatever it is given.
    public static let permissive = ChildSafetyPolicy(
        inputPolicy: .advisory, textPolicy: .advisory, imagePolicy: .advisory, publicationPolicy: .advisory
    )

    /// Which validator ids this policy considers safety-critical.
    ///
    /// These are the checks whose findings the publication gate refuses to
    /// waive, whatever severity the validator itself assigned.
    public static let safetyCriticalValidatorIDs: Set<String> = [
        ValidatorID.ageAppropriateness,
        ValidatorID.visualSafety,
        ValidatorID.characterConsistency,
        ValidatorID.generatedImage
    ]

    /// Codes that always represent a safety problem rather than a quality one.
    public static let safetyCriticalCodes: Set<String> = [
        "banned_phrase",
        "do_not_depict",
        "do_not_depict_not_excluded",
        "forbidden_clause_requested",
        "missing_negative_clauses",
        "image_validation_failed",
        "invented_appearance",
        "invented_appearance_in_prompt"
    ]
}
