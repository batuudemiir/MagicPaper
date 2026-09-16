import XCTest
@testable import StoryEngine

/// Phase 3, Pilot A — Family II (The Threshold).
///
/// The first blueprint authored against the beat architecture. Until it
/// existed, every claim the architecture makes about authorability was
/// unexercised: the reference arcs in `BeatVocabularyTests` are transcriptions
/// of the design document, checked against rules the same document defines. A
/// pilot is the first content written *by* the schema rather than *as* the
/// schema, and the first chance for the two to disagree.
final class PilotBlueprintTests: XCTestCase {

    // MARK: - Loading

    /// `.process("Resources")` flattens subdirectories, so the authored path
    /// `Resources/blueprints/…` ships at the bundle root. Verified from the
    /// built `.app` in I1; asserted here so a change to that behaviour surfaces
    /// as a named failure rather than a missing blueprint.
    private func loadPilots() throws -> [CatalogBlueprint] {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "pilot_library_v1", withExtension: "json"),
            "Pilot blueprint resource is not in the package bundle."
        )
        struct File: Decodable { let blueprints: [CatalogBlueprint] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(File.self, from: data).blueprints
    }

    /// Pilot A specifically. The library now holds five blueprints, one per
    /// family the Phase 4 matrix needs; these tests are about the Threshold.
    private func pilot() throws -> CatalogBlueprint {
        let all = try loadPilots()
        return try XCTUnwrap(
            all.first { $0.id.rawValue == "blueprint_threshold_crossing_001" },
            "Pilot A is missing from the library."
        )
    }

    func testPilotDecodes() throws {
        let blueprint = try pilot()
        XCTAssertEqual(blueprint.id.rawValue, "blueprint_threshold_crossing_001")
        XCTAssertEqual(blueprint.family, .threshold)
        XCTAssertEqual(blueprint.pageCount, 8)
        XCTAssertEqual(blueprint.pagePlan.count, 8)
        XCTAssertEqual(blueprint.ageRange.description, "5-6")
    }

    // MARK: - Structure

    func testEveryPageDeclaresABeatAndAnEmotion() throws {
        let blueprint = try pilot()
        XCTAssertTrue(blueprint.isBeatAuthored, "A pilot that is not beat-authored is not selectable.")
        for slot in blueprint.pagePlan {
            XCTAssertNotNil(slot.emotion, "Page \(slot.pageNumber) declares no emotion.")
        }
        XCTAssertEqual(blueprint.pagePlan.map(\.pageNumber).sorted(), Array(1...8))
    }

    func testPageRolesFollowTheMvpArc() throws {
        let blueprint = try pilot()
        XCTAssertEqual(blueprint.roleSequence, PageRole.mvpArc)
    }

    /// The whole point of the beat model: this is the only rule that decides
    /// whether authored content is coherent, and it must pass unaided.
    func testPilotPassesTheBeatSequenceValidator() throws {
        let blueprint = try pilot()
        let result = BeatSequenceValidator().validate(
            blueprint.beatSlots,
            conflictMechanism: blueprint.family?.conflict
        )
        XCTAssertTrue(
            result.isValid,
            "Pilot violates: " + result.issues.map { "p\($0.pageNumber) \($0.code): \($0.message)" }
                .joined(separator: " | ")
        )
        XCTAssertTrue(result.finalState.isResolved)
    }

    func testResolutionLandsOnPageSeven() throws {
        let blueprint = try pilot()
        let result = BeatSequenceValidator().validate(
            blueprint.beatSlots,
            conflictMechanism: blueprint.family?.conflict
        )
        let resolvedPage = result.statesByPage.filter { $0.value.isResolved }.keys.min()
        XCTAssertEqual(resolvedPage, 7)
        XCTAssertFalse(result.statesByPage[6]?.isResolved ?? true, "Page 6 must not have resolved yet.")
    }

    // MARK: - Family identity

    func testPilotCarriesFamilyTwosMechanismTriple() throws {
        let family = try XCTUnwrap(pilot().family)
        XCTAssertEqual(family.curiosity, .barrierWithSomethingBeyond)
        XCTAssertEqual(family.conflict, .interior)
        XCTAssertEqual(family.resolution, .incrementalCourage)
    }

    /// Family II's conflict is the child's own reluctance. If the interior
    /// beats were dropped the arc would still validate — `hesitate` and
    /// `find_own_courage` are not structurally mandatory — and the story would
    /// quietly become a different family. Phase 1 found exactly this failure in
    /// the shipped corpus, where the fear belongs to the companion.
    func testTheConflictBelongsToTheChild() throws {
        let beats = Set(try pilot().beatSlots.flatMap(\.beats))
        XCTAssertTrue(beats.contains(.hesitate), "Nothing names the child's reluctance.")
        XCTAssertTrue(beats.contains(.findOwnCourage), "The courage is not the child's own.")
        XCTAssertFalse(beats.contains(.cooperativeEffort), "Cooperation is Family III's resolution.")
        XCTAssertFalse(beats.contains(.askForHelp), "Asking transfers the interior work away from the child.")
    }

    /// A pilot has to be a *blueprint*, not a copy of the document's worked
    /// example. If it were identical, it would prove only that the fixture
    /// round-trips.
    func testPilotIsNotTheReferenceArc() throws {
        let referenceFamilyTwo: [StoryBeat] = [
            .noticeAnomaly, .approach, .meetCompanion, .hesitate,
            .smallStep, .findOwnCourage, .succeed, .selfRecognize, .warmClose
        ]
        let pilotBeats = try pilot().beatSlots.flatMap(\.beats)
        XCTAssertNotEqual(pilotBeats, referenceFamilyTwo)
        // It differs by the two beats that make it a distinct variant: the
        // companion offers, and the child commits before the hesitation is
        // overcome rather than after.
        XCTAssertTrue(pilotBeats.contains(.companionOffers))
        XCTAssertTrue(pilotBeats.contains(.commit))
    }

    // MARK: - Emotional arc

    func testArcStaysWithinTheAgeFiveCeilingAndLandsSettled() throws {
        let emotions = try pilot().pagePlan
            .sorted { $0.pageNumber < $1.pageNumber }
            .compactMap(\.emotion)
        XCTAssertEqual(emotions.count, 8)
        for emotion in emotions {
            XCTAssertLessThanOrEqual(emotion.intensity, 2, "'\(emotion.rawValue)' exceeds the ceiling.")
        }
        XCTAssertTrue(try XCTUnwrap(emotions.last).isPermittedLanding)
    }

    func testTensionNeverRunsForThreeConsecutivePages() throws {
        let emotions = try pilot().pagePlan
            .sorted { $0.pageNumber < $1.pageNumber }
            .compactMap(\.emotion)
        var run = 0
        for emotion in emotions {
            run = emotion.intensity >= 2 ? run + 1 : 0
            XCTAssertLessThanOrEqual(run, 2, "Three consecutive tense pages in a bedtime story.")
        }
    }

    // MARK: - Compatibility (§8)

    func testPilotDeclaresWhatItNeedsAndWhatItCannotHave() throws {
        let blueprint = try pilot()
        XCTAssertEqual(blueprint.requires.setting, [.hasThreshold])
        XCTAssertEqual(blueprint.requires.discovery, [.isUnexplained, .emitsSignal])
        // The companion is *cast*, not required. A crossing story needs someone
        // emotionally legible about the crossing, and the companion who is
        // frightened too and goes anyway is that as much as the steady one is —
        // arguably more. Requiring `canReassure`, as this blueprint used to,
        // excluded the better half of its own cast for no defensible reason.
        XCTAssertEqual(blueprint.requires.casting, [.hesitant, .reassuring])
        XCTAssertTrue(
            blueprint.requires.companion.isEmpty,
            "Capability is what a blueprint forbids; the part it casts belongs in `casting`.")
        XCTAssertEqual(blueprint.forbids.companion, [.canFly, .canCarry])
        XCTAssertTrue(blueprint.contradictoryTraits.isEmpty)
    }

    /// The exclusion has to do real work, or it is decoration. A companion that
    /// can carry the child across the threshold dissolves the premise without
    /// breaking anything — the story still generates, it is just no longer this
    /// story.
    func testACarryingCompanionIsRejected() throws {
        let blueprint = try pilot()
        let owl: Set<CompanionTrait> = [.canFly, .isPatient, .hasLocalKnowledge]
        XCTAssertFalse(TraitMatch.admits(
            offered: owl,
            required: blueprint.requires.companion,
            forbidden: blueprint.forbids.companion
        ))
        XCTAssertEqual(
            TraitMatch.rejection(offered: owl,
                                 required: blueprint.requires.companion,
                                 forbidden: blueprint.forbids.companion),
            "offers forbidden canFly"
        )
    }

    func testAGroundedCompanionWhoCanPlayThePartIsAccepted() throws {
        let blueprint = try pilot()
        let fox: Set<CompanionTrait> = [.hasLocalKnowledge, .isPlayful, .isQuick]
        XCTAssertTrue(TraitMatch.admits(
            offered: fox,
            required: blueprint.requires.companion,
            forbidden: blueprint.forbids.companion
        ))
        XCTAssertNil(TraitMatch.castingRejection(
            offered: [.guide, .reassuring], casting: blueprint.requires.casting))
    }

    /// The half of F2 that a single vocabulary could not express: the same
    /// record, small in every story, is admitted here and cast as the one who
    /// needs care elsewhere. Under the old vocabulary a blueprint that forbade
    /// `isSmallAndVulnerable` rejected it for a fact that was true of the animal
    /// and irrelevant to the part.
    func testASmallCompanionIsCastableWithoutBeingTheOneWhoNeedsCare() throws {
        let blueprint = try pilot()
        let hedgehog: Set<CompanionRole> = [.hesitant, .reassuring, .needsCare]
        XCTAssertNil(TraitMatch.castingRejection(
            offered: hedgehog, casting: blueprint.requires.casting))
        XCTAssertEqual(
            TraitMatch.castableRoles(offered: hedgehog, casting: blueprint.requires.casting),
            [.hesitant, .reassuring],
            "Casting narrows to the parts this blueprint offers; `needsCare` is not one of them.")
    }

    /// A companion that can only be the one in trouble cannot carry a crossing.
    func testACompanionWithNoOfferedPartIsRejectedWithAReason() throws {
        let blueprint = try pilot()
        XCTAssertEqual(
            TraitMatch.castingRejection(offered: [.needsCare], casting: blueprint.requires.casting),
            "cannot be cast as hesitant or reassuring")
    }

    /// §16 asks each pilot to be instantiable against the Phase 4 matrix. It is
    /// admitted by two of the five rows, and the three rejections are each for
    /// a stated reason — which is the behaviour §8.4 requires in place of a
    /// silent unfiltered fallback.
    func testPilotAgainstThePhaseFourMatrix() throws {
        let blueprint = try pilot()
        struct Row {
            let name: String
            let setting: Set<SettingTrait>
            let companion: Set<CompanionTrait>
            let roles: Set<CompanionRole>
            let discovery: Set<DiscoveryTrait>
        }
        let matrix: [Row] = [
            .init(name: "forest+fox+light",
                  setting: [.hasThreshold, .canConceal, .isEnclosed],
                  companion: [.hasLocalKnowledge, .isPlayful, .isQuick],
                  roles: [.guide, .reassuring],
                  discovery: [.isUnexplained, .emitsSignal]),
            .init(name: "mountain+owl+footprints",
                  setting: [.hasThreshold, .hasHeight, .isHazardous],
                  companion: [.canFly, .isPatient, .hasLocalKnowledge],
                  roles: [.guide, .reassuring],
                  discovery: [.impliesPresence, .isFragmentary]),
            .init(name: "garden+hedgehog+sound",
                  setting: [.hasThreshold, .isTended, .canConceal],
                  companion: [.isSmall, .isPatient],
                  roles: [.hesitant, .reassuring, .needsCare],
                  discovery: [.isUnexplained, .emitsSignal, .impliesNeed]),
            .init(name: "sea+dolphin+shell",
                  setting: [.hasWater, .isOpen],
                  companion: [.canCarry, .canSwim, .isPlayful],
                  roles: [.guide, .reassuring],
                  discovery: [.isBeautiful, .impliesPresence]),
            .init(name: "forest+rabbit+map",
                  setting: [.hasThreshold, .canConceal, .isEnclosed],
                  companion: [.isSmall, .isLiteralMinded, .isQuick],
                  roles: [.hesitant, .needsCare],
                  discovery: [.isFragmentary, .impliesPresence])
        ]

        var admitted: [String] = []
        var rejected: [String: [String]] = [:]
        for row in matrix {
            let reasons = [
                TraitMatch.rejection(offered: row.setting,
                                     required: blueprint.requires.setting,
                                     forbidden: blueprint.forbids.setting).map { "setting \($0)" },
                TraitMatch.rejection(offered: row.companion,
                                     required: blueprint.requires.companion,
                                     forbidden: blueprint.forbids.companion).map { "companion \($0)" },
                TraitMatch.castingRejection(offered: row.roles,
                                            casting: blueprint.requires.casting).map { "casting \($0)" },
                TraitMatch.rejection(offered: row.discovery,
                                     required: blueprint.requires.discovery,
                                     forbidden: blueprint.forbids.discovery).map { "discovery \($0)" }
            ].compactMap { $0 }
            if reasons.isEmpty { admitted.append(row.name) } else { rejected[row.name] = reasons }
        }

        XCTAssertEqual(admitted, ["forest+fox+light", "garden+hedgehog+sound"])
        // Three now, not two. The third is the setting: a mountain is somewhere
        // a child can actually be hurt, and this blueprint's premise is that the
        // barrier is *not* the obstacle — the fear is. Set the same story
        // somewhere genuinely dangerous and the reluctance becomes correct, the
        // companion's encouragement becomes bad advice, and nothing about the
        // generated text would look wrong.
        XCTAssertEqual(rejected["mountain+owl+footprints"]?.count, 3)   // hazardous place, flying companion, a discovery that does not signal
        XCTAssertEqual(rejected["sea+dolphin+shell"]?.count, 3)         // no threshold, a carrying companion, a silent discovery
        // One reason, not two. The rabbit used to be rejected both for the map
        // and for "nothing reassures" — and that second rejection was the rule
        // being wrong, not the content: a rabbit that is frightened and crosses
        // anyway is exactly what a threshold story wants. Only the map's silence
        // survives the split, and it survives for a reason about the map.
        XCTAssertEqual(rejected["forest+rabbit+map"], ["discovery lacks emitsSignal, isUnexplained"])
        XCTAssertFalse(admitted.isEmpty, "§8.4: a blueprint no content can satisfy is a build failure.")
    }

    // MARK: - Titles (§9)

    /// The titles are the reason the resolver had to be finished first.
    /// `T2_achievement` is built on locative + `-ki`, which until now was
    /// unrecognised — authoring these against the old resolver would have baked
    /// "Orman'nde" into the corpus.
    func testEveryTitlePatternRendersCleanlyForBothKindsOfSettingName() throws {
        let blueprint = try pilot()
        XCTAssertFalse(blueprint.titlePatterns.isEmpty, "A pilot with no titles cannot be published.")

        let settings: [(String, TurkishTextRenderer.Slot)] = [
            ("plain proper noun",
             .init("Fısıldayan Orman", isProperNoun: true)),
            ("possessive proper noun",
             .init("Gece Bahçesi", isProperNoun: true, hasPossessiveEnding: true))
        ]

        for (label, setting) in settings {
            for pattern in blueprint.titlePatterns {
                let result = TurkishTextRenderer.render(pattern, slots: [
                    "child.name": .init("Yeliz", isProperNoun: true),
                    "setting.name": setting
                ])
                XCTAssertTrue(
                    result.isClean,
                    "\(label) / '\(pattern)' → missing \(result.missingSlots), "
                    + "unrecognised \(result.unrecognisedSuffixes)"
                )
                XCTAssertFalse(result.text.contains("{{"), "Unsubstituted token in '\(result.text)'")
            }
        }
    }

    func testTitlesReadCorrectlyForAPlainProperNoun() throws {
        let blueprint = try pilot()
        let slots: [String: TurkishTextRenderer.Slot] = [
            "child.name": .init("Yeliz", isProperNoun: true),
            "setting.name": .init("Fısıldayan Orman", isProperNoun: true)
        ]
        let rendered = blueprint.titlePatterns.map { TurkishTextRenderer.render($0, slots: slots).text }
        XCTAssertEqual(rendered, [
            "Yeliz ve Fısıldayan Orman'daki Işık",
            "Yeliz'in Fısıldayan Orman'daki Cesur Adımı",
            "Fısıldayan Orman'a Cesur Yolculuk"
        ])
    }

    func testTitlesReadCorrectlyForAPossessiveProperNoun() throws {
        let blueprint = try pilot()
        let slots: [String: TurkishTextRenderer.Slot] = [
            "child.name": .init("Demir", isProperNoun: true),
            "setting.name": .init("Gece Bahçesi", isProperNoun: true, hasPossessiveEnding: true)
        ]
        let rendered = blueprint.titlePatterns.map { TurkishTextRenderer.render($0, slots: slots).text }
        XCTAssertEqual(rendered, [
            "Demir ve Gece Bahçesi'ndeki Işık",
            "Demir'in Gece Bahçesi'ndeki Cesur Adımı",
            "Gece Bahçesi'ne Cesur Yolculuk"
        ])
    }

    // MARK: - Isolation

    /// D2: V1 content is preserved until migration is verified.
    ///
    /// This originally asserted the pilot was absent from the *loaded* catalog.
    /// D8 changed that deliberately — the loader now merges the pilot library at
    /// load time, which is how anything becomes selectable at all. The
    /// guarantee D2 actually makes is about the **file**: V1's document is not
    /// rewritten, and the merge happens in memory.
    func testV1ContentIsUntouchedAndTheMergeHappensAtLoadTime() throws {
        let v1URL = try XCTUnwrap(
            Bundle.module.url(forResource: "shared_content_library_v2", withExtension: "json"))
        let v1 = try JSONDecoder().decode(ContentCatalog.self, from: Data(contentsOf: v1URL))

        XCTAssertNil(
            v1.blueprints.first { $0.id.rawValue == "blueprint_threshold_crossing_001" },
            "The pilot was written into the V1 document."
        )
        XCTAssertTrue(v1.blueprints.allSatisfy { !$0.isBeatAuthored },
                      "V1 blueprints were edited to carry beats.")
        XCTAssertEqual(v1.blueprints.count, 12)

        // And the loaded catalog does contain it, because merging is the point.
        let loaded = try ContentCatalogLoader().load().catalog
        XCTAssertNotNil(loaded.blueprints.first { $0.id.rawValue == "blueprint_threshold_crossing_001" })
    }
}
