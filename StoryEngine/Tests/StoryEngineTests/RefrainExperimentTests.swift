import XCTest
@testable import StoryEngine

/// The declared refrain (book research `p_repeated_line`, approved 14 October
/// 2026) and the experiment arm that uses it.
///
/// The arm lives in `Content/Experiments/x_refrain_bedtime.json`, which the app
/// never loads. These tests merge it in memory to show it composes and passes
/// the same checks as the shipped catalog; it reaches a child only through a
/// published package, after the owner marks the experiment live.
final class RefrainExperimentTests: XCTestCase {

    private static var experimentURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // StoryEngineTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // StoryEngine
            .deletingLastPathComponent()   // repo
            .appendingPathComponent("Content/Experiments/x_refrain_bedtime.json")
    }

    private func shipped() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    private func experiment() throws -> ContentCatalog {
        try JSONDecoder().decode(ContentCatalog.self, from: Data(contentsOf: Self.experimentURL))
    }

    private func merged() throws -> ContentCatalog {
        ContentCatalog.merging([try shipped(), try experiment()])
    }

    private func siblings() throws -> [CatalogBlueprint] {
        try experiment().blueprints
    }

    private func intent(_ seed: String) -> OfflineStoryIntent {
        OfflineStoryIntent(childName: "Yeliz", seed: seed)
    }

    private func words(_ text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    // MARK: - Nothing ships

    func testNoShippedBlueprintCarriesARefrain() throws {
        let catalog = try shipped()
        let carrying = (catalog.blueprints + catalog.series.continuations).filter { $0.refrain != nil }
        XCTAssertTrue(carrying.isEmpty, "Refrains are experimental: \(carrying.map(\.id.rawValue))")
    }

    // MARK: - The arm

    func testTheArmIsTwoBedtimeSiblingsOfShippedBlueprints() throws {
        let catalog = try shipped()
        let arm = try siblings()
        XCTAssertEqual(Set(arm.map(\.ageRange.description)), ["3-4", "5-6"])
        for sibling in arm {
            let controlID = String(sibling.id.rawValue.dropLast("_refrain".count))
            let control = try XCTUnwrap(catalog.blueprints.first { $0.id.rawValue == controlID },
                                        "\(sibling.id) has no shipped control \(controlID)")
            XCTAssertNotNil(sibling.refrain)
            XCTAssertEqual(sibling.pagePlan, control.pagePlan, "Only the refrain may differ.")
            XCTAssertEqual(sibling.family, control.family)
            XCTAssertEqual(sibling.ageRange, control.ageRange)
            XCTAssertEqual(sibling.requires, control.requires)
            XCTAssertEqual(sibling.forbids, control.forbids)
            XCTAssertEqual(sibling.family, .charge, "Bedtime serves the charge family.")
        }
    }

    func testTheMergedCatalogAddsNoIntegrityProblem() throws {
        let before = CatalogIntegrityChecker().check(try shipped())
        let after = CatalogIntegrityChecker().check(try merged())
        let added = Set(after.issues.filter { $0.severity != .warning }.map(\.code))
            .subtracting(before.issues.filter { $0.severity != .warning }.map(\.code))
        XCTAssertTrue(added.isEmpty, "New errors: \(added.sorted())")
        XCTAssertTrue(after.issues.filter { $0.code.hasPrefix("refrain_") }.isEmpty,
                      after.issues.filter { $0.code.hasPrefix("refrain_") }.map(\.message).joined(separator: "\n"))
    }

    func testTheRefrainEndsItsDeclaredPagesAndChangesOnTheLast() throws {
        let catalog = try merged()
        for sibling in try siblings() {
            let refrain = try XCTUnwrap(sibling.refrain)
            for seed in ["a", "b", "c", "d", "e", "f", "g", "h"] {
                let story = try OfflineStoryComposer().compose(
                    blueprint: sibling, catalog: catalog, intent: intent(seed))
                for page in story.pages {
                    let expected = refrain.text(onPage: page.pageNumber)
                    XCTAssertEqual(page.refrain, expected, "\(sibling.id) p\(page.pageNumber)")
                    if let expected {
                        XCTAssertTrue(page.text.hasSuffix(" " + expected), "\(sibling.id) p\(page.pageNumber): \(page.text)")
                    } else {
                        XCTAssertFalse(page.text.contains(refrain.line), "\(sibling.id) p\(page.pageNumber)")
                    }
                }
            }
        }
    }

    /// The page budget holds for the story's own lines; the refrain is allowed
    /// on top, and no more than `RefrainSpec.maxWords`.
    func testPagesStayInsideTheBudgetPlusTheRefrain() throws {
        let catalog = try merged()
        var outOfBudget: [String] = []
        for sibling in try siblings() {
            let band = sibling.ageRange.pageBudget
            for seed in ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"] {
                let story = try OfflineStoryComposer().compose(
                    blueprint: sibling, catalog: catalog, intent: intent(seed))
                for page in story.pages {
                    let refrainWords = page.refrain.map(words) ?? 0
                    XCTAssertLessThanOrEqual(refrainWords, RefrainSpec.maxWords)
                    let own = words(page.text) - refrainWords
                    if own < band.lower || own > band.upper {
                        outOfBudget.append("\(sibling.id) seed \(seed) p\(page.pageNumber): \(own) words")
                    }
                }
            }
        }
        XCTAssertTrue(outOfBudget.isEmpty, outOfBudget.joined(separator: "\n"))
    }

    /// Accidental repetition stays a defect: every phrase that repeats across
    /// pages of a refrain book either repeats in the same book without its
    /// refrain or is made of the refrain's own words.
    func testTheRefrainIsTheOnlyRepetitionItAdds() throws {
        let catalog = try merged()
        let size = 5
        func repeated(_ texts: [String]) -> Set<String> {
            var seen: [String: Int] = [:]
            for text in texts { for gram in Set(TextMetrics.nGrams(text, size: size)) { seen[gram, default: 0] += 1 } }
            return Set(seen.filter { $0.value > 1 }.keys)
        }
        for sibling in try siblings() {
            let refrain = try XCTUnwrap(sibling.refrain)
            let refrainWords = Set(TextMetrics.words(refrain.finalLine.lowercased()))
            for seed in ["a", "b", "c", "d"] {
                let story = try OfflineStoryComposer().compose(
                    blueprint: sibling, catalog: catalog, intent: intent(seed))
                let with = repeated(story.pages.map(\.text))
                let without = repeated(story.pages.map { page in
                    guard let line = page.refrain else { return page.text }
                    return String(page.text.dropLast(line.count)).trimmingCharacters(in: .whitespaces)
                })
                let added = with.subtracting(without).filter { gram in
                    // A gram that reaches into the refrain is the refrain's repetition.
                    !TextMetrics.words(gram).contains(where: refrainWords.contains)
                }
                // No assertion that the refrain itself shows up as a repeat: a
                // four-word refrain is shorter than the five-word window, so the
                // repetition metric never counts it. Its presence on every
                // declared page is asserted above.
                XCTAssertTrue(added.isEmpty, "\(sibling.id) seed \(seed): \(added.sorted())")
            }
        }
    }

    // MARK: - The integrity gate

    private func codes(for refrain: [String: Any]) throws -> Set<String> {
        let source = try XCTUnwrap(
            (try JSONSerialization.jsonObject(with: Data(contentsOf: Self.experimentURL)) as? [String: Any])?["blueprints"]
                as? [[String: Any]])
        var blueprint = try XCTUnwrap(source.first { ($0["ageRange"] as? String) == "5-6" })
        blueprint["refrain"] = refrain
        let data = try JSONSerialization.data(withJSONObject: ["version": "test", "blueprints": [blueprint]])
        let catalog = try JSONDecoder().decode(ContentCatalog.self, from: data)
        return Set(CatalogIntegrityChecker().check(catalog).issues.map(\.code).filter { $0.hasPrefix("refrain_") })
    }

    func testTheGateRejectsBadRefrains() throws {
        let good: [String: Any] = ["line": "Usul usul, yavaş yavaş.", "pages": [2, 4, 6],
                                   "finalLine": "Usul usul, uyku geldi.", "finalPage": 8]
        XCTAssertEqual(try codes(for: good), [])

        var once = good; once["pages"] = [2]
        XCTAssertTrue(try codes(for: once).contains("refrain_too_few_pages"))
        var long = good; long["line"] = "Usul usul, yavaş yavaş, sessizce, sabırla, hep birlikte."
        XCTAssertTrue(try codes(for: long).contains("refrain_too_long"))
        var slot = good; slot["line"] = "{{child.name}} usul usul."
        XCTAssertTrue(try codes(for: slot).contains("refrain_has_slot"))
        var same = good; same["finalLine"] = good["line"]
        XCTAssertTrue(try codes(for: same).contains("refrain_final_unchanged"))
        var early = good; early["finalPage"] = 7
        XCTAssertTrue(try codes(for: early).contains("refrain_final_not_on_last_page"))
        var stray = good; stray["pages"] = [2, 4, 12]
        XCTAssertTrue(try codes(for: stray).contains("refrain_page_missing"))
        var restless = good; restless["finalLine"] = "Usul usul, yarın ne olacak?"
        XCTAssertTrue(try codes(for: restless).contains("refrain_final_not_calm"))
    }

    func testARefrainSurvivesEncodingAndDecoding() throws {
        let sibling = try XCTUnwrap(try siblings().first)
        let data = try JSONEncoder().encode(sibling)
        let back = try JSONDecoder().decode(CatalogBlueprint.self, from: data)
        XCTAssertEqual(back.refrain, sibling.refrain)
        XCTAssertEqual(back, sibling)
    }
}
