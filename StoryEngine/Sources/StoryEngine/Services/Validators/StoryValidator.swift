import Foundation
import CharacterEngine
import VisualSystem

/// Everything a validator is allowed to look at.
public struct ValidationContext: Sendable {
    public let story: Story
    public let template: ResolvedTemplate
    public let request: StoryRequest
    public let lexicon: DescriptorLexicon

    public init(story: Story, template: ResolvedTemplate, request: StoryRequest, lexicon: DescriptorLexicon? = nil) {
        self.story = story
        self.template = template
        self.request = request
        self.lexicon = lexicon ?? DescriptorLexicon.builtIn(languageCode: request.languageCode)
    }

    public var rules: ValidationRules { template.template.validationRules }
    public var ageBand: AgeBandRule? { rules.ageBand(for: request.ageYears) }
    public var orderedPages: [StoryPage] { story.pages.sorted { $0.index < $1.index } }
}

/// A check that needs nothing but the story in front of it.
public protocol DeterministicValidator: Sendable {
    var id: String { get }
    func validate(_ context: ValidationContext) -> [ValidationIssue]
}

/// A check that asks a language model. Costs money, so it can be skipped.
public protocol SemanticValidator: Sendable {
    var id: String { get }
    func validate(_ context: ValidationContext, using service: StoryAIService) async throws -> [ValidationIssue]
}

/// Runs the validators a template asks for and collects their verdicts.
///
/// Two properties matter here. Publication is blocked by errors only, so a
/// warning never holds a book hostage. And a validator that could not run is
/// recorded as `.skipped` — a semantic check that was unaffordable must never
/// be indistinguishable from one that passed.
public struct StoryValidator: Sendable {
    private let deterministic: [DeterministicValidator]
    private let semantic: [SemanticValidator]
    private let clock: Clock

    public init(
        deterministic: [DeterministicValidator]? = nil,
        semantic: [SemanticValidator]? = nil,
        clock: Clock = SystemClock()
    ) {
        self.deterministic = deterministic ?? [
            StructuralValidator(),
            RepetitionValidator(),
            CharacterConsistencyValidator(),
            AgeAppropriatenessValidator(),
            VisualSafetyValidator(),
            GeneratedImageValidator()
        ]
        self.semantic = semantic ?? [
            NarrativeConsistencyValidator(),
            SceneTextAlignmentValidator()
        ]
        self.clock = clock
    }

    public func validate(_ context: ValidationContext, aiService: StoryAIService? = nil) async -> StoryValidationResult {
        var reports: [ValidatorReport] = []
        let enabled = Set(context.rules.enabledValidators)
        let policy = context.template.template.generationPolicy

        for validator in deterministic {
            guard enabled.contains(validator.id) else {
                reports.append(ValidatorReport(validatorID: validator.id, outcome: .skipped(reason: "disabled by template"), issues: []))
                continue
            }
            reports.append(
                ValidatorReport(
                    validatorID: validator.id,
                    outcome: .ran,
                    issues: validator.validate(context).stamped(with: validator.id)
                )
            )
        }

        for validator in semantic {
            guard enabled.contains(validator.id) else {
                reports.append(ValidatorReport(validatorID: validator.id, outcome: .skipped(reason: "disabled by template"), issues: []))
                continue
            }
            guard policy.semanticValidationEnabled else {
                reports.append(ValidatorReport(validatorID: validator.id, outcome: .skipped(reason: "semantic validation disabled"), issues: []))
                continue
            }
            guard let aiService else {
                reports.append(ValidatorReport(validatorID: validator.id, outcome: .skipped(reason: "no AI service available"), issues: []))
                continue
            }
            let estimate = UsageEstimate(operation: .semanticValidation, tokens: 4_000, costUSD: 0.01)
            guard await aiService.canAfford(estimate) else {
                reports.append(ValidatorReport(validatorID: validator.id, outcome: .skipped(reason: "budget exhausted"), issues: []))
                continue
            }

            do {
                let issues = try await validator.validate(context, using: aiService)
                // Advisory unless the template says otherwise. A model's opinion
                // about pacing should not be able to block a parent's book.
                let adjusted = policy.semanticIssuesAreBlocking
                    ? issues
                    : issues.map { issue in
                        ValidationIssue(
                            validatorID: issue.validatorID,
                            code: issue.code,
                            severity: issue.severity == .error ? .warning : issue.severity,
                            scope: issue.scope,
                            message: issue.message
                        )
                    }
                reports.append(ValidatorReport(validatorID: validator.id, outcome: .ran, issues: adjusted))
            } catch {
                reports.append(
                    ValidatorReport(
                        validatorID: validator.id,
                        outcome: .failed(reason: String(describing: error)),
                        issues: []
                    )
                )
            }
        }

        return StoryValidationResult(reports: reports, validatedAt: clock.now())
    }
}


extension Array where Element == ValidationIssue {
    /// Deterministic validators build issues without naming themselves; the
    /// runner stamps its id on, so there is one place that can be wrong.
    func stamped(with validatorID: String) -> [ValidationIssue] {
        map { issue in
            guard issue.validatorID.isEmpty else { return issue }
            return ValidationIssue(
                validatorID: validatorID,
                code: issue.code,
                severity: issue.severity,
                scope: issue.scope,
                message: issue.message
            )
        }
    }
}
