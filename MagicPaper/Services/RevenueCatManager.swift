import Foundation
import OSLog
#if canImport(RevenueCat)
import RevenueCat
#endif
import Combine

/// `print` reaches the shared device console verbatim. `Logger` redacts
/// interpolated values as `<private>` outside a debugger by default.
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "RevenueCatManager")

#if canImport(RevenueCat)
class RevenueCatManager: ObservableObject {
    static let shared = RevenueCatManager()
    
    @Published var customerInfo: CustomerInfo?
    @Published var offerings: Offerings?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        logger.debug("🔑 RevenueCatManager: Initializing...")

        // Purchases.configure() henüz çalışmadıysa `Purchases.shared` çöker.
        // AppDelegate'ten önce dokunulma ihtimaline karşı koruma.
        guard Purchases.isConfigured else {
            logger.warning("⚠️ RevenueCat henüz yapılandırılmadı — offerings yüklenmeyecek")
            return
        }

        // Customer info değişikliklerini dinle
        Purchases.shared.getCustomerInfo { [weak self] info, error in
            DispatchQueue.main.async {
                if let error = error {
                    logger.error("❌ RevenueCat customer info error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                if let info = info {
                    logger.debug("✅ RevenueCat customer info loaded")
                    self?.customerInfo = info
                    self?.updateSubscriptionManager(with: info)
                }
            }
        }
        
        // Offerings'i yükle
        fetchOfferings()
    }
    
    // MARK: - Customer info

    /// Yetki durumunu kaynaktan tazeler.
    ///
    /// `EntitlementService.refresh()` buraya iner. Çevrimdışı tolerans
    /// penceresini yenileyen tek yol bu; uygulamanın kendi kendine "doğrulandı"
    /// diyebildiği başka bir kapı bilerek yok.
    func refreshCustomerInfo() {
        guard Purchases.isConfigured else {
            errorMessage = "RevenueCat yapılandırılmadı"
            return
        }
        Purchases.shared.getCustomerInfo { [weak self] info, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Hata durumunda damgaya dokunulmaz: mevcut damga yaşlanmaya
                    // devam eder ve pencere dolunca yetki kendiliğinden düşer.
                    self?.errorMessage = error.localizedDescription
                    return
                }
                guard let info = info else { return }
                self?.customerInfo = info
                self?.updateSubscriptionManager(with: info)
            }
        }
    }

    // MARK: - Offerings
    
    func fetchOfferings() {
        guard Purchases.isConfigured else {
            errorMessage = "RevenueCat yapılandırılmadı"
            return
        }
        logger.debug("📦 RevenueCat: Fetching offerings...")
        isLoading = true
        errorMessage = nil
        
        Purchases.shared.getOfferings { [weak self] offerings, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    logger.error("❌ RevenueCat offerings error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                if let offerings = offerings {
                    self?.offerings = offerings
                    logger.debug("✅ RevenueCat offerings loaded: \(offerings.all.count) offerings")
                    
                    if let current = offerings.current {
                        logger.debug("📦 Current offering: \(current.identifier)")
                        logger.debug("📦 Available packages: \(current.availablePackages.count)")
                        
                        for package in current.availablePackages {
                            logger.debug("   - \(package.identifier): \(package.storeProduct.localizedPriceString)")
                        }
                    } else {
                        logger.warning("⚠️ No current offering found")
                    }
                } else {
                    logger.warning("⚠️ No offerings returned")
                }
            }
        }
    }
    
    // MARK: - Purchase
    
    func purchase(package: Package, completion: @escaping (Bool, Error?) -> Void) {
        guard Purchases.isConfigured else {
            completion(false, nil)
            return
        }
        logger.debug("💳 RevenueCat: Purchasing package \(package.identifier)...")
        isLoading = true
        errorMessage = nil
        
        Purchases.shared.purchase(package: package) { [weak self] transaction, customerInfo, error, userCancelled in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if userCancelled {
                    logger.warning("⚠️ User cancelled purchase")
                    completion(false, nil)
                    return
                }
                
                if let error = error {
                    logger.error("❌ Purchase error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    completion(false, error)
                    return
                }
                
                if let customerInfo = customerInfo {
                    logger.debug("✅ Purchase successful!")
                    self?.customerInfo = customerInfo
                    self?.updateSubscriptionManager(with: customerInfo)
                    completion(true, nil)
                } else {
                    logger.warning("⚠️ Purchase completed but no customer info")
                    completion(false, nil)
                }
            }
        }
    }
    
    // MARK: - Restore
    
    func restorePurchases(completion: @escaping (Bool, Error?) -> Void) {
        logger.debug("🔄 RevenueCat: Restoring purchases...")
        isLoading = true
        errorMessage = nil
        
        Purchases.shared.restorePurchases { [weak self] customerInfo, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    logger.error("❌ Restore error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    completion(false, error)
                    return
                }
                
                if let customerInfo = customerInfo {
                    logger.debug("✅ Restore successful")
                    self?.customerInfo = customerInfo
                    self?.updateSubscriptionManager(with: customerInfo)
                    
                    let hasPremium = customerInfo.entitlements["premium"]?.isActive == true
                    if hasPremium {
                        logger.debug("✅ Premium entitlement restored")
                    } else {
                        logger.debug("ℹ️ No active subscriptions found")
                    }
                    
                    completion(true, nil)
                } else {
                    logger.warning("⚠️ Restore completed but no customer info")
                    completion(false, nil)
                }
            }
        }
    }
    
    // MARK: - Subscription Manager Integration
    
    private func updateSubscriptionManager(with customerInfo: CustomerInfo) {
        let hasPremium = customerInfo.entitlements["premium"]?.isActive == true
        
        logger.debug("🔄 Updating SubscriptionManager...")
        logger.debug("   Premium active: \(hasPremium)")
        logger.debug("   Active subscriptions: \(customerInfo.activeSubscriptions)")
        
        if hasPremium {
            // Hangi paketi aldığını belirle
            if customerInfo.activeSubscriptions.contains("magicpaper_ultimate_monthly") {
                logger.debug("   → Setting tier: Ultimate")
                SubscriptionManager.shared.purchaseSubscription(tier: .ultimate)
            } else if customerInfo.activeSubscriptions.contains("magicpaper_premium_monthly") {
                logger.debug("   → Setting tier: Premium")
                SubscriptionManager.shared.purchaseSubscription(tier: .premium)
            } else if customerInfo.activeSubscriptions.contains("magicpaper_basic_monthly") {
                logger.debug("   → Setting tier: Basic")
                SubscriptionManager.shared.purchaseSubscription(tier: .basic)
            } else {
                logger.debug("   → Unknown subscription, setting to Basic")
                SubscriptionManager.shared.purchaseSubscription(tier: .basic)
            }

            // Kademe `CustomerInfo`'dan geldi — yalnızca burada damga atılır.
            // `EntitlementPolicy` ücretli yetenekleri bu damgaya bakarak açar;
            // damgasız bir `UserDefaults` kademesi premium açmaz.
            SubscriptionManager.shared.recordEntitlementVerification()
        } else {
            logger.debug("   → No premium, cancelling subscription")
            SubscriptionManager.shared.cancelSubscription()
        }
    }
    
    // MARK: - Helpers
    
    var isPremium: Bool {
        customerInfo?.entitlements["premium"]?.isActive == true
    }
    
    var activeSubscriptionTier: SubscriptionManager.SubscriptionTier {
        guard let customerInfo = customerInfo,
              customerInfo.entitlements["premium"]?.isActive == true else {
            return .none
        }
        
        if customerInfo.activeSubscriptions.contains("magicpaper_ultimate_monthly") {
            return .ultimate
        } else if customerInfo.activeSubscriptions.contains("magicpaper_premium_monthly") {
            return .premium
        } else if customerInfo.activeSubscriptions.contains("magicpaper_basic_monthly") {
            return .basic
        }
        
        return .none
    }
    
    /// Abonelik dönemi. Yıllık ürünler App Store Connect'te açıldığında
    /// `magicpaper_<tier>_yearly` kimlikleriyle otomatik eşleşir.
    enum BillingPeriod: String {
        case monthly, yearly
    }

    func productIdentifier(for tier: SubscriptionManager.SubscriptionTier,
                           period: BillingPeriod) -> String? {
        let base: String
        switch tier {
        case .basic:    base = "magicpaper_basic"
        case .premium:  base = "magicpaper_premium"
        case .ultimate: base = "magicpaper_ultimate"
        case .none:     return nil
        }
        return "\(base)_\(period.rawValue)"
    }

    // Package helper - offering'den package bul
    func getPackage(for tier: SubscriptionManager.SubscriptionTier,
                    period: BillingPeriod = .monthly) -> Package? {
        guard let currentOffering = offerings?.current else {
            logger.warning("⚠️ No current offering available")
            return nil
        }
        guard let productId = productIdentifier(for: tier, period: period) else { return nil }

        return currentOffering.availablePackages.first { package in
            package.storeProduct.productIdentifier == productId
        }
    }

    /// StoreKit'ten gelen yerelleştirilmiş fiyat. Ürün yoksa `nil` —
    /// arayüz o zaman sabit referans fiyata düşer.
    func localizedPrice(for tier: SubscriptionManager.SubscriptionTier,
                        period: BillingPeriod = .monthly) -> String? {
        getPackage(for: tier, period: period)?.storeProduct.localizedPriceString
    }

    func hasPackage(for tier: SubscriptionManager.SubscriptionTier,
                    period: BillingPeriod) -> Bool {
        getPackage(for: tier, period: period) != nil
    }

    /// Arayüzün tek çağrı noktası: seçilen plan + dönem için satın alma.
    func purchaseTier(_ tier: SubscriptionManager.SubscriptionTier,
                      period: BillingPeriod,
                      completion: @escaping (Bool, Error?) -> Void) {
        guard let package = getPackage(for: tier, period: period) else {
            logger.warning("⚠️ \(tier.rawValue) / \(period.rawValue) için ürün bulunamadı")
            completion(false, nil)
            return
        }
        purchase(package: package, completion: completion)
    }
}
#else
// RevenueCat modülü yoksa dummy class
class RevenueCatManager: ObservableObject {
    static let shared = RevenueCatManager()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        logger.warning("⚠️ RevenueCatManager: RevenueCat modülü bulunamadı")
    }
    
    enum BillingPeriod: String { case monthly, yearly }

    func fetchOfferings() {
        logger.warning("⚠️ RevenueCat modülü yüklenmedi - Xcode'da package'ı target'a ekleyin")
    }

    /// Modül yokken doğrulanacak bir kaynak da yok; damga atılmaz, dolayısıyla
    /// ücretli yetenekler kapalı kalır.
    func refreshCustomerInfo() {
        logger.warning("⚠️ RevenueCat modülü yüklenmedi - yetki doğrulanamıyor")
    }

    var isPremium: Bool { false }

    func localizedPrice(for tier: SubscriptionManager.SubscriptionTier,
                        period: BillingPeriod = .monthly) -> String? { nil }

    /// Modül yokken satın alma yapılamaz; arayüz yedek akışa düşer.
    func purchaseTier(_ tier: SubscriptionManager.SubscriptionTier,
                      period: BillingPeriod,
                      completion: @escaping (Bool, Error?) -> Void) {
        completion(false, nil)
    }

    func hasPackage(for tier: SubscriptionManager.SubscriptionTier,
                    period: BillingPeriod) -> Bool { false }
}
#endif

