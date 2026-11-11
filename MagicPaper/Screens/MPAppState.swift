import Combine
import SwiftUI

// MARK: - Uygulama durumu

/// Oturumluk uygulama durumu: okuyucu, masal yazma, akşam akışı, bildirim.
/// Kalıcı veri mevcut servislerde kalır. Gezinme `router`'da (`docs/ARCHITECTURE.md`).
@MainActor
final class MPAppState: ObservableObject {

    /// Sekme, yığın, sheet ve ebeveyn odası. Görünümler `app.router` ile okur;
    /// değişiklikleri buradan da yayınlanır, böylece mevcut gözlemciler güncellenir.
    var router = MPRouter()
    private var routerChanges: AnyCancellable?

    init() {
        routerChanges = router.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    // Tam ekran yollar
    /// The new two-choice creation flow.
    @Published var showStoryCreation = false
    /// A mode chosen on the home screen; the flow then opens at "Masalda
    /// kimler olsun?". Nil opens it at the modes. Cleared when the flow closes.
    @Published var creationPreset: StoryMode?
    /// 14 · "Bu karakterle masal yaz": a Masal ailem character already chosen.
    @Published var creationFamilyID: UUID?

    @Published var showPaywall = false
    @Published var readerStory: Story?
    /// Okuyucu kitaplıktaki bu kapaktan açıldı: kapaktan büyüyerek gelir
    /// (Faz 13). Başka yerden açılınca nil, olağan geçiş.
    var readerZoomID: UUID?
    /// Okuyucu hangi sayfadan açılsın; `nil` kaldığı yerden.
    @Published var readerStartPage: Int?
    /// 17 · Masal aksiyonları: kitaplıkta kapağa dokununca açılan sayfa.
    @Published var actionsStory: Story?
    /// Sayfa kapanınca açılacak masal (sayfa ile okuyucu aynı anda açılamaz).
    var pendingRead: (story: Story, startPage: Int?)?
    /// Okuyucu kapanınca yapılacak iş (masal sonu: "Bir masal daha", "İyi geceler").
    enum AfterReader { case create, sleep(Story) }
    var afterReader: AfterReader?
    /// 26 · Uyku modu (v2, `MPFeatures.sleepMode`).
    @Published var sleepSession: MPSleepSession?
    /// Uyku saatinde akşam kartının açtığı "Uyku masalı yaz" penceresi.
    /// Yalnızca karta dokununca açılır, kendiliğinden gelmez (15 Ekim 2026).
    @Published var showBedtimeSheet = false
    /// Pencerede seçilen yol: pencere kapandıktan sonra açılır (bir sayfa
    /// açıkken tam ekran sunum açılamaz).
    var pendingBedtimeChoice: BedtimeChoice?

    /// Okuyucu kapandıktan sonra (iki tam ekran sunum üst üste açılamaz).
    func runAfterReader() {
        noteFirstFinishedStory()
        guard let next = afterReader else { return }
        afterReader = nil
        switch next {
        case .create: startStoryCreation()
        case .sleep(let story):
            MPBedtimeRoutine.shared.mark(.light, for: ProfileManager.shared.currentProfile?.id)
            sleepSession = MPSleepSession(story: story)
        }
    }

    /// İlk biten masaldan sonra (Faz 8): "önce masal" sırası girişe geçer ve
    /// hatırlatma bir kez, değeri görüldükten sonra sorulur. Okuyucudan sonra
    /// başka bir iş varsa ("Bir masal daha") soru bekler.
    private func noteFirstFinishedStory() {
        let profile = ProfileManager.shared.currentProfile
        guard StoryGenerationManager.shared.stories.contains(where: { $0.isFinished && $0.belongs(to: profile) })
        else { return }
        UserDefaults.standard.set(true, forKey: MPWelcome.firstStoryDoneKey)
        let settings = MPSettingsStore.shared
        // "Önce masal": giriş yoksa kapı şimdi girişe döner, bu sheet'i
        // taşıyan ContentView kapanır. Soru harcanmaz; girişten sonra biten
        // ilk masalda sorulur.
        let account = AccountService.shared
        let staysInApp = account.account != nil || account.deferredSignIn
        // "Bir masal daha" de giriş ekranında kesilmez: istek saklanır, giriş ve
        // onaydan sonra ikinci masal kendiliğinden açılır (ContentView).
        if !staysInApp, case .create = afterReader {
            afterReader = nil
            UserDefaults.standard.set(true, forKey: MPWelcome.continueAfterSignInKey)
        }
        if staysInApp && !settings.reminderAsked && afterReader == nil {
            settings.reminderAsked = true
            router.sheet = .reminder
        }
    }

    /// "Uyku masalı yaz" penceresi kapandıktan sonra seçilen yol.
    func runBedtimeChoice() {
        guard let choice = pendingBedtimeChoice else { return }
        pendingBedtimeChoice = nil
        switch choice {
        case .bedtimeStory: startStoryCreation(mode: .bedtime)
        case .resume(let story): read(story)
        case .otherStory: startStoryCreation()
        case .sleepMode: openSleepMode()
        }
    }

    /// Masal sonu "İyi geceler": uyku modu açıksa masal orada sürer; kapalıyken
    /// okuyucu kapanır ve Ana sayfa iyi geceler der.
    func sayGoodNight(after story: Story) {
        // Faz 11: "İyi geceler" akşam sırasının ışık adımıdır.
        MPBedtimeRoutine.shared.mark(.light, for: ProfileManager.shared.currentProfile?.id)
        if MPFeatures.sleepMode {
            afterReader = .sleep(story)
        } else {
            showToast("İyi geceler", symbol: "moon")
        }
    }

    /// "Bu akşamın masalı" (`MPTonight`): Ana sayfa kartının düğmesi, widget
    /// ve Siri (FAZ 19). Dışarıdan gelindiğinde (widget, Siri) "bugün
    /// okudun" durumu yeni masal akışını açmaz, Ana sayfada kalır.
    func openTonight(fromSurface: Bool = false, now: Date = Date()) {
        let resolved = MPTonightSource.current()
        switch resolved.tonight(at: now) {
        case .bedtime:
            // Faz 11: akşam kartı hep pencereyi açar; uyku modu oradaki
            // seçeneklerden biri ("Uyku modunda dinle"). Widget ve Siri'nin
            // uyku bağlantısı doğrudan `openSleepMode()`'a gider.
            showBedtimeSheet = true
        case .resume:
            if let story = resolved.resumeStory { read(story) }
        case .unread:
            if let daily = resolved.daily { readOriginal(daily) }
        case .readToday:
            if !fromSurface { startStoryCreation() }
        }
    }

    /// 26 · Uyku modu: çocuğun son uyku masalı, yoksa günün masalı; ikisi de
    /// yoksa uyku öncesi modunda yeni bir masal. Uyku modu kapalıyken (v1)
    /// "Uyku masalı yaz" penceresi.
    func openSleepMode() {
        guard MPFeatures.sleepMode else {
            showBedtimeSheet = true
            return
        }
        if let session = MPTonightSource.sleepSession() {
            MPBedtimeRoutine.shared.mark(.light, for: ProfileManager.shared.currentProfile?.id)
            sleepSession = session
        } else {
            startStoryCreation(mode: .bedtime)
        }
    }

    /// Widget, Live Activity ya da Siri'den gelen yer (FAZ 19). Hepsi çocuk
    /// alanında açılır: ebeveyn modundaysa önce çocuk moduna dönülür, açık
    /// bir tam ekran varsa ona dokunulmaz.
    func open(_ link: MPSurfaceLink, childID: UUID?) {
        router.enterChildMode()
        guard readerStory == nil, sleepSession == nil, !showStoryCreation else { return }
        router.sheet = nil
        showBedtimeSheet = false
        pendingBedtimeChoice = nil
        actionsStory = nil
        router.tab = .home
        switch link {
        case .tonight:
            openTonight(fromSurface: true)
        case .sleep:
            // Uyku modu v2'de; eski widget ve kısayol dokunuşları boşa düşmez.
            if MPFeatures.sleepMode { openSleepMode() } else { openTonight(fromSurface: true) }
        case .series:
            guard let childID else { return }
            SeriesManager.shared.refreshUnlocks(for: childID)
            if SeriesManager.shared.openSeries(for: childID) != nil { router.openKidPage(.series(childID)) }
        }
    }

    func read(_ story: Story, fromStart: Bool = false) {
        readSize = MPSettingsStore.shared.effectiveReadSize(forAge: ProfileManager.shared.currentProfile?.age)
        readerStartPage = fromStart ? 0 : nil
        readerListens = false
        readerVoiceChoice = nil
        readerStory = story
    }

    /// Kapaktaki "Kim okusun?" seçimi (vizyon planı düzen 9). `nil` seçilmedi:
    /// ayar ve "Dinle" geçerli. Seçim yalnızca bu okumaya ait, ayar değişmez.
    @Published var readerVoiceChoice: Bool?

    /// Bu okumada anlatıcı okusun mu.
    func readerShouldSpeak(settings: MPSettingsStore) -> Bool {
        readerVoiceChoice ?? (settings.readAloud || readerListens)
    }

    /// Okuyucu açılır açılmaz sesli okusun mu (Günlük detayındaki "Dinle").
    /// Okuyucu her açılışta sıfırlar.
    @Published var readerListens = false

    // MARK: - Günlük (FAZ 20)

    /// Bir Günlük masalını okuyucuda açar: seçili anlatımla, kaldığı yerden.
    func readClassic(_ tale: ClassicTale, listen: Bool = false, progress: ClassicProgressStore = .shared) {
        let narration = progress.narration(for: tale.id)
        let pageCount = tale.text(narration).pages.count
        progress.markOpened(tale.id, pageCount: pageCount, narration: narration)
        let entry = progress.entry(tale.id)
        let finished = entry?.isFinished ?? false
        let child = ProfileManager.shared.currentProfile
        let story = ClassicReading.story(
            for: tale, narration: narration, childID: child?.id, childName: "",
            savedPage: finished ? 0 : entry?.page)
        read(story, fromStart: finished)
        readerListens = listen
    }

    /// Günlük akışın kendi masalı (FAZ 15), Günlük'ün okuyucusunda.
    func readOriginal(_ daily: DailyStory, progress: ClassicProgressStore = .shared) {
        let child = ProfileManager.shared.currentProfile
        let draft = ClassicReading.story(for: daily, childID: child?.id, childName: "", savedPage: nil)
        progress.markOpened(daily.id, pageCount: draft.pages.count, narration: .soft)
        let entry = progress.entry(daily.id)
        let finished = entry?.isFinished ?? false
        var story = draft
        story.lastReadPage = finished ? 0 : entry?.page
        DailyStoryManager.shared.markAsRead(storyId: daily.id)
        read(story, fromStart: finished)
    }

    // Bildirim
    @Published var toast: MPToastMessage?

    // Okuyucu tercihleri (okuma yüzeyine özel — uygulama geneli tema yok)
    /// Kalıcı (FAZ 17): `MPSettingsStore.readTheme`'e yazılır.
    @Published var readTheme: MP.ReadTheme = MPSettingsStore.shared.readTheme {
        didSet { MPSettingsStore.shared.readTheme = readTheme }
    }
    /// Yazı boyutu diske yazılıyordu ama buraya hiç geri okunmuyordu: her
    /// açılışta `.normal`'a dönüyordu. Ayarlar'da "Büyük" yazarken okuyucunun
    /// normal boyutta açılması, kaydedilmiş bir tercihin hiç kaydedilmemiş
    /// olmasından daha kötü — ekran tercihi gösteriyor, uygulama uygulamıyor.
    @Published var readSize: MP.ReadSize = MPSettingsStore.shared.readSize

    // MARK: Eylemler

    func showToast(_ message: String, symbol: String = "checkmark", tone: MPToast.Tone = .calm) {
        withAnimation(MP.M.gated(MP.M.easeOut)) {
            toast = MPToastMessage(message: message, symbol: symbol, tone: tone)
        }
    }

    /// (+) butonu ve ana sayfa hero kartı yeni akışı baştan açar; ana
    /// sayfadaki bir mod kartı ise modu vererek ikinci adımdan.
    func startStoryCreation(mode: StoryMode? = nil, family: UUID? = nil) {
        // Sadece okuma rolündeki yetişkin aileye masal yazamaz (FAZ 18).
        guard AccountService.shared.canWriteFamily else {
            showToast(FamilyCopy.readOnly, symbol: "book")
            return
        }
        creationPreset = mode
        creationFamilyID = family
        showStoryCreation = true
    }

    func openPaywall() {
        showPaywall = true
    }

}

// MARK: - İlk kurulum karşılaması
//
// İlk profil, ContentView (ve dolayısıyla MPAppState) daha var olmadan
// oluşturuluyor; toast'ı taşımak için küçük bir bayrak kullanılır.

enum MPWelcome {
    static let pendingKey = "mp_pendingWelcomeName"
    /// İlk masal bitip okuyucu kapandı (Faz 8): "önce masal" sırasında girişin
    /// zamanı ve hatırlatma sorusunun anı.
    static let firstStoryDoneKey = "mp_firstStoryDone"
    /// "Önce masal": çocuk ilk masalın sonunda "Bir masal daha" dedi, giriş araya
    /// girdi. Girişten sonra ikinci masal açılır.
    static let continueAfterSignInKey = "mp_continueAfterSignIn"
    /// "Önce masal": dönen ebeveyn karşılamada "Hesabım var" dedi; ad sorulmadan
    /// girişe gidilir, çocuklar hesaptan gelir.
    static let signInFirstKey = "mp_signInFirst"

    /// Girişten sonra bekleyen "Bir masal daha" isteğini okuyup temizler.
    static func consumeContinue() -> Bool {
        let d = UserDefaults.standard
        guard d.bool(forKey: continueAfterSignInKey) else { return false }
        d.removeObject(forKey: continueAfterSignInKey)
        return true
    }

    /// Bekleyen karşılama adını okuyup temizler.
    static func consume() -> String? {
        let d = UserDefaults.standard
        guard let name = d.string(forKey: pendingKey), !name.isEmpty else { return nil }
        d.removeObject(forKey: pendingKey)
        return name
    }
}
