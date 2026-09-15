import XCTest
@testable import StoryEngine

/// Locative + the relative `-ki`, and the five title families that depend on
/// the resolver being complete.
///
/// `BLUEPRINT_ARCHITECTURE.md` §9 makes this a ship gate: "Title families
/// cannot ship until the resolver covers GEN, LOC, DAT, ACC with correct
/// buffer consonants and proper-noun detection." The four cases were already
/// covered; `-daki` was not, and `T2_achievement` is built on it.
final class TurkishRelativeSuffixTests: XCTestCase {

    private func slot(
        _ value: String,
        proper: Bool = false,
        possessive: Bool = false
    ) -> TurkishTextRenderer.Slot {
        .init(value, isProperNoun: proper, hasPossessiveEnding: possessive)
    }

    // MARK: - Parsing

    func testEveryLocativeRelativeSpellingParses() {
        for spelling in ["daki", "deki", "taki", "teki", "ndaki", "ndeki", "ntaki", "nteki"] {
            XCTAssertEqual(
                TurkishSuffixRequest.parse(suffixSpelling: spelling),
                .locativeRelative,
                "'\(spelling)' should be read as locative + -ki"
            )
        }
    }

    func testRelativeSpellingSurvivesApostrophesAndTurkishUppercasing() {
        // `I` lowercases to `ı` in Turkish; a naive `.lowercased()` would turn
        // "DAKI" into "daki" on some locales and "dakı" on none, so pin it.
        for spelling in ["'daki", "\u{2019}daki", "DAKİ", "Deki"] {
            XCTAssertEqual(
                TurkishSuffixRequest.parse(suffixSpelling: spelling),
                .locativeRelative,
                "'\(spelling)' should normalise to a relative request"
            )
        }
    }

    func testCaseSpellingsStillParseAsCasesNotDerivations() {
        XCTAssertEqual(TurkishSuffixRequest.parse(suffixSpelling: "da"), .grammaticalCase(.locative))
        XCTAssertEqual(TurkishSuffixRequest.parse(suffixSpelling: "in"), .grammaticalCase(.genitive))
        XCTAssertEqual(TurkishSuffixRequest.parse(suffixSpelling: "ya"), .grammaticalCase(.dative))
    }

    func testGenitiveRelativeIsNotSilentlyAcceptedAsLocativeRelative() {
        // "-ninki" is a real suffix the resolver does not model. It must be
        // reported, not approximated — the whole point of the type.
        XCTAssertNil(TurkishSuffixRequest.parse(suffixSpelling: "ninki"))
        XCTAssertNil(TurkishSuffixRequest.parse(suffixSpelling: "ki"))
    }

    // MARK: - Surface forms

    func testRelativeInheritsVowelHarmony() {
        XCTAssertEqual(TurkishGrammar.apply(TurkishNoun("orman", isProperNoun: false), .locativeRelative), "ormandaki")
        XCTAssertEqual(TurkishGrammar.apply(TurkishNoun("ev", isProperNoun: false), .locativeRelative), "evdeki")
        XCTAssertEqual(TurkishGrammar.apply(TurkishNoun("göl", isProperNoun: false), .locativeRelative), "göldeki")
        XCTAssertEqual(TurkishGrammar.apply(TurkishNoun("bulut", isProperNoun: false), .locativeRelative), "buluttaki")
    }

    func testRelativeInheritsVoicingAssimilation() {
        // "fıstıkçı şahap" — a voiceless final consonant turns the d into t.
        XCTAssertEqual(TurkishGrammar.apply(TurkishNoun("kitap", isProperNoun: false), .locativeRelative), "kitaptaki")
        XCTAssertEqual(TurkishGrammar.apply(TurkishNoun("ağaç", isProperNoun: false), .locativeRelative), "ağaçtaki")
        XCTAssertEqual(TurkishGrammar.apply(TurkishNoun("raf", isProperNoun: false), .locativeRelative), "raftaki")
    }

    func testRelativeKeepsTheApostropheBeforeTheEndingNotAfterIt() {
        XCTAssertEqual(
            TurkishGrammar.apply(TurkishNoun("Fısıldayan Orman", isProperNoun: true), .locativeRelative),
            "Fısıldayan Orman'daki"
        )
    }

    func testRelativeTakesThePossessiveBuffer() {
        // Four shipped settings end in a third-person possessive and need -n-.
        XCTAssertEqual(
            TurkishGrammar.apply(
                TurkishNoun("Bulut Krallığı", isProperNoun: true, hasPossessiveEnding: true),
                .locativeRelative
            ),
            "Bulut Krallığı'ndaki"
        )
        XCTAssertEqual(
            TurkishGrammar.apply(
                TurkishNoun("Mercan Resifi", isProperNoun: true, hasPossessiveEnding: true),
                .locativeRelative
            ),
            "Mercan Resifi'ndeki"
        )
    }

    func testRelativeNeverSoftensTheFinalConsonant() {
        // -ki is consonant-initial via the locative, so "kitap" must stay hard:
        // "kitaptaki", never "kitabdaki".
        XCTAssertEqual(TurkishGrammar.apply(TurkishNoun("kitap", isProperNoun: false), .locativeRelative), "kitaptaki")
        XCTAssertEqual(TurkishGrammar.apply(TurkishNoun("kayık", isProperNoun: false), .locativeRelative), "kayıktaki")
    }

    func testRelativeIsInvariantAndDoesNotHarmoniseToKu() {
        // The vowel -ki follows is always the locative's a/e, so the rounded
        // "-kü" (dünkü) can never be reached from here.
        for word in ["gül", "orman", "köy", "kutu"] {
            XCTAssertTrue(
                TurkishGrammar.apply(TurkishNoun(word, isProperNoun: false), .locativeRelative).hasSuffix("ki"),
                "\(word) should end in an invariant -ki"
            )
        }
    }

    // MARK: - Sentence-initial capitalisation

    /// A slot's value carries the casing of the content record, which is right
    /// mid-sentence and wrong at the start of one. Found by reading generated
    /// prose: "…öte yana ulaştı. titrek bir ışık tam oradaydı."
    func testACommonNounIsCapitalisedWhenItStartsASentence() {
        let result = TurkishTextRenderer.render(
            "{{child.name}} ulaştı. {{thing}} tam oradaydı.",
            slots: [
                "child.name": slot("Yeliz", proper: true),
                "thing": slot("titrek bir ışık")
            ]
        )
        XCTAssertEqual(result.text, "Yeliz ulaştı. Titrek bir ışık tam oradaydı.")
    }

    func testTheSameValueStaysLowercaseMidSentence() {
        let result = TurkishTextRenderer.render(
            "Yeliz {{thing}} gördü.",
            slots: ["thing": slot("titrek bir ışık")]
        )
        XCTAssertEqual(result.text, "Yeliz titrek bir ışık gördü.")
    }

    /// The capital of `i` is `İ`. A locale-naive uppercase yields "Ince",
    /// which is the same defect the harmony table had for `I` / `ı`.
    func testCapitalisationUsesTurkishRules() {
        let result = TurkishTextRenderer.render(
            "Durdu. {{thing}} duyuldu.",
            slots: ["thing": slot("ince bir ses")]
        )
        XCTAssertEqual(result.text, "Durdu. İnce bir ses duyuldu.")
    }

    func testCapitalisationAppliesToTheInflectedForm() {
        let result = TurkishTextRenderer.render(
            "Durdu. {{thing}}'i aradı.",
            slots: ["thing": slot("ışık")]
        )
        XCTAssertEqual(result.text, "Durdu. Işığı aradı.")
    }

    func testAnOpeningQuoteDoesNotEndASentence() {
        // The word after `. "` still starts a sentence; the word after `ve "`
        // does not.
        XCTAssertTrue(TurkishTextRenderer.isAtSentenceStart("dedi. \""))
        XCTAssertTrue(TurkishTextRenderer.isAtSentenceStart(""))
        XCTAssertFalse(TurkishTextRenderer.isAtSentenceStart("ve "))
        XCTAssertFalse(TurkishTextRenderer.isAtSentenceStart("Yeliz ve "))
    }

    // MARK: - The five title families, rendered end to end

    func testT2AchievementRendersCleanly() {
        let result = TurkishTextRenderer.render(
            "{{child.name}}'in {{setting.name}}'daki Büyük Keşfi",
            slots: [
                "child.name": slot("Yeliz", proper: true),
                "setting.name": slot("Fısıldayan Orman", proper: true)
            ]
        )
        XCTAssertEqual(result.text, "Yeliz'in Fısıldayan Orman'daki Büyük Keşfi")
        XCTAssertTrue(result.isClean, "unrecognised: \(result.unrecognisedSuffixes)")
    }

    func testT2AchievementWithAPossessiveSetting() {
        let result = TurkishTextRenderer.render(
            "{{child.name}}'in {{setting.name}}'ndaki Büyük Keşfi",
            slots: [
                "child.name": slot("Demir", proper: true),
                "setting.name": slot("Bulut Krallığı", proper: true, possessive: true)
            ]
        )
        XCTAssertEqual(result.text, "Demir'in Bulut Krallığı'ndaki Büyük Keşfi")
        XCTAssertTrue(result.isClean)
    }

    func testT1PairingRendersCleanly() {
        let result = TurkishTextRenderer.render(
            "{{child.name}} ve {{setting.name}}'daki Gizemli Işık",
            slots: [
                "child.name": slot("Yeliz", proper: true),
                "setting.name": slot("Orman", proper: true)
            ]
        )
        XCTAssertEqual(result.text, "Yeliz ve Orman'daki Gizemli Işık")
        XCTAssertTrue(result.isClean)
    }

    func testT3SecretRendersCleanly() {
        let result = TurkishTextRenderer.render(
            "{{child.name}} ve {{object.name}}'nin Sırrı",
            slots: [
                "child.name": slot("Yeliz", proper: true),
                "object.name": slot("Kayıp Harita", proper: true)
            ]
        )
        XCTAssertEqual(result.text, "Yeliz ve Kayıp Harita'nın Sırrı")
        XCTAssertTrue(result.isClean)
    }

    func testT5JourneyRendersCleanly() {
        let result = TurkishTextRenderer.render(
            "{{setting.name}}'na Cesur Yolculuk",
            slots: ["setting.name": slot("Kristal Odası", proper: true, possessive: true)]
        )
        XCTAssertEqual(result.text, "Kristal Odası'na Cesur Yolculuk")
        XCTAssertTrue(result.isClean)
    }

    func testMisAuthoredRelativeSpellingIsCorrectedRatherThanPassedThrough() {
        // The author cannot know which setting will be substituted, so they
        // guess one spelling. Every guess must land on the same correct form.
        for spelling in ["daki", "deki", "taki", "teki", "ndaki"] {
            let result = TurkishTextRenderer.render(
                "{{setting.name}}'\(spelling) ışık",
                slots: ["setting.name": slot("Gece Bahçesi", proper: true, possessive: true)]
            )
            XCTAssertEqual(
                result.text, "Gece Bahçesi'ndeki ışık",
                "'\(spelling)' should be recomputed, not emitted"
            )
            XCTAssertTrue(result.isClean)
        }
    }

    func testCommonNounRelativeTakesNoApostrophe() {
        let result = TurkishTextRenderer.render(
            "{{companion.type}}'nin yanındaki {{object.name}}'daki iz",
            slots: [
                "companion.type": slot("tilki"),
                "object.name": slot("kütük")
            ]
        )
        // Capitalised because the token is at position 0: a common noun that
        // opens a sentence is still the start of a sentence.
        XCTAssertEqual(result.text, "Tilkinin yanındaki kütükteki iz")
        XCTAssertTrue(result.isClean)
    }
}
