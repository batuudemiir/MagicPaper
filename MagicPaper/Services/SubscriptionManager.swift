import Foundation
import SwiftUI

// Basit Üyelik Sistemi - Sadece 2 Paket
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var subscriptionTier: SubscriptionTier = .none
    @Published var remainingImageStories: Int = 0 // Aylık kalan görselli hikaye
    @Published var freeTrialUsed: Bool = false
    @Published var freeTrialCount: Int = 3 // 3 ücretsiz deneme (toplam)
    @Published var freeImageStoryUsed: Bool = false // Ücretsiz görselli hikaye kullanıldı mı?
    @Published var lastFreeTextStoryDate: Date? // Son ücretsiz metin hikaye tarihi

    // MARK: - Yetki doğrulaması
    //
    // Kademenin kendisi `UserDefaults`'ta duruyor ve orası cihaz sahibinin
    // yazabildiği bir yer. Bu iki alan "bu kademe nereden geldi" sorusunu
    // cevaplıyor; `EntitlementPolicy` kararı ikisine birlikte bakarak veriyor.
    // Yalnızca `RevenueCatManager` yazar — uygulamanın başka hiçbir yerinden
    // doğrulama damgası atılamaz.

    /// RevenueCat `CustomerInfo`'sunun kademeyi en son ne zaman doğruladığı.
    /// `nil` ise hiç doğrulanmadı ve ücretli hiçbir yetenek açılmaz.
    @Published private(set) var entitlementVerifiedAt: Date?

    /// Bu uygulama oturumunda taze doğrulama yapıldı mı.
    /// Kalıcı değil: her açılış yeniden kanıt ister.
    @Published private(set) var isEntitlementVerifiedInThisSession: Bool = false

    /// Doğrulama damgasını atar. Tek çağıran `RevenueCatManager`.
    func recordEntitlementVerification(at date: Date = Date()) {
        entitlementVerifiedAt = date
        isEntitlementVerifiedInThisSession = true
        UserDefaults.standard.set(date, forKey: Self.entitlementVerifiedAtKey)
    }

    fileprivate static let entitlementVerifiedAtKey = "mp_entitlementVerifiedAt"
    
    // Ücretsiz kullanıcı için 12 saatte 1 metin hikaye
    var canCreateFreeTextStory: Bool {
        guard subscriptionTier == .none else { return true } // Üyeler sınırsız
        
        guard let lastDate = lastFreeTextStoryDate else {
            return true // İlk hikaye
        }
        
        let hoursSinceLastStory = Date().timeIntervalSince(lastDate) / 3600
        return hoursSinceLastStory >= 12
    }
    
    var hoursUntilNextFreeStory: Int {
        guard let lastDate = lastFreeTextStoryDate else { return 0 }
        
        let hoursSinceLastStory = Date().timeIntervalSince(lastDate) / 3600
        let hoursRemaining = max(0, 12 - hoursSinceLastStory)
        return Int(ceil(hoursRemaining))
    }
    
    // Hikaye Kulübü paketleri
    enum SubscriptionTier: String, Codable {
        case none = "none"
        case basic = "basic"      // ₺89/ay - 1 görselli
        case premium = "premium"  // ₺149/ay - 5 görselli
        case ultimate = "ultimate" // ₺349/ay - 10 görselli
        
        var displayName: String {
            switch self {
            case .none: return "Ücretsiz"
            case .basic: return "⭐ Yıldız Kaşifi"
            case .premium: return "👑 Hikaye Kahramanı"
            case .ultimate: return "🌟 Sihir Ustası"
            }
        }
        
        var monthlyImageStories: Int {
            switch self {
            case .none: return 0
            case .basic: return 1
            case .premium: return 5
            case .ultimate: return 10
            }
        }
        
        var price: String {
            switch self {
            case .none: return "₺0"
            case .basic: return "₺89"
            case .premium: return "₺149"
            case .ultimate: return "₺349"
            }
        }
        
        var priceValue: Double {
            switch self {
            case .none: return 0
            case .basic: return 89.0
            case .premium: return 149.0
            case .ultimate: return 349.0
            }
        }
    }
    
    // Hikaye Kulübü paket bilgileri
    struct SubscriptionPackage {
        let tier: SubscriptionTier
        let title: String
        let price: String
        let priceValue: Double
        let features: [String]
        let isPopular: Bool
    }
    
    static let subscriptionPackages: [SubscriptionPackage] = [
        SubscriptionPackage(
            tier: .basic,
            title: "⭐ Yıldız Kaşifi",
            price: "₺89",
            priceValue: 89.0,
            features: [
                "Sınırsız metin hikaye",
                "Sınırsız günlük hikaye",
                "1 görselli hikaye/ay"
            ],
            isPopular: false
        ),
        SubscriptionPackage(
            tier: .premium,
            title: "👑 Hikaye Kahramanı",
            price: "₺149",
            priceValue: 149.0,
            features: [
                "Sınırsız metin hikaye",
                "Sınırsız günlük hikaye",
                "5 görselli hikaye/ay"
            ],
            isPopular: true
        ),
        SubscriptionPackage(
            tier: .ultimate,
            title: "🌟 Sihir Ustası",
            price: "₺349",
            priceValue: 349.0,
            features: [
                "Sınırsız metin hikaye",
                "Sınırsız günlük hikaye",
                "10 görselli hikaye/ay",
                "Öncelikli destek"
            ],
            isPopular: false
        )
    ]
    
    private init() {
        // UserDefaults'tan üyelik bilgilerini yükle
        if let savedTier = UserDefaults.standard.string(forKey: "subscriptionTier"),
           let tier = SubscriptionTier(rawValue: savedTier) {
            subscriptionTier = tier
        }
        
        remainingImageStories = UserDefaults.standard.integer(forKey: "remainingImageStories")
        freeTrialUsed = UserDefaults.standard.bool(forKey: "freeTrialUsed")
        freeTrialCount = UserDefaults.standard.integer(forKey: "freeTrialCount")
        freeImageStoryUsed = UserDefaults.standard.bool(forKey: "freeImageStoryUsed")
        
        if let savedDate = UserDefaults.standard.object(forKey: "lastFreeTextStoryDate") as? Date {
            lastFreeTextStoryDate = savedDate
        }

        // Damga yüklenir ama `isEntitlementVerifiedInThisSession` bilerek
        // `false` kalır: geçmiş bir doğrulama, tolerans penceresi içinde
        // `.cached` güveni verir; taze güveni vermez.
        entitlementVerifiedAt = UserDefaults.standard.object(
            forKey: Self.entitlementVerifiedAtKey) as? Date
        
        // İlk açılış kontrolü
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            freeTrialCount = 3
            freeTrialUsed = false
            freeImageStoryUsed = false
            UserDefaults.standard.set(3, forKey: "freeTrialCount")
            UserDefaults.standard.set(false, forKey: "freeImageStoryUsed")
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
        
        // Aylık görselli hikaye kotasını sıfırla (ay değiştiyse)
        checkAndResetMonthlyQuota()
    }
    
    // Aylık kotayı kontrol et ve sıfırla
    private func checkAndResetMonthlyQuota() {
        let calendar = Calendar.current
        let now = Date()
        
        if let lastReset = UserDefaults.standard.object(forKey: "lastQuotaReset") as? Date {
            let lastMonth = calendar.component(.month, from: lastReset)
            let currentMonth = calendar.component(.month, from: now)
            
            if lastMonth != currentMonth {
                // Ay değişti, kotayı sıfırla
                remainingImageStories = subscriptionTier.monthlyImageStories
                UserDefaults.standard.set(remainingImageStories, forKey: "remainingImageStories")
                UserDefaults.standard.set(now, forKey: "lastQuotaReset")
            }
        } else {
            // İlk kez, kotayı ayarla
            remainingImageStories = subscriptionTier.monthlyImageStories
            UserDefaults.standard.set(now, forKey: "lastQuotaReset")
        }
    }
    
    // Hikaye Kulübü üyeliği satın al
    func purchaseSubscription(tier: SubscriptionTier) {
        subscriptionTier = tier
        remainingImageStories = tier.monthlyImageStories
        
        UserDefaults.standard.set(tier.rawValue, forKey: "subscriptionTier")
        UserDefaults.standard.set(remainingImageStories, forKey: "remainingImageStories")
        UserDefaults.standard.set(Date(), forKey: "lastQuotaReset")
    }
    
    // Üyeliği iptal et
    func cancelSubscription() {
        subscriptionTier = .none
        remainingImageStories = 0
        
        UserDefaults.standard.set(SubscriptionTier.none.rawValue, forKey: "subscriptionTier")
        UserDefaults.standard.set(0, forKey: "remainingImageStories")

        // Abonelik yoksa doğrulama damgası da anlamsız: bırakılırsa bayat bir
        // damga sonraki bir kademe yazısına güven devretmiş olurdu.
        entitlementVerifiedAt = nil
        isEntitlementVerifiedInThisSession = false
        UserDefaults.standard.removeObject(forKey: Self.entitlementVerifiedAtKey)
    }
    
    // Hikaye oluşturabilir mi?
    func canCreateStory(type: StoryType) -> Bool {
        switch type {
        case .text:
            // Metin hikaye: Üyelik VEYA 12 saatte 1 ücretsiz VEYA deneme
            if subscriptionTier != .none {
                return true // Üyeler sınırsız
            }
            if freeTrialCount > 0 {
                return true // Deneme hakkı var
            }
            return canCreateFreeTextStory // 12 saatlik kontrol
            
        case .daily:
            // Günlük hikaye: Üyelik veya ücretsiz deneme
            if subscriptionTier != .none {
                return true // Üyeler sınırsız
            }
            return freeTrialCount > 0 // Deneme hakkı var
            
        case .image:
            // Görselli hikaye: Üyelik kotası VEYA (deneme hakkı var VE görselli henüz kullanılmadı)
            if subscriptionTier != .none {
                return remainingImageStories > 0 // Üyeler kota kontrolü
            }
            // Ücretsiz kullanıcı: Deneme hakkı var VE görselli hikaye henüz kullanılmadı
            return freeTrialCount > 0 && !freeImageStoryUsed
        }
    }
    
    // Hikaye oluştur (kotayı düş)
    func useStory(type: StoryType) -> Bool {
        // Önce ücretsiz deneme kontrolü
        if freeTrialCount > 0 && subscriptionTier == .none {
            // Görselli hikaye için özel kontrol
            if type == .image {
                if freeImageStoryUsed {
                    // Görselli hikaye zaten kullanılmış
                    return false
                }
                // Görselli hikaye kullanımını işaretle
                freeImageStoryUsed = true
                UserDefaults.standard.set(true, forKey: "freeImageStoryUsed")
            }
            
            // Deneme hakkını düş
            freeTrialCount -= 1
            UserDefaults.standard.set(freeTrialCount, forKey: "freeTrialCount")
            
            if freeTrialCount == 0 {
                freeTrialUsed = true
                UserDefaults.standard.set(true, forKey: "freeTrialUsed")
            }
            return true
        }
        
        // Hikaye Kulübü kontrolü
        switch type {
        case .text:
            if subscriptionTier != .none {
                return true // Üyeler sınırsız
            }
            // Ücretsiz kullanıcı - 12 saatlik kontrol
            if canCreateFreeTextStory {
                lastFreeTextStoryDate = Date()
                UserDefaults.standard.set(lastFreeTextStoryDate, forKey: "lastFreeTextStoryDate")
                return true
            }
            return false
            
        case .daily:
            return subscriptionTier != .none
            
        case .image:
            if remainingImageStories > 0 {
                remainingImageStories -= 1
                UserDefaults.standard.set(remainingImageStories, forKey: "remainingImageStories")
                return true
            }
            return false
        }
    }
    
#if DEBUG
    // MARK: - Geliştirici yardımcıları
    //
    // Yalnızca DEBUG derlemesinde derlenir. Release'te bu kod hiç bulunmaz —
    // yayınlanan uygulamada satın almayı baypas eden bir yol olmamalı.

    /// Test için yıldız ekler. Ücretsiz kullanıcıda deneme hakkını, üyede
    /// aylık görselli kotayı büyütür; tek seferlik görselli kilidi de açar.
    func grantTrialStars(_ count: Int = 5) {
        if subscriptionTier == .none {
            freeTrialCount += count
            freeTrialUsed = false
            freeImageStoryUsed = false
            lastFreeTextStoryDate = nil

            UserDefaults.standard.set(freeTrialCount, forKey: "freeTrialCount")
            UserDefaults.standard.set(false, forKey: "freeTrialUsed")
            UserDefaults.standard.set(false, forKey: "freeImageStoryUsed")
            UserDefaults.standard.removeObject(forKey: "lastFreeTextStoryDate")
        } else {
            remainingImageStories += count
            UserDefaults.standard.set(remainingImageStories, forKey: "remainingImageStories")
        }
        print("🧪 \(count) deneme yıldızı eklendi")
    }
#endif

    // Premium mu?
    var isPremium: Bool {
        return subscriptionTier != .none
    }
    
    // Test için üyelik değiştir
    func toggleSubscription() {
        if subscriptionTier == .none {
            purchaseSubscription(tier: .basic)
        } else if subscriptionTier == .basic {
            purchaseSubscription(tier: .premium)
        } else if subscriptionTier == .premium {
            purchaseSubscription(tier: .ultimate)
        } else {
            cancelSubscription()
        }
    }
    
    // Geriye dönük uyumluluk için (eski kodlar)
    var credits: Int {
        return remainingImageStories * 50 // Görselli hikaye sayısını kredi gibi göster
    }
    
    func addCredits(_ amount: Int) {
        // Artık kullanılmıyor ama geriye dönük uyumluluk için
    }
    
    func spendCredits(_ amount: Int) -> Bool {
        // Artık kullanılmıyor ama geriye dönük uyumluluk için
        return false
    }
    
    // Günlük hikaye kullanımı (eski kod için - artık kullanılmıyor)
    func incrementDailyStoryUsage() {
        // Artık kullanılmıyor
    }
}

// Hikaye türleri
enum StoryType {
    case text
    case image
    case daily
}
