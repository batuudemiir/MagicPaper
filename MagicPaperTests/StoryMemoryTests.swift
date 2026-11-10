import XCTest
@testable import MagicPaper

/// Faz 10: masal dünyası hatırlar. Cümle deterministik, seri bölümleri ve
/// bitmemiş masallar hatırlanmaz; harita gidilmemiş yerleri saymaz.
final class StoryMemoryTests: XCTestCase {

    private let garden = StoryMemory.Place(name: "Gece Bahçesi", isProperNoun: true,
                                           hasPossessiveEnding: true, blocksSoftening: false)
    private let forest = StoryMemory.Place(name: "Fısıldayan Orman", isProperNoun: true,
                                           hasPossessiveEnding: false, blocksSoftening: false)

    private func finished(setting: String, companion: String, episode: Int? = nil,
                          readAt: Date = Date()) -> Story {
        var story = ReaderFixtures.textStory(pages: 3)
        story.lastReadPage = 2
        story.lastReadAt = readAt
        story.origin = StoryOrigin(seed: "s", storyIdeaID: nil, blueprintID: "b", settingID: setting,
                                   companionID: companion, discoveryID: "d", fingerprint: "f",
                                   catalogVersion: "1", seriesEpisode: episode)
        return story
    }

    private func line(setting: String, place: StoryMemory.Place, companion: String,
                      previous: [Story]) -> String? {
        StoryMemory.recallLine(childName: "Yeliz", settingID: setting, place: place,
                               companionID: companion, companionName: "Tarçın", previous: previous,
                               placeNamed: { [garden, forest] in $0 == "garden" ? garden : $0 == "forest" ? forest : nil })
    }

    func testNothingToRememberOnFirstStory() {
        XCTAssertNil(line(setting: "garden", place: garden, companion: "fox", previous: []))
    }

    func testOldFriendNamesWhereTheyMet() {
        let previous = [finished(setting: "garden", companion: "fox")]
        let text = line(setting: "forest", place: forest, companion: "fox", previous: previous)
        XCTAssertEqual(text, "Tarçın ile Yeliz eski dostlardı. İlk kez Gece Bahçesi'nde tanışmışlardı.")
    }

    func testFirstMeetingWinsOverLaterOnes() {
        let previous = [finished(setting: "forest", companion: "fox", readAt: Date()),
                        finished(setting: "garden", companion: "fox", readAt: Date(timeIntervalSinceNow: -86_400))]
        let text = line(setting: "other", place: forest, companion: "fox", previous: previous)
        XCTAssertTrue(text?.contains("Gece Bahçesi'nde") == true, text ?? "nil")
    }

    func testReturningToAPlace() {
        let previous = [finished(setting: "garden", companion: "owl")]
        let text = line(setting: "garden", place: garden, companion: "fox", previous: previous)
        XCTAssertEqual(text, "Yeliz Gece Bahçesi'ne daha önce de gelmişti. Burayı hemen hatırladı.")
    }

    func testSeriesEpisodesAndUnfinishedStoriesAreNotMemories() {
        var unfinished = finished(setting: "garden", companion: "fox")
        unfinished.lastReadPage = 0
        let episode = finished(setting: "garden", companion: "fox", episode: 2)
        XCTAssertNil(line(setting: "garden", place: garden, companion: "fox", previous: [unfinished, episode]))
    }

    func testRememberAppendsToFirstPageAndMarksOrigin() {
        let story = finished(setting: "garden", companion: "fox")
        let remembered = StoryMemory.remember("Bir anı.", in: story)
        XCTAssertTrue(remembered.pages[0].text.hasSuffix("\n\nBir anı."))
        XCTAssertEqual(remembered.origin?.recalled, true)
        XCTAssertEqual(StoryMemory.remember(nil, in: story), story)
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
