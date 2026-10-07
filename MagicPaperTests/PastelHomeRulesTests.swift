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

    func testAtBedtimeOnlyTheBedtimeModeIsOffered() {
        let all: [StoryMode] = [.bedtime, .learning, .adventure]
        XCTAssertEqual(StoryCreationSteps.allowedModes(all, isBedtime: true), [.bedtime])
        XCTAssertEqual(StoryCreationSteps.allowedModes(all, isBedtime: false), all)
    }

    /// A band that cannot build a bedtime story is not locked out at night.
    func testBedtimeNeverEmptiesTheModes() {
        XCTAssertEqual(StoryCreationSteps.allowedModes([.learning], isBedtime: true), [.learning])
    }

    // MARK: - Rozetler

    private func store() -> MPBadgeStore {
        let defaults = UserDefaults(suiteName: "PastelHomeRulesTests-\(UUID().uuidString)")!
        return MPBadgeStore(defaults: defaults)
    }

    func testMilestonesAreEarnedOnlyByReading() {
        let none = MPMilestone.Reading(finishedStories: 0, finishedBedtime: 0, finishedAdventure: 0, daysInARow: 0)
        XCTAssertTrue(MPMilestone.allCases.allSatisfy { !$0.isMet(by: none) })
        let one = MPMilestone.Reading(finishedStories: 1, finishedBedtime: 0, finishedAdventure: 0, daysInARow: 1)
        XCTAssertEqual(MPMilestone.allCases.filter { $0.isMet(by: one) }, [.firstStory])
    }

    func testAnEarnedMilestoneIsNeverLost() {
        let s = store()
        let child = UUID()
        let fresh = s.update(for: child, reading: .init(finishedStories: 1, finishedBedtime: 0,
                                                        finishedAdventure: 0, daysInARow: 3))
        XCTAssertEqual(Set(fresh), [.firstStory, .threeDays])
        // The streak breaks: "3 gün üst üste" stays.
        let again = s.update(for: child, reading: .init(finishedStories: 1, finishedBedtime: 0,
                                                        finishedAdventure: 0, daysInARow: 0))
        XCTAssertTrue(again.isEmpty)
        XCTAssertEqual(s.earned(for: child), [.firstStory, .threeDays])
    }

    func testMilestonesArePerChildAndErasable() {
        let s = store()
        let a = UUID(), b = UUID()
        s.update(for: a, reading: .init(finishedStories: 10, finishedBedtime: 7, finishedAdventure: 3, daysInARow: 0))
        XCTAssertTrue(s.earned(for: b).isEmpty)
        XCTAssertEqual(s.earned(for: a), [.firstStory, .tenStories, .sevenBedtime, .adventurer])
        s.erase(for: a)
        XCTAssertTrue(s.earned(for: a).isEmpty)
    }

    func testEraseAllRemovesEveryChildsMilestones() {
        let defaults = UserDefaults(suiteName: "PastelHomeRulesTests-all-\(UUID().uuidString)")!
        let s = MPBadgeStore(defaults: defaults)
        s.update(for: UUID(), reading: .init(finishedStories: 1, finishedBedtime: 0, finishedAdventure: 0, daysInARow: 0))
        MPBadgeStore.eraseAll(in: defaults)
        XCTAssertFalse(defaults.dictionaryRepresentation().keys.contains { $0.hasPrefix("mp_badges_") })
    }

    // MARK: - Okuma şeridi

    func testStreakCopyIsCalm() {
        XCTAssertEqual(StreakStrip(done: [], streak: 0, todayIndex: 0).title, "Okuma yolculuğun burada başlıyor")
        XCTAssertEqual(StreakStrip(done: [], streak: 1, todayIndex: 0).title, "Okuma yolculuğun devam ediyor")
        XCTAssertEqual(StreakStrip(done: [], streak: 4, todayIndex: 0).title, "4 gün üst üste okudun")
    }
}
