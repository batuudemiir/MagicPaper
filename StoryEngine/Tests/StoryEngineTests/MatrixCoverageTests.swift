import XCTest
@testable import StoryEngine

/// The Phase 4 matrix: five content combinations that must each produce a book.
///
/// The naive way to satisfy this would be to widen Pilot A until it accepts
/// everything, which §8.3 exists to forbid — a companion that can carry the
/// child across dissolves a threshold story without breaking anything. So
/// coverage is bought with **more blueprints**, not looser ones: the library
/// now holds one blueprint per family the matrix needs, and the child's
/// discovery is what recruits the family.
final class MatrixCoverageTests: XCTestCase {

    private func library() throws -> ContentCatalog {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "pilot_library_v1", withExtension: "json"),
            "Pilot library missing from the package bundle."
        )
        return try JSONDecoder().decode(ContentCatalog.self, from: Data(contentsOf: url))
    }

    /// The five combinations from `BLUEPRINT_ARCHITECTURE.md` §16.
    private static let matrix: [(name: String, setting: String, companion: String, discovery: String)] = [
        ("forest+fox+light",        "setting_whispering_forest_001", "companion_fox_pilot_001",      "object_flickering_light_001"),
        ("mountain+owl+footprints", "setting_cloud_mountain_001",    "companion_owl_pilot_001",      "object_footprints_001"),
        ("garden+hedgehog+sound",   "setting_night_garden_001",      "companion_hedgehog_pilot_001", "object_faint_sound_001"),
        ("sea+dolphin+shell",       "setting_coral_sea_001",         "companion_dolphin_pilot_001",  "object_shell_001"),
        ("forest+rabbit+map",       "setting_whispering_forest_001", "companion_rabbit_pilot_001",   "object_torn_map_001"),
    ]

    private func intent(_ row: (name: String, setting: String, companion: String, discovery: String),
                        child: String = "Yeliz", seed: String) -> OfflineStoryIntent {
        OfflineStoryIntent(
            childName: child,
            settingID: ContentID(row.setting),
            companionID: ContentID(row.companion),
            discoveryID: ContentID(row.discovery),
            seed: seed
        )
    }

    // MARK: - Coverage

    func testEveryMatrixRowProducesACleanStory() throws {
        let catalog = try library()
        for row in Self.matrix {
            for seed in ["a", "b", "c", "d", "e"] {
                let story: ComposedStory
                do {
                    story = try OfflineStoryComposer().compose(
                        catalog: catalog, intent: intent(row, seed: seed))
                } catch {
                    return XCTFail("\(row.name) seed \(seed): "
                                   + ((error as? OfflineSelectionError)?.explanation ?? "\(error)"))
                }
                XCTAssertEqual(story.pages.count, 8, row.name)
                let defects = story.pages
                    .filter { !$0.missingSlots.isEmpty || !$0.unrecognisedSuffixes.isEmpty }
                    .map { "p\($0.pageNumber) missing=\($0.missingSlots) unknown=\($0.unrecognisedSuffixes)" }
                XCTAssertTrue(defects.isEmpty, "\(row.name) seed \(seed): \(defects.joined(separator: " | "))")
                XCTAssertFalse(story.title.contains("{{"), story.title)
                for page in story.pages {
                    XCTAssertFalse(page.text.contains("{{"),
                                   "\(row.name) p\(page.pageNumber): \(page.text)")
                }
            }
        }
    }

    /// Coverage must not have been bought by loosening Pilot A. If every row
    /// resolved to the same family, the constraints would have stopped doing
    /// work — which is the failure mode this whole design exists to prevent.
    func testTheMatrixIsCoveredByMoreThanOneFamily() throws {
        let catalog = try library()
        var families: Set<NarrativeFamily> = []
        for row in Self.matrix {
            for seed in ["a", "b", "c", "d", "e", "f", "g", "h"] {
                let story = try OfflineStoryComposer().compose(
                    catalog: catalog, intent: intent(row, seed: seed))
                if let family = story.family { families.insert(family) }
            }
        }
        XCTAssertGreaterThanOrEqual(families.count, 4,
            "Only \(families.map(\.rawValue).sorted()) reachable across the whole matrix.")
    }

    func testLibraryHoldsOneBlueprintPerFamily() throws {
        let blueprints = try library().blueprints
        let families = blueprints.compactMap(\.family)
        XCTAssertEqual(families.count, blueprints.count, "A blueprint declares no family.")
        XCTAssertEqual(Set(families).count, families.count, "Two blueprints share a family.")
        XCTAssertGreaterThanOrEqual(families.count, 5)
    }

    /// Every blueprint in the library must be coherent on its own terms. This
    /// is the rule that decides whether authored content ships.
    func testEveryBlueprintPassesTheBeatSequenceValidator() throws {
        for blueprint in try library().blueprints {
            XCTAssertTrue(blueprint.isBeatAuthored, "\(blueprint.id.rawValue) has no beats.")
            let result = BeatSequenceValidator().validate(
                blueprint.beatSlots, conflictMechanism: blueprint.family?.conflict)
            XCTAssertTrue(result.isValid, "\(blueprint.id.rawValue): "
                + result.issues.map { "p\($0.pageNumber) \($0.code)" }.joined(separator: ", "))
            XCTAssertTrue(blueprint.contradictoryTraits.isEmpty,
                          "\(blueprint.id.rawValue) requires and forbids \(blueprint.contradictoryTraits)")
        }
    }

    func testEveryBeatAskedForHasATemplateThatRealizesIt() throws {
        let catalog = try library()
        let asked = Set(catalog.blueprints.flatMap { $0.beatSlots.flatMap(\.beats) })
        let realized = Set(catalog.templates.compactMap(\.realizesBeat))
        XCTAssertTrue(asked.subtracting(realized).isEmpty,
                      "unrealized: \(asked.subtracting(realized).map(\.rawValue).sorted())")
        XCTAssertTrue(realized.subtracting(asked).isEmpty,
                      "unreachable: \(realized.subtracting(asked).map(\.rawValue).sorted())")
    }

    // MARK: - Recruitment (§8.2)

    /// Two discovery kinds with the same traits cannot recruit different
    /// families, because recruitment *is* trait intersection. §8.2 gives
    /// footprints and a torn map identical traits and then assigns them
    /// different family sets — an inconsistency in the document. Resolved by
    /// giving the map `isUnexplained`: it has to be read, footprints do not.
    func testNoTwoDiscoveriesShareATraitSet() throws {
        let objects = try library().objects
        var seen: [Set<DiscoveryTrait>: String] = [:]
        for object in objects {
            if let clash = seen[object.traits] {
                XCTFail("'\(object.id.rawValue)' and '\(clash)' have identical traits "
                        + "\(object.traits.map(\.rawValue).sorted()); they can never recruit "
                        + "different families.")
            }
            seen[object.traits] = object.id.rawValue
        }
    }

    /// Which families each discovery can recruit, judged on the discovery axis
    /// alone so the result does not depend on which companion happens to be
    /// available.
    private func recruits(_ discoveryID: String, in catalog: ContentCatalog) throws -> Set<NarrativeFamily> {
        let discovery = try XCTUnwrap(catalog.objects.first { $0.id.rawValue == discoveryID })
        return Set(catalog.blueprints.filter {
            TraitMatch.admits(offered: discovery.traits,
                              required: $0.requires.discovery,
                              forbidden: $0.forbids.discovery)
        }.compactMap(\.family))
    }

    func testDiscoveryRecruitmentMatchesTheArchitecture() throws {
        let catalog = try library()
        // §8.2, restricted to the five families the library implements.
        XCTAssertEqual(try recruits("object_flickering_light_001", in: catalog),
                       [.unexplained, .threshold], "a light")
        XCTAssertEqual(try recruits("object_footprints_001", in: catalog),
                       [.absence, .misreading], "footprints")
        XCTAssertEqual(try recruits("object_faint_sound_001", in: catalog),
                       [.unexplained, .threshold, .appeal], "a sound")
        XCTAssertEqual(try recruits("object_torn_map_001", in: catalog),
                       [.unexplained, .absence, .misreading], "a torn map")
    }

    // MARK: - Exclusions still bite

    func testALiteralMindedCompanionCannotCarryAMisreading() throws {
        let catalog = try library()
        let misreading = try XCTUnwrap(catalog.blueprints.first { $0.family == .misreading })
        let rabbit = try XCTUnwrap(catalog.companions.first { $0.id.rawValue == "companion_rabbit_pilot_001" })
        XCTAssertTrue(rabbit.traits.contains(.isLiteralMinded))
        XCTAssertFalse(TraitMatch.admits(offered: rabbit.traits,
                                         required: misreading.requires.companion,
                                         forbidden: misreading.forbids.companion),
                       "A companion that says exactly what it sees corrects the child on page 3.")
    }

    func testALocalExpertCannotCarryAnInsightOrASearch() throws {
        let catalog = try library()
        let fox = try XCTUnwrap(catalog.companions.first { $0.id.rawValue == "companion_fox_pilot_001" })
        XCTAssertTrue(fox.traits.contains(.hasLocalKnowledge))
        for family in [NarrativeFamily.unexplained, .absence] {
            let blueprint = try XCTUnwrap(catalog.blueprints.first { $0.family == family })
            XCTAssertFalse(TraitMatch.admits(offered: fox.traits,
                                             required: blueprint.requires.companion,
                                             forbidden: blueprint.forbids.companion),
                           "\(family.rawValue): a companion who already knows hands over the answer.")
        }
    }

    func testAnImpossibleCombinationStillFailsWithReasons() throws {
        let catalog = try library()
        // A sea has no threshold and the dolphin carries: nothing in the
        // library should be willing to make a Threshold story out of this.
        let threshold = try XCTUnwrap(catalog.blueprints.first { $0.family == .threshold })
        XCTAssertThrowsError(
            try OfflineStoryComposer().compose(
                blueprint: threshold, catalog: catalog,
                intent: intent(Self.matrix[3], seed: "x"))
        ) { error in
            guard case OfflineSelectionError.requestedContentRejected(_, let reason) = error else {
                return XCTFail("Wrong error: \(error)")
            }
            XCTAssertFalse(reason.isEmpty)
        }
    }

    // MARK: - Prose must not assume what the content is

    /// A companion may be a fox, an owl or a dolphin. The first draft of
    /// `meet_companion` had all three arrive by hopping through leaves.
    func testMeetCompanionAssumesNoParticularWayOfMoving() throws {
        let banned = ["zıplayarak", "yaprakların arasından", "bir taşın üzerinde", "koşarak", "yürüyerek"]
        let templates = try library().templates.filter { $0.realizesBeat == .meetCompanion }
        XCTAssertFalse(templates.isEmpty)
        for template in templates {
            for variant in template.variants {
                for phrase in banned {
                    XCTAssertFalse(variant.text.contains(phrase),
                                   "\(variant.id.rawValue) assumes locomotion: \(variant.text)")
                }
            }
        }
    }

    /// A discovery may be a sound. No page may see it, and the companion may
    /// not announce itself as a sound either — in the sound story that reads as
    /// the discovery arriving twice.
    func testNoPageAssumesTheDiscoveryIsVisible() throws {
        let catalog = try library()
        let sighted = ["gördü", "görebildi", "görünüyordu", "parlıyordu"]
        let row = Self.matrix[2]   // garden + hedgehog + sound
        for seed in ["a", "b", "c", "d", "e", "f", "g", "h"] {
            let story = try OfflineStoryComposer().compose(catalog: catalog, intent: intent(row, seed: seed))
            for page in story.pages {
                for verb in sighted where page.text.contains("ses") {
                    XCTAssertFalse(page.text.contains(verb),
                                   "p\(page.pageNumber) sees a sound: \(page.text)")
                }
            }
        }
    }

    /// A title is a different register from a sentence. "titrek bir ışık" reads
    /// correctly mid-sentence and wrongly on a cover.
    func testTitlesUseTheTitleRegisterNotTheProseOne() throws {
        let catalog = try library()
        for row in Self.matrix {
            for seed in ["a", "b", "c", "d", "e", "f"] {
                let story = try OfflineStoryComposer().compose(catalog: catalog, intent: intent(row, seed: seed))
                XCTAssertFalse(story.title.contains(" bir "),
                               "Indefinite article in a title: \(story.title)")
                XCTAssertEqual(story.title, story.title.trimmingCharacters(in: .whitespaces))
            }
        }
    }

    // MARK: - Determinism across stories

    /// Variant choice is keyed on the whole story. Keyed on the seed alone, a
    /// fox story and a dolphin story built from one seed picked the same
    /// sentence for every beat they shared.
    func testDifferentContentUnderOneSeedProducesDifferentProse() throws {
        let catalog = try library()
        let proses = try Self.matrix.map { row in
            try OfflineStoryComposer().compose(catalog: catalog, intent: intent(row, seed: "shared"))
                .pages.map(\.text).joined()
        }
        XCTAssertEqual(Set(proses).count, proses.count,
                       "Two matrix rows produced identical prose under one seed.")
    }

    func testRegeneratingTheSameIntentIsStillReproducible() throws {
        let catalog = try library()
        for row in Self.matrix {
            let first = try OfflineStoryComposer().compose(catalog: catalog, intent: intent(row, seed: "r"))
            let second = try OfflineStoryComposer().compose(catalog: catalog, intent: intent(row, seed: "r"))
            XCTAssertEqual(first.fingerprint, second.fingerprint, row.name)
            XCTAssertEqual(first.pages.map(\.text), second.pages.map(\.text), row.name)
            XCTAssertEqual(first.title, second.title, row.name)
        }
    }
}
