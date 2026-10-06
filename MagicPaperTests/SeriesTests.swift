import XCTest
import StoryEngine
@testable import MagicPaper

/// A device clock a test can move, with the time zone it shows.
final class TestClock {
    var now: Date
    var zone: TimeZone
    init(_ text: String, zone: String = "Europe/Istanbul") {
        self.zone = TimeZone(identifier: zone)!
        self.now = Self.date(text, zone: self.zone)
    }
    /// `"2026-10-06 10:00"` in `zone`.
    static func date(_ text: String, zone: TimeZone) -> Date {
        let format = DateFormatter()
        format.locale = Locale(identifier: "en_US_POSIX")
        format.timeZone = zone
        format.dateFormat = "yyyy-MM-dd HH:mm"
        return format.date(from: text)!
    }
    func set(_ text: String) { now = Self.date(text, zone: zone) }
}

/// The day rule (FAZ 13, karar: 6 Ekim 2026), on its own.
final class SeriesClockTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suite = ""

    override func setUp() {
        super.setUp()
        suite = "SeriesClockTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    private func clock(_ test: TestClock) -> SeriesClock {
        SeriesClock(wallClock: { test.now }, timeZone: { test.zone }, defaults: defaults)
    }

    func testTheSameDayDoesNotCount() {
        let test = TestClock("2026-10-06 09:00")
        let mark = clock(test).mark()
        test.set("2026-10-06 23:59")
        XCTAssertFalse(clock(test).dayHasPassed(since: mark))
    }

    func testTheNextDayCounts() {
        let test = TestClock("2026-10-06 09:00")
        let mark = clock(test).mark()
        test.set("2026-10-07 08:00")
        XCTAssertTrue(clock(test).dayHasPassed(since: mark))
    }

    func testTenMinutesAcrossMidnightIsTheNextDay() {
        let test = TestClock("2026-10-06 23:50")
        let mark = clock(test).mark()
        test.set("2026-10-07 00:00")
        XCTAssertTrue(clock(test).dayHasPassed(since: mark))
    }

    func testTurningTheClockBackDatesNothingEarlier() {
        let test = TestClock("2026-10-06 10:00")
        _ = clock(test).now()
        // Clock set back two days, then the story is read.
        test.set("2026-10-04 10:00")
        let mark = clock(test).mark()
        XCTAssertEqual(mark.day, "2026-10-06", "the reading is not dated before a moment already seen")
        // Put back: still the same day, so nothing opens.
        test.set("2026-10-06 18:00")
        XCTAssertFalse(clock(test).dayHasPassed(since: mark))
    }

    func testTurningTheClockBackAfterReadingDoesNotOpen() {
        let test = TestClock("2026-10-06 10:00")
        let mark = clock(test).mark()
        test.set("2026-10-05 10:00")
        XCTAssertFalse(clock(test).dayHasPassed(since: mark))
    }

    /// Accepted gap (karar 5): the clock moved forward opens early.
    func testTurningTheClockForwardIsTheAcceptedGap() {
        let test = TestClock("2026-10-06 10:00")
        let mark = clock(test).mark()
        test.set("2026-10-07 10:00")
        XCTAssertTrue(clock(test).dayHasPassed(since: mark))
    }

    func testTheDayIsCountedWhereTheStoryWasRead() {
        // Read at 22:00 in Istanbul; the device moves to Tokyo, where it is
        // already 04:00 the next day.
        let test = TestClock("2026-10-06 22:00")
        let mark = clock(test).mark()
        test.now = test.now.addingTimeInterval(10 * 60)
        test.zone = TimeZone(identifier: "Asia/Tokyo")!
        XCTAssertFalse(clock(test).dayHasPassed(since: mark), "still 6 October in Istanbul")
        test.now = TestClock.date("2026-10-07 00:30", zone: TimeZone(identifier: "Europe/Istanbul")!)
        XCTAssertTrue(clock(test).dayHasPassed(since: mark))
    }

    func testTheDayIsGregorianWhateverTheCalendar() {
        let zone = TimeZone(identifier: "Europe/Istanbul")!
        XCTAssertEqual(SeriesClock.day(of: TestClock.date("2026-01-02 03:04", zone: zone), in: zone), "2026-01-02")
    }
}

/// The series in the app (FAZ 13): who may continue, one episode a day, the
/// end, and what deleting takes with it.
///
/// Each test has its own series and Masal ailem folders and its own clock.
/// The library is the real one; what a test adds to it, it removes.
@MainActor
final class SeriesManagerTests: XCTestCase {

    private var seriesFolder = ""
    private var familyFolder = ""
    private var suite = ""
    private var defaults: UserDefaults!
    private var libraryBefore: Set<UUID> = []
    private var clock = TestClock("2026-10-06 10:00")

    override func setUp() {
        super.setUp()
        seriesFolder = "SeriesTest-\(UUID().uuidString)"
        familyFolder = "FamilyTest-\(UUID().uuidString)"
        suite = "SeriesManagerTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
        clock = TestClock("2026-10-06 10:00")
        libraryBefore = Set(StoryGenerationManager.shared.stories.map(\.id))
    }

    override func tearDown() {
        StorySeriesStore(subdirectory: seriesFolder).eraseAll()
        FamilyCharacterStore(subdirectory: familyFolder).eraseAll()
        defaults.removePersistentDomain(forName: suite)
        let added = Set(StoryGenerationManager.shared.stories.map(\.id)).subtracting(libraryBefore)
        StoryGenerationManager.shared.deleteStories(ids: added)
        super.tearDown()
    }

    private var store: StorySeriesStore { StorySeriesStore(subdirectory: seriesFolder) }
    private var family: FamilyCharacterStore { FamilyCharacterStore(subdirectory: familyFolder) }

    private func manager() -> SeriesManager {
        let test = clock
        return SeriesManager(
            store: store,
            clock: SeriesClock(wallClock: { test.now }, timeZone: { test.zone }, defaults: defaults),
            familyStore: family)
    }

    /// A finished first story, as `createStory` saves it.
    private func firstStory(
        child: UUID = UUID(), age: Int = 3, mode: StoryMode = .bedtime,
        strategy: StorySelectionStrategy = .direct, seed: String = "s1",
        character: FamilyCharacter? = nil
    ) throws -> MagicPaper.Story {
        let service = OfflineStoryService.shared
        let composed = try service.compose(
            childName: "Yeliz", ideaID: nil, companionID: nil, mode: mode, age: age, seed: seed,
            family: character)
        return OfflineStoryMapper.appStory(
            from: composed.story, childName: "Yeliz", childProfileID: child, storyIdeaID: nil,
            catalogVersion: composed.catalogVersion, mode: mode, selectionStrategy: strategy,
            ageBand: service.servedBand(forAge: age), familyCharacter: character)
    }

    private func libraryStory(_ id: UUID?) -> MagicPaper.Story? {
        id.flatMap { StoryGenerationManager.shared.getStory(id: $0) }
    }

    // MARK: - Who may continue

    func testADirectStoryMayBeContinued() throws {
        XCTAssertEqual(manager().eligibility(for: try firstStory()), .available)
    }

    func testASurpriseStoryMayNot() throws {
        XCTAssertEqual(manager().eligibility(for: try firstStory(strategy: .surprise)), .unavailable)
    }

    func testAStoryWithoutAnOriginMayNot() throws {
        var story = try firstStory()
        story.origin = nil
        XCTAssertEqual(manager().eligibility(for: story), .unavailable)
    }

    func testAModeNoContinuationServesMayNot() throws {
        // 5-6 learning is served; a 5-6 story whose origin claims an
        // unserved band is not.
        var story = try firstStory(age: 5, mode: .learning)
        XCTAssertEqual(manager().eligibility(for: story), .available)
        story.origin?.ageBand = "9-10"
        XCTAssertEqual(manager().eligibility(for: story), .unavailable)
    }

    func testOneOpenSeriesPerChild() throws {
        let child = UUID()
        let first = try firstStory(child: child, seed: "a")
        let second = try firstStory(child: child, seed: "b")
        let manager = manager()
        try manager.startSeries(from: first)
        XCTAssertEqual(manager.eligibility(for: second), .blockedByOpenSeries)
        XCTAssertEqual(manager.eligibility(for: first), .unavailable, "a story continues once")
        XCTAssertEqual(manager.eligibility(for: try firstStory(child: UUID(), seed: "c")), .available,
                       "another child is not blocked")
        XCTAssertThrowsError(try manager.startSeries(from: second))
    }

    // MARK: - One a day

    func testEpisodesOpenOneADayAndWaitWhenUnread() throws {
        let story = try firstStory()
        let child = try XCTUnwrap(story.childProfileID)
        let manager = manager()
        let series = try manager.startSeries(from: story)
        XCTAssertEqual(series.episodes.map(\.number), [2, 3, 4, 5])
        XCTAssertTrue(series.episodes.allSatisfy { $0.storyID == nil })

        // The same day: nothing.
        clock.set("2026-10-06 21:00")
        manager.refreshUnlocks(for: child)
        XCTAssertEqual(store.openSeries(for: child)?.episodes.filter(\.isUnlocked).count, 0)

        // The next day: episode 2 is on the shelf, an episode of this series.
        clock.set("2026-10-07 08:00")
        manager.refreshUnlocks(for: child)
        var current = try XCTUnwrap(store.openSeries(for: child))
        XCTAssertEqual(current.episodes.filter(\.isUnlocked).map(\.number), [2])
        let two = try XCTUnwrap(libraryStory(current.episodes[0].storyID))
        XCTAssertEqual(two.origin?.seriesEpisode, 2)
        XCTAssertEqual(two.origin?.seriesID, current.id.uuidString)
        XCTAssertEqual(manager.eligibility(for: two), .unavailable, "an episode does not start a series")

        // Unread for two days: episode 3 waits; nothing piles up.
        clock.set("2026-10-09 08:00")
        manager.refreshUnlocks(for: child)
        current = try XCTUnwrap(store.openSeries(for: child))
        XCTAssertEqual(current.episodes.filter(\.isUnlocked).map(\.number), [2])

        // Read today; tomorrow episode 3.
        XCTAssertEqual(manager.markRead(two), .episodeRead)
        manager.refreshUnlocks(for: child)
        XCTAssertEqual(store.openSeries(for: child)?.episodes.filter(\.isUnlocked).map(\.number), [2])
        clock.set("2026-10-10 07:00")
        manager.refreshUnlocks(for: child)
        XCTAssertEqual(store.openSeries(for: child)?.episodes.filter(\.isUnlocked).map(\.number), [2, 3])
    }

    func testTenMinutesBeforeMidnightOpensAtMidnight() throws {
        clock.set("2026-10-06 23:50")
        let story = try firstStory()
        let manager = manager()
        try manager.startSeries(from: story)
        clock.set("2026-10-07 00:00")
        manager.refreshUnlocks(for: story.childProfileID!)
        XCTAssertEqual(store.openSeries(for: story.childProfileID!)?.episodes.filter(\.isUnlocked).count, 1)
    }

    func testTurningTheClockBackOpensNothing() throws {
        let story = try firstStory()
        let manager = manager()
        try manager.startSeries(from: story)
        clock.set("2026-10-01 10:00")
        manager.refreshUnlocks(for: story.childProfileID!)
        clock.set("2026-10-06 23:00")
        manager.refreshUnlocks(for: story.childProfileID!)
        XCTAssertEqual(store.openSeries(for: story.childProfileID!)?.episodes.filter(\.isUnlocked).count, 0)
    }

    func testChangingTimeZoneDoesNotOpenEarly() throws {
        clock.set("2026-10-06 22:00")
        let story = try firstStory()
        let manager = manager()
        try manager.startSeries(from: story)
        clock.now = clock.now.addingTimeInterval(30 * 60)
        clock.zone = TimeZone(identifier: "Asia/Tokyo")!
        manager.refreshUnlocks(for: story.childProfileID!)
        XCTAssertEqual(store.openSeries(for: story.childProfileID!)?.episodes.filter(\.isUnlocked).count, 0)
    }

    // MARK: - The end

    func testTheFifthEpisodeCompletesTheSeries() throws {
        let story = try firstStory()
        let child = story.childProfileID!
        let manager = manager()
        try manager.startSeries(from: story)
        var outcomes: [SeriesManager.ReadOutcome] = []
        for day in 7...10 {
            clock.set("2026-10-\(String(format: "%02d", day)) 09:00")
            manager.refreshUnlocks(for: child)
            let series = try XCTUnwrap(manager.allSeries(for: child).first)
            let opened = try XCTUnwrap(series.episodes.last(where: \.isUnlocked))
            outcomes.append(manager.markRead(try XCTUnwrap(libraryStory(opened.storyID))))
        }
        XCTAssertEqual(outcomes, [.episodeRead, .episodeRead, .episodeRead, .seriesCompleted])
        let finished = try XCTUnwrap(manager.allSeries(for: child).first)
        XCTAssertEqual(finished.status, .completed)
        XCTAssertNil(store.openSeries(for: child))
        clock.set("2026-10-20 09:00")
        manager.refreshUnlocks(for: child)
        XCTAssertEqual(manager.allSeries(for: child).first?.episodes.filter(\.isUnlocked).count, 4)
        XCTAssertEqual(manager.eligibility(for: try firstStory(child: child, seed: "next")), .available,
                       "a finished series frees the child for another")
    }

    func testAnUnreadEpisodeDeletedFromTheLibraryComesBack() throws {
        let story = try firstStory()
        let child = story.childProfileID!
        let manager = manager()
        try manager.startSeries(from: story)
        clock.set("2026-10-07 09:00")
        manager.refreshUnlocks(for: child)
        let id = try XCTUnwrap(store.openSeries(for: child)?.episodes.first?.storyID)
        StoryGenerationManager.shared.deleteStory(id: id)
        manager.refreshUnlocks(for: child)
        XCTAssertNotNil(libraryStory(id))
    }

    // MARK: - What the screens show

    func testTheLastPageShowsWhatTheStoryAllows() throws {
        let child = UUID()
        let story = try firstStory(child: child, seed: "a")
        let other = try firstStory(child: child, seed: "b")
        let manager = manager()
        XCTAssertEqual(manager.endingState(for: story), .offer)
        XCTAssertEqual(manager.endingState(for: try firstStory(strategy: .surprise)), .none,
                       "no button on a surprise story")
        try manager.startSeries(from: story)
        XCTAssertEqual(manager.endingState(for: story), .started)
        XCTAssertEqual(manager.endingState(for: other), .blocked)

        clock.set("2026-10-07 09:00")
        manager.refreshUnlocks(for: child)
        let two = try XCTUnwrap(libraryStory(store.openSeries(for: child)?.episodes.first?.storyID))
        XCTAssertEqual(manager.endingState(for: two), .episode(2))
    }

    func testTheCardSaysReadyThenWaiting() throws {
        let story = try firstStory()
        let child = story.childProfileID!
        let manager = manager()
        XCTAssertNil(manager.cardState(for: child))
        let series = try manager.startSeries(from: story)
        XCTAssertEqual(manager.cardState(for: child), .waiting(episode: 2, title: series.firstStoryTitle))
        clock.set("2026-10-07 09:00")
        manager.refreshUnlocks(for: child)
        guard case .ready(let id, 2, _) = manager.cardState(for: child) else {
            return XCTFail("episode 2 should be ready")
        }
        manager.markRead(try XCTUnwrap(libraryStory(id)))
        XCTAssertEqual(manager.cardState(for: child), .waiting(episode: 3, title: series.firstStoryTitle))
    }

    func testTheCalmLineFollowsTheName() {
        XCTAssertTrue(SeriesCopy.blocked(child: "Yeliz").hasPrefix("Yeliz'in bir serisi"))
        XCTAssertTrue(SeriesCopy.blocked(child: "Can").hasPrefix("Can'ın bir serisi"))
        XCTAssertTrue(SeriesCopy.blocked(child: "Nuri").hasPrefix("Nuri'nin bir serisi"))
    }

    // MARK: - Masal ailem

    func testDeletingTheCharacterRewritesOnlyUnopenedEpisodes() throws {
        let child = UUID()
        let ela = FamilyCharacter(childID: child, name: "Ela", relation: .sibling)
        try family.save(ela)
        let story = try firstStory(child: child, age: 5, mode: .learning, character: ela)
        let manager = manager()
        let started = try manager.startSeries(from: story)
        XCTAssertNotNil(started.plan.family)
        XCTAssertTrue(started.episodes.allSatisfy { $0.pages.contains { $0.text.contains("Ela") } })

        clock.set("2026-10-07 09:00")
        manager.refreshUnlocks(for: child)
        try family.delete(id: ela.id, childID: child)
        manager.familyCharacterRemoved(id: ela.id, childID: child)

        let after = try XCTUnwrap(store.openSeries(for: child))
        XCTAssertNil(after.plan.family)
        XCTAssertEqual(after.episodes[0].pages, started.episodes[0].pages, "an opened episode stays as written")
        for episode in after.episodes.dropFirst() {
            XCTAssertFalse(episode.pages.contains { $0.text.contains("Ela") })
            XCTAssertNil(episode.origin.familyCharacterID)
        }
        XCTAssertEqual(after.status, .open)
    }

    // MARK: - Deletion and older data

    func testDeletingAProfileDeletesItsSeries() throws {
        let manager = ProfileManager.shared
        let savedProfiles = manager.profiles
        let savedCurrent = manager.currentProfile
        let savedData = UserDefaults.standard.data(forKey: "user_profiles")
        let savedCurrentID = UserDefaults.standard.string(forKey: "current_profile_id")
        let realStore = StorySeriesStore()
        let leaving = UserProfile(name: "Test Gider", age: 3, profileType: .child)
        let staying = UserProfile(name: "Test Kalır", age: 3, profileType: .child)
        defer {
            realStore.delete(for: leaving.id)
            realStore.delete(for: staying.id)
            manager.profiles = savedProfiles
            manager.currentProfile = savedCurrent
            UserDefaults.standard.set(savedData, forKey: "user_profiles")
            UserDefaults.standard.set(savedCurrentID, forKey: "current_profile_id")
        }
        manager.profiles = savedProfiles + [leaving, staying]
        let test = clock
        let series = SeriesManager(
            store: realStore,
            clock: SeriesClock(wallClock: { test.now }, timeZone: { test.zone }, defaults: defaults),
            familyStore: family)
        try series.startSeries(from: try firstStory(child: leaving.id, seed: "x"))
        try series.startSeries(from: try firstStory(child: staying.id, seed: "y"))

        if case .failure = manager.deleteProfile(leaving) { return XCTFail("deleteProfile refused") }
        XCTAssertEqual(realStore.series(for: leaving.id), [])
        XCTAssertEqual(realStore.series(for: staying.id).count, 1)
    }

    func testAStoryWrittenBeforeFaz13StillOpens() throws {
        let json = """
        {"seed":"s","blueprintID":"b","settingID":"st","companionID":"c","discoveryID":"d",
         "fingerprint":"f","catalogVersion":"2.0.0","modeID":"growth","selectionStrategy":"direct",
         "ageBand":"5-6","familyCharacterID":null}
        """
        let origin = try JSONDecoder().decode(StoryOrigin.self, from: Data(json.utf8))
        XCTAssertNil(origin.seriesID)
        XCTAssertNil(origin.seriesEpisode)
        XCTAssertEqual(origin.mode, .learning)
    }

    func testASeriesNeverDescribesTheChildOrTheText() throws {
        let series = try manager().startSeries(from: try firstStory())
        for text in [series.description, series.debugDescription, String(describing: series),
                     String(reflecting: series), "\(Mirror(reflecting: series).children.map { "\($0.value)" })"] {
            XCTAssertFalse(text.contains("Yeliz"), text)
            XCTAssertFalse(text.contains(series.firstStoryTitle), text)
        }
    }

    func testASeriesSurvivesAReload() throws {
        let story = try firstStory()
        let started = try manager().startSeries(from: story)
        XCTAssertEqual(store.series(for: story.childProfileID!), [started])
    }
}
