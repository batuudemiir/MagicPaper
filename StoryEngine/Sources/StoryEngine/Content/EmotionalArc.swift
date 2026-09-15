import Foundation

/// How a page feels. Closed, with an intensity used for the safety ceiling.
///
/// Intensity is the mechanism that turns "nothing frightening" from a review
/// note into something checkable at load.
public enum EmotionalState: String, Codable, Sendable, Hashable, CaseIterable {
    // Intensity 0 — settled, or a positive landing
    case ease, calm, warmth
    case joy, relief, pride, delight, insight, satisfaction

    // Intensity 1 — engaged
    case curiosity, wonder, puzzlement, determination, surprise
    case tenderness, certainty, duty, sympathy

    // Intensity 2 — tension a five-year-old can hold
    case unease, hesitation, concern, doubt, effort, frustration, patience

    // Intensity 3 — never permitted at age 5–6
    case fear, panic, grief, despair

    public var intensity: Int {
        switch self {
        case .ease, .calm, .warmth, .joy, .relief, .pride, .delight, .insight, .satisfaction:
            return 0
        case .curiosity, .wonder, .puzzlement, .determination, .surprise,
             .tenderness, .certainty, .duty, .sympathy:
            return 1
        case .unease, .hesitation, .concern, .doubt, .effort, .frustration, .patience:
            return 2
        case .fear, .panic, .grief, .despair:
            return 3
        }
    }

    /// States a story may end on: settled, or an earned positive feeling.
    public static let permittedLandings: Set<EmotionalState> = [
        .warmth, .calm, .ease, .pride, .joy, .relief, .tenderness, .satisfaction, .delight
    ]

    public var isPermittedLanding: Bool { Self.permittedLandings.contains(self) }
}

/// What pulls the child into the story.
public enum CuriosityMechanism: String, Codable, Sendable, Hashable, CaseIterable {
    case unexplainedPhenomenon
    case barrierWithSomethingBeyond
    case anotherStatedNeed
    case somethingMissing
    case apparentEvidence
    case smallThingNeedingCare
}

/// What resists.
public enum ConflictMechanism: String, Codable, Sendable, Hashable, CaseIterable {
    case cognitive
    case interior = "internal"
    case relational
    case uncertainty
    case perceptual
    case duration
}

/// What earns the ending.
public enum ResolutionMechanism: String, Codable, Sendable, Hashable, CaseIterable {
    case insight
    case incrementalCourage
    case cooperation
    case persistence
    case revelation
    case patience
}

/// The six narrative families.
///
/// Every mechanism value is unique to one family, so all fifteen family pairs
/// differ on all three axes by construction. The diversity gate's real work is
/// therefore *within* a family, where blueprints share curiosity and conflict and
/// differ only on resolution.
public enum NarrativeFamily: String, Codable, Sendable, Hashable, CaseIterable {
    case unexplained
    case threshold
    case appeal
    case absence
    case misreading
    case charge

    public var curiosity: CuriosityMechanism {
        switch self {
        case .unexplained: return .unexplainedPhenomenon
        case .threshold: return .barrierWithSomethingBeyond
        case .appeal: return .anotherStatedNeed
        case .absence: return .somethingMissing
        case .misreading: return .apparentEvidence
        case .charge: return .smallThingNeedingCare
        }
    }

    public var conflict: ConflictMechanism {
        switch self {
        case .unexplained: return .cognitive
        case .threshold: return .interior
        case .appeal: return .relational
        case .absence: return .uncertainty
        case .misreading: return .perceptual
        case .charge: return .duration
        }
    }

    public var resolution: ResolutionMechanism {
        switch self {
        case .unexplained: return .insight
        case .threshold: return .incrementalCourage
        case .appeal: return .cooperation
        case .absence: return .persistence
        case .misreading: return .revelation
        case .charge: return .patience
        }
    }

    /// The beat that realizes this family's resolution mechanism — the one that
    /// makes the way forward known.
    ///
    /// Distinct from the second half of `signatureBeats`. In five families they
    /// coincide, but Family IV resolves *by persistence* (`persist`) and then
    /// closes with `restore`, which it shares with Family III. Conflating the
    /// mechanism beat with the closing beat would make those two families look
    /// alike to the diversity gate, which is exactly what it must not do.
    public var resolutionBeat: StoryBeat {
        switch self {
        case .unexplained: return .insight
        case .threshold: return .findOwnCourage
        case .appeal: return .cooperativeEffort
        case .absence: return .persist
        case .misreading: return .revealTruth
        case .charge: return .patientWait
        }
    }

    /// The pair of beats that identifies this family, as documented: what sets
    /// the family's problem up, and what it closes on.
    public var signatureBeats: (setup: StoryBeat, resolve: StoryBeat) {
        switch self {
        case .unexplained: return (.formBelief, .insight)
        case .threshold: return (.hesitate, .findOwnCourage)
        case .appeal: return (.receiveAppeal, .cooperativeEffort)
        case .absence: return (.persist, .restore)
        case .misreading: return (.beliefFails, .revealTruth)
        case .charge: return (.takeCharge, .patientWait)
        }
    }

    /// How far apart two families are on mechanism. Always 3 between distinct
    /// families, by construction — which is exactly why the gate cannot rely on it.
    public func mechanismDistance(to other: NarrativeFamily) -> Int {
        var distance = 0
        if curiosity != other.curiosity { distance += 1 }
        if conflict != other.conflict { distance += 1 }
        if resolution != other.resolution { distance += 1 }
        return distance
    }
}
