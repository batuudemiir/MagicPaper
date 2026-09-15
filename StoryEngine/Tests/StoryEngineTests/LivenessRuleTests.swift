import XCTest
@testable import StoryEngine

/// D9 — liveness.
///
/// `BLUEPRINT_CATALOG_V2.md` defect #2: *"Pilot A's companion page, and page 5
/// of B and C, produced state nothing read. The engine would generate identical
/// stories with those pages deleted."* That last sentence is the test, taken
/// literally: delete the page, and see whether anything downstream notices.
final class LivenessRuleTests: XCTestCase {

    private func validate(_ slots: [BeatSlot]) -> BeatSequenceResult {
        BeatSequenceValidator().validate(slots)
    }

    private func slot(_ n: Int, _ role: PageRole, _ beat: StoryBeat,
                      _ supporting: StoryBeat? = nil, _ emotion: EmotionalState) -> BeatSlot {
        BeatSlot(pageNumber: n, role: role, beat: beat, supportingBeat: supporting, emotion: emotion)
    }

    /// An arc with a page whose product nothing reads.
    ///
    /// This used to be Family II's reference arc, where the companion arrived on
    /// page 3 and no beat required `companionPresent` again. **That arc can no
    /// longer be written**: the blueprint session tightened `small_step` to
    /// require a companion precisely because of this, and the liveness rule
    /// stopped flagging page 3 the moment they did — two independent routes to
    /// the same conclusion.
    ///
    /// So the fixture moved to the same failure one page earlier: a belief is
    /// formed on page 2 and this arc never reads it back.
    private var beliefNeverUsed: [BeatSlot] {
        [slot(1, .hook, .noticeAnomaly, nil, .curiosity),
         slot(2, .discovery, .formBelief, nil, .wonder),
         slot(3, .companion, .meetCompanion, nil, .warmth),
         slot(4, .problem, .hesitate, nil, .hesitation),
         slot(5, .attempt, .smallStep, nil, .effort),
         slot(6, .challenge, .findOwnCourage, nil, .determination),
         slot(7, .resolution, .succeed, nil, .relief),
         slot(8, .emotionalEnding, .selfRecognize, .warmClose, .pride)]
    }

    func testAPageWhoseProductIsNeverReadIsFlagged() {
        let result = validate(beliefNeverUsed)
        let inert = result.issues.filter { $0.code == "inert_page" }
        XCTAssertEqual(inert.map(\.pageNumber), [2])
        XCTAssertTrue(inert[0].message.contains("beliefFormed"))
    }

    /// The fix the blueprint session made, checked from this side: with
    /// `small_step` requiring a companion, a Family II companion page is
    /// load-bearing and the rule says so by staying quiet about it.
    func testTighteningAPreconditionIsWhatMakesAPageLoadBearing() {
        XCTAssertTrue(
            StoryBeat.smallStep.requires.keys.contains(.companionPresent),
            "The tightened precondition was lost.")
        let result = validate(beliefNeverUsed)
        XCTAssertFalse(result.issues.contains { $0.code == "inert_page" && $0.pageNumber == 3 })
    }

    /// The point of grading: a weak page is not an incoherent one. Making this
    /// fatal would make every blueprint in the library unselectable overnight,
    /// for a defect whose real fix is in the beat vocabulary.
    func testALivenessWarningDoesNotInvalidateTheBlueprint() {
        let result = validate(beliefNeverUsed)
        XCTAssertTrue(result.isValid, "An inert page must not block shipping.")
        XCTAssertTrue(result.fatalIssues.isEmpty)
        XCTAssertEqual(result.warnings.map(\.code), ["inert_page"])
    }

    /// Consuming the state **on the same page** does not rescue it: deleting the
    /// page deletes the consumer too, so nothing downstream ever misses it.
    ///
    /// This corrects my own first expectation. The rule is stricter than
    /// "somebody reads it" and is right to be: the question is whether the
    /// *page* earns its place, not whether the state is technically consumed.
    func testSamePageConsumptionDoesNotRescueThePage() {
        var slots = beliefNeverUsed
        slots[1] = slot(2, .discovery, .formBelief, .beliefFails, .wonder)
        let result = validate(slots)
        XCTAssertTrue(result.issues.contains { $0.code == "inert_page" && $0.pageNumber == 2 },
                      "Deleting page 2 removes the consumer too, so the story is unchanged.")
    }

    /// A *later* page consuming it is what makes page 2 load-bearing.
    func testALaterConsumerMakesThePageLive() {
        var slots = beliefNeverUsed
        slots[3] = slot(4, .problem, .hesitate, .beliefFails, .hesitation)
        let result = validate(slots)
        XCTAssertFalse(result.issues.contains { $0.code == "inert_page" && $0.pageNumber == 2 },
                       "belief_fails requires beliefFormed, which only page 2 produces.")
    }

    // MARK: - The two exemptions

    /// An ending is not load-bearing by design; `non_closing_final_page` and
    /// `unsettled_landing` govern it instead. Without this exemption every
    /// blueprint ever written fails.
    func testTheFinalPageIsNeverFlagged() {
        let result = validate(beliefNeverUsed)
        XCTAssertFalse(result.issues.contains { $0.code == "inert_page" && $0.pageNumber == 8 })
    }

    /// The rule is about state that goes unread. A page producing no state is
    /// not making an unread claim — whether an orientation beat earns its page
    /// is a different question, and the beat vocabulary would have to answer it.
    func testAPageThatProducesNothingIsNotJudged() {
        var slots = beliefNeverUsed
        slots[1] = slot(2, .discovery, .approach, nil, .wonder)
        XCTAssertEqual(StoryBeat.approach.produces, [])
        XCTAssertFalse(validate(slots).issues.contains {
            $0.code == "inert_page" && $0.pageNumber == 2
        })
    }

    // MARK: - It must not fire on genuinely load-bearing pages

    func testAFullyLiveArcIsSilent() {
        // Family IV: every producing page is read downstream — receive_appeal's
        // needKnown by restore, commit's committed by first_attempt,
        // first_attempt's attemptMade by persist.
        let slots = [
            slot(1, .hook, .noticeAnomaly, nil, .curiosity),
            slot(2, .discovery, .examine, nil, .puzzlement),
            slot(3, .companion, .meetCompanion, .receiveAppeal, .sympathy),
            slot(4, .problem, .commit, .obstacleRaises, .duty),
            slot(5, .attempt, .firstAttempt, nil, .effort),
            slot(6, .challenge, .persist, nil, .patience),
            slot(7, .resolution, .restore, nil, .relief),
            slot(8, .emotionalEnding, .warmClose, .carryForward, .warmth)
        ]
        let result = validate(slots)
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.issues.filter { $0.code == "inert_page" }.isEmpty,
                      "Flagged: \(result.issues.filter { $0.code == "inert_page" }.map(\.message))")
    }

    /// A page whose removal breaks a later precondition is load-bearing by
    /// definition and must never be flagged, whatever it produces.
    func testAPageWhoseRemovalBreaksTheStoryIsNeverFlagged() {
        let result = validate(beliefNeverUsed)
        // Page 4 is `hesitate`; without it `small_step` and `find_own_courage`
        // both lose `hesitationNamed`.
        XCTAssertFalse(result.issues.contains { $0.code == "inert_page" && $0.pageNumber == 4 })
        // Page 3 is `meet_companion`; `small_step` now needs it.
        XCTAssertFalse(result.issues.contains { $0.code == "inert_page" && $0.pageNumber == 3 })
    }

    func testAnArcThatNeverResolvesIsNotAlsoReportedAsInert() {
        let slots = [
            slot(1, .hook, .noticeAnomaly, nil, .curiosity),
            slot(2, .discovery, .examine, nil, .wonder),
            slot(3, .companion, .meetCompanion, nil, .warmth)
        ]
        let result = validate(slots)
        XCTAssertFalse(result.isValid, "This arc never resolves.")
        XCTAssertTrue(result.issues.filter { $0.code == "inert_page" }.isEmpty,
                      "A broken arc should report the break, not a liveness opinion about it.")
    }

    // MARK: - What it finds in the shipped library

    /// Recorded rather than asserted clean, because it is not clean. Four of the
    /// five blueprints carry an inert page, and this is the same finding the
    /// corpus session reported against its own pilots — which is the point: the
    /// rule reproduces an independent review's result.
    func testTheShippedLibraryIsMeasuredNotAssumed() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "pilot_library_v1", withExtension: "json"))
        let catalog = try JSONDecoder().decode(ContentCatalog.self, from: Data(contentsOf: url))

        var flagged: [String: [Int]] = [:]
        for blueprint in catalog.blueprints {
            let result = BeatSequenceValidator().validate(
                blueprint.beatSlots, conflictMechanism: blueprint.family?.conflict)
            XCTAssertTrue(result.isValid, "\(blueprint.id.rawValue) is structurally broken.")
            let pages = result.issues.filter { $0.code == "inert_page" }.map(\.pageNumber)
            if !pages.isEmpty { flagged[blueprint.family?.rawValue ?? "?"] = pages.sorted() }
        }

        // Measured after adopting the blueprint session's tightened
        // preconditions. Three of the five became clean without a word of
        // content changing — `small_step` needing a companion, and
        // `cooperative_effort` and `insight` needing an attempt, made those
        // pages load-bearing.
        XCTAssertNil(flagged["absence"], "absence: \(flagged["absence"] ?? [])")
        XCTAssertNil(flagged["threshold"], "threshold: \(flagged["threshold"] ?? [])")
        XCTAssertNil(flagged["appeal"], "appeal: \(flagged["appeal"] ?? [])")

        // The two that remain are genuine content findings, not engine bugs.
        // In both, the companion arrives and nothing later depends on it:
        //
        // - Family I: the catalog's §2.1 gives the companion one ordinary fact
        //   on page 3 that page 6 combines with the child's observation. The
        //   beat vocabulary does not encode "supplies a fact", so the
        //   contribution is real in the prose and invisible to the rule.
        // - Family V: this pilot resolves with `reveal_truth`, which needs no
        //   companion. The catalog's own V-2 resolves with `exchange_views`,
        //   which does — the fix exists, in content we have not ported yet.
        XCTAssertEqual(flagged["unexplained"], [3])
        XCTAssertEqual(flagged["misreading"], [3])
    }

    func testAnInertPageStillLoadsTheCatalog() throws {
        let report = try ContentCatalogLoader().load().report
        XCTAssertTrue(report.integrity?.isUsable ?? false)
    }
}
