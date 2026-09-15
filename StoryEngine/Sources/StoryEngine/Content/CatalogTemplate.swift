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

    private enum CodingKeys: String, CodingKey {
        case id, text, visualScene, requiredSlots, stateRequirements, stateChanges
        case lengthClass, move, afterBeat, settingTraits, discoveryTraits
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
    }

    /// Whether this line can be used for the content that was bound.
    ///
    /// A variant declaring nothing fits anything, which is what keeps the
    /// existing corpus working.
    public func fits(setting: CatalogSetting, discovery: CatalogObject) -> Bool {
        settingTraits.isSubset(of: setting.traits)
            && discoveryTraits.isSubset(of: discovery.traits)
    }

    /// Slots the text genuinely contains, regardless of what was declared.
    public var actualSlots: [ContentSlot] { ContentSlot.tokens(in: text) }
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

    private enum CodingKeys: String, CodingKey { case id, role, realizesBeat, compatibleThemes, variants }

    public init(
        id: ContentID,
        role: PageRole,
        realizesBeat: StoryBeat?,
        compatibleThemes: [String] = [],
        variants: [CatalogVariant]
    ) {
        self.id = id
        self.role = role
        self.realizesBeat = realizesBeat
        self.compatibleThemes = compatibleThemes
        self.variants = variants
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ContentID.self, forKey: .id)
        role = try container.decode(PageRole.self, forKey: .role)
        realizesBeat = try container.decodeIfPresent(StoryBeat.self, forKey: .realizesBeat)
        compatibleThemes = try container.decodeIfPresent([String].self, forKey: .compatibleThemes) ?? []
        variants = try container.decodeIfPresent([CatalogVariant].self, forKey: .variants) ?? []
    }

    /// Whether this template can be selected under the beat-driven model.
    public var isSelectable: Bool { realizesBeat != nil && !variants.isEmpty }
}
