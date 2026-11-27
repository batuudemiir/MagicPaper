import XCTest
import StoryEngine
@testable import MagicPaper

/// E6: special days. The store, the window, which chips show, what a
/// special-day story records, and that it neither continues nor recalls.
@MainActor
final class SpecialDayTests: XCTestCase {

    private var suite: String!
    private var defaults: UserDefaults!
    private var store: SpecialDayStore!
    private let istanbul = TimeZone(identifier: "Europe/Istanbul")!

    override func setUp() {
        super.setUp()
        suite = "SpecialDayTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
        store = SpecialDayStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    /// 17 Kasım 2026, 10:00 in Istanbul.
    private var today: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = istanbul
        return calendar.date(from: DateComponents(year: 2026, month: 11, day: 17, hour: 10))!
    }

    // MARK: - The store

    func testOneRecordPerKindAndDeletion() {
        let child = UUID(), other = UUID()
        store.save(SpecialDay(kind: .birthday), for: child)
        store.save(SpecialDay(kind: .birthday, day: "2026-11-20"), for: child)
        store.save(SpecialDay(kind: .firstLostTooth), for: child)
        store.save(SpecialDay(kind: .newSibling), for: other)

        XCTAssertEqual(store.days(for: child).map(\.kind), [.birthday, .firstLostTooth])
        XCTAssertEqual(store.days(for: child).first?.day, "2026-11-20", "the second save replaced the first")

        store.delete(.birthday, for: child)
        XCTAssertEqual(store.days(for: child).map(\.kind), [.firstLostTooth])

        store.deleteAll(for: child)
        XCTAssertTrue(store.days(for: child).isEmpty)
        XCTAssertEqual(store.days(for: other).map(\.kind), [.newSibling], "another child's days stay")
    }

    // MARK: - The window

    func testTheWindowIncludesFourteenDaysBeforeAndSevenAfter() {
        func active(_ day: String?) -> Bool {
            SpecialDayWindow.isActive(SpecialDay(kind: .birthday, day: day), today: today, timeZone: istanbul)
        }
        XCTAssertTrue(active(nil), "undated is always active")
        XCTAssertTrue(active("2026-11-17"))
        XCTAssertTrue(active("2026-11-24"), "+7")
        XCTAssertFalse(active("2026-11-25"), "+8")
        XCTAssertTrue(active("2026-11-03"), "-14")
        XCTAssertFalse(active("2026-11-02"), "-15")
        XCTAssertFalse(active("bozuk"))
    }

    /// A birthday comes back every year: the parent may pick the child's birth
    /// date, or last year's party. Only month and day count, in the same
    /// window around this year's, last year's or next year's birthday.
    func testABirthdayComesBackEveryYear() {
        func active(_ day: String, on date: Date? = nil) -> Bool {
            SpecialDayWindow.isActive(SpecialDay(kind: .birthday, day: day), today: date ?? today, timeZone: istanbul)
        }
        XCTAssertTrue(active("2020-11-20"), "birth date, +3 this year")
        XCTAssertTrue(active("2025-11-20"), "last year's date, +3 this year")
        XCTAssertTrue(active("2020-11-03"), "-14 this year")
        XCTAssertFalse(active("2020-11-02"), "-15 this year")
        XCTAssertFalse(active("2020-11-25"), "+8 this year")
        XCTAssertTrue(active("2019-01-03", on: day(2026, 12, 28)), "+6, across New Year")
        XCTAssertTrue(active("2018-12-25", on: day(2027, 1, 5)), "-11, across New Year")
    }

    /// A 29 February birthday is kept on 28 February in other years.
    func testALeapDayBirthdayFallsOnTheTwentyEighth() {
        func active(on date: Date) -> Bool {
            SpecialDayWindow.isActive(SpecialDay(kind: .birthday, day: "2020-02-29"), today: date, timeZone: istanbul)
        }
        XCTAssertTrue(active(on: day(2027, 2, 21)), "28 Feb is +7")
        XCTAssertTrue(active(on: day(2028, 2, 22)), "a leap year keeps 29 Feb, +7")
        XCTAssertFalse(active(on: day(2027, 2, 20)), "28 Feb is +8")
    }

    /// The other days happen once: their year counts.
    func testOtherDaysKeepTheirYear() {
        XCTAssertFalse(SpecialDayWindow.isActive(
            SpecialDay(kind: .firstSchoolDay, day: "2025-11-20"), today: today, timeZone: istanbul))
        XCTAssertFalse(SpecialDayWindow.isActive(
            SpecialDay(kind: .firstLostTooth, day: "2020-11-17"), today: today, timeZone: istanbul))
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = istanbul
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 10))!
    }

    /// The day is counted in the device's zone: just before midnight in
    /// Istanbul it is still the 17th there, already the 18th in Tokyo.
    func testTheWindowCountsDaysInTheGivenZone() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = istanbul
        let lateNight = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 17, hour: 23, minute: 30)))
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        XCTAssertEqual(SpecialDayWindow.daysFromToday(to: "2026-11-24", today: lateNight, timeZone: istanbul), 7)
        XCTAssertEqual(SpecialDayWindow.daysFromToday(to: "2026-11-24", today: lateNight, timeZone: tokyo), 6)
        XCTAssertEqual(SpecialDayWindow.dayString(lateNight, timeZone: istanbul), "2026-11-17")
    }

    // MARK: - Which chips show

    func testAChipNeedsAnActiveDayAndAWritableStory() {
        let child = UUID()
        store.save(SpecialDay(kind: .birthday), for: child)
        store.save(SpecialDay(kind: .newSibling, day: "2026-12-30"), for: child)   // far ahead
        store.save(SpecialDay(kind: .firstSchoolDay, day: "2026-11-20"), for: child)
        let active = store.activeKinds(for: child, today: today, timeZone: istanbul)
        XCTAssertEqual(active, [.birthday, .firstSchoolDay])

        let writable5Adventure = OfflineStoryService.shared.occasionChoices(forAge: 5, mode: .adventure)
        XCTAssertEqual(StoryCreationFlow.occasionChoices(active: active, writable: writable5Adventure),
                       [.birthday, .firstSchoolDay])
        let writable5Learning = OfflineStoryService.shared.occasionChoices(forAge: 5, mode: .learning)
        XCTAssertEqual(StoryCreationFlow.occasionChoices(active: active, writable: writable5Learning), [])
        let writable8Adventure = OfflineStoryService.shared.occasionChoices(forAge: 8, mode: .adventure)
        XCTAssertEqual(StoryCreationFlow.occasionChoices(active: active, writable: writable8Adventure), [],
                       "7-8 has no special days yet")
    }

    func testTheSiblingTravelsOnlyForANewSibling() {
        let sister = FamilyCharacter(childID: UUID(), name: "Ela", relation: .sibling)
        XCTAssertEqual(SpecialDayKind.newSibling.request(sibling: sister).sibling?.name, "Ela")
        XCTAssertNil(SpecialDayKind.birthday.request(sibling: sister).sibling)
        XCTAssertNil(SpecialDayKind.newSibling.request(sibling: nil).sibling)
        XCTAssertEqual(SpecialDayKind(occasionID: "occasion_first_lost_tooth"), .firstLostTooth)
    }

    // MARK: - What the story records

    private func occasionStory(_ kind: SpecialDayKind, age: Int, mode: StoryMode,
                               recall: RecallHistory? = nil) throws -> (MagicPaper.Story, ComposedStory) {
        let service = OfflineStoryService.shared
        let request = kind.request(sibling: nil)
        let composed = try service.compose(childName: "İrem", ideaID: nil, companionID: nil, mode: mode,
                                           age: age, seed: "special-\(kind.rawValue)", recall: recall,
                                           occasion: request)
        var story = OfflineStoryMapper.appStory(
            from: composed.story, childName: "İrem", childProfileID: UUID(), storyIdeaID: nil,
            catalogVersion: composed.catalogVersion, contentSource: composed.contentSource,
            mode: mode, selectionStrategy: .direct,
            ageBand: service.servedBand(forAge: age), occasion: request)
        story.lastReadPage = story.pages.count - 1
        return (story, composed.story)
    }

    func testTheOriginRecordsTheDay() throws {
        let (story, _) = try occasionStory(.birthday, age: 5, mode: .adventure)
        XCTAssertEqual(story.origin?.occasionID, "occasion_birthday")
        XCTAssertNil(story.origin?.recalled)
    }

    func testAnOriginWrittenBeforeE6StillDecodes() throws {
        let json = #"{"seed":"s","blueprintID":"b","settingID":"st","companionID":"c","discoveryID":"d","fingerprint":"f","catalogVersion":"1"}"#
        let origin = try JSONDecoder().decode(StoryOrigin.self, from: Data(json.utf8))
        XCTAssertNil(origin.occasionID)
    }

    func testASpecialDayStoryIsNotContinuedAndDoesNotRecall() throws {
        let folder = "SpecialDaySeries-\(UUID().uuidString)"
        defer {
            StorySeriesStore(subdirectory: folder).eraseAll()
            FamilyCharacterStore(subdirectory: folder).eraseAll()
        }
        let manager = SeriesManager(store: StorySeriesStore(subdirectory: folder),
                                    familyStore: FamilyCharacterStore(subdirectory: folder))
        let (story, composed) = try occasionStory(.newSibling, age: 3, mode: .bedtime)
        XCTAssertEqual(manager.eligibility(for: story, readToEnd: true), .unavailable)

        var plain = story
        plain.origin?.occasionID = nil
        XCTAssertEqual(manager.eligibility(for: plain, readToEnd: true), .available,
                       "the same story without the day could continue: the day is the reason")

        let history = RecallHistory(
            companions: [composed.content.companion.id: .init(storyCount: 2, firstSettingID: composed.content.setting.id)],
            visitedSettings: [composed.content.setting.id])
        let (_, recalled) = try occasionStory(.newSibling, age: 3, mode: .bedtime, recall: history)
        XCTAssertNil(recalled.recallLineID)
    }
}
