import XCTest
import StoryEngine
@testable import MagicPaper

/// Genuine pre-K1 composer→mapper fixtures, frozen before the source changes.
@MainActor
final class FrozenLegacyBooksTests: XCTestCase {
    private struct Fixtures: Decodable { let books: [Book] }
    private struct Book: Decodable {
        let blueprintID: String
        let companionID: String
        let discoveryID: String
        let settingID: String
        let seed: String
        let pages: [Page]
    }
    private struct Page: Decodable {
        let text: String
        let provenance: [PageSourcePart]
        let art: StoryPageArt?
    }

    func testFiveFrozenBooksKeepAllFortyTextsSourceTracesAndArtPins() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "k01-legacy-book-fixtures", withExtension: "json"))
        let fixtures = try JSONDecoder().decode(Fixtures.self, from: Data(contentsOf: url))
        let catalog = try ContentCatalogLoader().load().catalog
        let band = AgeBand(lowerBound: 5, upperBound: 6)
        XCTAssertEqual(fixtures.books.count, 5)
        var pagesChecked = 0
        for fixture in fixtures.books {
            let blueprint = try XCTUnwrap(catalog.blueprint(ContentID(fixture.blueprintID)))
            let intent = OfflineStoryIntent(childName: "Deniz", seed: fixture.seed,
                                           mode: .adventure, ageBand: band)
            let composed = try OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog, intent: intent)
            XCTAssertEqual(composed.content.companion.id.rawValue, fixture.companionID)
            XCTAssertEqual(composed.content.setting.id.rawValue, fixture.settingID)
            XCTAssertEqual(composed.content.discovery.id.rawValue, fixture.discoveryID)
            let mapped = OfflineStoryMapper.appStory(from: composed, childName: "Deniz", childProfileID: UUID(),
                storyIdeaID: nil, catalogVersion: catalog.version, mode: .adventure,
                selectionStrategy: .direct, ageBand: band)
            XCTAssertEqual(mapped.pages.count, fixture.pages.count)
            for (index, expected) in fixture.pages.enumerated() {
                XCTAssertEqual(Data(mapped.pages[index].text.utf8), Data(expected.text.utf8), "\(fixture.blueprintID) p\(index + 1)")
                XCTAssertEqual(mapped.pages[index].provenance, StoryPageProvenance(engine: expected.provenance))
                XCTAssertEqual(mapped.pages[index].art, expected.art)
                pagesChecked += 1
            }
        }
        XCTAssertEqual(pagesChecked, 40)
    }
}
