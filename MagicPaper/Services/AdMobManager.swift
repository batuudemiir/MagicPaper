import Foundation
import GoogleMobileAds
import UIKit
import AppTrackingTransparency

class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()
    
    @Published var isAdReady = false
    private var interstitialAd: GADInterstitialAd?
    
    // AdMob reklam birimi ID'si
    private let adUnitID = "ca-app-pub-5040506160335506/9277719944"
    
    private override init() {
        super.init()
    }
    
    // Google Mobile Ads SDK'yı başlat
    func initializeSDK() {
        // Tracking iznini kontrol et
        checkTrackingAuthorization()
        
        GADMobileAds.sharedInstance().start { status in
            print("✅ AdMob SDK başlatıldı")
            print("📊 Tracking Status: \(ATTrackingManager.trackingAuthorizationStatus.rawValue)")
            // İlk reklamı yükle
            self.loadInterstitialAd()
        }
    }
    
    // Tracking iznini kontrol et
    private func checkTrackingAuthorization() {
        let status = ATTrackingManager.trackingAuthorizationStatus
        switch status {
        case .authorized:
            print("✅ Tracking izni verildi - Kişiselleştirilmiş reklamlar gösterilebilir")
        case .denied:
            print("⚠️ Tracking izni reddedildi - Genel reklamlar gösterilecek")
        case .restricted:
            print("⚠️ Tracking kısıtlı - Genel reklamlar gösterilecek")
        case .notDetermined:
            print("⏳ Tracking izni henüz istenmedi")
        @unknown default:
            print("❓ Bilinmeyen tracking durumu")
        }
    }
    
    // Geçiş reklamını yükle
    func loadInterstitialAd() {
        let request = GADRequest()
        
        print("📥 Reklam yükleniyor...")
        
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("❌ Reklam yüklenemedi: \(error.localizedDescription)")
                self?.isAdReady = false
                return
            }
            
            self?.interstitialAd = ad
            self?.interstitialAd?.fullScreenContentDelegate = self
            self?.isAdReady = true
            print("✅ Reklam başarıyla yüklendi")
        }
    }
    
    // Reklamı göster
    func showInterstitialAd() {
        guard let interstitialAd = interstitialAd else {
            print("⚠️ Reklam hazır değil")
            loadInterstitialAd()
            return
        }
        
        // Root view controller'ı bul
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ Root view controller bulunamadı")
            return
        }
        
        print("🎬 Reklam gösteriliyor...")
        interstitialAd.present(fromRootViewController: rootViewController)
    }
}

// MARK: - GADFullScreenContentDelegate
extension AdMobManager: GADFullScreenContentDelegate {
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        print("📊 Reklam gösterildi")
    }
    
    func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        print("👆 Reklama tıklandı")
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Reklam gösterilemedi: \(error.localizedDescription)")
        isAdReady = false
        loadInterstitialAd()
    }
    
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("🎬 Reklam açılıyor")
    }
    
    func adWillDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("👋 Reklam kapatılıyor")
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("✅ Reklam kapatıldı")
        isAdReady = false
        // Yeni reklam yükle
        loadInterstitialAd()
    }
}
