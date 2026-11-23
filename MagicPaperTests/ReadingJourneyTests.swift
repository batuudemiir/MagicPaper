import XCTest
@testable import MagicPaper

/// "Okuma yolculuğum" (23 Kasım 2026): hafta, sakin seri dili, özet.
final class ReadingJourneyTests: XCTestCase {

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return cal
    }()

    private func date(_ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: 12))!
    }

    /// 23–29 Kasım 2026 (Pazartesi–Pazar); bugün Çarşamba 25.
    private func journey(read: Set<Int>, streak: Int, minutes: [Int] = [9, 14, 11, 0, 0, 0, 0],
                         words: [String] = []) -> ReadingJourney {
        let week = (23...29).map { (date: date($0), read: read.contains($0)) }
        return ReadingJourney.make(week: week, minutes: minutes, streak: streak, stars: 12,
                                   words: words, wordCount: words.count, lastBadge: nil,
                                   now: date(25), calendar: calendar)
    }

    func testTheWeekRunsMondayToSundayWithTodayAndFuture() {
        let j = journey(read: [23, 24, 25], streak: 3)
        XCTAssertEqual(j.days.map(\.label), ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"])
        XCTAssertEqual(j.days.map(\.dayOfMonth), [23, 24, 25, 26, 27, 28, 29])
        XCTAssertEqual(j.days.firstIndex(where: \.isToday), 2)
        XCTAssertEqual(j.days.map(\.isFuture), [false, false, false, true, true, true, true])
    }

    func testACalmStreakLine() {
        let j = journey(read: [23, 24, 25], streak: 3)
        XCTAssertEqual(j.headline, "3 gün üst üste")
        XCTAssertEqual(j.message, "Birlikte okudunuz. Okuma yolculuğunuz devam ediyor.")
        XCTAssertEqual(j.weekSummary, "Bu hafta 3 gün birlikte okudunuz")
        XCTAssertEqual(j.minutesThisWeek, 34)
    }

    func testNoStreakInvitesWithoutPressure() {
        let j = journey(read: [], streak: 0, minutes: [0, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(j.headline, "Okuma yolculuğun")
        XCTAssertEqual(j.message, "Bugün bir masalla yolculuğa başlayalım.")
        XCTAssertEqual(j.weekSummary, "Bu hafta ilk masalı birlikte okuyalım")
        // Baskı dili yok.
        for text in [j.headline, j.message, j.weekSummary] {
            XCTAssertFalse(text.lowercased().contains("kaybet"))
            XCTAssertFalse(text.lowercased().contains("kaldı"))
        }
    }

    func testOnlyThreeWordsAreShownButAllAreCounted() {
        let j = journey(read: [25], streak: 1, words: ["fener", "usulca", "pırıltı", "yamaç"])
        XCTAssertEqual(j.words, ["fener", "usulca", "pırıltı"])
        XCTAssertEqual(j.wordCount, 4)
    }

    func testNegativeMinutesNeverShow() {
        let j = journey(read: [], streak: 0, minutes: [-5, 3])
        XCTAssertEqual(j.days.map(\.minutes), [0, 3, 0, 0, 0, 0, 0])
    }

    func testTheStarLevelNeverAsksForMore() {
        let j = journey(read: [], streak: 0)
        XCTAssertEqual(j.level, MPStarLevel.current(score: 12))
    }
}
