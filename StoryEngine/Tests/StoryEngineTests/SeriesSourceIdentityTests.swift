import XCTest
@testable import StoryEngine

final class SeriesSourceIdentityTests: XCTestCase {
    private func reference(_ digit: Character = "a") throws -> ContentSourceReference {
        try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: String(digit), count: 64))
    }

    private func plan(source: ContentSourceMetadata?) -> SeriesPlan {
        SeriesPlan(seed: "source-test", catalogVersion: "2.1.0", mode: .learning,
                   ageBand: AgeBand(lowerBound: 5, upperBound: 6),
                   anchor: SeriesAnchor(settingID: "missing", companionID: "missing", keepsakeID: "missing"),
                   family: nil, episodes: [], contentSource: source)
    }

    func testRemovingFamilyKeepsExactSource() throws {
        let source = ContentSourceMetadata(try reference())
        XCTAssertEqual(plan(source: source).withoutFamily().contentSource, source)
    }

    func testOldPlanWithoutSourceStillDecodes() throws {
        let data = try JSONEncoder().encode(plan(source: nil))
        XCTAssertNil(try JSONDecoder().decode(SeriesPlan.self, from: data).contentSource)
    }

    func testMalformedSourceDoesNotLoseThePlan() throws {
        var value = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(plan(source: nil))) as? [String: Any])
        value["contentSource"] = ["schemaVersion": 1, "payloadSHA256": true]
        let decoded = try JSONDecoder().decode(SeriesPlan.self, from: JSONSerialization.data(withJSONObject: value))
        XCTAssertNotNil(decoded.contentSource)
        XCTAssertNil(decoded.contentSource?.reference)
        let roundTrip = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(decoded)) as? [String: Any])
        XCTAssertEqual((roundTrip["contentSource"] as? NSDictionary), (value["contentSource"] as? NSDictionary))
    }

    func testExactPlanRejectsWrongSourceBeforeLookingUpContent() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        XCTAssertThrowsError(try SeriesPlanner().compose(
            plan(source: ContentSourceMetadata(try reference())), childName: "Deniz", family: nil,
            catalog: catalog, sourceReference: reference("b"))) {
            XCTAssertEqual($0 as? SeriesPlanningError, .sourceMismatch)
        }
    }

    func testExactPlanMayNotBeRewrittenWithoutSourceEvidence() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        XCTAssertThrowsError(try SeriesPlanner().compose(
            plan(source: ContentSourceMetadata(try reference())), childName: "Deniz", family: nil, catalog: catalog)) {
            XCTAssertEqual($0 as? SeriesPlanningError, .sourceMismatch)
        }
    }
}
