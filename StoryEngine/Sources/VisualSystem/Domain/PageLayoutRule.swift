import Foundation
import EngineFoundation

/// Where a page sits in the book. Used by layout predicates so rules can talk
/// about "the first page" or "every other page" without hard-coding indices.
public enum PagePosition: String, Codable, Sendable, CaseIterable, Hashable {
    case first
    case last
    case even
    case odd
    case interior   // neither first nor last
}

/// What a page must look like for a rule to apply.
///
/// Beat roles are matched as strings on purpose: the narrative vocabulary lives
/// in the story templates, and the design system stays independent of it.
public struct LayoutPredicate: Codable, Sendable, Hashable {
    public let beatRoles: [String]?
    public let positions: [PagePosition]?
    public let pageIndices: [Int]?

    public init(beatRoles: [String]? = nil, positions: [PagePosition]? = nil, pageIndices: [Int]? = nil) {
        self.beatRoles = beatRoles
        self.positions = positions
        self.pageIndices = pageIndices
    }

    /// Matches everything. Used for a catch-all default rule.
    public static let always = LayoutPredicate()

    /// How specific this predicate is. More constraints win over fewer, so a
    /// rule for "the last page of a closing beat" beats a blanket default
    /// without anyone having to order the list carefully.
    public var specificity: Int {
        (beatRoles == nil ? 0 : 1) + (positions == nil ? 0 : 1) + (pageIndices == nil ? 0 : 2)
    }

    public func matches(_ context: LayoutContext) -> Bool {
        if let beatRoles, !beatRoles.contains(context.beatRole) { return false }
        if let pageIndices, !pageIndices.contains(context.pageIndex) { return false }
        if let positions, !positions.contains(where: { context.satisfies($0) }) { return false }
        return true
    }
}

/// The page being laid out, as the predicate sees it.
public struct LayoutContext: Sendable, Hashable {
    public let pageIndex: Int      // zero-based
    public let pageCount: Int
    public let beatRole: String

    public init(pageIndex: Int, pageCount: Int, beatRole: String) {
        self.pageIndex = pageIndex
        self.pageCount = pageCount
        self.beatRole = beatRole
    }

    func satisfies(_ position: PagePosition) -> Bool {
        switch position {
        case .first: return pageIndex == 0
        case .last: return pageIndex == pageCount - 1
        case .even: return pageIndex % 2 == 0
        case .odd: return pageIndex % 2 == 1
        case .interior: return pageIndex > 0 && pageIndex < pageCount - 1
        }
    }
}

/// How one page is built: layout, composition, type, and how much text fits.
public struct PageLayoutRule: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let version: SemanticVersion
    public let layout: PageLayout
    public let appliesTo: LayoutPredicate
    public let compositionRuleID: String
    public let typographyPresetID: String
    public let textWordBudget: ClosedRange<Int>

    public init(
        id: String,
        version: SemanticVersion,
        layout: PageLayout,
        appliesTo: LayoutPredicate,
        compositionRuleID: String,
        typographyPresetID: String,
        textWordBudget: ClosedRange<Int>
    ) {
        self.id = id
        self.version = version
        self.layout = layout
        self.appliesTo = appliesTo
        self.compositionRuleID = compositionRuleID
        self.typographyPresetID = typographyPresetID
        self.textWordBudget = textWordBudget
    }

    // ClosedRange is Codable, but as a two-element array; a named object reads
    // far better in a hand-edited template file.
    private enum CodingKeys: String, CodingKey {
        case id, version, layout, appliesTo, compositionRuleID, typographyPresetID, minimumWords, maximumWords
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        version = try container.decode(SemanticVersion.self, forKey: .version)
        layout = try container.decode(PageLayout.self, forKey: .layout)
        appliesTo = try container.decodeIfPresent(LayoutPredicate.self, forKey: .appliesTo) ?? .always
        compositionRuleID = try container.decode(String.self, forKey: .compositionRuleID)
        typographyPresetID = try container.decode(String.self, forKey: .typographyPresetID)
        let minimum = try container.decode(Int.self, forKey: .minimumWords)
        let maximum = try container.decode(Int.self, forKey: .maximumWords)
        guard minimum <= maximum, minimum >= 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .minimumWords,
                in: container,
                debugDescription: "Word budget \(minimum)...\(maximum) is not a valid range"
            )
        }
        textWordBudget = minimum...maximum
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(version, forKey: .version)
        try container.encode(layout, forKey: .layout)
        try container.encode(appliesTo, forKey: .appliesTo)
        try container.encode(compositionRuleID, forKey: .compositionRuleID)
        try container.encode(typographyPresetID, forKey: .typographyPresetID)
        try container.encode(textWordBudget.lowerBound, forKey: .minimumWords)
        try container.encode(textWordBudget.upperBound, forKey: .maximumWords)
    }
}
