import Foundation

/// A placeholder a variant needs filled, e.g. `child.name`, `setting.name`.
public struct ContentSlot: Hashable, Codable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }
    public var description: String { rawValue }

    /// The `{{token}}` form as it appears in text.
    public var token: String { "{{\(rawValue)}}" }

    public init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    /// Every `{{…}}` token actually present in a piece of text.
    public static func tokens(in text: String) -> [ContentSlot] {
        guard let regex = try? NSRegularExpression(pattern: "\\{\\{([^}]+)\\}\\}") else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var found: [ContentSlot] = []
        var seen: Set<String> = []
        regex.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match, match.numberOfRanges > 1,
                  let inner = Range(match.range(at: 1), in: text) else { return }
            let name = String(text[inner]).trimmingCharacters(in: .whitespaces)
            if seen.insert(name).inserted { found.append(ContentSlot(name)) }
        }
        return found
    }
}

/// One phrasing of a page role. Several per role is what stops every story
/// sounding the same.
public struct CatalogVariant: Codable, Sendable, Hashable, Identifiable {
    public let id: ContentID
    public let text: String
    public let visualScene: String
    /// Slots the author declared. Checked against the text at load: a mismatch
    /// means either an unfilled placeholder at runtime or a stale declaration.
    public let requiredSlots: [ContentSlot]
    public let stateRequirements: [StateFact]
    public let stateChanges: [StateFact]

    // MARK: Selection metadata (v3 corpus)

    /// Whether this line is a whole page or half of one.
    ///
    /// A beat that shares its page with a supporting beat needs a short line;
    /// a beat that has the page to itself needs a full one. Composing without
    /// this produced pages of wildly uneven length and, on page 4, two
    /// sentences that both opened with "Ama".
    public let lengthClass: VariantLengthClass?

    /// A short name for what this variant *does*, narratively.
    ///
    /// `sound_before_sight`, `body_notices_first`, `not_my_footprints`. Two
    /// variants sharing a move are interchangeable; different moves are
    /// genuinely different. This is the key a diversity gate needs, and without
    /// it "three variants" can mean three phrasings of one idea.
    public let move: String?

    /// Beats this line reads well after.
    ///
    /// A soft preference, not a requirement: a closing line that refers to what
    /// was just overcome only works after the beat that overcame it. An unknown
    /// beat here simply never matches.
    public let afterBeat: [StoryBeat]

    /// Content this variant assumes. Finer than the blueprint's requirements,
    /// which bind the whole story: a line about weather uncovering something
    /// needs a setting with weather even when the blueprint does not.
    public let settingTraits: Set<SettingTrait>
    public let discoveryTraits: Set<DiscoveryTrait>
    /// Capabilities the line takes for granted.
    ///
    /// `arrives_from_above` needs `canFly`. Declaring that is strictly better
    /// than the workaround this engine reached for, which was to delete flight
    /// from the prose so every line would be safe for every companion: that
    /// keeps the corpus usable at the cost of its best sentences.
    public let capabilityRequire: Set<CompanionTrait>
    /// Capabilities that would make the line false or silly.
    public let capabilityForbid: Set<CompanionTrait>
    /// Parts this line is written for.
    ///
    /// A companion cast as `needsCare` cannot stride in offering help, and one
    /// cast as `guide` cannot be trembling. Empty means the line works whoever
    /// the companion is being.
    public let castRoles: Set<CompanionRole>
    /// How certain the line sounds, where that is load-bearing.
    public let register: VariantRegister?

    /// Which conflict mechanisms this line is the right *shape* for.
    ///
    /// An obstacle that stands in the way is wrong for a conflict made of time,
    /// where nothing blocks the child and the difficulty is that it is not
    /// finished yet. Excluding `duration` from the general obstacles was the
    /// correct editorial call; not writing the duration-shaped ones it implied
    /// is what turned the exclusion into a pool of one.
    public let conflictKinds: Set<ConflictMechanism>

    /// The **resolution** this closing line reads well after — not the beat
    /// immediately before it.
    ///
    /// Genuinely different from `afterBeat`, which is why it is a separate
    /// field and not a synonym. On a page that pairs `self_recognize` with
    /// `warm_close`, the beat immediately before the closing line is the one
    /// beside it on the same page; what the closing line actually refers back
    /// to is how the story ended, two beats earlier. Reading this as `afterBeat`
    /// would have asked the wrong question and got a plausible wrong answer.
    public let afterClosing: [StoryBeat]

    /// Narrative state this line takes as already true.
    ///
    /// Finer than the beat's own preconditions, which bind every line that
    /// realizes it: a line that says the child now knew what was needed is only
    /// usable once something has established that, even where the beat itself
    /// does not require it.
    public let afterState: [NarrativeStateKey]

    /// Masal ailem relations this line is written for (FAZ 11).
    ///
    /// Empty means the line names no family character, which is every line
    /// written before FAZ 11. Non-empty means the line says `{{family.name}}`
    /// and reads right only for these relations — "kardeşi" is not a cat.
    /// Enforced like `castRoles`, never relaxed: see `suits(family:)`.
    public let familyRelations: Set<FamilyRelationKind>

    /// Safety topics (FAZ 17) this line touches, e.g. a line where the child
    /// is alone in the dark is `darkness` and `alone`. Empty is every line
    /// that touches none. Enforced, never relaxed: a parent who avoids the
    /// topic never hears the line (`OfflineStoryComposer.pool`).
    public let topics: Set<SafetyTopic>

    /// Glossary entries (FAZ 17, "Yeni kelimeler") this line teaches. Ids into
    /// `ContentCatalog.glossary`; the word itself is found in the rendered
    /// sentence, so the text stays plain prose for every other check.
    public let words: [ContentID]

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case id, text, visualScene, requiredSlots, stateRequirements, stateChanges
        case lengthClass, move, afterBeat, settingTraits, discoveryTraits
        case capabilityRequire, capabilityForbid, castRoles, register
        case conflictKinds, afterClosing, afterState
        case familyRelations
        case topics, words
    }

    /// Every key this type actually reads.
    ///
    /// Derived from `CodingKeys` rather than listed by hand, so it cannot drift
    /// from the decoder. A guard test compares it against what the corpus
    /// declares: a key the authors write and the engine ignores is the project's
    /// most durable failure mode — the content says a thing, the engine cannot
    /// hear it, and nothing anywhere reports that. `castRoles` sat unread that
    /// way, and so did `conflictKinds` while a whole family's obstacles were
    /// being carefully partitioned for an engine that was not listening.
    public static var decodedKeys: Set<String> {
        Set(CodingKeys.allCases.map(\.rawValue))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ContentID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        visualScene = try container.decodeIfPresent(String.self, forKey: .visualScene) ?? ""
        requiredSlots = try container.decodeIfPresent([ContentSlot].self, forKey: .requiredSlots) ?? []
        stateRequirements = try container.decodeIfPresent([StateFact].self, forKey: .stateRequirements) ?? []
        stateChanges = try container.decodeIfPresent([StateFact].self, forKey: .stateChanges) ?? []
        lengthClass = try container.decodeIfPresent(VariantLengthClass.self, forKey: .lengthClass)
        move = try container.decodeIfPresent(String.self, forKey: .move)
        // Unknown beats are dropped rather than rejected: `afterBeat` is a
        // preference, and a corpus should not fail to load because it names a
        // beat this engine does not model yet.
        afterBeat = (try container.decodeIfPresent([String].self, forKey: .afterBeat) ?? [])
            .compactMap(StoryBeat.init(rawValue:))
        settingTraits = try container.decodeIfPresent(Set<SettingTrait>.self, forKey: .settingTraits) ?? []
        discoveryTraits = try container.decodeIfPresent(Set<DiscoveryTrait>.self, forKey: .discoveryTraits) ?? []
        capabilityRequire = try container.decodeIfPresent(Set<CompanionTrait>.self, forKey: .capabilityRequire) ?? []
        capabilityForbid = try container.decodeIfPresent(Set<CompanionTrait>.self, forKey: .capabilityForbid) ?? []
        castRoles = try container.decodeIfPresent(Set<CompanionRole>.self, forKey: .castRoles) ?? []
        register = try container.decodeIfPresent(VariantRegister.self, forKey: .register)
        conflictKinds = try container.decodeIfPresent(Set<ConflictMechanism>.self, forKey: .conflictKinds) ?? []
        afterClosing = (try container.decodeIfPresent([String].self, forKey: .afterClosing) ?? [])
            .compactMap(StoryBeat.init(rawValue:))
        afterState = try container.decodeIfPresent([NarrativeStateKey].self, forKey: .afterState) ?? []
        familyRelations = try container.decodeIfPresent(Set<FamilyRelationKind>.self, forKey: .familyRelations) ?? []
        topics = try container.decodeIfPresent(Set<SafetyTopic>.self, forKey: .topics) ?? []
        words = try container.decodeIfPresent([ContentID].self, forKey: .words) ?? []
    }

    /// Whether this line is the right shape for how the story's conflict works.
    public func suits(conflict: ConflictMechanism?) -> Bool {
        guard !conflictKinds.isEmpty else { return true }
        guard let conflict else { return false }
        return conflictKinds.contains(conflict)
    }

    /// Whether this line can be used for the content that was bound.
    ///
    /// A variant declaring nothing fits anything, which is what keeps the
    /// existing corpus working.
    public func fits(
        setting: CatalogSetting,
        discovery: CatalogObject,
        companion: CatalogCompanion
    ) -> Bool {
        settingTraits.isSubset(of: setting.traits)
            && discoveryTraits.isSubset(of: discovery.traits)
            && capabilityRequire.isSubset(of: companion.traits)
            && capabilityForbid.isDisjoint(with: companion.traits)
    }

    /// Whether this line suits the part the companion is playing.
    ///
    /// Separate from `fits` because it is enforced differently: content the line
    /// assumes can be relaxed under pool pressure, a part cannot. See
    /// `OfflineStoryComposer.chooseVariant`.
    public func suits(role: CompanionRole?) -> Bool {
        guard !castRoles.isEmpty else { return true }
        guard let role else { return false }
        return castRoles.contains(role)
    }

    /// Whether this line may appear in a story with this Masal ailem character.
    ///
    /// Two directions, both strict. A family line in a story with no family
    /// character would leave `{{family.name}}` unfilled. A family line for the
    /// wrong relation describes someone else. Lines that name no family
    /// character suit every story; whether a family moment *must* carry one is
    /// the composer's decision, not the line's.
    public func suits(family relation: FamilyRelationKind?) -> Bool {
        guard !familyRelations.isEmpty else { return true }
        guard let relation else { return false }
        return familyRelations.contains(relation)
    }

    /// Whether this line carries a Masal ailem character at all.
    public var isFamilyLine: Bool { !familyRelations.isEmpty }

    /// Slots the text genuinely contains, regardless of what was declared.
    public var actualSlots: [ContentSlot] { ContentSlot.tokens(in: text) }
}

/// How certain a line sounds.
///
/// Authored only where it decides whether a later page still works. A belief
/// voiced as a maybe leaves page 6 something to do; one held with certainty is
/// what a Misreading story needs, because a tentative misreading leaves nothing
/// to overturn. The two are not stylistic variants of each other.
public enum VariantRegister: String, Codable, Sendable, Hashable, CaseIterable {
    case tentative
    case certain
}

/// Whether a variant is a whole page or half of one.
public enum VariantLengthClass: String, Codable, Sendable, Hashable, CaseIterable {
    /// The beat has the page to itself. Longer.
    case solo
    /// The page is shared with a supporting beat. Shorter.
    case paired
}

/// A pool of phrasings.
///
/// A template declares the **beat it realizes**, not the role it fills. One
/// well-written `insight` variant then serves every blueprint that uses
/// `insight`, whatever family it belongs to — prose reuse goes up, not down.
/// Role is retained for layout and visual intent, but it no longer drives text
/// selection.
///
/// `realizesBeat` is optional only so the current pre-beat catalog still loads.
/// A template without one is unselectable, and the integrity check says so.
public struct CatalogTemplate: Codable, Sendable, Hashable, Identifiable {
    public let id: ContentID
    public let role: PageRole
    public let realizesBeat: StoryBeat?
    public let compatibleThemes: [String]
    public let variants: [CatalogVariant]
    /// Bu prozanın yazıldığı yaş bandı.
    ///
    /// Yazım birimi dosyadır ve her dosya tek bir bant için yazılır — kelime
    /// bütçesi, cümle uzunluğu ve kelime dağarcığı bandın tamamı boyunca aynı
    /// kalır. Bu yüzden bant varyantta değil şablonda duruyor: bir dosyanın
    /// yarısını 3-4, yarısını 5-6 için yazmak diye bir şey yok.
    ///
    /// Nil "her banda uyar" demek ve yalnızca bant kavramından önce yazılmış
    /// eski kütüphane iskelesi için geçerli. Yeni içerik bandını söyler.
    public let ageBand: AgeBand?
    /// Bu prozanın yazıldığı ark (`NarrativeArc`). Bant gibi dosyada durur:
    /// uyku satırları yatakta başlayıp yatakta biten bir masal için yazılır ve
    /// bahçede açılan bir masala girmez; tersi de. Seçim ikisini hiç karıştırmaz
    /// (`OfflineStoryComposer.templates`), bu yüzden uyku satırı eklemek başka
    /// hiçbir masalın tohumunu kaydırmaz.
    public let arc: NarrativeArc

    private enum CodingKeys: String, CodingKey { case id, role, realizesBeat, compatibleThemes, variants, ageBand, arc }

    public init(
        id: ContentID,
        role: PageRole,
        realizesBeat: StoryBeat?,
        compatibleThemes: [String] = [],
        variants: [CatalogVariant],
        ageBand: AgeBand? = nil,
        arc: NarrativeArc = .standard
    ) {
        self.id = id
        self.role = role
        self.realizesBeat = realizesBeat
        self.compatibleThemes = compatibleThemes
        self.variants = variants
        self.ageBand = ageBand
        self.arc = arc
    }

    /// Bu şablon, bu bandın masalına yazı verebilir mi.
    ///
    /// Bantsız şablon her yere uyar (göç etmemiş içerik). Bantlı bir şablon,
    /// blueprint'in bandıyla ÖRTÜŞMELİ — kesişim boşsa 3-4 için yazılmış bir
    /// masala 5-6 cümlesi girer ve ortada hiçbir hata görünmez: metin
    /// kusursuzdur, yalnızca yanlış çocuğa yazılmıştır.
    public func suits(band: AgeBand?) -> Bool {
        guard let ageBand, let band else { return true }
        return ageBand.lowerBound <= band.upperBound && band.lowerBound <= ageBand.upperBound
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ContentID.self, forKey: .id)
        role = try container.decode(PageRole.self, forKey: .role)
        realizesBeat = try container.decodeIfPresent(StoryBeat.self, forKey: .realizesBeat)
        compatibleThemes = try container.decodeIfPresent([String].self, forKey: .compatibleThemes) ?? []
        variants = try container.decodeIfPresent([CatalogVariant].self, forKey: .variants) ?? []
        ageBand = try container.decodeIfPresent(AgeBand.self, forKey: .ageBand)
        arc = try container.decodeIfPresent(NarrativeArc.self, forKey: .arc) ?? .standard
    }

    /// `arc` is written only when it says something, so a standard template
    /// encodes exactly as it did before arcs existed.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(role, forKey: .role)
        try container.encodeIfPresent(realizesBeat, forKey: .realizesBeat)
        try container.encode(compatibleThemes, forKey: .compatibleThemes)
        try container.encode(variants, forKey: .variants)
        try container.encodeIfPresent(ageBand, forKey: .ageBand)
        if arc != .standard { try container.encode(arc, forKey: .arc) }
    }

    /// Whether this template can be selected under the beat-driven model.
    public var isSelectable: Bool { realizesBeat != nil && !variants.isEmpty }
}
