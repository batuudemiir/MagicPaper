import XCTest
import CharacterEngine
import VisualSystem
@testable import StoryEngine

final class ImageValidationTests: XCTestCase {
    private let clock = FixedClock(autoAdvance: 1)

    private func service(
        _ provider: FakeImageValidationProvider?,
        budget: GenerationBudget = .standard
    ) -> ImageValidationService {
        ImageValidationService(
            provider: provider,
            budget: GenerationBudgetManager(budget: budget),
            policy: RetryPolicy(maximumAttempts: 1),
            clock: clock,
            idGenerator: SequentialIDGenerator(startingAt: 7_000)
        )
    }

    private func validated(
        _ story: Story,
        template: ResolvedTemplate,
        request: StoryRequest
    ) async -> StoryValidationResult {
        await StoryValidator(clock: clock).validate(
            ValidationContext(story: story, template: template, request: request)
        )
    }

    /// Rebuilds the template with a chosen validation mode and safety policy.
    private func template(
        _ base: ResolvedTemplate,
        mode: ImageValidationMode,
        safety: ChildSafetyPolicy = .strict
    ) -> ResolvedTemplate {
        let policy = base.template.generationPolicy
        return ResolvedTemplate(
            template: StoryTemplate(
                id: base.template.id, version: base.template.version,
                displayName: base.template.displayName, themeKeys: base.template.themeKeys,
                narrative: base.template.narrative, visualStyleID: base.template.visualStyleID,
                sceneRules: base.template.sceneRules,
                generationPolicy: GenerationPolicy(
                    maximumAttemptsPerStage: policy.maximumAttemptsPerStage,
                    pageRefinementEnabled: policy.pageRefinementEnabled,
                    semanticValidationEnabled: false,
                    imageValidationMode: mode,
                    defaultBudget: policy.defaultBudget
                ),
                validationRules: base.template.validationRules,
                childSafety: safety,
                constraints: base.template.constraints
            ),
            visualStyle: base.visualStyle,
            ref: base.ref
        )
    }

    // MARK: - The provider sees the source of truth

    func testTheValidatorIsGivenIdentitySceneAndConstraints() async throws {
        let (story, request, base) = try StoryFixtures.completeStory()
        let resolved = template(base, mode: .advisory)
        let provider = FakeImageValidationProvider()

        _ = try await service(provider).validateImages(story: story, template: resolved, mode: .advisory)

        let context = try XCTUnwrap(provider.contexts.first)
        XCTAssertEqual(context.characterIdentity, story.protagonist?.identity,
                       "The check must compare against the real identity, not a description of it")
        XCTAssertEqual(context.expectedCastIDs, story.characters.map(\.id))
        XCTAssertTrue(story.scenes.contains { $0.id == context.scene.id })
        XCTAssertFalse(context.visualConstraints.identityClauses.isEmpty)
    }

    // MARK: - Outcomes

    func testAValidImagePasses() async throws {
        let (story, request, base) = try StoryFixtures.completeStory()
        let resolved = template(base, mode: .required)
        let provider = FakeImageValidationProvider(fallback: .passed)

        let result = try await service(provider).validateImages(story: story, template: resolved, mode: .required)
        let checked = try story.applying([.setScenes(result.scenes)], at: clock.now())
        let validation = await validated(checked, template: resolved, request: request)

        XCTAssertEqual(result.checkedCount, story.scenes.flatMap(\.visualAssets).count)
        XCTAssertTrue(checked.scenes.flatMap(\.visualAssets).allSatisfy { $0.currentValidation?.result.isPassed == true })
        XCTAssertTrue(validation.isValid, "Errors: \(validation.errors.map(\.code))")
    }

    func testAnUnsafeImageFailsAndBlocksPublication() async throws {
        let (story, request, base) = try StoryFixtures.completeStory()
        let resolved = template(base, mode: .required)
        let provider = FakeImageValidationProvider(scripted: [FakeImageValidationProvider.unsafe], fallback: .passed)

        let result = try await service(provider).validateImages(story: story, template: resolved, mode: .required)
        let checked = try story.applying([.setScenes(result.scenes)], at: clock.now())
        let validation = await validated(checked, template: resolved, request: request)

        XCTAssertFalse(validation.isValid)
        let issue = try XCTUnwrap(validation.errors.first { $0.code == "image_validation_failed" })
        XCTAssertTrue(issue.message.contains("dangerousOrInappropriateContent"))
        XCTAssertThrowsError(try BookAssembler(clock: clock).publish(
            story: try checked.applying([.setValidation(validation)], at: clock.now())
        ))
    }

    func testAnUncertainResultIsRecordedAsUncertain() async throws {
        let (story, request, base) = try StoryFixtures.completeStory()
        let resolved = template(base, mode: .advisory)
        let provider = FakeImageValidationProvider(fallback: FakeImageValidationProvider.cannotTell)

        let result = try await service(provider).validateImages(story: story, template: resolved, mode: .advisory)
        let checked = try story.applying([.setScenes(result.scenes)], at: clock.now())

        let record = try XCTUnwrap(checked.scenes.first?.visualAssets.first?.currentValidation)
        XCTAssertTrue(record.result.isUncertain)
        XCTAssertTrue(record.result.wasChecked, "Someone did look; they just could not tell")

        let validation = await validated(checked, template: resolved, request: request)
        XCTAssertTrue(validation.warnings.contains { $0.code == "image_validation_uncertain" })
        XCTAssertTrue(validation.isValid, "Advisory mode reports, it does not block")
    }

    func testUncertainBlocksUnderRequiredMode() async throws {
        let (story, request, base) = try StoryFixtures.completeStory()
        let resolved = template(base, mode: .required)
        let provider = FakeImageValidationProvider(fallback: FakeImageValidationProvider.cannotTell)

        let result = try await service(provider).validateImages(story: story, template: resolved, mode: .required)
        let checked = try story.applying([.setScenes(result.scenes)], at: clock.now())
        let validation = await validated(checked, template: resolved, request: request)

        XCTAssertFalse(validation.isValid, "\"I cannot tell\" is not good enough when the mode is required")
        XCTAssertTrue(validation.errors.contains { $0.code == "image_validation_uncertain" })
    }

    func testAdvisoryFailureIsOnlyAWarningForQualityFindings() async throws {
        let (story, request, base) = try StoryFixtures.completeStory()
        let resolved = template(base, mode: .advisory)
        // Appearance drift is a quality problem, not a safety one.
        let provider = FakeImageValidationProvider(fallback: FakeImageValidationProvider.driftedCharacter)

        let result = try await service(provider).validateImages(story: story, template: resolved, mode: .advisory)
        let checked = try story.applying([.setScenes(result.scenes)], at: clock.now())
        let validation = await validated(checked, template: resolved, request: request)

        XCTAssertTrue(validation.warnings.contains { $0.code == "image_validation_failed" })
        XCTAssertTrue(validation.isValid)
    }

    func testAdvisoryModeStillBlocksASafetyFinding() async throws {
        let (story, request, base) = try StoryFixtures.completeStory()
        let resolved = template(base, mode: .advisory)
        let provider = FakeImageValidationProvider(fallback: FakeImageValidationProvider.unsafe)

        let result = try await service(provider).validateImages(story: story, template: resolved, mode: .advisory)
        let checked = try story.applying([.setScenes(result.scenes)], at: clock.now())
        let validation = await validated(checked, template: resolved, request: request)

        XCTAssertFalse(validation.isValid,
                       "Advisory means do not block on quality; it never means publish unsafe content")
        XCTAssertTrue(validation.errors.contains { $0.code == "image_validation_failed" })
    }

    // MARK: - Unavailability is never a pass

    func testNoProviderIsRecordedAsUnavailableNotPassed() async throws {
        let (story, request, base) = try StoryFixtures.completeStory()
        let resolved = template(base, mode: .required)

        let result = try await service(nil).validateImages(story: story, template: resolved, mode: .required)
        let checked = try story.applying([.setScenes(result.scenes)], at: clock.now())

        let record = try XCTUnwrap(checked.scenes.first?.visualAssets.first?.currentValidation)
        guard case .providerUnavailable = record.result else {
            return XCTFail("Expected providerUnavailable, got \(record.result)")
        }
        XCTAssertFalse(record.result.wasChecked)
        XCTAssertFalse(record.result.isPassed)

        let validation = await validated(checked, template: resolved, request: request)
        XCTAssertTrue(validation.errors.contains { $0.code == "image_validation_unavailable" },
                      "Nobody looked at the picture, so it cannot be published under a required policy")
    }

    func testAThrowingProviderIsUnavailableRatherThanPassing() async throws {
        let (story, request, base) = try StoryFixtures.completeStory()
        let resolved = template(base, mode: .required)
        let provider = FakeImageValidationProvider(
            throwing: StoryEngineError.providerFailed(operation: .imageValidation, errorClass: .permanent, message: "down")
        )

        let result = try await service(provider).validateImages(story: story, template: resolved, mode: .required)
        let checked = try story.applying([.setScenes(result.scenes)], at: clock.now())
        let record = try XCTUnwrap(checked.scenes.first?.visualAssets.first?.currentValidation)

        guard case .providerUnavailable = record.result else {
            return XCTFail("Expected providerUnavailable, got \(record.result)")
        }
    }

    func testAnExhaustedBudgetLeavesTheImageUnexaminedNotApproved() async throws {
        let (story, request, base) = try StoryFixtures.completeStory()
        let resolved = template(base, mode: .required)
        let provider = FakeImageValidationProvider(fallback: .passed)
        let broke = GenerationBudget(maximumLanguageModelCalls: 0, maximumImageCalls: 0, maximumTokens: 0, maximumCostUSD: 0)

        let result = try await service(provider, budget: broke)
            .validateImages(story: story, template: resolved, mode: .required)
        let checked = try story.applying([.setScenes(result.scenes)], at: clock.now())

        XCTAssertEqual(provider.callCount, 0)
        let record = try XCTUnwrap(checked.scenes.first?.visualAssets.first?.currentValidation)
        guard case .providerUnavailable(let reason) = record.result else {
            return XCTFail("Expected providerUnavailable, got \(record.result)")
        }
        XCTAssertEqual(reason, "budget exhausted")
    }

    // MARK: - Off

    func testOffModeMakesNoProviderCalls() async throws {
        let (story, _, base) = try StoryFixtures.completeStory()
        let resolved = template(base, mode: .off)
        let provider = FakeImageValidationProvider(fallback: .passed)

        let result = try await service(provider).validateImages(story: story, template: resolved, mode: .off)

        XCTAssertEqual(provider.callCount, 0)
        XCTAssertEqual(result.checkedCount, 0)
    }

    func testOffModeProducesNoIssues() async throws {
        let (story, request, base) = try StoryFixtures.completeStory()
        let resolved = template(base, mode: .off)
        let result = try await service(nil).validateImages(story: story, template: resolved, mode: .off)
        let checked = try story.applying([.setScenes(result.scenes)], at: clock.now())

        let validation = await validated(checked, template: resolved, request: request)
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.issues.filter { $0.code.hasPrefix("image_validation") }.isEmpty)
    }

    // MARK: - Records track the image they describe

    func testARecordDoesNotSurviveTheImageItDescribed() async throws {
        let (story, _, base) = try StoryFixtures.completeStory()
        let resolved = template(base, mode: .advisory)
        let provider = FakeImageValidationProvider(fallback: .passed)

        let result = try await service(provider).validateImages(story: story, template: resolved, mode: .advisory)
        var asset = try XCTUnwrap(result.scenes.first?.visualAssets.first)
        XCTAssertNotNil(asset.currentValidation)

        // The picture is redrawn; the old verdict no longer describes it.
        asset.revision += 1
        XCTAssertNil(asset.currentValidation, "A verdict about the previous picture must not vouch for the new one")
        XCTAssertNotNil(asset.validation, "But the record is still there to read")
    }

    func testAlreadyValidatedImagesAreNotRecheckedOrRebilled() async throws {
        let (story, _, base) = try StoryFixtures.completeStory()
        let resolved = template(base, mode: .advisory)
        let provider = FakeImageValidationProvider(fallback: .passed)
        let validationService = service(provider)

        let first = try await validationService.validateImages(story: story, template: resolved, mode: .advisory)
        let checked = try story.applying([.setScenes(first.scenes)], at: clock.now())
        let callsAfterFirst = provider.callCount

        let second = try await validationService.validateImages(story: checked, template: resolved, mode: .advisory)

        XCTAssertEqual(provider.callCount, callsAfterFirst, "Looking at the same picture twice is waste")
        XCTAssertEqual(second.checkedCount, 0)
        XCTAssertGreaterThan(second.skippedCount, 0)
    }

    // MARK: - Findings

    func testEveryFindingKindIsRepresentable() {
        // The list is closed on purpose; this guards against a case being
        // dropped in a refactor and quietly becoming unreportable.
        XCTAssertEqual(ImageValidationFinding.allCases.count, 10)
        XCTAssertTrue(ImageValidationFinding.dangerousOrInappropriateContent.isSafetyFinding)
        XCTAssertTrue(ImageValidationFinding.doNotDepictViolation.isSafetyFinding)
        XCTAssertTrue(ImageValidationFinding.ageOrIdentityMismatch.isSafetyFinding)
        XCTAssertFalse(ImageValidationFinding.compositionViolation.isSafetyFinding)
        XCTAssertFalse(ImageValidationFinding.characterAppearanceDrift.isSafetyFinding)
    }

    func testWatermarkFindingIsReported() async throws {
        let (story, request, base) = try StoryFixtures.completeStory()
        let resolved = template(base, mode: .required)
        let provider = FakeImageValidationProvider(fallback: FakeImageValidationProvider.watermarked)

        let result = try await service(provider).validateImages(story: story, template: resolved, mode: .required)
        let checked = try story.applying([.setScenes(result.scenes)], at: clock.now())
        let validation = await validated(checked, template: resolved, request: request)

        XCTAssertTrue(validation.errors.contains { $0.message.contains("textOrWatermarkInImage") })
    }

    func testResultsRoundTrip() throws {
        let values: [ImageValidationResult] = [
            .passed,
            FakeImageValidationProvider.unsafe,
            FakeImageValidationProvider.cannotTell,
            .providerUnavailable(reason: "offline"),
            .skipped(reason: "mode off")
        ]
        let decoded = try JSONDecoder().decode([ImageValidationResult].self, from: JSONEncoder().encode(values))
        XCTAssertEqual(decoded, values)
    }
}
