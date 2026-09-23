import Combine
import XCTest
@testable import MagicPaper

/// Okuma serisinin defteri.
///
/// Buradaki testlerin işi bir sayıyı korumak değil, bir **anlamı** korumak:
/// bir gün, uygulama açıldığı için değil, gerçekten okunduğu için işaretlenir.
/// Kural silinirse ekrandaki şerit yine bir şey iddia ediyor olacak.
@MainActor
final class ReadingStreakTests: XCTestCase {

    // MARK: - Kurulum

    private var suiteName: String!
    private var defaults: UserDefaults!

    /// Gün sınırı saat dilimine bağlı bir kural; testler sabit bir dilimde
    /// çalışmalı yoksa makinenin yerel ayarı sonucu değiştirir.
    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        cal.locale = Locale(identifier: "en_US_POSIX")
        return cal
    }()

    override func setUp() {
        super.setUp()
        suiteName = "mp.streak.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    /// "2026-03-14 21:30" gibi bir anı, testin saat diliminde.
    private func date(_ day: String, _ time: String = "12:00") -> Date {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.timeZone = calendar.timeZone
        return f.date(from: "\(day) \(time)")!
    }

    /// Saatin ileri alınabildiği bir defter.
    private func streak(clock: Clock) -> MPStreak {
        MPStreak(defaults: defaults, calendar: calendar, now: { clock.now })
    }

    /// Testin elinde tuttuğu saat.
    private final class Clock {
        var now: Date
        init(_ now: Date) { self.now = now }
    }

    private func readSeconds() -> [String: Double] {
        defaults.dictionary(forKey: "mp_readSeconds") as? [String: Double] ?? [:]
    }

    // MARK: - H3: anlamlı okuma oturumu

    /// Açmak okumak değildir. Kapağa bakıp çıkan biri günü işaretlemez.
    func testOpeningAndLeavingImmediatelyDoesNotMarkTheDay() {
        let s = streak(clock: Clock(date("2026-03-14", "20:00")))
        XCTAssertFalse(s.markReadingSession(
            MPReadingSession(secondsRead: 4, pagesTurned: 0)
        ))
        XCTAssertFalse(s.readToday)
        XCTAssertEqual(s.currentStreak, 0)
    }

    /// Tek bir sayfa çevirmek yeter: kitabın kendi kanıtı.
    func testOneTurnedPageMarksTheDay() {
        let s = streak(clock: Clock(date("2026-03-14", "20:00")))
        XCTAssertTrue(s.markReadingSession(
            MPReadingSession(secondsRead: 3, pagesTurned: 1)
        ))
        XCTAssertTrue(s.readToday)
        XCTAssertEqual(s.currentStreak, 1)
    }

    /// Sayfası olmayan içerik için ölçüt süre. Eşiğin altı sayılmaz.
    func testDurationAloneMustReachTheThreshold() {
        let below = MPReadingSession(secondsRead: MPReadingSession.minimumSeconds - 1,
                                     pagesTurned: 0)
        let atThreshold = MPReadingSession(secondsRead: MPReadingSession.minimumSeconds,
                                           pagesTurned: 0)
        XCTAssertFalse(below.isMeaningful)
        XCTAssertTrue(atThreshold.isMeaningful)
    }

    /// Eşik bir hedef değil, gürültü filtresi: kazara açılışın üstünde,
    /// sesli okunan tek bir sayfanın altında kalmalı.
    func testThresholdSitsBetweenAMisTapAndASinglePage() {
        XCTAssertGreaterThan(MPReadingSession.minimumSeconds, 10,
                             "kazara açılıp kapanan masal günü işaretlememeli")
        XCTAssertLessThanOrEqual(MPReadingSession.minimumSeconds, 45,
                                 "gerçekten okunan tek bir sayfa eşiği geçmeli")
    }

    /// Aynı gün ikinci bir oturum defteri bozmaz.
    func testMarkingTwiceInOneDayIsIdempotent() {
        let s = streak(clock: Clock(date("2026-03-14", "20:00")))
        s.markReadingSession(MPReadingSession(secondsRead: 60, pagesTurned: 2))
        s.markReadingSession(MPReadingSession(secondsRead: 60, pagesTurned: 2))
        XCTAssertEqual(s.readDays.count, 1)
        XCTAssertEqual(s.currentStreak, 1)
    }

    /// Anlamsız bulunan bir oturum diske hiçbir şey yazmaz.
    func testARejectedSessionWritesNothing() {
        let s = streak(clock: Clock(date("2026-03-14", "20:00")))
        s.markReadingSession(MPReadingSession(secondsRead: 1, pagesTurned: 0))
        XCTAssertNil(defaults.stringArray(forKey: "mp_readDays"))
    }

    /// Ardışık günler seriyi büyütür, bir gün atlamak sıfırlar.
    func testStreakCountsConsecutiveDaysAndResetsOnAGap() {
        let clock = Clock(date("2026-03-10", "20:00"))
        let s = streak(clock: clock)
        for day in ["2026-03-10", "2026-03-11", "2026-03-12"] {
            clock.now = date(day, "20:00")
            s.markReadingSession(MPReadingSession(secondsRead: 90, pagesTurned: 3))
        }
        XCTAssertEqual(s.currentStreak, 3)

        // 13'ü okunmadı, 14'ünde tekrar okundu.
        clock.now = date("2026-03-14", "20:00")
        s.markReadingSession(MPReadingSession(secondsRead: 90, pagesTurned: 3))
        XCTAssertEqual(s.currentStreak, 1)
    }

    // MARK: - H6: gece yarısı

    /// 23:50'de başlayıp 00:20'de biten bir masal iki güne aittir.
    func testASessionCrossingMidnightIsSplitAcrossBothDays() {
        let s = streak(clock: Clock(date("2026-03-15", "00:20")))
        s.addReadingTime(30 * 60)

        let map = readSeconds()
        XCTAssertEqual(map["2026-03-14"] ?? 0, 10 * 60, accuracy: 1,
                       "23:50–00:00 dünün defterine")
        XCTAssertEqual(map["2026-03-15"] ?? 0, 20 * 60, accuracy: 1,
                       "00:00–00:20 bugünün defterine")
    }

    /// Gece yarısını aşmayan oturum bölünmez.
    func testASessionWithinOneDayStaysWhole() {
        let s = streak(clock: Clock(date("2026-03-14", "21:00")))
        s.addReadingTime(15 * 60)

        let map = readSeconds()
        XCTAssertEqual(map.count, 1)
        XCTAssertEqual(map["2026-03-14"] ?? 0, 15 * 60, accuracy: 1)
    }

    /// Bölünme toplamı korumalı: hiçbir saniye kaybolmaz, hiçbiri iki kez
    /// sayılmaz. Bu, günlük okuma bütçesinin doğruluğunun temeli.
    func testSplittingPreservesTheTotal() {
        let s = streak(clock: Clock(date("2026-03-15", "00:05")))
        let slices = s.daySlices(endingAt: date("2026-03-15", "00:05"), seconds: 40 * 60)
        XCTAssertEqual(slices.count, 2)
        XCTAssertEqual(slices.reduce(0) { $0 + $1.seconds }, 40 * 60, accuracy: 0.001)
    }

    /// Bugünün bütçesi yalnızca bugünün dilimini görür — dün yazılan kısım
    /// bugünün payını yemez.
    func testTodayBudgetOnlySeesTodaysSlice() {
        let s = streak(clock: Clock(date("2026-03-15", "00:20")))
        s.addReadingTime(30 * 60)
        XCTAssertEqual(s.secondsToday, 20 * 60, accuracy: 1)
    }

    // MARK: - H5: objectWillChange sözleşmesi

    /// Bildirim değişimden ÖNCE gelmeli: aboneye haber ulaştığında değer
    /// henüz eskidir, SwiftUI'ın beklediği sıra budur.
    func testObjectWillChangeFiresBeforeTheValueChanges() {
        let s = streak(clock: Clock(date("2026-03-14", "21:00")))
        var secondsSeenBySubscriber: Double?
        let token = s.objectWillChange.sink { _ in
            MainActor.assumeIsolated { secondsSeenBySubscriber = s.secondsToday }
        }
        defer { token.cancel() }

        s.addReadingTime(600)

        XCTAssertEqual(secondsSeenBySubscriber, 0,
                       "bildirim anında değer hâlâ eski olmalı")
        XCTAssertEqual(s.secondsToday, 600, accuracy: 1)
    }

    // MARK: - H4: sınırsız büyüme

    /// Pencerenin dışına düşen günler açılışta düşer.
    func testOldEntriesArePrunedOnLoad() {
        let today = date("2026-03-14", "12:00")
        let ancient = "2020-01-01"
        let recent = "2026-03-01"
        defaults.set([ancient, recent], forKey: "mp_readDays")
        let seeded: [String: Double] = [ancient: 600, recent: 900]
        defaults.set(seeded, forKey: "mp_readSeconds")

        let s = streak(clock: Clock(today))

        XCTAssertEqual(s.readDays, [recent])
        XCTAssertNil(readSeconds()[ancient])
        XCTAssertEqual(readSeconds()[recent] ?? 0, 900, accuracy: 1)
    }

    /// Pencere kesintisiz bir seriyi taşıyabilmeli — budama bir kota değil.
    /// 400 günlük bir seri budamadan sağ çıkar.
    func testThePruningWindowDoesNotTruncateALongLiveStreak() {
        let today = date("2026-03-14", "12:00")
        let cal = calendar
        let days = (0..<(MPStreak.retentionDays - 1)).compactMap { offset -> String? in
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyy-MM-dd"
            f.timeZone = cal.timeZone
            return f.string(from: d)
        }
        defaults.set(days, forKey: "mp_readDays")

        let s = streak(clock: Clock(today))
        XCTAssertEqual(s.readDays.count, days.count)
        XCTAssertEqual(s.currentStreak, days.count)
    }

    /// Defter sınırsız büyümez: yıllarca okunmuş bir geçmiş pencereye iner.
    func testTheLedgerStaysBounded() {
        let today = date("2026-03-14", "12:00")
        let cal = calendar
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = cal.timeZone

        var days: [String] = []
        var seconds: [String: Double] = [:]
        for offset in 0..<(5 * 365) {
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = f.string(from: d)
            days.append(key)
            seconds[key] = 300
        }
        defaults.set(days, forKey: "mp_readDays")
        defaults.set(seconds, forKey: "mp_readSeconds")

        let s = streak(clock: Clock(today))
        XCTAssertLessThanOrEqual(s.readDays.count, MPStreak.retentionDays + 1)
        XCTAssertLessThanOrEqual(readSeconds().count, MPStreak.retentionDays + 1)
    }

    // MARK: - Korunan davranış

    /// `.missed` ile `.upcoming` ayrımı KORUNUR. Çocuğa henüz gelmemiş
    /// günleri "kaçırdın" diye göstermek, alışkanlık kurmaya çalışan bir
    /// ekranın yapabileceği en ters şey.
    func testFutureDaysAreUpcomingNotMissed() {
        // 2026-03-11 bir Çarşamba.
        let wednesday = date("2026-03-11", "20:00")
        defaults.set(["2026-03-09"], forKey: "mp_readDays") // Pazartesi okundu
        let s = streak(clock: Clock(wednesday))

        let states = s.weekStates
        XCTAssertEqual(states.count, 7)
        XCTAssertEqual(states[0], .done, "Pazartesi okundu")
        XCTAssertEqual(states[1], .missed, "Salı geçti ve okunmadı")
        XCTAssertEqual(states[2], .today, "Çarşamba bugün")
        for index in 3..<7 {
            XCTAssertEqual(states[index], .upcoming,
                           "gelecek günler kaçırılmış sayılmaz")
        }
    }

    /// Haftalık süre toplamı hafta içindeki günlerden gelir.
    func testWeeklyMinutesSumTheWeek() {
        let wednesday = date("2026-03-11", "20:00")
        let seeded: [String: Double] = ["2026-03-09": 600, "2026-03-11": 300, "2026-03-01": 9000]
        defaults.set(seeded, forKey: "mp_readSeconds")
        let s = streak(clock: Clock(wednesday))
        XCTAssertEqual(s.minutesThisWeek, 15, "geçen haftanın dakikaları sayılmaz")
    }
}
