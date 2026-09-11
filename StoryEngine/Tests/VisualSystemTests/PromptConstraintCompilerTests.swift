import XCTest
import CharacterEngine
import EngineFoundation
@testable import VisualSystem

final class PromptConstraintCompilerTests: XCTestCase {
    private let compiler = PromptConstraintCompiler()

    private func input(
        cast: [ResolvedCharacter]? = nil,
        variant: VisualVariant = .default,
        sceneContext: SceneVisualContext? = nil,
        seed: UInt64 = 1234,
        preferredAssetRole: CharacterAssetRole = .master
    ) throws -> VisualCompilationInput {
        VisualCompilationInput(
            style: try VisualFixtures.resolvedStyle(),
            sceneContext: sceneContext ?? VisualFixtures.sceneContext,
            variant: variant,
            cast: cast ?? [VisualFixtures.character()],
            seed: seed,
            preferredAssetRole: preferredAssetRole
        )
    }

    // MARK: - Determinism

    func testCompilationIsDeterministic() throws {
        let cast = [VisualFixtures.character()]
        let first = try compiler.compile(try input(cast: cast))
        let second = try compiler.compile(try input(cast: cast))

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.fingerprint, second.fingerprint)
    }

    func testCastOrderDoesNotChangeOutput() throws {
        let hero = VisualFixtures.character(name: "Deniz", role: .protagonist)
        let friend = VisualFixtures.character(name: "Pamuk", role: .companion)

        let forward = try compiler.compile(try input(cast: [hero, friend]))
        let reversed = try compiler.compile(try input(cast: [friend, hero]))

        XCTAssertEqual(forward.fingerprint, reversed.fingerprint,
                       "Cast is ordered by role then name before compiling")
        XCTAssertTrue(forward.identityClauses.first?.contains("Deniz") == true,
                      "The protagonist leads the identity clauses")
    }

    func testDescriptorOrderWithinIdentityDoesNotChangeOutput() throws {
        let a = VisualFixtures.character(descriptors: [
            CharacterDescriptor(category: .eyes, value: "brown eyes"),
            CharacterDescriptor(category: .hair, value: "curly black hair")
        ])
        let b = VisualFixtures.character(descriptors: [
            CharacterDescriptor(category: .hair, value: "curly black hair"),
            CharacterDescriptor(category: .eyes, value: "brown eyes")
        ])
        XCTAssertEqual(
            try compiler.compile(try input(cast: [a])).identityClauses,
            try compiler.compile(try input(cast: [b])).identityClauses
        )
    }

    func testSeedChangesFingerprintButNotClauses() throws {
        let cast = [VisualFixtures.character()]
        let a = try compiler.compile(try input(cast: cast, seed: 1))
        let b = try compiler.compile(try input(cast: cast, seed: 2))

        XCTAssertEqual(a.identityClauses, b.identityClauses)
        XCTAssertEqual(a.styleClauses, b.styleClauses)
        XCTAssertNotEqual(a.fingerprint, b.fingerprint, "A reroll must count as a different image")
    }

    // MARK: - Identity comes only from the Character Engine

    func testIdentityClausesContainOnlyResolvedDescriptors() throws {
        let character = VisualFixtures.character(descriptors: [
            CharacterDescriptor(category: .hair, value: "curly black hair"),
            CharacterDescriptor(category: .clothingDefault, value: "yellow raincoat")
        ])
        let set = try compiler.compile(try input(cast: [character]))
        let joined = set.identityClauses.joined(separator: " | ")

        XCTAssertTrue(joined.contains("curly black hair"))
        XCTAssertTrue(joined.contains("yellow raincoat"))

        // Nothing outside the identity may appear as an appearance claim.
        let lexicon = DescriptorLexicon.builtIn(languageCode: "en")
        XCTAssertTrue(
            lexicon.violations(in: joined, authorizedBy: character.identity).isEmpty,
            "Compiled identity clauses must survive the same gate generated text does"
        )
    }

    func testSceneClausesNeverCarryAppearance() throws {
        // Scene context is the one caller-supplied free-text channel; it must
        // not become a back door for describing the child.
        let character = VisualFixtures.character()
        let scene = SceneVisualContext(
            settingKey: "beach",
            timeOfDayKey: "noon",
            moodKey: "bright",
            sceneClauses: ["waves on warm sand"]
        )
        let set = try compiler.compile(try input(cast: [character], sceneContext: scene))

        let lexicon = DescriptorLexicon.builtIn(languageCode: "en")
        XCTAssertTrue(lexicon.violations(in: set.sceneClauses.joined(separator: " "), authorizedBy: character.identity).isEmpty)
    }

    func testEmptyDescriptorsProduceNoAppearanceClaims() throws {
        let character = VisualFixtures.character(descriptors: [])
        let set = try compiler.compile(try input(cast: [character]))

        XCTAssertEqual(set.identityClauses, ["Deniz, age 6"],
                       "With nothing known, the engine says nothing beyond name and age")
    }

    // MARK: - Negatives and safety

    func testForbiddenClausesAlwaysPresent() throws {
        let set = try compiler.compile(try input())
        XCTAssertTrue(set.negativeClauses.contains("text"))
        XCTAssertTrue(set.negativeClauses.contains("watermark"))
        XCTAssertTrue(set.negativeClauses.contains("photorealistic rendering"),
                      "Preset-level negatives stack on the illustration style's own")
    }

    func testDoNotDepictReachesTheNegativePrompt() throws {
        let character = VisualFixtures.character(doNotDepict: ["hospital equipment"])
        let set = try compiler.compile(try input(cast: [character]))
        XCTAssertTrue(set.negativePrompt.contains("hospital equipment"))
    }

    func testNegativeClausesAreDeduplicated() throws {
        let character = VisualFixtures.character(negativeTraits: ["text", "TEXT", "blurry"])
        let set = try compiler.compile(try input(cast: [character]))
        XCTAssertEqual(set.negativeClauses.filter { $0.lowercased() == "text" }.count, 1)
    }

    // MARK: - Composition and variants

    func testVariantOverridesCompositionRule() throws {
        let set = try compiler.compile(try input(variant: VisualVariant(compositionRuleID: "centered_portrait")))
        XCTAssertEqual(set.aspectRatio, .portrait)
        XCTAssertTrue(set.compositionClauses.contains("subject centered in frame"))
    }

    func testSceneCompositionUsedWhenVariantIsSilent() throws {
        let scene = SceneVisualContext(
            settingKey: "castle gate", timeOfDayKey: "dawn", moodKey: "grand",
            compositionRuleID: "full_bleed_establishing"
        )
        let set = try compiler.compile(try input(sceneContext: scene))
        XCTAssertTrue(set.compositionClauses.contains("establishing shot of the whole setting"))
    }

    func testVariantBeatsSceneWhichBeatsPresetDefault() throws {
        let scene = SceneVisualContext(
            settingKey: "castle gate", timeOfDayKey: "dawn", moodKey: "grand",
            compositionRuleID: "full_bleed_establishing"
        )
        let set = try compiler.compile(
            try input(variant: VisualVariant(compositionRuleID: "centered_portrait"), sceneContext: scene)
        )
        XCTAssertTrue(set.compositionClauses.contains("close-up shot"))
    }

    func testVariantCanOverrideCameraWithoutANewRule() throws {
        let set = try compiler.compile(try input(variant: VisualVariant(cameraDistance: .wide)))
        XCTAssertTrue(set.compositionClauses.contains("wide shot"))
        XCTAssertTrue(set.compositionClauses.contains("subject positioned on the right third of the frame"),
                      "The rest of the rule is untouched")
    }

    func testPoseAndEmotionalBeatBecomeClauses() throws {
        let set = try compiler.compile(
            try input(variant: VisualVariant(characterPoseKey: "reaching upward", emotionalBeatKey: "hopeful"))
        )
        XCTAssertTrue(set.compositionClauses.contains("character pose: reaching upward"))
        XCTAssertTrue(set.compositionClauses.contains("emotional tone: hopeful"))
    }

    func testUnknownCompositionRuleThrows() throws {
        XCTAssertThrowsError(
            try compiler.compile(try input(variant: VisualVariant(compositionRuleID: "ghost_rule")))
        ) { error in
            XCTAssertEqual(error as? VisualSystemError, .compositionRuleNotFound("ghost_rule"))
        }
    }

    func testTextSafeAreaReachesTheProvider() throws {
        let set = try compiler.compile(try input())
        XCTAssertTrue(
            set.compositionClauses.contains(where: { $0.contains("uncluttered for text") }),
            "The illustration must be told to keep the typography area quiet"
        )
    }

    // MARK: - References

    func testReferenceLocatorsFollowTheAssetChain() throws {
        let assetSet = CharacterAssetSet(
            masterReference: CharacterAsset(role: .master, locator: "master.jpg", createdAt: VisualFixtures.referenceDate),
            fullBodyReference: CharacterAsset(role: .fullBody, locator: "body.jpg", createdAt: VisualFixtures.referenceDate),
            identitySeed: 7,
            stylePresetID: "magic_paper_v1"
        )
        let character = VisualFixtures.character(assetSet: assetSet)
        let set = try compiler.compile(try input(cast: [character], preferredAssetRole: .fullBody))

        XCTAssertEqual(set.referenceLocators, ["body.jpg", "master.jpg"])
    }

    func testReferenceLocatorsAreDeduplicatedAcrossCast() throws {
        let shared = CharacterAssetSet(
            masterReference: CharacterAsset(role: .master, locator: "same.jpg", createdAt: VisualFixtures.referenceDate),
            identitySeed: 7,
            stylePresetID: "magic_paper_v1"
        )
        let a = VisualFixtures.character(name: "A", role: .protagonist, assetSet: shared)
        let b = VisualFixtures.character(name: "B", role: .companion, assetSet: shared)

        XCTAssertEqual(try compiler.compile(try input(cast: [a, b])).referenceLocators, ["same.jpg"])
    }

    // MARK: - Provenance

    func testProvenancePinsStyleAndCharacterVersions() throws {
        let character = VisualFixtures.character()
        let set = try compiler.compile(try input(cast: [character]))

        XCTAssertTrue(set.provenance.contains("preset:magic_paper_v1@1.0.0"))
        XCTAssertTrue(set.provenance.contains("composition:character_right_text_left@1.0.0"))
        XCTAssertTrue(set.provenance.contains("character:\(character.characterID)@\(character.versionID)"))
    }

    func testPromptsAreBuiltInAFixedOrder() throws {
        let set = try compiler.compile(try input())
        let prompt = set.positivePrompt

        let sceneIndex = try XCTUnwrap(prompt.range(of: "setting: forest clearing")).lowerBound
        let identityIndex = try XCTUnwrap(prompt.range(of: "Deniz, age 6")).lowerBound
        let styleIndex = try XCTUnwrap(prompt.range(of: "hand-painted children's storybook illustration")).lowerBound

        XCTAssertLessThan(sceneIndex, identityIndex)
        XCTAssertLessThan(identityIndex, styleIndex)
    }
}
