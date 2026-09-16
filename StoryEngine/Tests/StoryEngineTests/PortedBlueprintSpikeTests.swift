import XCTest
@testable import StoryEngine

/// One of the fourteen, run end to end in this engine.
///
/// The fourteen were gate-verified in the authoring session's own model and have
/// never rendered a page here. "Superseded" in a merge plan is a statement of
/// intent, not evidence, so this is the evidence: II-2 expressed in the engine's
/// schema, validated by the engine's validator, composed by the engine's
/// composer, against the shipped catalog.
///
/// Deliberately a **fixture, not a catalog entry.** Whether the fourteen retire
/// the five working blueprints is not a question this file should answer by
/// quietly adding one; it is here to produce the evidence that question needs.
///
/// II-2 is the right one to run first. It was the weakest blueprint in the
/// catalog until it was rebuilt on the social threshold, it is the only one that
/// needs the `social` axis, and that axis had no content behind it until an hour
/// ago — so it exercises the newest and least-settled part of the merge.
enum PortedBlueprintSpikeTestsJSON {
    static let json = PortedBlueprintSpikeTests.blueprintJSON
}

final class PortedBlueprintSpikeTests: XCTestCase {

    /// `bp_threshold_joining_002` — *the barrier is being seen, and the way
    /// through is asking.*
    static let blueprintJSON = """
    {
      "id": "bp_threshold_joining_002",
      "genre": "gentle_adventure",
      "theme": "courage",
      "ageRange": "5-6",
      "pageCount": 8,
      "family": "threshold",
      "premise": "The child wants to join something already underway, and the barrier is other people.",
      "editorialName": "askingToJoin",
      "titlePatterns": [
        "{{child.name}} ve {{setting.name}}'daki Oyun",
        "{{child.name}}'in Cesur Sorusu"
      ],
      "requires": {
        "setting": { "anyOf": [["isOpen", "isTended"]] },
        "thresholdKind": ["social"],
        "casting": ["hesitant", "reassuring"],
        "discovery": { "anyOf": [["isBeautiful", "emitsSignal", "impliesPresence"]] }
      },
      "forbids": { "setting": ["isHazardous"] },
      "pages": [
        { "pageNumber": 1, "role": "hook", "beat": "notice_anomaly", "emotion": "curiosity" },
        { "pageNumber": 2, "role": "discovery", "beat": "examine", "emotion": "unease" },
        { "pageNumber": 3, "role": "companion", "beat": "meet_companion",
          "supportingBeat": "companion_offers", "emotion": "hesitation" },
        { "pageNumber": 4, "role": "problem", "beat": "hesitate", "emotion": "determination" },
        { "pageNumber": 5, "role": "attempt", "beat": "prepare", "emotion": "doubt" },
        { "pageNumber": 6, "role": "challenge", "beat": "ask_for_help", "emotion": "effort" },
        { "pageNumber": 7, "role": "resolution", "beat": "succeed", "emotion": "relief" },
        { "pageNumber": 8, "role": "emotional_ending", "beat": "warm_close",
          "supportingBeat": "carry_forward", "emotion": "pride" }
      ]
    }
    """

    private func blueprint() throws -> CatalogBlueprint {
        try JSONDecoder().decode(CatalogBlueprint.self, from: Data(Self.blueprintJSON.utf8))
    }

    /// The first real meeting of the two validators. Their gates said this
    /// sequence is sound; this asks the engine's, which derives state from the
    /// beats rather than reading authored preconditions.
    func testTheEnginesValidatorAcceptsTheSequence() throws {
        let blueprint = try blueprint()
        let result = BeatSequenceValidator().validate(
            blueprint.beatSlots, conflictMechanism: blueprint.family?.conflict)
        let fatal = result.issues.filter { $0.severity == .fatal }
        XCTAssertTrue(fatal.isEmpty,
                      "Disagreement between the two validators — a finding, not a porting error:\n"
                      + fatal.map(\.message).joined(separator: "\n"))
    }

    /// The chain the sequence depends on, asserted directly so a future change
    /// to any link fails here with its reason rather than as a mystery.
    ///
    /// `ask_for_help` needs a companion, a named obstacle and an attempt. II-2
    /// has no `obstacle_raises` and no `first_attempt`, which looks like a gap
    /// and is not: `hesitate` produces `obstacleNamed` — in this family the
    /// obstacle *is* the hesitation — and `prepare` produces `attemptMade`.
    func testTheStateChainThatMakesAskingPossible() throws {
        XCTAssertTrue(StoryBeat.hesitate.produces.contains(.obstacleNamed))
        XCTAssertTrue(StoryBeat.prepare.produces.contains(.attemptMade))
        XCTAssertTrue(StoryBeat.askForHelp.produces.contains(.solutionKnown))
        XCTAssertTrue(StoryBeat.succeed.requires.isSatisfied(
            by: DerivedNarrativeState().producing([.solutionKnown])))
    }

    func testItBindsToTheOnlyPlaceThatAffordsBeingJoined() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let content = try OfflineContentBinder().bind(
            blueprint: try blueprint(), catalog: catalog,
            intent: OfflineStoryIntent(childName: "Yeliz", seed: "ii2"))
        XCTAssertEqual(content.setting.id, ContentID("setting_festival_meadow_001"))
        XCTAssertTrue(content.setting.thresholdKinds.contains(.social))
        let role = try XCTUnwrap(content.castRole)
        XCTAssertTrue([.hesitant, .reassuring].contains(role))
    }

    /// The whole point: eight pages of Turkish, with no missing slot and no
    /// suffix the renderer could not spell.
    func testItRendersEightCleanPages() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let blueprint = try blueprint()

        for seed in ["a", "b", "c", "d", "e", "f", "g", "h"] {
            let story = try OfflineStoryComposer().compose(
                blueprint: blueprint, catalog: catalog,
                intent: OfflineStoryIntent(childName: "Yeliz", seed: seed))

            XCTAssertEqual(story.pages.count, 8, "seed \(seed)")
            XCTAssertTrue(story.isClean,
                          "seed \(seed): missing "
                          + "\(story.pages.flatMap(\.missingSlots)) / unrecognised "
                          + "\(story.pages.flatMap(\.unrecognisedSuffixes))")
            XCTAssertFalse(story.title.isEmpty)
            for page in story.pages {
                XCTAssertFalse(page.text.contains("{{"), "seed \(seed) p\(page.pageNumber)")
                XCTAssertGreaterThan(page.text.count, 20, "seed \(seed) p\(page.pageNumber)")
            }
        }
    }

    /// Supply, under the gate the rest of the corpus is held to. A blueprint
    /// that renders once but hands every child the same book is not ported.
    func testEveryPageHasRealChoiceForEveryLegalBinding() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let blueprint = try blueprint()
        let binder = OfflineContentBinder()
        var thin: [String] = []
        var checked = 0

        for setting in catalog.settings where !setting.traits.isEmpty {
            for companion in catalog.companions where !companion.traits.isEmpty {
                for discovery in catalog.objects where !discovery.traits.isEmpty {
                    let intent = OfflineStoryIntent(
                        childName: "Yeliz", settingID: setting.id,
                        companionID: companion.id, discoveryID: discovery.id, seed: "sweep")
                    guard let bound = try? binder.bind(
                        blueprint: blueprint, catalog: catalog, intent: intent) else { continue }

                    for role in TraitMatch.castableRoles(
                        offered: companion.castRoles, casting: blueprint.requires.casting) {
                        let content = BoundContent(
                            setting: bound.setting, companion: bound.companion,
                            discovery: bound.discovery, castRole: role)
                        for step in try OfflineStoryComposer.plan(blueprint) {
                            let templates = OfflineStoryComposer.templates(
                                for: step.beat, in: catalog, blueprint: blueprint)
                            guard !templates.isEmpty else { continue }
                            var available = 0
                            for template in templates {
                                available += try OfflineStoryComposer.pool(
                                    from: template.variants, realizing: step.beat,
                                    wanting: step.wanted, after: step.previous,
                                    closing: step.closing, state: step.state,
                                    onPage: step.pageNumber, content: content,
                                    register: blueprint.family?.beliefRegister,
                                    conflict: blueprint.family?.conflict).count
                            }
                            checked += 1
                            if available < 4 {
                                thin.append("p\(step.pageNumber) \(step.beat.rawValue) "
                                            + "[\(companion.id.rawValue) as \(role.rawValue)/"
                                            + "\(discovery.id.rawValue)]: \(available)")
                            }
                        }
                    }
                }
            }
        }

        XCTAssertGreaterThan(checked, 0, "No legal binding — the sweep proves nothing.")
        XCTAssertTrue(thin.isEmpty, "Thin cells:\n" + Set(thin).sorted().joined(separator: "\n"))
    }
}
