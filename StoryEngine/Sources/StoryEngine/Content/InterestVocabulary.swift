import Foundation

/// One word of the interest vocabulary, e.g. `animals`, `sea` (FAZ 12).
///
/// The parent's "Neleri sever?" chips and the tags on catalog content are the
/// same words, so a choice on the profile can only ever mean something the
/// engine can find. The set of words is **catalog data**, not a Swift enum:
/// adding "dinosaurs" is a catalog edit, and a remote content pack (FAZ 15) can
/// add one without an app update.
///
/// Deliberately not a `ContentTag`. Setting tags already have a job — they pick
/// the cover world and tie companions to places — and an interest word landing
/// in that list would quietly change a book's cover.
public struct InterestTag: Hashable, Codable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(_ rawValue: String) { self.rawValue = rawValue.lowercased() }
    public init(stringLiteral value: String) { self.init(value) }
    public var description: String { rawValue }

    public init(from decoder: Decoder) throws {
        self.init(try decoder.singleValueContainer().decode(String.self))
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// An interest the catalog defines: its id, the word a parent sees, and a glyph.
///
/// The display name lives here, beside the id, because the vocabulary is open:
/// a word the app has never seen still has to be shown by name.
public struct CatalogInterest: Codable, Sendable, Hashable, Identifiable {
    public let id: InterestTag
    /// The chip label, e.g. "Hayvanlar".
    public let name: String
    /// An SF Symbol name. Optional; the screen draws a plain chip without it.
    public let symbol: String?

    public init(id: InterestTag, name: String, symbol: String? = nil) {
        self.id = id
        self.name = name
        self.symbol = symbol
    }
}

/// Content that can carry interest words: settings, companions, objects and
/// blueprints. What selection weighs and what coverage counts.
public protocol InterestTagged {
    var id: ContentID { get }
    var interests: [InterestTag] { get }
}

extension InterestTagged {
    public func matches(_ wanted: Set<InterestTag>) -> Bool {
        !wanted.isEmpty && interests.contains(where: wanted.contains)
    }
}

extension CatalogSetting: InterestTagged {}
extension CatalogCompanion: InterestTagged {}
extension CatalogObject: InterestTagged {}
extension CatalogBlueprint: InterestTagged {}
