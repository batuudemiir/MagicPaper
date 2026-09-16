import SwiftUI

/// Okuma ilerlemesini nereye yazacağını bilen şey.
///
/// Protokol, testler için: sayfa çevirme mantığı `UserDefaults`'a dokunmadan
/// doğrulanabilsin diye. Yeni bir kalıcılık katmanı değil — tek gerçek
/// uygulama `StoryGenerationManager`'a gider, ki masalların tek sahibi odur.
@MainActor
protocol ReaderProgressStore {
    func saveProgress(storyID: UUID, page: Int)
}

/// Gerçek kalıcılık: mevcut yönetici, mevcut anahtar.
@MainActor
struct LiveReaderProgressStore: ReaderProgressStore {
    func saveProgress(storyID: UUID, page: Int) {
        StoryGenerationManager.shared.updateLastReadPage(storyId: storyID, page: page)
    }
}

/// Okuyucunun bütün durumu ve bütün sayfa mantığı.
///
/// İçinde ne SwiftUI ne UIKit var, ve bu kasıtlı: sayfa geçişiyle ilgili her
/// kural burada yaşadığı için düz bir birim testiyle doğrulanabiliyor. Sınır,
/// animasyonla boğuşan UI testleri yazmakla düz assert'ler yazmak arasındaki
/// fark.
@MainActor
final class StoryReaderModel: ObservableObject {

    let story: ReaderStory

    /// Hangi yapraktayız — kapanış yaprağı dâhil.
    @Published private(set) var leafIndex: Int

    /// Kontroller görünür mü (§10).
    @Published var controlsVisible: Bool = true

    /// Masal bir kez sonuna kadar gidildi mi?
    @Published private(set) var hasReachedEnding: Bool = false

    /// Bu oturumda ulaşılan en ileri sayfa.
    ///
    /// Modelin kendisinde tutulur çünkü eski okuyucu bunu her seferinde
    /// sunum anında kopyalanan `let story: Story` değerinden okuyordu — o değer
    /// hiç değişmediği için "ilerleme geri gitmez" kuralı yalnızca *açılış*
    /// sayfasına kadar koruyordu. Geri sayfalayıp çıkan biri ilerlemesini
    /// kaybediyordu.
    private(set) var furthestPageReached: Int

    private let progressStore: ReaderProgressStore
    /// En son diske yazılan değer — aynı sayfayı iki kez yazmamak için.
    private var lastPersistedPage: Int

    init(
        story: ReaderStory,
        startingAt requestedPage: Int? = nil,
        savedPage: Int? = nil,
        // Varsayılan argümanlar aktör bağlamının dışında değerlendirildiği
        // için burada `LiveReaderProgressStore()` yazılamaz; `nil` gelirse
        // init'in kendi @MainActor gövdesinde kurulur.
        progressStore: ReaderProgressStore? = nil
    ) {
        self.story = story
        self.progressStore = progressStore ?? LiveReaderProgressStore()

        // Bozuk ya da aralık dışı kayıtlı veri geçerli bir sayfada açılır,
        // çökmez (§25).
        let openingPage = StoryReaderModel.clamp(
            requestedPage ?? savedPage ?? 0,
            pageCount: story.pageCount
        )
        // Hiç okunmamış masal kapaktan açılır — kitap da kapağından açılır.
        // Devam eden okuma kaldığı sayfadan açılır, kapağı tekrar göstermez.
        let resumes = requestedPage != nil || savedPage != nil
        self.leafIndex = resumes ? story.leafIndex(forPage: openingPage) : 0
        self.furthestPageReached = openingPage
        // Kayıtlı ilerleme yoksa -1: ilk gerçek sayfa (0) da bir yazım sayılsın.
        //
        // `openingPage` ile başlatmak, bir masalın YALNIZCA ilk sayfasını okuyan
        // çocuğu hiç okumamış gibi gösteriyordu: 0 == 0 olduğu için kayıt
        // atlanıyor, masal sonsuza dek "Yeni" kalıyordu. Bir kitabı açıp ilk
        // sayfasını okumak, o kitabı açmamış olmakla aynı şey değildir.
        self.lastPersistedPage = savedPage ?? -1

        // Sayfası olmayan masal doğrudan kapanış yaprağında açılır.
        if story.isEmpty {
            self.hasReachedEnding = true
        }
    }

    // MARK: - Nerede olduğumuz

    /// Şu anki yaprak.
    var currentLeaf: ReaderLeaf {
        guard story.leaves.indices.contains(leafIndex) else { return .ending }
        return story.leaves[leafIndex]
    }

    /// Şu anki masal sayfası. Kapanış yaprağındaysak `nil`.
    var currentPage: ReaderPage? { currentLeaf.page }

    /// "3 / 8" — yalnızca gerçek bir sayfadayken.
    var folio: String? {
        guard let page = currentPage else { return nil }
        return "\(page.index + 1) / \(story.pageCount)"
    }

    var leafCount: Int { story.leaves.count }

    var canGoNext: Bool { leafIndex < leafCount - 1 }
    var canGoPrevious: Bool { leafIndex > 0 }

    var isOnEndingLeaf: Bool { currentLeaf.isEnding }

    // MARK: - Gezinme

    /// Sonraki yaprak. Sınırdaysa hiçbir şey yapmaz ve `false` döner —
    /// "son sayfadan ileri gidilemez" (§25) tam olarak bu.
    @discardableResult
    func next() -> Bool {
        guard canGoNext else { return false }
        move(to: leafIndex + 1)
        return true
    }

    /// Önceki yaprak. İlk sayfada hiçbir şey yapmaz.
    @discardableResult
    func previous() -> Bool {
        guard canGoPrevious else { return false }
        move(to: leafIndex - 1)
        return true
    }

    /// Programlı gezinme. Aralık dışı istekler sessizce reddedilir.
    @discardableResult
    func go(toLeaf index: Int) -> Bool {
        guard story.leaves.indices.contains(index), index != leafIndex else { return false }
        move(to: index)
        return true
    }

    /// Masalı baştan aç — kapanış yaprağındaki "Tekrar oku".
    /// Masalı baştan aç — kapak varsa kapaktan.
    func restart() {
        move(to: 0)
    }

    /// UIKit sayfa denetleyicisi kendi jestiyle sayfayı çevirdiğinde çağrılır.
    /// Modeli takip ettirir, ama geri dönüp denetleyiciyi tekrar sürmez.
    func syncFromPageController(leafIndex index: Int) {
        guard story.leaves.indices.contains(index), index != leafIndex else { return }
        move(to: index)
    }

    private func move(to index: Int) {
        leafIndex = index

        if let page = currentPage {
            furthestPageReached = max(furthestPageReached, page.index)
        }

        if currentLeaf.isEnding, !hasReachedEnding {
            hasReachedEnding = true
            // Kapanışa varmak masalın bittiği andır: ilerleme son sayfaya
            // sabitlenir ki kütüphane "bitti" desin.
            furthestPageReached = max(furthestPageReached, story.pageCount - 1)
        }
    }

    // MARK: - Kalıcılık

    /// İlerlemeyi yazar.
    ///
    /// Her karede değil, sayfa yerine oturduğunda, okuyucu kapandığında ve
    /// uygulama arka plana geçtiğinde. Her çevirmede yazmak bütün `[Story]`
    /// dizisini yeniden JSON'a çevirmek demek — `StoryGenerationManager` 1 MB
    /// üzerinde kendi kendini uyarıyor — ve parmağı takip eden bir çevirmede
    /// bu baskı yalnızca artar.
    func persistProgress() {
        guard !story.isEmpty else { return }
        let page = clampedFurthest
        guard page != lastPersistedPage else { return }
        lastPersistedPage = page
        progressStore.saveProgress(storyID: story.id, page: page)
    }

    /// Kapanış yaprağı ilerleme değildir: masalın son sayfasından ileri
    /// bir sayfa numarası kaydedilmez.
    private var clampedFurthest: Int {
        StoryReaderModel.clamp(furthestPageReached, pageCount: story.pageCount)
    }

    // MARK: - Kontroller

    func toggleControls() {
        controlsVisible.toggle()
    }

    func hideControls() {
        guard controlsVisible else { return }
        controlsVisible = false
    }

    // MARK: -

    static func clamp(_ page: Int, pageCount: Int) -> Int {
        guard pageCount > 0 else { return 0 }
        return min(max(page, 0), pageCount - 1)
    }
}
