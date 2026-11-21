import XCTest
import StoryEngine
@testable import MagicPaper

final class ReviewedDiscoveryArtPolicyTests: XCTestCase {
    func testExpansionAuthorizesEverySubjectSourceAndRecallWithCoupledAsset() throws {
        let policy = try XCTUnwrap(ReviewedDiscoveryArtPolicy.bundled)
        let catalog = try ContentCatalogLoader().load().catalog
        XCTAssertEqual(policy.entries.count, 20)
        XCTAssertEqual(policy.sources.count, 20)
        XCTAssertEqual(policy.pairedSources.count, 4)
        XCTAssertEqual(policy.pairedBlueprintIDs.count, 3)
        for entry in policy.entries {
            let object = try XCTUnwrap(catalog.objects.first { $0.id.rawValue == entry.asset.subjectID })
            var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(object)) as? [String: Any])
            json["description"] = "Changed canonical description"
            let changed = try JSONDecoder().decode(CatalogObject.self, from: JSONSerialization.data(withJSONObject: json))
            for source in policy.sources where source.templateID != "corpus_3-4_notice_anomaly" {
                let beat = PageSourcePart(kind: .beatLine, sourceID: source.sourceID,
                    sourceTextDigest: source.sourceTextDigest, templateID: source.templateID, beat: .noticeAnomaly,
                    visual: [.init(subject: .discovery, subjectID: object.id.rawValue, presence: .present, states: [])])
                XCTAssertEqual(policy.authorization(parts: [beat], variantIDs: [source.sourceID], discovery: object)?.asset.assetID,
                    entry.asset.assetID)
                XCTAssertNil(policy.authorization(parts: [beat], variantIDs: [source.sourceID], discovery: changed))
                for context in ["family", "occasion", "series", "unknown"] {
                    let contextual = PageSourcePart(kind: .beatLine, sourceID: source.sourceID,
                        sourceTextDigest: source.sourceTextDigest, templateID: source.templateID, beat: .noticeAnomaly,
                        contexts: [context], visual: beat.visual)
                    XCTAssertNil(policy.authorization(parts: [contextual], variantIDs: [source.sourceID], discovery: object))
                }
                let unknown = PageSourcePart(kind: .beatLine, sourceID: "unknown",
                    sourceTextDigest: source.sourceTextDigest, templateID: source.templateID,
                    beat: .noticeAnomaly, visual: beat.visual)
                XCTAssertNil(policy.authorization(parts: [unknown], variantIDs: ["unknown"], discovery: object))
                for other in policy.entries where other.asset.subjectID != object.id.rawValue {
                    let crossSubject = try XCTUnwrap(catalog.objects.first { $0.id.rawValue == other.asset.subjectID })
                    XCTAssertNil(policy.authorization(parts: [beat], variantIDs: [source.sourceID], discovery: crossSubject))
                }
                for recall in policy.recalls {
                    let part = PageSourcePart(kind: .recall, sourceID: recall.sourceID, sourceTextDigest: recall.sourceTextDigest)
                    let ids = [source.sourceID, recall.sourceID]
                    XCTAssertEqual(policy.authorization(parts: [beat, part], variantIDs: ids, discovery: object)?.asset.assetID,
                        entry.asset.assetID)
                    let corrupt = PageSourcePart(kind: .recall, sourceID: recall.sourceID, sourceTextDigest: "changed")
                    XCTAssertNil(policy.authorization(parts: [beat, corrupt], variantIDs: ids, discovery: object))
                    XCTAssertNil(policy.authorization(parts: [beat], variantIDs: ids, discovery: object))
                    XCTAssertNil(policy.authorization(parts: [part, beat], variantIDs: Array(ids.reversed()), discovery: object))
                    XCTAssertNil(policy.authorization(parts: [beat, part, part], variantIDs: ids + [recall.sourceID], discovery: object))
                }
            }
        }
    }

    func testPairedSourcesRequireExactCompositionContextAndCompanion() throws {
        let policy = try XCTUnwrap(ReviewedDiscoveryArtPolicy.bundled)
        let catalog = try ContentCatalogLoader().load().catalog
        let object = try XCTUnwrap(catalog.objects.first { $0.id.rawValue == "object_compass_001" })
        for source in policy.sources where source.templateID == "corpus_3-4_notice_anomaly" {
            let notice = PageSourcePart(kind: .beatLine, sourceID: source.sourceID,
                sourceTextDigest: source.sourceTextDigest, templateID: source.templateID, beat: .noticeAnomaly,
                visual: [.init(subject: .discovery, subjectID: object.id.rawValue, presence: .present, states: [])])
            XCTAssertNil(policy.authorization(parts: [notice], variantIDs: [source.sourceID], discovery: object))
            for support in policy.pairedSources {
                let meet = PageSourcePart(kind: .beatLine, sourceID: support.sourceID,
                    sourceTextDigest: support.sourceTextDigest, templateID: support.templateID, beat: .meetCompanion,
                    visual: [.init(subject: .companion, subjectID: "friend", presence: .present, states: ["greeting"])])
                let parts = [notice, meet], ids = parts.map(\.sourceID)
                for blueprint in policy.pairedBlueprintIDs {
                    XCTAssertEqual(policy.authorization(parts: parts, variantIDs: ids, discovery: object,
                        blueprintID: blueprint, pageNumber: 1, companionID: "friend")?.beats, [.noticeAnomaly, .meetCompanion])
                    for page in [0, 2] {
                        XCTAssertNil(policy.authorization(parts: parts, variantIDs: ids, discovery: object,
                            blueprintID: blueprint, pageNumber: page, companionID: "friend"))
                    }
                    XCTAssertNil(policy.authorization(parts: parts, variantIDs: ids, discovery: object,
                        blueprintID: blueprint, pageNumber: 1, companionID: "wrong"))
                }
                XCTAssertNil(policy.authorization(parts: parts, variantIDs: ids, discovery: object))
                XCTAssertNil(policy.authorization(parts: parts, variantIDs: ids, discovery: object,
                    blueprintID: "unknown", pageNumber: 1, companionID: "friend"))
                XCTAssertNil(policy.authorization(parts: Array(parts.reversed()), variantIDs: Array(ids.reversed()), discovery: object,
                    blueprintID: policy.pairedBlueprintIDs.first, pageNumber: 1, companionID: "friend"))
                XCTAssertNil(policy.authorization(parts: parts + [meet], variantIDs: ids + [meet.sourceID], discovery: object,
                    blueprintID: policy.pairedBlueprintIDs.first, pageNumber: 1, companionID: "friend"))
            }
        }
    }

    func testPairedMalformedSourcesAndVisualsFailClosed() throws {
        let policy = try XCTUnwrap(ReviewedDiscoveryArtPolicy.bundled)
        let catalog = try ContentCatalogLoader().load().catalog
        let object = try XCTUnwrap(catalog.objects.first { $0.id.rawValue == "object_coin_001" })
        let source = try XCTUnwrap(policy.sources.first { $0.templateID == "corpus_3-4_notice_anomaly" })
        let support = try XCTUnwrap(policy.pairedSources.first)
        let notice = PageSourcePart(kind: .beatLine, sourceID: source.sourceID,
            sourceTextDigest: source.sourceTextDigest, templateID: source.templateID, beat: .noticeAnomaly,
            visual: [.init(subject: .discovery, subjectID: object.id.rawValue, presence: .present, states: [])])
        let meet = PageSourcePart(kind: .beatLine, sourceID: support.sourceID,
            sourceTextDigest: support.sourceTextDigest, templateID: support.templateID, beat: .meetCompanion,
            visual: [.init(subject: .companion, subjectID: "friend", presence: .present, states: ["greeting"])])
        func authorize(_ parts: [PageSourcePart], ids: [String]? = nil) -> ReviewedDiscoveryArtPolicy.Authorization? {
            policy.authorization(parts: parts, variantIDs: ids ?? parts.map(\.sourceID), discovery: object,
                blueprintID: policy.pairedBlueprintIDs.first, pageNumber: 1, companionID: "friend")
        }
        XCTAssertNotNil(authorize([notice, meet]))
        for (template, digest, contexts, visual) in [
            ("wrong", support.sourceTextDigest, [String](), meet.visual!),
            (support.templateID, "wrong", [], meet.visual!),
            (support.templateID, support.sourceTextDigest, ["family"], meet.visual!),
            (support.templateID, support.sourceTextDigest, [], [.init(subject: .companion, subjectID: "friend", presence: .remembered, states: ["greeting"])]),
            (support.templateID, support.sourceTextDigest, [], [.init(subject: .companion, subjectID: "friend", presence: .present, states: [])]),
            (support.templateID, support.sourceTextDigest, [], meet.visual! + notice.visual!)
        ] {
            let changed = PageSourcePart(kind: .beatLine, sourceID: support.sourceID, sourceTextDigest: digest,
                templateID: template, beat: .meetCompanion, contexts: contexts, visual: visual)
            XCTAssertNil(authorize([notice, changed]))
        }
        for context in ["family", "occasion", "series", "world", "unknown"] {
            let changed = PageSourcePart(kind: .beatLine, sourceID: source.sourceID,
                sourceTextDigest: source.sourceTextDigest, templateID: source.templateID, beat: .noticeAnomaly,
                contexts: [context], visual: notice.visual)
            XCTAssertNil(authorize([changed, meet]))
        }
        let recall = try XCTUnwrap(policy.recalls.first)
        XCTAssertNil(authorize([notice, meet, .init(kind: .recall, sourceID: recall.sourceID, sourceTextDigest: recall.sourceTextDigest)]))
        XCTAssertNil(authorize([notice, meet], ids: [meet.sourceID, notice.sourceID]))
        XCTAssertNil(authorize([notice, meet], ids: [notice.sourceID]))
    }

    func testOldElevenSubjectManifestRemainsReadable() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "reviewed-discovery-art-expansion-v2", withExtension: "json"))
        let policy = try XCTUnwrap(ReviewedDiscoveryArtPolicy.load(data: Data(contentsOf: url)) { _, _ in true })
        XCTAssertEqual(policy.entries.count, 11)
        XCTAssertEqual(policy.sources.count, 5)
        XCTAssertTrue(policy.pairedSources.isEmpty)
        XCTAssertTrue(policy.pairedBlueprintIDs.isEmpty)
    }

    func testOldFourteenSubjectManifestRemainsReadable() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "reviewed-discovery-art-wave2-v2", withExtension: "json"))
        let policy = try XCTUnwrap(ReviewedDiscoveryArtPolicy.load(data: Data(contentsOf: url)) { _, _ in true })
        XCTAssertEqual(policy.entries.count, 14)
        XCTAssertEqual(policy.sources.count, 20)
        XCTAssertEqual(policy.pairedSources.count, 4)
        XCTAssertEqual(policy.pairedBlueprintIDs.count, 3)
    }

    @MainActor
    func testWaveTwoRealComposerMapsNewSubjectsAndAgeBandsWithoutChangingText() throws {
        for (age, discovery) in [("3-4", "object_compass_001"), ("7-8", "object_coin_001"),
                                  ("9-10", "object_star_stone_001")] {
            try assertRealComposition(age: age, discovery: discovery, wave: "wave2")
        }
    }

    @MainActor
    func testWaveThreeRealComposerMapsSixSubjectsWithoutChangingText() throws {
        for (age, discovery) in [("3-4", "object_ball_001"), ("3-4", "object_jump_rope_001"),
                                  ("3-4", "object_kite_001"), ("5-6", "object_ribbon_001"),
                                  ("7-8", "object_flute_001"), ("9-10", "object_mirror_001")] {
            try assertRealComposition(age: age, discovery: discovery, wave: "wave3")
        }
    }

    @MainActor
    private func assertRealComposition(age: String, discovery: String, wave: String) throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let policy = try XCTUnwrap(ReviewedDiscoveryArtPolicy.bundled)
        var matched = false
        for blueprint in catalog.blueprints where blueprint.ageRange.description == age {
            if age == "3-4" && !policy.pairedBlueprintIDs.contains(blueprint.id.rawValue) { continue }
            for seed in 0..<48 {
                let intent = OfflineStoryIntent(childName: "Deniz",
                    settingID: age == "3-4" && wave == "wave3" ? ContentID("setting_village_green_001") : nil,
                    discoveryID: ContentID(discovery),
                    seed: "reviewed-\(wave)-\(seed)")
                guard let composed = try? OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog, intent: intent),
                      composed.pages.contains(where: { policy.authorization(parts: $0.provenance,
                        variantIDs: $0.variantIDs.map(\.rawValue), discovery: composed.content.discovery,
                        blueprintID: composed.blueprintID.rawValue, pageNumber: $0.pageNumber,
                        companionID: composed.content.companion.id.rawValue) != nil }) else { continue }
                XCTAssertEqual(composed.content.discovery.id.rawValue, discovery)
                if age == "3-4" {
                    if wave == "wave3" {
                        XCTAssertEqual(composed.content.setting.id.rawValue, "setting_village_green_001")
                    }
                    XCTAssertEqual(composed.pages.first?.beats, [.noticeAnomaly, .meetCompanion])
                }
                let story = OfflineStoryMapper.appStory(from: composed, childName: "Deniz", childProfileID: UUID(),
                    storyIdeaID: nil, catalogVersion: catalog.version)
                XCTAssertEqual(story.pages.map(\.text), composed.pages.sorted { $0.pageNumber < $1.pageNumber }.map(\.text))
                let art = try XCTUnwrap(story.pages.compactMap(\.art).first)
                XCTAssertEqual(art.subjectID, discovery)
                XCTAssertEqual(art.bindingPolicyVersion, 2)
                let artIndex = try XCTUnwrap(story.pages.firstIndex { $0.art != nil })
                let page = composed.pages.sorted { $0.pageNumber < $1.pageNumber }[artIndex]
                let evidence = "age=\(age) blueprint=\(blueprint.id.rawValue) seed=reviewed-\(wave)-\(seed) subject=\(discovery) page=\(page.pageNumber) beats=\(page.beats.map(\.rawValue)) variants=\(page.variantIDs.map(\.rawValue))"
                XCTContext.runActivity(named: evidence) { activity in
                    let attachment = XCTAttachment(string: evidence)
                    attachment.lifetime = .keepAlways
                    activity.add(attachment)
                }
                XCTAssertNotNil(StorySpotAssetResolver.url(for: art))
                let saved = try JSONDecoder().decode(MagicPaper.Story.self, from: JSONEncoder().encode(story))
                XCTAssertEqual(saved.pages.compactMap(\.art), story.pages.compactMap(\.art))
                matched = true
                break
            }
            if matched { break }
        }
        XCTAssertTrue(matched, "Missing real composed fixture: \(age) \(discovery)")
    }

    func testExpansionManifestAndEveryMissingAssetFailClosed() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "reviewed-discovery-art-wave3-v2", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let policy = try XCTUnwrap(ReviewedDiscoveryArtPolicy.load(data: data) { _, _ in true })
        for entry in policy.entries {
            XCTAssertNil(ReviewedDiscoveryArtPolicy.load(data: data) { file, _ in file != entry.asset.fileName })
        }
        XCTAssertNil(ReviewedDiscoveryArtPolicy.load(data: data + Data([32])) { _, _ in true })
    }

    @MainActor
    func testRealComposerExpandedSubjectsPreserveVersionOnePriorityAndReviewedFallback() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let policy = try XCTUnwrap(ReviewedDiscoveryArtPolicy.bundled)
        let fixtures = [
            ("blueprint_absence_looking_001", "setting_forest_001", "companion_rabbit_pilot_001", "object_torn_map_001", "story-art-audit-23"),
            ("blueprint_appeal_together_001", "setting_forest_001", "companion_sparrow_001", "object_dropped_mitten_001", "story-art-audit-2"),
            ("blueprint_threshold_crossing_001", "setting_cloud_harbor_001", "companion_robot_sky_001", "object_lantern_001", "story-art-audit-1"),
            ("blueprint_appeal_together_001", "setting_whispering_forest_001", "companion_owl_pilot_001", "object_key_001", "story-art-audit-3"),
            ("blueprint_threshold_crossing_001", "setting_river_001", "companion_rabbit_pilot_001", "object_crystal_001", "story-art-audit-17"),
            ("blueprint_appeal_together_001", "setting_cave_001", "companion_owl_pilot_001", "object_feather_001", "story-art-audit-1"),
            ("bp_appeal_speakingup_002", "setting_beach_001", "companion_penguin_001", "object_shell_001", "story-art-audit-1"),
            ("bp_appeal_speakingup_002", "setting_meadow_001", "companion_firefly_001", "object_magnifying_glass_001", "story-art-audit-2"),
            ("bp_appeal_speakingup_002", "setting_coral_sea_001", "companion_penguin_001", "object_rope_001", "story-art-audit-0"),
            ("blueprint_appeal_together_001", "setting_garden_001", "companion_cat_001", "object_paper_lantern_001", "story-art-audit-5")
        ]
        XCTAssertEqual(fixtures.count, 10)
        for (blueprintID, settingID, companionID, discoveryID, seed) in fixtures {
            let blueprint = try XCTUnwrap(catalog.blueprints.first { $0.id.rawValue == blueprintID })
            let plainIntent = OfflineStoryIntent(childName: "Deniz", settingID: ContentID(settingID),
                companionID: ContentID(companionID), discoveryID: ContentID(discoveryID), seed: seed)
            let plain = try OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog, intent: plainIntent)
            let versionOne = OfflineStoryMapper.appStory(from: plain, childName: "Deniz", childProfileID: UUID(),
                storyIdeaID: nil, catalogVersion: catalog.version)
            XCTAssertEqual(versionOne.pages.first?.art?.bindingPolicyVersion, 1, discoveryID)
            var reviewed: MagicPaper.Story?
            var composedTexts: [String] = []
            // A fixed canonical cast and bounded seeds keep coverage independent of catalog search size.
            for attempt in 0..<32 {
                let intent = OfflineStoryIntent(childName: "Deniz", settingID: ContentID(settingID),
                    companionID: ContentID(companionID), discoveryID: ContentID(discoveryID),
                    seed: "reviewed-expansion-\(attempt)", recall: RecallHistory(companions: [ContentID(companionID):
                        .init(storyCount: 2, firstSettingID: ContentID(settingID))]))
                let composed = try OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog, intent: intent)
                guard composed.pages.contains(where: { $0.provenance.count == 2 && policy.authorization(
                    parts: $0.provenance, variantIDs: $0.variantIDs.map(\.rawValue), discovery: composed.content.discovery) != nil })
                else { continue }
                composedTexts = composed.pages.sorted { $0.pageNumber < $1.pageNumber }.map(\.text)
                reviewed = OfflineStoryMapper.appStory(from: composed, childName: "Deniz", childProfileID: UUID(),
                    storyIdeaID: nil, catalogVersion: catalog.version)
                break
            }
            let story = try XCTUnwrap(reviewed, discoveryID)
            XCTAssertEqual(story.pages.map(\.text), composedTexts)
            let art = try XCTUnwrap(story.pages.compactMap(\.art).first)
            XCTAssertEqual(art.bindingPolicyVersion, 2)
            XCTAssertEqual(art.subjectID, discoveryID)
            XCTAssertNotNil(StorySpotAssetResolver.url(for: art))
            let saved = try JSONDecoder().decode(MagicPaper.Story.self, from: JSONEncoder().encode(story))
            XCTAssertEqual(saved.pages.compactMap(\.art), story.pages.compactMap(\.art))
        }
    }

    func testExcludedAndUnknownDiscoveriesNeverAuthorize() throws {
        let policy = try XCTUnwrap(ReviewedDiscoveryArtPolicy.bundled)
        let catalog = try ContentCatalogLoader().load().catalog
        let source = try XCTUnwrap(policy.sources.first)
        let excluded = catalog.objects.filter { object in
            !policy.entries.contains { $0.asset.subjectID == object.id.rawValue }
        }
        XCTAssertFalse(excluded.isEmpty)
        for object in excluded {
            let beat = PageSourcePart(kind: .beatLine, sourceID: source.sourceID,
                sourceTextDigest: source.sourceTextDigest, templateID: source.templateID,
                beat: .noticeAnomaly, visual: [.init(subject: .discovery, subjectID: object.id.rawValue,
                    presence: .present, states: [])])
            XCTAssertNil(policy.authorization(parts: [beat], variantIDs: [source.sourceID], discovery: object))
        }
    }

    func testLegacyBellProofMatchesExpansionExactly() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "reviewed-discovery-art-v2", withExtension: "json"))
        let legacy = try XCTUnwrap(ReviewedDiscoveryArtPolicy.load(data: Data(contentsOf: url)) { _, _ in true })
        let expanded = try XCTUnwrap(ReviewedDiscoveryArtPolicy.bundled)
        let catalog = try ContentCatalogLoader().load().catalog
        let bell = try XCTUnwrap(catalog.objects.first { $0.id.rawValue == "object_bell_001" })
        for source in legacy.sources {
            let beat = PageSourcePart(kind: .beatLine, sourceID: source.sourceID,
                sourceTextDigest: source.sourceTextDigest, templateID: source.templateID, beat: .noticeAnomaly,
                visual: [.init(subject: .discovery, subjectID: bell.id.rawValue, presence: .present, states: [])])
            XCTAssertEqual(legacy.proof(parts: [beat], variantIDs: [source.sourceID], discovery: bell),
                expanded.proof(parts: [beat], variantIDs: [source.sourceID], discovery: bell))
        }
    }

    func testOnlyExactManuallyReviewedSourceAndCanonicalDiscoveryAuthorize() throws {
        let policy = try XCTUnwrap(ReviewedDiscoveryArtPolicy.bundled)
        let catalog = try ContentCatalogLoader().load().catalog
        let bell = try XCTUnwrap(catalog.objects.first { $0.id.rawValue == "object_bell_001" })
        var objectJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(bell)) as? [String: Any])
        objectJSON["description"] = "Changed canonical description"
        let changedBell = try JSONDecoder().decode(CatalogObject.self,
            from: JSONSerialization.data(withJSONObject: objectJSON))
        XCTAssertEqual(policy.sources.count, 20)
        XCTAssertEqual(policy.recalls.count, 38)
        for source in policy.sources where source.templateID != "corpus_3-4_notice_anomaly" {
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
        XCTAssertTrue(art(policy: 3).isBundledSpot)
        XCTAssertFalse(art(policy: 4).isBundledSpot)
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
    func testEveryReviewedBundledRevisionDecodesInReader() async throws {
        let policy = try XCTUnwrap(ReviewedDiscoveryArtPolicy.bundled)
        XCTAssertEqual(policy.entries.count, 20)
        for entry in policy.entries {
            let asset = entry.asset
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

}
