import Foundation
import EngineFoundation

// MARK: - What the child asked for

/// The three choices, plus what makes the result reproducible.
///
/// Note what is **not** here: a theme string, a genre, a page count, or any
/// engine-facing knob. The child picks a place, a companion and a discovery;
/// everything structural is derived from those.
public struct OfflineStoryIntent: Sendable, Hashable {
    public let childName: String
    /// The idea the child picked. Nil means "surprise me" — the engine chooses
    /// one, and the rest of the flow is unchanged.
    public let storyIdeaID: ContentID?
    /// Nil means "Surprise Me" — the engine picks from what is admissible.
    public let settingID: ContentID?
    public let companionID: ContentID?
    public let discoveryID: ContentID?
    /// Fixed input to every tie-break, so the same intent yields the same book.
    public let seed: String
    /// The parent's intent, already resolved — "surprise" never reaches the
    /// engine as a mode (`StoryModeResolver` turns it into one). Nil admits
    /// every family, which is how intents built before modes behave.
    public let mode: StoryMode?
    /// The band the story is written for, from `AgeBandResolver`. Nil admits
    /// every band, which is how intents built before age banding behave.
    public let ageBand: AgeBand?
    /// Mod içinde bir alt seçenek. Her mod için gelecek, bugün hep `nil` ve
    /// seçici ile composer onu okumaz: alanın yeri ürün kararından önce
    /// açıldı ki niyet modeli o gün değişmesin.
    public let subOption: String?
    /// The child's Masal ailem character, if one was asked for. Nil is every
    /// story written before FAZ 11, and its text does not change: lines
    /// written for a family character are left out of the pool entirely.
    public let family: FamilyCast?
    /// The child's interests (FAZ 12). They add weight to matching content
    /// and never filter: an interest the catalog cannot serve today leaves the
    /// story exactly as it would have been. Empty is every story before FAZ 12.
    public let interests: [InterestTag]
    /// What the child's last stories were made of, newest first. Recently used
    /// content loses weight, which is what keeps an interest from turning every
    /// story into the same one. Empty means no history, and selection is then
    /// exactly what it was before FAZ 12.
    public let recent: [RecentContent]
    /// What the child's own reading taught (FAZ 14): families and companions
    /// re-read weigh more, ones abandoned weigh less. `.neutral` — every story
    /// before FAZ 14, and every child with nothing read yet — changes nothing.
    public let usage: UsageProfile
    /// What the parent allows (FAZ 17). Nil filters nothing, which is every
    /// story before FAZ 17 and every test that does not ask; the app always
    /// passes the child's setting, `.mostProtective` until a parent changes it.
    /// A filter, not a weight, and not part of the story's seed: where it
    /// rules nothing out, the book is the one it would have been.
    public let safety: ContentSafety?
    /// The titles already in this child's library (21 Ekim 2026). Only the
    /// title reads it: a pattern whose title the child already has is skipped
    /// while another is clean (`TitleComposer`). Not part of the seed or the
    /// fingerprint; empty is every story before it, and changes nothing.
    public let recentTitles: Set<String>

    public init(
        childName: String,
        storyIdeaID: ContentID? = nil,
        settingID: ContentID? = nil,
        companionID: ContentID? = nil,
        discoveryID: ContentID? = nil,
        seed: String,
        mode: StoryMode? = nil,
        ageBand: AgeBand? = nil,
        subOption: String? = nil,
        family: FamilyCast? = nil,
        interests: [InterestTag] = [],
        recent: [RecentContent] = [],
        usage: UsageProfile = .neutral,
        safety: ContentSafety? = nil,
        recentTitles: Set<String> = []
    ) {
        self.childName = childName
        self.storyIdeaID = storyIdeaID
        self.settingID = settingID
        self.companionID = companionID
        self.discoveryID = discoveryID
        self.seed = seed
        self.mode = mode
        self.ageBand = ageBand
        self.subOption = subOption
        self.family = family
        self.interests = interests
        self.recent = recent
        self.usage = usage
        self.safety = safety
        self.recentTitles = recentTitles
    }
}

extension OfflineStoryIntent {
    /// The same intent with one more axis pinned; every other field kept.
    func pinning(
        settingID: ContentID? = nil,
        companionID: ContentID? = nil,
        discoveryID: ContentID? = nil
    ) -> OfflineStoryIntent {
        OfflineStoryIntent(
            childName: childName,
            storyIdeaID: storyIdeaID,
            settingID: settingID ?? self.settingID,
            companionID: companionID ?? self.companionID,
            discoveryID: discoveryID ?? self.discoveryID,
            seed: seed,
            mode: mode,
            ageBand: ageBand,
            subOption: subOption,
            family: family,
            interests: interests,
            recent: recent,
            usage: usage,
            safety: safety,
            recentTitles: recentTitles
        )
    }
}

/// The content one earlier story was built from. Ids only: what the story
/// said, and who it was for, never reaches the selector.
public struct RecentContent: Sendable, Hashable {
    public let blueprintID: ContentID?
    public let settingID: ContentID?
    public let companionID: ContentID?
    public let discoveryID: ContentID?

    public init(
        blueprintID: ContentID? = nil,
        settingID: ContentID? = nil,
        companionID: ContentID? = nil,
        discoveryID: ContentID? = nil
    ) {
        self.blueprintID = blueprintID
        self.settingID = settingID
        self.companionID = companionID
        self.discoveryID = discoveryID
    }
}

// MARK: - Failure

/// Why nothing could be built.
///
/// Every case names the axis and carries the per-candidate reasons. This is the
/// direct replacement for `noBlueprintsFound`, a string that said only that
/// something was empty — and for `if filtered.isEmpty { return items }`, which
/// said nothing at all and shipped a dolphin into a forest.
public enum OfflineSelectionError: Error, Sendable, Equatable {
    case noBlueprints
    case noBlueprintForChoices(reasons: [String])
    case storyIdeaNotFound(id: ContentID)
    case noStoryIdeas
    case noSetting(reasons: [String])
    case noCompanion(reasons: [String])
    case noDiscovery(reasons: [String])
    case requestedContentRejected(id: ContentID, reason: String)
    case noTemplate(beat: StoryBeat, page: Int)
    case noVariantAfter(beat: StoryBeat?, page: Int)
    case noVariantForRole(role: CompanionRole?, beat: StoryBeat, page: Int)
    /// A family moment with no line for this relation. Carries the relation,
    /// never the name: the name is the parent's words and stays in the text.
    case noVariantForFamily(relation: FamilyRelationKind, beat: StoryBeat, page: Int)
    case noVariantSatisfying(constraint: String, beat: StoryBeat, page: Int)
    case blueprintNotBeatAuthored(id: ContentID)
    /// Katalogda karşılığı olmayan bir alt seçenek istendi.
    case unknownTopic(String)

    public var explanation: String {
        switch self {
        case .noBlueprints:
            return "No beat-authored blueprint exists."
        case .noBlueprintForChoices(let reasons):
            return "No blueprint fits these choices:\n" + reasons.joined(separator: "\n")
        case .storyIdeaNotFound(let id):
            return "Story idea '\(id.rawValue)' is not in the catalog."
        case .unknownTopic(let raw):
            return "Sub-option '\(raw)' is not a topic in this catalog."
        case .noStoryIdeas:
            return "The catalog offers no story ideas." 
        case .noSetting(let reasons):
            return "No setting fits this blueprint:\n" + reasons.joined(separator: "\n")
        case .noCompanion(let reasons):
            return "No companion fits this blueprint:\n" + reasons.joined(separator: "\n")
        case .noDiscovery(let reasons):
            return "No discovery fits this blueprint:\n" + reasons.joined(separator: "\n")
        case .requestedContentRejected(let id, let reason):
            return "'\(id.rawValue)' was asked for but cannot be used: \(reason)"
        case .noTemplate(let beat, let page):
            return "Page \(page) needs a template realizing '\(beat.rawValue)'; none exists."
        case .noVariantAfter(let beat, let page):
            return "Page \(page) has no line written to follow "
                + "'\(beat?.rawValue ?? "the opening")'. Authoring gap: every beat that can "
                + "precede this one needs a line, or one line with no ordering constraint."
        case .noVariantForRole(let role, let beat, let page):
            return "Page \(page) needs a '\(beat.rawValue)' line for a companion cast as "
                + "'\(role?.rawValue ?? "nothing")'. Authoring gap: every part a blueprint can "
                + "cast needs a line for this beat, or one line that names no part."
        case .noVariantForFamily(let relation, let beat, let page):
            return "Page \(page) needs a '\(beat.rawValue)' line for a Masal ailem character "
                + "who is '\(relation.rawValue)'. Authoring gap: a blueprint is only offered with "
                + "a relation every one of its family moments has a line for."
        case .noVariantSatisfying(let constraint, let beat, let page):
            return "Page \(page) has no '\(beat.rawValue)' line for \(constraint). Authoring "
                + "gap: relaxing it would contradict another page, so it is reported rather "
                + "than quietly dropped."
        case .blueprintNotBeatAuthored(let id):
            return "Blueprint '\(id.rawValue)' declares no beats and cannot be composed."
        }
    }
}

// MARK: - Binding

/// The content a blueprint was filled with.
public struct BoundContent: Sendable, Hashable {
    public let setting: CatalogSetting
    public let companion: CatalogCompanion
    public let discovery: CatalogObject
    /// The part the companion plays in *this* story.
    ///
    /// Resolved once, here, rather than page by page. A companion eligible for
    /// several parts must commit to one: picking per page would let the same
    /// character arrive trembling on page 3 and speak steadily on page 6, which
    /// is not a range, it is two characters. Nil only when nothing in the
    /// catalog casts — content that declares no parts.
    public let castRole: CompanionRole?

    public init(
        setting: CatalogSetting,
        companion: CatalogCompanion,
        discovery: CatalogObject,
        castRole: CompanionRole? = nil
    ) {
        self.setting = setting
        self.companion = companion
        self.discovery = discovery
        self.castRole = castRole
    }
}

/// Chooses content for a blueprint by trait intersection.
///
/// There is deliberately **no fallback**. If nothing is admissible the caller
/// gets a typed error listing why each candidate was rejected; it never gets an
/// arbitrary substitute that lets an incoherent story generate anyway.
public struct OfflineContentBinder: Sendable {
    public init() {}

    public func bind(
        blueprint: CatalogBlueprint,
        catalog: ContentCatalog,
        intent: OfflineStoryIntent,
        idea: CatalogStoryIdea? = nil
    ) throws -> BoundContent {
        // The idea constrains what may be bound, not only which blueprint is
        // chosen. Teaching the selector about ideas and not the binder produced
        // exactly the defect this guards: a card promising something that
        // signals bound a torn map, because the blueprint alone was happy with
        // it and nothing else was consulted.
        let requires = idea.map { blueprint.requires.combined(with: $0.requires) } ?? blueprint.requires
        let forbids = idea.map { blueprint.forbids.combined(with: $0.forbids) } ?? blueprint.forbids

        // Alt seçenek bir söz (`CatalogStoryTopic`): "Meslekler" denmişse masal
        // meslekle ilgili olmak zorunda. Bu yüzden burada süzgece dönüşüyor.
        //
        // Tanınmayan bir alt seçenek sessizce yok sayılmaz: yok sayılsaydı
        // uygulamadaki bir yazım hatası, söz verilmiş ama tutulmamış bir masal
        // üretirdi — ve hiç kimse bunu fark etmezdi. FAZ 10'dan beri alan hep
        // `nil` geldiği için reddetmenin kimseye bir bedeli yok.
        let topic = try intent.subOption.map { raw -> CatalogStoryTopic in
            guard let topic = catalog.storyTopic(ContentID(raw)) else {
                throw OfflineSelectionError.unknownTopic(raw)
            }
            return topic
        }

        // Habitat couples the axes, so binding one at a time in order is no
        // longer enough: a mountain admits no hedgehog, and a blueprint that
        // needs someone small and vulnerable then has nobody — even though a
        // garden would have worked. Greedy binding reported that as "no
        // companion", which is true and useless.
        //
        // So the setting is chosen with the rest in mind: candidates are tried
        // in their seeded order and the first that yields a whole binding wins.
        // Deterministic, and it degrades to the greedy behaviour whenever the
        // first candidate already works.
        // A place to sleep belongs to the bedtime arc and only to it, both ways
        // (`SettingTrait.isRestingPlace`). Filtered before ordering, so a
        // standard story sees exactly the settings — and the seeded order — it
        // saw before bedrooms existed.
        let wantsRest = blueprint.arc == .bedtime
        let arcSettings = catalog.settings.filter {
            $0.traits.contains(.isRestingPlace) == wantsRest
        }
        var settingFailure: Error?
        for candidate in try orderedCandidates(
            arcSettings, requested: intent.settingID, seed: intent.seed, axis: "setting",
            weight: weigher(intent, recent: \.settingID),
            offered: \.traits, required: requires.setting, forbidden: forbids.setting,
            empty: OfflineSelectionError.noSetting,
            also: {
                TraitMatch.thresholdRejection(
                    offered: $0.thresholdKinds, wanted: requires.thresholdKind)
                    ?? intent.safety?.rejection(of: $0)
                    ?? topic?.rejection(setting: $0)
            }
        ) {
            do {
                return try bindRest(
                    setting: candidate, catalog: catalog, intent: intent,
                    requires: requires, forbids: forbids, topic: topic)
            } catch {
                settingFailure = error
                continue
            }
        }
        throw settingFailure ?? OfflineSelectionError.noSetting(reasons: [])
    }

    /// Everything that depends on the setting once one is provisionally chosen.
    private func bindRest(
        setting: CatalogSetting,
        catalog: ContentCatalog,
        intent: OfflineStoryIntent,
        requires: ContentRequirements,
        forbids: ContentExclusions,
        topic: CatalogStoryTopic?
    ) throws -> BoundContent {
        let unusedSetting = try choose(
            [setting], requested: nil, seed: intent.seed, axis: "setting",
            offered: \.traits, required: requires.setting, forbidden: forbids.setting,
            empty: OfflineSelectionError.noSetting,
            also: {
                TraitMatch.thresholdRejection(
                    offered: $0.thresholdKinds, wanted: requires.thresholdKind)
                    ?? intent.safety?.rejection(of: $0)
            }
        )
        _ = unusedSetting
        // Habitat is checked after the setting is known and before anything else
        // is bound: a companion or a discovery that could not plausibly be here
        // is not a weaker choice, it is a different story. This is the axis that
        // used to be missing entirely — nothing stopped a dolphin in a forest.
        let companion = try choose(
            catalog.companions.filter {
                TraitMatch.sharesHabitat($0.habitat, setting: setting.habitat)
            },
            requested: intent.companionID, seed: intent.seed, axis: "companion",
            weight: weigher(intent, recent: \.companionID, learned: intent.usage.multiplier(companion:)),
            offered: \.traits, required: requires.companion, forbidden: forbids.companion,
            empty: OfflineSelectionError.noCompanion,
            // Casting is checked alongside capability rather than before it, so
            // "cannot be cast as needsCare" reaches the caller in the same list
            // as "offers forbidden canFly". Pre-filtering would have been
            // shorter and would have dropped the reason, which is the habit this
            // whole error type exists to break.
            also: { companion in
                if let reason = intent.safety?.rejection(of: companion) { return reason }
                if let reason = topic?.rejection(companion: companion) { return reason }
                if let reason = TraitMatch.castingRejection(
                    offered: companion.castRoles, casting: requires.casting) {
                    return reason
                }
                // Two characters with one name in one book is not a story the
                // child can follow: "Pamuk" the rabbit beside "Pamuk" the cat.
                // The reason names neither — the family name is the parent's.
                if let family = intent.family, Self.sameName(companion.name, family.name) {
                    return "shares its name with the Masal ailem character"
                }
                return nil
            }
        )
        // One part, chosen once. `sorted` is not cosmetic: `Set` iteration order
        // is not stable between runs, so picking from the raw set would make the
        // same intent produce different books.
        let castable = TraitMatch
            .castableRoles(offered: companion.castRoles, casting: requires.casting)
            .sorted { $0.rawValue < $1.rawValue }
        let castRole = castable.isEmpty
            ? nil
            : DeterministicPicker.pick(from: castable, seed: intent.seed, salt: "cast")
        let discovery = try choose(
            catalog.objects.filter {
                TraitMatch.sharesHabitat($0.habitat, setting: setting.habitat)
            },
            requested: intent.discoveryID, seed: intent.seed, axis: "discovery",
            weight: weigher(intent, recent: \.discoveryID),
            offered: \.traits, required: requires.discovery, forbidden: forbids.discovery,
            empty: OfflineSelectionError.noDiscovery,
            // A place that already accounts for the thing makes it not a
            // discovery. Checked here rather than on the setting axis because
            // the claim belongs to the object — the water does not know it
            // explains a flicker, but the flicker knows.
            also: { discovery in
                if let reason = intent.safety?.rejection(of: discovery) { return reason }
                if let reason = topic?.rejection(discovery: discovery) { return reason }
                let explained = discovery.explainedBy.intersection(setting.traits)
                guard !explained.isEmpty else { return nil }
                return "already explained by the setting ("
                    + explained.map(\.rawValue).sorted().joined(separator: ", ") + ")"
            }
        )
        return BoundContent(
            setting: setting, companion: companion, discovery: discovery, castRole: castRole)
    }

    /// Names compared the way a reader hears them: Turkish case folding, so
    /// "IŞIK" and "Işık" are one name and "Işık" and "İşık" are not.
    static func sameName(_ a: String, _ b: String) -> Bool {
        let locale = Locale(identifier: "tr_TR")
        return a.trimmingCharacters(in: .whitespaces).lowercased(with: locale)
            == b.trimmingCharacters(in: .whitespaces).lowercased(with: locale)
    }

    /// How much each record of one axis weighs for this intent (FAZ 12):
    /// interests raise it, the child's recent stories on this axis lower it.
    /// `learned` is what reading taught about this axis (FAZ 14); only
    /// companions have one today.
    private func weigher<Record: WeighedContent>(
        _ intent: OfflineStoryIntent,
        recent axis: KeyPath<RecentContent, ContentID?>,
        learned: ((ContentID) -> Double)? = nil
    ) -> (Record) -> Double {
        let wanted = Set(intent.interests)
        let recent = intent.recent.map { $0[keyPath: axis] }
        return { record in
            SelectionScoring.weight(
                id: record.id, matchesInterest: record.matches(wanted),
                cooldown: record.weights.cooldown, recent: recent,
                usage: learned?(record.id) ?? 1)
        }
    }

    /// Admissible records in the order the seed would pick them, so trying them
    /// in turn is still deterministic and still honours an explicit request.
    private func orderedCandidates<Record: Identifiable, Trait>(
        _ records: [Record],
        requested: ContentID?,
        seed: String,
        axis: String,
        weight: (Record) -> Double = { _ in 1 },
        offered: KeyPath<Record, Set<Trait>>,
        required: TraitRequirement<Trait>,
        forbidden: Set<Trait>,
        empty: ([String]) -> OfflineSelectionError,
        also: ((Record) -> String?)? = nil
    ) throws -> [Record] where Record.ID == ContentID {
        var reasons: [String] = []
        var admissible: [Record] = []

        func rejection(_ record: Record) -> String? {
            TraitMatch.rejection(
                offered: record[keyPath: offered], required: required, forbidden: forbidden
            ) ?? also?(record)
        }

        for record in records {
            if let reason = rejection(record) {
                reasons.append("  \(record.id.rawValue): \(reason)")
            } else {
                admissible.append(record)
            }
        }

        if let requested {
            if let match = admissible.first(where: { $0.id == requested }) { return [match] }
            let why = records.first(where: { $0.id == requested })
                .flatMap(rejection) ?? "no such \(axis)"
            throw OfflineSelectionError.requestedContentRejected(id: requested, reason: why)
        }

        guard !admissible.isEmpty else { throw empty(reasons) }
        return SelectionScoring.ordered(
            admissible, weights: admissible.map(weight), id: \.id, seed: seed, salt: axis)
    }

    /// One implementation for all three axes. Written generically on purpose:
    /// three hand-rolled copies is how the old code ended up filtering settings
    /// one way and companions another.
    private func choose<Record: Identifiable, Trait>(
        _ records: [Record],
        requested: ContentID?,
        seed: String,
        axis: String,
        weight: (Record) -> Double = { _ in 1 },
        offered: KeyPath<Record, Set<Trait>>,
        required: TraitRequirement<Trait>,
        forbidden: Set<Trait>,
        empty: ([String]) -> OfflineSelectionError,
        also: ((Record) -> String?)? = nil
    ) throws -> Record where Record.ID == ContentID {
        var reasons: [String] = []
        var admissible: [Record] = []

        func rejection(_ record: Record) -> String? {
            TraitMatch.rejection(
                offered: record[keyPath: offered], required: required, forbidden: forbidden
            ) ?? also?(record)
        }

        for record in records {
            if let reason = rejection(record) {
                reasons.append("  \(record.id.rawValue): \(reason)")
            } else {
                admissible.append(record)
            }
        }

        // An explicit request is honoured or explained — never silently swapped.
        if let requested {
            if let match = admissible.first(where: { $0.id == requested }) { return match }
            let why = records.first(where: { $0.id == requested })
                .flatMap(rejection) ?? "no such \(axis)"
            throw OfflineSelectionError.requestedContentRejected(id: requested, reason: why)
        }

        guard !admissible.isEmpty else { throw empty(reasons) }
        return SelectionScoring.ordered(
            admissible, weights: admissible.map(weight), id: \.id, seed: seed, salt: axis)[0]
    }
}

// MARK: - Determinism

/// Picks reproducibly from a list.
///
/// Seeded rather than random, because §17 requires the same intent to produce
/// the same book — a parent who regenerates after a crash should not get a
/// different story — and because a test cannot assert on `Int.random`.
public enum DeterministicPicker {
    public static func index(count: Int, seed: String, salt: String) -> Int {
        guard count > 1 else { return 0 }
        return Int(StableHash.hash([seed, salt]) % UInt64(count))
    }

    public static func pick<T>(from items: [T], seed: String, salt: String) -> T {
        items[index(count: items.count, seed: seed, salt: salt)]
    }

    /// The same draw, with the hash mixed first (FAZ 13).
    ///
    /// `index` reads the low bits of an FNV-1a hash, and those barely depend
    /// on the seed: every page of a story shares one of four low-bit states
    /// before its salt is hashed, so two stories land in the same state one
    /// time in four — and then pick the same line on *every* page. Standalone
    /// stories keep `index`, because changing it would rewrite every saved
    /// book. Series episodes, which are new, use this.
    public static func mixedIndex(count: Int, seed: String, salt: String) -> Int {
        guard count > 1 else { return 0 }
        return Int(SelectionScoring.mixed(StableHash.hash([seed, salt])) % UInt64(count))
    }
}
