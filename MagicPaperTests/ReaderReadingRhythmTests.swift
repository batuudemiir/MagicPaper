import XCTest
@testable import MagicPaper

final class ReaderReadingRhythmTests: XCTestCase {
    private let prose = "İrem geldi. Kapı açıldı. Kuş uçtu. Gün bitti."

    func testOpeningAndFlowGroupOriginalSentencesWithoutRewriting() throws {
        let opening = try blocks("hook")
        let flow = try blocks("attempt")
        XCTAssertEqual(opening.count, 3)
        XCTAssertEqual(flow.count, 2)
        XCTAssertEqual(opening.map { $0.text }.joined(), prose)
        XCTAssertEqual(flow.map { $0.text }.joined(), prose)
        XCTAssertTrue(opening.allSatisfy { !$0.quiet })
    }

    func testQuietEndingAndBreathPreserveSourceUnits() throws {
        let older = try blocks("resolution")
        XCTAssertEqual(older.count, 3)
        XCTAssertEqual(older.filter(\.quiet).count, 1)
        let young = try blocks("bedtime_transition", layout: .breath)
        XCTAssertEqual(young.count, ReaderText.sentenceRanges(in: prose).count)
        XCTAssertTrue(young.last!.quiet)
        XCTAssertEqual(young.map { $0.text }.joined(), prose)
    }

    func testAuthoredSuffixOccursOnceAndTakesPrecedence() throws {
        let text = "İrem geldi. Gün bitti. Kuş uyudu. Gün bitti."
        let reading = StoryPageReading(role: "resolution", refrain: "Kuş uyudu. Gün bitti.")
        let groups = try XCTUnwrap(ReaderReadingRhythm.blocks(paragraphs: [text], reading: reading, layout: .paragraphs))
        XCTAssertEqual(groups.filter(\.quiet).count, 1)
        XCTAssertEqual(groups.last?.text, "Kuş uyudu. Gün bitti.")
        XCTAssertEqual(groups.compactMap { $0.text }.joined(), text)
    }

    func testBreathMultiSentenceRefrainKeepsSentenceUnitsAndOneBoundaryGap() throws {
        let text = "İrem geldi. Gün bitti. Kuş uyudu. Gün bitti."
        let reading = StoryPageReading(role: "resolution", refrain: "Kuş uyudu. Gün bitti.")
        let groups = try XCTUnwrap(ReaderReadingRhythm.blocks(paragraphs: [text], reading: reading, layout: .breath))
        let sentences = ReaderText.sentenceRanges(in: text)
        XCTAssertEqual(groups.count, sentences.count)
        XCTAssertEqual(groups.map(\.text).joined(), text)
        XCTAssertEqual(groups.filter(\.quiet).count, 1)
        XCTAssertEqual(groups[2].kind, .refrain)
        XCTAssertEqual(groups[3].kind, .body)
        for index in groups.indices {
            XCTAssertEqual(groups[index].sourceRange.lowerBound, sentences[index].lowerBound)
            XCTAssertEqual(groups[index].sourceRange.upperBound,
                           index + 1 < sentences.count ? sentences[index + 1].lowerBound : text.utf16.count)
        }
    }

    func testParagraphBoundariesAndTurkishQuotedAttributionArePreserved() throws {
        let paragraphs = ["“Gerçekten mi?” dedi İrem. Sonra yürüdü.", "Kuş geldi. Gün bitti."]
        let groups = try XCTUnwrap(ReaderReadingRhythm.blocks(paragraphs: paragraphs, reading: .init(role: "attempt"), layout: .paragraphs))
        for index in paragraphs.indices {
            XCTAssertEqual(groups.filter { $0.sourceParagraph == index }.compactMap { $0.text }.joined(), paragraphs[index])
        }
        XCTAssertEqual(groups.first?.sourceRange.lowerBound, 0)
    }

    func testUnknownVersionsRolesEmptyAndInvalidRefrainFallBackSafely() throws {
        XCTAssertNil(ReaderReadingRhythm.blocks(paragraphs: [prose], reading: nil, layout: .paragraphs))
        XCTAssertNil(ReaderReadingRhythm.blocks(paragraphs: [prose], reading: .init(role: "future"), layout: .paragraphs))
        XCTAssertNil(ReaderReadingRhythm.blocks(paragraphs: [prose], reading: .init(role: "hook", schemaVersion: 2), layout: .paragraphs))
        XCTAssertNil(ReaderReadingRhythm.blocks(paragraphs: [""], reading: .init(role: "hook"), layout: .paragraphs))
        let invalid = ReaderReadingRhythm.blocks(paragraphs: [prose], reading: .init(role: "attempt", refrain: "ün bitti."), layout: .paragraphs)
        XCTAssertEqual(invalid, try blocks("attempt"))
        let single = ReaderReadingRhythm.blocks(paragraphs: ["İrem geldi."], reading: .init(role: "resolution"), layout: .paragraphs)
        XCTAssertEqual(single?.count, 1)
        XCTAssertFalse(single!.first!.quiet)
    }

    func testUTF16RangesAndSpeechIntersectionRejectInvalidBoundaries() throws {
        let source = ["😀 İrem geldi. Kuş uçtu. Gün bitti."]
        let groups = try XCTUnwrap(ReaderReadingRhythm.blocks(paragraphs: source, reading: .init(role: "hook"), layout: .paragraphs))
        XCTAssertEqual(groups.compactMap { $0.text }.joined(), source[0])
        let final = groups.last!
        let mark = ReadAlongMark(paragraph: 0, start: final.sourceRange.lowerBound, end: final.sourceRange.upperBound)
        XCTAssertEqual(final.localMark(mark, in: source), 0..<final.sourceRange.count)
        XCTAssertEqual(groups[0].localMark(mark, in: source), groups[0].sourceRange.count..<groups[0].sourceRange.count)
        for range in [-1..<2, 1..<2, 0..<Int.max] {
            let bad = ReaderRhythmBlock(text: "", sourceParagraph: 0, sourceRange: range, kind: .body)
            XCTAssertNil(ReaderRhythmBlock.substring(source, paragraph: 0, range: range))
            XCTAssertNil(bad.localMark(mark, in: source))
        }
    }

    func testCombiningAndJoinedEmojiInteriorBoundariesAreRejected() {
        let cases: [(String, Range<Int>)] = [("e\u{0301} geldi.", 1..<2), ("👨‍👩‍👧 geldi.", 2..<3)]
        for (text, invalid) in cases {
            let paragraphs = [text]
            let whole = 0..<text.utf16.count
            XCTAssertEqual(ReaderRhythmBlock.substring(paragraphs, paragraph: 0, range: whole), text)
            XCTAssertNil(ReaderRhythmBlock.substring(paragraphs, paragraph: 0, range: invalid))
            let bad = ReaderRhythmBlock(text: "", sourceParagraph: 0, sourceRange: invalid, kind: .body)
            XCTAssertNil(bad.localMark(.init(paragraph: 0, start: 0, end: whole.upperBound), in: paragraphs))
            let block = ReaderRhythmBlock(text: text, sourceParagraph: 0, sourceRange: whole, kind: .body)
            XCTAssertNil(block.localMark(.init(paragraph: 0, start: invalid.lowerBound, end: invalid.upperBound), in: paragraphs))
        }
    }

    func testSpeechProjectionKeepsFuturePastAndOriginalBreathWordOffsets() throws {
        let source = ["İrem geldi. Kuş uçtu. Gün bitti.", "😀 İrem uyudu."]
        let groups = try XCTUnwrap(ReaderReadingRhythm.blocks(paragraphs: source, reading: .init(role: "hook"), layout: .paragraphs))
        let firstSentence = ReaderText.sentenceRanges(in: source[0])[0]
        let active = ReadAlongMark(paragraph: 0, start: firstSentence.lowerBound, end: firstSentence.upperBound)
        XCTAssertEqual(groups[0].localMark(active, in: source), firstSentence)
        XCTAssertNil(groups[1].localMark(active, in: source))
        let secondParagraph = ReadAlongMark(paragraph: 1, start: 3, end: 7)
        XCTAssertEqual(groups[0].localMark(secondParagraph, in: source), groups[0].sourceRange.count..<groups[0].sourceRange.count)
        XCTAssertEqual(groups.last?.localMark(secondParagraph, in: source), 3..<7)
        XCTAssertNil(groups[0].localMark(.init(paragraph: 0, start: -1, end: 2), in: source))
        let location = (source[0] as NSString).range(of: "Gün").location
        let word = try XCTUnwrap(ReaderText.breathWordMark(paragraphs: source, location: location, length: 3))
        let sentence = ReaderText.sentenceRanges(in: source[0])[word.line]
        let younger = try XCTUnwrap(ReaderReadingRhythm.blocks(paragraphs: source, reading: .init(role: "resolution"), layout: .breath))
        let selected = try XCTUnwrap(younger.first { $0.sourceParagraph == word.paragraph && $0.sourceRange.contains(location) })
        XCTAssertEqual(selected.localMark(.init(paragraph: word.paragraph, start: sentence.lowerBound + word.start,
                                                end: sentence.lowerBound + word.end), in: source), 0..<3)
    }

    func testOddWhitespaceEmojiAndCombiningGraphemesRetainContiguousCoverage() throws {
        let source = ["  😀 İrem geldi.  Kuş uçtu.\tGün bitti.  ", "İ\u{0307}rem baktı. 👨‍👩‍👧 aile uyudu.\t"]
        for layout in [ReaderTextLayout.paragraphs, .breath] {
            for role in ["hook", "attempt", "resolution"] {
                let groups = try XCTUnwrap(ReaderReadingRhythm.blocks(paragraphs: source, reading: .init(role: role), layout: layout))
                for paragraph in source.indices {
                    let pieces = groups.filter { $0.sourceParagraph == paragraph }
                    XCTAssertFalse(pieces.isEmpty)
                    XCTAssertEqual(pieces.map(\.text).joined(), source[paragraph])
                    var boundary = 0
                    for piece in pieces {
                        XCTAssertEqual(piece.sourceRange.lowerBound, boundary)
                        XCTAssertEqual(piece.text, ReaderRhythmBlock.substring(source, paragraph: paragraph, range: piece.sourceRange))
                        boundary = piece.sourceRange.upperBound
                    }
                    XCTAssertEqual(boundary, source[paragraph].utf16.count)
                }
            }
        }
    }

    func testEveryKnownRoleUsesBoundedGroups() throws {
        for role in ["hook", "discovery", "companion", "problem", "attempt", "challenge", "resolution", "celebration", "emotional_ending", "bedtime_transition"] {
            let resolved = try blocks(role)
            XCTAssertEqual(resolved.map(\.text).joined(), prose)
            XCTAssertTrue(resolved.allSatisfy { ReaderText.sentenceRanges(in: $0.text).count <= 2 })
        }
    }

    func testEligibilityUsesCompositionAccessibilityCompactAndFiniteGeometry() {
        XCTAssertTrue(ReaderReadingRhythm.isEligible(composition: .spot, accessibility: false, compactHeight: false, viewport: CGSize(width: 300, height: 400)))
        XCTAssertFalse(ReaderReadingRhythm.isEligible(composition: .scene, accessibility: false, compactHeight: false, viewport: CGSize(width: 300, height: 400)))
        XCTAssertFalse(ReaderReadingRhythm.isEligible(composition: .text, accessibility: true, compactHeight: false, viewport: CGSize(width: 300, height: 400)))
        XCTAssertFalse(ReaderReadingRhythm.isEligible(composition: .text, accessibility: false, compactHeight: true, viewport: CGSize(width: 300, height: 400)))
        XCTAssertFalse(ReaderReadingRhythm.isEligible(composition: .text, accessibility: false, compactHeight: false, viewport: .zero))
    }

    private func blocks(_ role: String, layout: ReaderTextLayout = .paragraphs) throws -> [ReaderRhythmBlock] {
        try XCTUnwrap(ReaderReadingRhythm.blocks(paragraphs: [prose], reading: .init(role: role), layout: layout))
    }
}
