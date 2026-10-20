import XCTest
@testable import MagicPaper

/// Masala "değerli nesne" havası: ithaf ve künye (`StoryColophon`).
final class StoryColophonTests: XCTestCase {

    private let ela = UUID()
    private let can = UUID()

    private func story(_ owner: UUID?, name: String = "Ela", minutesAgo: Double,
                       pages: Int = 2) -> Story {
        var s = Story(title: "Masal", childName: name, childProfileID: owner,
                      theme: .fantasy, language: .turkish, status: .completed,
                      pages: (0..<pages).map { _ in StoryPage(title: "", text: "Bir varmış.", imagePrompt: "") })
        s.createdAt = Date(timeIntervalSince1970: 1_800_000_000 - minutesAgo * 60)
        return s
    }

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return c
    }

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    // MARK: - Sıra numarası

    func testTheOrdinalFollowsWhenEachStoryWasWritten() {
        let first = story(ela, minutesAgo: 300)
        let second = story(ela, minutesAgo: 200)
        let third = story(ela, minutesAgo: 100)
        let library = [third, first, second]
        XCTAssertEqual(StoryColophon.ordinal(of: first, among: library), 1)
        XCTAssertEqual(StoryColophon.ordinal(of: second, among: library), 2)
        XCTAssertEqual(StoryColophon.ordinal(of: third, among: library), 3)
    }

    func testAnotherChildsStoriesAreNotCounted() {
        let mine = story(ela, minutesAgo: 10)
        let library = [story(can, name: "Can", minutesAgo: 50), story(can, name: "Can", minutesAgo: 40), mine]
        XCTAssertEqual(StoryColophon.ordinal(of: mine, among: library), 1)
    }

    func testAStoryNotYetInTheLibraryComesAfterTheOthers() {
        let library = [story(ela, minutesAgo: 50), story(ela, minutesAgo: 40)]
        XCTAssertEqual(StoryColophon.ordinal(of: story(ela, minutesAgo: 0), among: library), 3)
    }

    func testOldStoriesWithoutAnIdMatchByName() {
        let old = story(nil, minutesAgo: 90)
        let library = [old, story(nil, name: "Can", minutesAgo: 80), story(nil, minutesAgo: 70)]
        XCTAssertEqual(StoryColophon.ordinal(of: library[2], among: library), 2)
    }

    // MARK: - İthaf

    func testTheDedicationNamesTheChildAndTheEvening() {
        let d = StoryColophon.dedication(childName: "İrem", date: date(16, 20, 15), calendar: calendar)
        XCTAssertEqual(d.line, "Bu masal İrem için yazıldı.")
        XCTAssertEqual(d.date, "16 Ekim 2026, Cuma akşamı")
    }

    func testThePartOfTheDayFollowsTheClock() {
        func part(_ hour: Int, _ minute: Int = 0) -> String {
            StoryColophon.dedication(childName: "Ela", date: date(15, hour, minute), calendar: calendar).date
        }
        XCTAssertEqual(part(4, 59), "15 Ekim 2026, Perşembe gecesi")
        XCTAssertEqual(part(5), "15 Ekim 2026, Perşembe sabahı")
        XCTAssertEqual(part(11, 59), "15 Ekim 2026, Perşembe sabahı")
        XCTAssertEqual(part(12), "15 Ekim 2026, Perşembe öğleden sonrası")
        XCTAssertEqual(part(17, 59), "15 Ekim 2026, Perşembe öğleden sonrası")
        XCTAssertEqual(part(18), "15 Ekim 2026, Perşembe akşamı")
        XCTAssertEqual(part(21, 59), "15 Ekim 2026, Perşembe akşamı")
        XCTAssertEqual(part(22), "15 Ekim 2026, Perşembe gecesi")
    }

    func testOnlyAChildsOwnStoryCarriesADedication() {
        XCTAssertTrue(StoryColophon.hasDedication(story(ela, minutesAgo: 1)))
        XCTAssertFalse(StoryColophon.hasDedication(story(nil, name: "", minutesAgo: 1)))

        // Başlangıç kitapları (örnek masallar) bir çocuk için yazılmadı.
        var sample = story(ela, minutesAgo: 1, pages: 7)
        sample.pages[0].title = "Sihirli Başlangıç"
        XCTAssertFalse(StoryColophon.hasDedication(sample))
    }

    // MARK: - Künye

    func testTheColophonReadsLikeABooksLastPage() {
        XCTAssertEqual(StoryColophon.colophon(childName: "İrem", ordinal: 12),
                       "MagicPaper Kitaplığı · İrem'in 12. masalı")
        XCTAssertEqual(StoryColophon.colophon(childName: "Ela", ordinal: 1),
                       "MagicPaper Kitaplığı · Ela'nın ilk masalı")
    }
}
