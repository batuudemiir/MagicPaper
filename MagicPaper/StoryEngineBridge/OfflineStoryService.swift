import Foundation
import StoryEngine

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

        /// What to log.
        var detail: String {
            switch self {
            case .contentUnavailable(let detail), .noStoryForChoices(let detail): return detail
            }
        }
    }

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
            print("📚 \(result.report.summary)")
            return result.catalog
        } catch {
            throw Failure.contentUnavailable(detail: String(describing: error))
        }
    }

    var loadReport: CatalogLoadReport? { cachedReport }

    var catalogVersion: String { (try? catalog().version) ?? "unknown" }

    /// Bu yaştaki bir çocuğa gösterilecek fikirler.
    ///
    /// Süzgeç **geri açıldı**. Kapalıydı çünkü her fikir `5-6` bandındaydı ve
    /// tek bantlı bir katalogda süzmek yalnızca çıkarabilir: dört banttan üçü
    /// kartsız kalıyordu. 3-4 bandı yazılınca o öncül bozuldu — ve bozulduğunu
    /// söyleyen şey `AgeBandCoverageTests` oldu, bir insanın hatırlaması değil.
    ///
    /// Hiç içeriği olmayan bir bant için en yakın banda düşülüyor. Bu bir
    /// GEÇİCİ ÇÖZÜM ve öyle adlandırılıyor: 8-10 ve 11-12 için yazılmış hiçbir
    /// şey yok, ve bu bantları sunmaya devam eden profil ekranıdır. Boş bir ilk
    /// ekran bozuk bir uygulamadır; yaşı kayan bir masal ise bugün "Sürpriz"in
    /// zaten yaptığı şey. İkisi arasında seçim yapmak zorundayız ve ikincisi
    /// daha az kötü — ama sessiz kalmıyor.
    func storyIdeas(forAge age: Int) -> [CatalogStoryIdea] {
        guard let catalog = try? catalog() else { return [] }
        let matching = catalog.storyIdeas.filter { $0.suits(age: age) }
        guard matching.isEmpty else { return matching }

        // En yakın bant: bandın kendi yaşına uzaklığı.
        let nearest = catalog.storyIdeas.min { a, b in
            a.ageRange.distance(to: age) < b.ageRange.distance(to: age)
        }?.ageRange
        guard let nearest else { return catalog.storyIdeas }
        print("⚠️ \(age) yaşı için yazılmış hikâye fikri yok; \(nearest) bandına düşülüyor.")
        return catalog.storyIdeas.filter { $0.ageRange == nearest }
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
    func companionCandidates(forIdeaID ideaID: String?) -> [CatalogCompanion] {
        guard let catalog = try? catalog() else { return [] }
        let idea = ideaID.flatMap { id in catalog.storyIdeas.first { $0.id.rawValue == id } }
        return selector.companionCandidates(
            catalog: catalog,
            intent: OfflineStoryIntent(
                childName: "",
                storyIdeaID: idea?.id,
                seed: "candidates"
            ),
            idea: idea
        )
    }

    // MARK: - Composing

    /// Builds a story from the two choices the child made.
    ///
    /// - Parameter seed: supply one to rebuild an existing story exactly;
    ///   otherwise a fresh one is made and stored on the result, which is what
    ///   makes the story reproducible later. The previous implementation used
    ///   `UInt64.random` and kept it nowhere, so no story could ever be rebuilt.
    func compose(
        childName: String,
        ideaID: String?,
        companionID: String?,
        seed: String? = nil
    ) throws -> (story: ComposedStory, seed: String, catalogVersion: String) {
        let catalog = try catalog()
        let seed = seed ?? UUID().uuidString
        let intent = OfflineStoryIntent(
            childName: childName,
            storyIdeaID: ideaID.map { ContentID($0) },
            companionID: companionID.map { ContentID($0) },
            seed: seed
        )
        do {
            let composed = try composer.compose(catalog: catalog, intent: intent)
            return (composed, seed, catalog.version)
        } catch let error as OfflineSelectionError {
            // The full account goes to the log; the caller shows one sentence.
            throw Failure.noStoryForChoices(detail: error.explanation)
        } catch {
            throw Failure.noStoryForChoices(detail: String(describing: error))
        }
    }
}
