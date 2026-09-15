import Foundation

/// A page's beats, in the order they happen.
public struct BeatSlot: Sendable, Hashable {
    public let pageNumber: Int
    public let role: PageRole
    public let beat: StoryBeat
    public let supportingBeat: StoryBeat?
    public let emotion: EmotionalState?

    public init(
        pageNumber: Int,
        role: PageRole,
        beat: StoryBeat,
        supportingBeat: StoryBeat? = nil,
        emotion: EmotionalState? = nil
    ) {
        self.pageNumber = pageNumber
        self.role = role
        self.beat = beat
        self.supportingBeat = supportingBeat
        self.emotion = emotion
    }

    /// Both beats in order; the supporting beat happens after the required one.
    public var beats: [StoryBeat] {
        supportingBeat.map { [beat, $0] } ?? [beat]
    }
}

public struct BeatSequenceIssue: Sendable, Hashable {
    public let pageNumber: Int
    public let beat: StoryBeat
    public let code: String
    public let message: String

    public init(pageNumber: Int, beat: StoryBeat, code: String, message: String) {
        self.pageNumber = pageNumber
        self.beat = beat
        self.code = code
        self.message = message
    }
}

public struct BeatSequenceResult: Sendable {
    public let issues: [BeatSequenceIssue]
    /// State after every beat has been applied.
    public let finalState: DerivedNarrativeState
    /// State as it stood at the end of each page, for pacing checks.
    public let statesByPage: [Int: DerivedNarrativeState]

    public var isValid: Bool { issues.isEmpty }
}

/// Walks a blueprint's beats and checks the story actually holds together.
///
/// This is the rule that makes "page 7 resolves a conflict page 6 never raised"
/// a build failure rather than something a reader notices. It also makes the
/// unearned resolution impossible: `succeed` requires `solutionKnown`, and every
/// producer of `solutionKnown` is a caused action by the child, so there is no
/// path to a resolved story that does not pass through something the child did.
public struct BeatSequenceValidator: Sendable {
    /// Family VI's conflict is time, not difficulty. Nothing blocks the child,
    /// so it never produces `obstacleNamed`, and demanding one would destroy the
    /// only family whose tension is duration.
    private static let mechanismsWithoutObstacle: Set<ConflictMechanism> = [.duration]

    public init() {}

    public func validate(
        _ slots: [BeatSlot],
        conflictMechanism: ConflictMechanism? = nil,
        intensityCeiling: Int = 2
    ) -> BeatSequenceResult {
        var issues: [BeatSequenceIssue] = []
        var state = DerivedNarrativeState()
        var statesByPage: [Int: DerivedNarrativeState] = [:]
        let ordered = slots.sorted { $0.pageNumber < $1.pageNumber }

        // §4.3 — preconditions must be met in order.
        for slot in ordered {
            for beat in slot.beats {
                let requirement = beat.requires
                if !requirement.isSatisfied(by: state) {
                    let missing = requirement.unmet(in: state).map(\.rawValue).joined(separator: ", ")
                    issues.append(.init(
                        pageNumber: slot.pageNumber, beat: beat, code: "unmet_precondition",
                        message: "Page \(slot.pageNumber) uses '\(beat.rawValue)', which needs \(requirement.description); missing \(missing)."
                    ))
                }
                state.produce(beat.produces)
            }
            statesByPage[slot.pageNumber] = state
        }

        issues.append(contentsOf: checkResolution(ordered, statesByPage: statesByPage, finalState: state))
        issues.append(contentsOf: checkPacing(ordered, statesByPage: statesByPage, conflictMechanism: conflictMechanism))
        issues.append(contentsOf: checkEmotionalSafety(ordered, intensityCeiling: intensityCeiling))

        return BeatSequenceResult(issues: issues, finalState: state, statesByPage: statesByPage)
    }

    // MARK: - Rules

    private func checkResolution(
        _ slots: [BeatSlot],
        statesByPage: [Int: DerivedNarrativeState],
        finalState: DerivedNarrativeState
    ) -> [BeatSequenceIssue] {
        guard let last = slots.last else { return [] }
        guard finalState.isResolved else {
            return [.init(pageNumber: last.pageNumber, beat: last.beat, code: "never_resolves",
                          message: "The story never reaches 'resolved'. Every story must resolve.")]
        }
        return []
    }

    private func checkPacing(
        _ slots: [BeatSlot],
        statesByPage: [Int: DerivedNarrativeState],
        conflictMechanism: ConflictMechanism?
    ) -> [BeatSequenceIssue] {
        var issues: [BeatSequenceIssue] = []
        guard let last = slots.last else { return [] }

        // The story cannot spend three pages on setup.
        let anomalyPage = slots.first { $0.beats.contains(.noticeAnomaly) }?.pageNumber
        if let anomalyPage, anomalyPage > 2 {
            issues.append(.init(pageNumber: anomalyPage, beat: .noticeAnomaly, code: "anomaly_too_late",
                                message: "'notice_anomaly' must occur by page 2; it is on page \(anomalyPage)."))
        } else if anomalyPage == nil {
            issues.append(.init(pageNumber: 1, beat: .noticeAnomaly, code: "anomaly_missing",
                                message: "No page carries 'notice_anomaly'; nothing pulls the child in."))
        }

        // At most one page may establish the ordinary, and only page 1.
        let ordinaryPages = slots.filter { $0.beats.contains(.establishOrdinary) }.map(\.pageNumber)
        if ordinaryPages.count > 1 {
            issues.append(.init(pageNumber: ordinaryPages[1], beat: .establishOrdinary, code: "too_much_setup",
                                message: "'establish_ordinary' appears on pages \(ordinaryPages); at most one is allowed."))
        }
        if let first = ordinaryPages.first, first != 1 {
            issues.append(.init(pageNumber: first, beat: .establishOrdinary, code: "setup_out_of_place",
                                message: "'establish_ordinary' may only appear on page 1; it is on page \(first)."))
        }

        // The difficulty must be concrete before the attempt that does not fully
        // work — except where the conflict is duration and nothing blocks.
        let mechanismExempt = conflictMechanism.map(Self.mechanismsWithoutObstacle.contains) ?? false
        if !mechanismExempt {
            let namedByFive = statesByPage
                .filter { $0.key <= 5 }
                .contains { $0.value.contains(.obstacleNamed) }
            if !namedByFive {
                issues.append(.init(pageNumber: 5, beat: .obstacleRaises, code: "obstacle_too_late",
                                    message: "'obstacleNamed' must be true by page 5."))
            }
        }

        // Resolution lands on page 7, not before and not after.
        let resolvedPage = statesByPage.filter { $0.value.isResolved }.keys.min()
        if let resolvedPage {
            if resolvedPage < 7 {
                issues.append(.init(pageNumber: resolvedPage, beat: .succeed, code: "resolved_too_early",
                                    message: "The story resolves on page \(resolvedPage); nothing may resolve before page 7."))
            }
            if resolvedPage > 7 {
                issues.append(.init(pageNumber: resolvedPage, beat: .succeed, code: "resolved_too_late",
                                    message: "The story resolves on page \(resolvedPage); it must be resolved by page 7."))
            }
        }

        // The last page winds down; it does not do new work.
        let nonClosing = last.beats.filter { !$0.isClosing }
        if !nonClosing.isEmpty {
            issues.append(.init(pageNumber: last.pageNumber, beat: nonClosing[0], code: "non_closing_final_page",
                                message: "Page \(last.pageNumber) carries '\(nonClosing[0].rawValue)'; the final page may carry only closing beats."))
        }

        return issues
    }

    private func checkEmotionalSafety(_ slots: [BeatSlot], intensityCeiling: Int) -> [BeatSequenceIssue] {
        var issues: [BeatSequenceIssue] = []
        let emotions = slots.compactMap { slot in slot.emotion.map { (slot, $0) } }
        guard !emotions.isEmpty else { return [] }

        for (slot, emotion) in emotions where emotion.intensity > intensityCeiling {
            issues.append(.init(pageNumber: slot.pageNumber, beat: slot.beat, code: "intensity_over_ceiling",
                                message: "Page \(slot.pageNumber) feels '\(emotion.rawValue)' (intensity \(emotion.intensity)); the ceiling is \(intensityCeiling)."))
        }

        if let (slot, landing) = emotions.last, !landing.isPermittedLanding {
            issues.append(.init(pageNumber: slot.pageNumber, beat: slot.beat, code: "unsettled_landing",
                                message: "The story ends on '\(landing.rawValue)'; it must land settled or positive."))
        }

        // A five-year-old can hold tension for two spreads; three is where a
        // bedtime story stops being one.
        var run = 0
        for (slot, emotion) in emotions {
            run = emotion.intensity >= 2 ? run + 1 : 0
            if run > 2 {
                issues.append(.init(pageNumber: slot.pageNumber, beat: slot.beat, code: "sustained_tension",
                                    message: "Pages \(slot.pageNumber - 2)–\(slot.pageNumber) all sit at intensity 2; at most two consecutive are allowed."))
                break
            }
        }

        return issues
    }
}
