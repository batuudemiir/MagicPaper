import XCTest
@testable import StoryEngine

/// Proves the shipped catalog is discoverable and decodable from the package
/// bundle — the check that was missing when "no blueprints" could not be explained.
final class CatalogBundleTests: XCTestCase {

    func testTheShippedCatalogIsFoundInThePackageBundle() throws {
        var searched: [String] = []
        let url = ContentCatalogLoader.locate(searched: &searched)
        XCTAssertNotNil(url, "Catalog not found. Searched: \(searched)")
        XCTAssertEqual(searched.first, "Bundle.module", "The package's own bundle must be tried first")
    }

    func testTheShippedCatalogLoadsAndIsUsable() throws {
        let result = try ContentCatalogLoader().load()

        XCTAssertTrue(result.report.source.isFound)
        XCTAssertTrue(result.report.decoded)
        XCTAssertNil(result.report.decodeError)
        XCTAssertFalse(result.catalog.isEmpty)
        XCTAssertEqual(result.catalog.version, "2.0.0")
    }

    func testLoadingReportsThePackageBundleAsItsSource() throws {
        let result = try ContentCatalogLoader().load()
        guard case .packageBundle = result.report.source else {
            return XCTFail("Expected the package bundle, got \(result.report.source)")
        }
    }

    /// The shipped catalog is now two documents merged (D8). Both halves are
    /// pinned: the V1 contribution, so a merge cannot quietly drop it, and the
    /// total, so a new document cannot appear unnoticed.
    func testTheShippedCatalogHasTheExpectedRecordCounts() throws {
        let catalog = try ContentCatalogLoader().load().catalog

        // V1 — unchanged, and identifiable by carrying no beats or traits.
        XCTAssertEqual(catalog.blueprints.filter { !$0.isBeatAuthored }.count, 12)
        XCTAssertEqual(catalog.settings.filter(\.traits.isEmpty).count, 16)
        XCTAssertEqual(catalog.companions.filter(\.traits.isEmpty).count, 15)
        XCTAssertEqual(catalog.objects.filter(\.traits.isEmpty).count, 20)
        XCTAssertEqual(catalog.events.count, 20)
        XCTAssertEqual(catalog.challenges.count, 15)
        XCTAssertEqual(catalog.endings.count, 10)

        // Merged totals.
        XCTAssertEqual(catalog.blueprints.count, 17)
        // 22 with Şenlik Çayırı, the library's only *occupied* place and so the
        // only one that can afford a threshold you join rather than cross.
        XCTAssertEqual(catalog.settings.count, 22)
        XCTAssertEqual(catalog.companions.count, 20)
        XCTAssertEqual(catalog.objects.count, 25)
        // 85 with the corpus complete at 33 beat files, each replacing the
        // library's thinner scaffolding for the beat it covers.
        //
        // These two numbers are pinned on purpose, and they have now earned it
        // twice. A count that does not move when content is added is the only
        // cheap signal that the test bundle's nested resource bundle went stale
        // and the suite is being run against yesterday's corpus — a green run
        // proves nothing about content the tests never loaded. When they fail
        // after an authoring change, read the new number and move the pin.
        XCTAssertEqual(catalog.templates.count, 85)
        XCTAssertEqual(catalog.recordCounts["variants"], 512)
    }

    func testEveryShippedBlueprintDeclaresTheEightBeatArc() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        for blueprint in catalog.blueprints {
            XCTAssertEqual(blueprint.pageCount, 8, "\(blueprint.id)")
            XCTAssertEqual(blueprint.roleSequence, PageRole.mvpArc, "\(blueprint.id) has the wrong arc")
        }
    }

    func testTheCatalogFingerprintIsStable() throws {
        let a = try ContentCatalogLoader().load().catalog.fingerprint
        let b = try ContentCatalogLoader().load().catalog.fingerprint
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.count, 16)
    }

    func testMissingResourceIsReportedWithEverywhereItLooked() {
        // Decoding from data that is not a catalog still succeeds structurally
        // (every field is optional), so the fatal check is what catches it.
        XCTAssertThrowsError(try ContentCatalogLoader().load(data: Data("{}".utf8))) { error in
            guard case CatalogLoadError.unusable(let report) = error else {
                return XCTFail("Expected .unusable, got \(error)")
            }
            XCTAssertTrue(report.fatals.contains { $0.code == "no_blueprints" })
        }
    }

    func testMalformedJSONIsReportedAsUndecodable() {
        XCTAssertThrowsError(try ContentCatalogLoader().load(data: Data("not json".utf8))) { error in
            guard case CatalogLoadError.undecodable = error else {
                return XCTFail("Expected .undecodable, got \(error)")
            }
        }
    }

    func testTheRepositoryCachesAndKeepsItsReport() throws {
        let repository = BundledContentCatalogRepository()
        let first = try repository.catalog()
        let second = try repository.catalog()

        XCTAssertEqual(first.fingerprint, second.fingerprint)
        XCTAssertNotNil(repository.loadReport())
        XCTAssertTrue(repository.loadReport()?.summary.contains("blueprints") == true)
    }
}

/// The integrity checker is the thing that turns silent content faults into
/// something a person can act on. These tests pin what it says about the
/// catalog we actually ship.
final class CatalogIntegrityTests: XCTestCase {

    private func shippedReport() throws -> CatalogIntegrityReport {
        let catalog = try ContentCatalogLoader().load().catalog
        return CatalogIntegrityChecker().check(catalog)
    }

    func testTheShippedCatalogIsUsableDespiteItsFaults() throws {
        let report = try shippedReport()
        XCTAssertTrue(report.isUsable, "Fatals: \(report.fatals.map(\.message))")
        XCTAssertTrue(report.fatals.isEmpty)
    }

    func testEveryRoleBlueprintsNeedHasTemplates() throws {
        // This one is fatal if it ever breaks: a blueprint asking for a role
        // nothing can write cannot produce a book.
        let report = try shippedReport()
        XCTAssertTrue(report.issues(withCode: "role_without_templates").isEmpty)
    }

    func testOrphanSettingTagsAreReported() throws {
        // Known fault: companions want setting tags such as `ocean` that no
        // setting declares. Selection would silently substitute something else.
        let report = try shippedReport()
        let orphans = report.issues(withCode: "orphan_setting_tag")
        XCTAssertFalse(orphans.isEmpty, "The known orphan-tag fault should be surfaced")
        XCTAssertTrue(orphans.allSatisfy { $0.severity == .error })
    }

    func testThemesWithoutTemplatesAreReported() throws {
        let report = try shippedReport()
        XCTAssertFalse(report.issues(withCode: "theme_without_templates").isEmpty,
                       "Themes used by content but unwritable should be surfaced")
    }

    func testUnreachableTemplatesAreReportedAsWarnings() throws {
        // `celebration` and `bedtime_transition` templates exist but no
        // blueprint asks for those roles.
        let report = try shippedReport()
        let stranded = report.issues(withCode: "unreachable_template")
        XCTAssertFalse(stranded.isEmpty)
        XCTAssertTrue(stranded.allSatisfy { $0.severity == .warning })
    }

    func testEmptyCollectionsAreReported() throws {
        // `resolutions` is empty in the shipped catalog.
        let report = try shippedReport()
        XCTAssertFalse(report.issues(withCode: "empty_collection").isEmpty)
    }

    func testAnEmptyCatalogIsFatal() {
        let report = CatalogIntegrityChecker().check(ContentCatalog(version: "0.0.0"))
        XCTAssertFalse(report.isUsable)
        XCTAssertTrue(report.fatals.contains { $0.code == "no_blueprints" })
        XCTAssertTrue(report.fatals.contains { $0.code == "no_templates" })
    }

    func testDuplicateIDsAreReported() throws {
        let json = """
        {"version":"1.0.0",
         "settings":[{"id":"s1","name":"A"},{"id":"s1","name":"B"}],
         "templates":[{"id":"t1","role":"hook","variants":[{"id":"v1","text":"x"}]}],
         "blueprints":[{"id":"b1","genre":"g","theme":"t","ageRange":"5-6","pageCount":1,
                        "pageRoles":[{"pageNumber":1,"role":"hook"}]}]}
        """
        let catalog = try JSONDecoder().decode(ContentCatalog.self, from: Data(json.utf8))
        let report = CatalogIntegrityChecker().check(catalog)
        XCTAssertTrue(report.issues(withCode: "duplicate_id").contains { $0.recordID == "s1" })
    }

    func testPageCountMismatchIsReported() throws {
        let json = """
        {"version":"1.0.0",
         "templates":[{"id":"t1","role":"hook","variants":[{"id":"v1","text":"x"}]}],
         "blueprints":[{"id":"b1","genre":"g","theme":"t","ageRange":"5-6","pageCount":8,
                        "pageRoles":[{"pageNumber":1,"role":"hook"}]}]}
        """
        let catalog = try JSONDecoder().decode(ContentCatalog.self, from: Data(json.utf8))
        let report = CatalogIntegrityChecker().check(catalog)
        XCTAssertTrue(report.issues(withCode: "page_count_mismatch").contains { $0.recordID == "b1" })
    }

    func testTemplateWithoutVariantsIsAnError() throws {
        let json = """
        {"version":"1.0.0",
         "templates":[{"id":"t1","role":"hook","variants":[]}],
         "blueprints":[{"id":"b1","genre":"g","theme":"t","ageRange":"5-6","pageCount":1,
                        "pageRoles":[{"pageNumber":1,"role":"hook"}]}]}
        """
        let catalog = try JSONDecoder().decode(ContentCatalog.self, from: Data(json.utf8))
        let report = CatalogIntegrityChecker().check(catalog)
        XCTAssertTrue(report.issues(withCode: "template_without_variants").contains { $0.recordID == "t1" })
    }

    func testUndeclaredSlotIsReported() throws {
        let json = """
        {"version":"1.0.0",
         "templates":[{"id":"t1","role":"hook","variants":[
            {"id":"v1","text":"Merhaba {{child.name}}, {{setting.name}} güzel.","requiredSlots":["child.name"]}]}],
         "blueprints":[{"id":"b1","genre":"g","theme":"t","ageRange":"5-6","pageCount":1,
                        "pageRoles":[{"pageNumber":1,"role":"hook"}]}]}
        """
        let catalog = try JSONDecoder().decode(ContentCatalog.self, from: Data(json.utf8))
        let report = CatalogIntegrityChecker().check(catalog)
        let issue = report.issues(withCode: "undeclared_slot").first
        XCTAssertNotNil(issue)
        XCTAssertTrue(issue?.message.contains("setting.name") == true)
    }
}

/// The bridge between the pre-beat catalog we ship today and the beat-driven
/// model authored content will use.
final class CatalogBeatMigrationTests: XCTestCase {

    private func shippedReport() throws -> CatalogIntegrityReport {
        CatalogIntegrityChecker().check(try ContentCatalogLoader().load().catalog)
    }

    func testTheShippedCatalogStillLoadsDespiteHavingNoBeats() throws {
        // Deliberate: the pre-beat content stays usable until authored
        // replacements exist, or the offline path has nothing at all.
        let report = try shippedReport()
        XCTAssertTrue(report.isUsable)
        XCTAssertTrue(report.fatals.isEmpty)
    }

    func testTheBeatGapIsReportedRatherThanHidden() throws {
        let report = try shippedReport()
        XCTAssertFalse(report.issues(withCode: "blueprint_without_beats").isEmpty)
        XCTAssertFalse(report.issues(withCode: "template_without_beat").isEmpty)
        // The 12 V1 blueprints; the pilot library's five all declare a family.
        XCTAssertEqual(report.issues(withCode: "blueprint_without_family").count, 12)
    }

    /// This test used to assert the opposite — that nothing shipped was
    /// selectable — which was true and was the problem. D8 makes the loader read
    /// the pilot library too, so the inversion is the point rather than a
    /// regression. What still holds is that no *V1* blueprint became selectable
    /// by accident: the migration is additive, not a rewrite of V1 content.
    func testTheShippedCatalogIsNowSelectableWithoutChangingV1() throws {
        let catalog = try ContentCatalogLoader().load().catalog

        let selectable = catalog.blueprints.filter(\.isBeatAuthored)
        XCTAssertFalse(selectable.isEmpty, "D8 did not load the beat-authored library.")
        XCTAssertFalse(catalog.templates.filter(\.isSelectable).isEmpty)

        // Every selectable blueprint came from the pilot library; not one V1
        // blueprint acquired beats.
        XCTAssertTrue(
            selectable.allSatisfy { $0.family != nil },
            "A V1 blueprint appears to have become beat-authored."
        )
        XCTAssertEqual(catalog.blueprints.filter { !$0.isBeatAuthored }.count, 12)
    }

    func testABeatAuthoredBlueprintValidatesEndToEnd() throws {
        // The shape Phase 3 pilots will ship in.
        let json = """
        {"version":"3.0.0",
         "templates":[
           {"id":"t_notice","role":"hook","realizesBeat":"notice_anomaly","variants":[{"id":"v1","text":"{{child.name}} bir ışık gördü."}]},
           {"id":"t_examine","role":"discovery","realizesBeat":"examine","variants":[{"id":"v2","text":"{{child.name}} yaklaştı."}]},
           {"id":"t_meet","role":"companion","realizesBeat":"meet_companion","variants":[{"id":"v3","text":"{{companion.name}} geldi."}]},
           {"id":"t_belief","role":"problem","realizesBeat":"form_belief","variants":[{"id":"v4","text":"Belki de..."}]},
           {"id":"t_commit","role":"problem","realizesBeat":"commit","variants":[{"id":"v5","text":"Gitmeye karar verdi."}]},
           {"id":"t_attempt","role":"attempt","realizesBeat":"first_attempt","variants":[{"id":"v6","text":"Denedi."}]},
           {"id":"t_obstacle","role":"attempt","realizesBeat":"obstacle_raises","variants":[{"id":"v7","text":"Zor oldu."}]},
           {"id":"t_insight","role":"challenge","realizesBeat":"insight","variants":[{"id":"v8","text":"Birden anladı."}]},
           {"id":"t_succeed","role":"resolution","realizesBeat":"succeed","variants":[{"id":"v9","text":"Başardı."}]},
           {"id":"t_warm","role":"emotional_ending","realizesBeat":"warm_close","variants":[{"id":"v10","text":"Eve döndü."}]}
         ],
         "blueprints":[{"id":"bp_pilot","genre":"adventure","theme":"courage","ageRange":"5-6",
           "pageCount":8,"family":"unexplained","titlePatterns":["{{child.name}} ve Işık"],
           "pages":[
             {"pageNumber":1,"role":"hook","beat":"notice_anomaly","emotion":"ease"},
             {"pageNumber":2,"role":"discovery","beat":"examine","emotion":"curiosity"},
             {"pageNumber":3,"role":"companion","beat":"meet_companion","emotion":"wonder"},
             {"pageNumber":4,"role":"problem","beat":"form_belief","supportingBeat":"commit","emotion":"puzzlement"},
             {"pageNumber":5,"role":"attempt","beat":"first_attempt","supportingBeat":"obstacle_raises","emotion":"determination"},
             {"pageNumber":6,"role":"challenge","beat":"insight","emotion":"insight"},
             {"pageNumber":7,"role":"resolution","beat":"succeed","emotion":"satisfaction"},
             {"pageNumber":8,"role":"emotional_ending","beat":"warm_close","emotion":"warmth"}]}]}
        """
        let result = try ContentCatalogLoader().load(data: Data(json.utf8))
        let blueprint = try XCTUnwrap(result.catalog.blueprints.first)

        XCTAssertTrue(blueprint.isBeatAuthored)
        XCTAssertEqual(blueprint.family, .unexplained)
        XCTAssertTrue(result.catalog.templates.allSatisfy(\.isSelectable))

        let report = try XCTUnwrap(result.report.integrity)
        XCTAssertTrue(report.isUsable)
        XCTAssertTrue(report.issues(withCode: "blueprint_without_beats").isEmpty)
        XCTAssertTrue(report.issues(withCode: "beat_without_templates").isEmpty)
        // Structurally sound: no precondition, pacing or safety violation.
        let fatalBeatIssues = report.issues.filter {
            $0.code.hasPrefix("beat_sequence_") && $0.severity == .fatal
        }
        XCTAssertTrue(fatalBeatIssues.isEmpty,
                      "Pilot arc should satisfy the state rule: \(fatalBeatIssues.map(\.message))")

        // But not beyond criticism. The liveness rule (D9) flags the companion
        // page: this arc still resolves with page 3 deleted, so whatever the
        // companion is doing there, it is not structural. Reported, not fatal —
        // the fix belongs in the beat vocabulary, not in this blueprint.
        let inert = report.issues(withCode: "beat_sequence_inert_page")
        XCTAssertEqual(inert.count, 1, "Expected exactly one inert page: \(report.issues.map(\.code))")
        XCTAssertEqual(inert.first?.severity, .warning)
        XCTAssertTrue(report.isUsable, "A weak page must not stop the catalog loading.")
    }

    func testAnIncoherentBeatAuthoredBlueprintIsFatal() {
        // Page 6 resolves by insight, but no beat ever named an obstacle.
        let json = """
        {"version":"3.0.0",
         "templates":[
           {"id":"t_notice","role":"hook","realizesBeat":"notice_anomaly","variants":[{"id":"v1","text":"x"}]},
           {"id":"t_insight","role":"challenge","realizesBeat":"insight","variants":[{"id":"v2","text":"y"}]},
           {"id":"t_succeed","role":"resolution","realizesBeat":"succeed","variants":[{"id":"v3","text":"z"}]},
           {"id":"t_warm","role":"emotional_ending","realizesBeat":"warm_close","variants":[{"id":"v4","text":"w"}]}
         ],
         "blueprints":[{"id":"bp_broken","genre":"adventure","theme":"courage","ageRange":"5-6",
           "pageCount":4,"family":"unexplained",
           "pages":[
             {"pageNumber":1,"role":"hook","beat":"notice_anomaly","emotion":"ease"},
             {"pageNumber":2,"role":"challenge","beat":"insight","emotion":"insight"},
             {"pageNumber":3,"role":"resolution","beat":"succeed","emotion":"satisfaction"},
             {"pageNumber":4,"role":"emotional_ending","beat":"warm_close","emotion":"warmth"}]}]}
        """
        XCTAssertThrowsError(try ContentCatalogLoader().load(data: Data(json.utf8))) { error in
            guard case CatalogLoadError.unusable(let report) = error else {
                return XCTFail("Expected .unusable, got \(error)")
            }
            XCTAssertTrue(report.fatals.contains { $0.code == "beat_sequence_unmet_precondition" },
                          "An unearned resolution must be a load failure")
        }
    }

    func testABeatWithNoTemplateIsFatal() {
        let json = """
        {"version":"3.0.0",
         "templates":[{"id":"t_notice","role":"hook","realizesBeat":"notice_anomaly","variants":[{"id":"v1","text":"x"}]}],
         "blueprints":[{"id":"bp","genre":"adventure","theme":"courage","ageRange":"5-6",
           "pageCount":2,"family":"threshold",
           "pages":[
             {"pageNumber":1,"role":"hook","beat":"notice_anomaly","emotion":"ease"},
             {"pageNumber":2,"role":"companion","beat":"meet_companion","emotion":"warmth"}]}]}
        """
        XCTAssertThrowsError(try ContentCatalogLoader().load(data: Data(json.utf8))) { error in
            guard case CatalogLoadError.unusable(let report) = error else {
                return XCTFail("Expected .unusable, got \(error)")
            }
            // A slot with no realizing template is a named error, never a
            // silent fallback to "all templates".
            XCTAssertTrue(report.fatals.contains {
                $0.code == "beat_without_templates" && $0.message.contains("meet_companion")
            })
        }
    }
}
