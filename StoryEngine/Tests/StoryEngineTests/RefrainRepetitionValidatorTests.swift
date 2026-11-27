import XCTest
@testable import StoryEngine

/// RepetitionValidator and the declared refrain (work package `p_repeated_line`,
/// approved 14 October 2026; validator step approved 24 November 2026).
///
/// Research rule m003: the general repetition gate is not loosened. Only a
/// declared, slot-free refrain line is exempt; every other repeat still counts.
final class RefrainRepetitionValidatorTests: XCTestCase {
    private let clock = FixedClock()

    /// Five words, so with the default 5-gram window it repeats as a whole.
    private let refrain = "Yıldızlar yavaşça söner, uyku gelir."
    private let finalRefrain = "Yıldızlar söndü, uyku geldi artık."

    /// Seven pages whose own sentences share no five-word run.
    private let ownLines = [
        "Mavi bir kuş pencerenin kenarına kondu ve kanatlarını topladı.",
        "Bahçedeki eski kuyunun başında küçük bir fener parlıyordu.",
        "Tarçın ıslak çimenlerin üstünde sessizce yuvarlandı ve güldü.",
        "Uzaktaki tepede bir değirmen ağır ağır dönmeye başladı.",
        "Annesinin ördüğü kırmızı atkı yatağın ucunda bekliyordu.",
        "Bulutlar ayın önünden süzülüp kuzeye doğru yol aldı.",
        "Oda ılık ve sakindi, perdeler hafifçe kıpırdıyordu."
    ]

    private func story(_ texts: [String]) throws -> (Story, StoryRequest, ResolvedTemplate) {
        let (base, request, template) = try StoryFixtures.completeStory(pageCount: texts.count)
        var story = base
        for (page, text) in zip(base.pages.sorted { $0.index < $1.index }, texts) {
            story = try story.applying([.replacePageText(pageID: page.id, title: nil, text: text)], at: clock.now())
        }
        return (story, request, template)
    }

    /// Refrain on pages 2, 4, 6 (indices 1, 3, 5), changed line on the last.
    private func refrainTexts() -> [String] {
        ownLines.enumerated().map { index, line in
            if [1, 3, 5].contains(index) { return "\(line) \(refrain)" }
            if index == ownLines.count - 1 { return "\(line) \(finalRefrain)" }
            return line
        }
    }

    private func issues(_ texts: [String], refrains: [String]? = nil) throws -> [ValidationIssue] {
        let (story, request, template) = try story(texts)
        let context = refrains.map {
            ValidationContext(story: story, template: template, request: request, declaredRefrains: $0)
        } ?? ValidationContext(story: story, template: template, request: request)
        return RepetitionValidator().validate(context)
    }

    // (1) A declared refrain repeating across pages is not accidental repetition.

    func testADeclaredRefrainIsNotARepeatedPhrase() throws {
        let texts = refrainTexts()
        // Sanity: undeclared, the very same story is flagged, so the test bites.
        XCTAssertTrue(try issues(texts).contains { $0.code == "repeated_phrases" })

        let declared = try issues(texts, refrains: [refrain, finalRefrain])
        XCTAssertFalse(declared.contains { $0.code == "repeated_phrases" },
                       declared.map(\.message).joined(separator: "\n"))
    }

    // (2) An undeclared repeat in the same story is still flagged.

    func testAnUndeclaredRepeatBesideTheRefrainIsStillFlagged() throws {
        var texts = refrainTexts()
        let accident = "Rüzgar kapının önünde usulca şarkı söyledi."
        texts[0] += " \(accident)"
        texts[4] += " \(accident)"

        let found = try issues(texts, refrains: [refrain, finalRefrain])
        let repeated = try XCTUnwrap(found.first { $0.code == "repeated_phrases" })
        XCTAssertTrue(repeated.message.contains("şarkı"), repeated.message)
        XCTAssertFalse(repeated.message.contains("yavaşça"), "The refrain itself leaked into: \(repeated.message)")
    }

    /// Only the declared line is exempt, not its words: the same five words
    /// inside a longer sentence on two pages are an ordinary repeat.
    func testTheRefrainsWordsInsideAnotherSentenceStillCount() throws {
        var texts = ownLines
        texts[0] += " Annem dedi ki yıldızlar yavaşça söner, uyku gelir sonra."
        texts[2] += " Dedem de yıldızlar yavaşça söner, uyku gelir diye fısıldadı."

        let found = try issues(texts, refrains: [refrain, finalRefrain])
        XCTAssertTrue(found.contains { $0.code == "repeated_phrases" })
    }

    /// Refrains are slot-free (CatalogIntegrity `refrain_has_slot`); a line
    /// that still carries a slot is not exempt here either.
    func testASlotBearingLineIsNotExempt() throws {
        let slotted = "{{child}} yavaşça uyur, ay bakar."
        let texts = ownLines.enumerated().map { index, line in
            [1, 3, 5].contains(index) ? "\(line) \(slotted)" : line
        }
        let found = try issues(texts, refrains: [slotted])
        XCTAssertTrue(found.contains { $0.code == "repeated_phrases" })
    }

    // (3) Without a refrain the validator behaves exactly as before.

    func testWithoutARefrainNothingChanges() throws {
        var repeating = ownLines
        repeating[1] += " Rüzgar kapının önünde usulca şarkı söyledi."
        repeating[5] += " Rüzgar kapının önünde usulca şarkı söyledi."

        for texts in [ownLines, repeating, refrainTexts()] {
            let before = try issues(texts)
            XCTAssertEqual(try issues(texts, refrains: []), before)
        }
        XCTAssertFalse(try issues(ownLines).contains { $0.code == "repeated_phrases" })
        XCTAssertTrue(try issues(repeating).contains { $0.code == "repeated_phrases" })
    }

    func testTheContextDefaultsToNoRefrain() throws {
        let (story, request, template) = try story(ownLines)
        XCTAssertEqual(ValidationContext(story: story, template: template, request: request).declaredRefrains, [])
    }

    /// The spec hands the validator both of its lines.
    func testRefrainSpecDeclaresBothLines() {
        let spec = RefrainSpec(line: refrain, pages: [2, 4, 6], finalLine: finalRefrain, finalPage: 7)
        XCTAssertEqual(spec.declaredLines, [refrain, finalRefrain])
    }
}
