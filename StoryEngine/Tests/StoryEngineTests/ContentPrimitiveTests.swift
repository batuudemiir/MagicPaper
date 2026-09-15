import XCTest
@testable import StoryEngine

final class AgeBandTests: XCTestCase {
    func testParsesTheCatalogForm() {
        let band = AgeBand("5-6")
        XCTAssertEqual(band?.lowerBound, 5)
        XCTAssertEqual(band?.upperBound, 6)
    }

    func testRejectsMalformed() {
        XCTAssertNil(AgeBand("5"))
        XCTAssertNil(AgeBand("five-six"))
        XCTAssertNil(AgeBand(""))
    }

    func testInvertedBoundsAreNormalised() {
        let band = AgeBand(lowerBound: 9, upperBound: 3)
        XCTAssertEqual(band.lowerBound, 3)
        XCTAssertEqual(band.upperBound, 9)
    }

    func testContainment() {
        let band = AgeBand("5-7")!
        XCTAssertTrue(band.contains(5))
        XCTAssertTrue(band.contains(7))
        XCTAssertFalse(band.contains(4))
        XCTAssertFalse(band.contains(8))
    }

    func testRoundTripsAsAString() throws {
        let decoded = try JSONDecoder().decode([AgeBand].self, from: Data(#"["5-6"]"#.utf8))
        XCTAssertEqual(decoded.first?.description, "5-6")
        let data = try JSONEncoder().encode(decoded)
        XCTAssertEqual(String(data: data, encoding: .utf8), #"["5-6"]"#)
    }

    func testDecodingGarbageThrows() {
        XCTAssertThrowsError(try JSONDecoder().decode([AgeBand].self, from: Data(#"["abc"]"#.utf8)))
    }
}

final class ContentTagTests: XCTestCase {
    func testTagsAreCaseInsensitive() {
        XCTAssertEqual(ContentTag("Forest"), ContentTag("forest"))
        XCTAssertEqual(ContentTag("OCEAN").rawValue, "ocean")
    }

    func testIdsAreNotTags() {
        // Distinct types on purpose: this is the mix-up that produced the
        // catalog's orphan references.
        XCTAssertEqual(ContentID("setting_forest_001").rawValue, "setting_forest_001")
        XCTAssertEqual(ContentTag("forest").rawValue, "forest")
    }
}

final class PageRoleTests: XCTestCase {
    func testTheMvpArcIsEightBeats() {
        XCTAssertEqual(PageRole.mvpArc.count, 8)
        XCTAssertEqual(PageRole.mvpArc.first, .hook)
        XCTAssertEqual(PageRole.mvpArc.last, .emotionalEnding)
    }

    func testSnakeCaseRolesMapToCamelCase() throws {
        let decoded = try JSONDecoder().decode([PageRole].self, from: Data(#"["emotional_ending","bedtime_transition"]"#.utf8))
        XCTAssertEqual(decoded, [.emotionalEnding, .bedtimeTransition])
    }

    func testUnknownRoleFailsRatherThanSilentlyDropping() {
        XCTAssertThrowsError(try JSONDecoder().decode([PageRole].self, from: Data(#"["dance_break"]"#.utf8)))
    }
}

final class ContentSlotTests: XCTestCase {
    func testFindsEveryTokenInText() {
        let slots = ContentSlot.tokens(in: "Merhaba {{child.name}}, {{setting.name}} güzel.")
        XCTAssertEqual(slots.map(\.rawValue), ["child.name", "setting.name"])
    }

    func testRepeatedTokensAreReportedOnce() {
        let slots = ContentSlot.tokens(in: "{{child.name}} ve yine {{child.name}}")
        XCTAssertEqual(slots.count, 1)
    }

    func testTextWithoutTokens() {
        XCTAssertTrue(ContentSlot.tokens(in: "Hiç yer tutucu yok.").isEmpty)
    }

    func testTokenForm() {
        XCTAssertEqual(ContentSlot("child.name").token, "{{child.name}}")
    }
}

final class NarrativeStateTests: XCTestCase {
    func testParsesKeyValueExpressions() {
        let fact = StateFact(expression: "problem_solved=true")
        XCTAssertEqual(fact?.key, "problem_solved")
        XCTAssertEqual(fact?.value, "true")
    }

    func testBareKeyMeansTrue() {
        // The shipped catalog writes some flags without a value.
        XCTAssertEqual(StateFact(expression: "heard_sound")?.value, "true")
    }

    func testNonBooleanValues() {
        let fact = StateFact(expression: "problem=crossing")
        XCTAssertEqual(fact?.value, "crossing")
    }

    func testRejectsEmptyAndKeylessExpressions() {
        XCTAssertNil(StateFact(expression: ""))
        XCTAssertNil(StateFact(expression: "   "))
        XCTAssertNil(StateFact(expression: "=true"))
    }

    func testSatisfactionRequiresAnExactMatch() {
        let state = NarrativeState(applying: [StateFact(key: "problem", value: "crossing")])
        XCTAssertTrue(state.satisfies(StateFact(key: "problem", value: "crossing")))
        XCTAssertFalse(state.satisfies(StateFact(key: "problem", value: "climbing")))
        XCTAssertFalse(state.satisfies(StateFact(key: "missing", value: "x")))
    }

    func testAllRequirementsMustHold() {
        let state = NarrativeState(applying: [
            StateFact(key: "a", value: "1"), StateFact(key: "b", value: "2")
        ])
        XCTAssertTrue(state.satisfies([StateFact(key: "a", value: "1"), StateFact(key: "b", value: "2")]))
        XCTAssertFalse(state.satisfies([StateFact(key: "a", value: "1"), StateFact(key: "c", value: "3")]))
    }

    func testAnEmptyRequirementListIsAlwaysSatisfied() {
        XCTAssertTrue(NarrativeState().satisfies([]))
    }

    func testApplyingOverwritesAnEarlierValue() {
        var state = NarrativeState(applying: [StateFact(key: "mood", value: "afraid")])
        state.apply(StateFact(key: "mood", value: "calm"))
        XCTAssertEqual(state["mood"], "calm")
    }

    func testApplyingIsNonMutatingInTheFunctionalForm() {
        let original = NarrativeState(applying: [StateFact(key: "a", value: "1")])
        let derived = original.applying([StateFact(key: "b", value: "2")])
        XCTAssertNil(original["b"])
        XCTAssertEqual(derived["a"], "1")
        XCTAssertEqual(derived["b"], "2")
    }

    func testStateFactRoundTripsAsAnExpression() throws {
        let decoded = try JSONDecoder().decode([StateFact].self, from: Data(#"["problem=crossing"]"#.utf8))
        let data = try JSONEncoder().encode(decoded)
        XCTAssertEqual(String(data: data, encoding: .utf8), #"["problem=crossing"]"#)
    }
}
