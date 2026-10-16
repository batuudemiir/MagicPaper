import Foundation
import EngineFoundation

/// Everything the offline engine can build a story from.
///
/// One versioned document, owned by the package. The app never reads it; it asks
/// for display-ready choices and submits ids.
///
/// Decodable only, deliberately. The catalog is authored — by hand or by the
/// development-time Content Creator — and is never written by the runtime.
/// Making it `Encodable` would imply a round trip the engine does not have, and
/// could not honour for collections it does not yet model.
public struct ContentCatalog: Decodable, Sendable {
    public let version: String
    public let settings: [CatalogSetting]
    public let companions: [CatalogCompanion]
    public let objects: [CatalogObject]
    public let events: [CatalogEvent]
    public let challenges: [CatalogChallenge]
    public let endings: [CatalogEnding]
    public let templates: [CatalogTemplate]
    public let blueprints: [CatalogBlueprint]
    /// What the child is offered. Empty in the V1 document; authored
    /// alongside the beat-authored blueprints.
    public let storyIdeas: [CatalogStoryIdea]
    /// Which narrative families serve each parent intent (`StoryMode`).
    /// Authored content, not code: re-mapping a mode is a catalog edit.
    public let storyModes: [StoryModeProfile]
    /// Mod içindeki alt seçenekler (`CatalogStoryTopic`). İçerik, kod değil:
    /// yeni bir konu açmak katalog düzenlemesidir, uygulama güncellemesi değil.
    public let storyTopics: [CatalogStoryTopic]
    /// Beats where a Masal ailem character appears (FAZ 11). Authored content:
    /// today the opening and the closing, which every blueprint shares, so one
    /// set of lines makes every blueprint able to carry the character.
    public let familyMoments: [StoryBeat]
    /// The animal kinds a Masal ailem pet can be. A fixed list, not free text.
    public let familyAnimalKinds: [CatalogFamilyAnimalKind]
    /// The interest vocabulary (FAZ 12): every word a parent can pick under
    /// "Neleri sever?" and content can be tagged with. Authored, not coded —
    /// which words are *shown* is decided by coverage, not by this list.
    public let interests: [CatalogInterest]
    /// Topics a parent can ask stories to avoid (FAZ 17). Authored like the
    /// interests: a new topic is a catalog edit.
    public let safetyTopics: [CatalogSafetyTopic]
    /// Words stories teach, with their meanings (FAZ 17). Lines refer to
    /// entries by id (`CatalogVariant.words`).
    public let glossary: [CatalogGlossaryEntry]
    /// Everything only a series episode uses (FAZ 13). Kept out of
    /// `blueprints` and `templates` so no standalone story can reach it, and
    /// every book written before the series existed stays the same book.
    public let series: SeriesCatalog

    /// How many `resolutions` the file declares.
    ///
    /// The key exists in the shipped catalog but is empty, and there is no
    /// schema to infer from zero records — so it is counted rather than modelled.
    /// Counting it means the integrity check can say "declared but unusable"
    /// instead of the key vanishing silently on decode.
    public let declaredResolutionCount: Int

    private enum CodingKeys: String, CodingKey {
        case version, settings, companions, objects, events, challenges, endings, templates, blueprints
        case storyIdeas
        case storyModes
        case storyTopics
        case familyMoments, familyAnimalKinds
        case interests
        case safetyTopics, glossary
        case series
        case resolutions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(String.self, forKey: .version) ?? "0.0.0"
        settings = try container.decodeIfPresent([CatalogSetting].self, forKey: .settings) ?? []
        companions = try container.decodeIfPresent([CatalogCompanion].self, forKey: .companions) ?? []
        objects = try container.decodeIfPresent([CatalogObject].self, forKey: .objects) ?? []
        events = try container.decodeIfPresent([CatalogEvent].self, forKey: .events) ?? []
        challenges = try container.decodeIfPresent([CatalogChallenge].self, forKey: .challenges) ?? []
        endings = try container.decodeIfPresent([CatalogEnding].self, forKey: .endings) ?? []
        templates = try container.decodeIfPresent([CatalogTemplate].self, forKey: .templates) ?? []
        blueprints = try container.decodeIfPresent([CatalogBlueprint].self, forKey: .blueprints) ?? []
        storyIdeas = try container.decodeIfPresent([CatalogStoryIdea].self, forKey: .storyIdeas) ?? []
        storyModes = try container.decodeIfPresent([StoryModeProfile].self, forKey: .storyModes) ?? []
        storyTopics = try container.decodeIfPresent([CatalogStoryTopic].self, forKey: .storyTopics) ?? []
        familyMoments = try container.decodeIfPresent([StoryBeat].self, forKey: .familyMoments) ?? []
        familyAnimalKinds = try container.decodeIfPresent(
            [CatalogFamilyAnimalKind].self, forKey: .familyAnimalKinds) ?? []
        interests = try container.decodeIfPresent([CatalogInterest].self, forKey: .interests) ?? []
        safetyTopics = try container.decodeIfPresent([CatalogSafetyTopic].self, forKey: .safetyTopics) ?? []
        glossary = try container.decodeIfPresent([CatalogGlossaryEntry].self, forKey: .glossary) ?? []
        series = try container.decodeIfPresent(SeriesCatalog.self, forKey: .series) ?? SeriesCatalog()
        declaredResolutionCount = (try? container.decode([AnyIgnored].self, forKey: .resolutions).count) ?? 0
    }

    public init(
        version: String,
        settings: [CatalogSetting] = [],
        companions: [CatalogCompanion] = [],
        objects: [CatalogObject] = [],
        events: [CatalogEvent] = [],
        challenges: [CatalogChallenge] = [],
        endings: [CatalogEnding] = [],
        templates: [CatalogTemplate] = [],
        blueprints: [CatalogBlueprint] = [],
        storyIdeas: [CatalogStoryIdea] = [],
        storyModes: [StoryModeProfile] = [],
        storyTopics: [CatalogStoryTopic] = [],
        familyMoments: [StoryBeat] = [],
        familyAnimalKinds: [CatalogFamilyAnimalKind] = [],
        interests: [CatalogInterest] = [],
        safetyTopics: [CatalogSafetyTopic] = [],
        glossary: [CatalogGlossaryEntry] = [],
        series: SeriesCatalog = SeriesCatalog(),
        declaredResolutionCount: Int = 0
    ) {
        self.version = version
        self.settings = settings
        self.companions = companions
        self.objects = objects
        self.events = events
        self.challenges = challenges
        self.endings = endings
        self.templates = templates
        self.blueprints = blueprints
        self.storyIdeas = storyIdeas
        self.storyModes = storyModes
        self.storyTopics = storyTopics
        self.familyMoments = familyMoments
        self.familyAnimalKinds = familyAnimalKinds
        self.interests = interests
        self.safetyTopics = safetyTopics
        self.glossary = glossary
        self.series = series
        self.declaredResolutionCount = declaredResolutionCount
    }

    // MARK: - Lookups

    public func setting(_ id: ContentID) -> CatalogSetting? { settings.first { $0.id == id } }
    public func companion(_ id: ContentID) -> CatalogCompanion? { companions.first { $0.id == id } }
    public func object(_ id: ContentID) -> CatalogObject? { objects.first { $0.id == id } }
    public func blueprint(_ id: ContentID) -> CatalogBlueprint? { blueprints.first { $0.id == id } }
    public func modeProfile(_ mode: StoryMode) -> StoryModeProfile? { storyModes.first { $0.mode == mode } }
    public func familyAnimalKind(_ id: ContentID) -> CatalogFamilyAnimalKind? {
        familyAnimalKinds.first { $0.id == id }
    }
    public func interest(_ id: InterestTag) -> CatalogInterest? { interests.first { $0.id == id } }
    public func safetyTopic(_ id: SafetyTopic) -> CatalogSafetyTopic? { safetyTopics.first { $0.id == id } }
    public func glossaryEntry(_ id: ContentID) -> CatalogGlossaryEntry? { glossary.first { $0.id == id } }
    public func templates(for role: PageRole) -> [CatalogTemplate] { templates.filter { $0.role == role } }

    /// Every setting tag in the catalog — the vocabulary other records may
    /// legitimately refer to.
    public var settingTagVocabulary: Set<ContentTag> {
        Set(settings.flatMap(\.tags))
    }

    /// Every theme any record claims compatibility with.
    public var themeVocabulary: Set<String> {
        var themes = Set<String>()
        settings.forEach { themes.formUnion($0.compatibleThemes) }
        companions.forEach { themes.formUnion($0.compatibleThemes) }
        objects.forEach { themes.formUnion($0.compatibleThemes) }
        events.forEach { themes.formUnion($0.compatibleThemes) }
        challenges.forEach { themes.formUnion($0.compatibleThemes) }
        endings.forEach { themes.formUnion($0.compatibleThemes) }
        templates.forEach { themes.formUnion($0.compatibleThemes) }
        blueprints.forEach { themes.insert($0.theme) }
        return themes
    }

    /// Roles some blueprint actually asks for.
    public var reachableRoles: Set<PageRole> {
        Set(blueprints.flatMap(\.roleSequence))
    }

    public var isEmpty: Bool { blueprints.isEmpty }

    /// Stable identity of this catalog's contents, for provenance and for
    /// telling two builds apart.
    public var fingerprint: String {
        StableHash.fingerprint([
            version,
            "settings:\(settings.count)", "companions:\(companions.count)",
            "objects:\(objects.count)", "events:\(events.count)",
            "challenges:\(challenges.count)", "endings:\(endings.count)",
            "templates:\(templates.count)", "blueprints:\(blueprints.count)"
        ] + blueprints.map(\.id.rawValue).sorted())
    }

    public var recordCounts: [String: Int] {
        [
            "settings": settings.count, "companions": companions.count,
            "objects": objects.count, "events": events.count,
            "challenges": challenges.count, "endings": endings.count,
            "templates": templates.count, "blueprints": blueprints.count,
            "resolutions": declaredResolutionCount,
            "variants": templates.reduce(0) { $0 + $1.variants.count }
        ]
    }
}


/// The series layer of the catalog (FAZ 13).
///
/// Continuation blueprints, the lines written only for episodes, and where in
/// an episode the Masal ailem character appears. An episode opens with
/// `revisit`, not `notice_anomaly`, so its family moments differ from a
/// standalone story's.
public struct SeriesCatalog: Decodable, Sendable {
    public let continuations: [CatalogBlueprint]
    /// Episode-only lines, one template per beat file and band. Loaded from
    /// `beat_series_*.json` files; never in `ContentCatalog.templates`.
    public let templates: [CatalogTemplate]
    public let familyMoments: [StoryBeat]

    public init(
        continuations: [CatalogBlueprint] = [],
        templates: [CatalogTemplate] = [],
        familyMoments: [StoryBeat] = []
    ) {
        self.continuations = continuations
        self.templates = templates
        self.familyMoments = familyMoments
    }

    private enum CodingKeys: String, CodingKey { case continuations, templates, familyMoments }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        continuations = try container.decodeIfPresent([CatalogBlueprint].self, forKey: .continuations) ?? []
        templates = try container.decodeIfPresent([CatalogTemplate].self, forKey: .templates) ?? []
        familyMoments = try container.decodeIfPresent([StoryBeat].self, forKey: .familyMoments) ?? []
    }

    public var isEmpty: Bool { continuations.isEmpty }

    public func continuation(_ id: ContentID) -> CatalogBlueprint? { continuations.first { $0.id == id } }

    static func merging(_ parts: [SeriesCatalog]) -> SeriesCatalog {
        SeriesCatalog(
            continuations: parts.flatMap(\.continuations),
            templates: parts.flatMap(\.templates),
            familyMoments: parts.flatMap(\.familyMoments).reduce(into: []) {
                if !$0.contains($1) { $0.append($1) }
            })
    }

    /// The same layer with the corpus' series lines added.
    func adding(templates extra: [CatalogTemplate]) -> SeriesCatalog {
        SeriesCatalog(continuations: continuations, templates: extra + templates, familyMoments: familyMoments)
    }
}

/// Decodes and discards. Lets the catalog count records of a shape it does not
/// yet model without inventing one.
struct AnyIgnored: Decodable {
    init(from decoder: Decoder) throws {
        _ = try decoder.singleValueContainer()
    }
}

// MARK: - Merging

extension ContentCatalog {
    /// One catalog assembled from several authored documents.
    ///
    /// Content is authored in more than one file on purpose: the V1 library and
    /// the beat-authored pilot library have different lifetimes, and the corpus
    /// being written per-beat elsewhere will add more. Requiring one file would
    /// mean either freezing V1 content into the new library or waiting for a
    /// migration that is not finished.
    ///
    /// Records are concatenated in the order given, and **duplicate ids are not
    /// resolved here**. `CatalogIntegrityChecker` already reports duplicates,
    /// and silently dropping one of two records that claim the same id is how a
    /// content bug becomes a mystery. Lookups take the first match, so the order
    /// of `catalogs` is the precedence order.
    ///
    /// `version` is the first non-empty version, since that is the one a reader
    /// would call "the catalog version"; `declaredResolutionCount` sums, because
    /// it is a count of a thing that was never modelled.
    public static func merging(_ catalogs: [ContentCatalog]) -> ContentCatalog {
        guard let first = catalogs.first else {
            return ContentCatalog(version: "0.0.0")
        }
        guard catalogs.count > 1 else { return first }

        return ContentCatalog(
            version: catalogs.first { $0.version != "0.0.0" }?.version ?? first.version,
            settings: catalogs.flatMap(\.settings),
            companions: catalogs.flatMap(\.companions),
            objects: catalogs.flatMap(\.objects),
            events: catalogs.flatMap(\.events),
            challenges: catalogs.flatMap(\.challenges),
            endings: catalogs.flatMap(\.endings),
            templates: catalogs.flatMap(\.templates),
            blueprints: catalogs.flatMap(\.blueprints),
            storyIdeas: catalogs.flatMap(\.storyIdeas),
            storyModes: catalogs.flatMap(\.storyModes),
            storyTopics: catalogs.flatMap(\.storyTopics),
            // A moment is a beat, so two documents naming the same one mean
            // the same thing; kinds are records and go to the duplicate check.
            familyMoments: catalogs.flatMap(\.familyMoments).reduce(into: []) {
                if !$0.contains($1) { $0.append($1) }
            },
            familyAnimalKinds: catalogs.flatMap(\.familyAnimalKinds),
            interests: catalogs.flatMap(\.interests),
            safetyTopics: catalogs.flatMap(\.safetyTopics),
            glossary: catalogs.flatMap(\.glossary),
            series: SeriesCatalog.merging(catalogs.map(\.series)),
            declaredResolutionCount: catalogs.reduce(0) { $0 + $1.declaredResolutionCount }
        )
    }
}

extension ContentCatalog {
    /// This catalog with a different series layer; everything else as it is.
    func replacingSeries(_ series: SeriesCatalog) -> ContentCatalog {
        ContentCatalog(
            version: version, settings: settings, companions: companions, objects: objects,
            events: events, challenges: challenges, endings: endings, templates: templates,
            blueprints: blueprints, storyIdeas: storyIdeas, storyModes: storyModes,
            storyTopics: storyTopics, familyMoments: familyMoments, familyAnimalKinds: familyAnimalKinds,
            interests: interests, safetyTopics: safetyTopics, glossary: glossary, series: series,
            declaredResolutionCount: declaredResolutionCount)
    }
}
