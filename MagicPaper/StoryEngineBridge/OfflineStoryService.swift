import Foundation
import OSLog
import StoryEngine

/// `print` reaches the shared device console verbatim. `Logger` redacts
/// interpolated values as `<private>` outside a debugger by default.
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "OfflineStoryService")

/// The app's door into the offline story engine.
///
/// Everything the new creation flow needs and nothing it does not: the ideas to
/// offer, the companions that fit the chosen idea, and one call that produces a
/// finished story. The engine's own types stay behind this seam — no view ever
/// sees a blueprint, a beat or a trait.
@MainActor
final class OfflineStoryService {

    static let shared = OfflineStoryService()

    /// Why the engine could not produce a story, in terms the caller can act on.
    ///
    /// Deliberately small. The engine's own errors carry a full account of which
    /// candidate was rejected and why; that belongs in the log, not on a screen
    /// in front of a parent (§29).
    enum Failure: Error {
        /// The content could not be loaded at all. The app has nothing to offer.
        case contentUnavailable(detail: String)
        /// Content loaded, but no story could be built from these choices.
        case noStoryForChoices(detail: String)
        /// A story was built, but its text has holes — a slot left unfilled or
        /// a suffix the renderer did not know — so it is not shown to a child.
        case defectiveDraft(detail: String)

        /// What to log.
        var detail: String {
            switch self {
            case .contentUnavailable(let detail),
                 .noStoryForChoices(let detail),
                 .defectiveDraft(let detail):
                return detail
            }
        }
    }

    /// How many fresh seeds a new story may try before a defective draft is
    /// reported. A different seed picks different sentence variants, which is
    /// usually enough to step around one broken variant; a hole that every
    /// variant shares will fail every attempt, and should.
    static let cleanDraftAttempts = 3

    private var cached: ContentCatalog?
    private var cachedReport: CatalogLoadReport?
    /// Interest coverage asks the binder about every tagged record; the answer
    /// only changes with the catalog, which is loaded once.
    private var cachedInterests: [InterestChoice]?

    private let selector = BlueprintSelector()
    private let composer = OfflineStoryComposer()

    private init() {}

    /// Etkin çocuğun içerik güvenliği ayarı (FAZ 17). Uygulama profil
    /// değişince kurar (`ContentView`); `nil` süzgeç yok demektir, testler ve
    /// profilsiz önizlemeler böyle çalışır. Her sorgu ve her masal bunu okur:
    /// ayarın boşalttığı mod gösterilmez, seçilen masal ayarı geçer.
    var currentSafety: ContentSafety?

    // MARK: - Content

    /// Loads once and keeps it. The catalog is authored, read-only and small.
    ///
    /// The bundle's, or a downloaded content package that passed every check
    /// (FAZ 15, `CatalogSourceResolver`). Decided once per launch: a package
    /// that arrives mid-session waits for the next one.
    private func catalog() throws -> ContentCatalog {
        if let cached { return cached }
        do {
            let result = try CatalogSourceResolver.forThisLaunch().resolve().result
            cached = result.catalog
            cachedReport = result.report
            logger.debug("📚 \(result.report.summary)")
            return result.catalog
        } catch {
            throw Failure.contentUnavailable(detail: String(describing: error))
        }
    }

    var loadReport: CatalogLoadReport? { cachedReport }

    var catalogVersion: String { (try? catalog().version) ?? "unknown" }

    // MARK: - Age

    /// İçeriğin gerçekten yazılmış olduğu bantlar, küçükten büyüğe.
    ///
    /// Katalogdan sayılır, elle yazılmaz: "3-6 yaş destekleniyor" bir ürün
    /// vaadi değil, bugünkü blueprint'lerin bir sonucu. 7-8 için ilk masal
    /// yazıldığı gün bu liste kendiliğinden büyür ve onu okuyan ekranlar da
    /// kendiliğinden büyür.
    ///
    /// Boş dönerse katalog okunamıyor demektir; çağıran bunu bir içerik hatası
    /// gibi değil, "henüz bilmiyorum" gibi ele almalı.
    func authoredBands() -> [AgeBand] {
        guard let catalog = try? catalog() else { return [] }
        let authored = Set(catalog.blueprints.filter(\.isBeatAuthored).map(\.ageRange))
        return AgeBandResolver.bands.filter(authored.contains)
    }

    /// The band this child is served from.
    ///
    /// `AgeBandResolver` decides the child's band; if nothing is written for
    /// it yet, the nearest band that has content serves instead (younger on a
    /// tie). A TEMPORARY fallback, named as one: 7-8 and 9-10 have no content,
    /// and an empty first screen is a broken app.
    ///
    /// Yaratma akışı bu düşmeye artık **girmiyor**: desteklenmeyen bir bantta
    /// masal yazdırmak yerine açıklayıcı bir durum gösteriyor (C turu, 21 Ekim
    /// 2026). Burası ana sayfa vitrini gibi "bir şey göstermek zorunda olan"
    /// yüzeyler için duruyor.
    func servedBand(forAge age: Int) -> AgeBand {
        let requested = AgeBandResolver.band(forAge: age)
        let authored = Set(authoredBands())
        guard let served = AgeBandResolver.servedBand(for: requested, available: authored) else {
            return requested
        }
        if served != requested {
            logger.warning("⚠️ \(requested) bandı için yazılmış içerik yok; \(served) bandından sunuluyor.")
        }
        return served
    }

    /// Every idea for this child's band, regardless of mode.
    func storyIdeas(forAge age: Int) -> [CatalogStoryIdea] {
        guard let catalog = try? catalog() else { return [] }
        let band = servedBand(forAge: age)
        return catalog.storyIdeas.filter { $0.ageRange == band }
    }

    // MARK: - Modes

    /// The modes a story can be built in for this child. A mode that cannot
    /// produce a story is not offered.
    func availableModes(forAge age: Int) -> [StoryMode] {
        guard let catalog = try? catalog() else { return [] }
        return selector.availableModes(catalog: catalog, ageBand: servedBand(forAge: age), safety: currentSafety)
    }

    /// Bu modun bu çocuğa gerçekten sunulabilecek alt kategorileri.
    ///
    /// Boş ya da tek öğeli dönebilir, ve bu normaldir: alt kategori bir söz
    /// (`CatalogStoryTopic`) olduğu için yalnızca kurulabildiği yerde teklif
    /// edilir. İçerik yazıldıkça liste kendiliğinden büyür — ekran tarafında
    /// değişecek bir şey yok.
    func topicChoices(forAge age: Int, mode: StoryMode) -> [StoryTopicChoice] {
        guard let catalog = try? catalog() else { return [] }
        let intent = OfflineStoryIntent(
            childName: "", seed: "topics", mode: mode,
            ageBand: servedBand(forAge: age), safety: currentSafety)
        return selector.availableTopics(catalog: catalog, intent: intent).map {
            StoryTopicChoice(id: $0.id.rawValue, name: $0.name, symbol: $0.symbol ?? "sparkles")
        }
    }

    /// The optional idea cards under a mode. Empty means the flow skips them.
    func storyIdeas(forAge age: Int, mode: StoryMode) -> [CatalogStoryIdea] {
        guard let catalog = try? catalog() else { return [] }
        return selector.storyIdeas(catalog: catalog, mode: mode, ageBand: servedBand(forAge: age))
    }

    /// Turns the parent's choice into a mode. For "surprise" this is where
    /// MagicPaper decides, looking at what this child read last.
    ///
    /// - Parameter recent: the child's recent modes, newest first.
    func resolveMode(
        strategy: StorySelectionStrategy,
        requested: StoryMode?,
        forAge age: Int,
        recent: [StoryMode],
        seed: String = UUID().uuidString
    ) throws -> StoryMode {
        do {
            return try StoryModeResolver().resolve(
                strategy: strategy,
                requested: requested,
                available: availableModes(forAge: age),
                recent: recent,
                seed: seed
            )
        } catch {
            throw Failure.noStoryForChoices(detail: "Mod çözülemedi: \(error)")
        }
    }

    func storyIdea(id: String) -> CatalogStoryIdea? {
        guard let catalog = try? catalog() else { return nil }
        return catalog.storyIdeas.first { $0.id.rawValue == id }
    }

    /// The companions worth offering, given the idea the child just chose.
    ///
    /// Empty only if the content is unloadable; an idea that can be offered can
    /// always be companioned, and the load-time integrity check is what keeps
    /// that true.
    func companionCandidates(
        forIdeaID ideaID: String?,
        mode: StoryMode? = nil,
        age: Int? = nil,
        family: FamilyCharacter? = nil
    ) -> [CatalogCompanion] {
        guard let catalog = try? catalog() else { return [] }
        let idea = ideaID.flatMap { id in catalog.storyIdeas.first { $0.id.rawValue == id } }
        return selector.companionCandidates(
            catalog: catalog,
            intent: OfflineStoryIntent(
                childName: "",
                storyIdeaID: idea?.id,
                seed: "candidates",
                mode: mode,
                ageBand: age.map(servedBand(forAge:)),
                family: family.flatMap { familyCast(for: $0, in: catalog) },
                safety: currentSafety
            ),
            idea: idea
        )
    }

    // MARK: - İlgi alanları (FAZ 12)

    /// The interest chips a parent is offered: the catalog's words that reach
    /// a story in every band with content. Catalog order.
    func interestChoices() -> [InterestChoice] {
        if let cachedInterests { return cachedInterests }
        guard let catalog = try? catalog() else { return [] }
        let choices = selector.availableInterests(catalog: catalog).map {
            InterestChoice(id: $0.id.rawValue, name: $0.name, symbol: $0.symbol)
        }
        cachedInterests = choices
        return choices
    }

    // MARK: - Masal ailem (FAZ 11)

    /// The relations a Masal ailem character can have in a story of this mode
    /// for this child. A relation missing here is shown as unavailable.
    func availableFamilyRelations(mode: StoryMode?, age: Int) -> [FamilyRelationKind] {
        guard let catalog = try? catalog() else { return [] }
        return selector.availableFamilyRelations(
            catalog: catalog, mode: mode, ageBand: servedBand(forAge: age), safety: currentSafety)
    }

    /// Kaçınılabilecek konular (31 · Güvenlik), katalog sırasıyla.
    func safetyTopics() -> [CatalogSafetyTopic] {
        (try? catalog())?.safetyTopics ?? []
    }

    /// A companion's catalog type ("tavşan"), for reading events (FAZ 14).
    func companionKind(id: String) -> String? {
        (try? catalog())?.companions.first { $0.id.rawValue == id }?.type
    }

    /// A companion's name ("Tarçın"), for the masal atölyesi cast line.
    func companionName(id: String) -> String? {
        (try? catalog())?.companions.first { $0.id.rawValue == id }?.name
    }

    /// The fixed list of animal kinds a pet can be, in catalog order.
    func familyAnimalKinds() -> [CatalogFamilyAnimalKind] {
        (try? catalog())?.familyAnimalKinds ?? []
    }

    /// The engine's view of a Masal ailem character. Nil for an animal whose
    /// kind the catalog no longer lists, which the engine would refuse anyway.
    func familyCast(for character: FamilyCharacter, in catalog: ContentCatalog) -> FamilyCast? {
        var kind: CatalogFamilyAnimalKind?
        if let kindID = character.relation.animalKindID {
            guard let found = catalog.familyAnimalKind(ContentID(kindID)) else { return nil }
            kind = found
        }
        return FamilyCast(name: character.name, relation: character.relation.kind, animalKind: kind)
    }

    // MARK: - Composing

    /// Builds a story from the parent's choices.
    ///
    /// - Parameters:
    ///   - mode: the resolved intent. Nil admits every family, which is how
    ///     stories were built before modes existed.
    ///   - age: the child's age; the story is written for its served band. Nil
    ///     admits every band.
    ///   - subOption: alt kategori kimliği (`CatalogStoryTopic`). Verilirse
    ///     bağlayıcıda süzgeçtir: konuyu taşımayan içerik seçilmez ve hiçbir
    ///     şey kurulamazsa masal üretilmez (söz, tat değil). Katalogda
    ///     karşılığı olmayan bir kimlik reddedilir.
    ///   - usage: how this child read their stories (FAZ 14); what they
    ///     re-read weighs more, what they left weighs less. Not stored either.
    ///   - interests, recent: weigh the choice (FAZ 12). Neither is stored on
    ///     the story, so a rebuild by seed reproduces the book only with the
    ///     same interests and history it was written with. No caller rebuilds
    ///     today; whoever adds one decides whether to store them (FAZ 13).
    ///   - seed: supply one to rebuild an existing story exactly; otherwise a
    ///     fresh one is made and stored on the result, which is what makes the
    ///     story reproducible later. The previous implementation used
    ///     `UInt64.random` and kept it nowhere, so no story could ever be rebuilt.
    func compose(
        childName: String,
        ideaID: String?,
        companionID: String?,
        mode: StoryMode? = nil,
        age: Int? = nil,
        seed: String? = nil,
        subOption: String? = nil,
        family: FamilyCharacter? = nil,
        interests: [String] = [],
        recent: [StoryOrigin] = [],
        usage: [StoryUsage] = [],
        recentTitles: Set<String> = []
    ) throws -> (story: ComposedStory, seed: String, catalogVersion: String) {
        let catalog = try catalog()
        let familyCast = try family.map { character -> FamilyCast in
            guard let cast = self.familyCast(for: character, in: catalog) else {
                // The relation, never the name.
                throw Failure.noStoryForChoices(
                    detail: "Masal ailem hayvan türü katalogda yok (\(character.relation.kind.rawValue))")
            }
            return cast
        }
        // A supplied seed is a rebuild: it must produce that story or nothing,
        // so it gets exactly one attempt.
        // Only what the parent is offered today reaches the engine: a stored
        // word the catalog stopped offering is kept on the profile, not used.
        let wanted = ChildInterests.offered(interests, from: interestChoices()).map { InterestTag($0) }
        let history: [RecentContent] = recent
            .prefix(SelectionScoring.cooldownWindow)
            .map { origin -> RecentContent in
                // D2: eski masallarda satır kimliği yok, ve olmaması seçimi
                // etkilemiyor — boş küme "geçmiş yok" demekle aynı.
                let lines = Set((origin.variantIDs ?? []).map { ContentID($0) })
                return RecentContent(
                    blueprintID: ContentID(origin.blueprintID),
                    settingID: ContentID(origin.settingID),
                    companionID: ContentID(origin.companionID),
                    discoveryID: ContentID(origin.discoveryID),
                    variantIDs: lines)
            }
        let learned = UsageLearner.profile(from: usage, catalog: catalog)
        let seeds = seed.map { [$0] }
            ?? (0..<Self.cleanDraftAttempts).map { _ in UUID().uuidString }

        var defects: [String] = []
        for seed in seeds {
            let intent = OfflineStoryIntent(
                childName: childName,
                storyIdeaID: ideaID.map { ContentID($0) },
                companionID: companionID.map { ContentID($0) },
                seed: seed,
                mode: mode,
                ageBand: age.map(servedBand(forAge:)),
                subOption: subOption,
                family: familyCast,
                interests: wanted,
                recent: Array(history),
                usage: learned,
                safety: currentSafety,
                recentTitles: recentTitles
            )
            let composed: ComposedStory
            do {
                composed = try composer.compose(catalog: catalog, intent: intent)
            } catch let error as OfflineSelectionError {
                // The full account goes to the log; the caller shows one sentence.
                throw Failure.noStoryForChoices(detail: error.explanation)
            } catch {
                throw Failure.noStoryForChoices(detail: String(describing: error))
            }

            // The gate between the engine and a child. Nothing that failed
            // `isClean` is returned, whatever else is true of it.
            if composed.isClean {
                return (composed, seed, catalog.version)
            }
            defects.append(Self.defectReport(composed))
        }
        throw Failure.defectiveDraft(detail: defects.joined(separator: " | "))
    }

    // MARK: - Series (FAZ 13)

    /// Whether a story of this mode and band, set in this place, could be
    /// continued at all: some continuation serves it. A story that opened in a
    /// bedroom (uyku arkı, 21 Ekim 2026) continues only with bedtime-arc
    /// episodes. Cheap; the plan itself is made on "Devam ettir".
    func seriesAvailable(mode: StoryMode, band: AgeBand, settingID: String) -> Bool {
        guard let catalog = try? catalog() else { return false }
        return SeriesPlanner.isAvailable(
            settingID: ContentID(settingID), mode: mode, band: band, catalog: catalog)
    }

    /// Plans a series from a saved story's origin and writes its four episodes.
    ///
    /// The band is the one the first story was written for, not the child's
    /// age today: the series continues that book. Every episode must be clean,
    /// like any story shown to a child.
    func planSeries(
        from origin: StoryOrigin,
        childName: String,
        family: FamilyCharacter?
    ) throws -> (plan: SeriesPlan, episodes: [ComposedStory]) {
        let catalog = try catalog()
        guard let mode = origin.mode, let bandID = origin.ageBand, let band = AgeBand(bandID) else {
            throw Failure.noStoryForChoices(detail: "origin has no mode or band")
        }
        let cast = family.flatMap { familyCast(for: $0, in: catalog) }
        let anchor = SeriesAnchor(
            settingID: ContentID(origin.settingID),
            companionID: ContentID(origin.companionID),
            keepsakeID: ContentID(origin.discoveryID))
        do {
            let result = try SeriesPlanner().plan(
                anchor: anchor, mode: mode, band: band, family: cast,
                familyCharacterID: cast == nil ? nil : family?.id.uuidString,
                childName: childName,
                seed: SeriesPlanner.seed(storySeed: origin.seed, fingerprint: origin.fingerprint),
                catalog: catalog, safety: currentSafety)
            try Self.requireClean(result.episodes)
            return (result.plan, result.episodes)
        } catch let error as SeriesPlanningError {
            throw Failure.noStoryForChoices(detail: error.description)
        }
    }

    /// Writes every episode of a plan again (a plan whose Masal ailem
    /// character was removed composes without it).
    func composeSeries(_ plan: SeriesPlan, childName: String, family: FamilyCharacter?) throws -> [ComposedStory] {
        let catalog = try catalog()
        let cast = family.flatMap { familyCast(for: $0, in: catalog) }
        do {
            let episodes = try SeriesPlanner().compose(plan, childName: childName, family: cast, catalog: catalog)
            try Self.requireClean(episodes)
            return episodes
        } catch let error as SeriesPlanningError {
            throw Failure.noStoryForChoices(detail: error.description)
        } catch let error as OfflineSelectionError {
            throw Failure.noStoryForChoices(detail: error.explanation)
        }
    }

    private static func requireClean(_ episodes: [ComposedStory]) throws {
        let defects = episodes.filter { !$0.isClean }.map(defectReport)
        guard defects.isEmpty else { throw Failure.defectiveDraft(detail: defects.joined(separator: " | ")) }
    }

    /// What was wrong with a draft, for the log. Names content ids, slot names
    /// and suffix spellings — never the page text, which carries the child's
    /// name.
    static func defectReport(_ composed: ComposedStory) -> String {
        let pages = composed.pages.enumerated().compactMap { index, page -> String? in
            guard !page.missingSlots.isEmpty || !page.unrecognisedSuffixes.isEmpty else { return nil }
            var parts: [String] = []
            if !page.missingSlots.isEmpty {
                parts.append("missing slots \(page.missingSlots)")
            }
            if !page.unrecognisedSuffixes.isEmpty {
                parts.append("unknown suffixes \(page.unrecognisedSuffixes)")
            }
            return "page \(index + 1) [\(page.variantIDs.map(\.rawValue).joined(separator: ","))]: "
                + parts.joined(separator: ", ")
        }
        return "blueprint \(composed.blueprintID.rawValue): " + pages.joined(separator: "; ")
    }
}
