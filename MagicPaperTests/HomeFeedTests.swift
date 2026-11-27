import XCTest
@testable import MagicPaper

/// Ana sayfanın kararları (`HomeFeed`, 21 Kasım 2026; ANA_SAYFA_HAZIRLIK A2, A3, A4).
final class HomeFeedTests: XCTestCase {

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        cal.locale = Locale(identifier: "en_US_POSIX")
        return cal
    }()

    private func date(_ time: String, day: String = "2026-11-21") -> Date {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.timeZone = calendar.timeZone
        return f.date(from: "\(day) \(time)")!
    }

    private let bedtime = MPTonight.Bedtime(hour: 20, minute: 30)

    private func inputs(_ tonight: MPTonight, canWrite: Bool = true) -> HomeFeed.Inputs {
        HomeFeed.Inputs(tonight: tonight, canWriteNewStory: canWrite, stars: 7, streak: 3, hasSeriesCard: true)
    }

    // MARK: - Selam

    func testGreetingChangesAtItsHours() {
        XCTAssertEqual(HomeFeed.greeting(at: date("04:59"), calendar: calendar), "İyi geceler,")
        XCTAssertEqual(HomeFeed.greeting(at: date("05:00"), calendar: calendar), "Günaydın,")
        XCTAssertEqual(HomeFeed.greeting(at: date("10:59"), calendar: calendar), "Günaydın,")
        XCTAssertEqual(HomeFeed.greeting(at: date("11:00"), calendar: calendar), "İyi günler,")
        XCTAssertEqual(HomeFeed.greeting(at: date("17:00"), calendar: calendar), "İyi akşamlar,")
        XCTAssertEqual(HomeFeed.greeting(at: date("22:00"), calendar: calendar), "İyi geceler,")
    }

    // MARK: - Bu akşamın kartı

    func testEachTonightBecomesItsCardState() {
        let resume = MPTonight.Resume(storyID: UUID(), title: "Ay Işığı", page: 3, pageCount: 8, progress: 0.3)
        XCTAssertEqual(HomeFeed.state(for: .resume(resume), canWrite: true),
                       .resume(progress: 0.3, title: "Ay Işığı", meta: "Sayfa 3 / 8"))
        XCTAssertEqual(HomeFeed.state(for: .unread(.init(title: "Kayıp Yıldız", minutes: 6)), canWrite: true),
                       .unread(title: "Kayıp Yıldız", meta: "6 dakika"))
        XCTAssertEqual(HomeFeed.state(for: .bedtime(bedtime), canWrite: true), .bedtime(time: "20.30"))
    }

    func testReadTodayCarriesWhetherANewStoryCanBeWritten() {
        XCTAssertEqual(HomeFeed.state(for: .readToday, canWrite: true), .readToday(canWrite: true))
        XCTAssertEqual(HomeFeed.state(for: .readToday, canWrite: false), .readToday(canWrite: false))
    }

    func testOnlyBedtimeTurnsTheSceneToNight() {
        let night = HomeFeed.make(inputs(.bedtime(bedtime)), now: date("21:00"), calendar: calendar)
        XCTAssertTrue(night.isNight)
        XCTAssertEqual(night.greeting, "İyi akşamlar,")
        let day = HomeFeed.make(inputs(.readToday), now: date("15:00"), calendar: calendar)
        XCTAssertFalse(day.isNight)
        XCTAssertEqual(day.stars, 7)
        XCTAssertEqual(day.streak, 3)
        XCTAssertTrue(day.hasSeriesCard)
    }

    func testTheSameInputsAtTheSameMinuteGiveAnEqualFeed() {
        // Depo eşit sonucu yayınlamaz: ekran boşuna yeniden çizilmez.
        let a = HomeFeed.make(inputs(.readToday), now: date("15:00"), calendar: calendar)
        let b = HomeFeed.make(inputs(.readToday), now: date("15:00"), calendar: calendar)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, HomeFeed.make(inputs(.readToday, canWrite: false), now: date("15:00"), calendar: calendar))
    }

    // MARK: - Kartın kapağı (A6)

    private func daily(_ category: DailyStoryCategory) -> DailyStory {
        DailyStory(id: UUID(), title: "Kelebeğin Dönüşümü", category: category, ageRange: "3-6",
                   readingTime: 5, content: "", moralLesson: "", emoji: "", isRead: false, lastReadDate: nil)
    }

    func testTodaysStoryWithoutAPaintedCoverGetsItsCategoryTitleCover() {
        let story = daily(.nature)
        XCTAssertEqual(HomeFeed.cover(for: .unread(.init(title: story.title, minutes: 5)), resume: nil,
                                      daily: story, original: nil),
                       .title("Kelebeğin Dönüşümü", tone: .green, modeSymbol: nil, worldSymbol: "tree"))
    }

    func testTodaysStoryWithAPaintedCoverShowsIt() {
        let story = daily(.bedtime)
        let painted = ClassicOriginalCover(feedID: story.id, cover: "classic-orijinal-ayin-ninni-sarkisi",
                                           coverFocus: .center, coverCredit: "", shelves: [.uyku])
        XCTAssertEqual(HomeFeed.cover(for: .unread(.init(title: story.title, minutes: 5)), resume: nil,
                                      daily: story, original: painted),
                       .image("classic-orijinal-ayin-ninni-sarkisi", focus: .center))
    }

    func testBedtimeAndReadTodayOfferNoBookSoNoCover() {
        let story = daily(.nature)
        XCTAssertNil(HomeFeed.cover(for: .bedtime(bedtime), resume: nil, daily: story, original: nil))
        XCTAssertNil(HomeFeed.cover(for: .readToday, resume: nil, daily: story, original: nil))
    }

    func testEveryCategoryHasItsOwnTone() {
        let tones = DailyStoryCategory.allCases.map(HomeFeed.tone(for:))
        XCTAssertEqual(Set(tones).count, DailyStoryCategory.allCases.count)
    }

    // MARK: - Bir sonraki değişim

    func testNextChangeIsTheNearestGreetingHour() {
        XCTAssertEqual(HomeFeed.nextChange(after: date("16:30"), bedtime: bedtime, writeOpensAt: nil, calendar: calendar),
                       date("17:00"))
    }

    func testNextChangeIsBedtimeWhenItComesFirst() {
        XCTAssertEqual(HomeFeed.nextChange(after: date("20:00"), bedtime: bedtime, writeOpensAt: nil, calendar: calendar),
                       date("20:30"))
    }

    func testWithoutBedtimeTheEveningWaitsForTheNightGreeting() {
        XCTAssertEqual(HomeFeed.nextChange(after: date("20:00"), bedtime: nil, writeOpensAt: nil, calendar: calendar),
                       date("22:00"))
    }

    func testAfterTheLastGreetingTheDayTurnsAtMidnight() {
        XCTAssertEqual(HomeFeed.nextChange(after: date("23:10"), bedtime: bedtime, writeOpensAt: nil, calendar: calendar),
                       date("00:00", day: "2026-11-22"))
    }

    func testTheFreeStoryOpeningIsAChange() {
        XCTAssertEqual(HomeFeed.nextChange(after: date("20:40"), bedtime: bedtime, writeOpensAt: date("21:15"),
                                           calendar: calendar),
                       date("21:15"))
    }

    func testAnOpeningInThePastIsIgnored() {
        XCTAssertEqual(HomeFeed.nextChange(after: date("20:40"), bedtime: bedtime, writeOpensAt: date("19:00"),
                                           calendar: calendar),
                       date("22:00"))
    }

    func testABoundaryExactlyNowIsNotTheNextChange() {
        XCTAssertEqual(HomeFeed.nextChange(after: date("17:00"), bedtime: nil, writeOpensAt: nil, calendar: calendar),
                       date("22:00"))
    }
}
