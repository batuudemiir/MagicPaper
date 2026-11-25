import XCTest
import CryptoKit
import StoryEngine
@testable import MagicPaper

/// B1 (beş arkadaş B hattı): P56 masalı kalıcı `Story`'ye birebir ve kaynağıyla girer.
final class P56StoryMapperTests: XCTestCase {
    private let profileID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!

    private func package() throws -> P56Package {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-v1/payload.json"))
        let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        return try P56PackageLoader.load(payload: bytes, expectedSHA256: digest)
    }

    private func composed(seed: UInt64 = 7, mode: P56Mode = .learning) throws -> P56ComposedStory {
        try P56StoryComposer(package: package()).compose(
            P56Request(childID: "test-child", name: "Deniz", age: 5, seed: seed, mode: mode))
    }

    private func story(_ composed: P56ComposedStory) -> Story {
        P56StoryMapper.story(from: composed, childProfileID: profileID, strategy: nil)
    }

    func testMapsPagesAndOriginExactly() throws {
        let composed = try composed()
        let story = story(composed)

        XCTAssertEqual(story.title, composed.title)
        XCTAssertEqual(story.childName, "Deniz")
        XCTAssertEqual(story.childProfileID, profileID)
        XCTAssertEqual(story.status, .completed)
        XCTAssertEqual(story.pages.count, 8)
        XCTAssertEqual(story.pages.map(\.text), composed.pages.sorted { $0.number < $1.number }.map(\.text))
        XCTAssertTrue(story.pages.allSatisfy {
            $0.imagePrompt.isEmpty && $0.imageUrl == nil && $0.imageFileName == nil && $0.art == nil
        }, "P56 görseli onaylı değil; sayfa görsel taşımaz")

        let origin = try XCTUnwrap(story.origin)
        XCTAssertEqual(origin.contentSource?.p56Reference, composed.sourceReference)
        XCTAssertNil(origin.contentSource?.reference, "P56 kaynağı legacy referans sayılmaz")
        XCTAssertEqual(origin.contentSource?.status, .unsupported)
        XCTAssertEqual(origin.catalogVersion, "five-friends-56-runtime-v1")
        XCTAssertEqual(origin.blueprintID, composed.structureID)
        XCTAssertEqual(Set(composed.pages.map(\.settingID)).count, 1, "sekiz sayfa aynı mekânda")
        XCTAssertEqual(origin.settingID, composed.pages[0].settingID, "worldID değil, sayfaların mekânı")
        XCTAssertEqual(origin.companionID, composed.companion.id)
        XCTAssertEqual(origin.discoveryID, composed.discoveryID)
        XCTAssertEqual(origin.seed, "7")
        XCTAssertEqual(origin.modeID, "learning")
        XCTAssertEqual(origin.ageBand, "5-6")
        XCTAssertNil(origin.storyIdeaID)
        XCTAssertNil(origin.seriesID)
        XCTAssertNil(origin.familyCharacterID)
        XCTAssertNil(origin.recalled)
    }

    func testFingerprintIsStableAndSeedSensitive() throws {
        let first = try XCTUnwrap(story(composed(seed: 7)).origin?.fingerprint)
        let again = try XCTUnwrap(story(composed(seed: 7)).origin?.fingerprint)
        XCTAssertEqual(first, again)
        XCTAssertEqual(first.count, 64)

        let pagesOf7 = try composed(seed: 7).pages.map(\.text)
        let other = try composed(seed: 8)
        if other.pages.map(\.text) != pagesOf7 {
            XCTAssertNotEqual(story(other).origin?.fingerprint, first, "farklı metin, farklı parmak izi")
        }
    }

    func testEncodeDecodeRoundTripKeepsP56Reference() throws {
        let composed = try composed()
        let original = story(composed)
        let decoded = try JSONDecoder().decode(Story.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.pages.map(\.text), original.pages.map(\.text))
        XCTAssertEqual(decoded.origin?.contentSource?.p56Reference, composed.sourceReference)
        XCTAssertEqual(decoded.origin?.settingID, original.origin?.settingID)
    }

    func testUnknownWorldLeavesCoverWorldNil() throws {
        let composed = try composed()
        XCTAssertNil(MP.World(rawValue: composed.worldID), "pilot dünyası arayüz dünyası değil")
        let story = story(composed)
        XCTAssertNil(story.origin?.worldID)
        XCTAssertEqual(story.theme, .custom)
    }

    func testEveryModeMapsToItsStoryMode() throws {
        for mode in P56Mode.allCases {
            let story = story(try composed(mode: mode))
            XCTAssertEqual(story.origin?.modeID, mode.rawValue)
            XCTAssertEqual(story.origin?.mode?.rawValue, mode.rawValue)
        }
    }
}
