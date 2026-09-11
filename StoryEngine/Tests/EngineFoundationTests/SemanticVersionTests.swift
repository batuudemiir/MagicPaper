import XCTest
@testable import EngineFoundation

final class SemanticVersionTests: XCTestCase {
    func testParsesFullAndPartialStrings() {
        XCTAssertEqual(SemanticVersion("1.2.3"), SemanticVersion(1, 2, 3))
        XCTAssertEqual(SemanticVersion("2.1"), SemanticVersion(2, 1, 0))
        XCTAssertEqual(SemanticVersion("3"), SemanticVersion(3, 0, 0))
    }

    func testRejectsMalformedStrings() {
        XCTAssertNil(SemanticVersion("1.2.3.4"))
        XCTAssertNil(SemanticVersion("1.x.0"))
        XCTAssertNil(SemanticVersion(""))
        XCTAssertNil(SemanticVersion("-1.0.0"))
    }

    func testOrdering() {
        XCTAssertLessThan(SemanticVersion(1, 0, 0), SemanticVersion(1, 0, 1))
        XCTAssertLessThan(SemanticVersion(1, 9, 9), SemanticVersion(2, 0, 0))
        XCTAssertGreaterThan(SemanticVersion(1, 10, 0), SemanticVersion(1, 9, 0))
    }

    func testCompatibilityRequiresSameMajorAndNotOlder() {
        XCTAssertTrue(SemanticVersion(1, 2, 0).isCompatible(with: SemanticVersion(1, 3, 0)))
        XCTAssertTrue(SemanticVersion(1, 2, 0).isCompatible(with: SemanticVersion(1, 2, 0)))
        XCTAssertFalse(SemanticVersion(1, 2, 0).isCompatible(with: SemanticVersion(1, 1, 0)))
        XCTAssertFalse(SemanticVersion(1, 2, 0).isCompatible(with: SemanticVersion(2, 0, 0)))
    }

    func testRequirementSatisfaction() {
        XCTAssertTrue(VersionRequirement.latest.isSatisfied(by: SemanticVersion(9, 9, 9)))
        XCTAssertTrue(VersionRequirement.exact(SemanticVersion(1, 2, 0)).isSatisfied(by: SemanticVersion(1, 2, 0)))
        XCTAssertFalse(VersionRequirement.exact(SemanticVersion(1, 2, 0)).isSatisfied(by: SemanticVersion(1, 2, 1)))
        XCTAssertTrue(VersionRequirement.compatible(SemanticVersion(1, 0, 0)).isSatisfied(by: SemanticVersion(1, 5, 0)))
        XCTAssertFalse(VersionRequirement.compatible(SemanticVersion(1, 0, 0)).isSatisfied(by: SemanticVersion(2, 0, 0)))
    }

    func testEncodesAsReadableString() throws {
        let data = try JSONEncoder().encode(["version": SemanticVersion(1, 2, 0)])
        XCTAssertEqual(String(data: data, encoding: .utf8), #"{"version":"1.2.0"}"#)
    }

    func testDecodesFromString() throws {
        let decoded = try JSONDecoder().decode([String: SemanticVersion].self, from: Data(#"{"v":"4.5.6"}"#.utf8))
        XCTAssertEqual(decoded["v"], SemanticVersion(4, 5, 6))
    }

    func testDecodingRejectsGarbage() {
        XCTAssertThrowsError(try JSONDecoder().decode([String: SemanticVersion].self, from: Data(#"{"v":"nope"}"#.utf8)))
    }
}

final class VersionRequirementCodingTests: XCTestCase {
    func testLatestIsABareString() throws {
        let data = try JSONEncoder().encode([VersionRequirement.latest])
        XCTAssertEqual(String(data: data, encoding: .utf8), #"["latest"]"#)
    }

    func testExactAndCompatibleAreNamedObjects() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        XCTAssertEqual(
            String(data: try encoder.encode([VersionRequirement.exact(SemanticVersion(1, 2, 0))]), encoding: .utf8),
            #"[{"exact":"1.2.0"}]"#
        )
        XCTAssertEqual(
            String(data: try encoder.encode([VersionRequirement.compatible(SemanticVersion(2, 0, 0))]), encoding: .utf8),
            #"[{"compatible":"2.0.0"}]"#
        )
    }

    func testRoundTripsAllCases() throws {
        let values: [VersionRequirement] = [.latest, .exact(SemanticVersion(1, 0, 0)), .compatible(SemanticVersion(3, 1, 4))]
        let decoded = try JSONDecoder().decode([VersionRequirement].self, from: JSONEncoder().encode(values))
        XCTAssertEqual(decoded, values)
    }

    func testRejectsUnknownStringAndEmptyObject() {
        XCTAssertThrowsError(try JSONDecoder().decode([VersionRequirement].self, from: Data(#"["newest"]"#.utf8)))
        XCTAssertThrowsError(try JSONDecoder().decode([VersionRequirement].self, from: Data(#"[{}]"#.utf8)))
    }
}
