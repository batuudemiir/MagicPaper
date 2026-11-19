import Foundation

/// Testler ve SwiftUI önizlemeleri için tamamen belirlenimci entitlement servisi.
///
/// Gerçek servisin aynı `EntitlementPolicy`'sini kullanır — davranışı taklit
/// etmez, **aynısını** çalıştırır. Taklit eden bir sahte, politika değişince
/// sessizce yalan söylemeye başlardı.
public final class StubEntitlementService: EntitlementService {

    /// Politikaya verilecek bağlam. Test doğrudan buna yazar.
    public var context: EntitlementContext

    /// `consume` çağrılarının kaydı — bir ekranın kotayı gerçekten düşürdüğünü
    /// (ya da reddedilmişken düşürmediğini) doğrulamak için.
    public private(set) var consumed: [Capability] = []

    /// `refresh` çağrı sayısı.
    public private(set) var refreshCount = 0

    public init(context: EntitlementContext) {
        self.context = context
    }

    /// Ücretsiz, hiç denemesi kalmamış kullanıcı.
    public static func free(now: Date = Date()) -> StubEntitlementService {
        StubEntitlementService(context: EntitlementContext(
            plan: .free,
            trust: .verified,
            illustratedQuotaRemaining: 0,
            trialStarsRemaining: 0,
            freeIllustratedStoryUsed: true,
            lastFreeTextStoryAt: now,
            now: now
        ))
    }

    /// Doğrulanmış abone.
    public static func subscriber(plan: EntitlementPlan = .premium,
                                  now: Date = Date()) -> StubEntitlementService {
        StubEntitlementService(context: EntitlementContext(
            plan: plan,
            trust: .verified,
            illustratedQuotaRemaining: plan.monthlyIllustratedQuota,
            trialStarsRemaining: 0,
            freeIllustratedStoryUsed: false,
            lastFreeTextStoryAt: nil,
            now: now
        ))
    }

    public func evaluate(_ capability: Capability) -> EntitlementDecision {
        EntitlementPolicy.decide(capability, in: context)
    }

    @discardableResult
    public func consume(_ capability: Capability) -> EntitlementDecision {
        let decision = evaluate(capability)
        guard decision.isAllowed, capability.isMetered else { return decision }

        consumed.append(capability)

        // Gerçek servisin `SubscriptionManager` üzerinde yaptığı sayaç düşümünün
        // bağlam üzerindeki karşılığı; kural `EntitlementPolicy.consumption`'da.
        switch EntitlementPolicy.consumption(of: capability, decision: decision, in: context) {
        case .nothing:
            break
        case .quota:
            context.illustratedQuotaRemaining -= 1
        case .trialStar:
            context.trialStarsRemaining -= 1
            if capability == .illustratedStory { context.freeIllustratedStoryUsed = true }
        case .freeTextStory(let at):
            context.lastFreeTextStoryAt = at
        }
        return decision
    }

    public var snapshot: EntitlementSnapshot {
        let plan = EntitlementPolicy.effectivePlan(for: context)
        return EntitlementSnapshot(
            plan: plan,
            trust: context.trust,
            storyCredits: plan.isPaid ? context.illustratedQuotaRemaining
                                      : context.trialStarsRemaining
        )
    }

    public func refresh() { refreshCount += 1 }
}
