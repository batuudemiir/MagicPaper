# RevenueCat Entegrasyon Rehberi

## 🎯 Neden RevenueCat?

RevenueCat, abonelik yönetimini kolaylaştırır:
- ✅ StoreKit 2 otomasyonu
- ✅ Sunucu taraflı makbuz doğrulama
- ✅ Çapraz platform destek (iOS, Android, Web)
- ✅ Analitik ve raporlama
- ✅ A/B test desteği
- ✅ Webhook'lar
- ✅ Restore purchases otomasyonu

## 📦 Adım 1: RevenueCat Hesabı Oluşturma

1. https://app.revenuecat.com/signup adresine git
2. Ücretsiz hesap oluştur
3. Yeni bir proje oluştur: "MagicPaper"
4. iOS uygulaması ekle
5. Bundle ID'yi gir: `com.yourcompany.magicpaper`

## 🔑 Adım 2: API Key Alma

1. RevenueCat Dashboard > Project Settings
2. API Keys bölümüne git
3. "Public API Key" kopyala (örnek: `appl_xxxxxxxxxx`)
4. Bu key'i Secrets.xcconfig dosyasına ekle

## 📝 Adım 3: Secrets.xcconfig Güncelleme

```bash
# Secrets.xcconfig dosyasına ekle:
REVENUECAT_API_KEY = appl_xxxxxxxxxx
```

## 🛍️ Adım 4: App Store Connect'te Ürün Oluşturma

### In-App Purchase Ürünleri

App Store Connect > My Apps > MagicPaper > In-App Purchases

**1. Yıldız Kaşifi (Basic)**
- Product ID: `magicpaper_basic_monthly`
- Type: Auto-Renewable Subscription
- Price: ₺89.99
- Duration: 1 Month
- Display Name (TR): Yıldız Kaşifi
- Display Name (EN): Star Explorer
- Description: 1 görselli hikaye/ay + Sınırsız metin

**2. Hikaye Kahramanı (Premium)**
- Product ID: `magicpaper_premium_monthly`
- Type: Auto-Renewable Subscription
- Price: ₺149.99
- Duration: 1 Month
- Display Name (TR): Hikaye Kahramanı
- Display Name (EN): Story Hero
- Description: 5 görselli hikaye/ay + Sınırsız metin

**3. Sihir Ustası (Ultimate)**
- Product ID: `magicpaper_ultimate_monthly`
- Type: Auto-Renewable Subscription
- Price: ₺349.99
- Duration: 1 Month
- Display Name (TR): Sihir Ustası
- Display Name (EN): Magic Master
- Description: 10 görselli hikaye/ay + Sınırsız metin

### Subscription Group

- Group Name: "Hikaye Kulübü"
- Rank: 1 (Basic), 2 (Premium), 3 (Ultimate)

## 🔧 Adım 5: RevenueCat Dashboard Konfigürasyonu

### Entitlements Oluşturma

1. Dashboard > Entitlements > Create Entitlement
2. Identifier: `premium`
3. Display Name: "Premium Access"

### Products Ekleme

1. Dashboard > Products > Add Product
2. Her bir ürün için:
   - Product ID: `magicpaper_basic_monthly`
   - Store: App Store
   - Entitlement: `premium`
   - Repeat for all 3 products

### Offerings Oluşturma

1. Dashboard > Offerings > Create Offering
2. Identifier: `default`
3. Display Name: "Hikaye Kulübü Paketleri"
4. Packages ekle:
   - Package 1: `$rc_monthly_basic` → `magicpaper_basic_monthly`
   - Package 2: `$rc_monthly_premium` → `magicpaper_premium_monthly`
   - Package 3: `$rc_monthly_ultimate` → `magicpaper_ultimate_monthly`

## 📦 Adım 6: SPM ile RevenueCat Ekleme

### Xcode'da:

1. File > Add Package Dependencies
2. URL gir: `https://github.com/RevenueCat/purchases-ios-spm.git`
3. Version: "Up to Next Major" - 5.0.0
4. Add to Target: MagicPaper
5. Import: `RevenueCat`

### Veya project.pbxproj'e manuel ekle:

```
// Package.resolved dosyasına eklenecek
```

## 💻 Adım 7: Kod Entegrasyonu

### 7.1 MagicPaperApp.swift Güncelleme

```swift
import SwiftUI
import RevenueCat

@main
struct MagicPaperApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    init() {
        // RevenueCat konfigürasyonu
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String {
            Purchases.logLevel = .debug // Production'da .info yapın
            Purchases.configure(withAPIKey: apiKey)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(subscriptionManager)
        }
    }
}
```

### 7.2 Info.plist Güncelleme

```xml
<key>REVENUECAT_API_KEY</key>
<string>$(REVENUECAT_API_KEY)</string>
```

### 7.3 Yeni RevenueCatManager.swift Oluşturma

```swift
import Foundation
import RevenueCat
import Combine

class RevenueCatManager: ObservableObject {
    static let shared = RevenueCatManager()
    
    @Published var customerInfo: CustomerInfo?
    @Published var offerings: Offerings?
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Customer info değişikliklerini dinle
        Purchases.shared.getCustomerInfoPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                self?.customerInfo = info
                self?.updateSubscriptionManager(with: info)
            }
            .store(in: &cancellables)
        
        // Offerings'i yükle
        fetchOfferings()
    }
    
    // Offerings'i getir
    func fetchOfferings() {
        isLoading = true
        
        Purchases.shared.getOfferings { [weak self] offerings, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ RevenueCat offerings error: \(error.localizedDescription)")
                    return
                }
                
                self?.offerings = offerings
                print("✅ RevenueCat offerings loaded: \(offerings?.all.count ?? 0)")
            }
        }
    }
    
    // Satın alma
    func purchase(package: Package, completion: @escaping (Bool, Error?) -> Void) {
        isLoading = true
        
        Purchases.shared.purchase(package: package) { [weak self] transaction, customerInfo, error, userCancelled in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if userCancelled {
                    print("⚠️ User cancelled purchase")
                    completion(false, nil)
                    return
                }
                
                if let error = error {
                    print("❌ Purchase error: \(error.localizedDescription)")
                    completion(false, error)
                    return
                }
                
                if let customerInfo = customerInfo {
                    self?.customerInfo = customerInfo
                    self?.updateSubscriptionManager(with: customerInfo)
                    print("✅ Purchase successful")
                    completion(true, nil)
                }
            }
        }
    }
    
    // Restore purchases
    func restorePurchases(completion: @escaping (Bool, Error?) -> Void) {
        isLoading = true
        
        Purchases.shared.restorePurchases { [weak self] customerInfo, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Restore error: \(error.localizedDescription)")
                    completion(false, error)
                    return
                }
                
                if let customerInfo = customerInfo {
                    self?.customerInfo = customerInfo
                    self?.updateSubscriptionManager(with: customerInfo)
                    print("✅ Restore successful")
                    completion(true, nil)
                }
            }
        }
    }
    
    // SubscriptionManager'ı güncelle
    private func updateSubscriptionManager(with customerInfo: CustomerInfo) {
        let hasPremium = customerInfo.entitlements["premium"]?.isActive == true
        
        if hasPremium {
            // Hangi paketi aldığını belirle
            if customerInfo.activeSubscriptions.contains("magicpaper_ultimate_monthly") {
                SubscriptionManager.shared.purchaseSubscription(tier: .ultimate)
            } else if customerInfo.activeSubscriptions.contains("magicpaper_premium_monthly") {
                SubscriptionManager.shared.purchaseSubscription(tier: .premium)
            } else if customerInfo.activeSubscriptions.contains("magicpaper_basic_monthly") {
                SubscriptionManager.shared.purchaseSubscription(tier: .basic)
            }
        } else {
            SubscriptionManager.shared.cancelSubscription()
        }
    }
    
    // Premium kontrolü
    var isPremium: Bool {
        customerInfo?.entitlements["premium"]?.isActive == true
    }
}
```

### 7.4 SimpleSubscriptionView.swift Güncelleme

```swift
// En üste ekle
@StateObject private var revenueCatManager = RevenueCatManager.shared

// makePurchase() fonksiyonunu güncelle
private func makePurchase() {
    guard let package = selectedPackage else { return }
    
    // RevenueCat offerings'den paketi bul
    guard let offerings = revenueCatManager.offerings,
          let currentOffering = offerings.current else {
        alertMessage = "Paketler yüklenemedi. Lütfen tekrar deneyin."
        showingPurchaseAlert = true
        return
    }
    
    // Package ID'ye göre paketi bul
    let packageIdentifier: String
    switch package.tier {
    case .basic:
        packageIdentifier = "$rc_monthly_basic"
    case .premium:
        packageIdentifier = "$rc_monthly_premium"
    case .ultimate:
        packageIdentifier = "$rc_monthly_ultimate"
    default:
        return
    }
    
    guard let rcPackage = currentOffering.availablePackages.first(where: { 
        $0.identifier == packageIdentifier 
    }) else {
        alertMessage = "Paket bulunamadı."
        showingPurchaseAlert = true
        return
    }
    
    // RevenueCat ile satın al
    revenueCatManager.purchase(package: rcPackage) { success, error in
        if success {
            let dailyCost = Int(package.priceValue / 30)
            
            alertMessage = L.tr("""
            \(package.title) başarıyla aktif edildi!
            
            🎨 \(package.tier.monthlyImageStories) görselli hikaye/ay
            📚 Sınırsız metin hikaye
            🌟 Sınırsız günlük hikaye
            
            Günde sadece \(dailyCost)₺ ile çocuğunuza okuma alışkanlığı kazandırın!
            """, """
            \(package.title) successfully activated!
            
            🎨 \(package.tier.monthlyImageStories) illustrated stories/month
            📚 Unlimited text stories
            🌟 Unlimited daily stories
            
            Build reading habit for only $\(dailyCost)/day!
            """)
            
            showingPurchaseAlert = true
        } else if let error = error {
            alertMessage = L.tr(
                "Satın alma başarısız: \(error.localizedDescription)",
                "Purchase failed: \(error.localizedDescription)"
            )
            showingPurchaseAlert = true
        }
    }
}

// Restore purchases butonu ekle
private var restoreButton: some View {
    Button(action: {
        revenueCatManager.restorePurchases { success, error in
            if success {
                alertMessage = L.tr(
                    "Satın alımlarınız geri yüklendi!",
                    "Purchases restored!"
                )
            } else {
                alertMessage = L.tr(
                    "Geri yükleme başarısız.",
                    "Restore failed."
                )
            }
            showingPurchaseAlert = true
        }
    }) {
        Text(L.tr("Satın Alımları Geri Yükle", "Restore Purchases"))
            .font(.caption)
            .foregroundColor(.blue)
    }
}
```

## 🧪 Adım 8: Test Etme

### Sandbox Test

1. Settings > App Store > Sandbox Account
2. Test kullanıcısı oluştur (App Store Connect)
3. Uygulamayı çalıştır
4. Satın alma yap
5. RevenueCat Dashboard'da kontrol et

### Test Checklist

- [ ] Offerings yükleniyor mu?
- [ ] Paketler görünüyor mu?
- [ ] Satın alma çalışıyor mu?
- [ ] Restore purchases çalışıyor mu?
- [ ] Premium özelliklere erişim var mı?
- [ ] RevenueCat Dashboard'da görünüyor mu?

## 📊 Adım 9: Analytics ve Monitoring

### RevenueCat Dashboard

- Customer List: Tüm kullanıcılar
- Charts: Gelir grafikleri
- Events: Satın alma olayları
- Webhooks: Sunucu entegrasyonu

### Custom Events

```swift
// Özel event gönderme
Purchases.shared.logIn("user_id") { customerInfo, created, error in
    // User identified
}
```

## 🚀 Adım 10: Production'a Geçiş

### Checklist

- [ ] API Key production key ile değiştirildi
- [ ] Log level `.info` veya `.warn` yapıldı
- [ ] Test kodları kaldırıldı
- [ ] App Store Connect'te ürünler onaylandı
- [ ] RevenueCat Dashboard production mode
- [ ] Webhook'lar konfigüre edildi (opsiyonel)

### Production Konfigürasyonu

```swift
// MagicPaperApp.swift
Purchases.logLevel = .info // veya .warn
Purchases.configure(withAPIKey: apiKey)
```

## 🔒 Güvenlik

### API Key Güvenliği

- ✅ Public API Key kullan (client-side)
- ✅ Secret Key'i asla kodda kullanma
- ✅ Secrets.xcconfig'de sakla
- ✅ .gitignore'a ekle

### Makbuz Doğrulama

RevenueCat otomatik olarak:
- ✅ Makbuzları doğrular
- ✅ Sahte satın almaları engeller
- ✅ Sunucu taraflı kontrol yapar

## 📚 Ek Kaynaklar

- RevenueCat Docs: https://docs.revenuecat.com/
- iOS SDK: https://docs.revenuecat.com/docs/ios
- Sample Apps: https://github.com/RevenueCat/purchases-ios/tree/main/Examples
- Community: https://community.revenuecat.com/

## 🆘 Sorun Giderme

### Offerings yüklenmiyor

```swift
// Debug log'ları kontrol et
Purchases.logLevel = .debug
```

### Satın alma başarısız

- Sandbox hesabı doğru mu?
- Product ID'ler eşleşiyor mu?
- App Store Connect'te ürünler onaylı mı?

### Restore çalışmıyor

- Aynı Apple ID kullanılıyor mu?
- Sandbox hesabı doğru mu?

## 💡 İpuçları

1. **Test Sırasında**: Sandbox hesabı kullan
2. **Production'da**: Gerçek hesap kullan
3. **Debugging**: Log level'ı debug yap
4. **Analytics**: RevenueCat Dashboard'u düzenli kontrol et
5. **A/B Testing**: RevenueCat Experiments kullan

---

**Sonraki Adım**: RevenueCat hesabı oluştur ve API key al, sonra entegrasyona başla!
