import XCTest
import StoryEngine
@testable import MagicPaper

final class ReviewedDiscoveryArtPolicyTests: XCTestCase {
    func testOnlyExactManuallyReviewedSourceAndCanonicalDiscoveryAuthorize() throws {
        let policy = try XCTUnwrap(ReviewedDiscoveryArtPolicy.bundled)
        let catalog = try ContentCatalogLoader().load().catalog
        let bell = try XCTUnwrap(catalog.objects.first { $0.id.rawValue == "object_bell_001" })
        var objectJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(bell)) as? [String: Any])
        objectJSON["description"] = "Changed canonical description"
        let changedBell = try JSONDecoder().decode(CatalogObject.self,
            from: JSONSerialization.data(withJSONObject: objectJSON))
        XCTAssertEqual(policy.sources.count, 5)
        XCTAssertEqual(policy.recalls.count, 38)
        for source in policy.sources {
            let part = PageSourcePart(kind: .beatLine, sourceID: source.sourceID,
                sourceTextDigest: source.sourceTextDigest, templateID: source.templateID,
                beat: .noticeAnomaly, visual: [.init(subject: .discovery,
                    subjectID: bell.id.rawValue, presence: .present, states: ["examined"])], visualReview: .auto)
            XCTAssertNotNil(policy.proof(parts: [part], variantIDs: [source.sourceID], discovery: bell))
            XCTAssertNil(policy.proof(parts: [part], variantIDs: [source.sourceID], discovery: changedBell))
            XCTAssertNil(policy.proof(parts: [], variantIDs: [source.sourceID], discovery: bell))
            XCTAssertNil(policy.proof(parts: [part, part], variantIDs: [source.sourceID], discovery: bell))
            XCTAssertNil(policy.proof(parts: [part], variantIDs: [], discovery: bell))
            let corrupt = PageSourcePart(kind: .beatLine, sourceID: source.sourceID,
                sourceTextDigest: "changed", templateID: source.templateID, beat: .noticeAnomaly)
            XCTAssertNil(policy.proof(parts: [corrupt], variantIDs: [source.sourceID], discovery: bell))
            let wrongObject = try XCTUnwrap(catalog.objects.first { $0.id != bell.id })
            XCTAssertNil(policy.proof(parts: [part], variantIDs: [source.sourceID], discovery: wrongObject))
        }
    }

    func testEveryRecallRequiresIndividualDigestAndCompleteOrderedProof() throws {
        let policy = try XCTUnwrap(ReviewedDiscoveryArtPolicy.bundled)
        let catalog = try ContentCatalogLoader().load().catalog
        let bell = try XCTUnwrap(catalog.objects.first { $0.id.rawValue == "object_bell_001" })
        let source = try XCTUnwrap(policy.sources.first)
        let beat = PageSourcePart(kind: .beatLine, sourceID: source.sourceID,
            sourceTextDigest: source.sourceTextDigest, templateID: source.templateID, beat: .noticeAnomaly,
            visual: [.init(subject: .discovery, subjectID: bell.id.rawValue, presence: .present, states: [])], visualReview: .auto)
        for recall in policy.recalls {
            let part = PageSourcePart(kind: .recall, sourceID: recall.sourceID, sourceTextDigest: recall.sourceTextDigest)
            let ids = [source.sourceID, recall.sourceID]
            XCTAssertNotNil(policy.proof(parts: [beat, part], variantIDs: ids, discovery: bell))
            XCTAssertNil(policy.proof(parts: [beat], variantIDs: ids, discovery: bell))
            XCTAssertNil(policy.proof(parts: [part, beat], variantIDs: ids, discovery: bell))
            let changed = PageSourcePart(kind: .recall, sourceID: recall.sourceID, sourceTextDigest: "changed")
            XCTAssertNil(policy.proof(parts: [beat, changed], variantIDs: ids, discovery: bell))
        }
        for context in ["family", "occasion", "series", "unknown"] {
            let contextual = PageSourcePart(kind: .beatLine, sourceID: source.sourceID,
                sourceTextDigest: source.sourceTextDigest, templateID: source.templateID,
                beat: .noticeAnomaly, contexts: [context])
            XCTAssertNil(policy.proof(parts: [contextual], variantIDs: [source.sourceID], discovery: bell))
        }
    }

    func testSavedPolicyTwoPinRemainsCompatibleAndUnknownPolicyFailsClosed() {
        func art(policy: Int) -> StoryPageArt {
            StoryPageArt(role: "spot", altText: "Küçük gümüş çan.", sourceID: "spot.silver-bell",
                schemaVersion: 1, assetRevision: 1, assetDigest: String(repeating: "a", count: 64),
                styleRevision: "gouache-social-v1", bundledFileName: "bell.mpart", subjectID: "object_bell_001",
                subjectState: ["small", "silver"], variantIDs: ["na_any_01"],
                authoredSourceFingerprint: "proof", bindingPolicyVersion: policy, catalogVersion: "2.1.0")
        }
        XCTAssertTrue(art(policy: 2).isBundledSpot)
        XCTAssertFalse(art(policy: 3).isBundledSpot)
    }
    func testManifestCorruptionAndMissingAssetFailClosed() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "reviewed-discovery-art-v2", withExtension: "json"))
        let data = try Data(contentsOf: url)
        XCTAssertNotNil(ReviewedDiscoveryArtPolicy.load(data: data) { _, _ in true })
        XCTAssertNil(ReviewedDiscoveryArtPolicy.load(data: data) { _, _ in false })
        var changed = data
        changed.append(32)
        XCTAssertNil(ReviewedDiscoveryArtPolicy.load(data: changed) { _, _ in true })
    }

    @MainActor
    func testRealComposerBellWithRecallMapsAndPersistsExactPin() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let policy = try XCTUnwrap(ReviewedDiscoveryArtPolicy.bundled)
        var found = false
        for blueprint in catalog.blueprints where blueprint.ageRange.description == "5-6" {
            for seed in 0..<80 {
                let baseIntent = OfflineStoryIntent(childName: "Yeliz", discoveryID: ContentID("object_bell_001"),
                    seed: "reviewed-bell-\(seed)")
                guard let plain = try? OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog, intent: baseIntent)
                else { continue }
                let intent = OfflineStoryIntent(childName: "Yeliz", settingID: plain.content.setting.id,
                    companionID: plain.content.companion.id, discoveryID: plain.content.discovery.id,
                    seed: "reviewed-bell-\(seed)", recall: RecallHistory(companions: [plain.content.companion.id:
                        .init(storyCount: 2, firstSettingID: plain.content.setting.id)]))
                guard let composed = try? OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog, intent: intent),
                      composed.recallLineID != nil,
                      composed.pages.contains(where: { policy.proof(parts: $0.provenance,
                        variantIDs: $0.variantIDs.map(\.rawValue), discovery: composed.content.discovery) != nil })
                else { continue }
                let story = OfflineStoryMapper.appStory(from: composed, childName: "Yeliz", childProfileID: UUID(),
                    storyIdeaID: nil, catalogVersion: catalog.version)
                let art = try XCTUnwrap(story.pages.compactMap(\.art).first)
                XCTAssertEqual(art.bindingPolicyVersion, 2)
                XCTAssertEqual(art.sourceID, "spot.silver-bell")
                XCTAssertNotNil(StorySpotAssetResolver.url(for: art))
                XCTAssertEqual(story.pages.map(\.text), composed.pages.sorted { $0.pageNumber < $1.pageNumber }.map(\.text))
                let saved = try JSONDecoder().decode(MagicPaper.Story.self, from: JSONEncoder().encode(story))
                XCTAssertEqual(saved.pages.compactMap(\.art), story.pages.compactMap(\.art))
                var changed = story
                changed.pages = changed.pages.map { page in
                    var page = page
                    page.art = nil
                    return page
                }
                changed.pages[0].text += " changed"
                XCTAssertTrue(ReviewedDiscoveryArtBinder.bind(changed, composed: composed).pages.allSatisfy { $0.art == nil })
                changed.pages[0].text = story.pages[0].text
                changed.origin?.seriesID = UUID().uuidString
                XCTAssertTrue(ReviewedDiscoveryArtBinder.bind(changed, composed: composed).pages.allSatisfy { $0.art == nil })
                changed.origin?.seriesID = nil
                changed.origin?.discoveryID = "wrong"
                XCTAssertTrue(ReviewedDiscoveryArtBinder.bind(changed, composed: composed).pages.allSatisfy { $0.art == nil })
                var existing = story
                existing.pages[0].imageFileName = "existing.png"
                existing.pages[0].art = nil
                XCTAssertNil(ReviewedDiscoveryArtBinder.bind(existing, composed: composed).pages[0].art)
                existing.pages[0].imageFileName = nil
                existing.pages[0].art = StoryPageArt(role: "scene", altText: "Eski", sourceID: "old")
                XCTAssertEqual(ReviewedDiscoveryArtBinder.bind(existing, composed: composed).pages[0].art?.sourceID, "old")
                found = true
                break
            }
            if found { break }
        }
        XCTAssertTrue(found, "A real 5–6 bell composition with recall must bind")
    }

    @MainActor
    func testReviewedBellBundledRevisionDecodesInReader() async throws {
        let policy = try XCTUnwrap(ReviewedDiscoveryArtPolicy.bundled)
        let asset = policy.asset
        let art = StoryPageArt(role: "spot", altText: asset.altText, sourceID: asset.assetID,
            schemaVersion: 1, assetRevision: asset.revision, assetDigest: asset.digest,
            styleRevision: asset.styleRevision, bundledFileName: asset.fileName,
            subjectID: asset.subjectID, subjectState: asset.subjectState, variantIDs: ["na_any_01"],
            authoredSourceFingerprint: "reviewed-test", bindingPolicyVersion: 2, catalogVersion: policy.catalogVersion)
        let image = await ReaderImageLoader.shared.image(art: art, targetPixelWidth: 160)
        let decoded = try XCTUnwrap(image)
        XCTAssertLessThanOrEqual(max(decoded.size.width, decoded.size.height), 160)
        XCTAssertNotNil(decoded.cgImage)
    }

}
