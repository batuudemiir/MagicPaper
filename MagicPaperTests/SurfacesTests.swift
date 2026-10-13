import XCTest
@testable import MagicPaper

/// FAZ 19 · iOS yüzeyleri: widget kaydı, "bu akşamın masalı" kuralı,
/// bağlantılar ve uyku modunun Live Activity'si.
@MainActor
final class SurfacesTests: XCTestCase {

    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        cal.locale = Locale(identifier: "en_US_POSIX")
        return cal
    }()

    private func date(_ day: String, _ time: String = "12:00") -> Date {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.timeZone = calendar.timeZone
        return f.date(from: "\(day) \(time)")!
    }

    private let resume = MPTonight.Resume(storyID: UUID(), title: "Ay Işığı", page: 3, pageCount: 8, progress: 0.3)
    private let daily = MPTonight.Daily(title: "Kayıp Yıldız Gemisi", minutes: 6)
    private let bedtime = MPTonight.Bedtime(hour: 20, minute: 30)

    // MARK: - Bu akşamın masalı

    func testTonightFollowsTheHomeCardOrder() {
        let afternoon = date("2026-10-13", "16:00")
        let night = date("2026-10-13", "21:00")
        let all = MPTonight.Inputs(bedtime: bedtime, resume: resume, readToday: false, daily: daily)

        XCTAssertEqual(MPTonight.resolve(all, now: night, calendar: calendar), .bedtime(bedtime))
        XCTAssertEqual(MPTonight.resolve(all, now: afternoon, calendar: calendar), .resume(resume))

        var noResume = all
        noResume.resume = nil
        XCTAssertEqual(MPTonight.resolve(noResume, now: afternoon, calendar: calendar), .unread(daily))

        noResume.readToday = true
        XCTAssertEqual(MPTonight.resolve(noResume, now: afternoon, calendar: calendar), .readToday)
    }

    func testBedtimeRunsUntilFiveInTheMorning() {
        XCTAssertTrue(MPTonight.isBedtime(hour: 20, minute: 30, now: date("2026-10-13", "20:30"), calendar: calendar))
        XCTAssertTrue(MPTonight.isBedtime(hour: 20, minute: 30, now: date("2026-10-14", "04:59"), calendar: calendar))
        XCTAssertFalse(MPTonight.isBedtime(hour: 20, minute: 30, now: date("2026-10-14", "05:00"), calendar: calendar))
        XCTAssertFalse(MPTonight.isBedtime(hour: 20, minute: 30, now: date("2026-10-13", "20:29"), calendar: calendar))
    }

    /// Ana sayfanın uyku kuralı ile widget'ınki aynı kural.
    func testHomeAndWidgetAgreeOnBedtime() {
        for hour in 0..<24 {
            let now = date("2026-10-13", String(format: "%02d:10", hour))
            XCTAssertEqual(
                MPBedtime.isBedtime(enabled: true, hour: 20, minute: 30, now: now, calendar: calendar),
                MPTonight.isBedtime(hour: 20, minute: 30, now: now, calendar: calendar))
            XCTAssertFalse(MPBedtime.isBedtime(enabled: false, hour: 20, minute: 30, now: now, calendar: calendar))
        }
    }

    /// Widget zaman çizelgesi kuralın değiştiği anlarda yeni giriş açar.
    func testTheNextChangeIsBedtimeMorningOrMidnight() {
        XCTAssertEqual(MPTonight.nextChange(after: date("2026-10-13", "16:00"), bedtime: bedtime, calendar: calendar),
                       date("2026-10-13", "20:30"))
        XCTAssertEqual(MPTonight.nextChange(after: date("2026-10-13", "21:00"), bedtime: bedtime, calendar: calendar),
                       date("2026-10-14", "00:00"))
        XCTAssertEqual(MPTonight.nextChange(after: date("2026-10-14", "00:00"), bedtime: bedtime, calendar: calendar),
                       date("2026-10-14", "05:00"))
        XCTAssertEqual(MPTonight.nextChange(after: date("2026-10-13", "16:00"), bedtime: nil, calendar: calendar),
                       date("2026-10-14", "00:00"))
    }

    func testTheClockLabelIsTurkish() {
        XCTAssertEqual(bedtime.clockLabel, "20.30")
        XCTAssertEqual(MPReminder.clockLabel(hour: 7, minute: 5), "07.05")
    }

    // MARK: - Okuma haftası

    /// Widget'ın haftası Ana sayfadaki şeritle aynı günleri gösterir.
    func testTheWidgetWeekMatchesTheStreakStrip() {
        let suite = "mp.surfaces.week.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        var now = date("2026-10-12", "19:00") // Pazartesi
        let streak = MPStreak(defaults: defaults, calendar: calendar, now: { now })
        for day in ["2026-10-12", "2026-10-14", "2026-10-18"] {
            now = date(day, "19:00")
            streak.markReadingSession(MPReadingSession(secondsRead: 60, pagesTurned: 2))
        }
        now = date("2026-10-18", "21:00") // Pazar
        let kept = MPReadingWeek.recent(streak.readDays, now: now, calendar: calendar)

        XCTAssertEqual(MPReadingWeek.days(kept, weekOf: now, calendar: calendar), streak.thisWeek)
        XCTAssertEqual(MPReadingWeek.days(kept, weekOf: now, calendar: calendar),
                       [true, false, true, false, false, false, true])
        // Yeni hafta Pazartesi boş başlar.
        XCTAssertEqual(MPReadingWeek.days(kept, weekOf: date("2026-10-19", "08:00"), calendar: calendar),
                       Array(repeating: false, count: 7))
    }

    func testOnlyTheLastTwoWeeksTravelToTheWidget() {
        let now = date("2026-10-18")
        let days: Set<String> = ["2026-10-18", "2026-10-05", "2026-10-04", "2026-01-01"]
        XCTAssertEqual(Set(MPReadingWeek.recent(days, now: now, calendar: calendar)), ["2026-10-18", "2026-10-05"])
    }

    // MARK: - Kayıt

    func testTheSnapshotRoundTripsThroughTheAppGroupStore() {
        let suite = "mp.surfaces.store.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let store = MPSurfaceStore(suite: suite)
        let snapshot = MPSurfaceSnapshot(
            hasChild: true, bedtime: bedtime, resume: resume, daily: daily, readDays: ["2026-10-13"],
            series: .init(title: "Gökkuşağı köprüsü", episode: 3, isReady: false,
                          opensAt: date("2026-10-14", "00:00"), read: 2, total: 5))

        XCTAssertEqual(store.load(), .empty)
        XCTAssertTrue(store.save(snapshot))
        XCTAssertEqual(store.load(), snapshot)
        // Değişmeyen kayıt widget'ları yeniden çizdirmez.
        XCTAssertFalse(store.save(snapshot))

        store.erase()
        XCTAssertEqual(store.load(), .empty)
    }

    /// Başka sürümün kaydı okunmaz; widget boş durumuna düşer.
    func testAnUnknownSnapshotVersionReadsAsEmpty() throws {
        let suite = "mp.surfaces.version.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var future = MPSurfaceSnapshot.empty
        future.hasChild = true
        future.version = MPSurfaceSnapshot.currentVersion + 1
        defaults.set(try JSONEncoder().encode(future), forKey: MPSurfaceStore.key)
        XCTAssertEqual(MPSurfaceStore(suite: suite).load(), .empty)
    }

    /// Grup hesabı yoksa (imzasız derleme) yazma hiçbir yere gitmez.
    func testWithoutAnAppGroupNothingIsWritten() {
        let store = MPSurfaceStore(suite: nil)
        XCTAssertFalse(store.save(MPSurfaceSnapshot(hasChild: true, bedtime: nil, resume: nil, daily: daily,
                                                    readDays: [], series: nil)))
        XCTAssertEqual(store.load(), .empty)
    }

    /// Kayıtta çocuğun adı için ayrı bir alan yok; yalnızca gösterilecek olan.
    func testTheSnapshotCarriesNoChildIdentity() throws {
        let snapshot = MPSurfaceSnapshot(hasChild: true, bedtime: bedtime, resume: resume, daily: daily,
                                         readDays: [], series: nil)
        let json = try XCTUnwrap(String(data: JSONEncoder().encode(snapshot), encoding: .utf8))
        for field in ["name", "age", "childID", "profile", "photo"] {
            XCTAssertFalse(json.contains("\"\(field)\""), field)
        }
    }

    func testAWaitingEpisodeTurnsReadyOnItsDay() {
        let opens = date("2026-10-14", "00:00")
        let series = MPSurfaceSnapshot.Series(title: "Seri", episode: 3, isReady: false, opensAt: opens, read: 2, total: 5)
        XCTAssertFalse(series.isReady(at: date("2026-10-13", "23:59")))
        XCTAssertTrue(series.isReady(at: opens))
        let unread = MPSurfaceSnapshot.Series(title: "Seri", episode: 3, isReady: false, opensAt: nil, read: 1, total: 5)
        XCTAssertFalse(unread.isReady(at: date("2027-01-01")))
    }

    /// Bölüm, önceki bölümün okunduğu saat diliminde ertesi gün açılır
    /// (`SeriesClock.dayHasPassed`).
    func testTheNextEpisodeOpensAtMidnightWhereItWasRead() {
        let mark = SeriesReadMark(at: date("2026-10-13", "21:15"), day: "2026-10-13", timeZone: "Europe/Istanbul")
        XCTAssertEqual(MPSurfaceSync.dayAfter(mark), date("2026-10-14", "00:00"))
    }

    // MARK: - Bağlantılar

    func testSurfaceLinksRoundTrip() {
        for link in MPSurfaceLink.allCases {
            XCTAssertEqual(MPSurfaceLink(url: link.url), link)
        }
        XCTAssertEqual(MPSurfaceLink.tonight.url.absoluteString, "magicpaper://tonight")
    }

    func testOtherLinksAreNotSurfaces() {
        for text in ["magicpaper://invite/ABCD1234", "magicpaper://parent", "magicpaper://tonight/extra",
                     "https://magicpaper-393a7.web.app/i/ABCD1234", "other://tonight"] {
            XCTAssertNil(MPSurfaceLink(url: URL(string: text)!), text)
        }
        // Aile daveti de widget bağlantısını kendine almaz.
        for link in MPSurfaceLink.allCases {
            XCTAssertNil(FamilyInviteCode.from(url: link.url))
        }
    }

    // MARK: - Uyku modu

    private final class FakeSpeech: MPSleepSpeaking {
        var isPaused = false
        var onFinished: (() -> Void)?
        var spoken: [String] = []
        var stops = 0
        func speak(_ text: String, language: String, recording: URL?) { spoken.append(text); isPaused = false }
        func pause() { isPaused = true }
        func resume() { isPaused = false }
        func stop() { stops += 1; isPaused = false }
    }

    private final class FakeActivity: MPSleepActivityHosting {
        var states: [MPSleepActivityAttributes.ContentState] = []
        var started = 0
        var ended = 0
        func start(state: MPSleepActivityAttributes.ContentState) { started += 1; states.append(state) }
        func update(state: MPSleepActivityAttributes.ContentState) { states.append(state) }
        func end() { ended += 1 }
    }

    private final class Clock {
        var now: Date
        init(_ now: Date) { self.now = now }
    }

    private func playback(pages: [String] = ["Bir", "İki"], clock: Clock,
                          speech: FakeSpeech, activity: FakeActivity) -> MPSleepPlayback {
        MPSleepPlayback(session: MPSleepSession(title: "Uyku masalı", pages: pages),
                        speech: speech, activity: activity, now: { clock.now })
    }

    func testSleepModeReadsPageByPageAndShowsTheTimeLeft() {
        let clock = Clock(date("2026-10-13", "20:30"))
        let speech = FakeSpeech(), activity = FakeActivity()
        let sleep = playback(clock: clock, speech: speech, activity: activity)

        sleep.start()
        XCTAssertEqual(speech.spoken, ["Bir"])
        XCTAssertEqual(activity.started, 1)
        XCTAssertEqual(activity.states.last?.endsAt, clock.now.addingTimeInterval(15 * 60))
        XCTAssertEqual(activity.states.last?.isPaused, false)

        speech.onFinished?()
        XCTAssertEqual(speech.spoken, ["Bir", "İki"])
    }

    /// Duraklayınca sayaç durur: kalan süre kilit ekranında sabit kalır.
    func testPausingFreezesTheTimer() {
        let clock = Clock(date("2026-10-13", "20:30"))
        let speech = FakeSpeech(), activity = FakeActivity()
        let sleep = playback(clock: clock, speech: speech, activity: activity)
        sleep.start()

        clock.now += 5 * 60
        sleep.togglePlay()
        XCTAssertTrue(speech.isPaused)
        XCTAssertEqual(activity.states.last?.pausedRemaining, 10 * 60)

        clock.now += 30 * 60
        sleep.tick()
        XCTAssertEqual(sleep.elapsed, 5 * 60)

        sleep.togglePlay()
        XCTAssertNil(activity.states.last?.pausedRemaining)
        XCTAssertEqual(activity.states.last?.endsAt, clock.now.addingTimeInterval(10 * 60))
    }

    /// Süre telefon kilitliyken de işler: duvar saatiyle tutulur.
    func testTheTimerCountsTimeSpentInTheBackground() {
        let clock = Clock(date("2026-10-13", "20:30"))
        let speech = FakeSpeech(), activity = FakeActivity()
        let sleep = playback(pages: Array(repeating: "Sayfa", count: 40), clock: clock, speech: speech, activity: activity)
        var closed = 0
        sleep.onClose = { closed += 1 }
        sleep.start()

        clock.now += 14 * 60
        sleep.tick()
        XCTAssertEqual(closed, 0)

        clock.now += 60
        sleep.tick()
        sleep.tick()
        XCTAssertEqual(closed, 1)
        XCTAssertEqual(activity.ended, 1)
        XCTAssertGreaterThan(speech.stops, 0)
    }

    func testChangingTheTimerMovesTheEndTime() {
        let clock = Clock(date("2026-10-13", "20:30"))
        let activity = FakeActivity()
        let sleep = playback(clock: clock, speech: FakeSpeech(), activity: activity)
        sleep.start()
        sleep.timer.minutes = 20
        XCTAssertEqual(activity.states.last?.endsAt, clock.now.addingTimeInterval(20 * 60))
    }

    /// Live Activity'deki "Durdur" uyku modunu kapatır.
    func testTheLiveActivityStopButtonClosesSleepMode() {
        let clock = Clock(date("2026-10-13", "20:30"))
        let activity = FakeActivity()
        let sleep = playback(clock: clock, speech: FakeSpeech(), activity: activity)
        var closed = false
        sleep.onClose = { closed = true }
        sleep.start()

        MPSleepRemote.stop?()
        XCTAssertTrue(closed)
        XCTAssertEqual(activity.ended, 1)
        XCTAssertNil(MPSleepRemote.stop)
    }

    func testTheLastPageMarksTheStoryFinished() {
        let clock = Clock(date("2026-10-13", "20:30"))
        let speech = FakeSpeech(), activity = FakeActivity()
        let sleep = playback(pages: ["Tek"], clock: clock, speech: speech, activity: activity)
        sleep.start()
        speech.onFinished?()
        XCTAssertTrue(sleep.finished)
        XCTAssertEqual(activity.states.last?.finished, true)
    }
}
