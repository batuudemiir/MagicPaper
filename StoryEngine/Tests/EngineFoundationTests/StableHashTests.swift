import XCTest
@testable import EngineFoundation

final class StableHashTests: XCTestCase {
    func testIsDeterministicWithinAndAcrossRuns() {
        // Pinned literal: if this changes, every stored scene fingerprint and
        // image seed in the wild silently invalidates.
        XCTAssertEqual(StableHash.fingerprint("magic", "paper"), StableHash.fingerprint("magic", "paper"))
        XCTAssertEqual(StableHash.fingerprint(["scene", "forest", "dusk"]), "5ecc46015f2cbaf0")
    }

    func testComponentBoundariesMatter() {
        XCTAssertNotEqual(StableHash.fingerprint("ab", "c"), StableHash.fingerprint("a", "bc"),
                          "Joining components must not collide")
    }

    func testOrderMatters() {
        XCTAssertNotEqual(StableHash.fingerprint("a", "b"), StableHash.fingerprint("b", "a"))
    }

    func testFingerprintIsFixedWidthHex() {
        XCTAssertEqual(StableHash.fingerprint("x").count, 16)
        XCTAssertEqual(StableHash.fingerprint([]).count, 16)
    }

    func testEmptyAndWhitespaceDiffer() {
        XCTAssertNotEqual(StableHash.fingerprint(""), StableHash.fingerprint(" "))
    }
}
