import Foundation
import EngineFoundation

// MARK: - What the child asked for

/// The three choices, plus what makes the result reproducible.
///
/// Note what is **not** here: a theme string, a genre, a page count, or any
/// engine-facing knob. The child picks a place, a companion and a discovery;
/// everything structural is derived from those.
public struct OfflineStoryIntent: Sendable, Hashable {
    public let childName: String
    /// Nil means "Surprise Me" — the engine picks from what is admissible.
    public let settingID: ContentID?
    public let companionID: ContentID?
    public let discoveryID: ContentID?
    /// Fixed input to every tie-break, so the same intent yields the same book.
    public let seed: String

    public init(
        childName: String,
        settingID: ContentID? = nil,
        companionID: ContentID? = nil,
        discoveryID: ContentID? = nil,
        seed: String
    ) {
        self.childName = childName
        self.settingID = settingID
        self.companionID = companionID
        self.discoveryID = discoveryID
        self.seed = seed
    }
}

// MARK: - Failure

/// Why nothing could be built.
///
/// Every case names the axis and carries the per-candidate reasons. This is the
/// direct replacement for `noBlueprintsFound`, a string that said only that
/// something was empty — and for `if filtered.isEmpty { return items }`, which
/// said nothing at all and shipped a dolphin into a forest.
public enum OfflineSelectionError: Error, Sendable, Equatable {
    case noBlueprints
    case noBlueprintForChoices(reasons: [String])
    case noSetting(reasons: [String])
    case noCompanion(reasons: [String])
    case noDiscovery(reasons: [String])
    case requestedContentRejected(id: ContentID, reason: String)
    case noTemplate(beat: StoryBeat, page: Int)
    case blueprintNotBeatAuthored(id: ContentID)

    public var explanation: String {
        switch self {
        case .noBlueprints:
            return "No beat-authored blueprint exists."
        case .noBlueprintForChoices(let reasons):
            return "No blueprint fits these choices:\n" + reasons.joined(separator: "\n")
        case .noSetting(let reasons):
            return "No setting fits this blueprint:\n" + reasons.joined(separator: "\n")
        case .noCompanion(let reasons):
            return "No companion fits this blueprint:\n" + reasons.joined(separator: "\n")
        case .noDiscovery(let reasons):
            return "No discovery fits this blueprint:\n" + reasons.joined(separator: "\n")
        case .requestedContentRejected(let id, let reason):
            return "'\(id.rawValue)' was asked for but cannot be used: \(reason)"
        case .noTemplate(let beat, let page):
            return "Page \(page) needs a template realizing '\(beat.rawValue)'; none exists."
        case .blueprintNotBeatAuthored(let id):
            return "Blueprint '\(id.rawValue)' declares no beats and cannot be composed."
        }
    }
}

// MARK: - Binding

/// The content a blueprint was filled with.
public struct BoundContent: Sendable, Hashable {
    public let setting: CatalogSetting
    public let companion: CatalogCompanion
    public let discovery: CatalogObject
}

/// Chooses content for a blueprint by trait intersection.
///
/// There is deliberately **no fallback**. If nothing is admissible the caller
/// gets a typed error listing why each candidate was rejected; it never gets an
/// arbitrary substitute that lets an incoherent story generate anyway.
public struct OfflineContentBinder: Sendable {
    public init() {}

    public func bind(
        blueprint: CatalogBlueprint,
        catalog: ContentCatalog,
        intent: OfflineStoryIntent
    ) throws -> BoundContent {
        let setting = try choose(
            catalog.settings, requested: intent.settingID, seed: intent.seed, axis: "setting",
            offered: \.traits, required: blueprint.requires.setting, forbidden: blueprint.forbids.setting,
            empty: OfflineSelectionError.noSetting
        )
        let companion = try choose(
            catalog.companions, requested: intent.companionID, seed: intent.seed, axis: "companion",
            offered: \.traits, required: blueprint.requires.companion, forbidden: blueprint.forbids.companion,
            empty: OfflineSelectionError.noCompanion
        )
        let discovery = try choose(
            catalog.objects, requested: intent.discoveryID, seed: intent.seed, axis: "discovery",
            offered: \.traits, required: blueprint.requires.discovery, forbidden: blueprint.forbids.discovery,
            empty: OfflineSelectionError.noDiscovery
        )
        return BoundContent(setting: setting, companion: companion, discovery: discovery)
    }

    /// One implementation for all three axes. Written generically on purpose:
    /// three hand-rolled copies is how the old code ended up filtering settings
    /// one way and companions another.
    private func choose<Record: Identifiable, Trait>(
        _ records: [Record],
        requested: ContentID?,
        seed: String,
        axis: String,
        offered: KeyPath<Record, Set<Trait>>,
        required: TraitRequirement<Trait>,
        forbidden: Set<Trait>,
        empty: ([String]) -> OfflineSelectionError
    ) throws -> Record where Record.ID == ContentID {
        var reasons: [String] = []
        var admissible: [Record] = []

        for record in records {
            if let reason = TraitMatch.rejection(
                offered: record[keyPath: offered], required: required, forbidden: forbidden
            ) {
                reasons.append("  \(record.id.rawValue): \(reason)")
            } else {
                admissible.append(record)
            }
        }

        // An explicit request is honoured or explained — never silently swapped.
        if let requested {
            if let match = admissible.first(where: { $0.id == requested }) { return match }
            let why = records.first(where: { $0.id == requested })
                .flatMap {
                    TraitMatch.rejection(offered: $0[keyPath: offered], required: required, forbidden: forbidden)
                } ?? "no such \(axis)"
            throw OfflineSelectionError.requestedContentRejected(id: requested, reason: why)
        }

        guard !admissible.isEmpty else { throw empty(reasons) }
        return DeterministicPicker.pick(from: admissible, seed: seed, salt: axis)
    }
}

// MARK: - Determinism

/// Picks reproducibly from a list.
///
/// Seeded rather than random, because §17 requires the same intent to produce
/// the same book — a parent who regenerates after a crash should not get a
/// different story — and because a test cannot assert on `Int.random`.
public enum DeterministicPicker {
    public static func index(count: Int, seed: String, salt: String) -> Int {
        guard count > 1 else { return 0 }
        return Int(StableHash.hash([seed, salt]) % UInt64(count))
    }

    public static func pick<T>(from items: [T], seed: String, salt: String) -> T {
        items[index(count: items.count, seed: seed, salt: salt)]
    }
}
