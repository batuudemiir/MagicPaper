import Foundation
import XCTest
@testable import StoryEngine

final class P56PinTransitionTests: XCTestCase {
    private var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
    }
    func testApprovedActiveV3AndHistoricalPinsMatchExactBytes() throws {
        XCTAssertEqual(P56PinnedSource.packageVersion, "five-friends-56-runtime-v3")
        XCTAssertEqual(P56PinnedSource.sha256, "855870c8462f167b4031058897c2ddfc8c5f513802ad057758c86e3ff5316c3c")
        let versions = [("v1", P56PinnedSource.v1SHA256), ("v2", P56PinnedSource.v2SHA256),
                        ("v3", P56PinnedSource.sha256)]
        for (version, digest) in versions {
            let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-\(version)/payload.json"))
            XCTAssertEqual(P56Digest.sha256(bytes), digest)
            let package = try P56PackageLoader.load(payload: bytes, expectedSHA256: digest)
            XCTAssertEqual(package.sourceReference.packageVersion, "five-friends-56-runtime-" + version)
            XCTAssertEqual(package.sourceReference.payloadSHA256, digest)
        }
    }
    func testApprovedV3MostProtectiveOutputRoundTripsWithItsSource() throws {
        let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/\(P56PinnedSource.packageVersion)/payload.json"))
        let package = try P56PackageLoader.load(payload: bytes, expectedSHA256: P56PinnedSource.sha256)
        let request = P56Request(childID: "pin-transition-fixture", name: "İrem", age: 6, seed: 42,
            mode: .adventure, companionID: "companion_fox_pilot_001", contentSafety: .mostProtective)
        let story = try P56StoryComposer(package: package).compose(request)
        let reopened = try JSONDecoder().decode(P56ComposedStory.self, from: JSONEncoder().encode(story))
        XCTAssertEqual(reopened.sourceReference, package.sourceReference)
        XCTAssertEqual(reopened.pages.map(\.text), story.pages.map(\.text))
        XCTAssertEqual(reopened.pages.map(\.provenance), story.pages.map(\.provenance))
        XCTAssertEqual(reopened.pages.count, 8)
    }
}
