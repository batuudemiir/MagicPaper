import XCTest
import StoryEngine
@testable import MagicPaper

/// 21 · Masal yazılıyor: the masal atölyesi script (`docs/MASAL_ATOLYESI_PLANI.md`).
final class StoryPreparationScriptTests: XCTestCase {

    private func facts(
        name: String = "Ela",
        companion: PreparationFacts.Companion? = .init(name: "Tarçın", kind: "tilki"),
        family: String? = nil,
        mode: StoryMode? = .bedtime,
        hasNewWord: Bool = false,
        ordinal: Int = 1,
        firstRun: Bool = false,
        bedtime: Bool = false
    ) -> PreparationFacts {
        PreparationFacts(childName: name, companion: companion, familyName: family, mode: mode,
                         hasNewWord: hasNewWord, firstSentence: "Bir varmış bir yokmuş.",
                         pageCount: 8, storyOrdinal: ordinal, isFirstRun: firstRun, isBedtime: bedtime)
    }

    private func beats(_ f: PreparationFacts) -> [StoryPreparationScript.Beat] {
        StoryPreparationScript.steps(for: f).map(\.beat)
    }

    private func line(_ beat: StoryPreparationScript.Beat, _ f: PreparationFacts) -> String? {
        StoryPreparationScript.steps(for: f).first { $0.beat == beat }?.line
    }

    // MARK: - Sıra

    func testTheFullRitualHasEveryBeatInOrder() {
        XCTAssertEqual(beats(facts()), [.openBook, .cast, .ageFit, .modeTouch, .writing, .reread, .bind])
    }

    func testTheShortRitualFoldsTheAgeLine() {
        XCTAssertEqual(beats(facts(ordinal: 7)), [.openBook, .cast, .modeTouch, .writing, .reread, .bind])
    }

    func testAStoryWithoutAModeHasNoModeLine() {
        XCTAssertFalse(beats(facts(mode: nil)).contains(.modeTouch))
    }

    // MARK: - Metin

    func testModeLinesFollowTheStory() {
        XCTAssertEqual(line(.modeTouch, facts(mode: .bedtime)), "Uyku için yumuşak bir son yazılıyor.")
        XCTAssertEqual(line(.modeTouch, facts(mode: .adventure)), "Macera için bir yol çiziliyor.")
        XCTAssertEqual(line(.modeTouch, facts(mode: .learning, hasNewWord: true)), "Masala yeni bir kelime saklanıyor.")
        // Kelimesi olmayan bir masal "yeni kelime" demez.
        XCTAssertEqual(line(.modeTouch, facts(mode: .learning, hasNewWord: false)), "Masala bir keşif saklanıyor.")
    }

    func testTheCastNamesTheChildTheCompanionAndTheFamily() {
        XCTAssertEqual(line(.cast, facts(family: "Mia")), "Masalda Ela, tilki Tarçın ve Mia var.")
        XCTAssertEqual(line(.cast, facts()), "Masalda Ela ve tilki Tarçın var.")
        XCTAssertEqual(line(.cast, facts(companion: nil)), "Masalın kahramanı Ela.")
        XCTAssertEqual(line(.cast, facts(companion: .init(name: "Pamuk", kind: ""))), "Masalda Ela ve Pamuk var.")
    }

    func testOwnershipFollowsVowelHarmony() {
        XCTAssertEqual(line(.openBook, facts(name: "Ela")), "Ragi, Ela'nın masal defterini açıyor.")
        XCTAssertEqual(line(.openBook, facts(name: "Ömer")), "Ragi, Ömer'in masal defterini açıyor.")
        XCTAssertEqual(line(.openBook, facts(name: "Aslı")), "Ragi, Aslı'nın masal defterini açıyor.")
        XCTAssertEqual(line(.openBook, facts(name: "Defne")), "Ragi, Defne'nin masal defterini açıyor.")
    }

    func testTheBindingLineCountsTheChildsStories() {
        XCTAssertEqual(line(.bind, facts(ordinal: 1)), "Ela'nın ilk masalı hazır.")
        XCTAssertEqual(line(.bind, facts(ordinal: 12)), "Ela'nın 12. masalı hazır.")
    }

    func testTheWritingLineSaysHowManyPages() {
        XCTAssertEqual(line(.writing, facts()), "Sayfalar yazılıyor · 8 sayfa")
    }

    // MARK: - Defter

    func testEachStepLeavesItsNote() {
        typealias S = StoryPreparationScript
        XCTAssertEqual(S.note(for: .ageFit, facts: facts())?.text, "Yaşına uygun kelimeler")
        XCTAssertEqual(S.note(for: .modeTouch, facts: facts(mode: .bedtime))?.text, "Yumuşak bir son")
        XCTAssertEqual(S.note(for: .modeTouch, facts: facts(mode: .learning, hasNewWord: true))?.text, "Yeni bir kelime")
        XCTAssertEqual(S.note(for: .modeTouch, facts: facts(mode: .learning))?.text, "Bir keşif")
        XCTAssertEqual(S.note(for: .modeTouch, facts: facts(mode: .adventure))?.text, "Bir macera yolu")
        XCTAssertNil(S.note(for: .modeTouch, facts: facts(mode: nil)))
        XCTAssertEqual(S.note(for: .reread, facts: facts())?.text, "Ragi okudu")
        XCTAssertNil(S.note(for: .cast, facts: facts()))
    }

    func testTheNotebookHasTheChildsNameAndShelfNumber() {
        XCTAssertEqual(StoryPreparationScript.notebookTitle(facts(name: "Ömer")), "Ömer'in masal defteri")
        XCTAssertEqual(StoryPreparationScript.shelfNumber(facts(ordinal: 12)), "No. 12")
    }

    // MARK: - Süre

    func testTheRitualShortensAsTheFamilyLearnsIt() {
        let first = StoryPreparationScript.totalDuration(for: facts(ordinal: 1))
        let second = StoryPreparationScript.totalDuration(for: facts(ordinal: 2))
        let later = StoryPreparationScript.totalDuration(for: facts(ordinal: 4))
        XCTAssertGreaterThan(first, second)
        XCTAssertGreaterThan(second, later)
        XCTAssertEqual(first, 15, accuracy: 1)
        XCTAssertEqual(second, 10, accuracy: 1)
        XCTAssertEqual(later, 6, accuracy: 0.6)
    }

    func testBedtimeIsSlower() {
        let day = StoryPreparationScript.totalDuration(for: facts(ordinal: 5))
        let night = StoryPreparationScript.totalDuration(for: facts(ordinal: 5, bedtime: true))
        XCTAssertEqual(night, day * StoryPreparationScript.bedtimeScale, accuracy: 0.001)
    }

    func testTheCoverStays() {
        XCTAssertEqual(StoryPreparationScript.steps(for: facts()).last?.hold, 0)
    }

    func testTheFirstStoryIsNeverSkippable() {
        XCTAssertNil(StoryPreparationScript.skipDelay(for: facts(ordinal: 1)))
        XCTAssertNil(StoryPreparationScript.skipDelay(for: facts(ordinal: 6, firstRun: true)))
        XCTAssertEqual(StoryPreparationScript.skipDelay(for: facts(ordinal: 3)), 2)
        XCTAssertEqual(StoryPreparationScript.skipDelay(for: facts(ordinal: 4)), 1)
    }

    // MARK: - İlk cümle

    func testTheFirstSentenceIsTheStorysOwn() {
        XCTAssertEqual(StoryPreparationScript.firstSentence(of: "  Ela uyandı. Sonra pencereye koştu."), "Ela uyandı.")
        XCTAssertEqual(StoryPreparationScript.firstSentence(of: "Ne güzel bir gün! Ela gülümsedi."), "Ne güzel bir gün!")
        XCTAssertEqual(StoryPreparationScript.firstSentence(of: "Noktasız bir cümle"), "Noktasız bir cümle")
    }

    func testALongFirstSentenceIsCutAtAWord() {
        let long = String(repeating: "uzun kelime ", count: 20) + "son."
        let cut = StoryPreparationScript.firstSentence(of: long)
        XCTAssertTrue(cut.hasSuffix("…"))
        XCTAssertLessThanOrEqual(cut.count, StoryPreparationScript.firstSentenceLimit + 1)
        XCTAssertTrue(long.hasPrefix(String(cut.dropLast())), "kelime ortasından kesilmemeli")
        XCTAssertTrue(cut.dropLast().hasSuffix("kelime") || cut.dropLast().hasSuffix("uzun"))
    }

    // MARK: - Masaldan

    func testFactsComeFromTheBuiltStory() {
        var story = ReaderFixtures.textStory(pages: 2)
        story.pages[0].text = "Ela bir tohum buldu. Sonra ekti."
        story.pages[1].words = [StoryWord(id: "w", term: "tohum", meaning: "", surface: "tohum")]
        story.origin = StoryOrigin(
            seed: "s", storyIdeaID: nil, blueprintID: "bp", settingID: "set", companionID: "comp",
            discoveryID: "disc", fingerprint: "f", catalogVersion: "v", worldID: nil,
            modeID: "learning", selectionStrategy: "direct", ageBand: "5-6", subOptionID: nil)
        let f = PreparationFacts(story: story, childName: "Ela", companion: nil, familyName: nil,
                                 ordinal: 0, isFirstRun: false, isBedtime: false)
        XCTAssertEqual(f.mode, .learning)
        XCTAssertTrue(f.hasNewWord)
        XCTAssertEqual(f.firstSentence, "Ela bir tohum buldu.")
        XCTAssertEqual(f.pageCount, 2)
        XCTAssertEqual(f.storyOrdinal, 1)
    }
}
