import Foundation

// MARK: - Trait vocabularies

/// What a setting *affords*, structurally.
///
/// Blueprints ask for affordances; settings offer them; selection is a set
/// intersection. No blueprint ever names a forest.
///
/// This replaces matching on identifiers, which is how the shipped catalog came
/// to declare `compatibleSettings: ["ocean"]` against settings whose ids are
/// `setting_ocean_001` — a reference that looks valid, compiles, ships, and
/// never matches anything.
public enum SettingTrait: String, Codable, Sendable, Hashable, CaseIterable {
    case canConceal, hasThreshold, hasDistance, hasHeight, hasWater
    case isEnclosed, isOpen, showsTraces, isTended, hasWeather
}

/// What a companion can *do to the story* — not what species it is.
///
/// The fifteen shipped companions have well-drawn personalities that nothing in
/// the old system could act on, because nothing could express why a timid
/// rabbit and a wise owl are not interchangeable. These traits are that
/// expression.
public enum CompanionTrait: String, Codable, Sendable, Hashable, CaseIterable {
    case canHesitate, canReassure, hasLocalKnowledge, isSmallAndVulnerable
    case isLiteralMinded, canFly, canCarry, isPlayful, isPatient
}

/// What the thing the child finds *implies*.
///
/// The child's third choice is the most emotionally invested one. Modelled as a
/// bare object it carries no structural information, and blueprint selection
/// loses its most informative input. Modelled as traits, it selects the shape
/// of the story.
public enum DiscoveryTrait: String, Codable, Sendable, Hashable, CaseIterable {
    case isUnexplained, emitsSignal, impliesPresence, impliesNeed
    case isFragmentary, isFragile, isBeautiful
}

// MARK: - Requirements and exclusions

/// The traits a blueprint needs from each content axis.
public struct ContentRequirements: Codable, Sendable, Hashable {
    public let setting: Set<SettingTrait>
    public let companion: Set<CompanionTrait>
    public let discovery: Set<DiscoveryTrait>

    public init(
        setting: Set<SettingTrait> = [],
        companion: Set<CompanionTrait> = [],
        discovery: Set<DiscoveryTrait> = []
    ) {
        self.setting = setting
        self.companion = companion
        self.discovery = discovery
    }

    public var isEmpty: Bool { setting.isEmpty && companion.isEmpty && discovery.isEmpty }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        setting = try container.decodeIfPresent(Set<SettingTrait>.self, forKey: .setting) ?? []
        companion = try container.decodeIfPresent(Set<CompanionTrait>.self, forKey: .companion) ?? []
        discovery = try container.decodeIfPresent(Set<DiscoveryTrait>.self, forKey: .discovery) ?? []
    }
}

/// The traits a blueprint must *not* be given.
///
/// Not an afterthought — this is where a blueprint's dramatic identity lives.
/// A Family II blueprint whose premise is *the child must cross this
/// themselves* has to forbid `canCarry`, or an obliging dragon carries them
/// across and the premise evaporates silently. The story still generates. It is
/// just no longer the story.
public typealias ContentExclusions = ContentRequirements

// MARK: - Matching

/// Whether a piece of content may be used for a slot: it offers everything
/// required and nothing forbidden.
///
/// Stated once, generically, so the three axes cannot drift apart.
public enum TraitMatch {
    public static func admits<T: Hashable>(
        offered: Set<T>,
        required: Set<T>,
        forbidden: Set<T>
    ) -> Bool {
        required.isSubset(of: offered) && offered.isDisjoint(with: forbidden)
    }

    /// Why a candidate was rejected — never a bare "no". An empty candidate
    /// pool has to be explainable, which is the whole reason `noBlueprintsFound`
    /// was unattributable.
    public static func rejection<T: Hashable & RawRepresentable>(
        offered: Set<T>,
        required: Set<T>,
        forbidden: Set<T>
    ) -> String? where T.RawValue == String {
        let missing = required.subtracting(offered)
        let present = offered.intersection(forbidden)
        if missing.isEmpty && present.isEmpty { return nil }
        var parts: [String] = []
        if !missing.isEmpty {
            parts.append("lacks \(missing.map(\.rawValue).sorted().joined(separator: ", "))")
        }
        if !present.isEmpty {
            parts.append("offers forbidden \(present.map(\.rawValue).sorted().joined(separator: ", "))")
        }
        return parts.joined(separator: "; ")
    }
}
