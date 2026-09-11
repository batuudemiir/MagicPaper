import Foundation
import EngineFoundation
import VisualSystem

/// Picks the template a story will be generated from, and pins every version
/// in the chain.
///
/// Resolution order: candidates satisfying the version requirement, then the
/// template's own constraints, newest first. Each rejection has its own error,
/// because "no template matched" is useless to a caller trying to work out
/// whether they asked for too many pages or the wrong language.
public struct TemplateResolver: Sendable {
    private let repository: TemplateRepository
    private let visualResolver: VisualStyleResolver
    private let clock: Clock

    public init(repository: TemplateRepository, visualResolver: VisualStyleResolver = VisualStyleResolver(), clock: Clock = SystemClock()) {
        self.repository = repository
        self.visualResolver = visualResolver
        self.clock = clock
    }

    public func resolve(for request: StoryRequest) async throws -> ResolvedTemplate {
        let template = try await selectTemplate(for: request)
        let visualStyle: ResolvedVisualStyle
        do {
            visualStyle = try visualResolver.resolve(
                styleID: template.visualStyleID,
                requirement: template.visualStyleRequirement
            )
        } catch let error as VisualSystemError {
            throw StoryEngineError.visual(error)
        }

        let ref = TemplateRef(
            templateID: template.id,
            templateVersion: template.version,
            narrativeVersion: template.narrative.version,
            visualStyleID: visualStyle.preset.id,
            visualStylePins: visualStyle.versionPins,
            resolvedAt: clock.now()
        )
        return ResolvedTemplate(template: template, visualStyle: visualStyle, ref: ref)
    }

    private func selectTemplate(for request: StoryRequest) async throws -> StoryTemplate {
        // Ask only by id, so constraint rejections can be reported precisely.
        let anyVersion = try await repository.templates(
            matching: TemplateQuery(templateID: request.templateID, requirement: .latest)
        )
        guard !anyVersion.isEmpty else {
            throw StoryEngineError.templateNotFound(request.templateID)
        }

        let satisfyingVersion = anyVersion
            .filter { request.templateRequirement.isSatisfied(by: $0.version) }
            .sorted { $0.version > $1.version }
        guard !satisfyingVersion.isEmpty else {
            throw StoryEngineError.noCompatibleTemplate(
                id: request.templateID,
                requirement: request.templateRequirement
            )
        }

        // Theme is a data match against the template's own keys, never an enum.
        let themeMatched = satisfyingVersion.filter { $0.supports(themeKey: request.themeKey) }
        guard !themeMatched.isEmpty else {
            throw StoryEngineError.templateNotFound("\(request.templateID)#\(request.themeKey)")
        }

        let languageMatched = themeMatched.filter {
            $0.constraints.supportedLanguageCodes.contains(request.languageCode)
        }
        guard let byLanguage = languageMatched.first else {
            throw StoryEngineError.unsupportedLanguage(request.languageCode)
        }

        let ageMatched = languageMatched.filter { $0.constraints.supportedAgeRange.contains(request.ageYears) }
        guard let candidate = ageMatched.first else {
            _ = byLanguage
            throw StoryEngineError.unsupportedAgeBand(age: request.ageYears)
        }

        // Page count is clamped rather than rejected — see `BeatPlanner`. What
        // is rejected here is a template that cannot produce any page count in
        // its own declared range, which is an authoring mistake.
        guard !candidate.narrative.beats.isEmpty else {
            throw StoryEngineError.templateHasNoBeats(candidate.id)
        }
        return candidate
    }
}
