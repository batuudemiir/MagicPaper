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

    func testTheLoaderMergesBothShippedDocuments() throws {
        let report = try ContentCatalogLoader().load().report
        XCTAssertEqual(report.mergedSources, [
            "shared_content_library_v2.json",
            "pilot_library_v1.json"
        ])
        XCTAssertTrue(report.summary.contains("pilot_library_v1.json"),
                      "The summary must say what it loaded: \(report.summary)")
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
