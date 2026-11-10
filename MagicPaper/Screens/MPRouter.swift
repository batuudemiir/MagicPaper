import SwiftUI

// MARK: - Kök sekmeler

/// Çocuk alanının sekmeleri (11 · Ana sayfa, Masallar, 16 · Kitaplık, 12 · Profil).
///
/// 7 Kasım 2026 (Batuhan): Profil çubukta, çünkü profil değiştirme sık yapılan
/// bir iş; `KidCornerView`, kodda `corner`. "Masal yaz" bir sekme değil, bir
/// eylem: çubuk onu ayrı çizer.
enum MPTab: String, CaseIterable {
    case home, gunluk, library, corner

    var label: String {
        switch self {
        case .home:    return "Ana sayfa"
        case .gunluk:  return "Masallar"
        case .library: return "Kitaplık"
        case .corner:  return "Odam"
        }
    }

    var kidTab: KidTab {
        switch self {
        case .home:    return .home
        case .gunluk:  return .gunluk
        case .library: return .library
        case .corner:  return .corner
        }
    }

    init(_ kidTab: KidTab) {
        switch kidTab {
        case .home:    self = .home
        case .gunluk:  self = .gunluk
        case .library: self = .library
        case .corner:  self = .corner
        }
    }
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

/// Ebeveyn sekmesinin yığınına itilen sayfalar (teslimdeki `ParentRoute`,
/// SCREENS.md: push). FAZ 18 özellikleri `FamilyFeatureAccess` bayrağı açıkken
/// görünür; Masal kitabı sunucu istemediği için bayrak dışı.
enum MPParentRoute: Identifiable, Hashable {
    case bookExport       // 35 · Masal kitabı
    case voiceRecording   // 33 · Kendi sesin
    case familyMembers    // 34 · Aile üyeleri
    case shareLink        // 36 · Aileyle paylaş
    case familyCharacters(UUID)  // 14 · Masal ailem, profil düzenlemeden
    case bookCharacter(UUID)     // 13 · Kahraman oluşturucu, profil düzenlemeden
    case profileEdit(UUID)       // Çocuğun adı, rengi ve yaş bandı
    case profileHub(UUID)        // Çocuk profil sayfası (Faz 7; önceden sheet)

    var id: String {
        switch self {
        case .profileEdit(let i): return "profileEdit-\(i)"
        case .profileHub(let i): return "profileHub-\(i)"
        case .bookExport: return "bookExport"
        case .voiceRecording: return "voiceRecording"
        case .familyMembers: return "familyMembers"
        case .shareLink: return "shareLink"
        case .familyCharacters(let i): return "familyCharacters-\(i)"
        case .bookCharacter(let i): return "bookCharacter-\(i)"
        }
    }

    /// `-mpParentRoute` açılış argümanı (`MPDebugLaunch`).
    init?(debugName: String) {
        switch debugName {
        case "bookExport": self = .bookExport
        case "voiceRecording": self = .voiceRecording
        case "familyMembers": self = .familyMembers
        case "shareLink": self = .shareLink
        default: return nil
        }
    }
}

// MARK: - Çocuk alt sayfaları

/// Çocuk sekmesinin yığınına itilen sayfalar (SCREENS.md: push). Alt çubuk
/// görünür kalır, her sekme kendi yolunu korur. Masallar sekmesinde bunlar
/// `GunlukRoute.kid` içinde taşınır.
enum MPKidRoute: Hashable {
    case series(UUID)            // 18 · Seri masal
    case newWords(UUID)          // 15 · Yeni kelimelerim
    case familyCharacters(UUID)  // 14 · Masal ailem
    case bookCharacter(UUID)     // 13 · Kahraman oluşturucu
}

// MARK: - Alt sayfalar (sheet)

enum MPSheetRoute: Identifiable, Equatable {
    /// İlgi alanları (FAZ 12), çocuk başına; Ebeveyn > Çocuklar'dan.
    case interests(UUID)
    /// "Çıkış yap" onayı (FAZ 16), Ebeveyn > Ayarlar'dan.
    case signOut

    var id: String {
        switch self {
        case .interests(let i): return "interests-\(i)"
        case .signOut: return "signOut"
        }
    }
}

// MARK: - Gezinme

/// Uygulamanın tek gezinme kaynağı: sekme, sekme yığınları, sheet ve ebeveyn odası
/// (Faz 2, `docs/ARCHITECTURE.md`). İş mantığı ve kalıcı veri taşımaz. Tam ekran
/// sunumlar (okuyucu, masal yazma, uyku) oturumlarıyla birlikte `MPAppState`'te.
@MainActor
final class MPRouter: ObservableObject {

    @Published var tab: MPTab = .home

    /// Seçili sekmeye yeniden dokunulunca artar; sekme kendi köküne döner
    /// (Günlük'te açık detay sayfaları kapanır, iOS'un alışılmış davranışı).
    @Published private(set) var tabReselections = 0

    /// Çocuk sekmelerinin yığın yolları; sekme değişince kaybolmaz.
    @Published var kidPaths: [MPTab: [MPKidRoute]] = [:]

    /// Masallar sekmesinin yolu: rafları ve detayları da taşıdığı için ayrı.
    @Published var masallarPath: [GunlukRoute] = []

    func reselectTab() {
        kidPaths[tab] = []
        tabReselections += 1
    }

    /// Çocuk değişince önceki çocuğun sayfaları kapanır; klasikler herkesin, kalır.
    func closePagesOfPreviousChild() {
        kidPaths = [:]
        masallarPath.removeAll { route in
            if case .kid = route { return true }
            return false
        }
    }

    /// Alt sayfa, açık olan sekmenin yığınına itilir. Ebeveyn alanında karakter
    /// sayfaları ebeveyn sekmesinin yığınına gider; açık sheet kapanır.
    func openKidPage(_ route: MPKidRoute) {
        if isParentMode {
            switch route {
            case .bookCharacter(let id):
                sheet = nil
                parentRoute = .bookCharacter(id)
                return
            case .familyCharacters(let id):
                sheet = nil
                parentRoute = .familyCharacters(id)
                return
            case .series, .newWords:
                break
            }
        }
        if tab == .gunluk {
            guard masallarPath.last != .kid(route) else { return }
            masallarPath.append(.kid(route))
            return
        }
        guard kidPaths[tab]?.last != route else { return }
        kidPaths[tab, default: []].append(route)
    }

    /// Profil sayfasından "Profili düzenle": form yığına itilir.
    func openProfileEdit(_ id: UUID) {
        sheet = nil
        parentRoute = .profileEdit(id)
    }

    /// Alt sayfanın "Geri"si: bir geri döner.
    func closeKidPage() {
        if isParentMode {
            parentRoute = nil
        } else if tab == .gunluk {
            if !masallarPath.isEmpty { masallarPath.removeLast() }
        } else if kidPaths[tab]?.isEmpty == false {
            kidPaths[tab]?.removeLast()
        }
    }

    /// Sheet kapanırken başka bir modal açılamaz (iOS sunumu yutar): sıradaki iş
    /// sheet gerçekten kapanınca çalışır (`ContentView`, `onDismiss`).
    private var afterSheet: (() -> Void)?

    func closeSheet(then next: @escaping () -> Void) {
        afterSheet = next
        sheet = nil
    }

    func runAfterSheet() {
        let next = afterSheet
        afterSheet = nil
        next?()
    }

    /// Çocuk mu, ebeveyn mi. Oturumluk ve kalıcı değil: uygulama her zaman
    /// çocuk modunda açılır, arka plana gidince de çocuk moduna döner. Telefonu
    /// çocuğa geri veren bir ebeveynin hiçbir şeyi kapatmayı hatırlaması
    /// gerekmez.
    @Published private(set) var isParentMode = false
    /// Ebeveyn menüsünde açık sayfa. Her girişte Özet'ten başlar.
    @Published var parentTab: MPParentTab = .overview {
        didSet { if parentTab != oldValue { parentPath = [] } }
    }

    /// Ebeveyn alanından açılan tam ekran sayfa.
    /// Ebeveyn sekmesinin yığını (Faz 7: profil sayfasından form ve Masal ailem
    /// itilebilsin diye çok seviyeli).
    @Published var parentPath: [MPParentRoute] = []

    /// En üstteki sayfa. Atamak iter, `nil` bir geri döner.
    var parentRoute: MPParentRoute? {
        get { parentPath.last }
        set {
            if let newValue {
                if parentPath.last != newValue { parentPath.append(newValue) }
            } else if !parentPath.isEmpty {
                parentPath.removeLast()
            }
        }
    }
    @Published var showGate = false
    @Published var showProfileAdd = false
    /// Kapı açılınca doğrudan profil ekleme açılsın (Benim köşem "Ekle", 16 Ekim).
    private(set) var profileAddAfterGate = false
    /// Tek kapı (Faz 7): çocuk alanında kapı isteyen iş (kahraman, Masal ailem,
    /// paylaşma). Kapı geçilince odaya girilmez, iş çalışır.
    private var gateAction: (() -> Void)?
    private var gatePassed = false
    @Published var sheet: MPSheetRoute?

    /// 12 · Profil: Ana sayfadaki yıldız satırı bu sekmeye geçirir.
    func openKidCorner() {
        tab = .corner
    }

    /// Ebeveyn moduna geçiş her seferinde kapıdan geçer.
    func requestParentMode() {
        guard !isParentMode else { return }
        showGate = true
    }

    /// Bir işi ebeveyn kapısının arkasına koyar. Ebeveyn odasındayken doğrudan
    /// çalışır. Kapı tek yerden açılır (`ContentView`), ekranlar kendi kapısını tutmaz.
    func requestGate(then action: @escaping () -> Void) {
        if isParentMode { action(); return }
        gateAction = action
        gatePassed = false
        showGate = true
    }

    /// Kapı geçildi: iş bekliyorsa yalnızca kapı kapanır, yoksa oda açılır.
    func gateSucceeded() {
        if gateAction != nil {
            gatePassed = true
            showGate = false
            MPHaptics.tap()
        } else {
            unlockParent()
        }
    }

    func unlockParent() {
        showGate = false
        isParentMode = true
        parentTab = .overview
        MPHaptics.tap()
    }

    /// Çocuk alanındaki "Ekle": kapıdan geçer, kapı açılınca ebeveyn özetinde
    /// kalmadan doğrudan profil eklemeye gider.
    func requestProfileAdd() {
        if isParentMode { showProfileAdd = true; return }
        profileAddAfterGate = true
        showGate = true
    }

    /// Kapı ekranı kapandıktan sonra (iki tam ekran üst üste açılmasın diye
    /// kapanışta): kapı açıldıysa bekleyen profil eklemeyi açar, vazgeçildiyse unutur.
    func gateDismissed() {
        defer {
            profileAddAfterGate = false
            gateAction = nil
            gatePassed = false
        }
        if let action = gateAction, gatePassed { action() }
        if profileAddAfterGate && isParentMode { showProfileAdd = true }
    }

    /// Çocuk moduna dönüş kapısızdır ve çocuk her zaman Ana Sayfa'ya döner.
    /// Yalnızca ebeveynin açabildiği yüzeyler (profil ekleme/düzenleme) de
    /// kapanır: mod değiştiği hâlde açık kalan bir ebeveyn ekranı, kapıyı
    /// anlamsız kılardı.
    func enterChildMode() {
        guard isParentMode else { return }
        isParentMode = false
        parentPath = []
        showProfileAdd = false
        sheet = nil
    }
}
