import Foundation
import CharacterEngine

/// Applies the child safety policy at the points where it can still act.
///
/// Composition, not duplication: the input check is the only new inspection
/// here, and the publication gate reads verdicts the existing validators already
/// produced. What this adds is that the policy — not each validator's private
/// opinion — decides what is allowed through.
public struct ChildSafetyGate: Sendable {
    private let policy: ChildSafetyPolicy

    public init(policy: ChildSafetyPolicy) {
        self.policy = policy
    }

    // MARK: - Input

    /// Checks what a parent typed, before anything is paid for.
    ///
    /// The cheapest gate in the pipeline and the only one that can prevent
    /// spend rather than waste it.
    public func checkInput(request: StoryRequest, template: StoryTemplate) -> [ValidationIssue] {
        guard policy.inputPolicy != .off else { return [] }

        let lexiconLanguage = DescriptorLexicon.builtIn(languageCode: request.languageCode)
        let candidates = [request.themeKey, request.toneKey].compactMap { $0 }
        var issues: [ValidationIssue] = []

        for text in candidates {
            let normalized = DescriptorNormalization.normalize(text)
            for phrase in template.validationRules.bannedPhrases {
                let needle = DescriptorNormalization.normalize(phrase)
                guard DescriptorLexicon.contains(
                    phrase: needle, in: normalized, allowingSuffix: lexiconLanguage.allowsSuffixAttachment
                ) else { continue }
                issues.append(
                    ValidationIssue(
                        validatorID: ValidatorID.inputSafety,
                        code: "unsafe_input",
                        severity: policy.inputPolicy.severity,
                        scope: .story,
                        message: "The requested \"\(text)\" contains \"\(phrase)\", which is not allowed in a children's story."
                    )
                )
            }
        }

        if request.ageYears < template.constraints.supportedAgeRange.lowerBound
            || request.ageYears > template.constraints.supportedAgeRange.upperBound {
            issues.append(
                ValidationIssue(
                    validatorID: ValidatorID.inputSafety,
                    code: "age_outside_template",
                    severity: policy.inputPolicy.severity,
                    scope: .story,
                    message: "Age \(request.ageYears) is outside what this template is written for."
                )
            )
        }

        return issues
    }

    /// Whether input problems should stop the generation before it starts.
    public func shouldRefuseInput(_ issues: [ValidationIssue]) -> Bool {
        policy.inputPolicy == .blocking && issues.contains { $0.severity == .error }
    }

    // MARK: - Publication

    /// The last gate. Decides whether a validated story may be read.
    ///
    /// A safety-critical finding blocks regardless of the severity the
    /// validator gave it: an advisory text policy means "do not block on
    /// clumsy prose", never "publish a banned phrase".
    public func publicationDecision(for validation: StoryValidationResult) -> PublicationDecision {
        guard policy.publicationPolicy != .off else {
            return PublicationDecision(isAllowed: true, blockingIssues: [], unexaminedValidatorIDs: [])
        }

        var blocking = validation.errors

        let safetyFindings = validation.issues.filter { issue in
            issue.severity != .info
                && (ChildSafetyPolicy.safetyCriticalCodes.contains(issue.code)
                    || (ChildSafetyPolicy.safetyCriticalValidatorIDs.contains(issue.validatorID) && issue.severity == .error))
        }

        for finding in safetyFindings where !blocking.contains(finding) {
            blocking.append(finding)
        }

        // A safety-critical validator that never ran leaves the book
        // unexamined. Under a blocking policy that is itself a reason to stop.
        let unexamined = validation.reports
            .filter { report in
                ChildSafetyPolicy.safetyCriticalValidatorIDs.contains(report.validatorID) && !report.outcome.didRun
            }
            .map(\.validatorID)

        let isAllowed: Bool
        if policy.publicationPolicy == .blocking {
            isAllowed = blocking.isEmpty && unexamined.isEmpty
        } else {
            isAllowed = validation.errors.isEmpty
        }

        return PublicationDecision(
            isAllowed: isAllowed,
            blockingIssues: blocking,
            unexaminedValidatorIDs: unexamined
        )
    }

    /// Severity floor for text findings under this policy.
    public func textSeverity(default severity: ValidationSeverity) -> ValidationSeverity {
        switch policy.textPolicy {
        case .off: return .info
        case .advisory: return min(severity, .warning)
        case .blocking: return severity
        }
    }

    /// Severity floor for image findings under this policy.
    public func imageSeverity(default severity: ValidationSeverity) -> ValidationSeverity {
        switch policy.imagePolicy {
        case .off: return .info
        case .advisory: return min(severity, .warning)
        case .blocking: return severity
        }
    }
}

/// Why a book may or may not be published.
public struct PublicationDecision: Sendable, Hashable {
    public let isAllowed: Bool
    public let blockingIssues: [ValidationIssue]
    /// Safety-critical checks that never ran. Under a blocking policy these
    /// stop publication just as a failure would.
    public let unexaminedValidatorIDs: [String]

    public init(isAllowed: Bool, blockingIssues: [ValidationIssue], unexaminedValidatorIDs: [String]) {
        self.isAllowed = isAllowed
        self.blockingIssues = blockingIssues
        self.unexaminedValidatorIDs = unexaminedValidatorIDs
    }

    public var reasonCodes: [String] {
        blockingIssues.map(\.code) + unexaminedValidatorIDs.map { "unexamined_\($0)" }
    }
}
