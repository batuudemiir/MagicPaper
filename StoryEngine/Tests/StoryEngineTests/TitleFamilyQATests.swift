import XCTest
@testable import StoryEngine

/// Phase 6 QA: render every title family against real shipped content and
/// assert the Turkish is correct. Titles were hardcoded to
/// "{child} ve {companion}" in the shipped app; this is the first time the
/// five title families have been exercised end to end.
final class TitleFamilyQATests: XCTestCase {

    private func child(_ n: String) -> TurkishTextRenderer.Slot {
        .init(n, isProperNoun: true)
    }
    private func setting(_ n: String, possessive: Bool = false) -> TurkishTextRenderer.Slot {
        .init(n, isProperNoun: true, hasPossessiveEnding: possessive)
    }
    private func common(_ n: String, possessive: Bool = false) -> TurkishTextRenderer.Slot {
        .init(n, isProperNoun: false, hasPossessiveEnding: possessive)
    }

    // The five families from BLUEPRINT_ARCHITECTURE.md §9.
    private let T1 = "{{child.name}} ve {{discovery.phrase}}"
    private let T2 = "{{child.name}}'nin {{setting.name}}'daki Büyük Keşfi"
    private let T3 = "{{child.name}} ve {{discovery.phrase}}'nin Sırrı"
    private let T4 = "{{setting.name}}'a Cesur Yolculuk"
    private let T5 = "{{child.name}} ve {{companion.name}}'nin {{discovery.phrase}}"

    func testT2AcrossEverySettingShape() {
        let cases: [(String, Bool, String)] = [
            ("Fısıldayan Orman", false, "Yeliz'in Fısıldayan Orman'daki Büyük Keşfi"),
            ("Gizli Bahçe",      false, "Yeliz'in Gizli Bahçe'deki Büyük Keşfi"),
            ("Kristal Mağara",   false, "Yeliz'in Kristal Mağara'daki Büyük Keşfi"),
            ("Eski Taş Köprü",   false, "Yeliz'in Eski Taş Köprü'deki Büyük Keşfi"),
            ("Bulut Krallığı",   true,  "Yeliz'in Bulut Krallığı'ndaki Büyük Keşfi"),
            ("Ay Yüzeyi",        true,  "Yeliz'in Ay Yüzeyi'ndeki Büyük Keşfi"),
            ("Mercan Resifi",    true,  "Yeliz'in Mercan Resifi'ndeki Büyük Keşfi"),
            ("Karlı Vadi",       false, "Yeliz'in Karlı Vadi'deki Büyük Keşfi"),
        ]
        for (name, poss, expected) in cases {
            let r = TurkishTextRenderer.render(T2, slots: [
                "child.name": child("Yeliz"), "setting.name": setting(name, possessive: poss)
            ])
            XCTAssertEqual(r.text, expected, "T2 failed for \(name)")
            XCTAssertTrue(r.isClean)
        }
    }

    /// Dative across the same shapes — T4's only inflection.
    func testT4AcrossEverySettingShape() {
        let cases: [(String, Bool, String)] = [
            ("Fısıldayan Orman", false, "Fısıldayan Orman'a Cesur Yolculuk"),
            ("Kristal Mağara",   false, "Kristal Mağara'ya Cesur Yolculuk"),
            ("Eski Taş Köprü",   false, "Eski Taş Köprü'ye Cesur Yolculuk"),
            ("Bulut Krallığı",   true,  "Bulut Krallığı'na Cesur Yolculuk"),
            ("Yıldız İstasyonu", true,  "Yıldız İstasyonu'na Cesur Yolculuk"),
        ]
        for (name, poss, expected) in cases {
            let r = TurkishTextRenderer.render(T4, slots: ["setting.name": setting(name, possessive: poss)])
            XCTAssertEqual(r.text, expected, "T4 failed for \(name)")
        }
    }

    /// Genitive on a companion name, across all four vowel classes.
    func testT5CompanionGenitive() {
        let cases: [(String, String)] = [
            ("Kıpır",   "Yeliz ve Kıpır'ın Gizemli Işığı"),
            ("Bilge",   "Yeliz ve Bilge'nin Gizemli Işığı"),
            ("Pofuduk", "Yeliz ve Pofuduk'un Gizemli Işığı"),
            ("Dikenli", "Yeliz ve Dikenli'nin Gizemli Işığı"),
            ("Zip",     "Yeliz ve Zip'in Gizemli Işığı"),
        ]
        for (name, expected) in cases {
            let r = TurkishTextRenderer.render(T5, slots: [
                "child.name": child("Yeliz"),
                "companion.name": .init(name, isProperNoun: true),
                "discovery.phrase": common("Gizemli Işığı")
            ])
            XCTAssertEqual(r.text, expected, "T5 failed for \(name)")
        }
    }

    /// T3 inflects a common-noun discovery phrase — no apostrophe.
    func testT3DiscoveryPhraseIsCommonNoun() {
        let r = TurkishTextRenderer.render(T3, slots: [
            "child.name": child("Yeliz"), "discovery.phrase": common("kayıp harita")
        ])
        XCTAssertEqual(r.text, "Yeliz ve kayıp haritanın Sırrı")
    }

    /// Child names across all four vowel classes and both capital I forms —
    /// the personalisation slot every title family depends on.
    func testChildNameGenitiveAcrossVowelClasses() {
        for (name, expected) in [
            ("Yeliz", "Yeliz'in"), ("Arda", "Arda'nın"), ("Bulut", "Bulut'un"),
            ("Ömür", "Ömür'ün"), ("Irmak", "Irmak'ın"), ("İnci", "İnci'nin"),
            ("Deniz", "Deniz'in"), ("Ayşe", "Ayşe'nin"), ("Mert", "Mert'in"),
        ] {
            let r = TurkishTextRenderer.render("{{child.name}}'nin", slots: ["child.name": child(name)])
            XCTAssertEqual(r.text, expected, "genitive failed for \(name)")
        }
    }

    /// No title family may leave an unresolved token or an unrecognised suffix.
    func testEveryTitleFamilyRendersCleanly() {
        let slots: [String: TurkishTextRenderer.Slot] = [
            "child.name": child("Yeliz"),
            "companion.name": .init("Kıpır", isProperNoun: true),
            "setting.name": setting("Fısıldayan Orman"),
            "discovery.phrase": common("Gizemli Işığı")
        ]
        for (name, pattern) in [("T1", T1), ("T2", T2), ("T3", T3), ("T4", T4), ("T5", T5)] {
            let r = TurkishTextRenderer.render(pattern, slots: slots)
            XCTAssertTrue(r.isClean, "\(name) unclean: missing \(r.missingSlots) bad \(r.unrecognisedSuffixes)")
            XCTAssertFalse(r.text.contains("{{"), "\(name) left a token")
        }
    }
}
