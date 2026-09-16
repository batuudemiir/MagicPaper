import SwiftUI

// MARK: - Kök sekmeler

/// 04-STATE-INTERACTIONS.md — kök navigasyon 4 sekmelidir.
/// Dört yer, artı bir eylem.
///
/// Günlük geri geldi: alışkanlık tarafı burada geliştirilecek. Ana Sayfa'daki
/// kopyası kaldırıldı — aynı kartı iki sekmede göstermek, ilk seferinde de
/// sorun olan şeydi. Ana Sayfa yalnızca seriyi özetliyor ve dokununca buraya
/// getiriyor.
///
/// "Masal yarat" bu listede DEĞİL ve olmamalı: gidilecek bir yer değil,
/// yapılacak bir iş. Bar onu ayrı bir öğe türü olarak çiziyor.
enum MPTab: String, CaseIterable {
    case home, library, daily, parent

    var label: String {
        switch self {
        case .home:    return "Ana Sayfa"
        case .library: return "Kütüphane"
        case .daily:   return "Günlük"
        case .parent:  return "Ebeveyn"
        }
    }

    var symbol: String {
        switch self {
        case .home:    return "house"
        case .library: return "book"
        case .daily:   return "calendar"
        case .parent:  return "shield"
        }
    }
}

// MARK: - Alt sayfalar (sheet)

enum MPSheetRoute: Identifiable, Equatable {
    case profilePicker
    case storyActions(UUID)
    case profileEdit(UUID)

    var id: String {
        switch self {
        case .profilePicker:      return "profilePicker"
        case .storyActions(let i): return "storyActions-\(i)"
        case .profileEdit(let i): return "profileEdit-\(i)"
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

    // Ebeveyn kapısı oturum boyunca açık kalır
    @Published var parentUnlocked = false

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
    @Published var showSettings = false
    /// Geliştirici: dekorasyon galerisi ve demo sayfalar.
    @Published var showDecorationGallery = false
    @Published var showDecorationDemo = false
    @Published var showGate = false
    @Published var showProfileAdd = false
    @Published var readerStory: Story?

    // Alt sayfalar ve bildirim
    @Published var sheet: MPSheetRoute?
    @Published var toast: MPToastMessage?

    // Okuyucu tercihleri (okuma yüzeyine özel — uygulama geneli tema yok)
    @Published var readTheme: MP.ReadTheme = .light
    @Published var readSize: MP.ReadSize = .normal

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

    /// Ebeveyn sekmesi: kapı geçilmediyse önce matematik sorusu sorulur.
    /// Çocuk modu açıkken kapı her seferinde yeniden sorulur.
    func selectTab(_ next: MPTab, childModeOn: Bool) {
        guard next == .parent else {
            tab = next
            return
        }
        if parentUnlocked && !childModeOn {
            tab = .parent
        } else {
            showGate = true
        }
    }

    func unlockParent() {
        parentUnlocked = true
        showGate = false
        tab = .parent
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
