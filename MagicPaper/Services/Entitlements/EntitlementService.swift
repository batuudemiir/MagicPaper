import Foundation

// MARK: - Snapshot

/// Arayüzün **gösterebileceği** durum. Karar değil, etiket.
///
/// Ayrım kasıtlı: `starCount` ve plan adı gibi şeyler dört ekranda birden
/// `isPremium ? remainingImageStories : freeTrialCount` üçlüsüyle yeniden
/// hesaplanıyordu. O üçlü bir yetki kararı değil, bir bakiye; buraya ait.
public struct EntitlementSnapshot: Equatable, Sendable {

    /// Güven seviyesinden geçirilmiş plan — arayüz her zaman bunu göstermeli,
    /// kayıtlı planı değil.
    public var plan: EntitlementPlan

    /// Bilginin kaynağı. Arayüz "geri yükle" ipucunu buna göre gösterir.
    public var trust: EntitlementTrust

    /// Ekranda "yıldız" denen tek sayı.
    ///
    /// Abonede kalan aylık görselli kota, ücretsiz kullanıcıda kalan deneme
    /// hakkı. Bu seçim burada bir kez yapılır.
    public var storyCredits: Int

    public init(plan: EntitlementPlan, trust: EntitlementTrust, storyCredits: Int) {
        self.plan = plan
        self.trust = trust
        self.storyCredits = storyCredits
    }

    /// Abonelik kartının başlığı.
    public var planDisplayName: String { plan.displayName }

    /// Kayıtlı plan ücretliyken doğrulama düştü mü — "Satın alımları geri yükle"
    /// ipucunun tek koşulu.
    public var needsRestore: Bool {
        if case .unverified = trust { return true }
        if case .cached(let age) = trust {
            return age > EntitlementPolicy.offlineTrustWindow
        }
        return false
    }

    public static func free(trust: EntitlementTrust = .unverified,
                            storyCredits: Int = 0) -> EntitlementSnapshot {
        EntitlementSnapshot(plan: .free, trust: trust, storyCredits: storyCredits)
    }
}

// MARK: - Service

/// Yetki kapısı. Uygulamada `isPremium` soran tek katman burasıdır.
///
///     Capability → EntitlementService → RevenueCat
///
/// Arayüz `evaluate` ile sorar, izin verilirse ölçülen yeteneklerde `consume`
/// ile harcar. `consume`'un `evaluate`'i yeniden çalıştırması kasıtlıdır: soru
/// ile eylem arasında geçen sürede abonelik değişmiş olabilir ve ekranın
/// hatırladığı cevaba güvenmek tam da kaçındığımız şey.
public protocol EntitlementService: AnyObject {

    /// Bu yetenek şu anda kullanılabilir mi, kullanılamıyorsa neden.
    func evaluate(_ capability: Capability) -> EntitlementDecision

    /// Ölçülen bir yeteneği harcar. Kapı yeniden değerlendirilir; kapalıysa
    /// hiçbir sayaç düşmez ve dönen karar reddi taşır.
    ///
    /// Ölçülmeyen yeteneklerde (`Capability.isMetered == false`) tüketim yoktur;
    /// yalnızca değerlendirme döner.
    @discardableResult
    func consume(_ capability: Capability) -> EntitlementDecision

    /// Ekranda gösterilecek plan/bakiye durumu.
    var snapshot: EntitlementSnapshot { get }

    /// Yetki durumunu kaynaktan (RevenueCat) tazeler.
    ///
    /// Çevrimdışı tolerans penceresini yenileyen tek yol budur; arayüzün yerel
    /// bir yazıyla kendini premium yapabilmesi bilerek mümkün değil.
    func refresh()
}

public extension EntitlementService {

    /// Kısa okuma: yalnızca "açık mı" ilgilendiğinde.
    /// Ret sebebine ihtiyaç duyan her yerde `evaluate` kullanılmalı.
    func can(_ capability: Capability) -> Bool {
        evaluate(capability).isAllowed
    }
}
