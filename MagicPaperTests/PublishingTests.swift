import XCTest
@testable import MagicPaper

/// Faz 12: baskıya hazır PDF ölçüleri ve yıllık.
final class PublishingTests: XCTestCase {

    func testPrintSpecAddsBleedAndSlugAroundTheTrim() {
        let spec = MPPrintSpec.a5
        let trim = CGSize(width: 420, height: 595)
        XCTAssertEqual(spec.bleed, 3 * 72 / 25.4, accuracy: 0.001)
        XCTAssertEqual(spec.trimBox(trim: trim).size, trim)
        XCTAssertEqual(spec.bleedBox(trim: trim).width, 420 + spec.bleed * 2, accuracy: 0.001)
        XCTAssertTrue(spec.mediaBox(trim: trim).contains(spec.bleedBox(trim: trim)))
        XCTAssertEqual(spec.pageInfo(trim: trim).count, 2)
    }

    private func finished(_ title: String, setting: String, companion: String, at date: Date) -> Story {
        var story = ReaderFixtures.textStory(pages: 3, title: title)
        story.lastReadPage = 2
        story.lastReadAt = date
        story.origin = StoryOrigin(seed: "s", storyIdeaID: nil, blueprintID: "b", settingID: setting,
                                   companionID: companion, discoveryID: "d", fingerprint: "f",
                                   catalogVersion: "1", seriesEpisode: nil)
        return story
    }

    func testYearbookKeepsOnlyThatYearsFinishedStoriesInOrder() {
        let cal = Calendar(identifier: .gregorian)
        let d = { (y: Int, m: Int) in cal.date(from: DateComponents(year: y, month: m, day: 10))! }
        var unfinished = finished("Yarım", setting: "garden", companion: "fox", at: d(2026, 5))
        unfinished.lastReadPage = 0
        let stories = [
            finished("İkinci", setting: "forest", companion: "owl", at: d(2026, 9)),
            finished("Birinci", setting: "garden", companion: "fox", at: d(2026, 3)),
            finished("Üçüncü", setting: "garden", companion: "fox", at: d(2026, 11)),
            finished("Geçen yıl", setting: "garden", companion: "fox", at: d(2025, 12)),
            unfinished
        ]
        let book = MPYearbook(year: 2026, childName: "Yeliz", stories: stories, calendar: cal,
                              placeName: { ["garden": "Gece Bahçesi", "forest": "Fısıldayan Orman"][$0] },
                              companionName: { ["fox": "Tarçın", "owl": "Yıldız"][$0] })
        XCTAssertEqual(book.stories.map(\.title), ["Birinci", "İkinci", "Üçüncü"])
        XCTAssertEqual(book.places.first?.name, "Gece Bahçesi")
        XCTAssertEqual(book.places.first?.count, 2)
        XCTAssertEqual(book.friends, ["Tarçın", "Yıldız"])
        XCTAssertEqual(book.summaryLine, "2026 yılında 3 masal, 2 yer, 2 dost.")
        XCTAssertEqual(book.title, "Bu yıl Yeliz'in dünyasında")
    }

    func testAnEmptyYearSaysSo() {
        let book = MPYearbook(year: 2026, childName: "Yeliz", stories: [],
                              placeName: { _ in nil }, companionName: { _ in nil })
        XCTAssertTrue(book.isEmpty)
        XCTAssertTrue(book.sections.isEmpty)
    }
}
