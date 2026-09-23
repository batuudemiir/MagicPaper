import Foundation

// MARK: - Context

/// Kararın verilebilmesi için gereken **tüm** girdi.
///
/// Politikanın singleton okumamasının, saat sormamasının, `UserDefaults`'a
/// bakmamasının sebebi bu yapı: her şey dışarıdan gelir, dolayısıyla her vaka
/// test edilebilir. `now` bile girdidir — soğuma süresi testi gerçek zamanı
/// beklemez.
public struct EntitlementContext: Equatable, Sendable {

    /// Kayıtlı abonelik kademesi.
    public var plan: EntitlementPlan

    /// Bu kademenin nereden geldiği. Karar `plan`'a değil, `plan` + `trust`'a bakar.
    public var trust: EntitlementTrust

    /// Abonenin bu ayki kalan görselli masal kotası.
    /// (`SubscriptionManager.remainingImageStories`)
    public var illustratedQuotaRemaining: Int

    /// Ücretsiz kullanıcının kalan deneme yıldızı.
    /// (`SubscriptionManager.freeTrialCount`)
    public var trialStarsRemaining: Int

    /// Ücretsiz kullanıcının tek seferlik görselli hakkı harcandı mı.
    /// (`SubscriptionManager.freeImageStoryUsed`)
    public var freeIllustratedStoryUsed: Bool

    /// Son ücretsiz metin masalının zamanı. (`SubscriptionManager.lastFreeTextStoryDate`)
    public var lastFreeTextStoryAt: Date?

    /// Şimdi. Girdi olması kasıtlı.
    public var now: Date

    public init(plan: EntitlementPlan,
                trust: EntitlementTrust,
                illustratedQuotaRemaining: Int,
                trialStarsRemaining: Int,
                freeIllustratedStoryUsed: Bool,
                lastFreeTextStoryAt: Date?,
                now: Date) {
        self.plan = plan
        self.trust = trust
        self.illustratedQuotaRemaining = illustratedQuotaRemaining
        self.trialStarsRemaining = trialStarsRemaining
        self.freeIllustratedStoryUsed = freeIllustratedStoryUsed
        self.lastFreeTextStoryAt = lastFreeTextStoryAt
        self.now = now
    }
}

// MARK: - Policy

/// Uygulamadaki **tek** yetki kararı.
///
/// Saf fonksiyon: girdi `EntitlementContext`, çıktı `EntitlementDecision`.
/// Ağ yok, disk yok, saat yok, singleton yok. Ödeme mantığı kritik olduğu için
/// burası testte %100 kapsanır ve kapsanabilir olması bu saflığa bağlıdır.
public enum EntitlementPolicy {

    // MARK: Sabitler

    /// Ücretsiz metin masalları arasındaki soğuma süresi (saat).
    /// Mevcut davranışla birebir: `SubscriptionManager.canCreateFreeTextStory`.
    public static let freeTextStoryCooldownHours: Double = 12

    /// Çevrimdışı tolerans penceresi.
    ///
    /// Doğrulanmış bir abonelik bu süre boyunca ağ olmadan da onurlandırılır.
    /// Süresiz olamaz: `UserDefaults`'taki plan yazısı süresiz güvenilseydi,
    /// tek bir anahtarı değiştirmek kalıcı premium demek olurdu. Yedi gün,
    /// uzun bir tatil ile "bu artık kanıt değil" arasındaki dürüst sınır.
    public static let offlineTrustWindow: TimeInterval = 7 * 24 * 60 * 60

    // MARK: Karar

    public static func decide(_ capability: Capability,
                              in context: EntitlementContext) -> EntitlementDecision {
        switch capability {
        case .illustratedStory:      return decideIllustratedStory(context)
        case .unlimitedTextStories:  return decideTextStory(context)
        case .unlimitedDailyStories: return decideDailyStory(context)
        case .premiumWorlds, .premiumThemes, .longStories:
            return decidePaidUnlock(capability, context)
        }
    }

    // MARK: Etkin plan

    /// Güven seviyesinden geçirilmiş plan.
    ///
    /// Kayıtlı kademe ile **uygulanan** kademe farklı şeylerdir; arayüzün
    /// göreceği tek şey bu fonksiyonun sonucudur.
    public static func effectivePlan(for context: EntitlementContext) -> EntitlementPlan {
        switch context.trust {
        case .verified:
            return context.plan
        case .cached(let age):
            return age <= offlineTrustWindow ? context.plan : .free
        case .unverified:
            return .free
        }
    }

    /// Kayıtlı plan ücretliyken doğrulama düştüyse `true`.
    ///
    /// Bu ayrım arayüz için önemli: "abone ol" demek yanlış olurdu, doğrusu
    /// "satın alımları geri yükle".
    private static func isDowngradedByTrust(_ context: EntitlementContext) -> Bool {
        context.plan.isPaid && !effectivePlan(for: context).isPaid
    }

    /// Ücretli yetenekler için ortak ret sebebi.
    private static func paidDenial(_ context: EntitlementContext) -> EntitlementDenial {
        isDowngradedByTrust(context) ? .unverifiedEntitlement : .requiresSubscription
    }

    // MARK: Yetenekler

    /// Saf kilit açma: dünyalar, temalar, uzun masal.
    /// Kota yok, tüketim yok — ücretli plan var mı, yok mu.
    private static func decidePaidUnlock(_ capability: Capability,
                                         _ context: EntitlementContext) -> EntitlementDecision {
        effectivePlan(for: context).isPaid ? .allowed : .denied(paidDenial(context))
    }

    /// Görselli masal.
    ///
    /// Tek maliyet taşıyan yetenek olduğu için kural burada daha sıkı:
    /// önbelleğe alınmış bir abonelik **yetmez**, taze doğrulama gerekir.
    /// Gerekçe: bu yetenek her kullanımda uzak görsel üretimi parası harcar;
    /// üretim zaten ağ ister, dolayısıyla ağ varken `CustomerInfo` tazelenebilir.
    /// Çevrimdışı toleransın masrafı olan tek yer burasıdır, o yüzden burada yok.
    private static func decideIllustratedStory(_ context: EntitlementContext) -> EntitlementDecision {
        let plan = effectivePlan(for: context)

        if plan.isPaid {
            guard context.trust == .verified else {
                return .denied(.unverifiedEntitlement)
            }
            guard context.illustratedQuotaRemaining > 0 else {
                return .denied(.quotaExhausted)
            }
            return .allowedUsingQuota(remaining: context.illustratedQuotaRemaining)
        }

        // Ücretsiz kullanıcı: deneme hakkı var VE tek seferlik görselli henüz harcanmadı.
        // `SubscriptionManager.canCreateStory(type: .image)` ile birebir aynı kural.
        guard context.trialStarsRemaining > 0, !context.freeIllustratedStoryUsed else {
            return .denied(paidDenial(context))
        }
        return .allowedUsingTrial(remaining: context.trialStarsRemaining)
    }

    /// Metin masalı.
    ///
    /// Ücretsiz kullanıcı için reddin sebebi paywall değil **bekleme**: ürün
    /// 12 saatte bir masalı zaten veriyor. Sakin UX ilkesi bu ayrımı gerektiriyor;
    /// her redde abonelik ekranı açmak bu ürünün sesi değil.
    private static func decideTextStory(_ context: EntitlementContext) -> EntitlementDecision {
        if effectivePlan(for: context).isPaid { return .allowed }

        if context.trialStarsRemaining > 0 {
            return .allowedUsingTrial(remaining: context.trialStarsRemaining)
        }

        guard let last = context.lastFreeTextStoryAt else {
            return .allowed  // hiç ücretsiz masal alınmamış
        }

        let elapsedHours = context.now.timeIntervalSince(last) / 3600
        if elapsedHours >= freeTextStoryCooldownHours { return .allowed }

        // Geriye giden saat (kullanıcı cihaz saatini ileri/geri aldı) negatif
        // kalan üretebilirdi; `max(0,)` bunu kesiyor, `ceil` de "0 saat kaldı
        // ama hâlâ hayır" çelişkisini engelliyor.
        let remaining = max(0, freeTextStoryCooldownHours - elapsedHours)
        return .denied(.waitingForFreeStory(hours: max(1, Int(ceil(remaining)))))
    }

    /// Günün masalı. Ücretsiz kullanıcıda soğuma yok, yalnızca deneme hakkı.
    private static func decideDailyStory(_ context: EntitlementContext) -> EntitlementDecision {
        if effectivePlan(for: context).isPaid { return .allowed }

        guard context.trialStarsRemaining > 0 else {
            return .denied(paidDenial(context))
        }
        return .allowedUsingTrial(remaining: context.trialStarsRemaining)
    }
}
