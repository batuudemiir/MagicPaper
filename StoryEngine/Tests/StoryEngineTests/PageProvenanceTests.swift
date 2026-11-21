import XCTest
@testable import StoryEngine

/// Sayfa kaynak izi (20 Kasım 2026, görsel bağlayıcı sözleşmesi).
///
/// Her sayfa, metnini oluşturan parçaları kuruluş sırasıyla taşır: beat
/// satırı, nakarat ve hatırlama ayrı türlerdir; Masal ailem, özel gün, seri ve
/// dünya satırı tür değil bağlamdır. Kaynak kimliği metinden geri tahmin
/// edilmez, sayfa kurulurken yazılır.
final class PageProvenanceTests: XCTestCase {

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    private func compose(_ intent: OfflineStoryIntent, _ catalog: ContentCatalog) throws -> ComposedStory {
        try OfflineStoryComposer().compose(catalog: catalog, intent: intent)
    }

    func testEveryPageNamesItsLinesInTheOrderTheyWereWritten() throws {
        let catalog = try catalog()
        for band in [(3, 4), (5, 6), (7, 8), (9, 10)] {
            for mode in [StoryMode.bedtime, .learning, .adventure] {
                let story = try compose(OfflineStoryIntent(
                    childName: "Yeliz", seed: "prov-\(band.0)-\(mode.rawValue)", mode: mode,
                    ageBand: AgeBand(lowerBound: band.0, upperBound: band.1)), catalog)
                for page in story.pages {
                    XCTAssertEqual(page.provenance.filter { $0.kind == .beatLine }.map(\.sourceID),
                                   page.variantIDs.map(\.rawValue), "p\(page.pageNumber)")
                    XCTAssertFalse(page.provenance.isEmpty)
                    for part in page.provenance {
                        XCTAssertFalse(part.sourceTextDigest.isEmpty)
                        if part.kind == .beatLine {
                            XCTAssertNotNil(part.templateID); XCTAssertNotNil(part.beat)
                        }
                    }
                }
            }
        }
    }

    /// Nakarat bir satır değil: olay örgüsünün kendi metni. Satır kimliği
    /// uydurulmaz; kimlik olay örgüsü + alan, sürüm izi metnin özeti. Bugün
    /// gönderilen hiçbir olay örgüsünde nakarat yok; deney kolu kullanılır
    /// (`RefrainExperimentTests`).
    func testARefrainIsTracedToItsBlueprintNotToAMadeUpLine() throws {
        let experimentURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Content/Experiments/x_refrain_bedtime.json")
        let experiment = try JSONDecoder().decode(ContentCatalog.self, from: Data(contentsOf: experimentURL))
        let catalog = ContentCatalog.merging([try catalog(), experiment])
        let sibling = try XCTUnwrap(experiment.blueprints.first { $0.refrain != nil })
        let refrain = try XCTUnwrap(sibling.refrain)
        let story = try OfflineStoryComposer().compose(
            blueprint: sibling, catalog: catalog, intent: OfflineStoryIntent(childName: "Yeliz", seed: "refrain"))
        var checked = 0
        for page in story.pages {
            guard let text = page.refrain else {
                XCTAssertFalse(page.provenance.contains { $0.kind == .refrain })
                continue
            }
            let last = try XCTUnwrap(page.provenance.last)
            XCTAssertEqual(last.kind, .refrain)
            let field = page.pageNumber == refrain.finalPage ? "finalLine" : "line"
            XCTAssertEqual(last.sourceID, "\(sibling.id.rawValue)#refrain.\(field)")
            XCTAssertEqual(last.sourceTextDigest, PageSourcePart.digest(text))
            XCTAssertFalse(page.variantIDs.map(\.rawValue).contains(last.sourceID))
            checked += 1
        }
        XCTAssertGreaterThan(checked, 1)
    }

    /// Hatırlama satırı sayfanın sonunda ve kaynak izinde. Yazar parmak izi
    /// ise bilerek düşer (`StorySpotProvenanceTests`); beat parçaları kalır.
    func testARecallLineIsTheLastPartOfThePagesProvenance() throws {
        let catalog = try catalog()
        let base = OfflineStoryIntent(childName: "Yeliz", seed: "recall-seed-001", mode: .adventure,
                                      ageBand: AgeBand(lowerBound: 5, upperBound: 6))
        let plain = try compose(base, catalog)
        let here = plain.content.setting.id
        let recall = RecallHistory(
            companions: [plain.content.companion.id: .init(storyCount: 4, firstSettingID: here)],
            visitedSettings: [here])
        let story = try compose(OfflineStoryIntent(childName: "Yeliz", seed: "recall-seed-001", mode: .adventure,
                                                   ageBand: AgeBand(lowerBound: 5, upperBound: 6),
                                                   recall: recall), catalog)
        let lineID = try XCTUnwrap(story.recallLineID)
        let first = try XCTUnwrap(story.pages.first)
        let last = try XCTUnwrap(first.provenance.last)
        XCTAssertEqual(last.kind, .recall)
        XCTAssertEqual(last.sourceID, lineID.rawValue)
        let authored = try XCTUnwrap(catalog.recallLines.first { $0.id == lineID })
        XCTAssertEqual(last.sourceTextDigest, PageSourcePart.digest(authored.text))
        XCTAssertNil(first.authoredSourceFingerprint)
        XCTAssertEqual(Array(first.provenance.dropLast()), plain.pages.first?.provenance)
    }

    /// Masal ailem tür değil bağlam: aynı satır hem beat satırı hem aile satırıdır.
    func testAFamilyLineIsABeatLineWithAFamilyContext() throws {
        let catalog = try catalog()
        var found = false
        for i in 0..<40 {
            let story = try compose(OfflineStoryIntent(
                childName: "Yeliz", seed: "fam-\(i)", mode: .bedtime,
                ageBand: AgeBand(lowerBound: 5, upperBound: 6),
                family: FamilyCast(name: "Ela", relation: .sibling)), catalog)
            let parts = story.pages.flatMap(\.provenance).filter { $0.contexts.contains("family") }
            if let part = parts.first {
                XCTAssertEqual(part.kind, .beatLine)
                found = true
                break
            }
        }
        XCTAssertTrue(found, "Aile satırı taşıyan bir masal bulunamadı.")
    }

    /// Özet yazarın metnidir, çocuğun adıyla doldurulmuş hâli değil.
    func testTheDigestIsOfTheAuthoredTextNotTheRenderedOne() throws {
        let catalog = try catalog()
        let story = try compose(OfflineStoryIntent(childName: "Yeliz", seed: "digest", mode: .learning,
                                                   ageBand: AgeBand(lowerBound: 5, upperBound: 6)), catalog)
        var authored: [String: String] = [:]
        for template in catalog.templates { for v in template.variants { authored[v.id.rawValue] = v.text } }
        for part in story.pages.flatMap(\.provenance) where part.kind == .beatLine {
            let text = try XCTUnwrap(authored[part.sourceID])
            XCTAssertEqual(part.sourceTextDigest, PageSourcePart.digest(text))
        }
        XCTAssertEqual(PageSourcePart.schemaVersion, 1)
    }
}
