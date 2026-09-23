import XCTest
@testable import MagicPaper

/// Yetki kararının testi.
///
/// Buradaki iddia şu: ödeme mantığı, kırıldığında sessiz kalan tek mantıktır.
/// Yanlış açılan bir kapı kimseye hata göstermez — yalnızca parayı kaybeder ya
/// da parasını ödemiş bir aileyi kilitler. O yüzden `EntitlementPolicy`'nin her
/// dalı burada ayrı ayrı yürütülüyor.
final class EntitlementPolicyTests: XCTestCase {

    // Sabit bir "şimdi" — soğuma testleri gerçek saati beklemez.
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func context(plan: EntitlementPlan = .free,
                         trust: EntitlementTrust = .verified,
                         quota: Int = 0,
                         trial: Int = 0,
                         freeImageUsed: Bool = false,
                         lastFreeText: Date? = nil) -> EntitlementContext {
        EntitlementContext(plan: plan,
                           trust: trust,
                           illustratedQuotaRemaining: quota,
                           trialStarsRemaining: trial,
                           freeIllustratedStoryUsed: freeImageUsed,
                           lastFreeTextStoryAt: lastFreeText,
                           now: now)
    }

    private func decide(_ capability: Capability,
                        _ ctx: EntitlementContext) -> EntitlementDecision {
        EntitlementPolicy.decide(capability, in: ctx)
    }

    // MARK: - Etkin plan: güven seviyesi planı yenebilir

    func testAVerifiedPlanIsHonoredAsWritten() {
        for plan in EntitlementPlan.allCases {
            let effective = EntitlementPolicy.effectivePlan(
                for: context(plan: plan, trust: .verified))
            XCTAssertEqual(effective, plan)
        }
    }

    func testACachedPlanSurvivesInsideTheOfflineWindow() {
        let justInside = EntitlementPolicy.offlineTrustWindow - 1
        let effective = EntitlementPolicy.effectivePlan(
            for: context(plan: .ultimate, trust: .cached(age: justInside)))
        XCTAssertEqual(effective, .ultimate)
    }

    func testACachedPlanIsHonoredExactlyAtTheWindowBoundary() {
        let effective = EntitlementPolicy.effectivePlan(
            for: context(plan: .premium,
                         trust: .cached(age: EntitlementPolicy.offlineTrustWindow)))
        XCTAssertEqual(effective, .premium, "Sınır dahil olmalı; kapsam dışı kalırsa pencere sessizce kısalır.")
    }

    func testACachedPlanExpiresOnceTheWindowHasPassed() {
        let stale = EntitlementPolicy.offlineTrustWindow + 1
        let effective = EntitlementPolicy.effectivePlan(
            for: context(plan: .ultimate, trust: .cached(age: stale)))
        XCTAssertEqual(effective, .free, "Süresiz güvenilen bir yerel yazı, kalıcı bedava premium demekti.")
    }

    func testAnUnverifiedPlanNeverGrantsAnything() {
        let effective = EntitlementPolicy.effectivePlan(
            for: context(plan: .ultimate, trust: .unverified))
        XCTAssertEqual(effective, .free)
    }

    // MARK: - Saf kilit açma: dünyalar, temalar, uzun masal

    func testPaidUnlocksAreClosedOnTheFreePlan() {
        for capability in [Capability.premiumWorlds, .premiumThemes, .longStories] {
            XCTAssertEqual(decide(capability, context(plan: .free)),
                           .denied(.requiresSubscription),
                           "\(capability.rawValue) ücretsiz planda açık kalmamalı.")
        }
    }

    func testPaidUnlocksOpenOnEveryPaidPlan() {
        for plan in EntitlementPlan.allCases where plan.isPaid {
            for capability in [Capability.premiumWorlds, .premiumThemes, .longStories] {
                XCTAssertEqual(decide(capability, context(plan: plan)), .allowed,
                               "\(capability.rawValue) \(plan.rawValue) planında açık olmalı.")
            }
        }
    }

    func testPaidUnlocksStayOpenOfflineInsideTheWindow() {
        let ctx = context(plan: .basic, trust: .cached(age: 3 * 24 * 60 * 60))
        XCTAssertEqual(decide(.premiumWorlds, ctx), .allowed,
                       "Ağ yokken ödemiş aileyi kilitlemek yanlış olurdu.")
    }

    // MARK: - Ret sebebi: "abone ol" ile "geri yükle" aynı şey değil

    func testALapsedSubscriberIsAskedToRestoreRatherThanToSubscribe() {
        let stale = EntitlementPolicy.offlineTrustWindow + 60
        XCTAssertEqual(decide(.premiumWorlds, context(plan: .premium, trust: .cached(age: stale))),
                       .denied(.unverifiedEntitlement))
        XCTAssertEqual(decide(.premiumThemes, context(plan: .premium, trust: .unverified)),
                       .denied(.unverifiedEntitlement))
    }

    func testAGenuinelyFreeUserIsAskedToSubscribe() {
        XCTAssertEqual(decide(.premiumWorlds, context(plan: .free, trust: .unverified)),
                       .denied(.requiresSubscription),
                       "Hiç abone olmamış kullanıcıya 'geri yükle' demek anlamsız olurdu.")
    }

    // MARK: - Görselli masal: kotalı ve taze doğrulama isteyen tek yetenek

    func testASubscriberSpendsFromTheMonthlyQuota() {
        XCTAssertEqual(decide(.illustratedStory, context(plan: .premium, quota: 5)),
                       .allowedUsingQuota(remaining: 5))
    }

    func testASubscriberWithAnEmptyQuotaIsToldTheQuotaIsEmpty() {
        XCTAssertEqual(decide(.illustratedStory, context(plan: .ultimate, quota: 0)),
                       .denied(.quotaExhausted),
                       "Kota bitmesi ile abonelik olmaması farklı metinler gerektirir.")
    }

    func testTheIllustratedStoryRefusesACachedSubscriptionEvenInsideTheWindow() {
        let ctx = context(plan: .ultimate, trust: .cached(age: 60), quota: 10)
        XCTAssertEqual(decide(.illustratedStory, ctx), .denied(.unverifiedEntitlement),
                       "Para harcayan tek yetenek, önbellekten açılmamalı.")
    }

    func testAFreeUserGetsOneIllustratedStoryFromTheTrial() {
        XCTAssertEqual(decide(.illustratedStory, context(trial: 3, freeImageUsed: false)),
                       .allowedUsingTrial(remaining: 3))
    }

    func testTheFreeIllustratedStoryIsOnlyOfferedOnce() {
        XCTAssertEqual(decide(.illustratedStory, context(trial: 3, freeImageUsed: true)),
                       .denied(.requiresSubscription))
    }

    func testAFreeUserWithNoTrialLeftCannotIllustrate() {
        XCTAssertEqual(decide(.illustratedStory, context(trial: 0, freeImageUsed: false)),
                       .denied(.requiresSubscription))
    }

    // MARK: - Metin masalı: redde paywall değil, bekleme

    func testASubscriberWritesTextStoriesWithoutLimit() {
        for plan in EntitlementPlan.allCases where plan.isPaid {
            XCTAssertEqual(decide(.unlimitedTextStories, context(plan: plan, lastFreeText: now)),
                           .allowed)
        }
    }

    func testAFreeUserWithTrialStarsSpendsAStar() {
        XCTAssertEqual(decide(.unlimitedTextStories, context(trial: 2)),
                       .allowedUsingTrial(remaining: 2))
    }

    func testTheFirstFreeTextStoryIsAlwaysAllowed() {
        XCTAssertEqual(decide(.unlimitedTextStories, context(trial: 0, lastFreeText: nil)),
                       .allowed)
    }

    func testTheFreeTextStoryReopensAfterTheCooldown() {
        let twelveHoursAgo = now.addingTimeInterval(-12 * 3600)
        XCTAssertEqual(decide(.unlimitedTextStories, context(trial: 0, lastFreeText: twelveHoursAgo)),
                       .allowed)
    }

    func testAWaitingFreeUserIsToldHowLongRatherThanShownAPaywall() {
        let fourHoursAgo = now.addingTimeInterval(-4 * 3600)
        XCTAssertEqual(decide(.unlimitedTextStories, context(trial: 0, lastFreeText: fourHoursAgo)),
                       .denied(.waitingForFreeStory(hours: 8)))
    }

    func testAPartialHourRoundsUpSoTheCopyNeverPromisesZeroHours() {
        let elevenAndAHalf = now.addingTimeInterval(-11.5 * 3600)
        XCTAssertEqual(decide(.unlimitedTextStories, context(trial: 0, lastFreeText: elevenAndAHalf)),
                       .denied(.waitingForFreeStory(hours: 1)),
                       "'0 saat kaldı ama hâlâ hayır' çelişkisi ekrana çıkmamalı.")
    }

    func testAClockMovedForwardCannotProduceANegativeWait() {
        let future = now.addingTimeInterval(3600)   // kullanıcı saati geri aldı
        let decision = decide(.unlimitedTextStories, context(trial: 0, lastFreeText: future))
        guard case .denied(.waitingForFreeStory(let hours)) = decision else {
            return XCTFail("Beklenen bekleme reddi, alınan: \(decision)")
        }
        XCTAssertGreaterThan(hours, 0)
        XCTAssertLessThanOrEqual(hours, 13)
    }

    // MARK: - Günün masalı

    func testTheDailyStoryIsOpenForSubscribers() {
        XCTAssertEqual(decide(.unlimitedDailyStories, context(plan: .basic)), .allowed)
    }

    func testTheDailyStoryUsesTrialStarsForFreeUsers() {
        XCTAssertEqual(decide(.unlimitedDailyStories, context(trial: 1)),
                       .allowedUsingTrial(remaining: 1))
        XCTAssertEqual(decide(.unlimitedDailyStories, context(trial: 0)),
                       .denied(.requiresSubscription))
    }

    func testTheDailyStoryHasNoCooldown() {
        // Metin masalının aksine: deneme hakkı bittiyse beklemek açmaz.
        let ctx = context(trial: 0, lastFreeText: now.addingTimeInterval(-48 * 3600))
        XCTAssertEqual(decide(.unlimitedDailyStories, ctx), .denied(.requiresSubscription))
    }

    // MARK: - Mevcut davranışla eşleşme (regresyon kapısı)

    /// Bu tur davranışı değiştirmiyor, yerini değiştiriyor. Politika
    /// `SubscriptionManager.canCreateStory` ile aynı cevabı vermeli — aksi
    /// halde taşıma sessiz bir ürün değişikliği olurdu.
    func testThePolicyAgreesWithTheManagerItReplaces() {
        let cases: [(EntitlementPlan, Int, Int, Bool, StoryType, Bool)] = [
            // plan, kota, deneme, görselliKullanıldı, tür, beklenen
            (.free,    0, 3, false, .image, true),
            (.free,    0, 3, true,  .image, false),
            (.free,    0, 0, false, .image, false),
            (.premium, 5, 0, false, .image, true),
            (.premium, 0, 0, false, .image, false),
            (.free,    0, 1, false, .daily, true),
            (.free,    0, 0, false, .daily, false),
            (.basic,   1, 0, false, .daily, true),
            (.free,    0, 1, false, .text,  true),
            (.ultimate, 10, 0, false, .text, true)
        ]

        for (plan, quota, trial, imageUsed, type, expected) in cases {
            let capability: Capability = {
                switch type {
                case .image: return .illustratedStory
                case .text:  return .unlimitedTextStories
                case .daily: return .unlimitedDailyStories
                }
            }()
            let ctx = context(plan: plan, quota: quota, trial: trial,
                              freeImageUsed: imageUsed, lastFreeText: now)
            XCTAssertEqual(decide(capability, ctx).isAllowed, expected,
                           "\(plan.rawValue)/\(type) için politika ile eski kural ayrıştı.")
        }
    }
}
