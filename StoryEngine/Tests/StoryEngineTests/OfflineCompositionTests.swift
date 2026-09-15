import XCTest
@testable import StoryEngine

/// The S1 vertical slice: one blueprint, its content, and a real Turkish book
/// out the other end.
///
/// Everything before this was verified in pieces — the catalog decoded, the
/// beats validated, the grammar inflected — with nothing proving the pieces fit
/// together. Four defects showed up the first time this ran that no unit test
/// had caught, because each was a seam: a discovery that a page assumed could be
/// *seen* when it was a sound, a common noun landing at the start of a sentence
/// still lowercase, a past copula the resolver does not model, and two adjacent
/// beats both opening with "Ama".
final class OfflineCompositionTests: XCTestCase {

    private func pilotCatalog() throws -> ContentCatalog {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "pilot_threshold_v1", withExtension: "json"),
            "Pilot content package missing from the package bundle."
        )
        return try JSONDecoder().decode(ContentCatalog.self, from: Data(contentsOf: url))
    }

    private func pilotBlueprint() throws -> CatalogBlueprint {
        try XCTUnwrap(pilotCatalog().blueprints.first)
    }

    private func compose(
        child: String = "Yeliz",
        seed: String = "seed-1",
        setting: String? = nil,
        companion: String? = nil,
        discovery: String? = nil
    ) throws -> ComposedStory {
        try OfflineStoryComposer().compose(
            blueprint: pilotBlueprint(),
            catalog: pilotCatalog(),
            intent: OfflineStoryIntent(
                childName: child,
                settingID: setting.map { ContentID($0) },
                companionID: companion.map { ContentID($0) },
                discoveryID: discovery.map { ContentID($0) },
                seed: seed
            )
        )
    }

    // MARK: - The whole loop

    func testComposesAnEightPageStory() throws {
        let story = try compose()
        XCTAssertEqual(story.pages.count, 8)
        XCTAssertEqual(story.pages.map(\.pageNumber), Array(1...8))
        XCTAssertEqual(story.family, .threshold)
        XCTAssertFalse(story.title.isEmpty)
        for page in story.pages {
            XCTAssertFalse(page.text.isEmpty, "Page \(page.pageNumber) is empty.")
            XCTAssertFalse(page.text.contains("{{"), "Unsubstituted token on page \(page.pageNumber).")
        }
    }

    /// The gate that matters: no missing slot and no unrecognised suffix on any
    /// page, for every admissible combination and a spread of seeds.
    func testEveryAdmissibleCombinationRendersCleanly() throws {
        let catalog = try pilotCatalog()
        let blueprint = try pilotBlueprint()
        for setting in catalog.settings {
            for companion in catalog.companions {
                for discovery in catalog.objects {
                    let admissible =
                        TraitMatch.admits(offered: setting.traits,
                                          required: blueprint.requires.setting,
                                          forbidden: blueprint.forbids.setting)
                        && TraitMatch.admits(offered: companion.traits,
                                             required: blueprint.requires.companion,
                                             forbidden: blueprint.forbids.companion)
                        && TraitMatch.admits(offered: discovery.traits,
                                             required: blueprint.requires.discovery,
                                             forbidden: blueprint.forbids.discovery)
                    guard admissible else { continue }

                    for seed in ["a", "b", "c", "d", "e", "f"] {
                        let story = try compose(
                            child: "Yeliz", seed: seed,
                            setting: setting.id.rawValue,
                            companion: companion.id.rawValue,
                            discovery: discovery.id.rawValue
                        )
                        let defects = story.pages
                            .filter { !$0.missingSlots.isEmpty || !$0.unrecognisedSuffixes.isEmpty }
                            .map { "p\($0.pageNumber) missing=\($0.missingSlots) unknown=\($0.unrecognisedSuffixes)" }
                        XCTAssertTrue(
                            defects.isEmpty,
                            "\(setting.id.rawValue)/\(companion.id.rawValue)/\(discovery.id.rawValue) seed \(seed): "
                            + defects.joined(separator: " | ")
                        )
                    }
                }
            }
        }
    }

    /// A discovery may be a light or a sound, so no page may assume a modality.
    /// The first draft read "ince bir sesi … görebildi" — it saw a sound.
    func testNoPageAssumesTheDiscoveryCanBeSeen() throws {
        let sighted = ["gördü", "görebildi", "görünüyordu", "baktı ve gördü"]
        for seed in ["a", "b", "c", "d", "e", "f", "g", "h"] {
            let story = try compose(
                seed: seed,
                setting: "setting_night_garden_001",
                companion: "companion_hedgehog_pilot_001",
                discovery: "object_faint_sound_001"
            )
            for page in story.pages where page.text.contains("ses") {
                for verb in sighted {
                    XCTAssertFalse(
                        page.text.contains(verb),
                        "Page \(page.pageNumber) sees a sound: \(page.text)"
                    )
                }
            }
        }
    }

    // MARK: - Determinism

    func testSameIntentProducesTheSameBook() throws {
        let first = try compose(child: "Yeliz", seed: "stable")
        let second = try compose(child: "Yeliz", seed: "stable")
        XCTAssertEqual(first.fingerprint, second.fingerprint)
        XCTAssertEqual(first.title, second.title)
        XCTAssertEqual(first.pages.map(\.text), second.pages.map(\.text))
    }

    /// Regenerating after a crash must not hand the parent a different story,
    /// but a *different* child must not get the same one either.
    func testDifferentSeedsProduceDifferentBooks() throws {
        let texts = try ["s1", "s2", "s3", "s4", "s5", "s6"].map {
            try compose(child: "Yeliz", seed: $0).pages.map(\.text).joined()
        }
        XCTAssertGreaterThan(Set(texts).count, 1, "Every seed produced the same prose.")
    }

    func testFingerprintChangesWithTheChildsName() throws {
        let a = try compose(child: "Yeliz", seed: "same")
        let b = try compose(child: "Demir", seed: "same")
        XCTAssertNotEqual(a.fingerprint, b.fingerprint)
    }

    // MARK: - Selection

    func testAnExplicitChoiceIsHonoured() throws {
        let story = try compose(
            setting: "setting_night_garden_001",
            companion: "companion_hedgehog_pilot_001",
            discovery: "object_faint_sound_001"
        )
        XCTAssertEqual(story.content.setting.name, "Gece Bahçesi")
        XCTAssertEqual(story.content.companion.name, "Kestane")
        XCTAssertEqual(story.content.discovery.name, "ince bir ses")
    }

    /// The rule the old engine broke: an unusable request is **explained**, not
    /// silently swapped for something that happens to fit.
    func testARejectedRequestIsExplainedNotSubstituted() throws {
        let catalog = try pilotCatalog()
        let blueprint = try pilotBlueprint()
        // A companion that can carry the child across dissolves the premise.
        let carrier = CatalogCompanionFixture.carrying
        let widened = ContentCatalog(
            version: "test",
            settings: catalog.settings,
            companions: catalog.companions + [carrier],
            objects: catalog.objects,
            templates: catalog.templates,
            blueprints: catalog.blueprints
        )

        XCTAssertThrowsError(
            try OfflineStoryComposer().compose(
                blueprint: blueprint, catalog: widened,
                intent: OfflineStoryIntent(
                    childName: "Yeliz",
                    companionID: carrier.id,
                    seed: "s"
                )
            )
        ) { error in
            guard case OfflineSelectionError.requestedContentRejected(let id, let reason) = error else {
                return XCTFail("Wrong error: \(error)")
            }
            XCTAssertEqual(id, carrier.id)
            XCTAssertTrue(reason.contains("canCarry"), reason)
        }
    }

    /// §8.4 — an empty pool is a typed failure carrying every rejection, never
    /// `if filtered.isEmpty { return items }`.
    func testAnEmptyPoolFailsWithReasonsRatherThanFallingBack() throws {
        let catalog = try pilotCatalog()
        let blueprint = try pilotBlueprint()
        let noCompanions = ContentCatalog(
            version: "test",
            settings: catalog.settings,
            companions: [CatalogCompanionFixture.carrying],
            objects: catalog.objects,
            templates: catalog.templates,
            blueprints: catalog.blueprints
        )

        XCTAssertThrowsError(
            try OfflineStoryComposer().compose(
                blueprint: blueprint, catalog: noCompanions,
                intent: OfflineStoryIntent(childName: "Yeliz", seed: "s")
            )
        ) { error in
            guard case OfflineSelectionError.noCompanion(let reasons) = error else {
                return XCTFail("Wrong error: \(error)")
            }
            XCTAssertFalse(reasons.isEmpty, "An empty pool must say why.")
            XCTAssertTrue(reasons.joined().contains("canCarry"))
        }
    }

    func testAMissingTemplateIsNamedByBeatAndPage() throws {
        let catalog = try pilotCatalog()
        let blueprint = try pilotBlueprint()
        let stripped = ContentCatalog(
            version: "test",
            settings: catalog.settings,
            companions: catalog.companions,
            objects: catalog.objects,
            templates: catalog.templates.filter { $0.realizesBeat != .findOwnCourage },
            blueprints: catalog.blueprints
        )

        XCTAssertThrowsError(
            try OfflineStoryComposer().compose(
                blueprint: blueprint, catalog: stripped,
                intent: OfflineStoryIntent(childName: "Yeliz", seed: "s")
            )
        ) { error in
            guard case OfflineSelectionError.noTemplate(let beat, let page) = error else {
                return XCTFail("Wrong error: \(error)")
            }
            XCTAssertEqual(beat, .findOwnCourage)
            XCTAssertEqual(page, 6)
        }
    }

    // MARK: - Composition rules

    /// Text is chosen by beat, never by role — the change that lets five
    /// different families share one `problem` page and not collapse into one
    /// story.
    func testPageTextComesFromTemplatesThatRealizeItsBeats() throws {
        let catalog = try pilotCatalog()
        let story = try compose()
        let beatOf = Dictionary(
            uniqueKeysWithValues: catalog.templates.flatMap { template in
                template.variants.map { ($0.id, template.realizesBeat) }
            }
        )
        for page in story.pages {
            XCTAssertEqual(page.variantIDs.count, page.beats.count)
            for (variantID, beat) in zip(page.variantIDs, page.beats) {
                XCTAssertEqual(beatOf[variantID], beat,
                               "Page \(page.pageNumber) used a variant for the wrong beat.")
            }
        }
    }

    /// A supporting beat is a second sentence on the same page, not a ninth page.
    func testSupportingBeatsAppearOnTheirOwnPage() throws {
        let story = try compose()
        let pagesWithTwo = story.pages.filter { $0.beats.count == 2 }.map(\.pageNumber)
        XCTAssertEqual(pagesWithTwo, [3, 4, 8])
        for page in story.pages where page.beats.count == 2 {
            XCTAssertEqual(page.variantIDs.count, 2)
        }
    }

    func testTitleComesFromAnAuthoredPattern() throws {
        let blueprint = try pilotBlueprint()
        var seen: Set<String> = []
        for seed in ["t1", "t2", "t3", "t4", "t5", "t6"] {
            seen.insert(try compose(seed: seed).title)
        }
        XCTAssertFalse(seen.isEmpty)
        for title in seen {
            XCTAssertFalse(title.contains("{{"), title)
            XCTAssertFalse(title.hasSuffix("Hikâyesi"), "Fell back instead of using a pattern: \(title)")
        }
        XCTAssertGreaterThan(seen.count, 1, "Every seed produced the same title.")
        XCTAssertLessThanOrEqual(seen.count, blueprint.titlePatterns.count * 2)
    }

    /// Composition must not quietly repair an incoherent blueprint: the
    /// validator is the only thing that decides coherence, and a blueprint with
    /// no beats cannot be composed at all.
    func testABlueprintWithoutBeatsIsRefused() throws {
        let catalog = try pilotCatalog()
        let roleOnly = try JSONDecoder().decode(CatalogBlueprint.self, from: Data("""
        {"id":"bp_roles_only","genre":"adventure","theme":"courage","ageRange":"5-6",
         "pageCount":1,"pageRoles":[{"pageNumber":1,"role":"hook"}]}
        """.utf8))

        XCTAssertThrowsError(
            try OfflineStoryComposer().compose(
                blueprint: roleOnly, catalog: catalog,
                intent: OfflineStoryIntent(childName: "Yeliz", seed: "s")
            )
        ) { error in
            guard case OfflineSelectionError.blueprintNotBeatAuthored = error else {
                return XCTFail("Wrong error: \(error)")
            }
        }
    }
}

// MARK: - Fixtures

enum CatalogCompanionFixture {
    /// A companion that would make the threshold trivial to cross.
    static let carrying: CatalogCompanion = {
        try! JSONDecoder().decode(CatalogCompanion.self, from: Data("""
        {"id":"companion_dragon_test_001","name":"Kanat","type":"ejderha",
         "compatibleSettings":["forest"],"tags":["forest"],
         "traits":["canReassure","canCarry","canFly"]}
        """.utf8))
    }()
}
