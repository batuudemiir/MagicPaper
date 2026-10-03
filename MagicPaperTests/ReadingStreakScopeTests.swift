import XCTest
@testable import MagicPaper

/// Okuma defteri çocuğa aittir (ürün kararı 2026-09-23).
///
/// Anne Ali için hikâye okuduğunda Ece'nin serisi devam etmemeli; eski cihaz
/// geneli defter ise kaybolmadan, bir kez ve yalnızca bir çocuğa devredilmeli.
@MainActor
final class ReadingStreakScopeTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    private let ece = UUID()
    private let ali = UUID()

    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return cal
    }()

    private let today: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 3; c.day = 14; c.hour = 20
        c.timeZone = TimeZone(identifier: "Europe/Istanbul")
        return Calendar(identifier: .gregorian).date(from: c)!
    }()

    override func setUp() {
        super.setUp()
        suiteName = "mp.streak.scope.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func streak(_ profile: UUID?) -> MPStreak {
        let now = today
        return MPStreak(defaults: defaults, calendar: calendar, now: { now }, profileID: profile)
    }

    private let aPage = MPReadingSession(secondsRead: 40, pagesTurned: 1)

    func testOneChildsReadingDoesNotCountForAnother() {
        let s = streak(ali)
        XCTAssertTrue(s.markReadingSession(aPage))
        XCTAssertTrue(s.readToday)

        s.activate(profileID: ece)
        XCTAssertFalse(s.readToday, "Ali read; Ece's day must not be marked.")
        XCTAssertEqual(s.currentStreak, 0)

        s.activate(profileID: ali)
        XCTAssertTrue(s.readToday)
    }

    func testReadingTimeIsPerChild() {
        let s = streak(ali)
        s.addReadingTime(120)
        XCTAssertEqual(s.secondsToday, 120, accuracy: 0.5)
        s.activate(profileID: ece)
        XCTAssertEqual(s.secondsToday, 0)
    }

    func testTheOldDeviceLedgerGoesToTheFirstChildOnly() {
        defaults.set(["2026-03-13", "2026-03-14"], forKey: MPStreak.legacyDaysKey)
        defaults.set(["2026-03-14": 300.0], forKey: MPStreak.legacySecondsKey)

        let s = streak(ali)
        XCTAssertEqual(s.currentStreak, 2, "The child reading at migration keeps the history.")
        XCTAssertEqual(s.secondsToday, 300, accuracy: 0.5)

        s.activate(profileID: ece)
        XCTAssertEqual(s.currentStreak, 0, "A sibling does not inherit history that was not theirs.")

        // Kopyalandı, taşınmadı: eski defter yerinde.
        XCTAssertEqual(Set(defaults.stringArray(forKey: MPStreak.legacyDaysKey) ?? []),
                       ["2026-03-13", "2026-03-14"])
    }

    func testAdoptionHappensOnceAndNeverOverwrites() {
        defaults.set(["2026-03-14"], forKey: MPStreak.legacyDaysKey)
        defaults.set(["2026-03-01"], forKey: MPStreak.daysKey(for: ali))

        _ = streak(ali)
        XCTAssertEqual(defaults.stringArray(forKey: MPStreak.daysKey(for: ali)), ["2026-03-01"],
                       "A child's own ledger is never replaced by the old one.")
        _ = streak(ece)
        XCTAssertNil(defaults.stringArray(forKey: MPStreak.daysKey(for: ece)))
    }

    func testDeletingAChildErasesOnlyTheirLedger() {
        let s = streak(ali)
        s.markReadingSession(aPage)
        s.activate(profileID: ece)
        s.markReadingSession(aPage)

        MPStreak.eraseLedger(for: ali, in: defaults)
        XCTAssertNil(defaults.stringArray(forKey: MPStreak.daysKey(for: ali)))
        XCTAssertNotNil(defaults.stringArray(forKey: MPStreak.daysKey(for: ece)))
    }

    func testEraseAllRemovesEveryLedger() {
        defaults.set(["2026-03-14"], forKey: MPStreak.legacyDaysKey)
        let s = streak(ali)
        s.markReadingSession(aPage)
        s.addReadingTime(60)

        MPStreak.eraseAllLedgers(in: defaults)
        let left = defaults.dictionaryRepresentation().keys.filter {
            $0.hasPrefix("mp_read") || $0 == MPStreak.legacyAssignedKey
        }
        XCTAssertTrue(left.isEmpty, left.description)
    }
}
