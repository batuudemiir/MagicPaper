import XCTest
import VisualSystem
@testable import StoryEngine

final class BeatPlanningTests: XCTestCase {
    private let planner = BeatPlanner()

    func testRequestedPageCountIsHonoured() throws {
        for pageCount in 5...16 {
            let plan = try planner.plan(template: StoryFixtures.adventureTemplate, requestedPageCount: pageCount)
            XCTAssertEqual(plan.effectivePageCount, pageCount, "Asked for \(pageCount)")
            XCTAssertFalse(plan.wasClamped)
        }
    }

    func testTooManyPagesClampsToTheTemplateCeiling() throws {
        let plan = try planner.plan(template: StoryFixtures.adventureTemplate, requestedPageCount: 40)
        XCTAssertEqual(plan.effectivePageCount, 16)
        XCTAssertTrue(plan.wasClamped)
    }

    func testTooFewPagesClampsToTheTemplateFloor() throws {
        let plan = try planner.plan(template: StoryFixtures.adventureTemplate, requestedPageCount: 1)
        XCTAssertEqual(plan.effectivePageCount, 5)
        XCTAssertTrue(plan.wasClamped)
    }

    func testArcAlwaysOpensAndCloses() throws {
        for pageCount in 5...16 {
            let plan = try planner.plan(template: StoryFixtures.adventureTemplate, requestedPageCount: pageCount)
            XCTAssertEqual(plan.beats.first?.beat.role, .opening, "\(pageCount) pages")
            XCTAssertEqual(plan.beats.last?.beat.role, .closing, "\(pageCount) pages")
        }
    }

    func testRolesStayInOrder() throws {
        let plan = try planner.plan(template: StoryFixtures.adventureTemplate, requestedPageCount: 11)
        let ranks = plan.beats.map { beat -> Int in
            switch beat.beat.role {
            case .opening: return 0
            case .middle: return 1
            case .closing: return 2
            }
        }
        XCTAssertEqual(ranks, ranks.sorted(), "Openings, then middles, then closings")
    }

    func testMiddleStretchesToAbsorbExtraPages() throws {
        let short = try planner.plan(template: StoryFixtures.adventureTemplate, requestedPageCount: 6)
        let long = try planner.plan(template: StoryFixtures.adventureTemplate, requestedPageCount: 14)

        XCTAssertEqual(short.beats(role: .opening).count, long.beats(role: .opening).count)
        XCTAssertEqual(short.beats(role: .closing).count, long.beats(role: .closing).count)
        XCTAssertGreaterThan(long.beats(role: .middle).count, short.beats(role: .middle).count,
                             "Extra length lands on the middle, not the ending")
    }

    func testClosingIsReservedWhenPagesAreScarce() throws {
        // Two openings, two closings, one middle, but only three pages.
        let template = StoryFixtures.template(pageRange: 3...6)
        let plan = try planner.plan(template: template, requestedPageCount: 3)

        XCTAssertEqual(plan.effectivePageCount, 3)
        XCTAssertEqual(plan.beats(role: .closing).count, 2, "A story without an ending is the worse failure")
        XCTAssertEqual(plan.beats(role: .opening).count, 1)
    }

    func testEveryMiddleBeatIsUsedBeforeAnyRepeats() throws {
        let template = StoryFixtures.template(beats: [
            StoryFixtures.beat(id: "o", role: .opening),
            StoryFixtures.beat(id: "m1", role: .middle, repeatable: true),
            StoryFixtures.beat(id: "m2", role: .middle, repeatable: true),
            StoryFixtures.beat(id: "m3", role: .middle),
            StoryFixtures.beat(id: "c", role: .closing)
        ], pageRange: 3...9)

        let plan = try planner.plan(template: template, requestedPageCount: 5)
        let middles = plan.beats(role: .middle).map(\.beat.id)
        XCTAssertEqual(middles, ["m1", "m2", "m3"], "Declared order first, each once")
    }

    func testOnlyRepeatableBeatsAreReused() throws {
        let template = StoryFixtures.template(beats: [
            StoryFixtures.beat(id: "o", role: .opening),
            StoryFixtures.beat(id: "m1", role: .middle, repeatable: true),
            StoryFixtures.beat(id: "m2", role: .middle),
            StoryFixtures.beat(id: "c", role: .closing)
        ], pageRange: 3...9)

        let plan = try planner.plan(template: template, requestedPageCount: 7)
        let counts = Dictionary(grouping: plan.beats, by: { $0.beat.id }).mapValues(\.count)

        XCTAssertEqual(counts["m2"], 1, "A non-repeatable beat appears once")
        XCTAssertGreaterThan(counts["m1"] ?? 0, 1, "Repeatable beats cycle to fill")
    }

    func testOccurrenceIndexCountsRepeats() throws {
        let template = StoryFixtures.template(beats: [
            StoryFixtures.beat(id: "o", role: .opening),
            StoryFixtures.beat(id: "m", role: .middle, repeatable: true),
            StoryFixtures.beat(id: "c", role: .closing)
        ], pageRange: 3...9)

        let plan = try planner.plan(template: template, requestedPageCount: 5)
        let occurrences = plan.beats.filter { $0.beat.id == "m" }.map(\.occurrence)
        XCTAssertEqual(occurrences, [0, 1, 2])
    }

    func testWithoutRepeatablesThePlanCannotExceedItsBeats() throws {
        let template = StoryFixtures.template(beats: [
            StoryFixtures.beat(id: "o", role: .opening),
            StoryFixtures.beat(id: "m", role: .middle),
            StoryFixtures.beat(id: "c", role: .closing)
        ], pageRange: 3...12)

        let plan = try planner.plan(template: template, requestedPageCount: 12)
        XCTAssertEqual(plan.effectivePageCount, 3, "Nothing repeats, so three beats is three pages")
        XCTAssertTrue(plan.wasClamped)
    }

    func testEmptyTemplateThrows() {
        XCTAssertThrowsError(try planner.plan(template: StoryFixtures.template(beats: []), requestedPageCount: 5)) { error in
            XCTAssertEqual(error as? StoryEngineError, .templateHasNoBeats("test_template"))
        }
    }

    func testPlanningIsDeterministic() throws {
        let a = try planner.plan(template: StoryFixtures.adventureTemplate, requestedPageCount: 9)
        let b = try planner.plan(template: StoryFixtures.adventureTemplate, requestedPageCount: 9)
        XCTAssertEqual(a, b)
    }
}

final class PagePlannerTests: XCTestCase {

    func testPagesAreIndexedAndOrdered() throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 9)
        XCTAssertEqual(planned.pages.count, 9)
        XCTAssertEqual(planned.pages.map(\.index), Array(0..<9))
    }

    func testEveryPageGetsLayoutCompositionTypographyAndBudget() throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 9)
        for page in planned.pages {
            XCTAssertFalse(page.layoutRuleID.isEmpty)
            XCTAssertFalse(page.compositionRuleID.isEmpty)
            XCTAssertFalse(page.typographyPresetID.isEmpty)
            XCTAssertLessThanOrEqual(page.minimumWords, page.maximumWords)
            XCTAssertGreaterThan(page.maximumWords, 0)
        }
    }

    func testFirstPageUsesTheOpeningLayout() throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 7)
        XCTAssertEqual(planned.pages.first?.layout, .spread)
        XCTAssertEqual(planned.pages.first?.layoutRuleID, "layout_opening_spread")
    }

    func testLastPageUsesTheClosingLayout() throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 7)
        XCTAssertEqual(planned.pages.last?.layoutRuleID, "layout_closing_quiet")
    }

    func testBeatCompositionOverridesTheLayoutRule() throws {
        // The shipped opening beat asks for an establishing shot; the closing
        // beat asks for the quiet framing.
        let planned = try StoryFixtures.plannedStory(pageCount: 7)
        XCTAssertEqual(planned.pages.first?.compositionRuleID, "full_bleed_establishing")
        XCTAssertEqual(planned.pages.last?.compositionRuleID, "quiet_closing")
    }

    func testPlanningIsDeterministicForIdenticalInput() throws {
        let a = try StoryFixtures.plannedStory(pageCount: 8, ids: SequentialIDGenerator())
        let b = try StoryFixtures.plannedStory(pageCount: 8, ids: SequentialIDGenerator())
        XCTAssertEqual(a.pages, b.pages)
        XCTAssertEqual(a.scenes, b.scenes)
    }

    func testEveryPageBelongsToAPlannedScene() throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 11)
        let sceneIDs = Set(planned.scenes.map(\.id))
        for page in planned.pages {
            XCTAssertTrue(sceneIDs.contains(page.sceneID), "Page \(page.index) points at an unknown scene")
        }
    }

    func testPagesCarryTheirBeatIdentity() throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 7)
        for page in planned.pages {
            let beat = planned.outline.beat(id: page.outlineBeatID)
            XCTAssertNotNil(beat)
            XCTAssertEqual(beat?.templateBeatID, page.templateBeatID)
            XCTAssertEqual(beat?.role, page.beatRole)
        }
    }

    func testMissingSceneMappingThrows() throws {
        let resolved = try StoryFixtures.resolvedTemplate()
        let plan = try BeatPlanner().plan(template: resolved.template, requestedPageCount: 6)
        let outline = StoryFixtures.outline(from: plan)

        XCTAssertThrowsError(
            try PagePlanner(idGenerator: SequentialIDGenerator())
                .planPages(outline: outline, template: resolved, sceneIDByBeatID: [:])
        ) { error in
            guard case .sceneNotFound = error as? StoryEngineError else {
                return XCTFail("Expected sceneNotFound, got \(error)")
            }
        }
    }

    func testPageCountsFromFiveToSixteenAllPlanCleanly() throws {
        for pageCount in 5...16 {
            let planned = try StoryFixtures.plannedStory(pageCount: pageCount)
            XCTAssertEqual(planned.pages.count, pageCount)
            XCTAssertFalse(planned.scenes.isEmpty)
        }
    }
}
