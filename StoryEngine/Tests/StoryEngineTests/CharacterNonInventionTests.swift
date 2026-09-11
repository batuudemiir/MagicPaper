import XCTest
import CharacterEngine
import VisualSystem
@testable import StoryEngine

/// The engine must never state a physical fact about a child that did not come
/// from the Character Engine. Three mechanisms enforce that; this checks all three.
final class CharacterNonInventionTests: XCTestCase {

    // MARK: - 1. A StoryCharacter can only be built from a resolved one

    func testAStoryCharacterCarriesExactlyItsResolvedIdentity() {
        let resolved = StoryFixtures.resolvedCharacter(descriptors: [
            CharacterDescriptor(category: .hair, value: "curly black hair")
        ])
        let character = StoryCharacter(resolved: resolved)

        XCTAssertEqual(character.identity, resolved.identity)
        XCTAssertEqual(character.versionID, resolved.versionID, "The story pins the exact identity version")
        XCTAssertEqual(character.identity.descriptors.map(\.value), ["curly black hair"])
    }

    func testTheProjectionRoundTripsWithoutGainingAnything() {
        let resolved = StoryFixtures.resolvedCharacter()
        let roundTripped = StoryCharacter(resolved: resolved).resolved

        XCTAssertEqual(roundTripped.identity, resolved.identity)
        XCTAssertEqual(roundTripped.styleProfile, resolved.styleProfile)
        XCTAssertEqual(roundTripped.assetSet, resolved.assetSet)
    }

    func testEveryCharacterInAGeneratedStoryIsVersionPinned() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        let job = try await harness.orchestrator.generate(harness.request())
        let story = try await XCTUnwrapAsync(await harness.orchestrator.story(id: job.storyID))

        XCTAssertFalse(story.characters.isEmpty)
        for character in story.characters {
            XCTAssertTrue(character.versionPin.contains("@"), "Identity must be traceable to a version")
        }
    }

    // MARK: - 2. No appearance reaches a text prompt

    func testTheCastBlockNamesCharactersWithoutDescribingThem() {
        let characters = StoryFixtures.storyCharacters(
            StoryFixtures.cast(StoryFixtures.resolvedCharacter(descriptors: [
                CharacterDescriptor(category: .hair, value: "curly black hair"),
                CharacterDescriptor(category: .eyes, value: "brown eyes"),
                CharacterDescriptor(category: .clothingDefault, value: "yellow raincoat")
            ]))
        )
        let block = PromptAssembler(template: StoryFixtures.adventureTemplate).castBlock(characters)

        XCTAssertTrue(block.contains("Deniz"))
        XCTAssertTrue(block.contains("age 6"))
        XCTAssertFalse(block.contains("curly black hair"), "Appearance must not travel to a language model")
        XCTAssertFalse(block.contains("brown eyes"))
        XCTAssertFalse(block.contains("yellow raincoat"))
    }

    func testEveryGenerativePromptCarriesTheAppearanceLockdown() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        _ = try await harness.orchestrator.generate(harness.request())

        // Only the stages that put words into the book. The semantic
        // validators read a finished story and report on it; they never
        // produce story text, so the lockdown does not apply to them.
        let generative: Set<AIOperation> = [.outline, .narrativeDraft, .pageRefinement]
        let checked = harness.aiProvider.requests.filter { generative.contains($0.operation) }

        XCTAssertEqual(Set(checked.map(\.operation)), generative, "Every generative stage should have run")
        for request in checked {
            XCTAssertTrue(
                request.systemPrompt.lowercased().contains("never describe how any character looks"),
                "\(request.operation.rawValue) went out without the lockdown instruction"
            )
        }
    }

    func testATemplateThatForgetsTheLockdownStillGetsOne() {
        let careless = StoryFixtures.template(beats: StoryFixtures.defaultBeats)
        let withoutSlot = StoryTemplate(
            id: careless.id, version: careless.version, displayName: careless.displayName,
            themeKeys: careless.themeKeys,
            narrative: NarrativeTemplate(version: careless.narrative.version, beats: careless.narrative.beats, promptSlots: [:]),
            visualStyleID: careless.visualStyleID, sceneRules: careless.sceneRules,
            validationRules: careless.validationRules, constraints: careless.constraints
        )
        let instructions = PromptAssembler(template: withoutSlot).systemInstructions()

        XCTAssertTrue(
            instructions.joined(separator: " ").lowercased().contains("never describe how any character looks"),
            "A missing lockdown slot must fail safe, not fail open"
        )
    }

    func testNoTextPromptEverContainsAnAppearancePhrase() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        _ = try await harness.orchestrator.generate(harness.request())
        let lexicon = DescriptorLexicon.builtIn(languageCode: "en")
        // An identity with no descriptors at all: every appearance phrase in
        // the lexicon is unauthorized, so any that appears is a leak.
        let bare = CharacterIdentity(ageYears: 6, pronouns: .theyThem, descriptors: [], identitySeed: 0)

        let generative: Set<AIOperation> = [.outline, .narrativeDraft, .pageRefinement]
        for request in harness.aiProvider.requests where generative.contains(request.operation) {
            let prompt = request.userPrompt
            // The lockdown instruction itself names the categories; check only
            // the user-facing half, which is where story data travels.
            let violations = lexicon.violations(in: prompt, authorizedBy: bare)
            XCTAssertTrue(violations.isEmpty, "\(request.operation.rawValue) prompt leaked \(violations.map(\.phrase))")
        }
    }

    // MARK: - 3. The validator catches a model that invents anyway

    func testAModelThatInventsAppearanceIsCaught() async throws {
        let inventing: @Sendable (AICompletionRequest) -> ScriptedResult = { request in
            switch request.operation {
            case .outline:
                return .success(ScriptedResponses.outline(beatIDs: Array(repeating: "b", count: 7)))
            case .narrativeDraft:
                // The model ignores the lockdown and describes the child.
                let segments = (0..<7).map { index in
                    #"{"beatIndex":\#(index),"text":"Deniz tucked their blonde hair behind one ear. \#(ScriptedResponses.prose(words: 60, seed: index))"}"#
                }.joined(separator: ",")
                return .success(#"{"voiceProfile":{"narratorRegister":"warm"},"segments":[\#(segments)]}"#)
            case .pageRefinement:
                return .success(#"{"title":"A page","text":"Deniz tucked their blonde hair behind one ear. \#(ScriptedResponses.prose(words: 60))"}"#)
            case .semanticValidation:
                return .success(ScriptedResponses.noFindings)
            case .imageGeneration, .imageValidation:
                return .failure(.permanent, "wrong provider")
            }
        }

        let harness = OrchestratorHarness.make(pageCount: 7, fallback: inventing)
        let job = try await harness.orchestrator.generate(harness.request())
        let story = try await XCTUnwrapAsync(await harness.orchestrator.story(id: job.storyID))

        let validation = try XCTUnwrap(story.validation)
        XCTAssertFalse(validation.isValid, "An invented appearance must block publication")
        XCTAssertTrue(validation.errors.contains { $0.code == "invented_appearance" })
        XCTAssertEqual(story.status, .failed)

        XCTAssertThrowsError(try BookAssembler(clock: FixedClock()).publish(story: story))
    }

    func testAnInventedAppearanceInAnImagePromptIsCaught() async throws {
        let (base, request, template) = try StoryFixtures.completeStory()
        var scene = base.scenes[0]
        guard var asset = scene.visualAssets.first, let original = asset.promptSnapshot else {
            return XCTFail("Fixture has no illustration")
        }
        asset.promptSnapshot = VisualConstraintSet(
            styleClauses: original.styleClauses,
            compositionClauses: original.compositionClauses,
            paletteClauses: original.paletteClauses,
            sceneClauses: original.sceneClauses,
            identityClauses: original.identityClauses + ["Deniz has blue eyes"],
            negativeClauses: original.negativeClauses,
            referenceLocators: original.referenceLocators,
            aspectRatio: original.aspectRatio,
            seed: original.seed,
            provenance: original.provenance
        )
        scene.upsert(asset)
        let story = try base.applying([.setScenes([scene] + base.scenes.dropFirst())], at: StoryFixtures.referenceDate)

        let result = await StoryValidator(clock: FixedClock()).validate(
            ValidationContext(story: story, template: template, request: request)
        )

        XCTAssertTrue(result.errors.contains { $0.code == "invented_appearance_in_prompt" })
    }

    func testAuthorizedAppearanceFlowsThroughToTheImageRequest() async throws {
        let harness = OrchestratorHarness.make(pageCount: 7)
        _ = try await harness.orchestrator.generate(harness.request())

        let constraints = try XCTUnwrap(harness.imageProvider.requests.first?.constraints)
        let identityText = constraints.identityClauses.joined(separator: " ")

        XCTAssertTrue(identityText.contains("curly black hair"), "The picture must know what the child looks like")
        XCTAssertTrue(identityText.contains("brown eyes"))
        XCTAssertTrue(constraints.referenceLocators.contains("deniz-master.jpg"), "And carry the reference photo")
    }
}
