import XCTest
@testable import MagicPaper

/// 35 · Masal kitabı: kitaba giren masalların seçimi (FAZ 18).
final class BookExportSelectionTests: XCTestCase {

    private func story(_ title: String, pages: Int, child: UUID, daysAgo: Double, readable: Bool = true) -> Story {
        var s = ReaderFixtures.textStory(pages: pages, title: title)
        s.childProfileID = child
        s.createdAt = Date(timeIntervalSinceNow: -daysAgo * 86_400)
        if !readable { s.status = .failed; s.pages = [] }
        return s
    }

    func testOnlyTheChildsReadableStoriesAreOfferedOldestFirstAndAllSelected() {
        let profile = UserProfile(name: "İrem", age: 8)
        let other = UUID()
        let stories = [
            story("Kule Kapısındaki Bilmece", pages: 8, child: profile.id, daysAgo: 1),
            story("Şehri Kurtaran Gün", pages: 8, child: profile.id, daysAgo: 5),
            story("Başkasının masalı", pages: 6, child: other, daysAgo: 2),
            story("Yarım kalan", pages: 0, child: profile.id, daysAgo: 3, readable: false),
        ]
        let selection = BookExportSelection(profile: profile, stories: stories)

        XCTAssertEqual(selection.candidates.map(\.title), ["Şehri Kurtaran Gün", "Kule Kapısındaki Bilmece"])
        XCTAssertEqual(selection.selected.count, 2)
        XCTAssertEqual(selection.pageCount, 16)
        XCTAssertEqual(selection.summary, "2 masal, 16 sayfa. Yazdırmaya hazır PDF.")
    }

    func testToggleRemovesAndRestoresAStoryKeepingTheOrder() {
        let child = UUID()
        var selection = BookExportSelection(childName: "Elif", stories: [
            story("Bir", pages: 8, child: child, daysAgo: 3),
            story("İki", pages: 6, child: child, daysAgo: 2),
            story("Üç", pages: 4, child: child, daysAgo: 1),
        ])
        let middle = selection.candidates[1]

        selection.toggle(middle)
        XCTAssertFalse(selection.isSelected(middle))
        XCTAssertEqual(selection.selected.map(\.title), ["Bir", "Üç"])
        XCTAssertEqual(selection.pageCount, 12)

        selection.toggle(middle)
        XCTAssertEqual(selection.selected.map(\.title), ["Bir", "İki", "Üç"])
    }

    func testNothingSelectedCannotExport() {
        let child = UUID()
        var selection = BookExportSelection(childName: "Elif", stories: [story("Bir", pages: 8, child: child, daysAgo: 1)])
        selection.toggle(selection.candidates[0])
        XCTAssertFalse(selection.canExport)
        XCTAssertEqual(selection.summary, "Kitaba girecek masalları seç.")
    }

    func testBookTitleUsesTheTurkishGenitive() {
        XCTAssertEqual(BookExportSelection(childName: "İrem", stories: []).bookTitle, "İrem'in Masal Kitabı")
        XCTAssertEqual(BookExportSelection(childName: "Duru", stories: []).bookTitle, "Duru'nun Masal Kitabı")
        XCTAssertEqual(BookExportSelection(childName: " ", stories: []).bookTitle, "Masal Kitabı")
    }

    func testFileNameIsPlainAscii() {
        XCTAssertEqual(BookExportSelection(childName: "Işıl Çağla", stories: []).fileName, "isil-cagla-masal-kitabi.pdf")
        XCTAssertEqual(BookExportSelection(childName: "", stories: []).fileName, "masal-kitabi.pdf")
    }
}
