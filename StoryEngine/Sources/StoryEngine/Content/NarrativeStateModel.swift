import Foundation

/// The complete narrative state vocabulary: ten booleans, every one produced by
/// at least one beat and consumed by at least one beat.
///
/// Closed and boolean on purpose. No counters, no enums, no numeric values, no
/// branching. An eleventh key is a schema change with a review, not a content edit.
public enum NarrativeStateKey: String, Codable, Sendable, Hashable, CaseIterable {
    case anomalyKnown
    case companionPresent
    case needKnown
    case committed
    case attemptMade
    case obstacleNamed
    case hesitationNamed
    case beliefFormed
    case solutionKnown
    case resolved
}

/// What a beat needs before it may be used.
///
/// Most beats need a conjunction or nothing; `commit` is the one that needs a
/// disjunction (something to commit *to* — either an anomaly or a stated need),
/// which is why this is an expression rather than a set.
public enum BeatRequirement: Sendable, Hashable {
    case none
    /// Every key must hold.
    case all([NarrativeStateKey])
    /// At least one key must hold.
    case any([NarrativeStateKey])

    public func isSatisfied(by state: DerivedNarrativeState) -> Bool {
        switch self {
        case .none: return true
        case .all(let keys): return keys.allSatisfy(state.contains)
        case .any(let keys): return keys.contains(where: state.contains)
        }
    }

    /// The keys mentioned, for reporting which precondition was missing.
    public var keys: [NarrativeStateKey] {
        switch self {
        case .none: return []
        case .all(let keys), .any(let keys): return keys
        }
    }

    public func unmet(in state: DerivedNarrativeState) -> [NarrativeStateKey] {
        switch self {
        case .none: return []
        case .all(let keys): return keys.filter { !state.contains($0) }
        case .any(let keys): return state.contains(where: keys) ? [] : keys
        }
    }

    public var description: String {
        switch self {
        case .none: return "—"
        case .all(let keys): return keys.map(\.rawValue).joined(separator: " ∧ ")
        case .any(let keys): return keys.map(\.rawValue).joined(separator: " ∨ ")
        }
    }
}

/// Where the story has got to.
///
/// Derived, never authored. Authors write beats; this is computed from them. An
/// unreachable precondition becomes unrepresentable rather than undetected —
/// which is the failure the previous authored-state model had at both ends.
public struct DerivedNarrativeState: Sendable, Hashable {
    private var keys: Set<NarrativeStateKey>

    /// Content bound at selection time, not produced by any beat.
    public var locationID: ContentID?
    public var companionID: ContentID?
    public var discoveryID: ContentID?

    public init(
        _ keys: Set<NarrativeStateKey> = [],
        locationID: ContentID? = nil,
        companionID: ContentID? = nil,
        discoveryID: ContentID? = nil
    ) {
        self.keys = keys
        self.locationID = locationID
        self.companionID = companionID
        self.discoveryID = discoveryID
    }

    public func contains(_ key: NarrativeStateKey) -> Bool { keys.contains(key) }
    public func contains(where candidates: [NarrativeStateKey]) -> Bool {
        candidates.contains(where: keys.contains)
    }

    public var activeKeys: Set<NarrativeStateKey> { keys }
    public var isResolved: Bool { keys.contains(.resolved) }

    public mutating func produce(_ produced: [NarrativeStateKey]) {
        keys.formUnion(produced)
    }

    public func producing(_ produced: [NarrativeStateKey]) -> DerivedNarrativeState {
        var copy = self
        copy.produce(produced)
        return copy
    }
}
