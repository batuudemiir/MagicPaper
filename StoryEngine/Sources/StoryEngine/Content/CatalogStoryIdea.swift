import Foundation

/// What the child is offered: a story idea.
///
/// The product decision behind this type is that the user should not *build* a
/// story. The old flow asked for a type, a direction, a world, a companion, a
/// length and a tone — six decisions that made the engine's job harder and the
/// parent's job a configuration form. A story idea replaces the first four with
/// one choice, and the engine derives the rest.
///
/// What makes it more than marketing copy is that it is expressed in the same
/// vocabulary blueprints already use. An idea narrows the content the engine may
/// bind and says which narrative families it leans toward; it never names a
/// blueprint, a setting or an object. That is the difference between a promise
/// and a preset: *"follow the traces"* can become an Absence story about a lost
/// shell or a Misreading story about footprints that were never what they looked
/// like, and both keep the promise.
public struct CatalogStoryIdea: Decodable, Sendable, Hashable, Identifiable {

    public let id: ContentID

    // MARK: Presentation

    /// The line on the card. Authored here rather than in a Swift view so the
    /// set can change without a release, and so an id — not a Turkish string —
    /// is what travels into the engine and into analytics.
    public let display: String
    /// One short supporting sentence.
    public let supportingText: String
    /// Symbol or asset name for the card.
    public let illustration: String

    // MARK: Constraints

    public let ageRange: AgeBand

    /// Narrows what the engine may bind, in the blueprint's own vocabulary.
    ///
    /// Intersected with the blueprint's requirements rather than replacing them,
    /// so an idea can only ever make selection *more* specific. An idea that
    /// says nothing about settings leaves settings entirely to the blueprint.
    public let requires: ContentRequirements
    public let forbids: ContentExclusions

    /// Families this idea leans toward.
    ///
    /// Affinity, not a pin. A story idea bound to one blueprint is a preset
    /// wearing a different name, and the whole point is that the same card can
    /// produce genuinely different stories. The selector prefers these and falls
    /// outside them only when nothing preferred can be built — an unkept promise
    /// is better than no story, but only just, and it is recorded either way.
    public let preferredFamilies: [NarrativeFamily]

    public let weights: SelectionWeights

    private enum CodingKeys: String, CodingKey {
        case id, display, supportingText, illustration, ageRange
        case requires, forbids, preferredFamilies
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ContentID.self, forKey: .id)
        display = try container.decode(String.self, forKey: .display)
        supportingText = try container.decodeIfPresent(String.self, forKey: .supportingText) ?? ""
        illustration = try container.decodeIfPresent(String.self, forKey: .illustration) ?? "sparkles"
        ageRange = try container.decodeIfPresent(AgeBand.self, forKey: .ageRange)
            ?? AgeBand(lowerBound: 5, upperBound: 6)
        requires = try container.decodeIfPresent(ContentRequirements.self, forKey: .requires)
            ?? ContentRequirements()
        forbids = try container.decodeIfPresent(ContentExclusions.self, forKey: .forbids)
            ?? ContentExclusions()
        preferredFamilies = try container.decodeIfPresent([NarrativeFamily].self, forKey: .preferredFamilies) ?? []
        weights = try SelectionWeights(from: decoder)
    }

    public init(
        id: ContentID,
        display: String,
        supportingText: String = "",
        illustration: String = "sparkles",
        ageRange: AgeBand = AgeBand(lowerBound: 5, upperBound: 6),
        requires: ContentRequirements = ContentRequirements(),
        forbids: ContentExclusions = ContentExclusions(),
        preferredFamilies: [NarrativeFamily] = [],
        weights: SelectionWeights = .neutral
    ) {
        self.id = id
        self.display = display
        self.supportingText = supportingText
        self.illustration = illustration
        self.ageRange = ageRange
        self.requires = requires
        self.forbids = forbids
        self.preferredFamilies = preferredFamilies
        self.weights = weights
    }

    /// Whether this idea is offered to a child of this age.
    public func suits(age: Int) -> Bool { ageRange.contains(age) }
}

// MARK: - Combining an idea with a blueprint

extension ContentRequirements {
    /// Both sets of requirements at once.
    ///
    /// Conjunction, deliberately: an idea narrows, it never relaxes. Hard
    /// requirements union; choice groups are kept side by side, because each
    /// group must still be satisfied on its own — pooling them into one group
    /// would let a blueprint's choice be answered by an idea's alternative,
    /// which is not what either author wrote.
    public func combined(with other: ContentRequirements) -> ContentRequirements {
        ContentRequirements(
            setting: setting.combined(with: other.setting),
            companion: companion.combined(with: other.companion),
            discovery: discovery.combined(with: other.discovery)
        )
    }
}

extension ContentExclusions {
    /// Everything either side forbids.
    public func combined(with other: ContentExclusions) -> ContentExclusions {
        ContentExclusions(
            setting: setting.union(other.setting),
            companion: companion.union(other.companion),
            discovery: discovery.union(other.discovery)
        )
    }
}

extension TraitRequirement {
    public func combined(with other: TraitRequirement<Trait>) -> TraitRequirement<Trait> {
        TraitRequirement(allOf: allOf.union(other.allOf), anyOf: anyOf + other.anyOf)
    }
}
