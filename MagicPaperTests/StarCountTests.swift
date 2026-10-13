import XCTest
@testable import MagicPaper

/// Yıldız sayacı (karar 13 Ekim 2026): her sabah 1, sonuna kadar okunan her
/// farklı masal 1. Harcama yok; yalnızca kazanılır.
final class StarCountTests: XCTestCase {

    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return c
    }()

    private func at(_ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    func testTheFirstDayAlreadyHasItsMorningStar() {
        XCTAssertEqual(MPStars.count(createdAt: at(13, 21), finished: 0, now: at(13, 22), calendar: calendar), 1)
    }

    func testEachNewMorningAddsOneStar() {
        XCTAssertEqual(MPStars.count(createdAt: at(10, 21), finished: 0, now: at(13, 8), calendar: calendar), 4)
    }

    func testStarsDoNotDependOnOpeningTheApp() {
        // Açılmayan günlerin yıldızı da gelir: uygulamayı açmak ödüllendirilmez.
        let skipped = MPStars.count(createdAt: at(1, 9), finished: 0, now: at(11, 9), calendar: calendar)
        XCTAssertEqual(skipped, 11)
    }

    func testEveryFinishedStoryAddsOneStar() {
        XCTAssertEqual(MPStars.count(createdAt: at(13, 9), finished: 3, now: at(13, 20), calendar: calendar), 4)
    }

    func testAClockSetBeforeTheProfileNeverGoesBelowOneMorning() {
        XCTAssertEqual(MPStars.count(createdAt: at(13, 9), finished: 2, now: at(12, 9), calendar: calendar), 3)
    }

    func testFinishedStoriesComeFromTheBadgeLedgerAndCountOnce() {
        var ledger = MPBadgeLedger()
        ledger.recordFinished(storyID: "a", mode: .bedtime)
        ledger.recordFinished(storyID: "a", mode: .bedtime)
        ledger.recordFinished(storyID: "b", mode: nil)
        XCTAssertEqual(MPStars.count(createdAt: at(13, 9), ledger: ledger, now: at(13, 10), calendar: calendar), 3)
    }
}
