import Foundation

/// A place the story happens in. User-facing: this is a "Nereye gidelim?" card.
public struct CatalogSetting: Codable, Sendable, Hashable, Identifiable {
    public let id: ContentID
    public let name: String
    public let description: String
    public let visualKeywords: [String]
    public let compatibleGenres: [String]
    public let compatibleThemes: [String]
    /// What this setting *is*, for other records to match against.
    public let tags: [ContentTag]
    /// What this setting *affords*, for blueprints to match against (§8.1).
    ///
    /// Distinct from `tags`: a tag says a place is a forest, a trait says it
    /// has a threshold to cross. A blueprint never asks for a forest.
    public let traits: Set<SettingTrait>
    /// What sort of boundary this place has, when it has one.
    ///
    /// Held separately from `traits` because it is not a yes/no affordance but
    /// a choice among kinds, and because the renderer needs it: a line about
    /// stepping onto a log is wrong at a gate and right at a stream.
    public let thresholdKinds: Set<ThresholdKind>
    /// Turkish grammar the renderer cannot infer from spelling.
    ///
    /// `hasPossessiveEnding` is the one that genuinely cannot be guessed:
    /// "Karlı Vadi" and "Ay Yüzeyi" both end in -i and inflect differently
    /// ("Karlı Vadi'de" but "Ay Yüzeyi'nde"). Authoring it here is why the
    /// shipped corpus contains both correct and incorrect `'nde` spellings —
    /// the author generalised from the subset that happened to be right.
    /// Where this belongs. Empty means anywhere.
    public let habitat: Set<Habitat>
    public let isProperNoun: Bool
    public let hasPossessiveEnding: Bool
    public let blocksSoftening: Bool
    public let weights: SelectionWeights

    private enum CodingKeys: String, CodingKey {
        case id, name, description, visualKeywords, compatibleGenres, compatibleThemes, tags
        case traits, thresholdKinds
    , habitat, isProperNoun, hasPossessiveEnding, blocksSoftening}

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ContentID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        visualKeywords = try container.decodeIfPresent([String].self, forKey: .visualKeywords) ?? []
        compatibleGenres = try container.decodeIfPresent([String].self, forKey: .compatibleGenres) ?? []
        compatibleThemes = try container.decodeIfPresent([String].self, forKey: .compatibleThemes) ?? []
        tags = try container.decodeIfPresent([ContentTag].self, forKey: .tags) ?? []
        traits = try container.decodeIfPresent(Set<SettingTrait>.self, forKey: .traits) ?? []
        thresholdKinds = try container.decodeIfPresent(Set<ThresholdKind>.self, forKey: .thresholdKinds) ?? []
        habitat = try container.decodeIfPresent(Set<Habitat>.self, forKey: .habitat) ?? []
        isProperNoun = try container.decodeIfPresent(Bool.self, forKey: .isProperNoun) ?? true
        hasPossessiveEnding = try container.decodeIfPresent(Bool.self, forKey: .hasPossessiveEnding) ?? false
        blocksSoftening = try container.decodeIfPresent(Bool.self, forKey: .blocksSoftening) ?? false
        weights = try SelectionWeights(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(visualKeywords, forKey: .visualKeywords)
        try container.encode(compatibleGenres, forKey: .compatibleGenres)
        try container.encode(compatibleThemes, forKey: .compatibleThemes)
        try container.encode(tags, forKey: .tags)
        if !traits.isEmpty { try container.encode(traits, forKey: .traits) }
        if !thresholdKinds.isEmpty { try container.encode(thresholdKinds, forKey: .thresholdKinds) }
        if !habitat.isEmpty { try container.encode(habitat, forKey: .habitat) }
        try container.encode(isProperNoun, forKey: .isProperNoun)
        try container.encode(hasPossessiveEnding, forKey: .hasPossessiveEnding)
        try container.encode(blocksSoftening, forKey: .blocksSoftening)
        try weights.encode(to: encoder)
    }
}

/// Someone who comes along. User-facing: "Yanımızda kim olsun?"
public struct CatalogCompanion: Codable, Sendable, Hashable, Identifiable {
    public let id: ContentID
    public let name: String
    public let type: String
    public let personality: String
    public let description: String
    public let visualDescription: String
    /// Setting **tags** this companion belongs with — not setting ids.
    public let compatibleSettingTags: [ContentTag]
    public let compatibleThemes: [String]
    public let tags: [ContentTag]
    /// What this companion can do, intrinsically (§8.1).
    ///
    /// This is what was missing when fifteen well-drawn personalities were
    /// being selected interchangeably: nothing could express why a timid
    /// rabbit and a wise owl are not the same choice.
    public let traits: Set<CompanionTrait>
    /// The parts this companion could credibly play.
    ///
    /// Eligibility, not assignment: a hedgehog that can be `hesitant`,
    /// `reassuring` *or* `needsCare` is not three characters — it is one
    /// character a blueprint can cast three ways. Which part it actually plays
    /// is resolved per story and lives on the binding, never here.
    public let castRoles: Set<CompanionRole>
    /// Turkish grammar the renderer cannot infer from spelling.
    ///
    /// `hasPossessiveEnding` is the one that genuinely cannot be guessed:
    /// "Karlı Vadi" and "Ay Yüzeyi" both end in -i and inflect differently
    /// ("Karlı Vadi'de" but "Ay Yüzeyi'nde"). Authoring it here is why the
    /// shipped corpus contains both correct and incorrect `'nde` spellings —
    /// the author generalised from the subset that happened to be right.
    /// Where this belongs. Empty means anywhere.
    public let habitat: Set<Habitat>
    public let isProperNoun: Bool
    public let hasPossessiveEnding: Bool
    public let blocksSoftening: Bool
    public let weights: SelectionWeights

    private enum CodingKeys: String, CodingKey {
        case id, name, type, personality, description, visualDescription
        case compatibleSettings, compatibleThemes, tags
        case traits, castRoles
    , habitat, isProperNoun, hasPossessiveEnding, blocksSoftening}

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ContentID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        personality = try container.decodeIfPresent(String.self, forKey: .personality) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        visualDescription = try container.decodeIfPresent(String.self, forKey: .visualDescription) ?? ""
        compatibleSettingTags = try container.decodeIfPresent([ContentTag].self, forKey: .compatibleSettings) ?? []
        compatibleThemes = try container.decodeIfPresent([String].self, forKey: .compatibleThemes) ?? []
        tags = try container.decodeIfPresent([ContentTag].self, forKey: .tags) ?? []
        traits = try container.decodeIfPresent(Set<CompanionTrait>.self, forKey: .traits) ?? []
        castRoles = try container.decodeIfPresent(Set<CompanionRole>.self, forKey: .castRoles) ?? []
        habitat = try container.decodeIfPresent(Set<Habitat>.self, forKey: .habitat) ?? []
        isProperNoun = try container.decodeIfPresent(Bool.self, forKey: .isProperNoun) ?? true
        hasPossessiveEnding = try container.decodeIfPresent(Bool.self, forKey: .hasPossessiveEnding) ?? false
        blocksSoftening = try container.decodeIfPresent(Bool.self, forKey: .blocksSoftening) ?? false
        weights = try SelectionWeights(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(personality, forKey: .personality)
        try container.encode(description, forKey: .description)
        try container.encode(visualDescription, forKey: .visualDescription)
        try container.encode(compatibleSettingTags, forKey: .compatibleSettings)
        try container.encode(compatibleThemes, forKey: .compatibleThemes)
        try container.encode(tags, forKey: .tags)
        if !traits.isEmpty { try container.encode(traits, forKey: .traits) }
        if !castRoles.isEmpty { try container.encode(castRoles, forKey: .castRoles) }
        if !habitat.isEmpty { try container.encode(habitat, forKey: .habitat) }
        try container.encode(isProperNoun, forKey: .isProperNoun)
        try container.encode(hasPossessiveEnding, forKey: .hasPossessiveEnding)
        try container.encode(blocksSoftening, forKey: .blocksSoftening)
        try weights.encode(to: encoder)
    }
}

/// A thing that can be found. User-facing as the "secret / discovery" card.
public struct CatalogObject: Codable, Sendable, Hashable, Identifiable {
    public let id: ContentID
    public let name: String
    public let description: String
    public let compatibleThemes: [String]
    public let tags: [ContentTag]
    /// What finding this *implies* (§8.1) — the structural half of the child's
    /// most invested choice, and what lets it select a narrative family.
    public let traits: Set<DiscoveryTrait>
    /// Setting traits that would make this thing unremarkable.
    ///
    /// The reverse of every other constraint in this file: content ruling out a
    /// *place*, rather than a place ruling out content. It has to run this way
    /// because the failure is one of meaning, not plausibility — a flickering
    /// light beside water is perfectly plausible and completely uninteresting,
    /// because the water already explains it. Habitat cannot catch that; it
    /// asks whether the thing could be here, and the answer is yes.
    ///
    /// A discovery the setting explains is not a discovery, and the first four
    /// pages of the book are then about nothing.
    public let explainedBy: Set<SettingTrait>
    /// The same thing, named for a title.
    ///
    /// "titrek bir ışık" is right in a sentence and wrong on a cover: a title
    /// does not carry an indefinite article. One field cannot serve both
    /// registers, and using the prose name produced "Yeliz ve Kayıp yırtık bir
    /// harita". Falls back to `name` when unset.
    public let titleName: String
    /// Turkish grammar the renderer cannot infer from spelling.
    ///
    /// `hasPossessiveEnding` is the one that genuinely cannot be guessed:
    /// "Karlı Vadi" and "Ay Yüzeyi" both end in -i and inflect differently
    /// ("Karlı Vadi'de" but "Ay Yüzeyi'nde"). Authoring it here is why the
    /// shipped corpus contains both correct and incorrect `'nde` spellings —
    /// the author generalised from the subset that happened to be right.
    /// Where this belongs. Empty means anywhere.
    public let habitat: Set<Habitat>
    public let isProperNoun: Bool
    public let hasPossessiveEnding: Bool
    public let blocksSoftening: Bool
    public let weights: SelectionWeights

    private enum CodingKeys: String, CodingKey { case id, name, titleName, description, compatibleThemes, tags, traits, explainedBy, habitat, isProperNoun, hasPossessiveEnding, blocksSoftening }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ContentID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        compatibleThemes = try container.decodeIfPresent([String].self, forKey: .compatibleThemes) ?? []
        tags = try container.decodeIfPresent([ContentTag].self, forKey: .tags) ?? []
        traits = try container.decodeIfPresent(Set<DiscoveryTrait>.self, forKey: .traits) ?? []
        explainedBy = try container.decodeIfPresent(Set<SettingTrait>.self, forKey: .explainedBy) ?? []
        titleName = try container.decodeIfPresent(String.self, forKey: .titleName) ?? name
        habitat = try container.decodeIfPresent(Set<Habitat>.self, forKey: .habitat) ?? []
        isProperNoun = try container.decodeIfPresent(Bool.self, forKey: .isProperNoun) ?? false
        hasPossessiveEnding = try container.decodeIfPresent(Bool.self, forKey: .hasPossessiveEnding) ?? false
        blocksSoftening = try container.decodeIfPresent(Bool.self, forKey: .blocksSoftening) ?? false
        weights = try SelectionWeights(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(compatibleThemes, forKey: .compatibleThemes)
        try container.encode(tags, forKey: .tags)
        if !traits.isEmpty { try container.encode(traits, forKey: .traits) }
        if !explainedBy.isEmpty { try container.encode(explainedBy, forKey: .explainedBy) }
        try container.encode(titleName, forKey: .titleName)
        if !habitat.isEmpty { try container.encode(habitat, forKey: .habitat) }
        try container.encode(isProperNoun, forKey: .isProperNoun)
        try container.encode(hasPossessiveEnding, forKey: .hasPossessiveEnding)
        try container.encode(blocksSoftening, forKey: .blocksSoftening)
        try weights.encode(to: encoder)
    }
}

/// Something that happens. Engine-selected; never shown as a choice.
public struct CatalogEvent: Codable, Sendable, Hashable, Identifiable {
    public let id: ContentID
    public let type: String
    public let description: String
    public let compatibleSettingTags: [ContentTag]
    public let compatibleThemes: [String]
    public let requiredState: [StateFact]
    public let stateChanges: [StateFact]

    private enum CodingKeys: String, CodingKey {
        case id, type, description, compatibleSettings, compatibleThemes, requiredState, stateChanges
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ContentID.self, forKey: .id)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        compatibleSettingTags = try container.decodeIfPresent([ContentTag].self, forKey: .compatibleSettings) ?? []
        compatibleThemes = try container.decodeIfPresent([String].self, forKey: .compatibleThemes) ?? []
        requiredState = try container.decodeIfPresent([StateFact].self, forKey: .requiredState) ?? []
        stateChanges = try container.decodeIfPresent([StateFact].self, forKey: .stateChanges) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(description, forKey: .description)
        try container.encode(compatibleSettingTags, forKey: .compatibleSettings)
        try container.encode(compatibleThemes, forKey: .compatibleThemes)
        try container.encode(requiredState, forKey: .requiredState)
        try container.encode(stateChanges, forKey: .stateChanges)
    }
}

/// A difficulty to work through. Engine-selected.
public struct CatalogChallenge: Codable, Sendable, Hashable, Identifiable {
    public let id: ContentID
    public let description: String
    public let compatibleThemes: [String]
    public let compatibleSettingTags: [ContentTag]
    public let stateRequirements: [StateFact]
    public let stateChanges: [StateFact]

    private enum CodingKeys: String, CodingKey {
        case id, description, compatibleThemes, compatibleSettings, stateRequirements, stateChanges
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ContentID.self, forKey: .id)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        compatibleThemes = try container.decodeIfPresent([String].self, forKey: .compatibleThemes) ?? []
        compatibleSettingTags = try container.decodeIfPresent([ContentTag].self, forKey: .compatibleSettings) ?? []
        stateRequirements = try container.decodeIfPresent([StateFact].self, forKey: .stateRequirements) ?? []
        stateChanges = try container.decodeIfPresent([StateFact].self, forKey: .stateChanges) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(description, forKey: .description)
        try container.encode(compatibleThemes, forKey: .compatibleThemes)
        try container.encode(compatibleSettingTags, forKey: .compatibleSettings)
        try container.encode(stateRequirements, forKey: .stateRequirements)
        try container.encode(stateChanges, forKey: .stateChanges)
    }
}

/// How a story lands emotionally. Engine-selected.
public struct CatalogEnding: Codable, Sendable, Hashable, Identifiable {
    public let id: ContentID
    public let type: String
    public let description: String
    public let compatibleThemes: [String]

    private enum CodingKeys: String, CodingKey { case id, type, description, compatibleThemes }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ContentID.self, forKey: .id)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        compatibleThemes = try container.decodeIfPresent([String].self, forKey: .compatibleThemes) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(description, forKey: .description)
        try container.encode(compatibleThemes, forKey: .compatibleThemes)
    }
}
