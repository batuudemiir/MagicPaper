import XCTest
import StoryEngine
@testable import MagicPaper

final class WholeBookArtPolicyTests: XCTestCase {
    func testManifestIsPinnedAndFilesAreRequired() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "whole-book-art-v3", withExtension: "json"))
        let data = try Data(contentsOf: url)
        XCTAssertNotNil(WholeBookArtPolicy.load(data: data) { _, _ in true })
        XCTAssertNil(WholeBookArtPolicy.load(data: data) { _, _ in false })
        XCTAssertNil(WholeBookArtPolicy.load(data: data + Data([32])) { _, _ in true })
    }

    func testExactOrderedPartsAndIdentityAreRequired() throws {
        let policy = try XCTUnwrap(WholeBookArtPolicy.bundled)
        let catalog = try ContentCatalogLoader().load().catalog
        for rule in policy.rules {
            let entry = try XCTUnwrap(policy.assets.first { $0.asset.assetID == rule.assetID })
            func match(_ parts: [PageSourcePart], subject: String? = nil, identity: String? = nil) -> Bool {
                policy.matches(rule, blueprintID: rule.blueprintID, pageNumber: rule.pageNumber,
                    role: rule.role, beats: rule.beats, parts: parts, variantIDs: parts.map(\.sourceID),
                    subjectID: subject ?? entry.asset.subjectID,
                    canonicalFingerprint: identity ?? entry.canonicalFingerprint)
            }
            XCTAssertTrue(match(rule.orderedParts))
            XCTAssertFalse(match([]))
            XCTAssertFalse(match(rule.orderedParts + rule.orderedParts))
            XCTAssertFalse(match(rule.orderedParts, subject: "wrong"))
            XCTAssertFalse(match(rule.orderedParts, identity: "changed"))
            XCTAssertFalse(policy.matches(rule, blueprintID: "unknown", pageNumber: rule.pageNumber,
                role: rule.role, beats: rule.beats, parts: rule.orderedParts,
                variantIDs: rule.orderedParts.map(\.sourceID), subjectID: entry.asset.subjectID,
                canonicalFingerprint: entry.canonicalFingerprint))
            XCTAssertFalse(policy.matches(rule, blueprintID: rule.blueprintID, pageNumber: rule.pageNumber + 1,
                role: rule.role, beats: rule.beats, parts: rule.orderedParts,
                variantIDs: rule.orderedParts.map(\.sourceID), subjectID: entry.asset.subjectID,
                canonicalFingerprint: entry.canonicalFingerprint))
            if rule.orderedParts.count > 1 { XCTAssertFalse(match(Array(rule.orderedParts.reversed()))) }
            let original = try XCTUnwrap(JSONSerialization.jsonObject(
                with: JSONEncoder().encode(rule.orderedParts)) as? [[String: Any]])
            for index in rule.orderedParts.indices {
                var removed = rule.orderedParts
                removed.remove(at: index)
                XCTAssertFalse(match(removed))
                for key in ["sourceID", "sourceTextDigest", "templateID", "contexts", "visualReview"] {
                    var encoded = original
                    if key == "contexts" { encoded[index][key] = ["family"] }
                    else if key == "visualReview" {
                        encoded[index][key] = rule.orderedParts[index].visualReview == .auto ? "reviewed" : "auto"
                    } else { encoded[index][key] = "changed" }
                    let parts = try JSONDecoder().decode([PageSourcePart].self,
                        from: JSONSerialization.data(withJSONObject: encoded))
                    XCTAssertFalse(match(parts), "part \(index) \(key)")
                }
                guard let sourceVisuals = original[index]["visual"] as? [[String: Any]],
                      !sourceVisuals.isEmpty else { continue }
                var withoutVisual = original
                withoutVisual[index].removeValue(forKey: "visual")
                XCTAssertFalse(match(try JSONDecoder().decode([PageSourcePart].self,
                    from: JSONSerialization.data(withJSONObject: withoutVisual))))
                for visualIndex in sourceVisuals.indices {
                    for key in ["subjectID", "presence", "states"] {
                        var encoded = original
                        var visuals = sourceVisuals
                        if key == "states" { visuals[visualIndex][key] = ["changed"] }
                        else { visuals[visualIndex][key] = key == "presence" ? "remembered" : "changed" }
                        encoded[index]["visual"] = visuals
                        let parts = try JSONDecoder().decode([PageSourcePart].self,
                            from: JSONSerialization.data(withJSONObject: encoded))
                        XCTAssertFalse(match(parts), "part \(index) visual \(visualIndex) \(key)")
                    }
                }
            }
        }
        let fox = try XCTUnwrap(catalog.companions.first { $0.id.rawValue == "companion_fox_pilot_001" })
        XCTAssertEqual(WholeBookArtPolicy.companionFingerprint(fox), "3dc5e94208fa4542")
    }

    @MainActor
    func testPlannerPreservesPinsIsDeterministicAndRejectsOriginOrTextChanges() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let policy = try XCTUnwrap(WholeBookArtPolicy.bundled)
        var additions = 0
        var objectBooks: [String: Int] = [:]
        for id in policy.blueprintIDs {
            let blueprint = try XCTUnwrap(catalog.blueprints.first { $0.id.rawValue == id })
            for index in 0..<100 {
                let composed = try OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog,
                    intent: OfflineStoryIntent(childName: "Deniz", seed: String(format: "whole-book-art-v1-%03d", index),
                        mode: .adventure, ageBand: AgeBand(lowerBound: 5, upperBound: 6)))
                var mapped = OfflineStoryMapper.appStory(from: composed, childName: "Deniz", childProfileID: UUID(),
                    storyIdeaID: nil, catalogVersion: catalog.version)
                mapped.pages = mapped.pages.map { page in
                    var page = page
                    if page.art?.bindingPolicyVersion == 3 { page.art = nil }
                    return page
                }
                let bound = WholeBookArtBinder.bind(mapped, composed: composed, policy: policy)
                XCTAssertEqual(bound.pages, WholeBookArtBinder.bind(mapped, composed: composed, policy: policy).pages)
                XCTAssertEqual(bound.pages.map(\.text), composed.pages.map(\.text))
                XCTAssertLessThanOrEqual(bound.pages.compactMap(\.art).count, 3)
                let digests = bound.pages.compactMap { $0.art?.assetDigest }
                XCTAssertEqual(Set(digests).count, digests.count)
                for (before, after) in zip(mapped.pages, bound.pages) where before.art != nil {
                    XCTAssertEqual(before.art, after.art)
                }
                additions += bound.pages.filter { $0.art?.bindingPolicyVersion == 3 }.count
                let objectIDs = Set(bound.pages.compactMap { page -> String? in
                    guard page.art?.bindingPolicyVersion == 3,
                          let id = page.art?.subjectID, id.hasPrefix("object_") else { return nil }
                    return id
                })
                for id in objectIDs { objectBooks[id, default: 0] += 1 }
                XCTAssertEqual(try JSONDecoder().decode(MagicPaper.Story.self,
                    from: JSONEncoder().encode(bound)).pages, bound.pages)
                var bare = mapped
                bare.pages = bare.pages.map { page in
                    var page = page
                    page.art = nil
                    return page
                }
                var changed = bare
                changed.pages[0].text += "changed"
                XCTAssertEqual(WholeBookArtBinder.bind(changed, composed: composed, policy: policy).pages, changed.pages)
                changed = bare
                changed.origin?.seriesID = UUID().uuidString
                XCTAssertEqual(WholeBookArtBinder.bind(changed, composed: composed, policy: policy).pages, changed.pages)
                changed = bare
                changed.origin?.discoveryID = "wrong"
                XCTAssertEqual(WholeBookArtBinder.bind(changed, composed: composed, policy: policy).pages, changed.pages)
                XCTAssertEqual(StorySpotBinder.bind(bare, composed: composed, catalog: nil).pages, bare.pages)
            }
        }
        XCTAssertGreaterThan(additions, 0)
        for id in ["object_compass_001", "object_key_001", "object_torn_map_001"] {
            XCTAssertGreaterThanOrEqual(objectBooks[id, default: 0], 2, id)
        }
    }

    func testPolicyThreePinPersistsAndUnknownFourFailsClosed() throws {
        let policy = try XCTUnwrap(WholeBookArtPolicy.bundled)
        let entry = try XCTUnwrap(policy.assets.first)
        let art = WholeBookArtBinder.art(entry: entry, rule: try XCTUnwrap(policy.rules.first), policy: policy)
        XCTAssertTrue(art.isBundledSpot)
        XCTAssertEqual(try JSONDecoder().decode(StoryPageArt.self, from: JSONEncoder().encode(art)), art)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(art)) as? [String: Any])
        json["bindingPolicyVersion"] = 4
        XCTAssertFalse(try JSONDecoder().decode(StoryPageArt.self,
            from: JSONSerialization.data(withJSONObject: json)).isBundledSpot)
    }
}
