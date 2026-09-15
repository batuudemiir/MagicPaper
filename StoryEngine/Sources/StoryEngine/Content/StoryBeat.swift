import Foundation

/// What *happens* on a page, as opposed to what the page is *for*.
///
/// This is the central mechanism of the architecture. Page role is the spine and
/// is fixed; the beat is the variable. The same role carries a different beat in
/// every family — page 4 `problem` is `form_belief` in one family, `hesitate` in
/// another, `receive_appeal` in a third. That is what the previous system could
/// not express, and why twelve blueprints collapsed into one story.
///
/// Closed, with twenty-eight entries. Authors compose; they never invent. Each
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

    /// What must already be true for this beat to be usable.
    public var requires: BeatRequirement {
        switch self {
        case .establishOrdinary, .noticeAnomaly, .meetCompanion, .hesitate:
            return .none
        case .approach, .examine, .formBelief, .takeCharge:
            return .all([.anomalyKnown])
        case .companionOffers:
            return .all([.companionPresent])
        case .receiveAppeal:
            return .all([.companionPresent])
        // The only disjunction: you can commit to an anomaly or to a stated need.
        case .commit:
            return .any([.anomalyKnown, .needKnown])
        case .beliefFails, .revealTruth:
            return .all([.beliefFormed])
        case .firstAttempt, .obstacleRaises, .tend:
            return .all([.committed])
        case .insight:
            return .all([.obstacleNamed])
        case .cooperativeEffort, .askForHelp:
            return .all([.companionPresent, .obstacleNamed])
        case .persist:
            return .all([.attemptMade, .obstacleNamed])
        case .smallStep:
            return .all([.hesitationNamed])
        case .findOwnCourage:
            return .all([.hesitationNamed, .attemptMade])
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
        case .meetCompanion: return [.companionPresent]
        case .receiveAppeal: return [.needKnown]
        case .commit: return [.committed]
        case .formBelief: return [.beliefFormed]
        case .beliefFails, .obstacleRaises: return [.obstacleNamed]
        case .revealTruth, .insight, .cooperativeEffort, .persist,
             .askForHelp, .findOwnCourage, .patientWait:
            return [.solutionKnown]
        case .firstAttempt, .smallStep, .tend: return [.attemptMade]
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
