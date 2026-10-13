import SwiftUI

// MARK: - Kök sekmeler

/// Çocuk alanının sekmeleri (11 · Ana sayfa, 16 · Kitaplık).
///
/// FAZ 17 (Pastel Masal): alt bar Ana sayfa · Yarat · Kitaplık. "Günlük"
/// sekmesi kalktı; günün masalı ve okuma serisi Ana sayfada.
/// "Yarat" bir sekme değil, bir eylem: `KidTabBar` onu ayrı çizer.
enum MPTab: String, CaseIterable {
    case home, library

    var label: String {
        switch self {
        case .home:    return "Ana sayfa"
        case .library: return "Kitaplık"
        }
    }

    var kidTab: KidTab { self == .home ? .home : .library }
    init(_ kidTab: KidTab) { self = kidTab == .home ? .home : .library }
}

/// Ebeveyn alanının sekmeleri: Özet · Güvenlik · Ayarlar.
/// Çocuk profilleri Ayarlar'ın ilk bölümünde (FAZ 17).
enum MPParentTab: String, CaseIterable {
    case overview, safety, settings

    var parentTab: ParentTab {
        switch self {
        case .overview: return .summary
        case .safety:   return .safety
        case .settings: return .settings
        }
    }

    init(_ tab: ParentTab) {
        switch tab {
        case .summary:  self = .overview
        case .safety:   self = .safety
        case .settings: self = .settings
        }
    }
}

// MARK: - Ebeveyn alt sayfaları

/// Ebeveyn alanından tam ekran açılan sayfalar (teslimdeki `ParentRoute`).
/// FAZ 18 özellikleri `FamilyFeatureAccess` bayrağı açıkken görünür; Masal
/// kitabı sunucu istemediği için bayrak dışı.
enum MPParentRoute: String, Identifiable {
    case bookExport       // 35 · Masal kitabı
    case voiceRecording   // 33 · Kendi sesin
    case familyMembers    // 34 · Aile üyeleri
    case shareLink        // 36 · Aileyle paylaş
    var id: String { rawValue }
}

// MARK: - Alt sayfalar (sheet)

enum MPSheetRoute: Identifiable, Equatable {
    case profilePicker
    case profileEdit(UUID)
    /// Görselli kitabın karakteri (B2) — ebeveyn tarafı.
    case bookCharacter(UUID)
    /// Masal ailem (FAZ 11), çocuk başına. Benim köşem gelince oradan açılır.
    case familyCharacters(UUID)
    /// 15 · Yeni kelimelerim, Benim köşem'den.
    case newWords(UUID)
    /// İlgi alanları (FAZ 12), çocuk başına; Ebeveyn > Çocuklar'dan.
    case interests(UUID)
    /// "Çıkış yap" onayı (FAZ 16), Ebeveyn > Ayarlar'dan.
    case signOut

    var id: String {
        switch self {
        case .profilePicker:        return "profilePicker"
        case .profileEdit(let i):   return "profileEdit-\(i)"
        case .bookCharacter(let i): return "bookCharacter-\(i)"
        case .familyCharacters(let i): return "familyCharacters-\(i)"
        case .newWords(let i): return "newWords-\(i)"
        case .interests(let i): return "interests-\(i)"
        case .signOut: return "signOut"
        }
    }
}

// MARK: - Uygulama durumu

/// Tasarımın durum modelinin (04-STATE-INTERACTIONS.md) görünüm katmanı karşılığı.
/// Kalıcı veri mevcut servislerde kalır — burada yalnızca yönlendirme ve
/// oturumluk durum tutulur.
@MainActor
final class MPAppState: ObservableObject {

    // Kök navigasyon
    @Published var tab: MPTab = .home

    /// Çocuk mu, ebeveyn mi. Oturumluk ve kalıcı değil: uygulama her zaman
    /// çocuk modunda açılır, arka plana gidince de çocuk moduna döner. Telefonu
    /// çocuğa geri veren bir ebeveynin hiçbir şeyi kapatmayı hatırlaması
    /// gerekmez.
    @Published private(set) var isParentMode = false
    /// Ebeveyn menüsünde açık sayfa. Her girişte Özet'ten başlar.
    @Published var parentTab: MPParentTab = .overview

    // Tam ekran yollar
    /// The new two-choice creation flow.
    @Published var showStoryCreation = false
    /// A mode chosen on the home screen; the flow then opens at "Masalda
    /// kimler olsun?". Nil opens it at the modes. Cleared when the flow closes.
    @Published var creationPreset: StoryMode?
    /// 14 · "Bu karakterle masal yaz": a Masal ailem character already chosen.
    @Published var creationFamilyID: UUID?

    @Published var showPaywall = false
    /// Geliştirici: dekorasyon galerisi ve demo sayfalar.
    @Published var showDecorationGallery = false
    @Published var showDecorationDemo = false
    @Published var showGate = false
    /// Ebeveyn alanından açılan tam ekran sayfa.
    @Published var parentRoute: MPParentRoute?
    /// 12 · Benim köşem, Ana sayfa başlığındaki avatardan.
    @Published var showKidCorner = false
    @Published var showProfileAdd = false
    @Published var readerStory: Story?
    /// Okuyucu hangi sayfadan açılsın; `nil` kaldığı yerden.
    @Published var readerStartPage: Int?
    /// 17 · Masal aksiyonları: kitaplıkta kapağa dokununca açılan sayfa.
    @Published var actionsStory: Story?
    /// Sayfa kapanınca açılacak masal (sayfa ile okuyucu aynı anda açılamaz).
    var pendingRead: (story: Story, startPage: Int?)?
    /// Okuyucu kapanınca yapılacak iş (masal sonu: "Bir masal daha", "İyi geceler").
    enum AfterReader { case create, sleep(Story) }
    var afterReader: AfterReader?
    /// 26 · Uyku modu.
    @Published var sleepSession: MPSleepSession?

    /// Okuyucu kapandıktan sonra (iki tam ekran sunum üst üste açılamaz).
    func runAfterReader() {
        guard let next = afterReader else { return }
        afterReader = nil
        switch next {
        case .create: startStoryCreation()
        case .sleep(let story): sleepSession = MPSleepSession(story: story)
        }
    }

    /// 18 · Seri masal, çocuk kökünün üstünde.
    @Published var seriesChildID: UUID?

    func read(_ story: Story, fromStart: Bool = false) {
        readerStartPage = fromStart ? 0 : nil
        readerStory = story
    }

    // Alt sayfalar ve bildirim
    @Published var sheet: MPSheetRoute?
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

    /// Ebeveyn moduna geçiş her seferinde kapıdan geçer.
    func requestParentMode() {
        guard !isParentMode else { return }
        showGate = true
    }

    func unlockParent() {
        showGate = false
        showKidCorner = false
        isParentMode = true
        parentTab = .overview
        MPHaptics.tap()
    }

    /// Çocuk moduna dönüş kapısızdır ve çocuk her zaman Ana Sayfa'ya döner.
    /// Yalnızca ebeveynin açabildiği yüzeyler (profil ekleme/düzenleme) de
    /// kapanır: mod değiştiği hâlde açık kalan bir ebeveyn ekranı, kapıyı
    /// anlamsız kılardı.
    func enterChildMode() {
        guard isParentMode else { return }
        isParentMode = false
        tab = .home
        parentRoute = nil
        showProfileAdd = false
        if case .profileEdit = sheet { sheet = nil }
        if case .bookCharacter = sheet { sheet = nil }
        if case .familyCharacters = sheet { sheet = nil }
        if case .interests = sheet { sheet = nil }
    }
}

// MARK: - İlk kurulum karşılaması
//
// İlk profil, ContentView (ve dolayısıyla MPAppState) daha var olmadan
// oluşturuluyor; toast'ı taşımak için küçük bir bayrak kullanılır.

enum MPWelcome {
    static let pendingKey = "mp_pendingWelcomeName"

    /// Bekleyen karşılama adını okuyup temizler.
    static func consume() -> String? {
        let d = UserDefaults.standard
        guard let name = d.string(forKey: pendingKey), !name.isEmpty else { return nil }
        d.removeObject(forKey: pendingKey)
        return name
    }
}
