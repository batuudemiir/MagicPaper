import XCTest
@testable import MagicPaper

/// "Yeni kelimelerim" kartındaki masal cümlesi (21 Ekim 2026,
/// `docs/Kelime_Plani_kitapokur.md` A): kelime, geçtiği cümleyle gösterilir.
final class VocabularySentenceTests: XCTestCase {

    private func sentence(_ surface: String, in text: String) -> String? {
        MPVocabulary.sentence(containing: surface, in: text)
    }

    func testOnlyTheSentenceWithTheWordIsTaken() {
        let text = "Ragi uyandı. Ragi feneri yakıp mağaraya girdi. Içerisi serindi."
        XCTAssertEqual(sentence("feneri", in: text), "Ragi feneri yakıp mağaraya girdi.")
    }

    func testALastSentenceWithoutAFullStopIsFound() {
        XCTAssertEqual(sentence("usulca", in: "Kapı açıldı. Kedi usulca içeri girdi"),
                       "Kedi usulca içeri girdi")
    }

    func testDialogueIsNotSplitAtItsDash() {
        let text = "Ragi durdu. — Bak, fener! dedi Ragi. Ada güldü."
        XCTAssertEqual(sentence("fener", in: text), "— Bak, fener! dedi Ragi.")
    }

    func testAParagraphBreakEndsASentence() {
        let text = "Orman uyurken\n\nAda feneri buldu."
        XCTAssertEqual(sentence("feneri", in: text), "Ada feneri buldu.")
        XCTAssertEqual(sentence("Orman", in: text), "Orman uyurken")
    }

    func testTurkishCaseIsFoldedTheTurkishWay() {
        XCTAssertEqual(sentence("ışık", in: "Işık söndü. Ada uyudu."), "Işık söndü.")
        XCTAssertNil(sentence("ışık", in: "İşık söndü."))
    }

    func testAMissingWordGivesNoSentence() {
        XCTAssertNil(sentence("fener", in: "Ada uyudu."))
        XCTAssertNil(sentence("", in: "Ada uyudu."))
    }

    func testAShortSentenceIsPreferredToALongOne() {
        let long = "Fener " + Array(repeating: "çok", count: 40).joined(separator: " ") + " uzun bir cümlede parladı."
        let text = long + " Fener söndü."
        XCTAssertEqual(sentence("Fener", in: text), "Fener söndü.")
    }

    func testALongSentenceIsCutAtAWordAndKeepsTheWord() throws {
        let words = Array(repeating: "yavaşça", count: 30).joined(separator: " ")
        let text = "\(words) Ragi feneri aldı ve \(words) yürüdü."
        let found = try XCTUnwrap(sentence("feneri", in: text))
        XCTAssertLessThanOrEqual(found.count, MPVocabulary.sentenceLimit + 4) // "… " ve " …"
        XCTAssertTrue(found.contains("feneri"))
        XCTAssertTrue(found.hasPrefix("… "))
        XCTAssertTrue(found.hasSuffix(" …"))
        XCTAssertFalse(found.contains("yavaşç "), "kelimenin ortasından kesilmez")
    }

    func testALongSentenceKeepsItsStartWhenTheWordIsNearIt() throws {
        let tail = Array(repeating: "uzun", count: 50).joined(separator: " ")
        let found = try XCTUnwrap(sentence("feneri", in: "Ragi feneri aldı \(tail)."))
        XCTAssertTrue(found.hasPrefix("Ragi feneri aldı"))
        XCTAssertTrue(found.hasSuffix(" …"))
    }

    func testCollectedWordsCarryTheSentenceOfTheirFirstPage() {
        let fener = StoryWord(id: "w_fener", term: "fener", meaning: "Küçük ışık.", surface: "feneri")
        var page = MagicPaper.StoryPage(title: "", text: "Gece oldu. Ada feneri yaktı.", imagePrompt: "")
        page.words = [fener]
        var story = MagicPaper.Story(title: "Fener", childName: "Ada", theme: .fantasy, language: .turkish,
                                     status: .completed, pages: [page])
        story.lastReadPage = 0
        story.lastReadAt = Date()

        let words = MPVocabulary.collectedWords(in: [story])
        XCTAssertEqual(words.first?.sentence, "Ada feneri yaktı.")
    }
}
