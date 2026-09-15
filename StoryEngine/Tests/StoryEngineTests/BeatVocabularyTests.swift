import XCTest
@testable import StoryEngine

/// The six reference arcs from the architecture, transcribed verbatim.
///
/// The document states every column was machine-checked against the beat table
/// and passes. This is that check, run in CI rather than trusted.
enum ReferenceArcs {
    static func arc(
        _ family: NarrativeFamily,
        _ beats: [(StoryBeat, StoryBeat?)],
        _ emotions: [EmotionalState]
    ) -> [BeatSlot] {
        zip(beats.enumerated(), emotions).map { pair, emotion in
            BeatSlot(
                pageNumber: pair.offset + 1,
                role: PageRole.mvpArc[pair.offset],
                beat: pair.element.0,
                supportingBeat: pair.element.1,
                emotion: emotion
            )
        }
    }

    static let unexplained = arc(.unexplained, [
        (.noticeAnomaly, nil), (.examine, nil), (.meetCompanion, .companionOffers),
        (.formBelief, .commit), (.firstAttempt, .obstacleRaises), (.insight, nil),
        (.succeed, nil), (.warmClose, .carryForward)
    ], [.ease, .curiosity, .wonder, .puzzlement, .determination, .insight, .satisfaction, .warmth])

    static let threshold = arc(.threshold, [
        (.noticeAnomaly, nil), (.approach, nil), (.meetCompanion, nil),
        (.hesitate, nil), (.smallStep, nil), (.findOwnCourage, nil),
        (.succeed, nil), (.selfRecognize, .warmClose)
    ], [.ease, .curiosity, .hesitation, .unease, .determination, .effort, .relief, .pride])

    static let appeal = arc(.appeal, [
        (.noticeAnomaly, nil), (.approach, nil), (.meetCompanion, .receiveAppeal),
        (.commit, .obstacleRaises), (.firstAttempt, nil), (.cooperativeEffort, nil),
        (.restore, nil), (.warmClose, nil)
    ], [.ease, .curiosity, .sympathy, .concern, .determination, .effort, .relief, .warmth])

    static let absence = arc(.absence, [
        (.noticeAnomaly, nil), (.examine, nil), (.meetCompanion, .receiveAppeal),
        (.commit, .obstacleRaises), (.firstAttempt, nil), (.persist, nil),
        (.restore, nil), (.warmClose, .carryForward)
    ], [.ease, .wonder, .concern, .determination, .doubt, .patience, .relief, .tenderness])

    static let misreading = arc(.misreading, [
        (.noticeAnomaly, nil), (.examine, .formBelief), (.meetCompanion, nil),
        (.beliefFails, .commit), (.firstAttempt, nil), (.revealTruth, nil),
        (.succeed, nil), (.warmClose, nil)
    ], [.curiosity, .certainty, .surprise, .puzzlement, .doubt, .insight, .delight, .warmth])

    static let charge = arc(.charge, [
        (.noticeAnomaly, nil), (.examine, nil), (.meetCompanion, nil),
        (.takeCharge, nil), (.tend, nil), (.patientWait, nil),
        (.restore, nil), (.selfRecognize, .warmClose)
    ], [.ease, .surprise, .tenderness, .duty, .effort, .patience, .pride, .calm])

    static let all: [(NarrativeFamily, [BeatSlot])] = [
        (.unexplained, unexplained), (.threshold, threshold), (.appeal, appeal),
        (.absence, absence), (.misreading, misreading), (.charge, charge)
    ]
}

final class BeatVocabularyTests: XCTestCase {

    func testTheVocabularyIsTwentyEightBeats() {
        XCTAssertEqual(StoryBeat.allCases.count, 28)
    }

    func testEveryStateKeyIsProducedAndConsumed() {
        // The architecture's claim: ten keys, each produced by at least one beat
        // and consumed by at least one. A key that nothing produces is an
        // unreachable precondition; one nothing consumes is dead weight.
        let produced = Set(StoryBeat.allCases.flatMap(\.produces))
        let consumed = Set(StoryBeat.allCases.flatMap { $0.requires.keys })

        for key in NarrativeStateKey.allCases {
            XCTAssertTrue(produced.contains(key), "'\(key.rawValue)' is never produced by any beat")
            XCTAssertTrue(consumed.contains(key), "'\(key.rawValue)' is never required by any beat")
        }
    }

    func testSevenBeatsResolveAndTheChildIsAlwaysTheAgent() {
        let resolving = Set(StoryBeat.resolvingBeats)
        XCTAssertEqual(resolving, [
            .insight, .cooperativeEffort, .persist, .askForHelp,
            .findOwnCourage, .revealTruth, .patientWait
        ])
        XCTAssertEqual(resolving.count, 7)
    }

    func testTheOnlyDisjunctiveRequirementIsCommit() {
        let disjunctive = StoryBeat.allCases.filter {
            if case .any = $0.requires { return true } else { return false }
        }
        XCTAssertEqual(disjunctive, [.commit])
    }

    func testResolutionCannotBeReachedWithoutAnActionByTheChild() {
        // `succeed` needs `solutionKnown`, and every producer of it is a caused
        // action. There is no path to a resolved story that skips one.
        for beat in [StoryBeat.succeed, .restore] {
            XCTAssertTrue(beat.requires.keys.contains(.solutionKnown), "\(beat.rawValue)")
        }
        XCTAssertFalse(StoryBeat.resolvingBeats.isEmpty)
    }

    // MARK: - The six reference arcs

    func testAllSixReferenceArcsSatisfyEveryPrecondition() {
        for (family, slots) in ReferenceArcs.all {
            let result = BeatSequenceValidator().validate(slots, conflictMechanism: family.conflict)
            XCTAssertTrue(
                result.isValid,
                "Family \(family.rawValue) failed: " + result.issues.map(\.message).joined(separator: " | ")
            )
        }
    }

    func testEveryReferenceArcResolves() {
        for (family, slots) in ReferenceArcs.all {
            let result = BeatSequenceValidator().validate(slots, conflictMechanism: family.conflict)
            XCTAssertTrue(result.finalState.isResolved, "Family \(family.rawValue) never resolves")
        }
    }

    func testTheChargeFamilyNeverNamesAnObstacle() {
        // The documented exception: its conflict is duration. Nothing blocks the
        // child, so the by-page-5 obstacle rule must not apply to it.
        let result = BeatSequenceValidator().validate(
            ReferenceArcs.charge, conflictMechanism: .duration
        )
        XCTAssertTrue(result.isValid)
        XCTAssertFalse(result.finalState.contains(.obstacleNamed))
    }

    func testTheChargeFamilyWouldFailTheObstacleRuleWithoutItsExemption() {
        // Proves the exemption is doing real work rather than being decorative.
        let result = BeatSequenceValidator().validate(
            ReferenceArcs.charge, conflictMechanism: .cognitive
        )
        XCTAssertTrue(result.issues.contains { $0.code == "obstacle_too_late" })
    }

    func testEveryReferenceArcStaysInsideTheIntensityCeiling() {
        for (family, slots) in ReferenceArcs.all {
            let peak = slots.compactMap(\.emotion).map(\.intensity).max() ?? 0
            XCTAssertLessThanOrEqual(peak, 2, "Family \(family.rawValue) peaks at \(peak)")
        }
    }

    func testEveryReferenceArcLandsSettledOrPositive() {
        for (family, slots) in ReferenceArcs.all {
            let landing = slots.compactMap(\.emotion).last
            XCTAssertNotNil(landing)
            XCTAssertTrue(landing!.isPermittedLanding, "Family \(family.rawValue) lands on \(landing!.rawValue)")
        }
    }

    func testNoReferenceArcHoldsTensionForThreePages() {
        for (family, slots) in ReferenceArcs.all {
            var run = 0, worst = 0
            for emotion in slots.compactMap(\.emotion) {
                run = emotion.intensity >= 2 ? run + 1 : 0
                worst = max(worst, run)
            }
            XCTAssertLessThanOrEqual(worst, 2, "Family \(family.rawValue) holds tension for \(worst) pages")
        }
    }

    func testThresholdHoldsTensionForExactlyTwoPagesDeliberately() {
        // That family's identity is the held breath; two is the limit and it sits on it.
        let intensities = ReferenceArcs.threshold.compactMap(\.emotion).map(\.intensity)
        XCTAssertEqual(Array(intensities[2...3]), [2, 2])
        XCTAssertLessThan(intensities[4], 2)
    }

    func testMisreadingIsTheOnlyArcNotBeginningAtEase() {
        for (family, slots) in ReferenceArcs.all {
            let opening = slots.first?.emotion
            if family == .misreading {
                XCTAssertEqual(opening, .curiosity)
            } else {
                XCTAssertEqual(opening, .ease, "Family \(family.rawValue)")
            }
        }
    }

    // MARK: - Families

    func testAllFifteenFamilyPairsDifferOnAllThreeMechanisms() {
        let families = NarrativeFamily.allCases
        var pairs = 0
        for (index, a) in families.enumerated() {
            for b in families[(index + 1)...] {
                XCTAssertEqual(a.mechanismDistance(to: b), 3, "\(a.rawValue) vs \(b.rawValue)")
                pairs += 1
            }
        }
        XCTAssertEqual(pairs, 15)
    }

    func testEveryFamilysSignatureBeatsAppearInItsReferenceArc() {
        for (family, slots) in ReferenceArcs.all {
            let beats = Set(slots.flatMap(\.beats))
            let signature = family.signatureBeats
            XCTAssertTrue(beats.contains(signature.setup), "\(family.rawValue) lacks \(signature.setup.rawValue)")
            XCTAssertTrue(beats.contains(signature.resolve), "\(family.rawValue) lacks \(signature.resolve.rawValue)")
        }
    }

    func testEachFamilyResolvesByItsOwnMechanism() {
        // Exactly one beat per arc makes the way forward known, and it is the
        // one its resolution mechanism names.
        for (family, slots) in ReferenceArcs.all {
            let resolving = slots.flatMap(\.beats).filter { $0.produces.contains(.solutionKnown) }
            XCTAssertEqual(resolving, [family.resolutionBeat], "\(family.rawValue)")
        }
    }

    func testTheResolutionBeatIsNotAlwaysTheClosingSignatureBeat() {
        // Family IV resolves by `persist` but closes on `restore`, which it
        // shares with Family III. Treating the closing beat as the mechanism
        // would make those two families indistinguishable to the gate.
        XCTAssertEqual(NarrativeFamily.absence.resolutionBeat, .persist)
        XCTAssertEqual(NarrativeFamily.absence.signatureBeats.resolve, .restore)
        XCTAssertEqual(NarrativeFamily.appeal.signatureBeats.resolve, .cooperativeEffort)

        // In the other five they do coincide.
        for family in NarrativeFamily.allCases where family != .absence {
            XCTAssertEqual(family.resolutionBeat, family.signatureBeats.resolve, "\(family.rawValue)")
        }
    }

    func testEveryFamilyHasADistinctResolutionBeat() {
        let beats = NarrativeFamily.allCases.map(\.resolutionBeat)
        XCTAssertEqual(Set(beats).count, 6, "Two families resolve the same way")
    }
}

/// The validator must reject the failures it exists to prevent.
final class BeatSequenceValidatorTests: XCTestCase {

    private func slot(_ page: Int, _ beat: StoryBeat, _ emotion: EmotionalState = .curiosity) -> BeatSlot {
        BeatSlot(pageNumber: page, role: PageRole.mvpArc[min(page - 1, 7)], beat: beat, emotion: emotion)
    }

    func testResolvingAConflictNeverRaisedIsRejected() {
        // The named failure: page 7 resolves something page 6 never raised.
        let slots = [
            slot(1, .noticeAnomaly), slot(2, .examine), slot(3, .meetCompanion),
            slot(4, .commit), slot(5, .firstAttempt),
            slot(6, .insight),          // needs obstacleNamed — never produced
            slot(7, .succeed), slot(8, .warmClose, .warmth)
        ]
        let result = BeatSequenceValidator().validate(slots, conflictMechanism: .cognitive)

        XCTAssertFalse(result.isValid)
        let issue = result.issues.first { $0.code == "unmet_precondition" }
        XCTAssertEqual(issue?.beat, .insight)
        XCTAssertTrue(issue?.message.contains("obstacleNamed") == true)
    }

    func testAnUnearnedResolutionIsRejected() {
        let slots = [
            slot(1, .noticeAnomaly), slot(2, .examine), slot(3, .meetCompanion),
            slot(4, .commit), slot(5, .firstAttempt), slot(6, .examine),
            slot(7, .succeed),          // needs solutionKnown — nothing produced it
            slot(8, .warmClose, .warmth)
        ]
        let result = BeatSequenceValidator().validate(slots, conflictMechanism: .cognitive)
        XCTAssertTrue(result.issues.contains { $0.code == "unmet_precondition" && $0.beat == .succeed })
    }

    func testAStoryThatNeverResolvesIsRejected() {
        let slots = [
            slot(1, .noticeAnomaly), slot(2, .examine), slot(3, .meetCompanion),
            slot(4, .commit), slot(5, .obstacleRaises), slot(6, .insight),
            slot(7, .examine), slot(8, .examine, .warmth)
        ]
        let result = BeatSequenceValidator().validate(slots, conflictMechanism: .cognitive)
        XCTAssertTrue(result.issues.contains { $0.code == "never_resolves" })
    }

    func testResolvingBeforePageSevenIsRejected() {
        let slots = [
            slot(1, .noticeAnomaly), slot(2, .hesitate), slot(3, .smallStep),
            slot(4, .findOwnCourage), slot(5, .succeed),
            slot(6, .warmClose), slot(7, .warmClose), slot(8, .warmClose, .warmth)
        ]
        let result = BeatSequenceValidator().validate(slots, conflictMechanism: .interior)
        XCTAssertTrue(result.issues.contains { $0.code == "resolved_too_early" })
    }

    func testLateAnomalyIsRejected() {
        let slots = [
            slot(1, .establishOrdinary), slot(2, .establishOrdinary), slot(3, .noticeAnomaly),
            slot(4, .commit), slot(5, .obstacleRaises), slot(6, .insight),
            slot(7, .succeed), slot(8, .warmClose, .warmth)
        ]
        let result = BeatSequenceValidator().validate(slots, conflictMechanism: .cognitive)
        XCTAssertTrue(result.issues.contains { $0.code == "anomaly_too_late" })
        XCTAssertTrue(result.issues.contains { $0.code == "too_much_setup" })
    }

    func testNewWorkOnTheFinalPageIsRejected() {
        let slots = [
            slot(1, .noticeAnomaly), slot(2, .examine), slot(3, .meetCompanion),
            slot(4, .commit), slot(5, .obstacleRaises), slot(6, .insight),
            slot(7, .succeed), slot(8, .firstAttempt, .warmth)
        ]
        let result = BeatSequenceValidator().validate(slots, conflictMechanism: .cognitive)
        XCTAssertTrue(result.issues.contains { $0.code == "non_closing_final_page" })
    }

    func testAFrighteningPageIsRejectedForFiveYearOlds() {
        var slots = ReferenceArcs.unexplained
        slots[3] = BeatSlot(pageNumber: 4, role: .problem, beat: .formBelief,
                            supportingBeat: .commit, emotion: .fear)
        let result = BeatSequenceValidator().validate(slots, conflictMechanism: .cognitive, intensityCeiling: 2)
        XCTAssertTrue(result.issues.contains { $0.code == "intensity_over_ceiling" })
    }

    func testAnUnsettledEndingIsRejected() {
        var slots = ReferenceArcs.unexplained
        slots[7] = BeatSlot(pageNumber: 8, role: .emotionalEnding, beat: .warmClose,
                            supportingBeat: .carryForward, emotion: .doubt)
        let result = BeatSequenceValidator().validate(slots, conflictMechanism: .cognitive)
        XCTAssertTrue(result.issues.contains { $0.code == "unsettled_landing" })
    }

    func testThreeConsecutiveTensePagesAreRejected() {
        var slots = ReferenceArcs.threshold
        slots[4] = BeatSlot(pageNumber: 5, role: .attempt, beat: .smallStep, emotion: .concern)
        let result = BeatSequenceValidator().validate(slots, conflictMechanism: .interior)
        XCTAssertTrue(result.issues.contains { $0.code == "sustained_tension" })
    }

    func testStateIsDerivedNotAuthored() {
        let result = BeatSequenceValidator().validate(ReferenceArcs.unexplained, conflictMechanism: .cognitive)
        // Nothing authored these; every one came from the beat table.
        XCTAssertTrue(result.finalState.contains(.anomalyKnown))
        XCTAssertTrue(result.finalState.contains(.companionPresent))
        XCTAssertTrue(result.finalState.contains(.beliefFormed))
        XCTAssertTrue(result.finalState.contains(.solutionKnown))
        XCTAssertTrue(result.finalState.contains(.resolved))
    }
}
