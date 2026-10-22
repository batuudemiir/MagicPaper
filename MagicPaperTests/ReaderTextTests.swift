import XCTest
@testable import MagicPaper

/// Masal metninin sayfada dizilişi (21 Ekim 2026): yaş bandı, nefes satırları,
/// cümle takibi, çocuğun adı ve ses kelimeleri.
final class ReaderTextTests: XCTestCase {

    func testAgeBandPicksLayout() {
        XCTAssertEqual(ReaderTextLayout(ageBand: "3-4"), .breath)
        XCTAssertEqual(ReaderTextLayout(ageBand: "5-6"), .breath)
        XCTAssertEqual(ReaderTextLayout(ageBand: "7-8"), .paragraphs)
        XCTAssertEqual(ReaderTextLayout(ageBand: "9-10"), .paragraphs)
        // Bandı olmayan eski masal paragraf düzeninde açılır.
        XCTAssertEqual(ReaderTextLayout(ageBand: nil), .paragraphs)
        XCTAssertEqual(ReaderTextLayout(ageBand: "bozuk"), .paragraphs)
    }

    func testBreathLinesPutEachSentenceOnItsOwnLine() {
        let lines = ReaderText.breathLines(of: ["Deniz pencerenin önünde oturuyordu. Ay ışığı odaya süzüldü."])
        XCTAssertEqual(lines, [["Deniz pencerenin önünde oturuyordu.", "Ay ışığı odaya süzüldü."]])
    }

    func testDialogueAttributionStaysOnTheSameLine() {
        let lines = ReaderText.breathLines(of: ["\u{201C}Gerçekten mi?\u{201D} dedi Deniz. Ragi geldi."])
        XCTAssertEqual(lines, [["\u{201C}Gerçekten mi?\u{201D} dedi Deniz.", "Ragi geldi."]])
    }

    func testBreathLinesKeepParagraphsApart() {
        let lines = ReaderText.breathLines(of: ["Bir.", "İki. Üç."])
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines[1].count, 2)
    }

    func testReadAlongFindsTheSpokenSentence() {
        let paragraphs = ["Deniz oturuyordu. Ragi geldi.", "Yıldızlar şarkı söyledi."]
        // "Ragi" ilk paragrafın 18. konumunda başlıyor; 19 onun içinde.
        let mark = ReaderText.readAlongMark(paragraphs: paragraphs, spokenLocation: 19)
        XCTAssertEqual(mark?.paragraph, 0)
        XCTAssertEqual(mark?.start, 18)
        XCTAssertEqual(mark?.end, ("Deniz oturuyordu. Ragi geldi." as NSString).length)
    }

    func testReadAlongCountsTheParagraphBreak() {
        let paragraphs = ["Bir iki.", "Üç dört."]
        // İkinci paragraf "\n\n" sonrasında başlar: 8 + 2 = 10.
        let mark = ReaderText.readAlongMark(paragraphs: paragraphs, spokenLocation: 10)
        XCTAssertEqual(mark?.paragraph, 1)
        XCTAssertEqual(mark?.start, 0)
        XCTAssertNil(ReaderText.readAlongMark(paragraphs: paragraphs, spokenLocation: 500))
    }

    func testNameMatchesWholeWordsOnly() {
        let text = "Can, Canavar'ı gördü. Can'ın sesi titredi."
        let ranges = ReaderText.nameRanges(of: "Can", in: text)
        XCTAssertEqual(ranges.map { String(text[$0]) }, ["Can", "Can"])
    }

    func testNameIsCaseInsensitiveInTurkish() {
        let text = "İREM gülümsedi."
        XCTAssertEqual(ReaderText.nameRanges(of: "İrem", in: text).count, 1)
        XCTAssertTrue(ReaderText.nameRanges(of: "  ", in: text).isEmpty)
    }

    func testSoundWordsAreMarkedOneByOne() {
        let text = "Yağmur pıt, pıt, pıt diye yağdı. Dere şırıl şırıl aktı."
        let found = ReaderText.soundRanges(in: text).map { String(text[$0]) }
        XCTAssertEqual(found, ["pıt", "pıt", "pıt", "şırıl", "şırıl"])
    }

    func testOrdinaryWordsAreNotSounds() {
        XCTAssertTrue(ReaderText.soundRanges(in: "Yavaş yavaş eve döndü.").isEmpty)
    }

    func testDialogueStartsWithQuoteOrDash() {
        XCTAssertTrue(ReaderText.isDialogue("\u{201C}Gerçekten mi?\u{201D} dedi Deniz."))
        XCTAssertTrue(ReaderText.isDialogue("— Gel buraya!"))
        XCTAssertFalse(ReaderText.isDialogue("Deniz gülümsedi."))
    }
}
