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
    /// Whether this stops the blueprint shipping.
    ///
    /// Everything the validator checked before liveness is structural: an unmet
    /// precondition or a story that resolves on page 5 is incoherent, not
    /// merely weak. Liveness is different — an inert page is a *quality*
    /// failure, and grading it fatal would make every blueprint in the library
    /// unselectable overnight for a defect whose real fix is in the beat
    /// vocabulary, not the blueprint.
    public enum Severity: String, Sendable, Hashable { case fatal, warning }

    public let severity: Severity
    public let pageNumber: Int
    public let beat: StoryBeat
    public let code: String
    public let message: String

    public init(
        severity: Severity = .fatal,
        pageNumber: Int,
        beat: StoryBeat,
        code: String,
        message: String
    ) {
        self.severity = severity
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

    /// Issues that stop the blueprint shipping.
    public var fatalIssues: [BeatSequenceIssue] { issues.filter { $0.severity == .fatal } }
    /// Issues worth an author's attention that do not block.
    public var warnings: [BeatSequenceIssue] { issues.filter { $0.severity == .warning } }

    public var isValid: Bool { fatalIssues.isEmpty }
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
        issues.append(contentsOf: checkLiveness(ordered))

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

        // A return opens the book (FAZ 13): coming back to the place halfway
        // through an episode is a second story, not a continuation.
        for slot in slots where slot.pageNumber != 1 && slot.beats.contains(.revisit) {
            issues.append(.init(pageNumber: slot.pageNumber, beat: .revisit, code: "revisit_out_of_place",
                                message: "'revisit' may only appear on page 1; it is on page \(slot.pageNumber)."))
        }

        // Bu iki kural MUTLAK sayfa numaralarına yazılmıştı — "5. sayfaya kadar
        // engel", "7. sayfada çözüm" — ve sekiz sayfalık bir yay dışında hiçbir
        // şey için anlamlı değildi. Altı sayfalık bir masal 5. sayfada çözülür;
        // bu bir kusur değil, daha kısa bir kitaptır.
        //
        // Altta yatan özellikler sayfa numarası değil YAYDAKİ KONUM:
        // çözüm sondan bir önceki sayfaya düşer (son sayfa kapanır), engel de
        // çözümden en az iki sayfa önce adını almış olmalı ki tam olarak
        // çalışmayan denemeye yer kalsın. Sekiz sayfada bu eski sayıları
        // aynen verir: 7 ve 5.
        let closingPage = slots.map(\.pageNumber).max() ?? 1
        let resolutionPage = max(1, closingPage - 1)
        let obstacleDeadline = max(1, resolutionPage - 2)

        // The difficulty must be concrete before the attempt that does not fully
        // work — except where the conflict is duration and nothing blocks.
        let mechanismExempt = conflictMechanism.map(Self.mechanismsWithoutObstacle.contains) ?? false
        if !mechanismExempt {
            let namedInTime = statesByPage
                .filter { $0.key <= obstacleDeadline }
                .contains { $0.value.contains(.obstacleNamed) }
            if !namedInTime {
                issues.append(.init(pageNumber: obstacleDeadline, beat: .obstacleRaises, code: "obstacle_too_late",
                                    message: "'obstacleNamed' must be true by page \(obstacleDeadline)."))
            }
        }

        // Çözüm sondan bir önceki sayfada: ne erken ne geç.
        let resolvedPage = statesByPage.filter { $0.value.isResolved }.keys.min()
        if let resolvedPage {
            if resolvedPage < resolutionPage {
                issues.append(.init(pageNumber: resolvedPage, beat: .succeed, code: "resolved_too_early",
                                    message: "The story resolves on page \(resolvedPage); nothing may resolve before page \(resolutionPage)."))
            }
            if resolvedPage > resolutionPage {
                issues.append(.init(pageNumber: resolvedPage, beat: .succeed, code: "resolved_too_late",
                                    message: "The story resolves on page \(resolvedPage); it must be resolved by page \(resolutionPage)."))
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

    /// A page that produces narrative state nothing later reads.
    ///
    /// The test is the one that makes the failure concrete: **delete the page,
    /// and see whether anything downstream notices.** If every remaining beat's
    /// preconditions still hold and the story still resolves, the engine would
    /// produce the same book without that page — so whatever the page is doing,
    /// it is not doing it structurally.
    ///
    /// Two exemptions, both principled rather than convenient:
    ///
    /// - **The final page.** An ending is not load-bearing by design; it is
    ///   governed by `non_closing_final_page` and `unsettled_landing` instead.
    ///   Without this every blueprint ever written fails.
    /// - **Pages that produce nothing at all.** This rule is about state that
    ///   goes unread. A page producing no state is not making an unread claim —
    ///   whether an orientation beat earns its page is a different question, and
    ///   the beat vocabulary is what would have to answer it.
    ///
    /// The usual fix is *not* to delete the page. It is to tighten the beat
    /// vocabulary so that what the page establishes is genuinely required later.
    private func checkLiveness(_ slots: [BeatSlot]) -> [BeatSequenceIssue] {
        guard let last = slots.last, slots.count > 1 else { return [] }

        return slots.compactMap { candidate in
            guard candidate.pageNumber != last.pageNumber else { return nil }

            let produced = Set(candidate.beats.flatMap(\.produces))
            guard !produced.isEmpty else { return nil }

            var state = DerivedNarrativeState()
            for slot in slots where slot.pageNumber != candidate.pageNumber {
                for beat in slot.beats {
                    guard beat.requires.isSatisfied(by: state) else { return nil }
                    state.produce(beat.produces)
                }
            }
            guard state.isResolved else { return nil }

            let names = produced.map(\.rawValue).sorted().joined(separator: ", ")
            return BeatSequenceIssue(
                severity: .warning,
                pageNumber: candidate.pageNumber,
                beat: candidate.beat,
                code: "inert_page",
                message: "Page \(candidate.pageNumber) produces \(names), which nothing later requires; "
                       + "the story still resolves with this page deleted."
            )
        }
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
