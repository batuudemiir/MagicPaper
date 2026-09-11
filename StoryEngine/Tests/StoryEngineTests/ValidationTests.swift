import XCTest
import CharacterEngine
import VisualSystem
@testable import StoryEngine

final class ValidationTests: XCTestCase {
    private let clock = FixedClock()

    private func validate(
        _ story: Story,
        request: StoryRequest,
        template: ResolvedTemplate,
        aiService: StoryAIService? = nil
    ) async -> StoryValidationResult {
        await StoryValidator(clock: clock).validate(
            ValidationContext(story: story, template: template, request: request),
            aiService: aiService
        )
    }

    // MARK: - A healthy book passes

    func testACompleteStoryValidates() async throws {
        let (story, request, template) = try StoryFixtures.completeStory()
        let result = await validate(story, request: request, template: template)

        XCTAssertTrue(result.isValid, "Errors: \(result.errors.map(\.code))")
    }

    func testEveryDeterministicValidatorActuallyRan() async throws {
        let (story, request, template) = try StoryFixtures.completeStory()
        let result = await validate(story, request: request, template: template)

        for id in ValidatorID.allDeterministic {
            let report = result.reports.first { $0.validatorID == id }
            XCTAssertEqual(report?.outcome, .ran, "\(id) did not run")
        }
    }

    // MARK: - Structure

    func testMissingIllustrationBlocksPublication() async throws {
        var (story, request, template) = try StoryFixtures.completeStory(drawImages: false)
        story = try story.applying([.setStatus(.validating)], at: clock.now())

        let result = await validate(story, request: request, template: template)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.code == "image_not_ready" })
    }

    func testEmptyPageIsAnError() async throws {
        let (base, request, template) = try StoryFixtures.completeStory()
        let page = base.pages[2]
        let story = try base.applying([.replacePageText(pageID: page.id, title: nil, text: "  ")], at: clock.now())

        let result = await validate(story, request: request, template: template)
        XCTAssertTrue(result.errors.contains { $0.code == "page_empty" && $0.scope == .page(page.id) })
    }

    func testMissingTitleIsAnError() async throws {
        let (base, request, template) = try StoryFixtures.completeStory()
        let story = try base.applying([.setTitle("")], at: clock.now())

        let result = await validate(story, request: request, template: template)
        XCTAssertTrue(result.errors.contains { $0.code == "missing_title" })
    }

    func testOrphanSceneIsOnlyAWarning() async throws {
        let (base, request, template) = try StoryFixtures.completeStory()
        var scenes = base.scenes
        scenes.append(
            StoryScene(
                id: UUID(), index: scenes.count,
                signature: SceneSignature(settingKey: "nowhere", timeOfDayKey: "never", moodKey: "none", castNames: []),
                visualContext: SceneVisualContext(settingKey: "nowhere", timeOfDayKey: "never", moodKey: "none")
            )
        )
        let story = try base.applying([.setScenes(scenes)], at: clock.now())

        let result = await validate(story, request: request, template: template)
        XCTAssertTrue(result.warnings.contains { $0.code == "orphan_scene" })
        XCTAssertTrue(result.isValid, "An unused scene is untidy, not broken")
    }

    // MARK: - Character consistency is the non-invention gate

    func testInventedAppearanceInPageTextBlocksPublication() async throws {
        let (base, request, template) = try StoryFixtures.completeStory()
        let page = base.pages[1]
        let story = try base.applying([
            .replacePageText(
                pageID: page.id, title: nil,
                text: "Deniz pushed back their blonde hair and looked around the clearing. " + ScriptedResponses.prose(words: 60, seed: 3)
            )
        ], at: clock.now())

        let result = await validate(story, request: request, template: template)

        XCTAssertFalse(result.isValid)
        let issue = result.errors.first { $0.code == "invented_appearance" }
        XCTAssertNotNil(issue)
        XCTAssertEqual(issue?.scope, .page(page.id))
        XCTAssertTrue(issue?.message.contains("blonde hair") == true)
    }

    func testAuthorizedAppearanceIsFine() async throws {
        let (base, request, template) = try StoryFixtures.completeStory()
        let page = base.pages[1]
        let story = try base.applying([
            .replacePageText(
                pageID: page.id, title: nil,
                text: "Deniz shook their curly black hair. " + ScriptedResponses.prose(words: 60, seed: 4)
            )
        ], at: clock.now())

        let result = await validate(story, request: request, template: template)
        XCTAssertFalse(result.errors.contains { $0.code == "invented_appearance" })
    }

    func testPageThatNeverMentionsTheProtagonistWarns() async throws {
        let (base, request, template) = try StoryFixtures.completeStory()
        let page = base.pages[3]
        let story = try base.applying([
            .replacePageText(pageID: page.id, title: nil, text: "The clearing was quiet. Nothing moved between the stones at all.")
        ], at: clock.now())

        let result = await validate(story, request: request, template: template)
        XCTAssertTrue(result.warnings.contains { $0.code == "protagonist_absent" })
    }

    // MARK: - Age appropriateness

    func testBannedPhraseBlocksPublication() async throws {
        let (base, request, template) = try StoryFixtures.completeStory()
        let page = base.pages[2]
        let story = try base.applying([
            .replacePageText(pageID: page.id, title: nil, text: "Deniz did not want to die today. " + ScriptedResponses.prose(words: 60, seed: 5))
        ], at: clock.now())

        let result = await validate(story, request: request, template: template)
        XCTAssertTrue(result.errors.contains { $0.code == "banned_phrase" })
    }

    func testDoNotDepictBlocksPublication() async throws {
        let cast = StoryFixtures.storyCharacters(
            StoryFixtures.cast(StoryFixtures.resolvedCharacter(doNotDepict: ["hospital"]))
        )
        let (base, request, template) = try StoryFixtures.completeStory(characters: cast)
        let page = base.pages[1]
        let story = try base.applying([
            .replacePageText(pageID: page.id, title: nil, text: "Deniz remembered the hospital. " + ScriptedResponses.prose(words: 60, seed: 6))
        ], at: clock.now())

        let result = await validate(story, request: request, template: template)
        XCTAssertTrue(result.errors.contains { $0.code == "do_not_depict" })
    }

    func testOverlongPageWarnsForTheAgeBand() async throws {
        let (base, request, template) = try StoryFixtures.completeStory()
        let page = base.pages[2]
        let story = try base.applying([
            .replacePageText(pageID: page.id, title: nil, text: ScriptedResponses.prose(words: 400, seed: 7))
        ], at: clock.now())

        let result = await validate(story, request: request, template: template)
        XCTAssertTrue(result.warnings.contains { $0.code == "page_too_long" })
        XCTAssertTrue(result.isValid, "Length is advice, not a block")
    }

    func testOverlongSentenceWarns() async throws {
        let (base, request, template) = try StoryFixtures.completeStory()
        let page = base.pages[2]
        let sentence = "Deniz walked " + Array(repeating: "onward", count: 40).joined(separator: " ") + "."
        let story = try base.applying([.replacePageText(pageID: page.id, title: nil, text: sentence)], at: clock.now())

        let result = await validate(story, request: request, template: template)
        XCTAssertTrue(result.warnings.contains { $0.code == "sentence_too_long" })
    }

    // MARK: - Visual safety

    func testStrippingRequiredExclusionsBlocksPublication() async throws {
        let (base, request, template) = try StoryFixtures.completeStory()
        var scene = base.scenes[0]
        guard var asset = scene.visualAssets.first, let original = asset.promptSnapshot else {
            return XCTFail("Fixture has no illustration to tamper with")
        }
        asset.promptSnapshot = VisualConstraintSet(
            styleClauses: original.styleClauses,
            compositionClauses: original.compositionClauses,
            paletteClauses: original.paletteClauses,
            sceneClauses: original.sceneClauses,
            identityClauses: original.identityClauses,
            negativeClauses: [],
            referenceLocators: original.referenceLocators,
            aspectRatio: original.aspectRatio,
            seed: original.seed,
            provenance: original.provenance
        )
        scene.upsert(asset)
        let story = try base.applying([.setScenes([scene] + base.scenes.dropFirst())], at: clock.now())

        let result = await validate(story, request: request, template: template)
        XCTAssertTrue(result.errors.contains { $0.code == "missing_negative_clauses" })
    }

    // MARK: - Semantic validators

    private func semanticService(_ provider: FakeStoryAIProvider, budget: GenerationBudget = .standard) -> StoryAIService {
        StoryAIService(
            provider: provider,
            budget: GenerationBudgetManager(budget: budget),
            policy: RetryPolicy(maximumAttempts: 1),
            clock: FixedClock(autoAdvance: 1),
            idGenerator: SequentialIDGenerator(startingAt: 2_000)
        )
    }

    func testSemanticValidatorsRunAndReportNothingOnACleanBook() async throws {
        let (story, request, template) = try StoryFixtures.completeStory()
        let provider = FakeStoryAIProvider(fallback: { _ in .success(ScriptedResponses.noFindings) })

        let result = await validate(story, request: request, template: template, aiService: semanticService(provider))

        for id in ValidatorID.allSemantic {
            XCTAssertEqual(result.reports.first { $0.validatorID == id }?.outcome, .ran, "\(id) did not run")
        }
        XCTAssertEqual(provider.callCount(for: .semanticValidation), 2)
        XCTAssertTrue(result.isValid)
    }

    func testSceneTextMismatchIsReported() async throws {
        // The case deterministic checks cannot see: the text says one thing,
        // the illustration shows another.
        let (story, request, template) = try StoryFixtures.completeStory()
        let provider = FakeStoryAIProvider(
            script: [.semanticValidation: [
                .success(ScriptedResponses.noFindings),
                .success(ScriptedResponses.findings(
                    pageIndex: 2, code: "scene_text_mismatch",
                    message: "The text says Deniz was frightened of the forest, but the illustration shows a sunny beach."
                ))
            ]]
        )

        let result = await validate(story, request: request, template: template, aiService: semanticService(provider))
        let issue = result.issues.first { $0.code == "scene_text_mismatch" }

        XCTAssertNotNil(issue)
        XCTAssertEqual(issue?.validatorID, ValidatorID.sceneTextAlignment)
        XCTAssertEqual(issue?.scope, .page(story.pages[2].id))
    }

    func testSemanticFindingsAreAdvisoryByDefault() async throws {
        let (story, request, template) = try StoryFixtures.completeStory()
        let provider = FakeStoryAIProvider(fallback: { _ in
            .success(ScriptedResponses.findings(pageIndex: 1, code: "contradiction", message: "A fact changes.", severity: "error"))
        })

        let result = await validate(story, request: request, template: template, aiService: semanticService(provider))

        XCTAssertTrue(result.isValid, "A model's opinion must not block a parent's book by default")
        XCTAssertTrue(result.warnings.contains { $0.code == "contradiction" })
    }

    func testATemplateCanMakeSemanticFindingsBlocking() async throws {
        let strict = StoryFixtures.template(
            generationPolicy: GenerationPolicy(semanticIssuesAreBlocking: true)
        )
        let (story, request, template) = try StoryFixtures.completeStory(template: strict)
        let provider = FakeStoryAIProvider(fallback: { _ in
            .success(ScriptedResponses.findings(pageIndex: 1, code: "contradiction", message: "A fact changes.", severity: "error"))
        })

        // The test template enables only the deterministic validators, so the
        // semantic ones have to be switched on explicitly here.
        let strictTemplate = ResolvedTemplate(
            template: StoryTemplate(
                id: template.template.id, version: template.template.version,
                displayName: template.template.displayName, themeKeys: template.template.themeKeys,
                narrative: template.template.narrative, visualStyleID: template.template.visualStyleID,
                sceneRules: template.template.sceneRules,
                generationPolicy: GenerationPolicy(semanticIssuesAreBlocking: true),
                validationRules: ValidationRules(
                    ageBands: template.template.validationRules.ageBands,
                    enabledValidators: ValidatorID.all
                ),
                constraints: template.template.constraints
            ),
            visualStyle: template.visualStyle,
            ref: template.ref
        )

        let result = await validate(story, request: request, template: strictTemplate, aiService: semanticService(provider))
        XCTAssertFalse(result.isValid, "This template asked for semantic findings to block")
    }

    func testUnaffordableSemanticValidatorIsRecordedAsSkippedNotPassed() async throws {
        let (story, request, template) = try StoryFixtures.completeStory()
        let provider = FakeStoryAIProvider(fallback: { _ in .success(ScriptedResponses.noFindings) })
        let broke = GenerationBudget(maximumLanguageModelCalls: 0, maximumImageCalls: 0, maximumTokens: 0, maximumCostUSD: 0)

        let result = await validate(story, request: request, template: template, aiService: semanticService(provider, budget: broke))

        XCTAssertEqual(provider.callCount, 0)
        for id in ValidatorID.allSemantic {
            let outcome = result.reports.first { $0.validatorID == id }?.outcome
            guard case .skipped(let reason) = outcome else {
                return XCTFail("\(id) should be skipped, was \(String(describing: outcome))")
            }
            XCTAssertEqual(reason, "budget exhausted")
        }
        XCTAssertEqual(Set(result.skippedValidatorIDs), Set(ValidatorID.allSemantic))
    }

    func testSemanticValidatorsAreSkippedWhenNoAIServiceIsAvailable() async throws {
        let (story, request, template) = try StoryFixtures.completeStory()
        let result = await validate(story, request: request, template: template, aiService: nil)

        XCTAssertEqual(Set(result.skippedValidatorIDs), Set(ValidatorID.allSemantic))
    }

    func testAFailingSemanticValidatorIsRecordedAsFailedNotPassed() async throws {
        let (story, request, template) = try StoryFixtures.completeStory()
        let provider = FakeStoryAIProvider(fallback: { _ in .permanent })

        let result = await validate(story, request: request, template: template, aiService: semanticService(provider))

        for id in ValidatorID.allSemantic {
            guard case .failed = result.reports.first(where: { $0.validatorID == id })?.outcome else {
                return XCTFail("\(id) should be recorded as failed")
            }
        }
    }

    func testDisabledValidatorIsRecordedAsSkipped() async throws {
        let limited = StoryFixtures.template()
        let (story, request, template) = try StoryFixtures.completeStory(template: limited)
        let result = await validate(story, request: request, template: template)

        XCTAssertTrue(result.skippedValidatorIDs.contains(ValidatorID.narrativeConsistency))
    }

    // MARK: - Publication gate

    func testPublishRequiresValidation() throws {
        let (story, _, _) = try StoryFixtures.completeStory()
        XCTAssertThrowsError(try BookAssembler(clock: clock).publish(story: story)) { error in
            XCTAssertEqual(error as? StoryEngineError, .validationFailed(["not_validated"]))
        }
    }

    func testPublishRefusesAStoryWithErrors() async throws {
        let (base, request, template) = try StoryFixtures.completeStory()
        let broken = try base.applying([.setTitle("")], at: clock.now())
        let result = await validate(broken, request: request, template: template)
        let validated = try broken.applying([.setValidation(result)], at: clock.now())

        XCTAssertThrowsError(try BookAssembler(clock: clock).publish(story: validated)) { error in
            guard case .validationFailed(let codes) = error as? StoryEngineError else {
                return XCTFail("Unexpected error \(error)")
            }
            XCTAssertTrue(codes.contains("missing_title"))
        }
    }

    func testPublishSucceedsWhenOnlyWarningsRemain() async throws {
        let (base, request, template) = try StoryFixtures.completeStory()
        let page = base.pages[2]
        let long = try base.applying([.replacePageText(pageID: page.id, title: nil, text: ScriptedResponses.prose(words: 400, seed: 9))], at: clock.now())
        let result = await validate(long, request: request, template: template)
        let validated = try long.applying([.setValidation(result)], at: clock.now())

        XCTAssertFalse(result.warnings.isEmpty)
        let published = try BookAssembler(clock: clock).publish(story: validated)
        XCTAssertTrue(published.publication.isPublished)
    }
}
