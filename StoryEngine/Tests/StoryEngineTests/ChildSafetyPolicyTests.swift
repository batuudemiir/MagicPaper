import XCTest
import CharacterEngine
@testable import StoryEngine

final class ChildSafetyPolicyTests: XCTestCase {
    private let clock = FixedClock()

    private func gate(_ policy: ChildSafetyPolicy = .strict) -> ChildSafetyGate {
        ChildSafetyGate(policy: policy)
    }

    // MARK: - Policy shape

    func testTheDefaultForAChildrensProductBlocksEverywhere() {
        let policy = ChildSafetyPolicy.strict
        XCTAssertEqual(policy.inputPolicy, .blocking)
        XCTAssertEqual(policy.textPolicy, .blocking)
        XCTAssertEqual(policy.imagePolicy, .blocking)
        XCTAssertEqual(policy.publicationPolicy, .blocking)
    }

    func testATemplateThatSaysNothingAboutSafetyGetsTheStrictPolicy() throws {
        // Failing safe matters more here than failing convenient.
        let json = """
        {
          "id": "quiet_01", "version": "1.0.0",
          "narrative": { "version": "1.0.0", "beats": [
            { "id": "a", "role": "opening", "settingKey": "home" },
            { "id": "b", "role": "closing", "settingKey": "home" } ] },
          "visualStyleID": "magic_paper_v1",
          "sceneRules": { "maximumScenes": 3 },
          "validationRules": { "ageBands": [] },
          "constraints": { "minimumPages": 2, "maximumPages": 4,
            "minimumAge": 3, "maximumAge": 9, "supportedLanguageCodes": ["en"] }
        }
        """
        let template = try JSONDecoder().decode(StoryTemplate.self, from: Data(json.utf8))
        XCTAssertEqual(template.childSafety, .strict)
    }

    func testPolicyRoundTrips() throws {
        let policy = ChildSafetyPolicy(inputPolicy: .advisory, textPolicy: .blocking, imagePolicy: .off, publicationPolicy: .blocking)
        let decoded = try JSONDecoder().decode(ChildSafetyPolicy.self, from: JSONEncoder().encode(policy))
        XCTAssertEqual(decoded, policy)
    }

    func testSafetyLevelsAreOrdered() {
        XCTAssertLessThan(SafetyLevel.off, SafetyLevel.advisory)
        XCTAssertLessThan(SafetyLevel.advisory, SafetyLevel.blocking)
        XCTAssertEqual(SafetyLevel.blocking.severity, .error)
        XCTAssertEqual(SafetyLevel.advisory.severity, .warning)
    }

    // MARK: - Input gate

    func testUnsafeThemeInputIsRefusedBeforeAnythingIsPaidFor() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        // "kill" is in the shipped template's banned phrases.
        let request = StoryFixtures.request(themeKey: "how to kill a dragon")

        do {
            _ = try await harness.orchestrator.generate(request)
            XCTFail("Expected the request to be refused")
        } catch {
            guard case .unsafeInput(let codes) = error as? StoryEngineError else {
                return XCTFail("Unexpected error \(error)")
            }
            XCTAssertTrue(codes.contains("unsafe_input"))
        }

        XCTAssertEqual(harness.aiProvider.callCount, 0, "Nothing should have been generated")
        XCTAssertEqual(harness.imageProvider.callCount, 0, "And nothing billed")
    }

    func testUnsafeToneInputIsAlsoCaught() {
        let issues = gate().checkInput(
            request: StoryFixtures.request(templateID: "adventure_01"),
            template: StoryFixtures.adventureTemplate
        )
        XCTAssertTrue(issues.isEmpty, "The fixture request is fine")

        let unsafe = StoryRequest(
            cast: CastBinding(protagonist: CharacterID()),
            templateID: "adventure_01", themeKey: "forest", languageCode: "en",
            ageYears: 6, requestedPageCount: 7, toneKey: "make them hate each other",
            createdAt: StoryFixtures.referenceDate
        )
        let unsafeIssues = gate().checkInput(request: unsafe, template: StoryFixtures.adventureTemplate)
        XCTAssertTrue(unsafeIssues.contains { $0.code == "unsafe_input" })
    }

    func testAnAdvisoryInputPolicyReportsWithoutRefusing() {
        let advisory = gate(ChildSafetyPolicy(inputPolicy: .advisory))
        let request = StoryFixtures.request(themeKey: "how to kill a dragon")
        let issues = advisory.checkInput(request: request, template: StoryFixtures.adventureTemplate)

        XCTAssertFalse(issues.isEmpty)
        XCTAssertTrue(issues.allSatisfy { $0.severity == .warning })
        XCTAssertFalse(advisory.shouldRefuseInput(issues))
    }

    func testAnOffInputPolicyChecksNothing() {
        let off = gate(ChildSafetyPolicy(inputPolicy: .off))
        let request = StoryFixtures.request(themeKey: "how to kill a dragon")
        XCTAssertTrue(off.checkInput(request: request, template: StoryFixtures.adventureTemplate).isEmpty)
    }

    func testAgeOutsideTheTemplateIsRefused() {
        let request = StoryFixtures.request(ageYears: 2)
        let issues = gate().checkInput(request: request, template: StoryFixtures.adventureTemplate)
        XCTAssertTrue(issues.contains { $0.code == "age_outside_template" })
    }

    // MARK: - Publication gate

    func testACleanStoryIsAllowedThrough() async throws {
        let (story, request, template) = try StoryFixtures.completeStory()
        let validation = await StoryValidator(clock: clock).validate(
            ValidationContext(story: story, template: template, request: request)
        )
        let decision = gate().publicationDecision(for: validation)

        XCTAssertTrue(decision.isAllowed, "Blocked by: \(decision.reasonCodes)")
        XCTAssertTrue(decision.blockingIssues.isEmpty)
    }

    func testASafetyCriticalWarningStillBlocks() {
        // The rule that matters: a text policy set to advisory means "do not
        // block on clumsy prose", never "publish a banned phrase".
        let validation = StoryValidationResult(
            reports: [
                ValidatorReport(
                    validatorID: ValidatorID.ageAppropriateness,
                    outcome: .ran,
                    issues: [
                        ValidationIssue(
                            validatorID: ValidatorID.ageAppropriateness,
                            code: "banned_phrase",
                            severity: .warning,
                            scope: .story,
                            message: "contains a banned phrase"
                        )
                    ]
                )
            ],
            validatedAt: clock.now()
        )

        XCTAssertTrue(validation.isValid, "No errors, so ordinary validation would let it pass")
        let decision = gate().publicationDecision(for: validation)
        XCTAssertFalse(decision.isAllowed, "But the safety gate will not")
        XCTAssertTrue(decision.reasonCodes.contains("banned_phrase"))
    }

    func testAQualityWarningDoesNotBlock() {
        let validation = StoryValidationResult(
            reports: [
                ValidatorReport(
                    validatorID: ValidatorID.repetition,
                    outcome: .ran,
                    issues: [
                        ValidationIssue(
                            validatorID: ValidatorID.repetition, code: "repeated_phrases",
                            severity: .warning, scope: .story, message: "phrases repeat"
                        )
                    ]
                )
            ],
            validatedAt: clock.now()
        )
        XCTAssertTrue(gate().publicationDecision(for: validation).isAllowed)
    }

    func testASafetyCriticalValidatorThatNeverRanBlocks() {
        // Nobody checked the pictures. Under a blocking policy that is itself a
        // reason to stop: a book nobody examined is not a book that passed.
        let validation = StoryValidationResult(
            reports: [
                ValidatorReport(validatorID: ValidatorID.structural, outcome: .ran, issues: []),
                ValidatorReport(validatorID: ValidatorID.visualSafety, outcome: .skipped(reason: "disabled by template"), issues: [])
            ],
            validatedAt: clock.now()
        )
        let decision = gate().publicationDecision(for: validation)

        XCTAssertFalse(decision.isAllowed)
        XCTAssertTrue(decision.unexaminedValidatorIDs.contains(ValidatorID.visualSafety))
        XCTAssertTrue(decision.reasonCodes.contains("unexamined_\(ValidatorID.visualSafety)"))
    }

    func testAnAdvisoryPublicationPolicyFallsBackToOrdinaryValidation() {
        let validation = StoryValidationResult(
            reports: [
                ValidatorReport(
                    validatorID: ValidatorID.ageAppropriateness, outcome: .ran,
                    issues: [
                        ValidationIssue(
                            validatorID: ValidatorID.ageAppropriateness, code: "banned_phrase",
                            severity: .warning, scope: .story, message: "x"
                        )
                    ]
                )
            ],
            validatedAt: clock.now()
        )
        let advisory = gate(ChildSafetyPolicy(publicationPolicy: .advisory))
        XCTAssertTrue(advisory.publicationDecision(for: validation).isAllowed)
    }

    func testAnOffPublicationPolicyAllowsAnything() {
        let validation = StoryValidationResult(
            reports: [
                ValidatorReport(
                    validatorID: ValidatorID.ageAppropriateness, outcome: .ran,
                    issues: [
                        ValidationIssue(
                            validatorID: ValidatorID.ageAppropriateness, code: "banned_phrase",
                            severity: .error, scope: .story, message: "x"
                        )
                    ]
                )
            ],
            validatedAt: clock.now()
        )
        XCTAssertTrue(gate(ChildSafetyPolicy(publicationPolicy: .off)).publicationDecision(for: validation).isAllowed)
    }

    // MARK: - End to end

    func testAnUnsafeBookCannotBePublishedThroughTheOrchestrator() async throws {
        // The model ignores the safety instruction and writes a banned phrase.
        let unsafeWriter: @Sendable (AICompletionRequest) -> ScriptedResult = { request in
            switch request.operation {
            case .outline:
                return .success(ScriptedResponses.outline(beatIDs: Array(repeating: "b", count: 7)))
            case .narrativeDraft:
                let segments = (0..<7).map { index in
                    #"{"beatIndex":\#(index),"text":"Deniz was afraid the dragon would kill everyone. \#(ScriptedResponses.prose(words: 50, seed: index))"}"#
                }.joined(separator: ",")
                return .success(#"{"voiceProfile":{"narratorRegister":"warm"},"segments":[\#(segments)]}"#)
            case .pageRefinement:
                return .success(#"{"title":"A page","text":"Deniz was afraid the dragon would kill everyone. \#(ScriptedResponses.prose(words: 50))"}"#)
            case .semanticValidation:
                return .success(ScriptedResponses.noFindings)
            case .imageGeneration, .imageValidation:
                return .failure(.permanent, "wrong provider")
            }
        }

        let harness = OrchestratorHarness.make(pageCount: 7, fallback: unsafeWriter)
        let job = try await harness.orchestrator.generate(harness.request())
        let story = try await XCTUnwrapAsync(await harness.orchestrator.story(id: job.storyID))

        XCTAssertEqual(story.status, .failed)
        XCTAssertTrue(story.validation?.errors.contains { $0.code == "banned_phrase" } == true)

        do {
            _ = try await harness.orchestrator.publish(storyID: story.id)
            XCTFail("Expected publication to be blocked")
        } catch {
            guard case .blockedByChildSafety(let codes) = error as? StoryEngineError else {
                return XCTFail("Unexpected error \(error)")
            }
            XCTAssertTrue(codes.contains("banned_phrase"))
        }
    }

    func testASafeBookPublishesNormally() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        let job = try await harness.orchestrator.generate(harness.request())
        let published = try await harness.orchestrator.publish(storyID: job.storyID)

        XCTAssertTrue(published.publication.isPublished)
    }

    func testTheGateCoversEveryStageOfThePipeline() {
        // Input, text, image, publication — the four points at which the
        // product can still decline to show a child something.
        let policy = ChildSafetyPolicy.strict
        XCTAssertEqual(
            [policy.inputPolicy, policy.textPolicy, policy.imagePolicy, policy.publicationPolicy],
            [.blocking, .blocking, .blocking, .blocking]
        )
        XCTAssertTrue(ChildSafetyPolicy.safetyCriticalValidatorIDs.contains(ValidatorID.ageAppropriateness))
        XCTAssertTrue(ChildSafetyPolicy.safetyCriticalValidatorIDs.contains(ValidatorID.visualSafety))
        XCTAssertTrue(ChildSafetyPolicy.safetyCriticalValidatorIDs.contains(ValidatorID.generatedImage))
        XCTAssertTrue(ChildSafetyPolicy.safetyCriticalCodes.contains("do_not_depict"))
        XCTAssertTrue(ChildSafetyPolicy.safetyCriticalCodes.contains("image_validation_failed"))
    }
}
