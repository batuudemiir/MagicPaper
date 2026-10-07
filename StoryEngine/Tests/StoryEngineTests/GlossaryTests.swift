import XCTest
@testable import StoryEngine

/// Yeni kelimeler (FAZ 17): a line names the word it teaches, the composer
/// finds it in the rendered sentence and says where it sits on the page.
///
/// The shipped corpus teaches no words yet (the draft waits for review), so
/// the composition tests teach a copy of the real catalog one word per line.
final class GlossaryTests: XCTestCase {

    private static let band = AgeBand(lowerBound: 5, upperBound: 6)
    private static let locale = Locale(identifier: "tr_TR")

    // MARK: - Finding the word

    func testASuffixedWordIsHighlightedToItsEnd() throws {
        let entry = CatalogGlossaryEntry(id: "w_fener", term: "fener", meaning: "Elde taşınan küçük ışık.")
        let found = try XCTUnwrap(GlossaryMatcher.locate(entry, in: "Ayşe fenerini aldı."))
        XCTAssertEqual(found.start, 5)
        XCTAssertEqual(found.length, 8) // "fenerini"
    }

    func testTurkishCaseIsFoldedTheTurkishWay() throws {
        let entry = CatalogGlossaryEntry(id: "w_isik", term: "ışık", meaning: "Aydınlatan şey.")
        let found = try XCTUnwrap(GlossaryMatcher.locate(entry, in: "Işık söndü."))
        XCTAssertEqual(found.start, 0)
        XCTAssertEqual(found.length, 4)
        // Dotted capital İ is i, not ı.
        XCTAssertNil(GlossaryMatcher.locate(entry, in: "İşık söndü."))
    }

    func testAWordInsideAnotherWordIsNotIt() {
        let entry = CatalogGlossaryEntry(id: "w_fener", term: "fener", meaning: "Işık.")
        XCTAssertNil(GlossaryMatcher.locate(entry, in: "Kafeneri gördü."))
    }

    func testAChangedStemIsFoundByItsListedForm() throws {
        let entry = CatalogGlossaryEntry(
            id: "w_agac", term: "ağaç", forms: ["ağaç", "ağac"], meaning: "Gövdesi ve dalları olan büyük bitki.")
        let found = try XCTUnwrap(GlossaryMatcher.locate(entry, in: "Kirpi ağacın altında uyudu."))
        XCTAssertEqual(found.start, 6)
        XCTAssertEqual(found.length, 6) // "ağacın"
    }

    func testFormsDefaultToTheTerm() throws {
        let data = Data(#"{"id":"w_kum","term":"kum","meaning":"Çok küçük taş taneleri."}"#.utf8)
        let entry = try JSONDecoder().decode(CatalogGlossaryEntry.self, from: data)
        XCTAssertEqual(entry.forms, ["kum"])
        XCTAssertTrue(entry.bands.isEmpty)
    }

    // MARK: - On the composed page

    /// The first plain word of a line (no slot, four letters or more), so the
    /// test can teach every line something it really says.
    private func plainWord(in text: String) -> String? {
        let withoutSlots = text.replacingOccurrences(
            of: #"\{\{[^}]*\}\}\S*"#, with: " ", options: .regularExpression)
        return withoutSlots
            .split(whereSeparator: { !$0.isLetter })
            .map(String.init)
            .first { $0.count >= 4 }
    }

    private func taught(_ full: ContentCatalog, bands: [AgeBand] = []) -> ContentCatalog {
        var glossary: [CatalogGlossaryEntry] = []
        func teach(_ template: CatalogTemplate) -> CatalogTemplate {
            let variants = template.variants.map { variant -> CatalogVariant in
                guard let word = plainWord(in: variant.text) else { return variant }
                let id = ContentID("w_\(variant.id.rawValue)")
                glossary.append(CatalogGlossaryEntry(
                    id: id, term: word.lowercased(with: Self.locale),
                    meaning: "Anlamı.", bands: bands))
                // Through Codable, the same way the corpus loader builds lines.
                guard let data = try? JSONEncoder().encode(variant),
                      var object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return variant
                }
                object["words"] = [id.rawValue]
                return (try? JSONDecoder().decode(
                    CatalogVariant.self, from: JSONSerialization.data(withJSONObject: object))) ?? variant
            }
            return CatalogTemplate(
                id: template.id, role: template.role, realizesBeat: template.realizesBeat,
                compatibleThemes: template.compatibleThemes, variants: variants, ageBand: template.ageBand)
        }
        let templates = full.templates.map(teach)
        return ContentCatalog(
            version: full.version,
            settings: full.settings, companions: full.companions, objects: full.objects,
            events: full.events, challenges: full.challenges, endings: full.endings,
            templates: templates, blueprints: full.blueprints,
            storyIdeas: full.storyIdeas, storyModes: full.storyModes,
            familyMoments: full.familyMoments, familyAnimalKinds: full.familyAnimalKinds,
            interests: full.interests, safetyTopics: full.safetyTopics,
            glossary: glossary, series: full.series)
    }

    /// Every word lands where the page text has it, including after a sentence
    /// whose slots changed its length ("Yeliz", a companion name).
    func testEveryWordSitsWhereThePageSaysIt() throws {
        let catalog = taught(try ContentCatalogLoader().load().catalog)
        var words = 0
        for mode in StoryMode.allCases {
            for seed in ["a", "b", "c", "d"] {
                guard let story = try? OfflineStoryComposer().compose(catalog: catalog, intent: OfflineStoryIntent(
                    childName: "Yeliz", seed: seed, mode: mode, ageBand: Self.band)) else { continue }
                for page in story.pages {
                    let characters = Array(page.text)
                    for word in page.words {
                        words += 1
                        XCTAssertLessThanOrEqual(word.start + word.length, characters.count, "\(page.text)")
                        let slice = String(characters[word.start..<(word.start + word.length)])
                            .lowercased(with: Self.locale)
                        XCTAssertTrue(slice.hasPrefix(word.term), "'\(slice)' for '\(word.term)' in \(page.text)")
                        if word.start > 0 { XCTAssertFalse(characters[word.start - 1].isLetter) }
                        XCTAssertEqual(word.meaning, "Anlamı.")
                    }
                }
            }
        }
        XCTAssertGreaterThan(words, 20)
    }

    /// Teaching words changes no text and no choice.
    func testTeachingWordsChangesNothingElse() throws {
        let plain = try ContentCatalogLoader().load().catalog
        let catalog = taught(plain)
        for mode in StoryMode.allCases {
            for seed in ["a", "b", "c"] {
                let intent = OfflineStoryIntent(childName: "Can", seed: seed, mode: mode, ageBand: Self.band)
                let before = try? OfflineStoryComposer().compose(catalog: plain, intent: intent)
                let after = try? OfflineStoryComposer().compose(catalog: catalog, intent: intent)
                XCTAssertEqual(before?.fingerprint, after?.fingerprint)
                XCTAssertEqual(before?.pages.map(\.text), after?.pages.map(\.text))
                XCTAssertTrue(before?.pages.allSatisfy { $0.words.isEmpty } ?? true)
            }
        }
    }

    func testAWordWrittenForAnotherBandIsNotHighlighted() throws {
        let catalog = taught(try ContentCatalogLoader().load().catalog, bands: [AgeBand(lowerBound: 3, upperBound: 4)])
        let story = try OfflineStoryComposer().compose(catalog: catalog, intent: OfflineStoryIntent(
            childName: "Yeliz", seed: "a", mode: .bedtime, ageBand: Self.band))
        XCTAssertTrue(story.pages.allSatisfy { $0.words.isEmpty })
    }

    // MARK: - Integrity

    func testAWordTheLineDoesNotSayIsAnError() throws {
        let full = try ContentCatalogLoader().load().catalog
        let template = try XCTUnwrap(full.templates.first { !$0.variants.isEmpty })
        let variant = try XCTUnwrap(template.variants.first)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(variant)) as? [String: Any])
        object["words"] = ["w_zurafa", "w_missing"]
        let lying = try JSONDecoder().decode(CatalogVariant.self, from: JSONSerialization.data(withJSONObject: object))
        let catalog = ContentCatalog(
            version: "0",
            templates: [CatalogTemplate(
                id: template.id, role: template.role, realizesBeat: template.realizesBeat,
                variants: [lying], ageBand: template.ageBand)],
            glossary: [CatalogGlossaryEntry(id: "w_zurafa", term: "zürafa", meaning: "Boynu uzun hayvan.")])
        let report = CatalogIntegrityChecker().check(catalog)
        XCTAssertEqual(report.issues(withCode: "glossary_word_not_in_line").count, 1)
        XCTAssertEqual(report.issues(withCode: "unknown_glossary_word").count, 1)
    }

    func testTheShippedGlossaryIsClean() throws {
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        for code in ["duplicate_glossary_entry", "glossary_entry_without_meaning",
                     "unknown_glossary_word", "glossary_word_not_in_line"] {
            XCTAssertTrue(report.issues(withCode: code).isEmpty, "\(code): \(report.issues(withCode: code))")
        }
    }
}
