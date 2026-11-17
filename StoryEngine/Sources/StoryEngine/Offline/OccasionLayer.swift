import Foundation
import EngineFoundation

// MARK: - The request

/// A special day a story is written for (E6): a birthday, the first school
/// day, a new sibling, the first lost tooth.
///
/// Ids only, and at most one name: the sibling's, when the parent chose one of
/// the child's Masal ailem siblings. Without it the story says "küçük kardeşi".
public struct OccasionRequest: Sendable, Hashable {
    public let kind: ContentID
    public let sibling: FamilyCast?

    public init(kind: ContentID, sibling: FamilyCast? = nil) {
        self.kind = kind
        self.sibling = sibling
    }
}

// MARK: - The catalog layer

/// One special day the catalog knows.
public struct CatalogOccasion: Codable, Sendable, Hashable, Identifiable {
    public let id: ContentID
    /// Shown to the parent; the app keeps its own copy for the screens.
    public let name: String

    public init(id: ContentID, name: String) {
        self.id = id
        self.name = name
    }
}

/// A blueprint written for one special day. Decoded from the same JSON object
/// as an ordinary blueprint, with one more key, `occasion`.
public struct OccasionBlueprint: Decodable, Sendable {
    public let occasion: ContentID
    public let blueprint: CatalogBlueprint

    public init(occasion: ContentID, blueprint: CatalogBlueprint) {
        self.occasion = occasion
        self.blueprint = blueprint
    }

    private enum CodingKeys: String, CodingKey { case occasion }

    public init(from decoder: Decoder) throws {
        occasion = try decoder.container(keyedBy: CodingKeys.self).decode(ContentID.self, forKey: .occasion)
        blueprint = try CatalogBlueprint(from: decoder)
    }
}

/// Lines written for one special day, for the opening or the closing beat of
/// its blueprints. Same JSON shape as a library template, plus `occasion`.
public struct OccasionTemplate: Decodable, Sendable, Hashable {
    public let occasion: ContentID
    public let template: CatalogTemplate

    public init(occasion: ContentID, template: CatalogTemplate) {
        self.occasion = occasion
        self.template = template
    }

    private enum CodingKeys: String, CodingKey { case occasion }

    public init(from decoder: Decoder) throws {
        occasion = try decoder.container(keyedBy: CodingKeys.self).decode(ContentID.self, forKey: .occasion)
        template = try CatalogTemplate(from: decoder)
    }
}

/// Everything only a special-day story uses (E6), kept apart like
/// `SeriesCatalog`: no ordinary story can reach these blueprints or lines, and
/// every book written without an occasion stays the same book.
public struct OccasionCatalog: Decodable, Sendable {
    public let kinds: [CatalogOccasion]
    public let blueprints: [OccasionBlueprint]
    public let templates: [OccasionTemplate]

    public init(
        kinds: [CatalogOccasion] = [],
        blueprints: [OccasionBlueprint] = [],
        templates: [OccasionTemplate] = []
    ) {
        self.kinds = kinds
        self.blueprints = blueprints
        self.templates = templates
    }

    private enum CodingKeys: String, CodingKey { case kinds, blueprints, templates }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kinds = try container.decodeIfPresent([CatalogOccasion].self, forKey: .kinds) ?? []
        blueprints = try container.decodeIfPresent([OccasionBlueprint].self, forKey: .blueprints) ?? []
        templates = try container.decodeIfPresent([OccasionTemplate].self, forKey: .templates) ?? []
    }

    public var isEmpty: Bool { kinds.isEmpty && blueprints.isEmpty }

    public func kind(_ id: ContentID) -> CatalogOccasion? { kinds.first { $0.id == id } }

    static func merging(_ parts: [OccasionCatalog]) -> OccasionCatalog {
        OccasionCatalog(
            kinds: parts.flatMap(\.kinds),
            blueprints: parts.flatMap(\.blueprints),
            templates: parts.flatMap(\.templates))
    }
}

// MARK: - Composing

extension OfflineStoryComposer {
    /// The slot a special-day line names the sibling with: the parent's chosen
    /// sibling by name, otherwise "küçük kardeşi" (a possessive phrase, so
    /// "küçük kardeşine", "küçük kardeşini").
    static let occasionSiblingSlot = "occasion.sibling"

    static func occasionSlot(_ occasion: OccasionRequest) -> TurkishTextRenderer.Slot {
        if let sibling = occasion.sibling {
            return .init(sibling.name, isProperNoun: true)
        }
        return .init("küçük kardeşi", isProperNoun: false, hasPossessiveEnding: true)
    }

    /// What an occasion adds to a seed or fingerprint. Empty without one, so
    /// nothing written before E6 changes.
    static func occasionKey(_ occasion: OccasionRequest?) -> [String] {
        guard let occasion else { return [] }
        return ["occasion", occasion.kind.rawValue, occasion.sibling?.name ?? ""]
    }

    /// The special day's blueprints this intent can use: its band, its mode,
    /// what the parent allows. In a seeded rotation, so the same seed starts
    /// from the same one.
    static func occasionCandidates(
        catalog: ContentCatalog, intent: OfflineStoryIntent, occasion: OccasionRequest
    ) -> [CatalogBlueprint] {
        let profile = intent.mode.flatMap { catalog.modeProfile($0) }
        let pool = catalog.occasions.blueprints
            .filter { $0.occasion == occasion.kind }
            .map(\.blueprint)
            .filter { blueprint in intent.ageBand.map { blueprint.ageRange == $0 } ?? true }
            .filter { blueprint in intent.mode == nil || (profile?.admits(blueprint) ?? false) }
            .filter { intent.safety?.admits(blueprint: $0) ?? true }
            .sorted { $0.id.rawValue < $1.id.rawValue }
        guard pool.count > 1 else { return pool }
        let start = DeterministicPicker.index(count: pool.count, seed: intent.seed, salt: "occasion")
        return Array(pool[start...] + pool[..<start])
    }

    /// A special-day story, or a typed error. Never an ordinary story instead:
    /// the parent asked for this day.
    func composeOccasion(
        catalog: ContentCatalog, intent: OfflineStoryIntent, occasion: OccasionRequest
    ) throws -> ComposedStory {
        let candidates = Self.occasionCandidates(catalog: catalog, intent: intent, occasion: occasion)
        var reasons: [String] = candidates.isEmpty ? ["no blueprint for this band, mode and setting"] : []
        for blueprint in candidates {
            do {
                return try compose(blueprint: blueprint, catalog: catalog, intent: intent, idea: nil)
            } catch {
                reasons.append("\(blueprint.id.rawValue): \(error)")
            }
        }
        throw OfflineSelectionError.noOccasionStory(occasion: occasion.kind.rawValue, reasons: reasons)
    }

    /// The special day's own lines for this beat, when it has any for this
    /// blueprint's band and arc. They replace the ordinary lines on that page.
    static func occasionTemplates(
        for beat: StoryBeat, in catalog: ContentCatalog, blueprint: CatalogBlueprint, occasion: ContentID
    ) -> [CatalogTemplate] {
        catalog.occasions.templates
            .filter { $0.occasion == occasion }
            .map(\.template)
            .filter {
                $0.realizesBeat == beat && !$0.variants.isEmpty
                    && $0.suits(band: blueprint.ageRange) && $0.arc == blueprint.arc
            }
    }
}

// MARK: - What the app may offer

extension BlueprintSelector {
    /// The special days a story can be written for, with this mode, band and
    /// what the parent allows. Asked before a chip is shown, like
    /// `availableTopics`: a day whose blueprint cannot bind is not offered.
    public func availableOccasions(catalog: ContentCatalog, intent: OfflineStoryIntent) -> [CatalogOccasion] {
        let binder = OfflineContentBinder()
        return catalog.occasions.kinds.filter { kind in
            let request = OccasionRequest(kind: kind.id)
            let probe = intent.replacingOccasion(request)
            return OfflineStoryComposer.occasionCandidates(catalog: catalog, intent: probe, occasion: request)
                .contains { (try? binder.bind(blueprint: $0, catalog: catalog, intent: probe)) != nil }
        }
    }
}

extension OfflineStoryIntent {
    /// The same intent for another occasion; every other field kept.
    func replacingOccasion(_ occasion: OccasionRequest?) -> OfflineStoryIntent {
        OfflineStoryIntent(
            childName: childName, storyIdeaID: storyIdeaID, settingID: settingID,
            companionID: companionID, discoveryID: discoveryID, seed: seed, mode: mode,
            ageBand: ageBand, subOption: subOption, family: family, interests: interests,
            recent: recent, usage: usage, safety: safety, recentTitles: recentTitles,
            recall: recall, occasion: occasion)
    }
}
