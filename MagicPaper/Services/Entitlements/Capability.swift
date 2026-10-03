import Foundation

// MARK: - Capability

/// Uygulamanın **yapmak istediği şey**. Planın adı değil.
///
/// Bu tipin varlık sebebi tek bir cümle: arayüz "premium miyim" diye sormamalı,
/// "bunu yapabilir miyim" diye sormalı. `if isPremium` bir gün üç kademeli bir
/// planla karşılaşınca on dokuz yerde birden yanlışa döner; `Capability` ise
/// kararın tek bir yerde — `EntitlementPolicy` — verilmesini zorlar.
///
/// Liste **koddan türetildi**, tasarlanmadı. Her vakanın karşılığı olan mevcut
/// kontrol `MagicPaper_Monetization.md` içindeki taşıma tablosunda dosya:satır
/// olarak yazılı.
public enum Capability: String, CaseIterable, Sendable {

    /// Görselli (illüstrasyonlu) masal üretmek.
    ///
    /// Kotalı. Tek gerçek maliyet taşıyan yetenek bu: uzak görsel üretimi para
    /// harcar, dolayısıyla tüketim anında **taze** doğrulama ister (bkz.
    /// `EntitlementPolicy`).
    /// Bugünkü karşılığı: `SubscriptionManager.canCreateStory(type: .image)`.
    case illustratedStory

    /// Metin masalını beklemeden üretmek.
    ///
    /// Ücretsiz kullanıcı 12 saatte bir üretebiliyor; abone sınırsız.
    /// Bugünkü karşılığı: `SubscriptionManager.canCreateStory(type: .text)`.
    case unlimitedTextStories

    /// Günün masalını sınırsız açmak.
    /// Bugünkü karşılığı: `SubscriptionManager.canCreateStory(type: .daily)`.
    case unlimitedDailyStories

    /// Kilitli dünyalar: peri, korsan, kar, çiftlik, robot, sirk.
    /// Bugünkü karşılığı: `MP.World.isPremium && !subscriptionManager.isPremium`.
    case premiumWorlds

    /// Kilitli temalar: jungle, hero, underwater, custom.
    /// Bugünkü karşılığı: `StoryTheme.isPremium` (`Models/Story.swift:238`).
    case premiumThemes

    /// Uzun masal (12 sayfa).
    /// Bugün karşılığı yok: uzunluk seçimi kalktı, sayfa sayısı yaş bandından
    /// gelir (FAZ 10, `AgeBand.pageCount`).
    case longStories
}

public extension Capability {
    /// Yeteneğin her kullanımının bir kontör düşürüp düşürmediği.
    ///
    /// Yalnızca bunlar için `EntitlementService.consume` çağrılmalı; diğerleri
    /// saf erişim kapısıdır ve tüketilmez.
    var isMetered: Bool {
        switch self {
        case .illustratedStory:
            return true
        case .unlimitedTextStories, .unlimitedDailyStories,
             .premiumWorlds, .premiumThemes, .longStories:
            return false
        }
    }

    /// Uzak (ücretli) üretim tetikleyen yetenekler.
    ///
    /// Bunlar önbelleğe alınmış bir aboneliğe güvenerek açılmaz — bkz.
    /// `EntitlementPolicy.decide`.
    var incursRemoteCost: Bool { self == .illustratedStory }
}

// MARK: - Plan

/// Abonelik kademesi, entitlement katmanının kendi terimiyle.
///
/// `SubscriptionManager.SubscriptionTier` ile bilerek ayrı tutuldu: politika
/// dosyası `SubscriptionManager`'a (ve dolayısıyla `UserDefaults`'a, SwiftUI'ye,
/// RevenueCat'e) bağlanmasın diye. Eşleme yalnızca adaptörde yapılır.
public enum EntitlementPlan: String, Codable, CaseIterable, Sendable {
    case free
    case basic
    case premium
    case ultimate

    public var isPaid: Bool { self != .free }

    /// Aylık görselli masal kotası. `SubscriptionTier.monthlyImageStories`
    /// ile birebir aynı; kaynak orada, bu yalnızca politikanın okuyabildiği kopya.
    public var monthlyIllustratedQuota: Int {
        switch self {
        case .free:     return 0
        case .basic:    return 1
        case .premium:  return 5
        case .ultimate: return 10
        }
    }

    /// Ebeveyne gösterilecek sade ad. Emoji yok — rozet arayüzün işi.
    public var displayName: String {
        switch self {
        case .free:     return "Ücretsiz plan"
        case .basic:    return "Yıldız Kaşifi"
        case .premium:  return "Hikaye Kahramanı"
        case .ultimate: return "Sihir Ustası"
        }
    }
}

// MARK: - Trust

/// Elimizdeki abonelik bilgisinin **nereden** geldiği.
///
/// Bu tip güvenlik için var. `SubscriptionManager` planı `UserDefaults`'a
/// yazıyor ve sonraki açılışlarda oradan okuyor; o değer cihaz sahibinin
/// yazabildiği bir değerdir ve tek başına yetki kanıtı değildir. Politika,
/// planı **ve** planın kaynağını birlikte değerlendirir.
public enum EntitlementTrust: Equatable, Sendable {

    /// Bu oturumda RevenueCat `CustomerInfo`'sundan doğrulandı.
    case verified

    /// Daha önce doğrulanmıştı, şu an ağ yok. `age` son doğrulamadan bu yana
    /// geçen süre. Tolerans penceresi içindeyse plan onurlandırılır.
    case cached(age: TimeInterval)

    /// Hiç doğrulanmadı — elimizdeki tek şey yerel yazı. Ücretli hiçbir yetenek
    /// bununla açılmaz.
    case unverified
}

// MARK: - Decision

/// Politika çıktısı. Bilerek `Bool` değil.
///
/// `Bool` "neden hayır" bilgisini düşürür, ve arayüz o bilgiyi kaybedince
/// yeniden uydurur: bekleme süresini, kota metnini, hangi ekranın açılacağını.
/// Ondokuz çağrı yerinin ondokuz farklı biçimde uydurmasının sebebi buydu.
public enum EntitlementDecision: Equatable, Sendable {

    /// Abonelik kapsamında, sayaç düşmeden.
    case allowed

    /// Ücretsiz deneme hakkıyla. `remaining` tüketimden **önceki** hak sayısı.
    case allowedUsingTrial(remaining: Int)

    /// Abonelik kotasından. `remaining` tüketimden **önceki** kota.
    case allowedUsingQuota(remaining: Int)

    /// Hayır, ve nedeni.
    case denied(EntitlementDenial)

    public var isAllowed: Bool {
        if case .denied = self { return false }
        return true
    }

    /// Karar izin veriyorsa, tüketimden önce kalan hak/kota. Kotasız izinlerde `nil`.
    public var remainingBeforeUse: Int? {
        switch self {
        case .allowedUsingTrial(let r), .allowedUsingQuota(let r): return r
        case .allowed, .denied: return nil
        }
    }

    public var denial: EntitlementDenial? {
        if case .denied(let reason) = self { return reason }
        return nil
    }
}

/// Reddin sebebi — arayüzün ne göstereceğini bu belirler.
public enum EntitlementDenial: Equatable, Sendable {

    /// Ücretsiz planda hiç yok. → paywall.
    case requiresSubscription

    /// Abone ama bu ayın kotası bitti. → paywall (yükseltme) veya "ay başında yenilenir".
    case quotaExhausted

    /// Ücretsiz metin masalı soğuma süresi. → paywall değil, sakin bir bekleme metni.
    /// `hours` kalan tam saat, yukarı yuvarlanmış.
    case waitingForFreeStory(hours: Int)

    /// Plan kayıtlı görünüyor ama doğrulanamadı (hiç doğrulanmadı ya da tolerans
    /// penceresi doldu). → "Satın alımları geri yükle", paywall değil.
    case unverifiedEntitlement
}
