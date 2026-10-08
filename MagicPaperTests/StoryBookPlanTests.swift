import XCTest
@testable import MagicPaper

/// 35 · Masal kitabı: hangi masalların kitaba girdiği, sırası ve sayfa sayısı.
@MainActor
final class StoryBookPlanTests: XCTestCase {

    private func story(_ title: String, for profile: UserProfile, pages: Int = 2,
                       read: Int? = nil, ageDays: Double = 0) -> MagicPaper.Story {
        var s = MagicPaper.Story(title: title, childName: profile.name, childProfileID: profile.id, theme: .fantasy,
                                 language: .turkish, status: .completed,
                                 pages: (0..<pages).map { _ in MagicPaper.StoryPage(title: "", text: "a", imagePrompt: "") })
        s.lastReadPage = read
        s.createdAt = Date(timeIntervalSinceNow: -ageDays * 86_400)
        return s
    }

    func testOnlyThisChildsStoriesOldestFirst() {
        let ada = UserProfile(name: "Ada", age: 6)
        let can = UserProfile(name: "Can", age: 8)
        let newer = story("Yeni", for: ada, ageDays: 1)
        let older = story("Eski", for: ada, ageDays: 5)
        let other = story("Başka", for: can)
        XCTAssertEqual(StoryBookPlan.candidates([newer, other, older], for: ada).map(\.title), ["Eski", "Yeni"])
    }

    func testDefaultSelectionIsFinishedStoriesOrAllWhenNoneFinished() {
        let ada = UserProfile(name: "Ada", age: 6)
        let done = story("Bitti", for: ada, pages: 2, read: 1)
        let half = story("Yarım", for: ada, pages: 3, read: 0)
        XCTAssertEqual(StoryBookPlan.defaultSelection([done, half]), [done.id])
        XCTAssertEqual(StoryBookPlan.defaultSelection([half]), [half.id])
    }

    func testPageCountIsOneCoverPerStoryPlusItsPages() {
        let ada = UserProfile(name: "Ada", age: 6)
        let stories = [story("A", for: ada, pages: 8), story("B", for: ada, pages: 6)]
        XCTAssertEqual(StoryBookPlan.pageCount(stories), 16)
    }

    func testOrderedKeepsBookOrderNotTapOrder() {
        let ada = UserProfile(name: "Ada", age: 6)
        let a = story("A", for: ada, ageDays: 3), b = story("B", for: ada, ageDays: 2), c = story("C", for: ada, ageDays: 1)
        XCTAssertEqual(StoryBookPlan.ordered([a, b, c], selected: [c.id, a.id]).map(\.title), ["A", "C"])
    }

    func testFileNameIsSafeAndCarriesOnlyTheName() {
        XCTAssertEqual(StoryBookPlan.fileName(childName: "Çağrı Işık"), "cagriisik-masal-kitabi.pdf")
        XCTAssertEqual(StoryBookPlan.fileName(childName: "!!"), "masal-kitabi.pdf")
    }
}
