import XCTest
@testable import StoryEngine

/// Ek çekimi, Masal ailem adları için (FAZ 11).
///
/// Bu adları ebeveyn yazar; içerikte hiçbiri yok. Tablo ünlü uyumunu
/// (kalın/ince, düz/yuvarlak), kaynaştırma harflerini, d/t benzeşmesini ve
/// özel adda yumuşamanın yazıya geçmemesini (TDK: "Ahmet'e", "Burak'a") sınar.
/// İnce *l* ile biten birkaç ad kalın ünlüye rağmen ince ek alır; bunlar
/// yazımdan çıkarılamaz, `TurkishGrammar.frontHarmonyNames` listesindedir.
final class FamilyNameGrammarTests: XCTestCase {

    private func name(_ text: String) -> TurkishNoun { TurkishNoun(text, isProperNoun: true) }

    func testTheNameTable() {
        let table: [(String, TurkishCase, String)] = [
            ("Can", .dative, "Can'a"),
            ("Pamuk", .dative, "Pamuk'a"),
            ("Elif", .dative, "Elif'e"),
            ("Nuri", .dative, "Nuri'ye"),
            ("Ela", .dative, "Ela'ya"),
            ("Duru", .accusative, "Duru'yu"),
            ("Övgü", .accusative, "Övgü'yü"),
            ("Ömer", .genitive, "Ömer'in"),
            ("Ayşe", .genitive, "Ayşe'nin"),
            ("Umut", .accusative, "Umut'u"),
            ("Burak", .dative, "Burak'a"),
            ("Ahmet", .genitive, "Ahmet'in"),
            ("Zeynep", .accusative, "Zeynep'i"),
            ("Yusuf", .locative, "Yusuf'ta"),
            ("Mert", .locative, "Mert'te"),
            ("Toprak", .ablative, "Toprak'tan"),
            ("Deniz", .locative, "Deniz'de"),
            ("Ilgaz", .genitive, "Ilgaz'ın"),
            ("İpek", .dative, "İpek'e"),
            ("Köpük", .ablative, "Köpük'ten"),
            ("Boncuk", .genitive, "Boncuk'un"),
            ("Su", .dative, "Su'ya"),
            ("Serap", .ablative, "Serap'tan"),
            ("Kemal", .dative, "Kemal'e"),
            ("Hilal", .accusative, "Hilal'i"),
            ("Kemâl", .dative, "Kemâl'e"),
            ("Ali Can", .dative, "Ali Can'a"),
            ("Ali Kemal", .genitive, "Ali Kemal'in"),
        ]
        for (text, grammaticalCase, expected) in table {
            XCTAssertEqual(TurkishGrammar.inflect(name(text), into: grammaticalCase), expected,
                           "\(text) + \(grammaticalCase)")
        }
    }

    /// The exception list is for names only. "kartal" is a common noun and
    /// keeps its back vowel.
    func testTheExceptionListDoesNotReachCommonNouns() {
        XCTAssertEqual(
            TurkishGrammar.inflect(TurkishNoun("kartal", isProperNoun: false), into: .dative),
            "kartala")
        XCTAssertEqual(TurkishGrammar.inflect(name("Kartal"), into: .dative), "Kartal'a")
    }

    /// The animal kinds are common nouns: they soften and take no apostrophe.
    func testAnimalKinds() {
        let table: [(String, TurkishCase, String, Bool)] = [
            ("köpek", .dative, "köpeğe", false),
            ("köpek", .accusative, "köpeği", false),
            ("balık", .dative, "balığa", false),
            ("kuş", .dative, "kuşa", false),
            ("kedi", .dative, "kediye", false),
            ("kaplumbağa", .dative, "kaplumbağaya", false),
            ("hamster", .dative, "hamstere", true),
        ]
        for (text, grammaticalCase, expected, blocks) in table {
            XCTAssertEqual(
                TurkishGrammar.inflect(TurkishNoun(text, isProperNoun: false, blocksSoftening: blocks),
                                       into: grammaticalCase),
                expected, text)
        }
        // The owned form already carries a possessive: buffer -n-.
        XCTAssertEqual(
            TurkishGrammar.inflect(TurkishNoun("kedisi", isProperNoun: false, hasPossessiveEnding: true),
                                   into: .accusative),
            "kedisini")
        XCTAssertEqual(
            TurkishGrammar.inflect(TurkishNoun("köpeği", isProperNoun: false, hasPossessiveEnding: true),
                                   into: .accusative),
            "köpeğini")
    }
}
