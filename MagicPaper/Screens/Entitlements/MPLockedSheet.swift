import SwiftUI

/// Çocuk alanında kapalı bir şeye dokunulunca açılan sakin pencere (E7,
/// karar: Batuhan 19 Kasım 2026).
///
/// Satış yapmaz: sayı, geri sayım, fiyat yok. 26 Kasım 2026'dan beri çocuğu
/// büyüğüne de yönlendirmez ("Büyüklere göster" kalktı): çocuğa ücretli bir
/// şeyi istetmek, çocuğa doğrudan satış çağrısı sayılabilir (AB UCPD Ek I
/// madde 28, İngiltere DMCC Ek 20 paragraf 30). Ebeveyn bunu Büyükler için
/// odasında kendisi görür (`MPLockedInterest`); satış orada, kapının arkasında.
/// Ücretsiz günün masalı yazıldıysa bekleme metni yarına bakar, saate değil.
struct MPLockedSheet: View {
    let capability: Capability
    @EnvironmentObject private var app: MPAppState

    var body: some View {
        MPSheet(onClose: close) {
            VStack(alignment: .leading, spacing: MP.S.x4) {
                MascotSays(mascot: copy.mascot, text: copy.ragi, mascotWidth: 72)
                Text(copy.title)
                    .font(MP.F.displaySM())
                    .foregroundStyle(MP.C.textTitle)
                    .accessibilityAddTraits(.isHeader)
                Text(copy.message)
                    .mpText(.body)
                    .foregroundStyle(MP.C.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } footer: {
            VStack(spacing: MP.S.x2) {
                MPButton(title: "Kitaplığa bak", fullWidth: true) {
                    app.router.closeSheet { app.router.tab = .library }
                }
                MPButton(title: "Şimdi değil", kind: .ghost, fullWidth: true, action: close)
            }
        }
        .onAppear { MPLockedInterest.record(capability, childName: ProfileManager.shared.currentProfile?.name) }
    }

    private func close() { app.router.sheet = nil }

    private var copy: MPLockedCopy { MPLockedCopy(capability) }
}

/// Çocuğun en son dokunduğu kapalı şey (26 Kasım 2026). Ebeveyn bunu Büyükler
/// için odasında tek satır olarak görür ve kapatabilir; satış kararı onundur.
/// Yalnızca son kayıt tutulur; "Tamam" deyince silinir ve yeni bir dokunuş
/// olmadan geri gelmez (ısrar yok).
enum MPLockedInterest {
    struct Entry: Equatable {
        let capability: Capability
        let childName: String?
        let date: Date
    }

    private static let key = "mp_lockedInterest"
    /// Bir haftadan eski kayıt gösterilmez.
    static let maxAge: TimeInterval = 7 * 24 * 60 * 60

    static func record(_ capability: Capability, childName: String?, now: Date = Date(),
                       defaults: UserDefaults = .standard) {
        var value: [String: Any] = ["capability": capability.rawValue, "date": now.timeIntervalSince1970]
        if let childName { value["childName"] = childName }
        defaults.set(value, forKey: key)
    }

    static func latest(now: Date = Date(), defaults: UserDefaults = .standard) -> Entry? {
        guard let value = defaults.dictionary(forKey: key),
              let raw = value["capability"] as? String, let capability = Capability(rawValue: raw),
              let stamp = value["date"] as? Double else { return nil }
        let date = Date(timeIntervalSince1970: stamp)
        guard now.timeIntervalSince(date) <= maxAge else { return nil }
        return Entry(capability: capability, childName: value["childName"] as? String, date: date)
    }

    static func clear(defaults: UserDefaults = .standard) { defaults.removeObject(forKey: key) }

    /// "İrem, masalın devamını açmak istedi."
    static func sentence(for entry: Entry) -> String {
        let what: String
        switch entry.capability {
        case .unlimitedTextStories, .unlimitedDailyStories, .illustratedStory, .longStories:
            what = "bugün bir masal daha yazmak istedi"
        case .classicLibrary: what = "Premium'daki bir masalı açmak istedi"
        case .seriesStories: what = "masalın devamını açmak istedi"
        case .familyCast: what = "Masal ailem'den bir kişiyi daha masala katmak istedi"
        case .multipleChildren: what = "yeni bir çocuk profili eklemek istedi"
        case .premiumWorlds, .premiumThemes: what = "yeni bir dünyada masal yazmak istedi"
        case .ownVoice: what = "masalı senin sesinle dinlemek istedi"
        case .pdfBook: what = "masallarından kitap yapmak istedi"
        }
        let name = entry.childName?.trimmingCharacters(in: .whitespaces) ?? ""
        return name.isEmpty ? "Çocuk, \(what)." : "\(name), \(what)."
    }
}

/// Kilit penceresinin sözleri. Görünümden ayrı ki testte okunabilsin.
struct MPLockedCopy: Equatable {
    let mascot: Mascot
    let ragi: String
    let title: String
    let message: String

    init(_ capability: Capability) {
        switch capability {
        case .unlimitedTextStories, .unlimitedDailyStories, .illustratedStory, .longStories:
            mascot = .sleepy
            ragi = "Bugün güzel bir masal yazdık."
            title = "Bugünün masalı yazıldı"
            message = "Yarın yeni bir masal yazabiliriz. O zamana kadar kitaplıktaki masallar seni bekliyor."
        case .classicLibrary:
            mascot = .reading
            ragi = "Bu masal şimdilik kapalı."
            title = "Şimdilik kapalı bir masal"
            message = "Kitaplığında okuyabileceğin başka masallar var."
        case .seriesStories:
            mascot = .reading
            ragi = "Masalın devamı şimdilik kapalı."
            title = "Masalın devamı"
            message = "Bu arada kitaplığındaki masallara bakabilirsin."
        case .familyCast:
            mascot = .waving
            ragi = "Masal ailen şimdilik bu kadar."
            title = "Masal ailem"
            message = "Masalı ailenden ilk eklenen kişiyle yazabilirsin."
        case .multipleChildren:
            mascot = .waving
            ragi = "Yeni profil şimdilik eklenmiyor."
            title = "Yeni bir çocuk"
            message = "Kendi masallarına devam edebilirsin."
        case .premiumWorlds, .premiumThemes:
            mascot = .curious
            ragi = "Bu dünya şimdilik kapalı."
            title = "Şimdilik kapalı bir dünya"
            message = "Başka bir dünyada masal yazabilirsin."
        case .ownVoice, .pdfBook:
            mascot = .calm
            ragi = "Bu şimdilik kapalı."
            title = "Şimdilik kapalı"
            message = "Kitaplığındaki masallar seni bekliyor."
        }
    }
}
