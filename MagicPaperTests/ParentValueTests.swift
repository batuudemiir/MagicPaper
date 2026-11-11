import XCTest
@testable import MagicPaper

/// Faz 14: akıllı hatırlatma ve değerlendirme isteği.
final class ParentValueTests: XCTestCase {

    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return c
    }()

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    func testSevenEveningsStartingTonight() {
        let plan = MPReminderPlan.evenings(from: date(11, 18), hour: 20, minute: 30,
                                           readToday: false, calendar: calendar)
        XCTAssertEqual(plan.count, 7)
        XCTAssertEqual(plan.first, date(11, 20, 30))
        XCTAssertEqual(plan.last, date(17, 20, 30))
    }

    func testAReadEveningIsSkipped() {
        let plan = MPReminderPlan.evenings(from: date(11, 18), hour: 20, minute: 30,
                                           readToday: true, calendar: calendar)
        XCTAssertEqual(plan.count, 7)
        XCTAssertEqual(plan.first, date(12, 20, 30))
    }

    func testAPassedEveningIsSkipped() {
        let plan = MPReminderPlan.evenings(from: date(11, 21), hour: 20, minute: 30,
                                           readToday: false, calendar: calendar)
        XCTAssertEqual(plan.first, date(12, 20, 30))
    }

    @MainActor
    func testReminderBodyNamesTonightsStory() {
        XCTAssertEqual(MPReminder.body(childName: "İrem", tonightTitle: "Uykucu Ay"),
                       "İrem için bu akşamın masalı: Uykucu Ay.")
        XCTAssertEqual(MPReminder.body(childName: "İrem"), "İrem için bu akşamın masalı.")
    }

    func testReviewWaitsForThreeFinishedStories() {
        XCTAssertFalse(MPReviewPolicy.shouldAsk(finished: 2, lastAsked: nil, lastCrash: nil, now: date(11, 12)))
        XCTAssertTrue(MPReviewPolicy.shouldAsk(finished: 3, lastAsked: nil, lastCrash: nil, now: date(11, 12)))
    }

    func testReviewIsSpacedAndQuietAfterACrash() {
        let now = date(11, 12)
        let recently = calendar.date(byAdding: .day, value: -30, to: now)!
        let longAgo = calendar.date(byAdding: .day, value: -61, to: now)!
        XCTAssertFalse(MPReviewPolicy.shouldAsk(finished: 5, lastAsked: recently, lastCrash: nil, now: now, calendar: calendar))
        XCTAssertTrue(MPReviewPolicy.shouldAsk(finished: 5, lastAsked: longAgo, lastCrash: nil, now: now, calendar: calendar))
        XCTAssertFalse(MPReviewPolicy.shouldAsk(finished: 5, lastAsked: nil, lastCrash: date(11, 9), now: now, calendar: calendar))
    }
}
