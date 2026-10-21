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
    case canConceal, hasThreshold, hasHeight, hasWater
    case isEnclosed, isOpen, showsTraces, isTended, hasWeather
    /// Somewhere a child could actually be hurt.
    ///
    /// The exclusion a Family II blueprint needs and could not previously
    /// write. Its premise is *the barrier is not the obstacle — the fear is*,
    /// and that premise requires the fear to be unfounded. Set the same story
    /// somewhere genuinely dangerous and the child's reluctance becomes correct,
    /// the encouragement becomes bad advice, and the book is teaching something
    /// nobody meant to teach. Nothing about the generated text would look wrong.
    case isHazardous
    /// Somewhere a child goes to sleep: a bedroom, a bed by a window.
    ///
    /// The place an uyku öncesi story opens and closes in (`NarrativeArc.bedtime`).
    /// Not an affordance any other story can use: a setting offering it is
    /// bound only for a bedtime-arc blueprint, and a bedtime-arc blueprint is
    /// bound only to such a setting (`OfflineContentBinder.bind`). Without that
    /// rule a forest adventure could open in a bedroom, and a bedtime story
    /// could end in a forest.
    case isRestingPlace
}

/// What sort of threshold a place offers.
///
/// `hasThreshold` says there is a boundary; this says what kind, and the prose
/// cannot be written without it — you pass *through* an opening, *across* a
/// span, and *into* a circle of others. A corpus that does not know which one
/// it has must write every crossing line abstractly, which is how a beat about
/// the most physical moment in the book ends up with no physical verb in it.
///
/// `social` is the one that shows the axis is not spatial: joining a group
/// already playing is a threshold in every sense the narrative model cares
/// about, and the beat validator makes no spatial assumption anywhere.
public enum ThresholdKind: String, Codable, Sendable, Hashable, CaseIterable {
    /// A gate, a gap in a wall, a doorway. Passed through.
    case opening
    /// A log, a bridge, a line of stones. Crossed over.
    case span
    /// A circle of others already underway. Joined.
    case social
}

/// What a companion *is capable of* — intrinsic, and true in every story.
///
/// Capabilities are what a blueprint **forbids**: an obliging dragon that can
/// carry the child across dissolves a crossing story, so Family II forbids
/// `canCarry` and the premise survives.
///
/// What a capability is *not* is a part in a story. That distinction is the
/// whole of D2, and getting it wrong was a real defect on both sides of this
/// merge: `isSmallAndVulnerable` was required by one blueprint ("someone who
/// cannot manage alone") and forbidden by another ("someone needing care pulls
/// attention away from thinking"), and both rationales were sound, because they
/// were about different things. A firefly is small in every story; it is the
/// one who needs help in only some of them. One vocabulary could not say that,
/// so a blueprint excluded a firefly for a reason that was not true of it there.
///
/// `isSmall` is therefore the physical fact and lives here; `needsCare` is the
/// part being played and lives in `CompanionRole`.
public enum CompanionTrait: String, Codable, Sendable, Hashable, CaseIterable {
    case hasLocalKnowledge, isLiteralMinded
    case canFly, canCarry, canSwim
    case isSmall, isStrong, isQuick
    case isPlayful, isPatient
}

/// A part a companion can credibly play.
///
/// Not `CharacterEngine.CastRole`, which answers a different question: that one
/// says *which slot in the cast* (protagonist, companion, supporting), this one
/// says *what the companion is being* within that slot. Both are casting; they
/// are not the same casting, and one type doing both jobs would be the very
/// conflation this delta exists to undo.
///
/// Declared by content as **eligibility** — "this one could be the knowledgeable
/// local, or the one who is scared too" — and consumed by a blueprint as
/// **casting**: *I cast the companion as `needsCare`*. The same firefly is a
/// guide in one blueprint and the care-recipient in another, which is what a
/// reusable content library is for, and what a single flat trait list made
/// impossible.
///
/// Distinct from a capability in one testable way: capabilities are true of the
/// record, cast roles are true of *this story*. So exactly one is resolved per
/// story and carried on the binding — a companion that arrives trembling on
/// page 3 and speaks steadily on page 6 is not two shades of the same
/// character, it is two characters.
public enum CompanionRole: String, Codable, Sendable, Hashable, CaseIterable {
    /// Knows the way, or knows this place. Leads.
    case guide
    /// Is the one in trouble. The child's help is what the story turns on.
    case needsCare
    /// Is frightened too, and comes anyway. Not a lesser `reassuring`: for a
    /// crossing story this is arguably the better children's-book part.
    case hesitant
    /// Is steady about the thing the child finds hard.
    case reassuring
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
    /// Can be looked at.
    ///
    /// The modality axis, and the one this engine got wrong before it existed:
    /// a light can be seen and a sound cannot, so a line that has the child
    /// *see* the discovery is only usable for some of them. It was worked
    /// around by writing every line modality-neutral, which costs the corpus
    /// its best sentences; declaring it lets a variant say "gördü" and be
    /// offered only when that is true.
    case isVisible
    /// Can be heard.
    ///
    /// The half of the modality axis that was missing, and the gap was invisible
    /// because `emitsSignal` reads as though it covers it. It does not: a
    /// flickering light and a faint sound both signal, and with only one
    /// modality declared, a line built on *hearing* had nothing to require and
    /// was offered to the light. The rendered story then opened on a sound and
    /// examined a light on the next page — two pages that each read perfectly
    /// and contradict each other.
    ///
    /// A half-built axis is worse than none: `isVisible` looks like modality is
    /// handled, so nobody checks the other direction.
    case isAudible
}

/// Where a piece of content belongs.
///
/// A separate axis from narrative traits, because it answers a different
/// question: not *what can this do for a story* but *could it plausibly be
/// here*. Without it nothing stops a squirrel on a coral reef or a seashell in
/// a snowy valley — which was the original content audit's complaint, and was
/// reproduced by the system that replaced it.
///
/// Reuses `ContentTag` rather than introducing a fourth vocabulary: the shipped
/// content already tags settings `forest`, `garden`, `sea`.
public typealias Habitat = ContentTag

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
    /// What sort of threshold the story needs — **one of** these.
    ///
    /// Empty means the blueprint does not care, which is the honest default for
    /// the nine families that are not about crossing anything.
    public let thresholdKind: Set<ThresholdKind>
    /// The part the companion is cast in — **one of** these, not all of them.
    ///
    /// Deliberately not a `TraitRequirement`. A story casts exactly one part, so
    /// a conjunction here would be unwriteable ("must play the guide *and* the
    /// one who needs care") and the type should not be able to say it. Empty
    /// means the blueprint does not care, and any part the companion can play
    /// will do.
    ///
    /// A choice of parts is the common case rather than the exception: a
    /// crossing story wants a companion who is *emotionally legible about the
    /// crossing*, which `hesitant` and `reassuring` both are. Requiring only the
    /// soothing one — as this engine's own threshold blueprint did — excludes
    /// the frightened companion who goes anyway, for no reason anybody would
    /// defend once it is written down.
    public let casting: Set<CompanionRole>

    public init(
        setting: TraitRequirement<SettingTrait> = [],
        companion: TraitRequirement<CompanionTrait> = [],
        discovery: TraitRequirement<DiscoveryTrait> = [],
        casting: Set<CompanionRole> = [],
        thresholdKind: Set<ThresholdKind> = []
    ) {
        self.setting = setting
        self.companion = companion
        self.discovery = discovery
        self.casting = casting
        self.thresholdKind = thresholdKind
    }

    public var isEmpty: Bool {
        setting.isEmpty && companion.isEmpty && discovery.isEmpty
            && casting.isEmpty && thresholdKind.isEmpty
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        setting = try container.decodeIfPresent(TraitRequirement<SettingTrait>.self, forKey: .setting) ?? []
        companion = try container.decodeIfPresent(TraitRequirement<CompanionTrait>.self, forKey: .companion) ?? []
        discovery = try container.decodeIfPresent(TraitRequirement<DiscoveryTrait>.self, forKey: .discovery) ?? []
        casting = try container.decodeIfPresent(Set<CompanionRole>.self, forKey: .casting) ?? []
        thresholdKind = try container.decodeIfPresent(Set<ThresholdKind>.self, forKey: .thresholdKind) ?? []
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
    /// Whether a piece of content could plausibly be where the story is set.
    ///
    /// Content declaring no habitat goes anywhere — that is the unmigrated case,
    /// and habitat is not the axis that should exclude it. Content that names
    /// its habitats must share one with the setting.
    public static func sharesHabitat(_ content: Set<Habitat>, setting: Set<Habitat>) -> Bool {
        content.isEmpty || setting.isEmpty || !content.isDisjoint(with: setting)
    }

    /// The parts this companion could play in *this* blueprint.
    ///
    /// Empty casting means the blueprint does not cast, so any part the
    /// companion declares is available. Otherwise it is the overlap — and an
    /// empty overlap is what makes the companion inadmissible, not a weaker
    /// choice.
    public static func castableRoles(
        offered: Set<CompanionRole>,
        casting: Set<CompanionRole>
    ) -> Set<CompanionRole> {
        casting.isEmpty ? offered : offered.intersection(casting)
    }

    /// Why this companion cannot be cast — or nil if it can.
    ///
    /// A companion declaring no parts is treated the way trait-less content is:
    /// it has made no claims, so nothing about it can be checked. That keeps an
    /// unmigrated record out of a cast rather than letting it through because
    /// nobody asked it anything.
    public static func castingRejection(
        offered: Set<CompanionRole>,
        casting: Set<CompanionRole>
    ) -> String? {
        guard !offered.isEmpty else { return "declares no castable role" }
        guard !casting.isEmpty else { return nil }
        guard castableRoles(offered: offered, casting: casting).isEmpty else { return nil }
        return "cannot be cast as "
            + casting.map(\.rawValue).sorted().joined(separator: " or ")
    }

    /// Why this place cannot host the crossing this story needs.
    ///
    /// A place offering no threshold at all is already rejected by
    /// `hasThreshold`; this is the finer question of whether it offers the
    /// *right* one, which is what the prose depends on.
    public static func thresholdRejection(
        offered: Set<ThresholdKind>,
        wanted: Set<ThresholdKind>
    ) -> String? {
        guard !wanted.isEmpty else { return nil }
        guard offered.isDisjoint(with: wanted) else { return nil }
        return "offers no "
            + wanted.map(\.rawValue).sorted().joined(separator: " or ")
            + " threshold"
    }

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
