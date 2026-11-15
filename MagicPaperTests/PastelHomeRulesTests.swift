import XCTest
import StoryEngine
@testable import MagicPaper

/// FAZ 17 (Pastel Masal) kuralları: uyku saati, rozetler, uyku saatinde mod.
final class PastelHomeRulesTests: XCTestCase {

    private func at(_ hour: Int, _ minute: Int) -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 10; c.day = 7; c.hour = hour; c.minute = minute
        return Calendar.current.date(from: c)!
    }

    // MARK: - Uyku saati

    func testBedtimeStartsAtTheChosenMinuteAndLastsUntilMorning() {
        func bed(_ h: Int, _ m: Int) -> Bool {
            MPBedtime.isBedtime(enabled: true, hour: 20, minute: 30, now: at(h, m))
        }
        XCTAssertFalse(bed(20, 29))
        XCTAssertTrue(bed(20, 30))
        XCTAssertTrue(bed(23, 59))
        XCTAssertTrue(bed(0, 10), "20.30'da başlayan gece yarısında bitmez")
        XCTAssertTrue(bed(4, 59))
        XCTAssertFalse(bed(5, 0))
        XCTAssertFalse(bed(15, 0))
    }

    func testBedtimeOffNeverRestricts() {
        XCTAssertFalse(MPBedtime.isBedtime(enabled: false, hour: 20, minute: 30, now: at(22, 0)))
    }

    /// Akşam üç mod da seçilebilir; Uyku öncesi ilk ve vurgulu (15 Ekim 2026).
    func testAtBedtimeEveryModeIsOfferedAndBedtimeLeads() {
        let all: [StoryMode] = [.adventure, .learning, .bedtime]
        let emphasized = StoryCreationSteps.emphasizedMode(all, isBedtime: true)
        XCTAssertEqual(emphasized, .bedtime)
        XCTAssertEqual(StoryCreationSteps.shownModes(all, emphasized: emphasized), [.bedtime, .learning, .adventure])
    }

    func testDuringTheDayNothingIsEmphasized() {
        let all: [StoryMode] = [.bedtime, .learning, .adventure]
        XCTAssertNil(StoryCreationSteps.emphasizedMode(all, isBedtime: false))
        XCTAssertEqual(StoryCreationSteps.shownModes(all), StoryMode.displayOrder)
    }

    /// A band that cannot build a bedtime story keeps its modes and gets no emphasis.
    func testBedtimeNeverEmptiesTheModes() {
        XCTAssertNil(StoryCreationSteps.emphasizedMode([.learning], isBedtime: true))
        XCTAssertEqual(StoryCreationSteps.shownModes([.learning], emphasized: nil), [.learning])
    }

    // MARK: - Rozetler

    /// Sabit saat: öğleden sonra, sabah rozeti karışmasın.
    private var badgeCalendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return c
    }

    private func afternoon(_ day: Int = 11) -> Date {
        badgeCalendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: 15))!
    }

    func testTheFirstFinishedStoryEarnsTheFirstBadgeOnce() {
        var ledger = MPBadgeLedger()
        let first = ledger.recordFinished(storyID: "a", mode: .bedtime, at: afternoon(), calendar: badgeCalendar)
        XCTAssertEqual(Set(first), [.firstStory, MPBadgeCatalog.badge("firstBedtime")!])
        XCTAssertTrue(ledger.recordFinished(storyID: "a", mode: .bedtime, at: afternoon(), calendar: badgeCalendar)
            .isEmpty, "aynı masal ikinci kez sayılmaz")
        XCTAssertEqual(ledger.finished.count, 1)
    }

    func testModeBadgesAndThresholds() {
        var ledger = MPBadgeLedger()
        ledger.recordFinished(storyID: "l", mode: .learning, at: afternoon(), calendar: badgeCalendar)
        ledger.recordFinished(storyID: "a", mode: .adventure, at: afternoon(), calendar: badgeCalendar)
        XCTAssertEqual(Set(ledger.earnedBadges), [.firstStory, .firstLearning, .firstAdventure])
        for i in 0..<7 { ledger.recordFinished(storyID: "b\(i)", mode: .bedtime, at: afternoon(), calendar: badgeCalendar) }
        XCTAssertTrue(ledger.earnedBadges.contains(.sevenBedtime))
        XCTAssertTrue(ledger.earnedBadges.contains(.fiveStories))
        XCTAssertTrue(ledger.earnedIDs.contains("allThreeModes"))
        XCTAssertFalse(ledger.earnedBadges.contains(.tenStories))
    }

    func testTheFifthEpisodeCompletesASeriesBadge() {
        var ledger = MPBadgeLedger()
        XCTAssertTrue(ledger.recordFinished(storyID: "e5", mode: .bedtime, seriesCompletedID: "s1")
            .contains(.firstSeriesCompleted))
    }

    func testMergingKeepsEveryBadgeAndTheEarliestDate() {
        let early = Date(timeIntervalSince1970: 100), late = Date(timeIntervalSince1970: 200)
        var a = MPBadgeLedger(); a.recordFinished(storyID: "x", mode: .learning, at: late)
        var b = MPBadgeLedger(); b.recordFinished(storyID: "y", mode: .adventure, at: early)
        let merged = a.merged(with: b)
        XCTAssertEqual(merged.finished, ["x", "y"])
        XCTAssertEqual(merged.earned[MPBadge.firstStory.id], early)
        XCTAssertNotNil(merged.earned[MPBadge.firstLearning.id])
        XCTAssertNotNil(merged.earned[MPBadge.firstAdventure.id])
    }

    func testLedgersArePerChildAndErasable() {
        let defaults = UserDefaults(suiteName: "PastelHomeRulesTests-\(UUID().uuidString)")!
        let store = MPBadgeStore(defaults: defaults)
        let a = UUID(), b = UUID()
        var ledger = MPBadgeLedger(); ledger.recordFinished(storyID: "x", mode: nil, at: afternoon(), calendar: badgeCalendar)
        store.save(ledger, for: a)
        XCTAssertNil(store.storedLedger(for: b))
        store.merge(MPBadgeLedger(), for: a)
        XCTAssertEqual(store.storedLedger(for: a)?.earnedBadges, [.firstStory])
        MPBadgeStore.eraseAll(in: defaults)
        XCTAssertNil(store.storedLedger(for: a))
    }

    // MARK: - Okuma şeridi

    func testStreakCopyIsCalm() {
        XCTAssertEqual(StreakStrip(done: [], streak: 0, todayIndex: 0).title, "Okuma yolculuğun burada başlıyor")
        XCTAssertEqual(StreakStrip(done: [], streak: 1, todayIndex: 0).title, "Okuma yolculuğun devam ediyor")
        XCTAssertEqual(StreakStrip(done: [], streak: 4, todayIndex: 0).title, "4 gün üst üste okudun")
    }

    // MARK: - Ebeveyn kapısı

    func testTheGateAsksAMultiplicationAndAcceptsTheProduct() {
        var quiz = MPGateQuiz(a: 7, b: 4)
        XCTAssertEqual(quiz.question, "7 × 4 = ?")
        XCTAssertEqual(quiz.answer(28), .correct)
    }

    func testAWrongAnswerAsksANewQuestion() {
        var quiz = MPGateQuiz(a: 7, b: 4)
        XCTAssertEqual(quiz.answer(27, next: { (3, 3) }), .wrong)
        XCTAssertEqual(quiz.question, "3 × 3 = ?")
    }

    func testThreeMissesLockTheGateForThirtySeconds() {
        let t0 = Date(timeIntervalSince1970: 1_000)
        var quiz = MPGateQuiz(a: 2, b: 2)
        XCTAssertEqual(quiz.answer(1, at: t0, next: { (2, 2) }), .wrong)
        XCTAssertEqual(quiz.answer(1, at: t0, next: { (2, 2) }), .wrong)
        XCTAssertEqual(quiz.answer(1, at: t0, next: { (2, 2) }), .locked)
        // Even the right answer waits.
        XCTAssertEqual(quiz.answer(4, at: t0.addingTimeInterval(29)), .locked)
        XCTAssertEqual(quiz.secondsLeft(at: t0.addingTimeInterval(20)), 10)
        XCTAssertEqual(quiz.answer(4, at: t0.addingTimeInterval(30)), .correct)
    }
}
