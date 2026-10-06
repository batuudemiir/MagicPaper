import Foundation

/// What *happens* on a page, as opposed to what the page is *for*.
///
/// This is the central mechanism of the architecture. Page role is the spine and
/// is fixed; the beat is the variable. The same role carries a different beat in
/// every family — page 4 `problem` is `form_belief` in one family, `hesitate` in
/// another, `receive_appeal` in a third. That is what the previous system could
/// not express, and why twelve blueprints collapsed into one story.
///
/// Closed, with thirty-five entries (twenty-eight, six resolution variants,
/// one series opening). Authors compose; they never invent. Each
/// beat declares what it requires and what it produces, which is what makes
/// narrative state derivable rather than authored.
public enum StoryBeat: String, Codable, Sendable, Hashable, CaseIterable {
    // Orientation
    case establishOrdinary = "establish_ordinary"
    case noticeAnomaly = "notice_anomaly"
    case approach
    case examine

    // Relational
    case meetCompanion = "meet_companion"
    case companionOffers = "companion_offers"
    case receiveAppeal = "receive_appeal"
    case commit

    // Belief
    case formBelief = "form_belief"
    case beliefFails = "belief_fails"
    case revealTruth = "reveal_truth"

    // Effort
    case firstAttempt = "first_attempt"
    case obstacleRaises = "obstacle_raises"
    case insight
    case cooperativeEffort = "cooperative_effort"
    case persist
    case askForHelp = "ask_for_help"

    // Internal
    case hesitate
    case smallStep = "small_step"
    case findOwnCourage = "find_own_courage"
    case selfRecognize = "self_recognize"

    // Care
    case takeCharge = "take_charge"
    case tend
    case patientWait = "patient_wait"

    // Closing
    case succeed
    case restore
    case warmClose = "warm_close"
    case carryForward = "carry_forward"

    // MARK: Resolution variants (Phase 5)
    //
    // Six beats the fourteen-blueprint catalog uses that the original
    // twenty-eight did not contain. They are not new *kinds* of move: each is a
    // sibling of a beat already here, differing in how the way forward is
    // found. Their preconditions and products are fixed by where the catalog's
    // arcs put them, and every one of those arcs is validated in CI — an
    // invented requirement would show up as a broken arc, not as an opinion.

    /// The child says what someone else cannot. Family III's resolution when
    /// the companion has no voice of its own.
    case speakFor = "speak_for"
    /// The child gives up something of theirs. Family III resolving by cost
    /// rather than by cooperation.
    case giveUpSomething = "give_up_something"
    /// The child goes back over the ground already covered. Family IV's
    /// alternative to persisting forward.
    case retrace
    /// The child listens, and sees the same thing differently. Family V
    /// resolving through the companion rather than by direct revelation.
    case exchangeViews = "exchange_views"
    /// The child releases what they cared for, because that is the good
    /// outcome. Family VI.
    case letGo = "let_go"
    /// The child gets ready before trying. An attempt beat, sibling to
    /// `small_step`.
    case prepare

    // MARK: Series (FAZ 13)

    /// The child comes back to a place and a friend the reader already knows.
    /// The opening of every later episode of a series, in place of meeting the
    /// companion: nobody is introduced twice. Only continuation blueprints use
    /// it, and only on page 1 (`BeatSequenceValidator`).
    case revisit

    /// What must already be true for this beat to be usable.
    public var requires: BeatRequirement {
        switch self {
        case .establishOrdinary, .noticeAnomaly, .meetCompanion, .hesitate, .revisit:
            return .none
        case .approach, .examine, .formBelief:
            return .all([.anomalyKnown])
        // Taking charge is taking charge *of* someone.
        case .takeCharge:
            return .all([.anomalyKnown, .companionPresent])
        case .companionOffers:
            return .all([.companionPresent])
        case .receiveAppeal:
            return .all([.companionPresent])
        // The only disjunction: you can commit to an anomaly or to a stated need.
        case .commit:
            return .any([.anomalyKnown, .needKnown])
        case .beliefFails:
            return .all([.beliefFormed])
        case .revealTruth:
            return .all([.beliefFormed, .attemptMade, .obstacleNamed])
        case .firstAttempt, .obstacleRaises, .tend:
            return .all([.committed])
        // Family I's insight combines what was observed with what was tried.
        // Requiring only an obstacle let a belief be formed on page 4 and never
        // read again.
        case .insight:
            return .all([.beliefFormed, .attemptMade, .obstacleNamed])
        case .cooperativeEffort, .askForHelp, .speakFor, .giveUpSomething:
            return .all([.companionPresent, .obstacleNamed, .attemptMade])
        // Also needs the belief, or misreading_twosides_002's page-2 belief is
        // formed and never read.
        case .exchangeViews:
            return .all([.companionPresent, .beliefFormed, .obstacleNamed, .attemptMade])
        case .persist:
            return .all([.attemptMade, .obstacleNamed])
        case .retrace:
            return .all([.companionPresent, .obstacleNamed, .attemptMade])
        // You cannot let go of something you never took charge of.
        case .letGo:
            return .all([.committed, .attemptMade, .needKnown])
        // The companion must be there: a child taking the first small step
        // with nobody beside them is a different story, and page 3 was
        // otherwise deletable.
        case .smallStep, .prepare:
            return .all([.hesitationNamed, .companionPresent])
        case .findOwnCourage:
            return .all([.hesitationNamed, .attemptMade, .obstacleNamed])
        case .patientWait:
            return .all([.attemptMade])
        case .succeed:
            return .all([.solutionKnown])
        case .restore:
            return .all([.solutionKnown, .needKnown])
        case .selfRecognize, .warmClose, .carryForward:
            return .all([.resolved])
        }
    }

    /// What becomes true once this beat has happened.
    public var produces: [NarrativeStateKey] {
        switch self {
        case .establishOrdinary, .approach, .examine, .companionOffers,
             .selfRecognize, .warmClose, .carryForward:
            return []
        case .noticeAnomaly: return [.anomalyKnown]
        case .meetCompanion, .revisit: return [.companionPresent]
        case .receiveAppeal: return [.needKnown]
        case .commit: return [.committed]
        case .formBelief: return [.beliefFormed]
        case .beliefFails, .obstacleRaises: return [.obstacleNamed]
        case .revealTruth, .insight, .cooperativeEffort, .persist,
             .askForHelp, .findOwnCourage, .patientWait,
             .speakFor, .giveUpSomething, .retrace, .exchangeViews, .letGo:
            return [.solutionKnown]
        case .firstAttempt, .smallStep, .tend, .prepare: return [.attemptMade]
        case .hesitate: return [.hesitationNamed, .obstacleNamed]
        case .takeCharge: return [.committed, .needKnown]
        case .succeed, .restore: return [.resolved]
        }
    }

    /// Beats that make the way forward known.
    ///
    /// In every one the child is the agent. The companion may contribute
    /// knowledge or hands; it may never be the subject of the beat that resolves
    /// the story. `cooperativeEffort` and `askForHelp` are the delicate ones and
    /// are still the child's act: the child *joins*, the child *asks*.
    public static var resolvingBeats: [StoryBeat] {
        allCases.filter { $0.produces.contains(.solutionKnown) }
    }

    /// Beats that may appear on the closing page.
    public static let closingBeats: Set<StoryBeat> = [.warmClose, .carryForward, .selfRecognize]

    public var isClosing: Bool { Self.closingBeats.contains(self) }
}
