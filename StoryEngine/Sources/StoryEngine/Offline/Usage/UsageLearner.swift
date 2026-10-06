import Foundation

/// One story the child has read, as the learner sees it (FAZ 14).
///
/// Ids and counts only. Who the story was for, what it said and when it was
/// read never reach the engine.
public struct StoryUsage: Sendable, Hashable {
    public let blueprintID: ContentID
    public let companionID: ContentID?
    /// Nil for a story written before modes existed; it is judged by the
    /// default rule.
    public let mode: StoryMode?
    /// How many times the child reached the last page.
    public let completions: Int
    /// The last reading stopped before the end, and the story was never
    /// finished. Whether that means anything depends on the mode.
    public let abandoned: Bool

    public init(
        blueprintID: ContentID,
        companionID: ContentID?,
        mode: StoryMode?,
        completions: Int,
        abandoned: Bool
    ) {
        self.blueprintID = blueprintID
        self.companionID = companionID
        self.mode = mode
        self.completions = completions
        self.abandoned = abandoned
    }
}

/// What the child's reading taught, as multipliers on selection weight.
///
/// Only keys with something learned are stored; everything else is exactly 1,
/// so a child with nothing read — and every story before FAZ 14 — gets the
/// seeded rotation the engine always used.
public struct UsageProfile: Sendable, Hashable {
    public let families: [NarrativeFamily: Double]
    public let companions: [ContentID: Double]

    public init(families: [NarrativeFamily: Double], companions: [ContentID: Double]) {
        self.families = families
        self.companions = companions
    }

    public static let neutral = UsageProfile(families: [:], companions: [:])

    public func multiplier(family: NarrativeFamily?) -> Double {
        family.flatMap { families[$0] } ?? 1
    }

    public func multiplier(companion: ContentID) -> Double {
        companions[companion] ?? 1
    }
}

/// Turns a child's reading into a `UsageProfile`. Pure and deterministic.
///
/// Each story gives one signal to its narrative family and its companion:
/// re-read (finished twice or more) +1, finished once +¼, abandoned −1 when
/// the mode counts abandoning (`ModeSuccessRule`), otherwise 0. A key's
/// multiplier is `1 + sum / (stories + prior)`: the prior keeps one story
/// from deciding much, and it is clamped so learning nudges and never
/// outweighs an interest (×3) or a cooldown.
///
/// Every signal is a multiple of ¼, so sums are exact in binary floating
/// point and the result cannot depend on the order stories arrive in.
public enum UsageLearner {
    public static let rereadSignal = 1.0
    public static let completionSignal = 0.25
    public static let abandonSignal = -1.0
    /// Imagined neutral stories every key starts with.
    public static let prior = 2.0
    public static let floor = 0.6
    public static let ceiling = 1.8

    public static func profile(from stories: [StoryUsage], catalog: ContentCatalog) -> UsageProfile {
        guard !stories.isEmpty else { return .neutral }
        var familyOf: [ContentID: NarrativeFamily] = [:]
        for blueprint in catalog.blueprints + catalog.series.continuations {
            if let family = blueprint.family { familyOf[blueprint.id] = family }
        }

        var families: [NarrativeFamily: (sum: Double, count: Double)] = [:]
        var companions: [ContentID: (sum: Double, count: Double)] = [:]
        for story in stories {
            let rule = story.mode.flatMap { catalog.modeProfile($0)?.success } ?? .default
            let value = signal(story, rule: rule)
            if let family = familyOf[story.blueprintID] {
                families[family, default: (0, 0)].sum += value
                families[family, default: (0, 0)].count += 1
            }
            if let companion = story.companionID {
                companions[companion, default: (0, 0)].sum += value
                companions[companion, default: (0, 0)].count += 1
            }
        }
        return UsageProfile(
            families: families.compactMapValues(multiplier),
            companions: companions.compactMapValues(multiplier))
    }

    static func signal(_ story: StoryUsage, rule: ModeSuccessRule) -> Double {
        if story.completions >= 2 { return rereadSignal }
        if story.completions == 1 { return completionSignal }
        if story.abandoned && rule.abandonIsPenalty { return abandonSignal }
        return 0
    }

    /// Nil when nothing was learned, so the key stays out and reads as 1.
    private static func multiplier(_ tally: (sum: Double, count: Double)) -> Double? {
        guard tally.sum != 0 else { return nil }
        return min(ceiling, max(floor, 1 + tally.sum / (tally.count + prior)))
    }
}
