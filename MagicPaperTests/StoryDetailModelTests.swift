import XCTest
@testable import MagicPaper

/// Masal detayı ve raf süzgeci: süre, alıntı, mod.
@MainActor
final class StoryDetailModelTests: XCTestCase {

    // MARK: Süre

    func testReadingMinutesFollowReadAloudPace() {
        XCTAssertEqual(Self.story(words: 450).mpReadingMinutes, 5)
        XCTAssertEqual(Self.story(words: 90).mpReadingMinutes, 1)
    }

    func testReadingMinutesNeverZero() {
        XCTAssertEqual(Self.story(words: 0).mpReadingMinutes, 1)
        XCTAssertEqual(Self.story(words: 20).mpReadingMinutes, 1)
    }

    // MARK: Alıntı

    func testExcerptSkipsDialogueAndKeepsWholeSentences() {
        let story = Self.story(firstPage: """
        “Bu da ne?” diye fısıldadı Yeliz.

        Akşam bahçeye inerken ay çoktan çıkmıştı. Fener sallanıyordu. Kıpır yanındaydı.
        """)
        let excerpt = story.mpExcerpt
        XCTAssertEqual(excerpt?.hasPrefix("Akşam bahçeye"), true, excerpt ?? "nil")
        XCTAssertEqual(excerpt?.last, ".", "cümle ortasında kesilmemeli")
        XCTAssertFalse(excerpt?.contains("“") ?? true)
    }

    func testExcerptRespectsLimitButKeepsFirstSentence() {
        let long = String(repeating: "uzun ", count: 60) + "cümle."
        let story = Self.story(firstPage: long + " İkinci cümle.")
        let excerpt = story.mpExcerpt ?? ""
        XCTAssertTrue(excerpt.hasSuffix("cümle."), "ilk cümle sınırı aşsa da tek başına gösterilir")
        XCTAssertFalse(excerpt.contains("İkinci"))
    }

    func testExcerptNilWhenOnlyDialogue() {
        XCTAssertNil(Self.story(firstPage: "“Merhaba!” dedi.").mpExcerpt)
        XCTAssertNil(Self.story(firstPage: "").mpExcerpt)
    }

    // MARK: Mod ve süzgeç

    func testModeComesFromOrigin() {
        XCTAssertEqual(Self.story(mode: "bedtime").mpMode, .bedtime)
        XCTAssertNil(ReaderFixtures.textStory(pages: 2).mpMode)
        XCTAssertNil(Self.story(mode: "surprise").mpMode, "bilinmeyen mod yok sayılır")
    }

    func testNoFiltersWhenShelfHasOneMode() {
        let shelf = [Self.story(mode: "bedtime"), Self.story(mode: "bedtime")]
        XCTAssertTrue(MPShelfFilter.available(in: shelf).isEmpty)
    }

    /// Süzgeçler ekran sırasıyla (K5): Uyku öncesi, Yeni şeyler öğrenelim,
    /// Maceraya çıkalım. `"growth"` 3 Ekim 2026 öncesi kayıtların adı.
    func testFiltersListPresentModesInFixedOrder() {
        let shelf = [Self.story(mode: "adventure"), Self.story(mode: "growth"),
                     Self.story(mode: "bedtime"), ReaderFixtures.textStory(pages: 2)]
        XCTAssertEqual(MPShelfFilter.available(in: shelf),
                       [.all, .mode(.bedtime), .mode(.learning), .mode(.adventure)])
    }

    func testFilterAdmitsOnlyItsMode() {
        let bedtime = Self.story(mode: "bedtime")
        let learning = Self.story(mode: "growth")
        XCTAssertTrue(MPShelfFilter.mode(.bedtime).admits(bedtime))
        XCTAssertFalse(MPShelfFilter.mode(.bedtime).admits(learning))
        XCTAssertTrue(MPShelfFilter.all.admits(learning))
    }

    /// Eski ad ve yeni ad aynı rafta tek bir süzgeç olur.
    func testOldAndNewLearningStoriesShareOneFilter() {
        let shelf = [Self.story(mode: "growth"), Self.story(mode: "learning")]
        XCTAssertTrue(MPShelfFilter.available(in: shelf).isEmpty, "tek mod: süzgeç yok")
        XCTAssertTrue(shelf.allSatisfy(MPShelfFilter.mode(.learning).admits))
        XCTAssertEqual(Self.story(mode: "growth").mpMode, .learning)
    }

    // MARK: Yardımcılar

    private static func story(words: Int) -> Story {
        story(firstPage: Array(repeating: "kelime", count: words).joined(separator: " "))
    }

    private static func story(firstPage text: String) -> Story {
        var story = ReaderFixtures.textStory(pages: 1)
        story.pages[0].text = text
        return story
    }

    private static func story(mode: String) -> Story {
        var story = ReaderFixtures.textStory(pages: 2)
        story.origin = StoryOrigin(
            seed: "s", storyIdeaID: nil, blueprintID: "b", settingID: "st",
            companionID: "c", discoveryID: "d", fingerprint: "f", catalogVersion: "v",
            worldID: "orman", modeID: mode, selectionStrategy: "direct", ageBand: "5-6"
        )
        return story
    }
}
