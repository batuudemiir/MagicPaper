import XCTest
import CryptoKit
import UIKit
import StoryEngine
@testable import MagicPaper

@MainActor
final class P56StoryArtPolicyTests: XCTestCase {
    private var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }

    private func policy() throws -> P56StoryArtPolicy {
        let url = root.appendingPathComponent("MagicPaper/StoryEngineBridge/StoryArtResources/p56-story-art-v4.json")
        return try XCTUnwrap(P56StoryArtPolicy.load(data: Data(contentsOf: url),
                                                   expectedSHA256: P56StoryArtPolicy.resourceSHA256))
    }

    private func composed(bookID: String, name: String = "İrem") throws -> P56ComposedStory {
        let url = root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-v4/payload.json")
        let package = try P56PackageLoader.load(payload: Data(contentsOf: url), expectedSHA256: P56StoryArtPolicy.payloadPin)
        let book = try XCTUnwrap(package.books.first { $0.id == bookID })
        return try P56StoryComposer(package: package).compose(.init(
            childID: "art-test", name: name, age: 5, seed: 7, mode: book.mode,
            companionID: book.companionID, forcedStructure: book.structureID,
            recentBookIDs: package.books.filter { $0.id != bookID }.map(\.id)))
    }

    private func bare(_ composed: P56ComposedStory) -> MagicPaper.Story {
        var story = P56StoryMapper.story(from: composed, childProfileID: UUID(), strategy: nil)
        for index in story.pages.indices { story.pages[index].art = nil }
        return story
    }

    private func changed<T: Codable>(_ value: T, _ mutation: (inout [String: Any]) -> Void) throws -> T {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as? [String: Any])
        mutation(&json)
        return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: json))
    }

    func testReviewedRulesBindWithoutChangingTextOrSourceAndPersist() throws {
        let policy = try policy()
        let bookID = try XCTUnwrap(policy.rules.first?.bookID)
        let composed = try composed(bookID: bookID)
        let original = bare(composed)
        let bound = P56StoryArtBinder.bind(original, composed: composed, policy: policy)
        XCTAssertEqual(bound.pages.map(\.text), original.pages.map(\.text))
        XCTAssertEqual(bound.origin?.contentSource?.p56Reference, composed.sourceReference)
        let pins = bound.pages.compactMap(\.art)
        XCTAssertFalse(pins.isEmpty)
        XCTAssertLessThanOrEqual(pins.count, 3)
        XCTAssertTrue(pins.allSatisfy { $0.bindingPolicyVersion == 4 && $0.isBundledSpot })
        let restored = try JSONDecoder().decode(MagicPaper.Story.self, from: JSONEncoder().encode(bound))
        XCTAssertEqual(restored.pages.compactMap(\.art), pins)
        XCTAssertEqual(P56StoryArtBinder.bind(restored, composed: composed, policy: nil).pages.compactMap(\.art), pins)
        let reader = ReaderStory(from: restored).leaves.compactMap(\.page)
        XCTAssertEqual(reader.filter { $0.composition == .spot }.count, pins.count)
        XCTAssertTrue(reader.filter(\.hasIllustration).allSatisfy { $0.imageLabel?.isEmpty == false })
    }

    func testPayloadBookIdentityAndFullPageSourceMutationFailClosed() throws {
        let policy = try policy()
        let original = try composed(bookID: XCTUnwrap(policy.rules.first?.bookID))
        let mutations: [(inout [String: Any]) -> Void] = [
            { $0["bookID"] = "unknown-book" },
            { $0["age"] = 7 },
            { var ref = $0["sourceReference"] as! [String: Any]; ref["payloadSHA256"] = String(repeating: "0", count: 64); $0["sourceReference"] = ref },
            { var profile = $0["companion"] as! [String: Any]; profile["id"] = "wrong-companion"; $0["companion"] = profile },
            { var pages = $0["pages"] as! [[String: Any]]; pages[7]["text"] = "changed closing"; $0["pages"] = pages },
            { var pages = $0["pages"] as! [[String: Any]]; pages[1] = pages[0]; $0["pages"] = pages }
        ]
        for mutation in mutations {
            let altered: P56ComposedStory = try changed(original, mutation)
            XCTAssertTrue(P56StoryArtBinder.bind(bare(altered), composed: altered, policy: policy).pages.allSatisfy { $0.art == nil })
        }
        for field in ["templateID", "templateSHA256", "parentSourceID", "parentSHA256", "parentPointer", "renderedSHA256", "order"] {
            let altered: P56ComposedStory = try changed(original) { json in
                var pages = json["pages"] as! [[String: Any]]
                var trace = pages[7]["provenance"] as! [String: Any]
                if field == "order" { trace[field] = 1 } else { trace[field] = "changed-source" }
                pages[7]["provenance"] = trace
                json["pages"] = pages
            }
            XCTAssertTrue(P56StoryArtBinder.bind(bare(altered), composed: altered, policy: policy).pages.allSatisfy { $0.art == nil }, field)
        }
    }

    func testMissingPolicyExistingPicturesAndStoredTextArePreserved() throws {
        let policy = try policy()
        let composed = try composed(bookID: XCTUnwrap(policy.rules.first?.bookID))
        var story = bare(composed)
        XCTAssertTrue(P56StoryArtBinder.bind(story, composed: composed, policy: nil).pages.allSatisfy { $0.art == nil })
        for index in story.pages.indices { story.pages[index].imageFileName = "existing-\(index).png" }
        let preserved = P56StoryArtBinder.bind(story, composed: composed, policy: policy)
        XCTAssertEqual(preserved.pages.map(\.imageFileName), story.pages.map(\.imageFileName))
        XCTAssertTrue(preserved.pages.allSatisfy { $0.art == nil })
        story = bare(composed)
        story.pages[7].text += " changed"
        XCTAssertTrue(P56StoryArtBinder.bind(story, composed: composed, policy: policy).pages.allSatisfy { $0.art == nil })
    }

    func testEveryResourceHasExactBytesAndPolicyRejectsTampering() throws {
        let policy = try policy()
        for asset in policy.assets {
            let file = root.appendingPathComponent("MagicPaper/StoryEngineBridge/StoryArtResources/\(asset.fileName)")
            let bytes = try Data(contentsOf: file)
            XCTAssertEqual(P56StoryArtPolicy.digest(bytes), asset.digest, asset.assetID)
            XCTAssertNotNil(UIImage(data: bytes), asset.assetID)
            XCTAssertNotNil(StorySpotAssetResolver.validatedURL(fileName: asset.fileName, digest: asset.digest))
        }
        let file = root.appendingPathComponent("MagicPaper/StoryEngineBridge/StoryArtResources/p56-story-art-v4.json")
        var bytes = try Data(contentsOf: file)
        bytes.append(32)
        XCTAssertNil(P56StoryArtPolicy.load(data: bytes, expectedSHA256: P56StoryArtPolicy.resourceSHA256))
    }

    func testV4PinsRejectUnscopedOrMalformedPersistedMetadata() throws {
        let policy = try policy()
        let composed = try composed(bookID: XCTUnwrap(policy.rules.first?.bookID))
        let pin = try XCTUnwrap(P56StoryArtBinder.bind(bare(composed), composed: composed, policy: policy).pages.compactMap(\.art).first)
        XCTAssertTrue(pin.isBundledSpot)
        for (key, value) in [
            ("catalogVersion", "five-friends-56-runtime-v3"),
            ("styleRevision", "unreviewed"),
            ("sourceID", "legacy-asset"),
            ("bundledFileName", "../v4_bad.mpart"),
            ("assetDigest", "not-a-digest"),
            ("authoredSourceFingerprint", "not-a-proof")
        ] {
            let altered: StoryPageArt = try changed(pin) { $0[key] = value }
            XCTAssertFalse(altered.isBundledSpot, key)
        }
        let wrongVersion: StoryPageArt = try changed(pin) { $0["bindingPolicyVersion"] = 5 }
        XCTAssertFalse(wrongVersion.isBundledSpot)
        let wrongSource: StoryPageArt = try changed(pin) { $0["variantIDs"] = ["legacy-line"] }
        XCTAssertFalse(wrongSource.isBundledSpot)
    }

    func testLegacyVersionsDoNotReceiveV4Art() throws {
        let policy = try policy()
        for version in ["v1", "v2", "v3"] {
            let file = root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-\(version)/payload.json")
            let data = try Data(contentsOf: file)
            let package = try P56PackageLoader.load(payload: data, expectedSHA256: P56StoryArtPolicy.digest(data))
            let composed = try P56StoryComposer(package: package).compose(.init(childID: "legacy", name: "Deniz", age: 5, seed: 1, mode: .learning))
            XCTAssertTrue(P56StoryArtBinder.bind(bare(composed), composed: composed, policy: policy).pages.allSatisfy { $0.art == nil })
        }
    }
}
