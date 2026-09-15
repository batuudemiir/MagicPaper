import XCTest
@testable import StoryEngine

/// The word budget is a **page** budget.
///
/// The corpus session validates each variant against its declared band. That
/// cannot see the property that matters to a reader: a page is often two
/// variants concatenated, and two individually-valid lines can still produce a
/// page outside the budget. So this is the check that belongs on this side of
/// the seam — they validate lines, the engine validates pages.
final class PageBudgetTests: XCTestCase {

    /// 18–38 words per page, from the catalog's shared constraints.
    private let pageBudget = BeatCorpusLoader.WordBand(lower: 18, upper: 38)

    private func words(_ text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    // MARK: - Bands are read, not assumed

    /// `companion_offers` is banded 8–14, not the usual paired 10–16, because
    /// `meet_companion` is a long partner and the two share page 3. A composer
    /// that assumed one paired band would pass lines that put the page out of
    /// budget.
    func testPerBeatBandsAreReadFromTheCorpus() {
        let bands = BeatCorpusLoader().load().bands
        XCTAssertFalse(bands.isEmpty, "No band was parsed from any beat file.")

        if let offers = bands[.companionOffers]?[.paired] {
            XCTAssertNotEqual(offers.upper, 16,
                "companion_offers should carry its own narrower band, not the default.")
        } else {
            XCTFail("companion_offers declares no paired band: \(bands.keys.map(\.rawValue).sorted())")
        }
    }

    func testDeclaredBandsParseIntoUsableNumbers() {
        for (beat, classes) in BeatCorpusLoader().load().bands {
            for (kind, band) in classes {
                XCTAssertLessThan(band.lower, band.upper, "\(beat.rawValue)/\(kind.rawValue)")
                XCTAssertGreaterThan(band.lower, 0)
            }
        }
    }

    /// Every variant sits inside the band its own beat declares for its class —
    /// measured on the **rendered** text.
    ///
    /// Counting the template instead is measuring the wrong thing, and it
    /// produced a false positive the first time this ran: `{{setting.name}}` is
    /// one token and "Fısıldayan Orman" is two words, so a line that reads as 18
    /// counted as 17. The budget is about what a child hears read aloud, so the
    /// count has to happen after substitution.
    func testEveryCorpusVariantIsInsideItsOwnDeclaredBandWhenRendered() throws {
        let report = BeatCorpusLoader().load()
        let slots: [String: TurkishTextRenderer.Slot] = [
            "child.name": .init("Yeliz", isProperNoun: true),
            "setting.name": .init("Fısıldayan Orman", isProperNoun: true),
            "companion.name": .init("Tarçın", isProperNoun: true),
            "companion.type": .init("tilki", isProperNoun: false),
            "discovery.name": .init("titrek bir ışık", isProperNoun: false),
            "discovery.title": .init("Titrek Işık", isProperNoun: false)
        ]

        var outOfBand: [String] = []
        for template in report.templates {
            guard let beat = template.realizesBeat,
                  let classes = report.bands[beat] else { continue }
            for variant in template.variants {
                guard let kind = variant.lengthClass, let band = classes[kind] else { continue }
                let rendered = TurkishTextRenderer.render(variant.text, slots: slots)
                let count = words(rendered.text)
                if !band.contains(count) {
                    outOfBand.append("\(variant.id.rawValue) (\(beat.rawValue)/\(kind.rawValue)): "
                                     + "\(count) words, band \(band.lower)–\(band.upper)")
                }
            }
        }
        XCTAssertTrue(outOfBand.isEmpty, outOfBand.joined(separator: "\n"))
    }

    // MARK: - Pages, which is what a reader sees

    func testComposedPagesLandInsideThePageBudget() throws {
        let catalog = try catalog()
        var outOfBudget: [String] = []

        for seed in ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "Yeliz", seed: seed))
            for page in story.pages {
                // Only judge pages written entirely from the banded corpus;
                // the library's remaining scaffolding declares no band.
                let banded = page.variantIDs.allSatisfy { id in
                    catalog.templates.flatMap(\.variants)
                        .first { $0.id == id }?.lengthClass != nil
                }
                guard banded else { continue }
                let count = words(page.text)
                if !pageBudget.contains(count) {
                    outOfBudget.append("seed \(seed) p\(page.pageNumber): \(count) words "
                                       + "(\(page.beats.map(\.rawValue).joined(separator: "+")))")
                }
            }
        }

        XCTAssertTrue(outOfBudget.isEmpty,
                      "Pages outside \(pageBudget.lower)–\(pageBudget.upper) words:\n"
                      + outOfBudget.joined(separator: "\n"))
    }

    /// A page is never empty and never a single word — the cheap sanity check
    /// that would catch a variant lost to a bad merge.
    func testNoPageIsEmpty() throws {
        let catalog = try catalog()
        for seed in ["a", "b", "c"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "Yeliz", seed: seed))
            for page in story.pages {
                XCTAssertGreaterThan(words(page.text), 3, "p\(page.pageNumber): \(page.text)")
            }
        }
    }
}
