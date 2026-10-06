import XCTest
@testable import MagicPaper

/// Günün masalı (FAZ 15): chosen from the feed, deterministically.
final class TodaysStoryPickerTests: XCTestCase {

    private let a = TestPublisher.story("A", day: "2026-10-01", id: UUID(uuidString: "00000000-0000-0000-0000-00000000000A")!)
    private let b = TestPublisher.story("B", day: "2026-10-03", id: UUID(uuidString: "00000000-0000-0000-0000-00000000000B")!)
    private let future = TestPublisher.story("Yarın", day: "2026-10-07")

    private func pick(_ stories: [FeedStory], today: String = "2026-10-06", age: Int? = 5,
                      read: Set<UUID> = [], pinned: UUID? = nil) -> String? {
        TodaysStoryPicker.pick(from: stories, today: today, age: age, read: read, pinned: pinned)?.title
    }

    func testTheNewestPublishedStoryWins() {
        XCTAssertEqual(pick([a, b]), "B")
        XCTAssertEqual(pick([b, a]), "B", "Order in the feed does not matter")
    }

    func testAStoryIsNotShownBeforeItsDay() {
        XCTAssertEqual(pick([a, future]), "A")
        XCTAssertEqual(pick([a, future], today: "2026-10-07"), "Yarın")
        XCTAssertEqual(TodaysStoryPicker.published([a, future], today: "2026-10-06").map(\.title), ["A"])
    }

    func testUnreadComesFirst() {
        XCTAssertEqual(pick([a, b], read: [b.id]), "A")
    }

    func testTheStoryChosenTodayStaysAfterItIsRead() {
        XCTAssertEqual(pick([a, b], read: [b.id], pinned: b.id), "B")
    }

    func testWhenEverythingIsReadTheNewestIsShown() {
        XCTAssertEqual(pick([a, b], read: [a.id, b.id]), "B")
    }

    func testTheChildsAgeNarrowsTheChoice() {
        let older = TestPublisher.story("Büyükler", day: "2026-10-05", age: "8-10")
        XCTAssertEqual(pick([a, older], age: 4), "A")
        XCTAssertEqual(pick([a, older], age: 9), "Büyükler")
    }

    func testWithNothingForTheAgeTheWholePoolServes() {
        let older = TestPublisher.story("Büyükler", day: "2026-10-05", age: "8-10")
        XCTAssertEqual(pick([older], age: 3), "Büyükler")
    }

    func testTheSameDayIsTheSameStory() {
        let stories = (1...9).map { TestPublisher.story("M\($0)", day: "2026-10-0\($0)") }
        let first = pick(stories, today: "2026-10-05")
        for _ in 0..<20 { XCTAssertEqual(pick(stories.shuffled(), today: "2026-10-05"), first) }
    }

    func testTheDayIsTheLocalCalendarDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        let lateEvening = TestClock.date("2026-10-06 23:30", zone: calendar.timeZone)
        XCTAssertEqual(TodaysStoryPicker.day(lateEvening, calendar: calendar), "2026-10-06")
    }
}

@MainActor
final class DailyStoryManagerTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suite = ""
    private var clock: TestClock!
    private var calendar = Calendar(identifier: .gregorian)

    override func setUp() async throws {
        suite = "DailyStoryManagerTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
        clock = TestClock("2026-10-06 09:00")
        calendar.timeZone = clock.zone
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suite)
    }

    private func manager(feed: ContentFeed? = nil, age: Int? = 5,
                         fallback: [FeedStory] = DailyStoryManager.bundledFallback()) -> DailyStoryManager {
        let clock = clock!
        return DailyStoryManager(defaults: defaults, now: { clock.now }, calendar: calendar,
                                 currentAge: { age }, feed: feed, fallback: fallback)
    }

    private func feed(_ version: Int, _ stories: [FeedStory]) -> ContentFeed {
        ContentFeed(feedVersion: version, publishedAt: "2026-10-06", stories: stories, catalogPackage: nil)
    }

    func testTheAppShipsTwelveStoriesWithStableIDs() {
        let stories = DailyStoryManager.bundledFallback()
        XCTAssertEqual(stories.count, 12)
        XCTAssertEqual(Set(stories.map(\.id)).count, 12)
        XCTAssertEqual(stories.map(\.id), DailyStoryManager.bundledFallback().map(\.id))
        XCTAssertEqual(stories.filter { $0.category == .educational }.count, 2)
    }

    func testWithoutAFeedTheBundledStoriesServe() {
        let daily = manager()
        XCTAssertEqual(daily.dailyStories.count, 12)
        XCTAssertNotNil(daily.todaysStory)
    }

    /// The acceptance case: a new feed with a story for today shows it at
    /// once — no relaunch.
    func testANewFeedChangesTodaysStoryWithoutARestart() {
        let a = TestPublisher.story("A", day: "2026-10-01")
        let daily = manager(feed: feed(1, [a]))
        XCTAssertEqual(daily.todaysStory?.title, "A")

        daily.apply(feed: feed(2, [a, TestPublisher.story("B", day: "2026-10-06")]))

        XCTAssertEqual(daily.todaysStory?.title, "B")
        XCTAssertEqual(daily.dailyStories.map(\.title), ["B", "A"])
    }

    func testEducationalStoriesComeFromTheFeed() {
        let lesson = TestPublisher.story("Sayılar", category: .educational)
        let daily = manager(feed: feed(1, [TestPublisher.story("Uyku"), lesson]))
        XCTAssertEqual(daily.getStoriesByCategory(.educational).map(\.title), ["Sayılar"])
    }

    func testReadingIsRememberedAndTodaysStoryStays() {
        let a = TestPublisher.story("A", day: "2026-10-01")
        let b = TestPublisher.story("B", day: "2026-10-02")
        let daily = manager(feed: feed(1, [a, b]))
        XCTAssertEqual(daily.todaysStory?.title, "B")

        daily.markAsRead(storyId: b.id)
        XCTAssertEqual(daily.todaysStory?.title, "B")
        XCTAssertEqual(daily.todaysStory?.isRead, true)

        let relaunched = manager(feed: feed(1, [a, b]))
        XCTAssertEqual(relaunched.todaysStory?.title, "B", "Same day, same story")
        XCTAssertTrue(relaunched.dailyStories.first { $0.id == b.id }!.isRead)

        clock.set("2026-10-07 09:00")
        relaunched.refreshForToday()
        XCTAssertEqual(relaunched.todaysStory?.title, "A", "A new day brings the unread one")
    }

    func testTheOldReadFlagsCarryOverByTitle() throws {
        let fallback = DailyStoryManager.bundledFallback()
        let first = fallback[0]
        let legacy = [DailyStory(title: first.title, category: first.category, ageRange: first.ageRange,
                                 readingTime: first.readingTime, content: first.content,
                                 moralLesson: first.moralLesson, emoji: first.emoji, isRead: true,
                                 lastReadDate: clock.now)]
        defaults.set(try JSONEncoder().encode(legacy), forKey: DailyStoryManager.Key.legacyStories)
        defaults.set(clock.now, forKey: DailyStoryManager.Key.legacyRotation)

        let daily = manager()

        XCTAssertTrue(daily.dailyStories.first { $0.id == first.id }!.isRead)
        XCTAssertNil(defaults.object(forKey: DailyStoryManager.Key.legacyStories))
        XCTAssertNil(defaults.object(forKey: DailyStoryManager.Key.legacyRotation))
    }

    func testEraseForgetsWhatWasRead() {
        let a = TestPublisher.story("A")
        let daily = manager(feed: feed(1, [a]))
        daily.markAsRead(storyId: a.id)

        daily.eraseReadingState()

        XCTAssertEqual(daily.todaysStory?.isRead, false)
        XCTAssertNil(defaults.object(forKey: DailyStoryManager.Key.readDates))
    }

    func testAnEmptyFeedKeepsTheBundledStories() {
        let daily = manager(feed: feed(1, []))
        XCTAssertEqual(daily.dailyStories.count, 12)
    }
}
