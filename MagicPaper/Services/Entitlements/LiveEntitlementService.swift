import Foundation
import Combine

/// Üretimdeki entitlement servisi.
///
///     Capability → LiveEntitlementService → SubscriptionManager → RevenueCat
///
/// Bu sınıf **karar vermez** — kararı `EntitlementPolicy` verir. Buradaki tek iş
/// kaynakları toplamak: kayıtlı kademe, o kademenin ne zaman doğrulandığı,
/// kalan kota ve deneme hakkı. Karar mantığı buraya sızarsa test edilemez hale
/// gelir, o yüzden sınır katı.
///
/// `SubscriptionManager` hâlâ durumun sahibi; bu tur onu yerinden etmiyor
/// (CLAUDE.md İlke 2 — çalışan sistem yeniden yazılmaz). Değişen şey, ekranların
/// artık ona doğrudan `isPremium` sormaması.
public final class LiveEntitlementService: ObservableObject, EntitlementService {

    public static let shared = LiveEntitlementService()

    private let subscriptions: SubscriptionManager
    private let clock: () -> Date
    private var cancellables = Set<AnyCancellable>()

    init(subscriptions: SubscriptionManager = .shared,
         clock: @escaping () -> Date = Date.init) {
        self.subscriptions = subscriptions
        self.clock = clock

        // Kademe veya kota değişince ekranlar yeniden çizilsin. Görünümler bu
        // servisi gözlemleyecek, `SubscriptionManager`'ı değil.
        subscriptions.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - Bağlam

    /// Politikanın göreceği anlık durum.
    ///
    /// `internal` — testler bağlamın doğru toplandığını doğrulayabilsin, ama
    /// arayüz bağlamı değil kararı görsün.
    var context: EntitlementContext {
        EntitlementContext(
            plan: EntitlementPlan(subscriptions.subscriptionTier),
            trust: trust,
            illustratedQuotaRemaining: subscriptions.remainingImageStories,
            trialStarsRemaining: subscriptions.freeTrialCount,
            freeIllustratedStoryUsed: subscriptions.freeImageStoryUsed,
            lastFreeTextStoryAt: subscriptions.lastFreeTextStoryDate,
            now: clock()
        )
    }

    /// Kayıtlı kademenin kaynağı.
    ///
    /// Yalnızca `RevenueCatManager`, `CustomerInfo` elde ettiğinde damga atar.
    /// Damga yoksa elimizdeki `UserDefaults` yazısıdır ve tek başına kanıt değildir.
    private var trust: EntitlementTrust {
        guard let verifiedAt = subscriptions.entitlementVerifiedAt else {
            return .unverified
        }
        if subscriptions.isEntitlementVerifiedInThisSession { return .verified }
        return .cached(age: max(0, clock().timeIntervalSince(verifiedAt)))
    }

    // MARK: - EntitlementService

    public func evaluate(_ capability: Capability) -> EntitlementDecision {
        EntitlementPolicy.decide(capability, in: context)
    }

    @discardableResult
    public func consume(_ capability: Capability) -> EntitlementDecision {
        let decision = evaluate(capability)
        guard decision.isAllowed, capability.isMetered else { return decision }

        // Sayaçların sahibi hâlâ `SubscriptionManager`. Reddedilen bir kapıda
        // buraya hiç gelinmez, dolayısıyla kota yanlışlıkla düşmez.
        switch capability {
        case .illustratedStory:
            guard subscriptions.useStory(type: .image) else {
                // Politika ile sayaç ayrıştıysa yetkiyi değil, reddi döndürürüz.
                return .denied(.quotaExhausted)
            }
        case .unlimitedTextStories, .unlimitedDailyStories,
             .premiumWorlds, .premiumThemes, .longStories:
            break
        }
        return decision
    }

    public var snapshot: EntitlementSnapshot {
        let current = context
        let plan = EntitlementPolicy.effectivePlan(for: current)
        return EntitlementSnapshot(
            plan: plan,
            trust: current.trust,
            storyCredits: plan.isPaid ? current.illustratedQuotaRemaining
                                      : current.trialStarsRemaining
        )
    }

    public func refresh() {
        RevenueCatManager.shared.refreshCustomerInfo()
    }
}
