import XCTest
@testable import StoryEngine

/// D8 — the loader reads more than one authored document.
///
/// Until this, `ContentCatalogLoader` located exactly one file: the V1 library,
/// which has no beats and no traits. Everything selectable under the beat model
/// lived in `pilot_library_v1.json`, reachable only by tests. The app could load
/// a catalog successfully and still be unable to build a single story — which is
/// why this is the blocking step of the Story Creation V2 plan.
final class CatalogMergeTests: XCTestCase {

    // MARK: - Merging as an operation

    private func catalog(_ json: String) throws -> ContentCatalog {
        try JSONDecoder().decode(ContentCatalog.self, from: Data(json.utf8))
    }

    func testMergingConcatenatesEveryCollection() throws {
        let a = try catalog("""
        {"version":"1.0.0",
         "settings":[{"id":"s_a","name":"A"}],
         "templates":[{"id":"t_a","role":"hook","variants":[{"id":"v","text":"x"}]}]}
        """)
        let b = try catalog("""
        {"version":"2.0.0",
         "settings":[{"id":"s_b","name":"B"}],
         "companions":[{"id":"c_b","name":"B","type":"tilki"}]}
        """)
        let merged = ContentCatalog.merging([a, b])
        XCTAssertEqual(merged.settings.map(\.id.rawValue), ["s_a", "s_b"])
        XCTAssertEqual(merged.companions.map(\.id.rawValue), ["c_b"])
        XCTAssertEqual(merged.templates.map(\.id.rawValue), ["t_a"])
    }

    func testMergingOneCatalogChangesNothing() throws {
        let only = try catalog(#"{"version":"1.0.0","settings":[{"id":"s","name":"S"}]}"#)
        let merged = ContentCatalog.merging([only])
        XCTAssertEqual(merged.settings.count, 1)
        XCTAssertEqual(merged.version, "1.0.0")
    }

    func testMergingNothingIsAnEmptyCatalogRatherThanACrash() {
        let merged = ContentCatalog.merging([])
        XCTAssertTrue(merged.blueprints.isEmpty)
        XCTAssertTrue(merged.settings.isEmpty)
    }

    /// Duplicate ids are a content defect, and the integrity checker already
    /// names them. Resolving them here — dropping one of two records that claim
    /// the same id — would turn a reportable bug into a mystery.
    func testDuplicateIdsAcrossDocumentsAreReportedNotSilentlyResolved() throws {
        let a = try catalog(#"{"version":"1.0.0","settings":[{"id":"s_dup","name":"First"}]}"#)
        let b = try catalog(#"{"version":"1.0.0","settings":[{"id":"s_dup","name":"Second"}]}"#)
        let merged = ContentCatalog.merging([a, b])

        XCTAssertEqual(merged.settings.count, 2, "Neither record may be dropped.")
        let report = CatalogIntegrityChecker().check(merged)
        XCTAssertFalse(report.issues(withCode: "duplicate_id").isEmpty,
                       "codes: \(report.issues.map(\.code))")
    }

    /// Order is precedence: lookups take the first match, so the document listed
    /// first wins.
    func testTheFirstDocumentTakesPrecedenceInLookups() throws {
        let a = try catalog(#"{"version":"1.0.0","settings":[{"id":"s_dup","name":"First"}]}"#)
        let b = try catalog(#"{"version":"1.0.0","settings":[{"id":"s_dup","name":"Second"}]}"#)
        XCTAssertEqual(
            ContentCatalog.merging([a, b]).settings.first { $0.id.rawValue == "s_dup" }?.name,
            "First")
    }

    // MARK: - The shipped load

    /// Three layers now: the V1 library, the beat-authored pilot library, and
    /// the per-beat prose corpus.
    func testTheLoaderMergesEveryShippedDocument() throws {
        let report = try ContentCatalogLoader().load().report
        XCTAssertEqual(report.mergedSources.prefix(2), [
            "shared_content_library_v2.json",
            "pilot_library_v1.json"
        ])
        let corpus = report.mergedSources.filter { $0.hasPrefix("beat_") }
        XCTAssertFalse(corpus.isEmpty, "The beat corpus was not loaded: \(report.mergedSources)")
        XCTAssertTrue(report.summary.contains("pilot_library_v1.json"),
                      "The summary must say what it loaded: \(report.summary)")
    }

    /// The corpus replaces the library's scaffolding for the beats it covers,
    /// rather than sitting alongside it. Leaving both in the pool leaked prose
    /// written for one blueprint into another.
    func testTheCorpusReplacesScaffoldingForBeatsItCovers() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let corpusBeats = Set(BeatCorpusLoader().load().templates.compactMap(\.realizesBeat))
        XCTAssertFalse(corpusBeats.isEmpty)

        for beat in corpusBeats {
            let realizing = catalog.templates.filter { $0.realizesBeat == beat }
            XCTAssertEqual(realizing.count, 1, "\(beat.rawValue) has \(realizing.count) templates.")
            XCTAssertEqual(realizing.first?.id, BeatCorpusLoader.templateID(for: beat),
                           "\(beat.rawValue) is not the corpus one.")
        }
    }

    /// The reason D8 exists. V1 alone offers nothing the beat model can select.
    func testTheLoadedCatalogContainsBeatAuthoredBlueprints() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let authored = catalog.blueprints.filter(\.isBeatAuthored)
        XCTAssertFalse(authored.isEmpty, "Nothing selectable was loaded.")
        XCTAssertEqual(Set(authored.compactMap(\.family)).count, authored.count,
                       "Each beat-authored blueprint should carry its own family.")
    }

    /// The acceptance criterion, stated as the app will exercise it: a child's
    /// name and a seed, nothing pinned, and a finished Turkish story out.
    func testAStoryComposesFromTheLoadedCatalogWithNothingPinned() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        for seed in ["a", "b", "c", "d", "e"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "Yeliz", seed: seed))
            XCTAssertEqual(story.pages.count, 8, "seed \(seed)")
            XCTAssertTrue(story.isClean, "seed \(seed): "
                + story.pages.flatMap { $0.missingSlots + $0.unrecognisedSuffixes }.joined(separator: ", "))
            XCTAssertFalse(story.title.contains("{{"), story.title)
        }
    }

    /// V1 records carry no traits, so a beat-authored blueprint must never bind
    /// one. Without this the merge would quietly put a trait-less seashell into
    /// a story whose blueprint asked for something that implies a presence.
    func testTraitlessLegacyContentIsNeverBound() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let legacyIDs = Set(
            catalog.settings.filter(\.traits.isEmpty).map(\.id)
                + catalog.companions.filter(\.traits.isEmpty).map(\.id)
                + catalog.objects.filter(\.traits.isEmpty).map(\.id)
        )
        XCTAssertFalse(legacyIDs.isEmpty, "Expected the V1 document to still be present.")

        for seed in ["a", "b", "c", "d", "e", "f", "g", "h"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "Yeliz", seed: seed))
            XCTAssertFalse(legacyIDs.contains(story.content.setting.id), story.content.setting.id.rawValue)
            XCTAssertFalse(legacyIDs.contains(story.content.companion.id), story.content.companion.id.rawValue)
            XCTAssertFalse(legacyIDs.contains(story.content.discovery.id), story.content.discovery.id.rawValue)
        }
    }

    /// D2 said V1 content stays untouched until migration is verified. Merging
    /// must not be the thing that quietly drops it.
    func testLegacyContentSurvivesTheMerge() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        XCTAssertNotNil(catalog.blueprints.first { !$0.isBeatAuthored },
                        "The V1 blueprints were lost.")
        XCTAssertNotNil(catalog.objects.first { $0.id.rawValue == "object_shell_001" },
                        "The V1 seashell was lost.")
        XCTAssertNotNil(catalog.objects.first { $0.id.rawValue == "object_shell_pilot_001" },
                        "The pilot seashell was lost.")
    }

    func testTheCatalogRemainsUsableAfterMerging() throws {
        let report = try XCTUnwrap(try ContentCatalogLoader().load().report.integrity)
        XCTAssertTrue(report.isUsable)
        XCTAssertTrue(report.fatals.isEmpty, report.fatals.map(\.message).joined(separator: " | "))
    }
}

// MARK: - Habitat and binding order

/// D3 — habitat, and what adding it broke.
extension CatalogMergeTests {

    func testContentIsNeverBoundOutsideItsHabitat() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        for seed in ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "Yeliz", seed: seed))
            let setting = story.content.setting.habitat
            XCTAssertTrue(
                TraitMatch.sharesHabitat(story.content.companion.habitat, setting: setting),
                "\(story.content.companion.id.rawValue) in \(story.content.setting.id.rawValue)")
            XCTAssertTrue(
                TraitMatch.sharesHabitat(story.content.discovery.habitat, setting: setting),
                "\(story.content.discovery.id.rawValue) in \(story.content.setting.id.rawValue)")
        }
    }

    /// The specific case the audit named, and that this engine got wrong until
    /// habitat existed.
    func testTheDolphinNeverEndsUpInTheForest() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        XCTAssertThrowsError(
            try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(
                    childName: "Yeliz",
                    settingID: ContentID("setting_whispering_forest_001"),
                    companionID: ContentID("companion_dolphin_pilot_001"),
                    seed: "habitat"))
        )
    }

    /// Habitat couples the axes, so binding them one at a time in order is no
    /// longer enough: a mountain admits no hedgehog, and a blueprint needing
    /// someone small and vulnerable then has nobody — even though a garden
    /// would have worked. The binder has to reconsider the setting.
    func testTheBinderReconsidersTheSettingRatherThanGivingUp() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        // "Someone needs us" leans Appeal, which casts the companion as the
        // one who needs care — a hedgehog or a rabbit, neither of which lives
        // on a mountain.
        for seed in ["a", "b", "c", "d", "e", "f", "g", "h"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(
                    childName: "Yeliz",
                    storyIdeaID: ContentID("idea_someone_needs_us_001"),
                    seed: seed))
            XCTAssertEqual(story.content.castRole, .needsCare)
            XCTAssertTrue(TraitMatch.sharesHabitat(
                story.content.companion.habitat, setting: story.content.setting.habitat))
        }
    }

    func testBacktrackingStaysDeterministic() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        for seed in ["x", "y", "z"] {
            let intent = OfflineStoryIntent(
                childName: "Yeliz",
                storyIdeaID: ContentID("idea_someone_needs_us_001"),
                seed: seed)
            let first = try OfflineStoryComposer().compose(catalog: catalog, intent: intent)
            let second = try OfflineStoryComposer().compose(catalog: catalog, intent: intent)
            XCTAssertEqual(first.fingerprint, second.fingerprint)
            XCTAssertEqual(first.content.setting.id, second.content.setting.id)
        }
    }

    // MARK: Variant selection metadata

    /// A page carrying two beats needs two short lines; a page carrying one
    /// needs a full one. The word band is a **page** budget, not a variant one.
    func testASharedPageAsksForPairedLines() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let byID = Dictionary(
            uniqueKeysWithValues: catalog.templates.flatMap { $0.variants }.map { ($0.id, $0) })

        for seed in ["a", "b", "c", "d", "e", "f"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "Yeliz", seed: seed))
            for page in story.pages {
                let wanted: VariantLengthClass = page.beats.count > 1 ? .paired : .solo
                for id in page.variantIDs {
                    guard let declared = byID[id]?.lengthClass else { continue }
                    XCTAssertEqual(declared, wanted,
                        "p\(page.pageNumber) (\(page.beats.count) beat) used a \(declared.rawValue) line")
                }
            }
        }
    }

    /// A line written to follow a particular beat must only appear after it —
    /// otherwise a story that resolved by asking gets an ending about working
    /// something out.
    func testALineThatFollowsABeatOnlyAppearsAfterIt() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let byID = Dictionary(
            uniqueKeysWithValues: catalog.templates.flatMap { $0.variants }.map { ($0.id, $0) })

        for seed in ["a", "b", "c", "d", "e", "f", "g", "h"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "Yeliz", seed: seed))
            let ordered = story.pages.sorted { $0.pageNumber < $1.pageNumber }
            for (index, page) in ordered.enumerated() where index > 0 {
                let previous = ordered[index - 1].beats.last
                for id in page.variantIDs {
                    guard let after = byID[id]?.afterBeat, !after.isEmpty, let previous else { continue }
                    XCTAssertTrue(after.contains(previous),
                        "p\(page.pageNumber) used a line for \(after.map(\.rawValue)) after \(previous.rawValue)")
                }
            }
        }
    }

    /// A line that assumes something about the content must only be used when
    /// that is true — the structural version of never having the child see a
    /// sound.
    func testALineNeverAssumesContentThatIsNotThere() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let byID = Dictionary(
            uniqueKeysWithValues: catalog.templates.flatMap { $0.variants }.map { ($0.id, $0) })

        for seed in ["a", "b", "c", "d", "e", "f", "g", "h"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "Yeliz", seed: seed))
            for page in story.pages {
                for id in page.variantIDs {
                    guard let variant = byID[id] else { continue }
                    XCTAssertTrue(
                        variant.fits(setting: story.content.setting,
                                     discovery: story.content.discovery,
                                     companion: story.content.companion),
                        "p\(page.pageNumber) used \(id.rawValue), which needs "
                        + "\(variant.settingTraits.map(\.rawValue))/\(variant.discoveryTraits.map(\.rawValue))"
                        + "/\(variant.capabilityRequire.map(\.rawValue))")
                    // A line written for a part must never reach a companion
                    // playing a different one — the cast is resolved once for
                    // the story, so this holds across pages, not just within
                    // them.
                    XCTAssertTrue(
                        variant.suits(role: story.content.castRole),
                        "p\(page.pageNumber) used \(id.rawValue), written for "
                        + "\(variant.castRoles.map(\.rawValue)), but the companion is cast as "
                        + "\(story.content.castRole?.rawValue ?? "nothing")")
                }
            }
        }
    }
}
