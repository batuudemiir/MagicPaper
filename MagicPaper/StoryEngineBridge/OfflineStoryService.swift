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

    private let selector = BlueprintSelector()
    private let composer = OfflineStoryComposer()

    private init() {}

    // MARK: - Content

    /// Loads once and keeps it. The catalog is authored, read-only and small.
    private func catalog() throws -> ContentCatalog {
        if let cached { return cached }
        do {
            let result = try ContentCatalogLoader().load()
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

    /// The band this child is served from.
    ///
    /// `AgeBandResolver` decides the child's band; if nothing is written for
    /// it yet, the nearest band that has content serves instead (younger on a
    /// tie). A TEMPORARY fallback, named as one: 7-8 and 9-10 have no content,
    /// and an empty first screen is a broken app.
    func servedBand(forAge age: Int) -> AgeBand {
        let requested = AgeBandResolver.band(forAge: age)
        guard let catalog = try? catalog() else { return requested }
        let authored = Set(catalog.blueprints.filter(\.isBeatAuthored).map(\.ageRange))
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
        return selector.availableModes(catalog: catalog, ageBand: servedBand(forAge: age))
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
                family: family.flatMap { familyCast(for: $0, in: catalog) }
            ),
            idea: idea
        )
    }

    // MARK: - Masal ailem (FAZ 11)

    /// The relations a Masal ailem character can have in a story of this mode
    /// for this child. A relation missing here is shown as unavailable.
    func availableFamilyRelations(mode: StoryMode?, age: Int) -> [FamilyRelationKind] {
        guard let catalog = try? catalog() else { return [] }
        return selector.availableFamilyRelations(
            catalog: catalog, mode: mode, ageBand: servedBand(forAge: age))
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
    ///   - subOption: a choice within the mode. Always nil today; the engine
    ///     carries it but does not read it.
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
        family: FamilyCharacter? = nil
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
                family: familyCast
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
