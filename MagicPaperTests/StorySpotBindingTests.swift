import XCTest
import StoryEngine
@testable import MagicPaper

final class StorySpotBindingTests: XCTestCase {
    func testOldArtDecodesWithoutBundlePin() throws {
        let art = try JSONDecoder().decode(StoryPageArt.self, from: Data(#"{"role":"spot","altText":"Harita","sourceID":"old"}"#.utf8))
        XCTAssertTrue(art.isSpot)
        XCTAssertFalse(art.isBundledSpot)
    }

    func testCompletePinRoundTripsAndUnknownVersionsFailClosed() throws {
        let art = StoryPageArt(role: "spot", altText: "Harita", sourceID: "spot.map", schemaVersion: 1,
            assetRevision: 5, assetDigest: String(repeating: "a", count: 64), styleRevision: "gouache-v1",
            bundledFileName: "map-r5.png", subjectID: "map", subjectState: ["torn"], variantIDs: ["na_neutral_01"],
            authoredSourceFingerprint: "abc", bindingPolicyVersion: 1, catalogVersion: "v1")
        let decoded = try JSONDecoder().decode(StoryPageArt.self, from: JSONEncoder().encode(art))
        XCTAssertEqual(art, decoded)
        XCTAssertTrue(decoded.isBundledSpot)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(art)) as? [String: Any])
        json["schemaVersion"] = 2
        XCTAssertFalse(try JSONDecoder().decode(StoryPageArt.self, from: JSONSerialization.data(withJSONObject: json)).isBundledSpot)
        json["schemaVersion"] = "malformed"
        XCTAssertFalse(try JSONDecoder().decode(StoryPageArt.self, from: JSONSerialization.data(withJSONObject: json)).isBundledSpot)
    }
    func testMalformedMetadataPresenceSurvivesRoundTrip() throws {
        let malformed = Data(#"{"role":"spot","altText":"Harita","schemaVersion":"wrong","bundledFileName":42}"#.utf8)
        let decoded = try JSONDecoder().decode(StoryPageArt.self, from: malformed)
        XCTAssertTrue(decoded.hasBundledMetadata)
        XCTAssertFalse(decoded.isBundledSpot)
        let restored = try JSONDecoder().decode(StoryPageArt.self, from: JSONEncoder().encode(decoded))
        XCTAssertTrue(restored.hasBundledMetadata)
        XCTAssertFalse(restored.isBundledSpot)
        let legacy = StoryPageArt(role: "spot", altText: "Harita", sourceID: "old")
        XCTAssertFalse(try JSONDecoder().decode(StoryPageArt.self, from: JSONEncoder().encode(legacy)).hasBundledMetadata)
    }

    @MainActor
    func testRealBundledCompositionBindsAndUnsupportedVariantStaysText() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let spots = try XCTUnwrap(StorySpotCatalog.bundled)
        let rule = try XCTUnwrap(spots.rules.first)
        let asset = try XCTUnwrap(spots.assets.first { $0.assetID == rule.assetID && $0.revision == rule.assetRevision })
        let blueprint = try XCTUnwrap(catalog.blueprints.first { $0.id.rawValue == rule.blueprintID })
        var bound = false
        var unsupported = false
        for seed in 0..<160 {
            let intent = OfflineStoryIntent(childName: "Yeliz",
                settingID: rule.settingIDs?.first.map { ContentID($0) },
                discoveryID: ContentID(asset.subjectID), seed: "spot-fixture-\(seed)")
            guard let composed = try? OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog, intent: intent) else { continue }
            let story = OfflineStoryMapper.appStory(from: composed, childName: "Yeliz", childProfileID: UUID(),
                storyIdeaID: nil, catalogVersion: catalog.version)
            if story.pages.first?.art?.isBundledSpot == true {
                bound = true
                try assertBoundStory(story, composed: composed, catalog: catalog, blueprint: blueprint,
                    spots: spots, seed: "spot-fixture-\(seed)")
            }
            if let first = composed.pages.first,
               first.variantIDs.count != 1 || !["na_neutral_01", "na_neutral_02"].contains(first.variantIDs[0].rawValue) {
                XCTAssertNil(story.pages[0].art)
                unsupported = true
            }
            if bound && unsupported { break }
        }
        XCTAssertTrue(bound, "A real reviewed bundled composition must bind")
        XCTAssertTrue(unsupported, "A real non-reviewed variant must stay text")
    }


    @MainActor
    private func assertBoundStory(_ story: MagicPaper.Story, composed: ComposedStory, catalog: ContentCatalog,
                                  blueprint: CatalogBlueprint, spots: StorySpotCatalog, seed: String) throws {
        let reloaded = try JSONDecoder().decode(MagicPaper.Story.self, from: JSONEncoder().encode(story))
        XCTAssertEqual(reloaded.pages[0].art, story.pages[0].art)
        XCTAssertNil(story.pages[0].imageFileName)
        let recallIntent = OfflineStoryIntent(childName: "Yeliz", settingID: composed.content.setting.id,
            companionID: composed.content.companion.id, discoveryID: composed.content.discovery.id,
            seed: seed, recall: RecallHistory(companions: [composed.content.companion.id:
                .init(storyCount: 2, firstSettingID: composed.content.setting.id)]))
        let recalled = try OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog, intent: recallIntent)
        XCTAssertNotNil(recalled.recallLineID)
        XCTAssertNil(recalled.pages[0].authoredSourceFingerprint)
        XCTAssertNil(OfflineStoryMapper.appStory(from: recalled, childName: "Yeliz", childProfileID: UUID(),
            storyIdeaID: nil, catalogVersion: catalog.version).pages[0].art)
        var existing = story
        existing.pages[0].art = StoryPageArt(role: "scene", altText: "Eski", sourceID: "old")
        XCTAssertEqual(StorySpotBinder.bind(existing, composed: composed, catalog: spots).pages[0].art?.sourceID, "old")
        XCTAssertNil(OfflineStoryMapper.appStory(from: composed, childName: "Yeliz", childProfileID: UUID(),
            storyIdeaID: nil, catalogVersion: "changed").pages[0].art)
    }

    @MainActor
    func testRealContinuationRemainsText() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        var checked = false
        for blueprint in catalog.series.continuations {
            for seed in 0..<12 {
                guard let composed = try? OfflineStoryComposer().composeEpisode(blueprint: blueprint, catalog: catalog,
                    intent: OfflineStoryIntent(childName: "Yeliz", seed: "spot-continuation-\(seed)"),
                    episode: EpisodeContext(number: 2, keepsake: try XCTUnwrap(catalog.objects.first))) else { continue }
                let story = OfflineStoryMapper.appStory(from: composed, childName: "Yeliz", childProfileID: UUID(),
                    storyIdeaID: nil, catalogVersion: catalog.version, series: (UUID(), 2))
                XCTAssertNil(story.pages.first?.art)
                checked = true
                break
            }
            if checked { break }
        }
        XCTAssertTrue(checked, "A genuine continuation must be composed")
    }

    func testCatalogRejectsUnknownPolicyDuplicateDraftAndUnsafeAssets() throws {
        let asset: [String: Any] = ["assetID": "spot.map", "revision": 1, "digest": String(repeating: "a", count: 64),
            "styleRevision": "gouache-v1", "fileName": "map-r1.png", "status": "approved", "subjectID": "map",
            "subjectState": ["torn"], "altText": "Harita"]
        let rule: [String: Any] = ["bindingPolicyVersion": 1, "catalogVersion": "v1", "blueprintID": "bp",
            "pageNumber": 1, "role": "hook", "beats": ["notice_anomaly"], "variantIDs": ["na_neutral_01"],
            "authoredSourceFingerprint": "source", "assetID": "spot.map", "assetRevision": 1]
        func load(_ assets: [[String: Any]], _ rules: [[String: Any]], validFile: Bool = true) throws -> StorySpotCatalog? {
            StorySpotCatalog.load(data: try JSONSerialization.data(withJSONObject:
                ["schemaVersion": 1, "assets": assets, "rules": rules])) { _, _ in validFile }
        }
        XCTAssertNotNil(try load([asset], [rule]))
        XCTAssertNil(try load([asset, asset], [rule]))
        XCTAssertNil(try load([asset], [rule], validFile: false))
        var invalidAsset = asset
        invalidAsset["status"] = "draft"
        XCTAssertNil(try load([invalidAsset], [rule]))
        invalidAsset = asset
        invalidAsset["fileName"] = "../map.png"
        XCTAssertNil(try load([invalidAsset], [rule]))
        var invalidRule = rule
        invalidRule["bindingPolicyVersion"] = 2
        XCTAssertNil(try load([asset], [invalidRule]))
    }

}
