import Foundation
import SwiftUI

// Basit Abonelik Sistemi - Sadece 2 Paket
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var subscriptionTier: SubscriptionTier = .none
    @Published var remainingImageStories: Int = 0 // Aylık kalan görselli hikaye
    @Published var freeTrialUsed: Bool = false
    @Published var freeTrialCount: Int = 3 // 3 ücretsiz deneme
    @Published var lastFreeTextStoryDate: Date? // Son ücretsiz metin hikaye tarihi
    
    // Ücretsiz kullanıcı için 12 saatte 1 metin hikaye
    var canCreateFreeTextStory: Bool {
        guard subscriptionTier == .none else { return true } // Aboneler sınırsız
        
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
    
    // Abonelik paketleri
    enum SubscriptionTier: String, Codable {
        case none = "none"
        case basic = "basic"      // ₺89/ay - 1 görselli
        case premium = "premium"  // ₺149/ay - 5 görselli
        
        var displayName: String {
            switch self {
            case .none: return "Ücretsiz"
            case .basic: return "Temel Paket"
            case .premium: return "Premium Paket"
            }
        }
        
        var monthlyImageStories: Int {
            switch self {
            case .none: return 0
            case .basic: return 1
            case .premium: return 5
            }
        }
        
        var price: String {
            switch self {
            case .none: return "₺0"
            case .basic: return "₺89"
            case .premium: return "₺149"
            }
        }
        
        var priceValue: Double {
            switch self {
            case .none: return 0
            case .basic: return 89.0
            case .premium: return 149.0
            }
        }
    }
    
    // Abonelik paket bilgileri
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
            title: "Temel Paket",
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
            title: "Premium Paket",
            price: "₺149",
            priceValue: 149.0,
            features: [
                "Sınırsız metin hikaye",
                "Sınırsız günlük hikaye",
                "5 görselli hikaye/ay"
            ],
            isPopular: true
        )
    ]
    
    private init() {
        // UserDefaults'tan abonelik bilgilerini yükle
        if let savedTier = UserDefaults.standard.string(forKey: "subscriptionTier"),
           let tier = SubscriptionTier(rawValue: savedTier) {
            subscriptionTier = tier
        }
        
        remainingImageStories = UserDefaults.standard.integer(forKey: "remainingImageStories")
        freeTrialUsed = UserDefaults.standard.bool(forKey: "freeTrialUsed")
        freeTrialCount = UserDefaults.standard.integer(forKey: "freeTrialCount")
        
        if let savedDate = UserDefaults.standard.object(forKey: "lastFreeTextStoryDate") as? Date {
            lastFreeTextStoryDate = savedDate
        }
        
        // İlk açılış kontrolü
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            freeTrialCount = 3
            freeTrialUsed = false
            UserDefaults.standard.set(3, forKey: "freeTrialCount")
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
    
    // Abonelik satın al
    func purchaseSubscription(tier: SubscriptionTier) {
        subscriptionTier = tier
        remainingImageStories = tier.monthlyImageStories
        
        UserDefaults.standard.set(tier.rawValue, forKey: "subscriptionTier")
        UserDefaults.standard.set(remainingImageStories, forKey: "remainingImageStories")
        UserDefaults.standard.set(Date(), forKey: "lastQuotaReset")
    }
    
    // Aboneliği iptal et
    func cancelSubscription() {
        subscriptionTier = .none
        remainingImageStories = 0
        
        UserDefaults.standard.set(SubscriptionTier.none.rawValue, forKey: "subscriptionTier")
        UserDefaults.standard.set(0, forKey: "remainingImageStories")
    }
    
    // Hikaye oluşturabilir mi?
    func canCreateStory(type: StoryType) -> Bool {
        switch type {
        case .text:
            // Metin hikaye: Abonelik VEYA 12 saatte 1 ücretsiz VEYA deneme
            if subscriptionTier != .none {
                return true // Aboneler sınırsız
            }
            if freeTrialCount > 0 {
                return true // Deneme hakkı var
            }
            return canCreateFreeTextStory // 12 saatlik kontrol
            
        case .daily:
            // Günlük hikaye: Abonelik veya ücretsiz deneme
            return subscriptionTier != .none || freeTrialCount > 0
            
        case .image:
            // Görselli hikaye: Abonelik kotası veya ücretsiz deneme
            return remainingImageStories > 0 || freeTrialCount > 0
        }
    }
    
    // Hikaye oluştur (kotayı düş)
    func useStory(type: StoryType) -> Bool {
        // Önce ücretsiz deneme kontrolü
        if freeTrialCount > 0 {
            freeTrialCount -= 1
            UserDefaults.standard.set(freeTrialCount, forKey: "freeTrialCount")
            if freeTrialCount == 0 {
                freeTrialUsed = true
                UserDefaults.standard.set(true, forKey: "freeTrialUsed")
            }
            return true
        }
        
        // Abonelik kontrolü
        switch type {
        case .text:
            if subscriptionTier != .none {
                return true // Aboneler sınırsız
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
    
    // Premium mu?
    var isPremium: Bool {
        return subscriptionTier != .none
    }
    
    // Test için abonelik değiştir
    func toggleSubscription() {
        if subscriptionTier == .none {
            purchaseSubscription(tier: .basic)
        } else if subscriptionTier == .basic {
            purchaseSubscription(tier: .premium)
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
