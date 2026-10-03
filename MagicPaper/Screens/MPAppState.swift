import SwiftUI

// MARK: - Kök sekmeler

/// 04-STATE-INTERACTIONS.md — kök navigasyon.
/// Üç yer, artı bir eylem.
///
/// Günlük geri geldi: alışkanlık tarafı burada geliştirilecek. Ana Sayfa'daki
/// kopyası kaldırıldı — aynı kartı iki sekmede göstermek, ilk seferinde de
/// sorun olan şeydi. Ana Sayfa yalnızca seriyi özetliyor ve dokununca buraya
/// getiriyor.
///
/// Ebeveyn artık bir sekme değil, bir mod (`MPAppState.isParentMode`): ana
/// ekranın sağ üstündeki anahtarla açılır ve Ana Sayfa'nın yerini alır.
///
/// "Masal yarat" bu listede DEĞİL ve olmamalı: gidilecek bir yer değil,
/// yapılacak bir iş. Bar onu ayrı bir öğe türü olarak çiziyor.
enum MPTab: String, CaseIterable {
    case home, library, daily

    var label: String {
        switch self {
        case .home:    return "Ana Sayfa"
        case .library: return "Kütüphane"
        case .daily:   return "Günlük"
        }
    }

    var symbol: String {
        switch self {
        case .home:    return "house"
        case .library: return "book"
        case .daily:   return "calendar"
        }
    }
}

/// Ebeveyn modunun kendi menüsü. Çocuk menüsüyle ortak hiçbir sekmesi yok:
/// ebeveynin yaptığı işler — bakmak, düzenlemek, ayarlamak — çocuğun
/// yaptıklarından (okumak, yaratmak) ayrı.
///
/// Ham değerler `MPTab`'inkilerle çakışmamalı: ikisi de aynı sekme çubuğunun
/// `String` seçimine yazılıyor.
enum MPParentTab: String, CaseIterable {
    case overview, children, settings

    var label: String {
        switch self {
        case .overview: return "Özet"
        case .children: return "Çocuklar"
        case .settings: return "Ayarlar"
        }
    }

    var symbol: String {
        switch self {
        case .overview: return "chart.bar"
        case .children: return "person.2"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Alt sayfalar (sheet)

enum MPSheetRoute: Identifiable, Equatable {
    case profilePicker
    case profileEdit(UUID)
    /// Görselli kitabın karakteri (B2) — ebeveyn tarafı.
    case bookCharacter(UUID)

    var id: String {
        switch self {
        case .profilePicker:        return "profilePicker"
        case .profileEdit(let i):   return "profileEdit-\(i)"
        case .bookCharacter(let i): return "bookCharacter-\(i)"
        }
    }
}

// MARK: - Sihirbaz ön ayarı

/// Ana sayfadaki dünya tile'ından girildiğinde sihirbaz doğrudan 3. adımda açılır.
struct MPWizardPreset: Equatable {
    var world: MP.World?
    var startStep: Int = 0
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

    /// The old four-step wizard.
    ///
    /// Kept deliberately and temporarily. It is the only way to create an
    /// *illustrated* story, and the feature meant to replace it — turning an
    /// existing story into a picture book — does not exist yet. Reachable from
    /// the world tiles rather than from the primary action, so the ritual is the
    /// new flow and this is the side door. Retire it with that feature.
    @Published var showWizard = false
    @Published var wizardPreset = MPWizardPreset()
    @Published var showPaywall = false
    /// Geliştirici: dekorasyon galerisi ve demo sayfalar.
    @Published var showDecorationGallery = false
    @Published var showDecorationDemo = false
    @Published var showGate = false
    @Published var showProfileAdd = false
    @Published var readerStory: Story?
    /// Raftan açılan masal detayı. Okuyucu detayın içinden açılır, bu yüzden
    /// detaydan okumaya geçmek `readerStory`'ye dokunmaz.
    @Published var detailStory: Story?

    // Alt sayfalar ve bildirim
    @Published var sheet: MPSheetRoute?
    @Published var toast: MPToastMessage?

    // Okuyucu tercihleri (okuma yüzeyine özel — uygulama geneli tema yok)
    @Published var readTheme: MP.ReadTheme = .light
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

    /// (+) butonu ve ana sayfa hero kartı — yeni akışı açar.
    func startStoryCreation() {
        showStoryCreation = true
    }

    /// Masal dünyaları — geçici olarak eski sihirbaza gider (görselli masal).
    func startWizard(world: MP.World? = nil) {
        wizardPreset = MPWizardPreset(world: world, startStep: world == nil ? 0 : 1)
        showWizard = true
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
        showProfileAdd = false
        if case .profileEdit = sheet { sheet = nil }
        if case .bookCharacter = sheet { sheet = nil }
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
