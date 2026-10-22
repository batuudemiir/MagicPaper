import Foundation
import StoryEngine

// MARK: - Vocabulary the screens may use

/// The engine's value vocabulary, named in the app module so the creation
/// screens can speak it without `import StoryEngine`.
///
/// These are plain values — a mode, a band, how a choice was made — and the
/// product talks in them. What the screens must not see is the machinery
/// (catalog records, traits, blueprints, the provider), and that is what the
/// seam below keeps out.
typealias StoryMode = StoryEngine.StoryMode
typealias StorySelectionStrategy = StoryEngine.StorySelectionStrategy
typealias AgeBand = StoryEngine.AgeBand
typealias AgeBandResolver = StoryEngine.AgeBandResolver

// MARK: - What a screen shows

/// One idea card, as the idea step draws it.
///
/// Carries display text and a stable id, nothing else. `CatalogStoryIdea`
/// also carries the traits and affinities the selector casts with; a view that
/// can read those can start making casting decisions, which is the engine's job.
struct StoryIdeaChoice: Identifiable, Hashable {
    /// Stable content id, handed back to the source when the story is built.
    let id: String
    let title: String
    let detail: String
    /// SF Symbol name.
    let symbol: String
}

/// Modun içindeki bir alt kategori, adım 2'nin çizdiği hâliyle.
///
/// `CatalogStoryTopic`'in ekrana düşen yarısı: kimlik, ad, simge. Konunun
/// hangi yuvada hangi sözcüğü şart koştuğu motorun işi — ekranın onu bilmesi,
/// ekranın süzme kararı vermeye başlaması demek olurdu.
struct StoryTopicChoice: Identifiable, Hashable {
    /// Stable content id, handed back to the source when the story is built.
    let id: String
    let name: String
    /// SF Symbol name.
    let symbol: String
}

/// One animal kind a Masal ailem pet can be — "kedi", "köpek".
struct FamilyAnimalKindChoice: Identifiable, Hashable {
    let id: String
    let name: String
}

/// One companion tile, as the companion step draws it.
struct CompanionChoice: Identifiable, Hashable {
    /// Stable content id, handed back to the source when the story is built.
    let id: String
    let name: String
    /// What the companion is — "tilki", "baykuş". Drives the tile's symbol.
    let kind: String
    /// The companion's own line; empty when content has none.
    let personality: String
}

// MARK: - The seam

/// Everything the creation flow asks of a story source before a story exists.
///
/// The flow used to call `OfflineStoryService` by name and read catalog
/// records directly, so the screens knew which provider was writing the story
/// (D1). Behind this protocol the provider can change — the illustrated path
/// will put a different one here — without a screen changing with it.
///
/// Building the story itself stays with `StoryGenerationManager.createStory`,
/// which saves it; this is only the part that happens while the parent chooses.
@MainActor
protocol StoryChoiceSource {
    /// Masal yazılmış yaş bantları, küçükten büyüğe.
    ///
    /// Ekranlar "hangi yaşlar destekleniyor" sorusunu buradan sorar, kendi
    /// listesini tutmaz: desteklenen bant bir ürün vaadi değil, içeriğin
    /// bugünkü hâli. Boş liste "henüz bilmiyorum" demektir (katalog
    /// okunamadı), "hiçbir yaş desteklenmiyor" demek değil.
    func authoredBands() -> [AgeBand]
    /// The modes that have something to offer a child of this age.
    func availableModes(forAge age: Int) -> [StoryMode]
    /// Bu modun alt kategorileri. Boş ya da tek öğeliyse akış adımı atlar.
    func topicChoices(forAge age: Int, mode: StoryMode) -> [StoryTopicChoice]
    /// The idea cards for a mode, in the order they should be shown.
    func ideaChoices(forAge age: Int, mode: StoryMode) -> [StoryIdeaChoice]
    /// The companions that fit the chosen idea, best first.
    func companionChoices(forIdeaID ideaID: String?, mode: StoryMode?, age: Int?) -> [CompanionChoice]
    /// The companions, when a Masal ailem character comes along too: a
    /// companion with the character's name is not offered beside them.
    func companionChoices(
        forIdeaID ideaID: String?, mode: StoryMode?, age: Int?, family: FamilyCharacter?
    ) -> [CompanionChoice]
    /// Masal ailem relations a story of this mode can carry for this child.
    func availableFamilyRelations(mode: StoryMode?, age: Int) -> [FamilyRelationKind]
    /// The animal kinds a Masal ailem pet can be.
    func familyAnimalKindChoices() -> [FamilyAnimalKindChoice]
    /// The "Neleri sever?" chips a parent is offered (FAZ 12).
    func interestChoices() -> [InterestChoice]
    /// Turns "surprise me" (or a direct choice) into one concrete mode.
    func resolveMode(
        strategy: StorySelectionStrategy,
        requested: StoryMode?,
        forAge age: Int,
        recent: [StoryMode]
    ) throws -> StoryMode
}

/// The source the creation flow uses. The one place that names a provider.
@MainActor
enum StoryChoiceSources {
    static var current: any StoryChoiceSource { OfflineStoryService.shared }
}

/// What to log when a source or the build fails.
///
/// §29: the parent sees one sentence; the log gets the account. Callers used to
/// cast to `OfflineStoryService.Failure` themselves, which is the provider's
/// name leaking into a screen through its error type.
func storyFailureDetail(_ error: Error) -> String {
    (error as? OfflineStoryService.Failure)?.detail ?? String(describing: error)
}

/// Why a story could not be written, as far as the parent needs to know (43).
///
/// Only one reason is worth telling apart: the parent's content safety
/// setting (FAZ 17) left nothing to tell. Everything else is one calm
/// sentence; the detail goes to the log.
enum StoryFailureReason: Equatable {
    case general
    /// The safety setting ruled out every story for these choices.
    case safetySetting

    init(_ error: Error) {
        let detail = storyFailureDetail(error)
        // The engine's rejection reasons for a safety rule (`ContentSafety`,
        // `OfflineStoryComposer.pool`) all name the parent's setting.
        self = Self.safetyMarkers.contains(where: detail.contains) ? .safetySetting : .general
    }

    static let safetyMarkers = ["which the parent avoids", "the parent chose calm stories",
                                "clear of the topics the parent avoids", "carries a topic the parent avoids"]

    /// The sentence under the title. Never blames the child.
    var message: String {
        switch self {
        case .general:
            return "Bir şeyler yolunda gitmedi ama sorun sende değil. Tekrar deneyelim mi?"
        case .safetySetting:
            return "Bu seçimlerle, güvenlik ayarlarına uyan bir masal bulunamadı. Başka bir masal türü deneyebilirsin; ayarlara bir büyüğün bakması da olur."
        }
    }
}

// MARK: - The offline engine behind it

extension OfflineStoryService: StoryChoiceSource {

    func ideaChoices(forAge age: Int, mode: StoryMode) -> [StoryIdeaChoice] {
        storyIdeas(forAge: age, mode: mode).map(StoryIdeaChoice.init)
    }

    /// The service's own `resolveMode` also takes a `seed` for tests; a
    /// defaulted parameter does not satisfy a requirement, so this forwards.
    func resolveMode(
        strategy: StorySelectionStrategy,
        requested: StoryMode?,
        forAge age: Int,
        recent: [StoryMode]
    ) throws -> StoryMode {
        try resolveMode(
            strategy: strategy, requested: requested, forAge: age,
            recent: recent, seed: UUID().uuidString)
    }

    func companionChoices(forIdeaID ideaID: String?, mode: StoryMode?, age: Int?) -> [CompanionChoice] {
        Self.drawable(companionCandidates(forIdeaID: ideaID, mode: mode, age: age).map(CompanionChoice.init))
    }

    func companionChoices(
        forIdeaID ideaID: String?, mode: StoryMode?, age: Int?, family: FamilyCharacter?
    ) -> [CompanionChoice] {
        Self.drawable(companionCandidates(forIdeaID: ideaID, mode: mode, age: age, family: family)
            .map(CompanionChoice.init))
    }

    /// Ekranda ayırt edilebilen arkadaşlar (21 Ekim 2026).
    ///
    /// "Kim gelsin?" ekranı resimle seçtiriyor ve beş yaşındaki çocuk resme
    /// bakarak seçiyor. Bu yüzden ekranın tek kuralı var: **bir resim bu
    /// ekranda en çok bir kez görünür.** Aynı resmi taşıyan ikinci aday
    /// teklif edilmez.
    ///
    /// Havuz A turunda diriltilince kural iki yerden birden kırıldı: beş yeni
    /// tür aynı pati ikonuna düştü (iOS'un simge kümesinde kirpi, sincap,
    /// penguen ve kurbağa yok), köpek de tilkinin ikonuna oturdu — tilki
    /// simgesi de yok. Beş farklı hayvanı tek resimle göstermek seçimi seçim
    /// olmaktan çıkarır; "Cesur (köpek)" ile "Tarçın (tilki)" yan yana iki
    /// özdeş karttır.
    ///
    /// Süzülen tür **motorun havuzunda kalır** — masalda çıkmaya devam eder,
    /// yalnızca karttan seçilemez. Yani bu bir içerik eksiltmesi değil,
    /// ekranın okunabilirliği.
    ///
    /// Doğru çözüm bu süzgeç değil, o türler için çizim. Geldiğinde
    /// `CompanionStep.symbol(forType:)`'a eklenir ve burası kendiliğinden
    /// onları teklif etmeye başlar.
    static func drawable(_ choices: [CompanionChoice]) -> [CompanionChoice] {
        var shown: Set<String> = []
        return choices.filter { shown.insert(CompanionStep.symbol(forType: $0.kind)).inserted }
    }

    func familyAnimalKindChoices() -> [FamilyAnimalKindChoice] {
        familyAnimalKinds().map { FamilyAnimalKindChoice(id: $0.id.rawValue, name: $0.name) }
    }
}

extension StoryIdeaChoice {
    init(_ idea: CatalogStoryIdea) {
        self.init(
            id: idea.id.rawValue,
            title: idea.display,
            detail: idea.supportingText,
            symbol: idea.illustration
        )
    }
}

extension CompanionChoice {
    init(_ companion: CatalogCompanion) {
        self.init(
            id: companion.id.rawValue,
            name: companion.name,
            kind: companion.type,
            personality: companion.personality
        )
    }
}
