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

    private enum CodingKeys: String, CodingKey {
        case id, text, visualScene, requiredSlots, stateRequirements, stateChanges
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ContentID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        visualScene = try container.decodeIfPresent(String.self, forKey: .visualScene) ?? ""
        requiredSlots = try container.decodeIfPresent([ContentSlot].self, forKey: .requiredSlots) ?? []
        stateRequirements = try container.decodeIfPresent([StateFact].self, forKey: .stateRequirements) ?? []
        stateChanges = try container.decodeIfPresent([StateFact].self, forKey: .stateChanges) ?? []
    }

    /// Slots the text genuinely contains, regardless of what was declared.
    public var actualSlots: [ContentSlot] { ContentSlot.tokens(in: text) }
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
