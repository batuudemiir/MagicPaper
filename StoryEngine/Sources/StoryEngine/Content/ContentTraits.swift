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

/// What one content axis must offer.
///
/// Conjunction alone cannot say what blueprints actually need. Thirteen of the
/// fourteen blueprints in `BLUEPRINT_CATALOG_V2.md` ask for something like
/// `isUnexplained ∧ (emitsSignal ∨ isFragmentary)` — a hard requirement plus a
/// choice — and a flat `Set` can express only the first half.
///
/// So: `allOf` must all be present, and **each** group in `anyOf` must be met by
/// at least one trait. Two groups mean two independent choices, not one.
public struct TraitRequirement<Trait>: Sendable, Hashable, ExpressibleByArrayLiteral
where Trait: Hashable & Codable & Sendable & RawRepresentable, Trait.RawValue == String {

    public let allOf: Set<Trait>
    public let anyOf: [Set<Trait>]

    public init(allOf: Set<Trait> = [], anyOf: [Set<Trait>] = []) {
        self.allOf = allOf
        // An empty choice group can never be satisfied, and an author who wrote
        // one meant to write nothing. Dropping it is the reading that cannot
        // silently make a blueprint unselectable.
        self.anyOf = anyOf.filter { !$0.isEmpty }
    }

    /// `[.hasThreshold]` still means "all of these", so the plain form reads
    /// unchanged wherever a choice is not needed.
    public init(arrayLiteral elements: Trait...) {
        self.init(allOf: Set(elements))
    }

    public var isEmpty: Bool { allOf.isEmpty && anyOf.isEmpty }

    /// Every trait this requirement could ever look at.
    public var mentioned: Set<Trait> { anyOf.reduce(allOf) { $0.union($1) } }

    public func isSatisfied(by offered: Set<Trait>) -> Bool {
        allOf.isSubset(of: offered) && anyOf.allSatisfy { !$0.isDisjoint(with: offered) }
    }

    /// Why this is not met, in the author's own terms — a missing hard trait is
    /// named, an unmet choice is shown as the choice it was.
    public func unmet(in offered: Set<Trait>) -> [String] {
        var reasons: [String] = []
        let missing = allOf.subtracting(offered)
        if !missing.isEmpty {
            reasons.append(missing.map(\.rawValue).sorted().joined(separator: ", "))
        }
        for group in anyOf where group.isDisjoint(with: offered) {
            reasons.append("one of " + group.map(\.rawValue).sorted().joined(separator: " or "))
        }
        return reasons
    }
}

extension TraitRequirement: Codable {
    /// Two authored forms. A bare array is the conjunction, which is what the
    /// existing corpus is written in; the object form adds the choice groups.
    /// Both decode, so adopting disjunction does not require rewriting content
    /// that never needed it.
    private enum CodingKeys: String, CodingKey { case allOf, anyOf }

    public init(from decoder: Decoder) throws {
        if let flat = try? decoder.singleValueContainer().decode(Set<Trait>.self) {
            self.init(allOf: flat)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            allOf: try container.decodeIfPresent(Set<Trait>.self, forKey: .allOf) ?? [],
            anyOf: try container.decodeIfPresent([Set<Trait>].self, forKey: .anyOf) ?? []
        )
    }

    public func encode(to encoder: Encoder) throws {
        guard !anyOf.isEmpty else {
            var single = encoder.singleValueContainer()
            try single.encode(allOf)
            return
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(allOf, forKey: .allOf)
        try container.encode(anyOf, forKey: .anyOf)
    }
}

/// The traits a blueprint needs from each content axis.
public struct ContentRequirements: Codable, Sendable, Hashable {
    public let setting: TraitRequirement<SettingTrait>
    public let companion: TraitRequirement<CompanionTrait>
    public let discovery: TraitRequirement<DiscoveryTrait>

    public init(
        setting: TraitRequirement<SettingTrait> = [],
        companion: TraitRequirement<CompanionTrait> = [],
        discovery: TraitRequirement<DiscoveryTrait> = []
    ) {
        self.setting = setting
        self.companion = companion
        self.discovery = discovery
    }

    public var isEmpty: Bool { setting.isEmpty && companion.isEmpty && discovery.isEmpty }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        setting = try container.decodeIfPresent(TraitRequirement<SettingTrait>.self, forKey: .setting) ?? []
        companion = try container.decodeIfPresent(TraitRequirement<CompanionTrait>.self, forKey: .companion) ?? []
        discovery = try container.decodeIfPresent(TraitRequirement<DiscoveryTrait>.self, forKey: .discovery) ?? []
    }
}

/// The traits a blueprint must *not* be given.
///
/// Not an afterthought — this is where a blueprint's dramatic identity lives.
/// A Family II blueprint whose premise is *the child must cross this
/// themselves* has to forbid `canCarry`, or an obliging dragon carries them
/// across and the premise evaporates silently. The story still generates. It is
/// just no longer the story.
///
/// Flat sets, deliberately: exclusion is "offers none of these". A *choice* of
/// things to forbid has no meaning — forbidding `a ∨ b` either forbids both or
/// forbids nothing in particular — so this is not `TraitRequirement`.
public struct ContentExclusions: Codable, Sendable, Hashable {
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

// MARK: - Matching

/// Whether a piece of content may be used for a slot: it meets the requirement
/// and offers nothing forbidden.
///
/// Stated once, generically, so the three axes cannot drift apart.
public enum TraitMatch {
    public static func admits<Trait>(
        offered: Set<Trait>,
        required: TraitRequirement<Trait>,
        forbidden: Set<Trait>
    ) -> Bool {
        !offered.isEmpty
            && required.isSatisfied(by: offered)
            && offered.isDisjoint(with: forbidden)
    }

    /// Why a candidate was rejected — never a bare "no". An empty candidate
    /// pool has to be explainable, which is the whole reason `noBlueprintsFound`
    /// was unattributable.
    public static func rejection<Trait>(
        offered: Set<Trait>,
        required: TraitRequirement<Trait>,
        forbidden: Set<Trait>
    ) -> String? {
        // Content that declares no traits has made no claims, so nothing about
        // it can be checked against a blueprint's premise. An empty requirement
        // would otherwise admit it — which is how merging the V1 library, whose
        // records carry no traits at all, put an unclassified bear into a story
        // that needed a companion able to ask for help.
        //
        // This is the §8.4 rule applied to the content side: an unmigrated
        // record is unavailable to trait-based selection, and says so, rather
        // than passing silently because nobody asked it anything.
        guard !offered.isEmpty else { return "declares no traits" }

        let missing = required.unmet(in: offered)
        let present = offered.intersection(forbidden)
        if missing.isEmpty && present.isEmpty { return nil }
        var parts: [String] = []
        if !missing.isEmpty {
            parts.append("lacks " + missing.joined(separator: "; "))
        }
        if !present.isEmpty {
            parts.append("offers forbidden " + present.map(\.rawValue).sorted().joined(separator: ", "))
        }
        return parts.joined(separator: "; ")
    }
}
