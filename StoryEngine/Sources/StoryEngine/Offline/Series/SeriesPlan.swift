import Foundation
import EngineFoundation

// MARK: - Plan

/// What a series keeps from its first story (FAZ 13).
///
/// The first story's finishing `DerivedNarrativeState` is the same for every
/// finished story — every key true, `resolved` included — except for the
/// content it was bound to. That content is what a series carries, and it is
/// already in the story's origin; so the anchor is built from the origin, and
/// no narrative state is stored.
public struct SeriesAnchor: Codable, Sendable, Hashable {
    public let settingID: ContentID
    public let companionID: ContentID
    /// What the first story found. It comes back in every episode as a
    /// remembered thing (`{{keepsake.name}}`) and is never found again.
    public let keepsakeID: ContentID

    public init(settingID: ContentID, companionID: ContentID, keepsakeID: ContentID) {
        self.settingID = settingID
        self.companionID = companionID
        self.keepsakeID = keepsakeID
    }
}

/// The Masal ailem character a series was planned with, without the name.
///
/// The name is the parent's words and lives only in the text. The plan keeps
/// what it needs to compose an episode again — the relation, the animal kind —
/// and the app's id for the character, so it can tell when that character is
/// deleted.
public struct SeriesFamily: Codable, Sendable, Hashable {
    public let characterID: String
    public let relation: FamilyRelationKind
    public let animalKindID: ContentID?

    public init(characterID: String, relation: FamilyRelationKind, animalKindID: ContentID? = nil) {
        self.characterID = characterID
        self.relation = relation
        self.animalKindID = animalKindID
    }
}

/// One planned episode: everything that decides its text, as ids.
public struct PlannedEpisode: Codable, Sendable, Hashable {
    /// 2…5.
    public let number: Int
    public let blueprintID: ContentID
    public let discoveryID: ContentID
    public let seed: String

    public init(number: Int, blueprintID: ContentID, discoveryID: ContentID, seed: String) {
        self.number = number
        self.blueprintID = blueprintID
        self.discoveryID = discoveryID
        self.seed = seed
    }
}

/// The four episodes after a story, decided once when "Devam ettir" is pressed.
///
/// Self-contained on purpose: nothing about the child's interests or history
/// enters it, so the same series continues the same way whatever changes
/// later. The episode text is composed from it at the same moment and stored by
/// the app; the plan is kept so an unopened episode can be composed again
/// without its Masal ailem character if that character is deleted.
public struct SeriesPlan: Codable, Sendable, Hashable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let seed: String
    public let catalogVersion: String
    public let mode: StoryMode
    public let ageBand: AgeBand
    public let anchor: SeriesAnchor
    public private(set) var family: SeriesFamily?
    public let episodes: [PlannedEpisode]
    /// The parent's content setting when the series was planned (FAZ 17). Kept
    /// so composing again gives the same episodes; a later change to the
    /// setting applies to the next series. Nil is every plan before FAZ 17.
    public let safety: ContentSafety?

    public init(
        seed: String,
        catalogVersion: String,
        mode: StoryMode,
        ageBand: AgeBand,
        anchor: SeriesAnchor,
        family: SeriesFamily?,
        episodes: [PlannedEpisode],
        safety: ContentSafety? = nil
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        self.safety = safety
        self.seed = seed
        self.catalogVersion = catalogVersion
        self.mode = mode
        self.ageBand = ageBand
        self.anchor = anchor
        self.family = family
        self.episodes = episodes
    }

    /// The same plan without its Masal ailem character.
    public func withoutFamily() -> SeriesPlan {
        var copy = self
        copy.family = nil
        return copy
    }

    public func episode(_ number: Int) -> PlannedEpisode? { episodes.first { $0.number == number } }
}

// MARK: - Planning

/// Why a series could not be planned. Names content by id, never the child or
/// the family character.
public enum SeriesPlanningError: Error, Sendable, Equatable, CustomStringConvertible {
    /// The anchor names content the catalog does not have.
    case unknownContent(ContentID)
    /// No continuation blueprint serves this mode, band and episode.
    case noContinuation(mode: StoryMode, band: AgeBand, episode: Int)
    /// No discovery could be bound for this episode.
    case noDiscovery(episode: Int)

    public var description: String {
        switch self {
        case .unknownContent(let id): return "Series anchor names unknown content \(id.rawValue)"
        case .noContinuation(let mode, let band, let episode):
            return "No continuation serves \(mode.rawValue) \(band) episode \(episode)"
        case .noDiscovery(let episode): return "No discovery fits episode \(episode)"
        }
    }
}

/// Plans and composes a series (FAZ 13). Pure: same inputs, same series.
public struct SeriesPlanner: Sendable {
    /// The episodes a plan holds. The first story is episode 1.
    public static let episodeNumbers = Array(ContinuationSpec.allEpisodes)

    private let composer = OfflineStoryComposer()

    public init() {}

    /// The series seed for a story: its own seed and fingerprint, so the same
    /// story always continues the same way and two stories never share one.
    public static func seed(storySeed: String, fingerprint: String) -> String {
        StableHash.fingerprint(["series", storySeed, fingerprint])
    }

    public struct Result: Sendable {
        public let plan: SeriesPlan
        /// Episodes 2…5 composed with the family character, in order.
        public let episodes: [ComposedStory]
    }

    /// Plans the four episodes and composes them.
    ///
    /// Every episode is checked twice before it is accepted: with the Masal
    /// ailem character and without. Deleting the character later recomposes
    /// the unopened episodes without it, and that must not be the moment the
    /// series turns out to be impossible.
    ///
    /// Discoveries are new in every episode and never the keepsake. When the
    /// catalog cannot give four new ones for this place, one may come back,
    /// but never in two episodes in a row.
    public func plan(
        anchor: SeriesAnchor,
        mode: StoryMode,
        band: AgeBand,
        family: FamilyCast?,
        familyCharacterID: String?,
        childName: String,
        seed: String,
        catalog: ContentCatalog,
        safety: ContentSafety? = nil
    ) throws -> Result {
        guard let keepsake = catalog.object(anchor.keepsakeID) else {
            throw SeriesPlanningError.unknownContent(anchor.keepsakeID)
        }
        guard catalog.setting(anchor.settingID) != nil else {
            throw SeriesPlanningError.unknownContent(anchor.settingID)
        }
        guard catalog.companion(anchor.companionID) != nil else {
            throw SeriesPlanningError.unknownContent(anchor.companionID)
        }

        let blueprints = try Self.episodeNumbers.map { number in
            try blueprint(for: number, mode: mode, band: band, seed: seed, catalog: catalog)
        }

        let seriesFamily = family.map {
            SeriesFamily(characterID: familyCharacterID ?? "", relation: $0.relation,
                         animalKindID: $0.animalKind?.id)
        }

        // Depth-first over discoveries: four levels, a handful of objects each.
        // First without any discovery coming back; only if no such series
        // exists for this place, again with one allowed back (never twice in
        // a row). Taking the first series found would repeat a discovery that
        // a different order could have kept new.
        var chosen: [(PlannedEpisode, ComposedStory)] = []
        var allowReuse = false
        func search(_ index: Int) -> Bool {
            guard index < Self.episodeNumbers.count else { return true }
            let number = Self.episodeNumbers[index]
            let used = chosen.map(\.0.discoveryID)
            let previous = used.last
            let avoiding = Set(chosen.flatMap { $0.1.pages.flatMap(\.variantIDs) })
            let episodeSeed = StableHash.fingerprint([seed, "episode", String(number)])
            for discovery in Self.candidates(
                catalog: catalog, keepsake: anchor.keepsakeID, used: used, previous: previous,
                seed: episodeSeed, allowReuse: allowReuse) {
                let planned = PlannedEpisode(
                    number: number, blueprintID: blueprints[index].id,
                    discoveryID: discovery, seed: episodeSeed)
                guard let story = try? compose(
                    planned, blueprint: blueprints[index], anchor: anchor, keepsake: keepsake,
                    mode: mode, band: band, childName: childName, family: family,
                    avoiding: avoiding, catalog: catalog, safety: safety)
                else { continue }
                // Avoiding is a preference that never fails a page, so the
                // set used here does not change whether this composes.
                if family != nil {
                    guard (try? compose(
                        planned, blueprint: blueprints[index], anchor: anchor, keepsake: keepsake,
                        mode: mode, band: band, childName: childName, family: nil,
                        avoiding: avoiding, catalog: catalog, safety: safety)) != nil
                    else { continue }
                }
                chosen.append((planned, story))
                if search(index + 1) { return true }
                chosen.removeLast()
            }
            return false
        }
        if !search(0) {
            chosen = []
            allowReuse = true
            guard search(0) else {
                throw SeriesPlanningError.noDiscovery(episode: Self.episodeNumbers[chosen.count])
            }
        }

        let plan = SeriesPlan(
            seed: seed, catalogVersion: catalog.version, mode: mode, ageBand: band,
            anchor: anchor, family: seriesFamily, episodes: chosen.map(\.0), safety: safety)
        return Result(plan: plan, episodes: chosen.map(\.1))
    }

    /// Composes every episode of a plan again, in order, from the plan alone.
    ///
    /// The whole series, because each episode avoids the lines of the ones
    /// before it: composing one alone could not know them. With the same plan,
    /// name and character this gives exactly what `plan` returned. `family`
    /// is used only while the plan still has one; a plan whose character was
    /// removed composes without it.
    public func compose(
        _ plan: SeriesPlan,
        childName: String,
        family: FamilyCast?,
        catalog: ContentCatalog
    ) throws -> [ComposedStory] {
        guard let keepsake = catalog.object(plan.anchor.keepsakeID) else {
            throw SeriesPlanningError.unknownContent(plan.anchor.keepsakeID)
        }
        var stories: [ComposedStory] = []
        for episode in plan.episodes {
            guard let blueprint = catalog.series.continuation(episode.blueprintID) else {
                throw SeriesPlanningError.unknownContent(episode.blueprintID)
            }
            stories.append(try compose(
                episode, blueprint: blueprint, anchor: plan.anchor, keepsake: keepsake,
                mode: plan.mode, band: plan.ageBand, childName: childName,
                family: plan.family == nil ? nil : family,
                avoiding: Set(stories.flatMap { $0.pages.flatMap(\.variantIDs) }),
                catalog: catalog, safety: plan.safety))
        }
        return stories
    }

    // MARK: - Internals

    private func compose(
        _ episode: PlannedEpisode,
        blueprint: CatalogBlueprint,
        anchor: SeriesAnchor,
        keepsake: CatalogObject,
        mode: StoryMode,
        band: AgeBand,
        childName: String,
        family: FamilyCast?,
        avoiding: Set<ContentID>,
        catalog: ContentCatalog,
        safety: ContentSafety?
    ) throws -> ComposedStory {
        let intent = OfflineStoryIntent(
            childName: childName,
            settingID: anchor.settingID,
            companionID: anchor.companionID,
            discoveryID: episode.discoveryID,
            seed: episode.seed,
            mode: mode,
            ageBand: band,
            family: family,
            safety: safety)
        return try composer.composeEpisode(
            blueprint: blueprint, catalog: catalog, intent: intent,
            episode: EpisodeContext(number: episode.number, keepsake: keepsake, avoiding: avoiding))
    }

    /// The continuation for one episode.
    ///
    /// The eligible blueprints are taken in id order and walked from a seeded
    /// start, one step per episode, so two mechanisms alternate (A-B-A-B)
    /// rather than the seed landing on the same one four times.
    private func blueprint(
        for number: Int, mode: StoryMode, band: AgeBand, seed: String, catalog: ContentCatalog
    ) throws -> CatalogBlueprint {
        let eligible = catalog.series.continuations
            .filter { $0.ageRange == band && $0.continuation?.modes.contains(mode) == true }
            .sorted { $0.id.rawValue < $1.id.rawValue }
        guard !eligible.isEmpty else {
            throw SeriesPlanningError.noContinuation(mode: mode, band: band, episode: number)
        }
        let start = DeterministicPicker.index(count: eligible.count, seed: seed, salt: "continuation")
        let offset = number - Self.episodeNumbers[0]
        for step in 0..<eligible.count {
            let candidate = eligible[(start + offset + step) % eligible.count]
            if candidate.continuation?.serves(mode: mode, episode: number) == true { return candidate }
        }
        throw SeriesPlanningError.noContinuation(mode: mode, band: band, episode: number)
    }

    /// Discoveries to try for an episode, best first: new ones in a seeded
    /// order, then (when allowed) ones already used — except the episode
    /// just before.
    static func candidates(
        catalog: ContentCatalog,
        keepsake: ContentID,
        used: [ContentID],
        previous: ContentID?,
        seed: String,
        allowReuse: Bool = true
    ) -> [ContentID] {
        let ordered = catalog.objects.map(\.id)
            .filter { $0 != keepsake }
            .sorted {
                (StableHash.hash([seed, $0.rawValue]), $0.rawValue)
                    < (StableHash.hash([seed, $1.rawValue]), $1.rawValue)
            }
        let fresh = ordered.filter { !used.contains($0) }
        guard allowReuse else { return fresh }
        let again = ordered.filter { used.contains($0) && $0 != previous }
        return fresh + again
    }
}
