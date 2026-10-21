import XCTest
import StoryEngine
@testable import MagicPaper

/// Masal başlıkları (21 Ekim 2026): çocuğun kitaplığındaki başlıklar motora
/// gider, motor aynı başlığı başka bir kalıp temizse yeniden yazmaz.
@MainActor
final class StoryTitleLibraryTests: XCTestCase {

    private let service = OfflineStoryService.shared

    private func story(_ title: String, for profile: UserProfile, daysAgo: Double) -> MagicPaper.Story {
        var story = MagicPaper.Story(
            title: title, childName: profile.name, childProfileID: profile.id,
            theme: .fantasy, language: .turkish, status: .completed)
        story.createdAt = Date(timeIntervalSinceNow: -daysAgo * 86_400)
        return story
    }

    func testOnlyThisChildsNewestTitlesAreAvoided() {
        let yeliz = UserProfile(name: "Yeliz", age: 6, profileType: .child)
        let arda = UserProfile(name: "Arda", age: 6, profileType: .child)
        let library = [
            story("Tarçın'ın Uykulu Gecesi", for: yeliz, daysAgo: 1),
            story("Titrek Işık Nereden Geliyor?", for: yeliz, daysAgo: 2),
            story("Bulut Dağı'nda Yırtık Harita", for: arda, daysAgo: 1)
        ]
        XCTAssertEqual(
            StoryGenerationManager.recentTitles(of: library, for: yeliz),
            ["Tarçın'ın Uykulu Gecesi", "Titrek Işık Nereden Geliyor?"])
        XCTAssertEqual(
            StoryGenerationManager.recentTitles(of: library, for: yeliz, limit: 1),
            ["Tarçın'ın Uykulu Gecesi"], "Newest first.")
        XCTAssertEqual(StoryGenerationManager.recentTitles(of: library, for: arda),
                       ["Bulut Dağı'nda Yırtık Harita"])
    }

    func testTheServicePassesTheLibraryToTheTitle() throws {
        let first = try service.compose(
            childName: "Yeliz", ideaID: nil, companionID: nil, mode: .bedtime, age: 6, seed: "baslik-1")
        let again = try service.compose(
            childName: "Yeliz", ideaID: nil, companionID: nil, mode: .bedtime, age: 6, seed: "baslik-1",
            recentTitles: [first.story.title])
        XCTAssertNotEqual(again.story.title, first.story.title)
        XCTAssertEqual(again.story.pages.map(\.text), first.story.pages.map(\.text),
                       "Only the title moves; the book is the same book.")
    }

    func testWithoutALibraryTheTitleIsUnchanged() throws {
        let plain = try service.compose(
            childName: "Yeliz", ideaID: nil, companionID: nil, mode: .learning, age: 6, seed: "baslik-2")
        let empty = try service.compose(
            childName: "Yeliz", ideaID: nil, companionID: nil, mode: .learning, age: 6, seed: "baslik-2",
            recentTitles: [])
        XCTAssertEqual(plain.story.title, empty.story.title)
    }
}
