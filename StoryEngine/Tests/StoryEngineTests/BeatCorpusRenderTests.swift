import XCTest
@testable import StoryEngine

/// Renders the authored `notice_anomaly` corpus through the real Turkish
/// resolver against every setting shape in the library. A variant that renders
/// ungrammatically here would ship ungrammatically.
final class BeatCorpusRenderTests: XCTestCase {

    private struct Variant: Decodable {
        let id: String
        let text: String
        let requiredSlots: [String]
        // Beats differ in which axes they constrain: notice_anomaly flavours by
        // setting and discovery, meet_companion by casting, warm_close by
        // length class and which closing beat precedes it. Optional, so one
        // decoder reads the whole corpus.
        let settingTraits: [String]?
        let discoveryTraits: [String]?
        let castRoles: [String]?
        let lengthClass: String?
        let afterClosing: [String]?
        let move: String
    }
    private struct BeatFile: Decodable {
        let beat: String
        let produces: [String]
        let variants: [Variant]
    }

    /// Read from the source tree: this is authored content under review, not a
    /// bundled resource, and the file a human will diff is the one to test.
    private func loadCorpus() throws -> BeatFile {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()      // StoryEngineTests
            .deletingLastPathComponent()      // Tests
            .deletingLastPathComponent()      // StoryEngine
            .appendingPathComponent("Sources/StoryEngine/Resources/templates/v3/beat_notice_anomaly.json")
        return try JSONDecoder().decode(BeatFile.self, from: Data(contentsOf: url))
    }

    /// Every authored beat file in the v3 corpus.
    private func loadAllCorpora() throws -> [BeatFile] {
        let dir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/StoryEngine/Resources/templates/v3")
        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("beat_") && $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        XCTAssertFalse(files.isEmpty, "no beat files found")
        return try files.map { try JSONDecoder().decode(BeatFile.self, from: Data(contentsOf: $0)) }
    }

    /// The whole authored corpus, every variant against every setting, every
    /// child name and a representative companion. This is the check that caught
    /// a glowing egg and trees inside a cloud kingdom.
    func testWholeCorpusRendersCleanly() throws {
        let corpora = try loadAllCorpora()
        var rendered = 0
        for corpus in corpora {
            XCTAssertFalse(corpus.variants.isEmpty, "\(corpus.beat) is empty")
            XCTAssertEqual(Set(corpus.variants.map(\.id)).count, corpus.variants.count,
                           "\(corpus.beat) has duplicate variant ids")
            for variant in corpus.variants {
                for (settingName, possessive) in settings {
                    for childName in children {
                        let slots: [String: TurkishTextRenderer.Slot] = [
                            "child.name": .init(childName, isProperNoun: true),
                            "setting.name": .init(settingName, isProperNoun: true, hasPossessiveEnding: possessive),
                            "discovery.name": .init("parlayan bir ışık", isProperNoun: false),
                            "companion.name": .init("Kıpır", isProperNoun: true),
                            "companion.type": .init("tilki", isProperNoun: false)
                        ]
                        let r = TurkishTextRenderer.render(variant.text, slots: slots)
                        XCTAssertTrue(r.isClean,
                            "\(corpus.beat)/\(variant.id) @ \(settingName)/\(childName): missing \(r.missingSlots) bad \(r.unrecognisedSuffixes)")
                        XCTAssertFalse(r.text.contains("{{"), "\(variant.id) left a token")
                        rendered += 1
                    }
                }
            }
        }
        XCTAssertGreaterThanOrEqual(rendered, 48 * 16 * 8)
    }

    /// Discovery phrases can be possessive stems too: "ayak izleri" is
    /// ayak + iz + plural + 3sg possessive, so the accusative is "izlerini",
    /// never "izleriyi". Found by rendering a real story, not by reading.
    func testPossessiveStemDiscoveryPhrase() {
        let wrong: TurkishTextRenderer.Slot = .init("ayak izleri", isProperNoun: false)
        let right: TurkishTextRenderer.Slot = .init("ayak izleri", isProperNoun: false, hasPossessiveEnding: true)
        XCTAssertEqual(
            TurkishTextRenderer.render("Tam o sırada {{d}}'i fark etti.", slots: ["d": wrong]).text,
            "Tam o sırada ayak izleriyi fark etti.",
            "undeclared: this is the wrong form the corpus would ship"
        )
        XCTAssertEqual(
            TurkishTextRenderer.render("Tam o sırada {{d}}'i fark etti.", slots: ["d": right]).text,
            "Tam o sırada ayak izlerini fark etti."
        )
        XCTAssertEqual(
            TurkishTextRenderer.render("{{d}}'e baktı.", slots: ["d": right]).text,
            "Ayak izlerine baktı."
        )
    }

    /// The possessive-stem companion type must survive the whole path.
    func testFireflyCompanionTypeInCorpus() throws {
        let corpora = try loadAllCorpora()
        for corpus in corpora {
            for variant in corpus.variants where variant.text.contains("{{companion.type}}") {
                let r = TurkishTextRenderer.render(variant.text, slots: [
                    "child.name": .init("Yeliz", isProperNoun: true),
                    "setting.name": .init("Fısıldayan Orman", isProperNoun: true),
                    "discovery.name": .init("parlayan bir ışık", isProperNoun: false),
                    "companion.name": .init("Pırıltı", isProperNoun: true),
                    "companion.type": .init("ateşböceği", isProperNoun: false, hasPossessiveEnding: true)
                ])
                XCTAssertTrue(r.isClean, "\(variant.id) unclean with ateşböceği")
                XCTAssertFalse(r.text.contains("ateşböceğiy"), "\(variant.id): wrong buffer on ateşböceği")
            }
        }
    }

    /// Every setting shape in the shipped library: consonant-final, vowel-final,
    /// front and back harmony, and all four possessive stems.
    private let settings: [(String, Bool)] = [
        ("Fısıldayan Orman", false), ("Güneşli Çayır", false), ("Kristal Mağara", false),
        ("Bulutlu Zirve", false), ("Sakin Kumsal", false), ("Şırıl Şırıl Nehir", false),
        ("Gizli Bahçe", false), ("Minik Köy", false), ("Terkedilmiş Şato", false),
        ("Karlı Vadi", false), ("Güneşli Ada", false), ("Eski Taş Köprü", false),
        ("Bulut Krallığı", true), ("Yıldız İstasyonu", true),
        ("Ay Yüzeyi", true), ("Mercan Resifi", true),
    ]
    private let children = ["Yeliz", "Ada", "Abdullah", "Irmak", "İnci", "Ömür", "Bulut", "Deniz"]

    func testCorpusHasFullTieredSupply() throws {
        let corpus = try loadCorpus()
        XCTAssertEqual(corpus.beat, "notice_anomaly")
        XCTAssertEqual(corpus.produces, ["anomalyKnown"])
        // notice_anomaly appears in all 14 blueprints; the tiered allocation
        // in the QA report puts a 14/14-exposure beat at 16 variants.
        XCTAssertEqual(corpus.variants.count, 16, "tiered supply for a 14/14 beat is 16")
        XCTAssertEqual(Set(corpus.variants.map(\.id)).count, 16, "variant ids must be unique")
    }

    /// Every variant × every setting × every child name must render with no
    /// missing slot and no unrecognised suffix.
    func testEveryVariantRendersCleanlyAcrossTheLibrary() throws {
        let corpus = try loadCorpus()
        var rendered = 0
        for variant in corpus.variants {
            for (settingName, possessive) in settings {
                for childName in children {
                    let slots: [String: TurkishTextRenderer.Slot] = [
                        "child.name": .init(childName, isProperNoun: true),
                        "setting.name": .init(settingName, isProperNoun: true, hasPossessiveEnding: possessive),
                        "discovery.name": .init("parlayan bir ışık", isProperNoun: false)
                    ]
                    let r = TurkishTextRenderer.render(variant.text, slots: slots)
                    XCTAssertTrue(
                        r.isClean,
                        "\(variant.id) / \(settingName) / \(childName): missing \(r.missingSlots) bad \(r.unrecognisedSuffixes)"
                    )
                    XCTAssertFalse(r.text.contains("{{"), "\(variant.id) left a token")
                    rendered += 1
                }
            }
        }
        XCTAssertEqual(rendered, 16 * 16 * 8)
    }

    /// Declared `requiredSlots` must match the tokens actually used, or the
    /// selector cannot know what a variant needs.
    /// Checks the WHOLE corpus, not one file: a mismatch in `restore` survived
    /// because this test used to load only `notice_anomaly`.
    func testDeclaredSlotsMatchUsedTokens() throws {
        for corpus in try loadAllCorpora() {
            try assertSlotsMatch(corpus)
        }
    }

    private func assertSlotsMatch(_ corpus: BeatFile) throws {
        let pattern = try NSRegularExpression(pattern: "\\{\\{([^}]+)\\}\\}")
        for variant in corpus.variants {
            let ns = variant.text as NSString
            let used = Set(pattern.matches(in: variant.text, range: NSRange(location: 0, length: ns.length))
                .map { ns.substring(with: $0.range(at: 1)) })
            XCTAssertEqual(used, Set(variant.requiredSlots), "\(variant.id) slot declaration is out of sync")
        }
    }

    /// Spot-check the suffix forms the corpus leans on hardest, against the
    /// two setting shapes that behave differently.
    func testSuffixFormsOnBothSettingShapes() {
        let plain: TurkishTextRenderer.Slot = .init("Fısıldayan Orman", isProperNoun: true)
        let poss: TurkishTextRenderer.Slot = .init("Bulut Krallığı", isProperNoun: true, hasPossessiveEnding: true)
        XCTAssertEqual(TurkishTextRenderer.render("{{s}}'a", slots: ["s": plain]).text, "Fısıldayan Orman'a")
        XCTAssertEqual(TurkishTextRenderer.render("{{s}}'a", slots: ["s": poss]).text, "Bulut Krallığı'na")
        XCTAssertEqual(TurkishTextRenderer.render("{{s}}'da", slots: ["s": plain]).text, "Fısıldayan Orman'da")
        XCTAssertEqual(TurkishTextRenderer.render("{{s}}'da", slots: ["s": poss]).text, "Bulut Krallığı'nda")
        // The accusative the enclosed variant uses on a common-noun phrase.
        // Embedded mid-sentence, which is how the corpus actually uses it —
        // at position zero the renderer capitalises, correctly.
        XCTAssertEqual(
            TurkishTextRenderer.render(
                "Tam o sırada {{d}}'i fark etti.",
                slots: ["d": .init("parlayan bir ışık", isProperNoun: false)]
            ).text,
            "Tam o sırada parlayan bir ışığı fark etti."
        )
        // And at a sentence start it must capitalise with Turkish rules.
        XCTAssertEqual(
            TurkishTextRenderer.render(
                "{{d}} oradaydı.",
                slots: ["d": .init("ince bir ses", isProperNoun: false)]
            ).text,
            "İnce bir ses oradaydı."
        )
    }
}
