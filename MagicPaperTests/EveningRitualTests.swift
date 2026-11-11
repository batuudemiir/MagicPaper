import XCTest
@testable import MagicPaper

/// Faz 11: akşam sırası ve okuyucuda "Konuşalım".
@MainActor
final class EveningRitualTests: XCTestCase {

    private var defaults: UserDefaults!
    private let child = UUID()
    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return c
    }()

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "EveningRitualTests")
        defaults.removePersistentDomain(forName: "EveningRitualTests")
    }

    private func date(_ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    func testStepsAreKeptPerChildAndEvening() {
        let routine = MPBedtimeRoutine(defaults: defaults, calendar: calendar)
        routine.toggle(.teeth, for: child, now: date(11, 20))
        routine.mark(.story, for: child, now: date(11, 21))
        XCTAssertEqual(routine.done(for: child, now: date(11, 21)), [.teeth, .story])
        XCTAssertEqual(routine.done(for: UUID(), now: date(11, 21)), [])
        XCTAssertEqual(routine.done(for: nil, now: date(11, 21)), [])
    }

    func testTheEveningLastsUntilMorning() {
        let routine = MPBedtimeRoutine(defaults: defaults, calendar: calendar)
        routine.mark(.light, for: child, now: date(12, 0))
        // Gece yarısından sonra işaretlenen ışık bir önceki akşama sayılır.
        XCTAssertEqual(routine.done(for: child, now: date(11, 22)), [.light])
        // Sabah sıra boşalır; kaçırılan akşam hiçbir yerde görünmez.
        XCTAssertEqual(routine.done(for: child, now: date(12, 9)), [])
    }

    func testToggleUndoesAndMarkIsIdempotent() {
        let routine = MPBedtimeRoutine(defaults: defaults, calendar: calendar)
        routine.toggle(.pajamas, for: child, now: date(11, 20))
        routine.toggle(.pajamas, for: child, now: date(11, 20))
        routine.mark(.story, for: child, now: date(11, 20))
        routine.mark(.story, for: child, now: date(11, 20))
        XCTAssertEqual(routine.done(for: child, now: date(11, 20)), [.story])
    }

    func testCaptionNamesTheNextStepNeverACount() {
        XCTAssertEqual(MPBedtimeRoutine.caption(for: []), "Önce dişler fırçalanır.")
        XCTAssertEqual(MPBedtimeRoutine.caption(for: [.teeth, .pajamas, .story]), "Masal tamam. Sırada ışık var.")
        XCTAssertEqual(MPBedtimeRoutine.caption(for: Set(MPBedtimeRoutine.Step.allCases)), "Hepsi tamam. İyi uykular.")
        for text in [MPBedtimeRoutine.caption(for: []), MPBedtimeRoutine.caption(for: [.teeth])] {
            XCTAssertFalse(text.contains("kaldı"), text)
            XCTAssertNil(text.rangeOfCharacter(from: .decimalDigits), text)
        }
    }

    func testTalkPromptsSitOnMiddlePagesOnly() {
        let long = StoryTalkPrompts.pagePrompts(for: ReaderFixtures.textStory(pages: 8))
        XCTAssertEqual(long.count, 3)
        XCTAssertTrue(long.keys.allSatisfy { (1...6).contains($0) }, "\(long.keys.sorted())")

        let short = StoryTalkPrompts.pagePrompts(for: ReaderFixtures.textStory(pages: 6))
        XCTAssertEqual(short.count, 2)
        XCTAssertTrue(short.keys.allSatisfy { (1...4).contains($0) })

        XCTAssertTrue(StoryTalkPrompts.pagePrompts(for: ReaderFixtures.textStory(pages: 3)).isEmpty)
    }

    func testTalkPromptsAreStableForAStory() {
        let story = ReaderFixtures.textStory(pages: 8)
        XCTAssertEqual(StoryTalkPrompts.pagePrompts(for: story), StoryTalkPrompts.pagePrompts(for: story))
        XCTAssertTrue(StoryTalkPrompts.pagePrompts(for: story).values.allSatisfy { $0.hasSuffix("?") })
    }

    func testTheSleepGateTimerHasAHandDimDarkerThanTheTimer() {
        XCTAssertGreaterThan(MPSleepTimer.handDim, MPSleepTimer.maxDim)
        XCTAssertLessThan(MPScreenBrightness.night, MPScreenBrightness.evening)
    }
}
