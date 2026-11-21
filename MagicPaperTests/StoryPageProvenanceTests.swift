import StoryEngine
import XCTest
@testable import MagicPaper

/// Sayfanın kalıcı kaynak izi (20 Kasım 2026): motorun parçaları kitapla,
/// sırasıyla saklanır; eski kitaplarda yoktur ve sonradan üretilmez.
final class StoryPageProvenanceTests: XCTestCase {

    private func story(seed: String, recall: RecallHistory? = nil) throws -> (ComposedStory, MagicPaper.Story) {
        let catalog = try ContentCatalogLoader().load().catalog
        let composed = try OfflineStoryComposer().compose(catalog: catalog, intent: OfflineStoryIntent(
            childName: "Deniz", seed: seed, mode: .adventure,
            ageBand: AgeBand(lowerBound: 5, upperBound: 6), recall: recall))
        let story = OfflineStoryMapper.appStory(from: composed, childName: "Deniz", childProfileID: UUID(),
            storyIdeaID: nil, catalogVersion: catalog.version, ageBand: AgeBand(lowerBound: 5, upperBound: 6))
        return (composed, story)
    }

    func testEveryPageCarriesTheEnginesPartsInOrder() throws {
        let (composed, story) = try story(seed: "provenance-app")
        XCTAssertEqual(story.pages.count, composed.pages.count)
        for (page, engine) in zip(story.pages, composed.pages.sorted { $0.pageNumber < $1.pageNumber }) {
            let provenance = try XCTUnwrap(page.provenance)
            XCTAssertEqual(provenance.schemaVersion, PageSourcePart.schemaVersion)
            XCTAssertTrue(provenance.isComplete)
            XCTAssertEqual(provenance.parts.map(\.sourceID), engine.provenance.map(\.sourceID))
            XCTAssertEqual(provenance.parts.map(\.sourceKind), engine.provenance.map(\.kind.rawValue))
            XCTAssertEqual(provenance.beatLineIDs, engine.variantIDs.map(\.rawValue))
            // Görsel anlam kanonik konu kimliğiyle taşınır; etiketsiz satırda yok.
            XCTAssertEqual(provenance.parts.map { $0.visual?.map(\.subjectID) },
                           engine.provenance.map { $0.visual?.map(\.subjectID) })
            XCTAssertEqual(provenance.parts.map(\.visualReview), engine.provenance.map { $0.visualReview?.rawValue })
        }
        // Masal düzeyindeki düz liste (soğuma için) değişmedi.
        XCTAssertEqual(story.origin?.variantIDs, composed.pages.flatMap { $0.variantIDs.map(\.rawValue) })
    }

    func testARecallLineIsSavedAsItsOwnPartOnThePageItWasAddedTo() throws {
        let (plain, _) = try story(seed: "provenance-recall")
        let here = plain.content.setting.id
        let recall = RecallHistory(
            companions: [plain.content.companion.id: .init(storyCount: 4, firstSettingID: here)],
            visitedSettings: [here])
        let (composed, story) = try story(seed: "provenance-recall", recall: recall)
        guard let lineID = composed.recallLineID else { throw XCTSkip("Bu seed hatırlama satırı yazmadı.") }
        let first = try XCTUnwrap(story.pages.first?.provenance)
        XCTAssertEqual(first.parts.last?.sourceKind, "recall")
        XCTAssertEqual(first.parts.last?.sourceID, lineID.rawValue)
        XCTAssertFalse(first.beatLineIDs.contains(lineID.rawValue))
    }

    func testItSurvivesSavingAndAnOldBookHasNone() throws {
        let (_, story) = try story(seed: "provenance-codable")
        let data = try JSONEncoder().encode(story)
        let decoded = try JSONDecoder().decode(MagicPaper.Story.self, from: data)
        XCTAssertEqual(decoded.pages.map(\.provenance), story.pages.map(\.provenance))

        let old = MagicPaper.StoryPage(title: "", text: "Eski bir sayfa.", imagePrompt: "")
        let oldDecoded = try JSONDecoder().decode(MagicPaper.StoryPage.self, from: JSONEncoder().encode(old))
        XCTAssertNil(oldDecoded.provenance)
    }

    /// Tanınmayan tür okunur; bozuk parça atlanır, öbürleri ve sıra kalır.
    func testAnUnknownKindIsKeptAndABrokenPartIsDropped() throws {
        let json = """
        {"schemaVersion": 1, "parts": [
          {"sourceKind": "beat_line", "sourceID": "a", "sourceTextDigest": "1", "contexts": ["family"]},
          {"sourceKind": "future_kind", "sourceID": "b", "sourceTextDigest": "2"},
          {"sourceID": "broken"},
          {"sourceKind": "recall", "sourceID": "c", "sourceTextDigest": "3"}
        ]}
        """
        let provenance = try JSONDecoder().decode(StoryPageProvenance.self, from: Data(json.utf8))
        XCTAssertEqual(provenance.parts.map(\.sourceID), ["a", "b", "c"])
        // Atlanan parça sayfayı eksik yapar; yeniden kaydedilince de eksik kalır.
        XCTAssertFalse(provenance.isComplete)
        let again = try JSONDecoder().decode(StoryPageProvenance.self, from: JSONEncoder().encode(provenance))
        XCTAssertFalse(again.isComplete)
        XCTAssertEqual(again.partCount, 4)
        XCTAssertEqual(provenance.parts.first?.contexts, ["family"])
        XCTAssertEqual(provenance.beatLineIDs, ["a"])
    }
}
