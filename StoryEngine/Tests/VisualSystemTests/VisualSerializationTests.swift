import XCTest
import EngineFoundation
@testable import VisualSystem

final class VisualSerializationTests: XCTestCase {
    private func roundTrip<T: Codable & Equatable>(_ value: T, file: StaticString = #filePath, line: UInt = #line) throws {
        let decoded = try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))
        XCTAssertEqual(decoded, value, file: file, line: line)
    }

    func testCatalogRoundTrips() throws {
        try roundTrip(VisualCatalog.builtIn)
    }

    func testResolvedStyleRoundTrips() throws {
        try roundTrip(try VisualFixtures.resolvedStyle())
    }

    func testConstraintSetRoundTrips() throws {
        let set = try PromptConstraintCompiler().compile(
            VisualCompilationInput(
                style: try VisualFixtures.resolvedStyle(),
                sceneContext: VisualFixtures.sceneContext,
                cast: [VisualFixtures.character()],
                seed: 99
            )
        )
        try roundTrip(set)
    }

    func testLayoutRuleUsesNamedWordBudgetKeys() throws {
        let rule = PageLayoutRule(
            id: "r", version: SemanticVersion(1, 2, 0), layout: .spread,
            appliesTo: LayoutPredicate(positions: [.first]),
            compositionRuleID: "c", typographyPresetID: "t", textWordBudget: 40...90
        )
        let object = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(rule)) as? [String: Any]
        )
        XCTAssertEqual(object["minimumWords"] as? Int, 40)
        XCTAssertEqual(object["maximumWords"] as? Int, 90)
        XCTAssertEqual(object["version"] as? String, "1.2.0")
        try roundTrip(rule)
    }

    func testInvertedWordBudgetIsRejected() {
        let json = """
        {"id":"r","version":"1.0.0","layout":"spread","compositionRuleID":"c",
         "typographyPresetID":"t","minimumWords":90,"maximumWords":40}
        """
        XCTAssertThrowsError(try JSONDecoder().decode(PageLayoutRule.self, from: Data(json.utf8)))
    }

    func testMissingPredicateDefaultsToAlways() throws {
        let json = """
        {"id":"r","version":"1.0.0","layout":"textOnly","compositionRuleID":"c",
         "typographyPresetID":"t","minimumWords":10,"maximumWords":20}
        """
        let rule = try JSONDecoder().decode(PageLayoutRule.self, from: Data(json.utf8))
        XCTAssertEqual(rule.appliesTo, .always)
    }

    func testVariantFingerprintComponentsAreStable() {
        let variant = VisualVariant(cameraDistance: .wide, characterPoseKey: "running", emotionalBeatKey: "joy")
        XCTAssertEqual(variant.fingerprintComponents, [
            "camera:wide", "pose:running", "beat:joy", "aspect:-", "composition:-"
        ])
    }
}
