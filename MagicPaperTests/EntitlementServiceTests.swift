import XCTest
@testable import MagicPaper

/// Servis katmanı: kapının kararı ile **tüketimin** aynı şey olmadığı yer.
///
/// Reddedilmiş bir kapıda sayaç düşerse kullanıcı ödediği hakkı kaybeder;
/// kabul edilmiş bir kapıda düşmezse ürün bedavaya çalışır. İkisi de sessiz
/// hatalardır, ikisi de burada assert ediliyor.
final class EntitlementServiceTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: - Tüketim

    func testAnAllowedIllustratedStorySpendsExactlyOneQuotaUnit() {
        let service = StubEntitlementService.subscriber(plan: .premium, now: now)
        XCTAssertEqual(service.snapshot.storyCredits, 5)

        let decision = service.consume(.illustratedStory)

        XCTAssertEqual(decision, .allowedUsingQuota(remaining: 5),
                       "Karar tüketimden ÖNCEKİ bakiyeyi taşımalı.")
        XCTAssertEqual(service.snapshot.storyCredits, 4)
        XCTAssertEqual(service.consumed, [.illustratedStory])
    }

    func testADeniedCapabilityNeverSpendsAnything() {
        let service = StubEntitlementService.subscriber(plan: .premium, now: now)
        service.context.illustratedQuotaRemaining = 0

        let decision = service.consume(.illustratedStory)

        XCTAssertEqual(decision, .denied(.quotaExhausted))
        XCTAssertEqual(service.snapshot.storyCredits, 0, "Kapalı kapıda sayaç eksiye düşmemeli.")
        XCTAssertTrue(service.consumed.isEmpty)
    }

    func testAFreeUsersIllustratedStoryBurnsTheOneTimeUnlockAndAStar() {
        let service = StubEntitlementService(context: EntitlementContext(
            plan: .free, trust: .verified,
            illustratedQuotaRemaining: 0, trialStarsRemaining: 3,
            freeIllustratedStoryUsed: false, lastFreeTextStoryAt: nil, now: now))

        XCTAssertEqual(service.consume(.illustratedStory), .allowedUsingTrial(remaining: 3))
        XCTAssertEqual(service.snapshot.storyCredits, 2)
        XCTAssertTrue(service.context.freeIllustratedStoryUsed)

        // İkincisi artık açılmamalı: tek seferlik kilit harcandı.
        XCTAssertEqual(service.consume(.illustratedStory), .denied(.requiresSubscription))
        XCTAssertEqual(service.snapshot.storyCredits, 2)
    }

    func testUnmeteredCapabilitiesAreEvaluatedButNeverConsumed() {
        let service = StubEntitlementService.subscriber(plan: .ultimate, now: now)
        let before = service.snapshot.storyCredits

        for capability in Capability.allCases where !capability.isMetered {
            XCTAssertTrue(service.consume(capability).isAllowed)
        }

        XCTAssertEqual(service.snapshot.storyCredits, before)
        XCTAssertTrue(service.consumed.isEmpty, "Kilit açmak bir kontör harcaması değil.")
    }

    func testRefreshIsForwardedRatherThanFaked() {
        let service = StubEntitlementService.free(now: now)
        service.refresh()
        service.refresh()
        XCTAssertEqual(service.refreshCount, 2)
    }

    // MARK: - Kısa okuma

    func testTheBooleanShorthandMatchesTheFullDecision() {
        let service = StubEntitlementService.free(now: now)
        for capability in Capability.allCases {
            XCTAssertEqual(service.can(capability), service.evaluate(capability).isAllowed)
        }
    }

    // MARK: - Snapshot: ekrandaki "yıldız" tek bir yerde hesaplanır

    func testTheStarCountIsTheQuotaForSubscribersAndTheTrialForEveryoneElse() {
        let subscriber = StubEntitlementService.subscriber(plan: .basic, now: now)
        XCTAssertEqual(subscriber.snapshot.storyCredits, 1)
        XCTAssertEqual(subscriber.snapshot.planDisplayName, "Yıldız Kaşifi")

        let free = StubEntitlementService.free(now: now)
        free.context.trialStarsRemaining = 7
        XCTAssertEqual(free.snapshot.storyCredits, 7)
        XCTAssertEqual(free.snapshot.planDisplayName, "Ücretsiz plan")
    }

    func testADowngradedSnapshotShowsTheFreePlanAndAsksForARestore() {
        let stale = EntitlementPolicy.offlineTrustWindow + 1
        let service = StubEntitlementService(context: EntitlementContext(
            plan: .ultimate, trust: .cached(age: stale),
            illustratedQuotaRemaining: 10, trialStarsRemaining: 0,
            freeIllustratedStoryUsed: false, lastFreeTextStoryAt: nil, now: now))

        XCTAssertEqual(service.snapshot.plan, .free,
                       "Ekran kayıtlı planı değil, uygulanan planı göstermeli.")
        XCTAssertTrue(service.snapshot.needsRestore)
    }

    func testAVerifiedSubscriberIsNeverAskedToRestore() {
        XCTAssertFalse(StubEntitlementService.subscriber(now: now).snapshot.needsRestore)
    }

    func testAFreshOfflineSubscriberIsNotAskedToRestore() {
        let snapshot = EntitlementSnapshot(plan: .premium,
                                           trust: .cached(age: 60),
                                           storyCredits: 5)
        XCTAssertFalse(snapshot.needsRestore)
    }

    func testTheFreeSnapshotFactoryDefaultsToAnUnverifiedEmptyPlan() {
        let snapshot = EntitlementSnapshot.free()
        XCTAssertEqual(snapshot.plan, .free)
        XCTAssertEqual(snapshot.storyCredits, 0)
        XCTAssertTrue(snapshot.needsRestore)
    }

    // MARK: - Karar tipinin kendisi

    func testDecisionAccessorsReportTheRightShape() {
        XCTAssertNil(EntitlementDecision.allowed.remainingBeforeUse)
        XCTAssertNil(EntitlementDecision.allowed.denial)
        XCTAssertEqual(EntitlementDecision.allowedUsingTrial(remaining: 2).remainingBeforeUse, 2)
        XCTAssertEqual(EntitlementDecision.allowedUsingQuota(remaining: 9).remainingBeforeUse, 9)

        let denied = EntitlementDecision.denied(.quotaExhausted)
        XCTAssertFalse(denied.isAllowed)
        XCTAssertNil(denied.remainingBeforeUse)
        XCTAssertEqual(denied.denial, .quotaExhausted)
    }

    // MARK: - Yetenek meta verisi

    func testOnlyTheIllustratedStoryIsMeteredAndCostsMoney() {
        XCTAssertEqual(Capability.allCases.filter(\.isMetered), [.illustratedStory])
        XCTAssertEqual(Capability.allCases.filter(\.incursRemoteCost), [.illustratedStory])
    }

    func testEveryPlanDeclaresItsQuotaAndPaidStatus() {
        XCTAssertFalse(EntitlementPlan.free.isPaid)
        XCTAssertEqual(EntitlementPlan.free.monthlyIllustratedQuota, 0)
        XCTAssertEqual(EntitlementPlan.basic.monthlyIllustratedQuota, 1)
        XCTAssertEqual(EntitlementPlan.premium.monthlyIllustratedQuota, 5)
        XCTAssertEqual(EntitlementPlan.ultimate.monthlyIllustratedQuota, 10)

        for plan in EntitlementPlan.allCases where plan != .free {
            XCTAssertTrue(plan.isPaid)
            XCTAssertFalse(plan.displayName.isEmpty)
        }
    }

    /// Kademe eşlemesi iki yönlü kayıpsız olmalı: kayıpsız olmasaydı
    /// `SubscriptionManager` ile entitlement katmanı zamanla ayrışırdı.
    func testThePlanAndTierMappingIsLossless() {
        for plan in EntitlementPlan.allCases {
            XCTAssertEqual(EntitlementPlan(plan.tier), plan)
        }
        for tier in [SubscriptionManager.SubscriptionTier.none, .basic, .premium, .ultimate] {
            XCTAssertEqual(EntitlementPlan(tier).tier, tier)
        }
    }

    /// Kotalar iki yerde yazılı (`SubscriptionTier` ve `EntitlementPlan`).
    /// Bu test onların ayrışmasını yakalar.
    func testTheQuotaTableMatchesTheSubscriptionManagersTable() {
        for plan in EntitlementPlan.allCases {
            XCTAssertEqual(plan.monthlyIllustratedQuota,
                           plan.tier.monthlyImageStories,
                           "\(plan.rawValue) kotası iki tabloda ayrıştı.")
        }
    }
}
