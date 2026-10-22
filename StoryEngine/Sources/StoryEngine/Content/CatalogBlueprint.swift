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

/// What a continuation blueprint (FAZ 13) promises about the series it joins.
///
/// What it carries over is not declared, because it is not a choice: every
/// episode keeps the first story's place, companion, Masal ailem character and
/// keepsake, and finds something new. Only *which* series it may serve is.
public struct ContinuationSpec: Codable, Sendable, Hashable {
    /// The parent intents whose series this episode can belong to. The tone
    /// comes from here, not from `storyModes`: a continuation is chosen for the
    /// mode its first story was written in.
    public let modes: [StoryMode]
    /// The episode numbers it may fill (2…5). Empty in the file means all.
    public let episodes: [Int]

    public static let allEpisodes = Array(2...5)

    public init(modes: [StoryMode], episodes: [Int] = ContinuationSpec.allEpisodes) {
        self.modes = modes
        self.episodes = episodes
    }

    private enum CodingKeys: String, CodingKey { case modes, episodes }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        modes = try container.decodeIfPresent([StoryMode].self, forKey: .modes) ?? []
        let declared = try container.decodeIfPresent([Int].self, forKey: .episodes) ?? []
        episodes = declared.isEmpty ? Self.allEpisodes : declared
    }

    public func serves(mode: StoryMode, episode: Int) -> Bool {
        modes.contains(mode) && episodes.contains(episode)
    }
}

/// A declared refrain (book research `p_repeated_line`, approved 14 October 2026).
///
/// A line the listener can join, said on fixed pages, and changed once on its
/// last use. It is the only repetition a book may carry on purpose: accidental
/// repetition is still a defect. Slot-free, so it cannot break vowel harmony
/// and cannot be welded to content the blueprint does not bind.
///
/// Experimental: no shipped blueprint carries one. Refrain siblings live in an
/// experiment file and reach children only through a published package.
public struct RefrainSpec: Codable, Sendable, Hashable {
    /// The repeated line, ending in its own punctuation.
    public let line: String
    /// Pages that end with `line`, in reading order. At least two: a line said
    /// once is not a refrain.
    public let pages: [Int]
    /// The changed last use, and the page it closes.
    public let finalLine: String
    public let finalPage: Int

    /// Longest line a refrain may be, in words. A refrain is short enough to
    /// join after hearing it once; the page budget allows this much on top.
    public static let maxWords = 6

    public init(line: String, pages: [Int], finalLine: String, finalPage: Int) {
        self.line = line
        self.pages = pages
        self.finalLine = finalLine
        self.finalPage = finalPage
    }

    /// The refrain sentence a page ends with, if it carries one.
    public func text(onPage page: Int) -> String? {
        if page == finalPage { return finalLine }
        return pages.contains(page) ? line : nil
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
    /// Interest words (FAZ 12) the story itself is about, independent of the
    /// content bound into it. Most blueprints are structural and carry none.
    public let interests: [InterestTag]
    /// Safety topics (FAZ 17) the story itself is about, whatever is bound
    /// into it. A parent who avoids one never gets this blueprint.
    public let topics: [SafetyTopic]
    /// Where this blueprint may stand in a series (FAZ 13). Nil for every
    /// standalone story. A continuation blueprint lives in
    /// `ContentCatalog.series`, never in `blueprints`, so nothing that picks a
    /// standalone story can see it.
    public let continuation: ContinuationSpec?
    /// What every child's reading says of this blueprint (FAZ 14 madde 4): a
    /// multiplier on its selection weight, published by the server from
    /// `BlueprintOutcome` rows. 1 — the default, and every shipped blueprint
    /// today — changes nothing.
    public let aggregateWeight: Double
    /// A declared refrain (experimental). Nil for every shipped blueprint.
    public let refrain: RefrainSpec?
    /// The contour this blueprint is written in (`NarrativeArc`). `standard`
    /// for every blueprint that does not say, which is every one written
    /// before 21 October 2026. A mode admits a blueprint by family **and** arc.
    public let arc: NarrativeArc

    private enum CodingKeys: String, CodingKey {
        case id, genre, theme, ageRange, pageCount, pageRoles, pages, titlePatterns, family
        case premise, editorialName, editorialGuidance, requires, forbids, interests, topics
        case continuation, aggregateWeight, refrain, arc
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
        interests = try container.decodeIfPresent([InterestTag].self, forKey: .interests) ?? []
        topics = try container.decodeIfPresent([SafetyTopic].self, forKey: .topics) ?? []
        continuation = try container.decodeIfPresent(ContinuationSpec.self, forKey: .continuation)
        aggregateWeight = try container.decodeIfPresent(Double.self, forKey: .aggregateWeight) ?? 1
        refrain = try container.decodeIfPresent(RefrainSpec.self, forKey: .refrain)
        arc = try container.decodeIfPresent(NarrativeArc.self, forKey: .arc) ?? .standard
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
        if !interests.isEmpty { try container.encode(interests, forKey: .interests) }
        if !topics.isEmpty { try container.encode(topics, forKey: .topics) }
        try container.encodeIfPresent(continuation, forKey: .continuation)
        if aggregateWeight != 1 { try container.encode(aggregateWeight, forKey: .aggregateWeight) }
        try container.encodeIfPresent(refrain, forKey: .refrain)
        if arc != .standard { try container.encode(arc, forKey: .arc) }
    }

    /// Bu blueprint'in olay örgüsü mekanizması: `editorialName`'in sağ yarısı.
    ///
    /// "III-2 - advocacy" → "advocacy". Ad kuralı içerikte tutarlı
    /// ("<aile numarası> - <mekanizma>"); ayıraç yoksa adın tamamı mekanizma
    /// sayılır, çünkü yanlış ayrıştırmaktansa kaba saymak iyidir — eksik sayım
    /// çeşitliliği olduğundan AZ gösterir, ki güvenli yön o.
    ///
    /// Varyasyonun asıl ölçütü bu, blueprint sayısı değil: aynı mekanizmanın
    /// iki blueprint'i çocuğa iki masal değil, bir masalın iki çekimi gibi
    /// gelir. Hem ölçüm (`VariationReport`) hem konu kapısı
    /// (`BlueprintSelector.availableTopics`) buradan okuyor; iki kopya tanım
    /// bu projenin tekrar tekrar bulduğu kusur.
    public var mechanism: String? {
        guard let editorialName, !editorialName.isEmpty else { return nil }
        guard let dash = editorialName.range(of: " - ") else { return editorialName }
        return String(editorialName[dash.upperBound...]).trimmingCharacters(in: .whitespaces)
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
        // Each axis is sorted: these come out of `Set.intersection`, whose
        // iteration order is seeded per process, so the integrity report named
        // the same contradictions in a different order on every run. The axes
        // stay in their own fixed order — setting, companion, discovery — so the
        // message still reads in the order an author thinks about them.
        requires.setting.mentioned.intersection(forbids.setting).map(\.rawValue).sorted()
            + requires.companion.mentioned.intersection(forbids.companion).map(\.rawValue).sorted()
            + requires.discovery.mentioned.intersection(forbids.discovery).map(\.rawValue).sorted()
    }
}
