import XCTest
import StoryEngine
@testable import MagicPaper

/// Faz 10: masal dünyası hatırlar. E3'ten beri cümleyi motor yazıyor; burada
/// uygulamanın payı kalıyor: geçmişi kimlik ve sayı olarak kuran
/// `StoryContextBuilder.recallHistory` ve harita. Seri bölümleri, bitmemiş ve
/// kökensiz masallar hatırlanmaz; son iki masaldan birinde hatırlama varsa
/// bu masalda yok.
final class StoryMemoryTests: XCTestCase {

    private let garden = StoryMemory.Place(name: "Gece Bahçesi", isProperNoun: true,
                                           hasPossessiveEnding: true, blocksSoftening: false)
    private let forest = StoryMemory.Place(name: "Fısıldayan Orman", isProperNoun: true,
                                           hasPossessiveEnding: false, blocksSoftening: false)

    private func finished(setting: String, companion: String, episode: Int? = nil,
                          readAt: Date = Date(), createdDaysAgo: Double = 10,
                          recalled: Bool? = nil) -> MagicPaper.Story {
        var story = ReaderFixtures.textStory(pages: 3)
        story.lastReadPage = 2
        story.lastReadAt = readAt
        story.createdAt = Date(timeIntervalSinceNow: -createdDaysAgo * 86_400)
        story.origin = StoryOrigin(seed: "s", storyIdeaID: nil, blueprintID: "b", settingID: setting,
                                   companionID: companion, discoveryID: "d", fingerprint: "f",
                                   catalogVersion: "1", seriesEpisode: episode)
        story.origin?.recalled = recalled
        return story
    }

    @MainActor
    private func history(_ stories: [MagicPaper.Story]) -> RecallHistory? {
        StoryContextBuilder.recallHistory(of: stories)
    }

    @MainActor
    func testNothingToRememberOnFirstStory() {
        XCTAssertNil(history([]))
    }

    /// Kademe yol arkadaşıyla biten masal sayısından: 1 tanıştı, 2-3 dost,
    /// 4 ve üstü eski dost. Kademeyi motor seçer; burada sayı doğru gitmeli.
    @MainActor
    func testTheCompanionIsCountedForTheTier() throws {
        let one = try XCTUnwrap(history([finished(setting: "garden", companion: "fox")]))
        XCTAssertEqual(one.companions[ContentID("fox")]?.storyCount, 1)
        XCTAssertEqual(RecallTier.forCompanion(storyCount: 1), .metOnce)

        let three = try XCTUnwrap(history((0..<3).map { _ in finished(setting: "garden", companion: "fox") }))
        XCTAssertEqual(three.companions[ContentID("fox")]?.storyCount, 3)
        XCTAssertEqual(RecallTier.forCompanion(storyCount: 3), .friends)

        let five = try XCTUnwrap(history((0..<5).map { _ in finished(setting: "garden", companion: "fox") }))
        XCTAssertEqual(RecallTier.forCompanion(storyCount: five.companions[ContentID("fox")]!.storyCount), .oldFriends)
    }

    @MainActor
    func testFirstMeetingWinsOverLaterOnes() throws {
        let previous = [finished(setting: "forest", companion: "fox", readAt: Date()),
                        finished(setting: "garden", companion: "fox", readAt: Date(timeIntervalSinceNow: -86_400))]
        let recall = try XCTUnwrap(history(previous))
        XCTAssertEqual(recall.companions[ContentID("fox")]?.firstSettingID, ContentID("garden"))
        XCTAssertEqual(recall.visitedSettings, [ContentID("garden"), ContentID("forest")])
    }

    @MainActor
    func testSeriesEpisodesUnfinishedAndOriginlessStoriesAreNotMemories() {
        var unfinished = finished(setting: "garden", companion: "fox")
        unfinished.lastReadPage = 0
        let episode = finished(setting: "garden", companion: "fox", episode: 2)
        var originless = finished(setting: "garden", companion: "fox")
        originless.origin = nil
        XCTAssertNil(history([unfinished, episode, originless]))
    }

    /// En çok üç masalda bir: en yeni iki masaldan biri hatırladıysa bu yok.
    @MainActor
    func testARecallInOneOfTheTwoNewestStoriesKeepsThisOneWithout() {
        let older = finished(setting: "garden", companion: "fox", createdDaysAgo: 5)
        let recalledSecond = finished(setting: "forest", companion: "owl", createdDaysAgo: 2, recalled: true)
        let newest = finished(setting: "forest", companion: "owl", createdDaysAgo: 1)
        XCTAssertNil(history([older, recalledSecond, newest]))

        let recalledThird = finished(setting: "forest", companion: "owl", createdDaysAgo: 3, recalled: true)
        let second = finished(setting: "forest", companion: "owl", createdDaysAgo: 2)
        XCTAssertNotNil(history([older, recalledThird, second, newest]),
                        "Üçüncü masaldaki hatırlama bu masalı engellemez.")
    }

    func testMapListsVisitedFirstAndKeepsUnvisitedUncounted() {
        let stories = [finished(setting: "forest", companion: "fox"),
                       finished(setting: "forest", companion: "owl"),
                       finished(setting: "forest", companion: "fox")]
        let places = StoryMapModel.places(
            stories: stories,
            catalog: [("garden", garden, []), ("forest", forest, [])],
            companionName: { $0 == "fox" ? "Tarçın" : "Pırıl" })
        XCTAssertEqual(places.map(\.id), ["forest", "garden"])
        XCTAssertEqual(places[0].storyCount, 3)
        XCTAssertEqual(places[0].friends, ["Tarçın", "Pırıl"])
        XCTAssertFalse(places[1].visited)
    }
}
