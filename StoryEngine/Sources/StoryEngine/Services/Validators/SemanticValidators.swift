import Foundation

// Semantic validators build their own requests rather than going through
// `PromptAssembler`. They are reading a finished story and reporting on it, not
// writing any part of it, so the appearance lockdown that every generative
// prompt carries does not apply — a proofreader has to be able to quote the
// text it is objecting to.

/// The shape every semantic validator asks the model for.
struct SemanticFindingsResponse: Codable {
    struct Finding: Codable {
        let pageIndex: Int?
        let code: String?
        let severity: String?
        let message: String
    }
    let findings: [Finding]
}

extension SemanticFindingsResponse.Finding {
    func severityValue(default fallback: ValidationSeverity) -> ValidationSeverity {
        guard let severity else { return fallback }
        return ValidationSeverity(rawValue: severity.lowercased()) ?? fallback
    }
}

/// Asks whether the book holds together: facts that contradict, setups that go
/// nowhere, pacing that collapses.
///
/// Deterministic checks cannot see any of this. A model can — imperfectly — so
/// its findings are advisory by default and the template decides whether to
/// promote them.
public struct NarrativeConsistencyValidator: SemanticValidator {
    public let id = ValidatorID.narrativeConsistency
    public init() {}

    public func validate(_ context: ValidationContext, using service: StoryAIService) async throws -> [ValidationIssue] {
        let pages = context.orderedPages
        guard pages.count > 1 else { return [] }

        let body = pages
            .map { "PAGE \($0.index): \($0.text)" }
            .joined(separator: "\n\n")

        let request = AICompletionRequest(
            operation: .semanticValidation,
            modelTier: context.template.template.generationPolicy.validationModelTier,
            systemInstructions: [
                """
                You are proofreading a children's picture book for continuity. Report only \
                concrete problems you can point at: a fact contradicted later, something set \
                up and never resolved, a character who acts against what was established, or \
                a jump that would confuse a child. Do not comment on style or taste. \
                If the book holds together, return an empty findings array.
                """
            ],
            userInstructions: [
                "TITLE: \(context.story.title)",
                body
            ],
            responseSchemaDescription: Self.schema,
            languageCode: context.request.languageCode,
            temperature: 0.2,
            identity: IdempotencyKeyFactory.semanticValidation(
                storyID: context.story.id, validatorID: id, contentHash: context.story.contentHash
            )
        )

        let result = try await service.complete(
            request,
            stage: .validate,
            estimate: UsageEstimate(operation: .semanticValidation, tokens: 4_000, costUSD: 0.01),
            decoding: SemanticFindingsResponse.self
        )

        return result.value.findings.map { finding in
            let page = finding.pageIndex.flatMap { index in pages.first { $0.index == index } }
            return ValidationIssue(
                validatorID: id,
                code: finding.code ?? "narrative_inconsistency",
                severity: finding.severityValue(default: .warning),
                scope: page.map { ValidationScope.page($0.id) } ?? .story,
                message: finding.message
            )
        }
    }

    static let schema = """
    { "findings": [ { "pageIndex": 0, "code": "short_snake_case", "severity": "warning", "message": "what is wrong" } ] }
    """
}

/// Asks whether each page's words match the picture beside them.
///
/// This is the "Deniz was frightened of the forest" over a sunny-beach
/// illustration case. Nothing deterministic can catch it: the text is fine, the
/// picture is fine, and only together are they wrong.
public struct SceneTextAlignmentValidator: SemanticValidator {
    public let id = ValidatorID.sceneTextAlignment
    public init() {}

    public func validate(_ context: ValidationContext, using service: StoryAIService) async throws -> [ValidationIssue] {
        let pages = context.orderedPages.filter { $0.requiresImage && $0.hasText }
        guard !pages.isEmpty else { return [] }

        let pairs = pages.compactMap { page -> String? in
            guard let scene = context.story.scene(id: page.sceneID) else { return nil }
            let illustration = [
                "setting: \(scene.visualContext.settingKey)",
                "time: \(scene.visualContext.timeOfDayKey)",
                "mood: \(scene.visualContext.moodKey)"
            ].joined(separator: ", ")
            return """
            PAGE \(page.index)
            ILLUSTRATION SHOWS: \(illustration)
            TEXT: \(page.text)
            """
        }.joined(separator: "\n\n")

        let request = AICompletionRequest(
            operation: .semanticValidation,
            modelTier: context.template.template.generationPolicy.validationModelTier,
            systemInstructions: [
                """
                Each page of this picture book has text and an illustration. Report any page \
                where the text and the illustration clearly disagree — the text says forest \
                and the illustration shows a beach, the text says night and the illustration \
                shows noon, the text describes fear and the illustration is cheerful. \
                Small differences of emphasis are fine; report only plain contradictions. \
                If every page agrees, return an empty findings array.
                """
            ],
            userInstructions: [pairs],
            responseSchemaDescription: NarrativeConsistencyValidator.schema,
            languageCode: context.request.languageCode,
            temperature: 0.2,
            identity: IdempotencyKeyFactory.semanticValidation(
                storyID: context.story.id, validatorID: id, contentHash: context.story.contentHash
            )
        )

        let result = try await service.complete(
            request,
            stage: .validate,
            estimate: UsageEstimate(operation: .semanticValidation, tokens: 4_000, costUSD: 0.01),
            decoding: SemanticFindingsResponse.self
        )

        return result.value.findings.map { finding in
            let page = finding.pageIndex.flatMap { index in pages.first { $0.index == index } }
            return ValidationIssue(
                validatorID: id,
                code: finding.code ?? "scene_text_mismatch",
                severity: finding.severityValue(default: .warning),
                scope: page.map { ValidationScope.page($0.id) } ?? .story,
                message: finding.message
            )
        }
    }
}
