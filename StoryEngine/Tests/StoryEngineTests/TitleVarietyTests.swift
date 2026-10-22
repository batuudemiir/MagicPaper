import XCTest
@testable import StoryEngine

/// Masal başlıkları (21 Ekim 2026, Batuhan onayı).
///
/// Başlıklar birbirine benziyordu: katalogda 13 kalıp vardı, 11'i çocuğun
/// adıyla başlıyordu ve uyku masalı yalnızca iki kalıptan birini alıyordu.
/// Burada üç şey sabitlenir:
///
/// 1. Kalıplar moda özel ve çoğunlukla adsız (blueprint başına 4-6, en fazla
///    yarısı adla başlar) — `CatalogIntegrity` kuralı.
/// 2. Kapakta okunmayan başlık yazılmaz: uzun (bandın sınırını aşan) ya da
///    aynı kelimeyi iki kez taşıyan başlık bir sonraki kalıba bırakılır.
/// 3. Çocuğun kitaplığındaki bir başlık, başka bir kalıp temizse yeniden
///    yazılmaz; hepsi kullanıldıysa bugünkü seçim kalır. Aynı girdi, aynı başlık.
final class TitleVarietyTests: XCTestCase {

    // MARK: - Fixtures

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    /// A shipped blueprint with its title patterns replaced. Round-trips
    /// through JSON so every other field stays the shipped one.
    private func blueprint(
        _ id: String = "bp_charge_tending_001",
        patterns: [String],
        ageRange: String? = nil
    ) throws -> CatalogBlueprint {
        let catalog = try catalog()
        let original = try XCTUnwrap(
            (catalog.blueprints + catalog.series.continuations).first { $0.id.rawValue == id })
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        object["titlePatterns"] = patterns
        if let ageRange { object["ageRange"] = ageRange }
        return try JSONDecoder().decode(
            CatalogBlueprint.self, from: JSONSerialization.data(withJSONObject: object))
    }

    private func slots(
        child: String = "Yeliz",
        setting: String = "Gece Bahçesi",
        settingPossessive: Bool = true,
        companion: String = "Tarçın",
        discovery: String = "Solan Fide"
    ) -> [String: TurkishTextRenderer.Slot] {
        [
            "child.name": .init(child, isProperNoun: true),
            "setting.name": .init(setting, isProperNoun: true, hasPossessiveEnding: settingPossessive),
            "companion.name": .init(companion, isProperNoun: true),
            "discovery.title": .init(discovery, isProperNoun: false)
        ]
    }

    private let composer = TitleComposer()

    private let fourPatterns = [
        "{{companion.name}}'ın Uykulu Gecesi",
        "{{discovery.title}}'e İyi Geceler",
        "{{setting.name}}'nda Usulca",
        "{{child.name}} Bekledi"
    ]

    // MARK: - Anti-repeat

    func testATitleAlreadyInTheLibraryIsNotWrittenAgain() throws {
        let blueprint = try blueprint(patterns: fourPatterns)
        let today = composer.compose(blueprint: blueprint, slots: slots(), seed: "s1")
        let next = composer.compose(blueprint: blueprint, slots: slots(), seed: "s1", avoiding: [today])
        XCTAssertNotEqual(next, today)
        XCTAssertTrue(TitleComposer.defects(of: next, band: blueprint.ageRange).isEmpty, next)
    }

    func testTheLibraryIsComparedFoldedAndTurkishAware() throws {
        let blueprint = try blueprint(patterns: fourPatterns)
        let today = composer.compose(blueprint: blueprint, slots: slots(), seed: "s1")
        // Turkish upper-casing (i → İ, ı → I), extra spaces, a typographic apostrophe.
        let shouted = "  " + today.uppercased(with: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "'", with: "\u{2019}")
            .replacingOccurrences(of: " ", with: "  ") + " "
        let next = composer.compose(blueprint: blueprint, slots: slots(), seed: "s1", avoiding: [shouted])
        XCTAssertNotEqual(next, today, "\(shouted) should fold to \(today)")
        XCTAssertEqual(TitleComposer.fold(shouted), TitleComposer.fold(today))
        // Dotted and dotless i are different letters, not one folded letter.
        XCTAssertNotEqual(TitleComposer.fold("Işık"), TitleComposer.fold("İşik"))
    }

    func testWhenEveryTitleIsUsedTodaysChoiceStays() throws {
        let blueprint = try blueprint(patterns: fourPatterns)
        let today = composer.compose(blueprint: blueprint, slots: slots(), seed: "s2")
        let everything = Set(fourPatterns.map { TurkishTextRenderer.render($0, slots: slots()).text })
        XCTAssertEqual(
            composer.compose(blueprint: blueprint, slots: slots(), seed: "s2", avoiding: everything), today)
    }

    func testSameInputsIncludingTheLibraryGiveTheSameTitle() throws {
        let blueprint = try blueprint(patterns: fourPatterns)
        for seed in ["a", "b", "c", "d", "e"] {
            let today = composer.compose(blueprint: blueprint, slots: slots(), seed: seed)
            let library: Set<String> = [today, "Başka Bir Masal"]
            let first = composer.compose(blueprint: blueprint, slots: slots(), seed: seed, avoiding: library)
            let second = composer.compose(blueprint: blueprint, slots: slots(), seed: seed, avoiding: library)
            XCTAssertEqual(first, second)
            XCTAssertEqual(composer.compose(blueprint: blueprint, slots: slots(), seed: seed), today,
                           "No library changes nothing.")
        }
    }

    func testAnEmptyLibraryLeavesTheTitleAsItWas() throws {
        let blueprint = try blueprint(patterns: fourPatterns)
        for seed in ["a", "b", "c"] {
            XCTAssertEqual(
                composer.compose(blueprint: blueprint, slots: slots(), seed: seed, avoiding: []),
                composer.compose(blueprint: blueprint, slots: slots(), seed: seed))
        }
    }

    // MARK: - Cover-readiness

    func testAnOverlongTitleFallsToTheNextPattern() throws {
        let blueprint = try blueprint(patterns: [
            "{{child.name}} ve {{companion.name}} Çok Uzun Bir Yolculukta",
            "{{companion.name}}'ın Uykulu Gecesi"
        ])
        for seed in ["a", "b", "c", "d", "e", "f"] {
            XCTAssertEqual(composer.compose(blueprint: blueprint, slots: slots(), seed: seed),
                           "Tarçın'ın Uykulu Gecesi")
        }
    }

    func testARepeatedWordFallsToTheNextPattern() throws {
        let blueprint = try blueprint(patterns: [
            "Kayıp {{discovery.title}}",
            "{{setting.name}}'nda Sessiz Gece",
            "{{discovery.title}}'in Peşinde"
        ])
        for seed in ["a", "b", "c", "d", "e", "f"] {
            XCTAssertEqual(
                composer.compose(blueprint: blueprint, slots: slots(discovery: "Kayıp Eldiven"), seed: seed),
                "Kayıp Eldivenin Peşinde")
        }
        XCTAssertTrue(TitleComposer.defects(of: "Kayıp Kayıp Eldiven", band: nil).contains(.repeatedWord))
        XCTAssertTrue(TitleComposer.defects(of: "Gece Bahçesi'nde Sessiz Gece", band: nil).contains(.repeatedWord))
        XCTAssertTrue(TitleComposer.defects(of: "Gizemli Ses ve Gizemli Işık", band: nil).contains(.repeatedWord))
        XCTAssertTrue(TitleComposer.defects(of: "Bulut Dağı'nda Yırtık Harita", band: nil).isEmpty)
    }

    func testTheYoungestBandGetsAShorterCover() {
        let five = AgeBand(lowerBound: 5, upperBound: 6)
        let three = AgeBand(lowerBound: 3, upperBound: 4)
        XCTAssertEqual(TitleComposer.maxLength(for: five), 32)
        XCTAssertLessThan(TitleComposer.maxLength(for: three), TitleComposer.maxLength(for: five))
        let title = "Eski Meyve Bahçesi'nde Usulca"   // 29
        XCTAssertTrue(TitleComposer.defects(of: title, band: five).isEmpty)
        XCTAssertEqual(TitleComposer.defects(of: title, band: three), [.tooLong])
        XCTAssertEqual(TitleComposer.defects(of: String(repeating: "a", count: 33), band: nil), [.tooLong])
    }

    func testTheFallbackRespectsVowelHarmony() throws {
        let blueprint = try blueprint(patterns: [])
        let title = composer.compose(
            blueprint: blueprint,
            slots: ["child.name": .init("Arda", isProperNoun: true)],
            seed: "s")
        XCTAssertEqual(title, "Arda'nın Hikâyesi")
    }

    // MARK: - The shipped catalog

    private func allBlueprints(_ catalog: ContentCatalog) -> [CatalogBlueprint] {
        catalog.blueprints + catalog.series.continuations
    }

    func testEveryBlueprintHasFourToSixPatternsMostlyWithoutTheName() throws {
        for blueprint in allBlueprints(try catalog()) {
            let patterns = blueprint.titlePatterns
            XCTAssertTrue((4...6).contains(patterns.count), "\(blueprint.id): \(patterns.count) patterns")
            let led = patterns.filter(TitleComposer.isNameLed).count
            XCTAssertLessThanOrEqual(led * 2, patterns.count, "\(blueprint.id): \(led) of \(patterns.count) start with the name")
            XCTAssertEqual(Set(patterns).count, patterns.count, "\(blueprint.id) repeats a pattern")
        }
    }

    func testTheShippedCatalogHasNoTitlePatternIssue() throws {
        let report = CatalogIntegrityChecker().check(try catalog())
        XCTAssertTrue(report.issues.filter { $0.code.hasPrefix("title_patterns_") }.isEmpty,
                      "\(report.issues.filter { $0.code.hasPrefix("title_patterns_") })")
    }

    func testIntegrityFlagsANameLedBlueprint() throws {
        let led = try blueprint(patterns: [
            "{{child.name}} ve {{companion.name}}", "{{child.name}} Bekledi",
            "{{child.name}}'in Gecesi", "{{companion.name}}'ın Uykulu Gecesi"
        ])
        let issues = CatalogIntegrityChecker()
            .check(ContentCatalog(version: "0.0.1", blueprints: [led]))
            .issues(withCode: "title_patterns_name_led")
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.severity, .error)
        XCTAssertEqual(issues.first?.recordID, led.id)

        let fine = try blueprint(patterns: fourPatterns)
        XCTAssertTrue(CatalogIntegrityChecker()
            .check(ContentCatalog(version: "0.0.1", blueprints: [fine]))
            .issues(withCode: "title_patterns_name_led").isEmpty)
    }

    func testIntegrityWarnsAboutTooFewPatterns() throws {
        let thin = try blueprint(patterns: ["{{companion.name}}'ın Uykulu Gecesi", "{{child.name}} Bekledi"])
        let issues = CatalogIntegrityChecker()
            .check(ContentCatalog(version: "0.0.1", blueprints: [thin]))
            .issues(withCode: "title_patterns_too_few")
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.severity, .warning)
    }

    /// Every pattern against every place, companion and discovery the catalog
    /// has: the suffix machinery is reused, never bypassed, so nothing renders
    /// with a raw token, an unknown suffix or an indefinite article.
    func testEveryPatternRendersCleanlyForEveryContentRecord() throws {
        let catalog = try catalog()
        for blueprint in allBlueprints(catalog) {
            for pattern in blueprint.titlePatterns {
                for setting in catalog.settings {
                    for companion in catalog.companions {
                        for object in catalog.objects {
                            let content = BoundContent(setting: setting, companion: companion, discovery: object)
                            let rendered = TurkishTextRenderer.render(
                                pattern,
                                slots: OfflineStoryComposer.slots(childName: "Arda", content: content))
                            XCTAssertTrue(rendered.isClean, "\(blueprint.id) '\(pattern)' → \(rendered.text)")
                            XCTAssertFalse(rendered.text.contains(" bir "), rendered.text)
                            XCTAssertFalse(rendered.text.contains("Arda'in"), rendered.text)
                        }
                    }
                }
            }
        }
    }

    /// Mode voice, kept loose on purpose: a learning story asks, a bedtime
    /// story does not, and every blueprint has a title without the child's name.
    ///
    /// Soru **blueprint başına** ve `admits` üzerinden soruluyor, aile üzerinden
    /// değil (22 Ekim 2026). Eskiden aileye bakıyordu ve o gün `charge` iki
    /// moda birden girdi: aynı blueprint'ten hem "soru sor" hem "sessiz ol"
    /// istenmeye başlandı, yani test kendi kendiyle çelişti. Modları ayıran
    /// şey artık yalnızca aile değil (aile, ark) ikilisi, ve bu soruyu da o
    /// ikili cevaplamalı.
    func testEachModeSoundsLikeItself() throws {
        let catalog = try catalog()
        for blueprint in catalog.blueprints {
            guard blueprint.family != nil else { continue }
            let asking = Set(catalog.storyModes.filter { $0.admits(blueprint) }.map(\.mode))
            let patterns = blueprint.titlePatterns
            XCTAssertTrue(patterns.contains { !TitleComposer.isNameLed($0) }, "\(blueprint.id)")
            if asking.contains(.learning) {
                XCTAssertTrue(patterns.contains { $0.hasSuffix("?") }, "\(blueprint.id): learning asks")
            }
            if asking.contains(.bedtime) {
                XCTAssertFalse(patterns.contains { $0.contains("?") || $0.contains("!") },
                               "\(blueprint.id): bedtime is quiet")
            }
        }
    }

    /// Composed end to end: across many seeds, every title is cover-ready and
    /// each mode offers real variety.
    func testComposedTitlesAreCoverReadyAndVaried() throws {
        let catalog = try catalog()
        let engine = OfflineStoryComposer()
        for mode in [StoryMode.bedtime, .learning, .adventure] {
            for (name, band) in [("Yeliz", AgeBand(lowerBound: 5, upperBound: 6)),
                                 ("Ece", AgeBand(lowerBound: 3, upperBound: 4))] {
                var titles: Set<String> = []
                var nameLed = 0
                var total = 0
                for index in 0..<40 {
                    let intent = OfflineStoryIntent(
                        childName: name, seed: "variety-\(index)", mode: mode, ageBand: band)
                    guard let story = try? engine.compose(catalog: catalog, intent: intent) else { continue }
                    total += 1
                    titles.insert(story.title)
                    if story.title.hasPrefix(name) { nameLed += 1 }
                    XCTAssertTrue(TitleComposer.defects(of: story.title, band: band).isEmpty,
                                  "\(mode) \(band): \(story.title)")
                }
                guard total > 0 else { continue }   // a mode a band does not serve
                XCTAssertGreaterThanOrEqual(titles.count, 4, "\(mode) \(band): \(titles.sorted())")
                XCTAssertLessThan(nameLed * 2, total + 1, "\(mode) \(band): \(nameLed)/\(total) name-led")
            }
        }
    }

    /// The library threads through the intent: a child whose library already
    /// holds today's title gets another one, and the book is otherwise the same.
    func testTheIntentCarriesTheLibraryToTheTitle() throws {
        let catalog = try catalog()
        let engine = OfflineStoryComposer()
        let plain = OfflineStoryIntent(childName: "Yeliz", seed: "lib-1", mode: .bedtime)
        let today = try engine.compose(catalog: catalog, intent: plain)
        let withLibrary = OfflineStoryIntent(
            childName: "Yeliz", seed: "lib-1", mode: .bedtime, recentTitles: [today.title])
        let next = try engine.compose(catalog: catalog, intent: withLibrary)
        XCTAssertNotEqual(next.title, today.title)
        XCTAssertEqual(next.pages.map(\.text), today.pages.map(\.text), "Only the title moves.")
        XCTAssertEqual(next.fingerprint, today.fingerprint, "The fingerprint excludes the title.")
    }

    // MARK: - The experiment copy

    private static var experimentURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Content/Experiments/x_refrain_bedtime.json")
    }

    func testTheExperimentArmKeepsItsControlsTitles() throws {
        let catalog = try catalog()
        let arm = try JSONDecoder().decode(
            ContentCatalog.self, from: Data(contentsOf: Self.experimentURL)).blueprints
        XCTAssertFalse(arm.isEmpty)
        for sibling in arm {
            let controlID = String(sibling.id.rawValue.dropLast("_refrain".count))
            let control = try XCTUnwrap(catalog.blueprints.first { $0.id.rawValue == controlID })
            XCTAssertEqual(sibling.titlePatterns, control.titlePatterns, "\(sibling.id)")
        }
    }
}
