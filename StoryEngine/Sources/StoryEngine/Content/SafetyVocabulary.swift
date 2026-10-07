import Foundation

/// One topic a parent can ask stories to stay away from, e.g. `darkness` (FAZ 17).
///
/// Catalog data like `InterestTag`, not a Swift enum: a topic the content
/// pipeline starts tagging is a catalog edit, and a remote pack can add one
/// without an app update. A parent's "avoid every topic" then covers it too.
///
/// "Ölüm ve kayıp" is deliberately not a topic. No line, record or blueprint
/// tells of death or grief; offering it as a choice would suggest that some
/// story does. The validator refuses such a tag (`check_safety_topics`).
public struct SafetyTopic: Hashable, Codable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
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

/// A topic the catalog defines: its id, the word a parent sees, and a short
/// sentence saying what avoiding it changes.
public struct CatalogSafetyTopic: Codable, Sendable, Hashable, Identifiable {
    public let id: SafetyTopic
    /// The chip label, e.g. "Karanlık".
    public let name: String
    /// One sentence for the parent, e.g. "Gece ve karanlık yerler geçmez."
    public let summary: String?

    public init(id: SafetyTopic, name: String, summary: String? = nil) {
        self.id = id
        self.name = name
        self.summary = summary
    }
}

/// Content that can carry safety topics: settings, companions, objects and
/// blueprints. Lines carry them too (`CatalogVariant.topics`), as a set.
public protocol SafetyTagged {
    var topics: [SafetyTopic] { get }
}

extension CatalogSetting: SafetyTagged {}
extension CatalogCompanion: SafetyTagged {}
extension CatalogObject: SafetyTagged {}
extension CatalogBlueprint: SafetyTagged {}

/// What a parent allows in a child's stories (FAZ 17, "İçerik güvenliği").
///
/// A filter, never a weight: content it rules out is not chosen less often, it
/// is not chosen. Where that leaves a mode with nothing to tell, the mode is
/// not offered (`BlueprintSelector.availableModes`), it does not fail at "Başla".
public struct ContentSafety: Sendable, Hashable, Codable {

    /// How much tension a story may hold. Two steps, by decision (7 Ekim 2026).
    public enum Level: String, Sendable, Hashable, Codable, CaseIterable {
        /// No page that is uneasy or hesitant. The default.
        case calm
        /// Every story the catalog has; nothing in it is frightening (the
        /// emotional ceiling already keeps fear and panic out of every band).
        case someExcitement
    }

    public let level: Level
    /// Topics to avoid. Nil means every topic the catalog defines, including
    /// ones added after the parent chose: the most protective answer to a
    /// question the parent was never asked.
    public let avoided: Set<SafetyTopic>?

    public init(level: Level, avoided: Set<SafetyTopic>?) {
        self.level = level
        self.avoided = avoided
    }

    /// The default for every child: calm, every topic avoided.
    public static let mostProtective = ContentSafety(level: .calm, avoided: nil)
    /// Nothing filtered. What an intent without a safety setting means.
    public static let unfiltered = ContentSafety(level: .someExcitement, avoided: [])

    /// Page emotions a `.calm` story does not have.
    ///
    /// By name, not by intensity: intensity 2 also holds `effort`, `patience`
    /// and `frustration`, which are the work of nearly every story and frighten
    /// nobody. Unease and hesitation are the two that read as being afraid.
    public static let tenseEmotions: Set<EmotionalState> = [.unease, .hesitation]

    public func avoids(_ topic: SafetyTopic) -> Bool {
        avoided?.contains(topic) ?? true
    }

    public func admits<Topics: Sequence>(topics: Topics) -> Bool where Topics.Element == SafetyTopic {
        !topics.contains(where: avoids)
    }

    public func admits(_ record: some SafetyTagged) -> Bool {
        admits(topics: record.topics)
    }

    /// Whether a blueprint may be told at all: its own topics, and for `.calm`
    /// the feeling of every page.
    public func admits(blueprint: CatalogBlueprint) -> Bool {
        guard admits(topics: blueprint.topics) else { return false }
        guard level == .calm else { return true }
        return !blueprint.pagePlan.contains { $0.emotion.map(Self.tenseEmotions.contains) ?? false }
    }

    /// Why a blueprint is ruled out, for the selector's rejection list. Names
    /// the topic or the emotion, never anything about the child.
    func rejection(of blueprint: CatalogBlueprint) -> String? {
        if let topic = blueprint.topics.first(where: avoids) {
            return "tells of '\(topic.rawValue)', which the parent avoids"
        }
        if level == .calm, let tense = blueprint.pagePlan.compactMap(\.emotion)
            .first(where: Self.tenseEmotions.contains) {
            return "has a '\(tense.rawValue)' page and the parent chose calm stories"
        }
        return nil
    }

    func rejection(of record: some SafetyTagged) -> String? {
        record.topics.first(where: avoids).map { "carries '\($0.rawValue)', which the parent avoids" }
    }
}
