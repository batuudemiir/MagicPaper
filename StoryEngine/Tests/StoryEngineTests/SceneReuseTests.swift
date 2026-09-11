import XCTest
import CharacterEngine
import VisualSystem
@testable import StoryEngine

final class SceneReuseTests: XCTestCase {
    static let testStoryID = UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000001")!


    // MARK: - Grouping

    func testConsecutiveBeatsInTheSamePlaceShareAScene() throws {
        let template = StoryFixtures.template(beats: [
            StoryFixtures.beat(id: "a", role: .opening, setting: "clearing", timeOfDay: "noon"),
            StoryFixtures.beat(id: "b", role: .middle, setting: "clearing", timeOfDay: "noon"),
            StoryFixtures.beat(id: "c", role: .middle, setting: "clearing", timeOfDay: "noon"),
            StoryFixtures.beat(id: "d", role: .closing, setting: "home", timeOfDay: "night")
        ], pageRange: 4...4)

        let planned = try StoryFixtures.plannedStory(template: template, pageCount: 4)

        XCTAssertEqual(planned.scenes.count, 2, "Three clearing pages are one scene")
        XCTAssertEqual(planned.scenes[0].pageIDs.count, 3)
        XCTAssertEqual(planned.scenes[1].pageIDs.count, 1)
    }

    func testChangingSettingStartsANewScene() throws {
        let template = StoryFixtures.template(beats: [
            StoryFixtures.beat(id: "a", role: .opening, setting: "home"),
            StoryFixtures.beat(id: "b", role: .middle, setting: "forest"),
            StoryFixtures.beat(id: "c", role: .closing, setting: "home")
        ], pageRange: 3...3)

        let planned = try StoryFixtures.plannedStory(template: template, pageCount: 3)
        XCTAssertEqual(planned.scenes.count, 3, "Returning home later is a new visual moment, not the first one again")
    }

    func testMoodIsNotATriggerByDefault() throws {
        let template = StoryFixtures.template(beats: [
            StoryFixtures.beat(id: "a", role: .opening, setting: "clearing", mood: "calm"),
            StoryFixtures.beat(id: "b", role: .middle, setting: "clearing", mood: "tense"),
            StoryFixtures.beat(id: "c", role: .closing, setting: "clearing", mood: "joyful")
        ], pageRange: 3...3)

        let planned = try StoryFixtures.plannedStory(template: template, pageCount: 3)
        XCTAssertEqual(planned.scenes.count, 1, "Default triggers are setting, time and cast")
    }

    func testATemplateCanMakeMoodATrigger() throws {
        let template = StoryFixtures.template(
            beats: [
                StoryFixtures.beat(id: "a", role: .opening, setting: "clearing", mood: "calm"),
                StoryFixtures.beat(id: "b", role: .middle, setting: "clearing", mood: "tense"),
                StoryFixtures.beat(id: "c", role: .closing, setting: "clearing", mood: "joyful")
            ],
            sceneRules: SceneRules(maximumScenes: 8, changeTriggers: [.setting, .timeOfDay, .cast, .mood]),
            pageRange: 3...3
        )

        let planned = try StoryFixtures.plannedStory(template: template, pageCount: 3)
        XCTAssertEqual(planned.scenes.count, 3)
    }

    func testSceneCeilingIsRespected() throws {
        let beats = (0..<10).map { StoryFixtures.beat(id: "b\($0)", role: $0 == 0 ? .opening : ($0 == 9 ? .closing : .middle), setting: "place\($0)") }
        let template = StoryFixtures.template(
            beats: beats,
            sceneRules: SceneRules(maximumScenes: 3),
            pageRange: 10...10
        )

        let planned = try StoryFixtures.plannedStory(template: template, pageCount: 10)
        XCTAssertEqual(planned.scenes.count, 3, "The ceiling caps how many pictures a book can need")
        XCTAssertEqual(planned.scenes.reduce(0) { $0 + $1.pageIDs.count }, 10, "Every page still has a scene")
    }

    func testShippedTemplateReusesScenesAcrossPages() throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 11)
        XCTAssertLessThan(planned.scenes.count, planned.pages.count,
                          "An 11-page book must not need 11 illustrations")
    }

    // MARK: - Assets

    private func planAssets(_ planned: StoryFixtures.PlannedStory, ids: IDGenerator = SequentialIDGenerator(startingAt: 500)) throws -> [StoryScene] {
        try VisualPlanner(idGenerator: ids).planAssets(
            scenes: planned.scenes,
            pages: planned.pages,
            characters: planned.characters,
            template: planned.template,
            storyID: UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000001")!,
            seedPolicy: .deterministic
        )
    }

    func testSingleAssetPolicyGivesOnePicturePerScene() throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 11)
        let scenes = try planAssets(planned)

        for scene in scenes {
            XCTAssertEqual(scene.visualAssets.count, 1, "Scene \(scene.index) should own exactly one asset")
        }
    }

    func testAssetPerVariantPolicyCanGiveASceneSeveralPictures() throws {
        // Same place throughout, but the first and last pages ask for different
        // shots — the case a scene-equals-image model could not express.
        let template = StoryFixtures.template(
            beats: [
                StoryFixtures.beat(id: "a", role: .opening, setting: "clearing", compositionRuleID: "full_bleed_establishing"),
                StoryFixtures.beat(id: "b", role: .middle, setting: "clearing"),
                StoryFixtures.beat(id: "c", role: .closing, setting: "clearing", compositionRuleID: "centered_portrait")
            ],
            sceneRules: SceneRules(maximumScenes: 8, visualPolicy: .assetPerVariant),
            pageRange: 3...3
        )
        let planned = try StoryFixtures.plannedStory(template: template, pageCount: 3)
        let scenes = try planAssets(planned)

        XCTAssertEqual(scenes.count, 1, "It is all one place")
        XCTAssertEqual(scenes[0].visualAssets.count, 3, "But three different shots of it")
        XCTAssertEqual(Set(scenes[0].visualAssets.map(\.fingerprint)).count, 3, "Each shot is its own picture")
    }

    func testPagesSharingASceneShareItsAsset() throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 11)
        let scenes = try planAssets(planned)
        let pages = VisualPlanner().assigning(pages: planned.pages, to: scenes, policy: .singleAssetPerScene)

        for scene in scenes {
            let assetIDs = Set(pages.filter { $0.sceneID == scene.id }.compactMap(\.visualAssetID))
            XCTAssertLessThanOrEqual(assetIDs.count, 1, "Scene \(scene.index) pages should point at one asset")
        }
        XCTAssertTrue(pages.allSatisfy { !$0.requiresImage || $0.visualAssetID != nil })
    }

    // MARK: - Generation is skipped when nothing changed

    private func makeService(_ provider: FakeImageProvider, budget: GenerationBudget = .standard) -> ImageGenerationService {
        ImageGenerationService(
            provider: provider,
            budget: GenerationBudgetManager(budget: budget),
            policy: RetryPolicy(maximumAttempts: 2),
            clock: FixedClock(autoAdvance: 1),
            idGenerator: SequentialIDGenerator(startingAt: 900)
        )
    }

    func testEachSceneIsDrawnOnce() async throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 11)
        let scenes = try planAssets(planned)
        let provider = FakeImageProvider()

        let result = try await makeService(provider).generateMissing(in: scenes, storyID: Self.testStoryID)

        XCTAssertEqual(provider.callCount, scenes.count)
        XCTAssertEqual(result.generatedCount, scenes.count)
        XCTAssertLessThan(provider.callCount, planned.pages.count, "Fewer images than pages is the point")
    }

    func testUnchangedAssetsCostNothingOnASecondPass() async throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 11)
        let scenes = try planAssets(planned)
        let provider = FakeImageProvider()
        let service = makeService(provider)

        let first = try await service.generateMissing(in: scenes, storyID: Self.testStoryID)
        let callsAfterFirst = provider.callCount

        let second = try await service.generateMissing(in: first.scenes, storyID: Self.testStoryID)

        XCTAssertEqual(provider.callCount, callsAfterFirst, "A second pass must issue zero provider calls")
        XCTAssertEqual(second.generatedCount, 0)
        XCTAssertEqual(second.skippedCount, scenes.count)
    }

    func testReplanningKeepsReadyImagesWhenNothingMaterialChanged() async throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 9)
        let scenes = try planAssets(planned)
        let provider = FakeImageProvider()
        let drawn = try await makeService(provider).generateMissing(in: scenes, storyID: Self.testStoryID).scenes

        // Re-run the visual planner over already-drawn scenes.
        let replanned = try VisualPlanner(idGenerator: SequentialIDGenerator(startingAt: 700)).planAssets(
            scenes: drawn,
            pages: planned.pages,
            characters: planned.characters,
            template: planned.template,
            storyID: UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000001")!,
            seedPolicy: .deterministic
        )

        XCTAssertTrue(replanned.allSatisfy { $0.visualAssets.allSatisfy(\.isReady) },
                      "Re-planning must not throw away images that are still correct")
        XCTAssertEqual(ImageGenerationService(
            provider: provider,
            budget: GenerationBudgetManager(budget: .standard),
            policy: RetryPolicy(),
            clock: FixedClock()
        ).pendingAssetCount(in: replanned), 0)
    }

    func testChangingTheCharacterInvalidatesTheImage() async throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 7)
        let scenes = try planAssets(planned)
        let provider = FakeImageProvider()
        let drawn = try await makeService(provider).generateMissing(in: scenes, storyID: Self.testStoryID).scenes
        let callsAfterFirst = provider.callCount

        // A new identity version: different hair, so the pictures are wrong now.
        let newCast = StoryFixtures.storyCharacters(
            StoryFixtures.cast(
                StoryFixtures.resolvedCharacter(descriptors: [
                    CharacterDescriptor(category: .hair, value: "short red hair")
                ])
            )
        )
        let replanned = try VisualPlanner(idGenerator: SequentialIDGenerator(startingAt: 800)).planAssets(
            scenes: drawn,
            pages: planned.pages,
            characters: newCast,
            template: planned.template,
            storyID: UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000001")!,
            seedPolicy: .deterministic
        )

        XCTAssertTrue(replanned.allSatisfy { $0.visualAssets.allSatisfy { $0.state == .notRequested } })

        let redrawn = try await makeService(provider).generateMissing(in: replanned, storyID: Self.testStoryID)
        XCTAssertEqual(provider.callCount, callsAfterFirst + scenes.count, "Every picture is redrawn")
        XCTAssertEqual(redrawn.skippedCount, 0)
    }

    func testTextOnlySceneNeedsNoImage() throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 7)
        // Force every page to a text-only layout by emptying the page list the
        // planner sees for that scene.
        let scenes = try VisualPlanner(idGenerator: SequentialIDGenerator(startingAt: 600)).planAssets(
            scenes: planned.scenes,
            pages: [],
            characters: planned.characters,
            template: planned.template,
            storyID: UUID(),
            seedPolicy: .deterministic
        )
        XCTAssertTrue(scenes.allSatisfy(\.visualAssets.isEmpty))
    }

    func testSeedIsDeterministicAndRevisionChangesIt() throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 5)
        let storyID = UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000001")!
        let scene = planned.scenes[0]

        let a = VisualPlanner.seed(storyID: storyID, scene: scene, variant: .default,
                                   characters: planned.characters, seedPolicy: .deterministic, revision: 0)
        let b = VisualPlanner.seed(storyID: storyID, scene: scene, variant: .default,
                                   characters: planned.characters, seedPolicy: .deterministic, revision: 0)
        let rerolled = VisualPlanner.seed(storyID: storyID, scene: scene, variant: .default,
                                          characters: planned.characters, seedPolicy: .deterministic, revision: 1)

        XCTAssertEqual(a, b, "Same inputs, same picture")
        XCTAssertNotEqual(a, rerolled, "A reroll must land somewhere else")
    }

    func testSaltedSeedPolicyShiftsEverySeed() throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 5)
        let storyID = UUID()
        let plain = VisualPlanner.seed(storyID: storyID, scene: planned.scenes[0], variant: .default,
                                       characters: planned.characters, seedPolicy: .deterministic, revision: 0)
        let salted = VisualPlanner.seed(storyID: storyID, scene: planned.scenes[0], variant: .default,
                                        characters: planned.characters, seedPolicy: .salted(99), revision: 0)
        XCTAssertNotEqual(plain, salted)
    }
}
