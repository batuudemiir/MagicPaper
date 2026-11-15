import XCTest
@testable import MagicPaper

/// Yıldız puanı (karar 13 Ekim 2026; puan ve "okuma sabahı" 15 Kasım 2026):
/// bitirilen her farklı masal 1 yıldız; sabah yıldızı kural geçişine kadar her
/// gün, sonra yalnızca masal bitirilen günlerde. Puan hiç düşmez.
final class StarCountTests: XCTestCase {

    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return c
    }()

    private func at(_ day: Int, _ hour: Int, month: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    private func day(_ d: Int, month: Int = 10) -> String {
        MPBadgeDay.key(for: at(d, 12, month: month), calendar: calendar)
    }

    /// Kural geçişi "şimdi" iken eski kuralın sonuçları aynen kalır.
    private func legacy(createdAt: Date, finished: Int, now: Date) -> Int {
        MPStars.score(createdAt: createdAt, ruleSince: now, readingDays: [], finished: finished,
                      now: now, calendar: calendar)
    }

    // MARK: - Geçişe kadarki sabahlar (13 Ekim kuralı)

    func testTheFirstDayAlreadyHasItsMorningStar() {
        XCTAssertEqual(legacy(createdAt: at(13, 21), finished: 0, now: at(13, 22)), 1)
    }

    func testEachMorningBeforeTheSwitchCounts() {
        XCTAssertEqual(legacy(createdAt: at(10, 21), finished: 0, now: at(13, 8)), 4)
    }

    func testEveryFinishedStoryAddsOneStar() {
        XCTAssertEqual(legacy(createdAt: at(13, 9), finished: 3, now: at(13, 20)), 4)
    }

    func testAClockSetBeforeTheProfileNeverGoesBelowOneMorning() {
        XCTAssertEqual(legacy(createdAt: at(13, 9), finished: 2, now: at(12, 9)), 3)
    }

    // MARK: - Okuma sabahı (15 Kasım kuralı)

    func testAfterTheSwitchOnlyReadingDaysBringAMorningStar() {
        // Profil 1 Ekim'de, geçiş 10 Ekim'de: 1-10 arası 10 sabah korunur.
        // Sonra yalnızca 12 ve 15 Ekim'de okundu.
        let score = MPStars.score(createdAt: at(1, 9), ruleSince: at(10, 9),
                                  readingDays: [day(5), day(10), day(12), day(15)], finished: 4,
                                  now: at(20, 9), calendar: calendar)
        // 10 eski sabah + 2 okuma sabahı (5 ve 10 Ekim zaten sayıldı) + 4 masal.
        XCTAssertEqual(score, 16)
    }

    func testANewProfileAfterTheSwitchHasNoPassiveMornings() {
        let score = MPStars.score(createdAt: at(12, 9), ruleSince: at(10, 9),
                                  readingDays: [day(12)], finished: 1, now: at(14, 9), calendar: calendar)
        XCTAssertEqual(score, 2, "yalnızca 12 Ekim'in okuma sabahı ve masalı")
    }

    func testSkippedDaysAfterTheSwitchBringNothing() {
        let quiet = MPStars.score(createdAt: at(1, 9), ruleSince: at(1, 9), readingDays: [], finished: 0,
                                  now: at(11, 9), calendar: calendar)
        XCTAssertEqual(quiet, 1, "açılış sabahı kalır, okunmayan günler yıldız getirmez")
    }

    func testTheSwitchNeverLowersTheScore() {
        let before = legacy(createdAt: at(1, 9), finished: 2, now: at(11, 9))
        let after = MPStars.score(createdAt: at(1, 9), ruleSince: at(11, 9), readingDays: [], finished: 2,
                                  now: at(11, 20), calendar: calendar)
        XCTAssertEqual(before, after)
    }

    func testFinishedStoriesComeFromTheBadgeLedgerAndCountOnce() {
        var ledger = MPBadgeLedger()
        ledger.recordFinished(storyID: "a", mode: .bedtime, at: at(13, 10), calendar: calendar)
        ledger.recordFinished(storyID: "a", mode: .bedtime, at: at(13, 11), calendar: calendar)
        ledger.recordFinished(storyID: "b", mode: nil, at: at(13, 12), calendar: calendar)
        ledger.morningRuleSince = at(13, 9)
        XCTAssertEqual(MPStars.score(createdAt: at(13, 9), ledger: ledger, now: at(13, 20), calendar: calendar), 3)
    }

    // MARK: - Yıldız katı

    func testStarLevelsFollowTheScoreAndAreRecordedOnce() {
        var ledger = MPBadgeLedger()
        XCTAssertTrue(ledger.awardStarLevels(score: 9).isEmpty)
        XCTAssertEqual(ledger.awardStarLevels(score: 55).map(\.title), ["Kıvılcım", "Yıldız tozu", "Parıltı"])
        XCTAssertTrue(ledger.awardStarLevels(score: 55).isEmpty)
        XCTAssertEqual(MPStarLevel.current(score: 2000)?.title, "Masal göğü")
        XCTAssertNil(MPStarLevel.current(score: 9))
        XCTAssertEqual(MPStarLevel.all.count, 12)
        XCTAssertFalse(MPStarLevel.all[3].lockedHint.contains("kaldı"))
    }
}
