import XCTest
@testable import StoryEngine

/// Cases are drawn from the shipped content wherever possible, so a passing
/// suite means the corpus renders correctly — not that an invented example does.
final class TurkishGrammarTests: XCTestCase {

    // MARK: - Helpers

    private func proper(_ text: String, possessive: Bool = false) -> TurkishNoun {
        TurkishNoun(text, isProperNoun: true, hasPossessiveEnding: possessive)
    }

    private func common(_ text: String, blocksSoftening: Bool = false) -> TurkishNoun {
        TurkishNoun(text, isProperNoun: false, blocksSoftening: blocksSoftening)
    }

    // MARK: - Regressions from the shipped corpus

    /// The eight `{{setting.name}}'nde` and five `{{setting.name}}'ne` usages in
    /// the V2 library. Both spellings fell through to literal passthrough and
    /// shipped as "Fısıldayan Orman'nde".
    func testSettingLocativeAndDative_theShippedRegression() {
        XCTAssertEqual(
            TurkishGrammar.inflect(proper("Fısıldayan Orman"), into: .locative),
            "Fısıldayan Orman'da"
        )
        XCTAssertEqual(
            TurkishGrammar.inflect(proper("Fısıldayan Orman"), into: .dative),
            "Fısıldayan Orman'a"
        )
        XCTAssertEqual(
            TurkishGrammar.inflect(proper("Gizli Bahçe"), into: .locative),
            "Gizli Bahçe'de"
        )
        XCTAssertEqual(
            TurkishGrammar.inflect(proper("Kristal Mağara"), into: .locative),
            "Kristal Mağara'da"
        )
    }

    /// The four shipped settings that really do end in a third-person
    /// possessive. These are the ones `'nde` was right for — which is why the
    /// buffer has to be declared rather than inferred.
    func testPossessiveStemSettingsTakeBufferN() {
        XCTAssertEqual(
            TurkishGrammar.inflect(proper("Bulut Krallığı", possessive: true), into: .locative),
            "Bulut Krallığı'nda"
        )
        XCTAssertEqual(
            TurkishGrammar.inflect(proper("Yıldız İstasyonu", possessive: true), into: .dative),
            "Yıldız İstasyonu'na"
        )
        XCTAssertEqual(
            TurkishGrammar.inflect(proper("Ay Yüzeyi", possessive: true), into: .locative),
            "Ay Yüzeyi'nde"
        )
        XCTAssertEqual(
            TurkishGrammar.inflect(proper("Mercan Resifi", possessive: true), into: .genitive),
            "Mercan Resifi'nin"
        )
    }

    /// "Karlı Vadi" ends in -i like "Ay Yüzeyi" but is not a possessive stem.
    /// If this pair ever renders the same way, the declaration has been lost.
    func testPossessiveLookalikeIsNotBuffered() {
        XCTAssertEqual(
            TurkishGrammar.inflect(proper("Karlı Vadi"), into: .locative),
            "Karlı Vadi'de"
        )
        XCTAssertEqual(
            TurkishGrammar.inflect(proper("Karlı Vadi"), into: .dative),
            "Karlı Vadi'ye"
        )
    }

    /// `{{companion.type}}'ye` in the V1 corpus rendered as "tilki'ye".
    /// Common nouns take no apostrophe.
    func testCommonNounsTakeNoApostrophe() {
        XCTAssertEqual(TurkishGrammar.inflect(common("tilki"), into: .dative), "tilkiye")
        XCTAssertEqual(TurkishGrammar.inflect(common("tilki"), into: .accusative), "tilkiyi")
        XCTAssertEqual(TurkishGrammar.inflect(common("baykuş"), into: .genitive), "baykuşun")
        XCTAssertEqual(TurkishGrammar.inflect(common("kaplumbağa"), into: .locative), "kaplumbağada")
    }

    // MARK: - Vowel harmony

    func testGenitiveHarmonyAcrossAllFourVowelClasses() {
        XCTAssertEqual(TurkishGrammar.inflect(proper("Yeliz"), into: .genitive), "Yeliz'in")     // front unrounded
        XCTAssertEqual(TurkishGrammar.inflect(proper("Orman"), into: .genitive), "Orman'ın")     // back unrounded
        XCTAssertEqual(TurkishGrammar.inflect(proper("Bulut"), into: .genitive), "Bulut'un")     // back rounded
        XCTAssertEqual(TurkishGrammar.inflect(proper("Gündüz"), into: .genitive), "Gündüz'ün")   // front rounded
    }

    func testAccusativeHarmony() {
        XCTAssertEqual(TurkishGrammar.inflect(proper("Yeliz"), into: .accusative), "Yeliz'i")
        XCTAssertEqual(TurkishGrammar.inflect(proper("Orman"), into: .accusative), "Orman'ı")
        XCTAssertEqual(TurkishGrammar.inflect(proper("Bulut"), into: .accusative), "Bulut'u")
        XCTAssertEqual(TurkishGrammar.inflect(proper("Gündüz"), into: .accusative), "Gündüz'ü")
    }

    func testDativeIsTwoWayNotFourWay() {
        XCTAssertEqual(TurkishGrammar.inflect(proper("Yeliz"), into: .dative), "Yeliz'e")
        XCTAssertEqual(TurkishGrammar.inflect(proper("Bulut"), into: .dative), "Bulut'a")
        XCTAssertEqual(TurkishGrammar.inflect(proper("Gündüz"), into: .dative), "Gündüz'e")
    }

    /// `I` is the capital of `ı` (back) and `İ` the capital of `i` (front).
    /// The previous table classified `I` as front, flipping harmony for any
    /// uppercase-stored name.
    func testDottedAndDotlessCapitalsHarmoniseOppositely() {
        XCTAssertEqual(TurkishGrammar.inflect(proper("IRMAK"), into: .genitive), "IRMAK'ın")
        XCTAssertEqual(TurkishGrammar.inflect(proper("İZMİR"), into: .genitive), "İZMİR'in")
    }

    // MARK: - Buffer consonants

    func testVowelFinalStemsTakeTheRightBuffer() {
        // genitive buffers with n, dative and accusative with y
        XCTAssertEqual(TurkishGrammar.inflect(proper("Mağara"), into: .genitive), "Mağara'nın")
        XCTAssertEqual(TurkishGrammar.inflect(proper("Mağara"), into: .dative), "Mağara'ya")
        XCTAssertEqual(TurkishGrammar.inflect(proper("Mağara"), into: .accusative), "Mağara'yı")
        // locative and ablative take none
        XCTAssertEqual(TurkishGrammar.inflect(proper("Mağara"), into: .locative), "Mağara'da")
        XCTAssertEqual(TurkishGrammar.inflect(proper("Mağara"), into: .ablative), "Mağara'dan")
    }

    func testFrontRoundedVowelFinalStem() {
        XCTAssertEqual(TurkishGrammar.inflect(proper("Köprü"), into: .genitive), "Köprü'nün")
        XCTAssertEqual(TurkishGrammar.inflect(proper("Köprü"), into: .dative), "Köprü'ye")
    }

    // MARK: - d / t assimilation

    func testLocativeAndAblativeAssimilateAfterVoicelessConsonants() {
        XCTAssertEqual(TurkishGrammar.inflect(common("kitap"), into: .locative), "kitapta")
        XCTAssertEqual(TurkishGrammar.inflect(common("köpek"), into: .locative), "köpekte")
        XCTAssertEqual(TurkishGrammar.inflect(common("ağaç"), into: .ablative), "ağaçtan")
        XCTAssertEqual(TurkishGrammar.inflect(common("orman"), into: .locative), "ormanda")
        XCTAssertEqual(TurkishGrammar.inflect(common("deniz"), into: .ablative), "denizden")
    }

    /// After a possessive buffer the preceding letter is -n-, which is voiced,
    /// so the ending is always d — even when the stem ends voiceless.
    func testPossessiveBufferForcesVoicedEnding() {
        XCTAssertEqual(
            TurkishGrammar.inflect(proper("Yıldız İstasyonu", possessive: true), into: .locative),
            "Yıldız İstasyonu'nda"
        )
    }

    // MARK: - Final-consonant softening

    func testRegularSofteningOnCommonNouns() {
        XCTAssertEqual(TurkishGrammar.inflect(common("kitap"), into: .accusative), "kitabı")
        XCTAssertEqual(TurkishGrammar.inflect(common("köpek"), into: .dative), "köpeğe")
        XCTAssertEqual(TurkishGrammar.inflect(common("ağaç"), into: .dative), "ağaca")
        XCTAssertEqual(TurkishGrammar.inflect(common("sincap"), into: .dative), "sincaba")
    }

    /// Turkish orthography does not soften proper nouns: "Sinop'a", not
    /// "Sinob'a". Child and setting names are proper nouns, so this protects
    /// every name in the product.
    func testProperNounsNeverSoften() {
        XCTAssertEqual(TurkishGrammar.inflect(proper("Sinop"), into: .dative), "Sinop'a")
        XCTAssertEqual(TurkishGrammar.inflect(proper("Mehmet"), into: .accusative), "Mehmet'i")
    }

    func testSingleSyllableWordsResistSoftening() {
        XCTAssertEqual(TurkishGrammar.inflect(common("at"), into: .accusative), "atı")
        XCTAssertEqual(TurkishGrammar.inflect(common("ot"), into: .accusative), "otu")
    }

    func testLoanwordsCanBlockSoftening() {
        XCTAssertEqual(
            TurkishGrammar.inflect(common("robot", blocksSoftening: true), into: .accusative),
            "robotu"
        )
        XCTAssertEqual(
            TurkishGrammar.inflect(common("robot", blocksSoftening: true), into: .dative),
            "robota"
        )
    }

    func testSofteningNeedsAVowelBeforeTheFinalConsonant() {
        // "Türk" — the k follows a consonant, so it does not soften.
        XCTAssertEqual(TurkishGrammar.inflect(common("türk"), into: .dative), "türke")
    }

    // MARK: - Suffix spelling to case

    func testEveryAuthoredSpellingResolvesToACase() {
        // The exact spellings counted in the shipped corpus.
        for spelling in ["nde", "ne", "nin", "ni", "da", "de", "ta", "te"] {
            XCTAssertNotNil(
                TurkishCase.parse(suffixSpelling: spelling),
                "\(spelling) should resolve to a case"
            )
        }
        XCTAssertEqual(TurkishCase.parse(suffixSpelling: "nde"), .locative)
        XCTAssertEqual(TurkishCase.parse(suffixSpelling: "ne"), .dative)
        XCTAssertEqual(TurkishCase.parse(suffixSpelling: "nin"), .genitive)
        XCTAssertEqual(TurkishCase.parse(suffixSpelling: "yi"), .accusative)
        XCTAssertEqual(TurkishCase.parse(suffixSpelling: "dan"), .ablative)
    }

    func testCopulaAndTyposAreNotCases() {
        // "'ydi" and "'dı" appear in V1; they are copulas, not case endings.
        XCTAssertNil(TurkishCase.parse(suffixSpelling: "ydi"))
        XCTAssertNil(TurkishCase.parse(suffixSpelling: "dı"))
        // The English possessive that leaked into underwater_friendship_002.
        XCTAssertNil(TurkishCase.parse(suffixSpelling: "s"))
    }

    // MARK: - Rendering

    private var yeliz: TurkishTextRenderer.Slot {
        .init("Yeliz", isProperNoun: true)
    }
    private var orman: TurkishTextRenderer.Slot {
        .init("Fısıldayan Orman", isProperNoun: true)
    }
    private var tilki: TurkishTextRenderer.Slot {
        .init("tilki", isProperNoun: false)
    }

    func testRendersTheShippedTemplateCorrectly() {
        let result = TurkishTextRenderer.render(
            "Birlikte başarmış olmanın verdiği sevinçle, {{setting.name}}'nde neşeyle güldüler.",
            slots: ["setting.name": orman]
        )
        XCTAssertEqual(
            result.text,
            "Birlikte başarmış olmanın verdiği sevinçle, Fısıldayan Orman'da neşeyle güldüler."
        )
        XCTAssertTrue(result.isClean)
    }

    func testRendersMultipleSlotsAndBareTokens() {
        let result = TurkishTextRenderer.render(
            "{{child.name}}, {{companion.name}}'yi aldı ve {{setting.name}}'ne yürüdü.",
            slots: [
                "child.name": yeliz,
                "companion.name": .init("Kıpır", isProperNoun: true),
                "setting.name": orman
            ]
        )
        XCTAssertEqual(result.text, "Yeliz, Kıpır'ı aldı ve Fısıldayan Orman'a yürüdü.")
        XCTAssertTrue(result.isClean)
    }

    func testMissingSlotIsReportedAndLeftVisible() {
        let result = TurkishTextRenderer.render(
            "{{child.name}} ve {{object.name}} birlikte.",
            slots: ["child.name": yeliz]
        )
        XCTAssertEqual(result.missingSlots, ["object.name"])
        // The raw token survives so the defect is visible rather than a hole.
        XCTAssertTrue(result.text.contains("{{object.name}}"))
        XCTAssertFalse(result.isClean)
    }

    /// `{{child.favoriteColor}}` appears 16 times in V1 and is undeclared at
    /// runtime. It must be reported, not silently dropped.
    func testUndeclaredV1SlotIsReported() {
        let result = TurkishTextRenderer.render(
            "Aniden, çok güzel {{child.favoriteColor}} çiçekler açtı!",
            slots: ["child.name": yeliz]
        )
        XCTAssertEqual(result.missingSlots, ["child.favoriteColor"])
    }

    func testUnrecognisedSuffixIsReportedRatherThanSilentlyEmitted() {
        let result = TurkishTextRenderer.render(
            "{{companion.name}}'ydi.",
            slots: ["companion.name": .init("Kıpır", isProperNoun: true)]
        )
        XCTAssertEqual(result.unrecognisedSuffixes, ["ydi"])
        XCTAssertFalse(result.isClean)
    }

    func testCommonNounSlotRendersWithoutApostrophe() {
        let result = TurkishTextRenderer.render(
            "Küçük {{companion.type}}'ye baktı.",
            slots: ["companion.type": tilki]
        )
        XCTAssertEqual(result.text, "Küçük tilkiye baktı.")
    }

    /// The previous renderer re-ran its regex over its own output, so a value
    /// containing "{{" would be substituted a second time.
    func testSubstitutedValueIsNotRescanned() {
        let result = TurkishTextRenderer.render(
            "{{child.name}} geldi.",
            slots: [
                "child.name": .init("{{companion.name}}", isProperNoun: true),
                "companion.name": .init("Kıpır", isProperNoun: true)
            ]
        )
        XCTAssertEqual(result.text, "{{companion.name}} geldi.")
    }

    func testEmptyAndUnslottedTemplatesAreStable() {
        XCTAssertEqual(TurkishTextRenderer.render("", slots: [:]).text, "")
        XCTAssertEqual(
            TurkishTextRenderer.render("Hiç yer tutucu yok.", slots: [:]).text,
            "Hiç yer tutucu yok."
        )
        XCTAssertEqual(TurkishGrammar.inflect(proper(""), into: .genitive), "")
    }

    // MARK: - Locative relative (-ki)

    /// `T2_achievement` — *{Child}+GEN {Setting}+LOC+ki {AchievementNoun}* —
    /// needs locative + the relative -ki ("Ormandaki"). Plain locative is not
    /// enough, and folding -ki into the case enum would misrepresent it: the
    /// result is an adjective and cannot take a further case.
    func testLocativeRelativeBuildsOnTheLocative() {
        XCTAssertEqual(
            TurkishGrammar.apply(proper("Fısıldayan Orman"), .locativeRelative),
            "Fısıldayan Orman'daki"
        )
        XCTAssertEqual(
            TurkishGrammar.apply(proper("Gizli Bahçe"), .locativeRelative),
            "Gizli Bahçe'deki"
        )
        XCTAssertEqual(TurkishGrammar.apply(common("orman"), .locativeRelative), "ormandaki")
    }

    /// It must inherit the locative's assimilation and possessive buffer
    /// rather than reimplementing them.
    func testLocativeRelativeInheritsAssimilationAndBuffer() {
        XCTAssertEqual(TurkishGrammar.apply(common("kitap"), .locativeRelative), "kitaptaki")
        XCTAssertEqual(TurkishGrammar.apply(common("köpek"), .locativeRelative), "köpekteki")
        XCTAssertEqual(
            TurkishGrammar.apply(proper("Bulut Krallığı", possessive: true), .locativeRelative),
            "Bulut Krallığı'ndaki"
        )
        XCTAssertEqual(
            TurkishGrammar.apply(proper("Ay Yüzeyi", possessive: true), .locativeRelative),
            "Ay Yüzeyi'ndeki"
        )
    }

    /// -ki resists vowel harmony, and in this position the question cannot
    /// arise: it only ever follows the locative's `a` or `e`.
    func testLocativeRelativeDoesNotHarmonise() {
        XCTAssertEqual(TurkishGrammar.apply(common("köprü"), .locativeRelative), "köprüdeki")
        XCTAssertEqual(TurkishGrammar.apply(common("bulut"), .locativeRelative), "buluttaki")
    }

    func testSuffixRequestParsing() {
        XCTAssertEqual(TurkishSuffixRequest.parse(suffixSpelling: "daki"), .locativeRelative)
        XCTAssertEqual(TurkishSuffixRequest.parse(suffixSpelling: "deki"), .locativeRelative)
        XCTAssertEqual(TurkishSuffixRequest.parse(suffixSpelling: "ndaki"), .locativeRelative)
        XCTAssertEqual(TurkishSuffixRequest.parse(suffixSpelling: "teki"), .locativeRelative)
        XCTAssertEqual(TurkishSuffixRequest.parse(suffixSpelling: "da"), .grammaticalCase(.locative))
        XCTAssertEqual(TurkishSuffixRequest.parse(suffixSpelling: "nin"), .grammaticalCase(.genitive))
        XCTAssertNil(TurkishSuffixRequest.parse(suffixSpelling: "ydi"))
        // -ki must not be mistaken for a case; a case parse of it stays nil.
        XCTAssertNil(TurkishCase.parse(suffixSpelling: "daki"))
    }

    /// Casing is normalised with Turkish rules, so `I` lowercases to `ı`.
    func testSuffixSpellingNormalisationIsTurkishAware() {
        XCTAssertEqual(TurkishSuffixRequest.parse(suffixSpelling: "DA"), .grammaticalCase(.locative))
        XCTAssertEqual(TurkishSuffixRequest.parse(suffixSpelling: "\u{2019}nin"), .grammaticalCase(.genitive))
    }

    /// The whole `T2_achievement` title shape, end to end.
    func testAchievementTitleRenders() {
        let result = TurkishTextRenderer.render(
            "{{child.name}}'nin {{setting.name}}'daki Büyük Keşfi",
            slots: [
                "child.name": yeliz,
                "setting.name": .init("Fısıldayan Orman", isProperNoun: true)
            ]
        )
        XCTAssertEqual(result.text, "Yeliz'in Fısıldayan Orman'daki Büyük Keşfi")
        XCTAssertTrue(result.isClean)
    }

    /// The same shape with a possessive-stem setting, which is where the
    /// buffer and the apostrophe both have to land correctly.
    func testAchievementTitleWithPossessiveStemSetting() {
        let result = TurkishTextRenderer.render(
            "{{child.name}}'nin {{setting.name}}'daki Büyük Keşfi",
            slots: [
                "child.name": yeliz,
                "setting.name": .init("Bulut Krallığı", isProperNoun: true, hasPossessiveEnding: true)
            ]
        )
        XCTAssertEqual(result.text, "Yeliz'in Bulut Krallığı'ndaki Büyük Keşfi")
    }

    // MARK: - Corpus sweep

    /// Every companion type in the shipped library, inflected into every case,
    /// must produce output with no apostrophe and no doubled buffer.
    func testAllShippedCompanionTypesInflectCleanly() {
        let types = [
            "tilki", "tavşan", "baykuş", "kirpi", "ejderha", "sincap", "ayı",
            "penguen", "kaplumbağa", "yunus", "ateşböceği", "kurbağa", "kedi", "köpek"
        ]
        for type in types {
            for grammaticalCase in TurkishCase.allCases {
                let output = TurkishGrammar.inflect(common(type), into: grammaticalCase)
                XCTAssertFalse(output.contains("'"), "\(type) \(grammaticalCase) gained an apostrophe")
                XCTAssertFalse(output.contains("nn"), "\(type) \(grammaticalCase) doubled a buffer")
                XCTAssertTrue(output.hasPrefix(String(type.prefix(2))), "\(type) lost its stem")
            }
        }
    }

    /// Rendered through a slot, the way the app does it — the compound
    /// possessive must survive the whole path, not just direct inflection.
    func testFireflyTypeRendersThroughSlot() {
        let result = TurkishTextRenderer.render(
            "Minik {{companion.type}}'ye baktı.",
            slots: ["companion.type": .init("ateşböceği", isProperNoun: false, hasPossessiveEnding: true)]
        )
        XCTAssertEqual(result.text, "Minik ateşböceğine baktı.")
    }

    /// "ateşböceği" is a possessive compound and needs the buffer even as a
    /// common noun.
    func testPossessiveCompoundCommonNoun() {
        let firefly = TurkishNoun("ateşböceği", isProperNoun: false, hasPossessiveEnding: true)
        XCTAssertEqual(TurkishGrammar.inflect(firefly, into: .dative), "ateşböceğine")
        XCTAssertEqual(TurkishGrammar.inflect(firefly, into: .locative), "ateşböceğinde")
        XCTAssertEqual(TurkishGrammar.inflect(firefly, into: .accusative), "ateşböceğini")
    }
}
