import XCTest
@testable import StoryEngine

/// Satırın görsel anlamı (20 Kasım 2026): içerik neyi anlattığını söyler,
/// motor rolü kanonik konuya çevirir, denetim sözlük dışını reddeder.
final class VisualMeaningTests: XCTestCase {

    private func shipped() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    private func catalog(withVariants variants: String) throws -> ContentCatalog {
        let json = """
        {"version": "visual-fixture", "templates": [{"id": "tpl_visual_fixture", "role": "hook",
          "realizesBeat": "notice_anomaly", "compatibleThemes": [], "variants": [\(variants)]}]}
        """
        let extra = try JSONDecoder().decode(ContentCatalog.self, from: Data(json.utf8))
        return ContentCatalog.merging([try shipped(), extra])
    }

    private func codes(_ catalog: ContentCatalog) -> [String] {
        CatalogIntegrityChecker().check(catalog).issues.map(\.code).filter { $0.hasPrefix("visual_") }
    }

    func testUnreviewedEmptyAndAnnotatedAreThreeDifferentThings() throws {
        let catalog = try catalog(withVariants: """
          {"id": "v_none", "text": "{{child.name}} durdu."},
          {"id": "v_empty", "text": "{{child.name}} durdu.", "visual": [], "visualReview": "reviewed"},
          {"id": "v_held", "text": "{{child.name}} {{discovery.name}}'i eline aldı.",
           "visual": [{"subject": "discovery", "presence": "present", "states": ["held"]}],
           "visualReview": "auto"}
        """)
        let variants = Dictionary(uniqueKeysWithValues: catalog.templates.flatMap(\.variants).map { ($0.id.rawValue, $0) })
        XCTAssertNil(variants["v_none"]?.visual)
        XCTAssertEqual(variants["v_empty"]?.visual, [])
        XCTAssertEqual(variants["v_held"]?.visual?.first?.presence, .present)
        XCTAssertEqual(variants["v_held"]?.visualReview, .auto)
        XCTAssertTrue(codes(catalog).isEmpty, "\(codes(catalog))")
    }

    func testTheCheckerRejectsAnUnknownStateAndARepeatedSubject() throws {
        let catalog = try catalog(withVariants: """
          {"id": "v_bad_state", "text": "x", "visual": [{"subject": "discovery", "presence": "present", "states": ["sparkly"]}]},
          {"id": "v_twice", "text": "x", "visual": [{"subject": "companion", "presence": "present"},
                                                  {"subject": "companion", "presence": "remembered"}]},
          {"id": "v_lonely_review", "text": "x", "visualReview": "auto"}
        """)
        XCTAssertEqual(Set(codes(catalog)),
                       ["visual_state_unknown", "visual_subject_repeated", "visual_review_without_visual"])
    }

    /// "Hatırladı" ile "eline aldı" aynı konuyu anar ama aynı varlığı değil.
    func testRolesResolveToTheBoundRecords() throws {
        let catalog = try shipped()
        let content = BoundContent(
            setting: try XCTUnwrap(catalog.settings.first { $0.id.rawValue == "setting_whispering_forest_001" }),
            companion: try XCTUnwrap(catalog.companions.first { $0.id.rawValue == "companion_fox_pilot_001" }),
            discovery: try XCTUnwrap(catalog.objects.first { $0.id.rawValue == "object_torn_map_001" }))
        let resolved = ResolvedVisual.resolve([
            VisualMention(subject: .discovery, presence: .remembered),
            VisualMention(subject: .companion, presence: .present, states: ["helping"]),
            VisualMention(subject: .setting, presence: .present, states: ["evening"])
        ], content: content)
        XCTAssertEqual(resolved.map(\.subjectID),
                       ["object_torn_map_001", "companion_fox_pilot_001", "setting_whispering_forest_001"])
        XCTAssertEqual(resolved.first?.presence, .remembered)
    }

    /// Kaynak izi etiketsiz satırda görsel anlam uydurmaz.
    func testAnUnannotatedLineCarriesNoVisualOnItsPart() throws {
        let catalog = try shipped()
        let story = try OfflineStoryComposer().compose(catalog: catalog, intent: OfflineStoryIntent(
            childName: "Yeliz", seed: "visual-none", mode: .adventure, ageBand: AgeBand(lowerBound: 5, upperBound: 6)))
        var byID: [String: CatalogVariant] = [:]
        for t in catalog.templates { for v in t.variants { byID[v.id.rawValue] = v } }
        for part in story.pages.flatMap(\.provenance) where part.kind == .beatLine {
            let variant = try XCTUnwrap(byID[part.sourceID])
            XCTAssertEqual(part.visual == nil, variant.visual == nil, part.sourceID)
        }
    }
}
