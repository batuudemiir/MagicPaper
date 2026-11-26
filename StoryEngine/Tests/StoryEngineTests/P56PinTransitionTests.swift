import Foundation
import XCTest
@testable import StoryEngine

final class P56PinTransitionTests: XCTestCase {
    private var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
    }
    func testApprovedActiveV4AndHistoricalPinsMatchExactBytes() throws {
        XCTAssertEqual(P56PinnedSource.packageVersion, "five-friends-56-runtime-v4")
        XCTAssertEqual(P56PinnedSource.sha256, "c06a5dfc3f586eae5d837926cab915be6b22480c20e11e02c9ea7fd5894990d6")
        let versions = [("v1", P56PinnedSource.v1SHA256), ("v2", P56PinnedSource.v2SHA256),
                        ("v3", P56PinnedSource.v3SHA256), ("v4", P56PinnedSource.sha256)]
        for (version, digest) in versions {
            let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-\(version)/payload.json"))
            XCTAssertEqual(P56Digest.sha256(bytes), digest)
            let package = try P56PackageLoader.load(payload: bytes, expectedSHA256: digest)
            XCTAssertEqual(package.sourceReference.packageVersion, "five-friends-56-runtime-" + version)
            XCTAssertEqual(package.sourceReference.payloadSHA256, digest)
        }
    }
    func testApprovedV4MostProtectiveOutputRoundTripsWithItsSource() throws {
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
