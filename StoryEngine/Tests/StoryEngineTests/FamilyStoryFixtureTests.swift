import XCTest
@testable import StoryEngine

/// Masal ailem masallarının tam metni, bant × ilişki türü başına bir masal (FAZ 11).
///
/// `FamilyCastTests` kuralları sınar; bu test metnin kendisini sabitler. Bir
/// fark her zaman hata değildir ama her zaman bir karardır: içerik ya da
/// motor değiştiyse fixture bilerek yeniden üretilir ve commit'te neden
/// değiştiği söylenir. Yerel ad, keşif, yol arkadaşı ve tohum sabittir.
final class FamilyStoryFixtureTests: XCTestCase {

    /// Set to true, run once, set back to false. Do not leave it on.
    private let regenerateFixture = false

    private struct Story: Codable, Equatable {
        let band: String
        let relation: String
        let blueprintID: String
        let pages: [String]
    }

    private static var fixtureURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/family_stories_01.json")
    }

    func testFamilyStoriesMatchTheFixture() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        var stories: [Story] = []
        for band in [AgeBand(lowerBound: 3, upperBound: 4), AgeBand(lowerBound: 5, upperBound: 6)] {
            for relation in FamilyRelationKind.allCases {
                let family: FamilyCast
                switch relation {
                case .sibling: family = FamilyCast(name: "Ela", relation: .sibling)
                case .friend: family = FamilyCast(name: "Deniz", relation: .friend)
                case .animal:
                    family = FamilyCast(name: "Boncuk", relation: .animal,
                                        animalKind: catalog.familyAnimalKind("family_animal_cat"))
                case .imaginary: family = FamilyCast(name: "Bulut", relation: .imaginary)
                }
                let story = try OfflineStoryComposer().compose(
                    catalog: catalog,
                    intent: OfflineStoryIntent(
                        childName: "Yeliz", seed: "family-golden", mode: .bedtime,
                        ageBand: band, family: family))
                stories.append(Story(
                    band: band.description, relation: relation.rawValue,
                    blueprintID: story.blueprintID.rawValue, pages: story.pages.map(\.text)))
            }
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        if regenerateFixture {
            try encoder.encode(stories).write(to: Self.fixtureURL)
            XCTFail("Fixture regenerated at \(Self.fixtureURL.path); set regenerateFixture back to false.")
            return
        }
        let expected = try JSONDecoder().decode([Story].self, from: Data(contentsOf: Self.fixtureURL))
        XCTAssertEqual(stories.count, expected.count)
        for (actual, pinned) in zip(stories, expected) {
            XCTAssertEqual(actual, pinned, "\(actual.band) \(actual.relation)")
        }
    }
}
