import Foundation

/// One page's slot in a blueprint: which beat it is, and (later) what state it
/// needs and sets.
/// One page of a blueprint: what it is for, what happens on it, how it feels.
///
/// Note what is **absent**: any `requiredState` or `stateChanges`. State is a
/// pure function of the beat sequence. Authors previously wrote requirements and
/// productions independently, so nothing forced them to meet — 15 authored
/// conditions with 8 that nothing produced. Deriving state instead makes an
/// unreachable precondition unrepresentable rather than undetected.
public struct BlueprintPageSlot: Codable, Sendable, Hashable {
    public let pageNumber: Int
    public let role: PageRole
    /// What happens. Optional only so the current pre-beat catalog still loads.
    public let beat: StoryBeat?
    public let supportingBeat: StoryBeat?
    public let emotion: EmotionalState?

    private enum CodingKeys: String, CodingKey {
        case pageNumber, role, beat, supportingBeat, emotion
    }

    public init(
        pageNumber: Int,
        role: PageRole,
        beat: StoryBeat? = nil,
        supportingBeat: StoryBeat? = nil,
        emotion: EmotionalState? = nil
    ) {
        self.pageNumber = pageNumber
        self.role = role
        self.beat = beat
        self.supportingBeat = supportingBeat
        self.emotion = emotion
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pageNumber = try container.decode(Int.self, forKey: .pageNumber)
        role = try container.decode(PageRole.self, forKey: .role)
        beat = try container.decodeIfPresent(StoryBeat.self, forKey: .beat)
        supportingBeat = try container.decodeIfPresent(StoryBeat.self, forKey: .supportingBeat)
        emotion = try container.decodeIfPresent(EmotionalState.self, forKey: .emotion)
    }

    /// This slot as the validator consumes it, when it has a beat.
    public var beatSlot: BeatSlot? {
        guard let beat else { return nil }
        return BeatSlot(pageNumber: pageNumber, role: role, beat: beat,
                        supportingBeat: supportingBeat, emotion: emotion)
    }
}

/// A reusable narrative skeleton — *not* a story.
///
/// It says what shape a book has: which beats, in what order, for whom. It says
/// nothing about a specific forest, fox or light. That is what makes one
/// blueprint able to produce many different stories.
public struct CatalogBlueprint: Codable, Sendable, Hashable, Identifiable {
    public let id: ContentID
    public let genre: String
    public let theme: String
    public let ageRange: AgeBand
    public let pageCount: Int
    public let pagePlan: [BlueprintPageSlot]
    /// Which narrative family this belongs to. Optional only for the pre-beat
    /// catalog; the diversity gate reads it.
    public let family: NarrativeFamily?
    /// Title patterns, e.g. `"{{child.name}} ve {{setting.name}}'ndeki Sır"`.
    /// Absent from the shipped catalog; titles are currently hard-coded in the
    /// prototype, which is what this replaces.
    public let titlePatterns: [String]

    /// One line saying what shape this story is, in semantic terms and without
    /// nouns. *"The child wants to reach something on the other side of a
    /// boundary, and the boundary is not the obstacle."* Never shown to anyone.
    public let premise: String?
    /// An internal handle for humans. Never rendered.
    public let editorialName: String?
    /// At most two sentences of direction for a human author. The only free
    /// text a blueprint carries, and deliberately not content: *"page 5 is an
    /// attempt that partly works"* is guidance; *"Yeliz stepped onto the log"*
    /// is a story.
    public let editorialGuidance: String?
    /// Traits the content bound to this blueprint must offer.
    public let requires: ContentRequirements
    /// Traits it must not offer. §8.3 — this is where identity lives.
    public let forbids: ContentExclusions

    private enum CodingKeys: String, CodingKey {
        case id, genre, theme, ageRange, pageCount, pageRoles, pages, titlePatterns, family
        case premise, editorialName, editorialGuidance, requires, forbids
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ContentID.self, forKey: .id)
        genre = try container.decode(String.self, forKey: .genre)
        theme = try container.decode(String.self, forKey: .theme)
        ageRange = try container.decode(AgeBand.self, forKey: .ageRange)
        pageCount = try container.decode(Int.self, forKey: .pageCount)
        // `pages` is the beat-bearing form; `pageRoles` is the pre-beat one.
        pagePlan = try container.decodeIfPresent([BlueprintPageSlot].self, forKey: .pages)
            ?? container.decodeIfPresent([BlueprintPageSlot].self, forKey: .pageRoles)
            ?? []
        family = try container.decodeIfPresent(NarrativeFamily.self, forKey: .family)
        titlePatterns = try container.decodeIfPresent([String].self, forKey: .titlePatterns) ?? []
        premise = try container.decodeIfPresent(String.self, forKey: .premise)
        editorialName = try container.decodeIfPresent(String.self, forKey: .editorialName)
        editorialGuidance = try container.decodeIfPresent(String.self, forKey: .editorialGuidance)
        requires = try container.decodeIfPresent(ContentRequirements.self, forKey: .requires)
            ?? ContentRequirements()
        forbids = try container.decodeIfPresent(ContentExclusions.self, forKey: .forbids)
            ?? ContentExclusions()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(genre, forKey: .genre)
        try container.encode(theme, forKey: .theme)
        try container.encode(ageRange, forKey: .ageRange)
        try container.encode(pageCount, forKey: .pageCount)
        try container.encode(pagePlan, forKey: .pages)
        try container.encodeIfPresent(family, forKey: .family)
        try container.encode(titlePatterns, forKey: .titlePatterns)
        try container.encodeIfPresent(premise, forKey: .premise)
        try container.encodeIfPresent(editorialName, forKey: .editorialName)
        try container.encodeIfPresent(editorialGuidance, forKey: .editorialGuidance)
        if !requires.isEmpty { try container.encode(requires, forKey: .requires) }
        if !forbids.isEmpty { try container.encode(forbids, forKey: .forbids) }
    }

    /// The roles this blueprint asks for, in page order.
    public var roleSequence: [PageRole] {
        pagePlan.sorted { $0.pageNumber < $1.pageNumber }.map(\.role)
    }

    /// The beat sequence, when this blueprint has been authored against the
    /// beat vocabulary.
    public var beatSlots: [BeatSlot] {
        pagePlan.sorted { $0.pageNumber < $1.pageNumber }.compactMap(\.beatSlot)
    }

    /// Whether every page declares a beat — the condition for being selectable
    /// and for being checked against the state rule.
    public var isBeatAuthored: Bool {
        !pagePlan.isEmpty && pagePlan.allSatisfy { $0.beat != nil }
    }

    /// A blueprint that requires and forbids the same trait can never be
    /// satisfied by anything. Cheap to write by accident, impossible to notice
    /// at runtime — the pool is simply always empty.
    public var contradictoryTraits: [String] {
        // `mentioned` covers the choice groups too: forbidding one arm of a
        // disjunction is legitimate, forbidding every arm is not, and both are
        // worth surfacing to the author.
        Array(requires.setting.mentioned.intersection(forbids.setting).map(\.rawValue))
            + requires.companion.mentioned.intersection(forbids.companion).map(\.rawValue)
            + requires.discovery.mentioned.intersection(forbids.discovery).map(\.rawValue)
    }
}
