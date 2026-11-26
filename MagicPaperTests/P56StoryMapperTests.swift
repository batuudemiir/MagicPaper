import XCTest
import CryptoKit
import StoryEngine
@testable import MagicPaper

/// B1 (beş arkadaş B hattı): P56 masalı kalıcı `Story`'ye birebir ve kaynağıyla girer.
final class P56StoryMapperTests: XCTestCase {
    private let profileID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!

    private func package(_ version: String = "five-friends-56-runtime-v1") throws -> P56Package {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/\(version)/payload.json"))
        let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        return try P56PackageLoader.load(payload: bytes, expectedSHA256: digest)
    }

    private func composed(seed: UInt64 = 7, mode: P56Mode = .learning) throws -> P56ComposedStory {
        try P56StoryComposer(package: package()).compose(
            P56Request(childID: "test-child", name: "Deniz", age: 5, seed: seed, mode: mode))
    }

    private func story(_ composed: P56ComposedStory) -> MagicPaper.Story {
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

    func testV2StoryCarriesV2SourceOnEveryPage() throws {
        let composed = try P56StoryComposer(package: package("five-friends-56-runtime-v2")).compose(
            P56Request(childID: "test-child", name: "Deniz", age: 6, seed: 11, mode: .adventure,
                       contentSafety: .mostProtective))
        let story = story(composed)
        XCTAssertEqual(story.origin?.catalogVersion, "five-friends-56-runtime-v2")
        XCTAssertEqual(story.origin?.contentSource?.p56Reference?.packageVersion, "five-friends-56-runtime-v2")
        XCTAssertEqual(story.origin?.contentSource?.p56Reference?.payloadSHA256, P56PinnedSource.v2SHA256)
        XCTAssertEqual(story.pages.compactMap { $0.provenance?.p56?.renderedSHA256 },
                       composed.pages.sorted { $0.number < $1.number }.map(\.provenance.renderedSHA256))
        XCTAssertTrue(story.pages.allSatisfy { $0.provenance?.p56?.packageVersion == "five-friends-56-runtime-v2" })
    }

    func testActiveStoryCarriesActiveSourceOnEveryPage() throws {
        let composed = try P56StoryComposer(package: package(P56PinnedSource.packageVersion)).compose(
            P56Request(childID: "test-child", name: "Deniz", age: 6, seed: 11, mode: .adventure,
                       contentSafety: .mostProtective))
        let story = story(composed)
        XCTAssertEqual(story.origin?.catalogVersion, P56PinnedSource.packageVersion)
        XCTAssertEqual(story.origin?.contentSource?.p56Reference?.packageVersion, P56PinnedSource.packageVersion)
        XCTAssertEqual(story.origin?.contentSource?.p56Reference?.payloadSHA256, P56PinnedSource.sha256)
        XCTAssertEqual(story.pages.compactMap { $0.provenance?.p56?.renderedSHA256 },
                       composed.pages.sorted { $0.number < $1.number }.map(\.provenance.renderedSHA256))
        XCTAssertTrue(story.pages.allSatisfy { $0.provenance?.p56?.packageVersion == P56PinnedSource.packageVersion })
    }

    func testFingerprintEdges() {
        let a = String(repeating: "a", count: 64), b = String(repeating: "b", count: 64)
        XCTAssertEqual(P56StoryMapper.fingerprint(ofRenderedDigests: [a, b]),
                       P56StoryMapper.fingerprint(ofRenderedDigests: [a, b]))
        XCTAssertNotEqual(P56StoryMapper.fingerprint(ofRenderedDigests: [a, b]),
                          P56StoryMapper.fingerprint(ofRenderedDigests: [b, a]), "sıra değişimi")
        XCTAssertNotEqual(P56StoryMapper.fingerprint(ofRenderedDigests: [a, b]),
                          P56StoryMapper.fingerprint(ofRenderedDigests: [a, String(repeating: "c", count: 64)]), "metin değişimi")
        XCTAssertNotEqual(P56StoryMapper.fingerprint(ofRenderedDigests: []),
                          P56StoryMapper.fingerprint(ofRenderedDigests: [a]), "boş liste")
        XCTAssertEqual(P56StoryMapper.fingerprint(ofRenderedDigests: []).count, 64)
    }

    func testEveryPageKeepsItsP56SourceChain() throws {
        let composed = try composed()
        let story = story(composed)
        for (stored, page) in zip(story.pages, composed.pages.sorted { $0.number < $1.number }) {
            let chain = try XCTUnwrap(stored.provenance?.p56)
            XCTAssertEqual(chain.packageVersion, composed.sourceReference.packageVersion)
            XCTAssertEqual(chain.templateID, page.provenance.templateID)
            XCTAssertEqual(chain.templateSHA256, page.provenance.templateSHA256)
            XCTAssertEqual(chain.parentSourceID, page.provenance.parentSourceID)
            XCTAssertEqual(chain.parentSHA256, page.provenance.parentSHA256)
            XCTAssertEqual(chain.parentPointer, page.provenance.parentPointer)
            XCTAssertEqual(chain.renderedSHA256, page.provenance.renderedSHA256)
            XCTAssertEqual(chain.order, page.provenance.order)
            XCTAssertEqual(stored.provenance?.parts, [], "P56 sayfası beat_line gibi görünmez")
            XCTAssertEqual(stored.provenance?.beatLineIDs, [])
        }
    }

    func testP56ChainSurvivesSaveAndLegacyProvenanceIsUnchanged() throws {
        let original = story(try composed())
        let decoded = try JSONDecoder().decode(MagicPaper.Story.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(decoded.pages.map { $0.provenance?.p56 }, original.pages.map { $0.provenance?.p56 })

        let legacy = Data(#"{"schemaVersion":1,"partCount":1,"parts":[{"sourceKind":"beat_line","sourceID":"x","sourceTextDigest":"0123456789abcdef"}]}"#.utf8)
        let provenance = try JSONDecoder().decode(StoryPageProvenance.self, from: legacy)
        XCTAssertNil(provenance.p56)
        XCTAssertEqual(provenance.beatLineIDs, ["x"])
        XCTAssertTrue(provenance.isComplete)
    }

    func testMalformedP56ChainDropsOnlyTheChain() throws {
        let broken = Data(#"{"schemaVersion":1,"partCount":0,"parts":[],"p56":{"templateID":"t"}}"#.utf8)
        let provenance = try JSONDecoder().decode(StoryPageProvenance.self, from: broken)
        XCTAssertNil(provenance.p56)
        XCTAssertEqual(provenance.parts, [])
    }

    func testEncodeDecodeRoundTripKeepsP56Reference() throws {
        let composed = try composed()
        let original = story(composed)
        let decoded = try JSONDecoder().decode(MagicPaper.Story.self, from: JSONEncoder().encode(original))
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
