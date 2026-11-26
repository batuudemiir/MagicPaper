import XCTest
import CryptoKit
import StoryEngine
@testable import MagicPaper

/// B3 (beş arkadaş B hattı): eski motor mu P56 mı, ve neden.
final class StoryRuntimeRouterTests: XCTestCase {
    private static let fixture: Result<(P56SourceReference, P56Package), Error> = Result {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/\(P56PinnedSource.packageVersion)/payload.json"))
        let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        let package = try P56PackageLoader.load(payload: bytes, expectedSHA256: digest)
        return (package.sourceReference, package)
    }

    private func router(enabled: Bool = true,
                        load: @escaping () throws -> (P56SourceReference, P56Package) = { try fixture.get() }) -> StoryRuntimeRouter {
        StoryRuntimeRouter(isEnabled: enabled, loadSource: { P56VerifiedSource(try load()) }, archive: nil)
    }

    private func request(age: Int = 5, mode: StoryMode = .learning,
                         companionID: String? = "companion_fox_pilot_001",
                         family: FamilyCharacter? = nil, topicID: String? = nil,
                         occasion: String? = nil, safety: ContentSafety? = nil) -> StoryRuntimeRequest {
        StoryRuntimeRequest(age: age, mode: mode, companionID: companionID, family: family,
                            topicID: topicID, occasion: occasion, safety: safety)
    }

    func testFlagOffAlwaysLegacyWithoutLoading() async {
        var loaded = false
        let decision = await router(enabled: false, load: { loaded = true; return try Self.fixture.get() }).decide(request())
        XCTAssertEqual(decision, StoryRuntimeDecision(route: .legacy, reason: .flagOff))
        XCTAssertFalse(loaded, "bayrak kapalıyken payload okunmaz")
    }

    func testSupportedRequestRoutesToP56() async throws {
        let (reference, _) = try Self.fixture.get()
        let awaited1 = await router().decide(request())
        XCTAssertEqual(awaited1, StoryRuntimeDecision(route: .p56(reference), reason: nil))
    }

    func testEveryModeAndFriendIsSupportedAtFiveAndSix() async throws {
        let (reference, package) = try Self.fixture.get()
        for age in [5, 6] {
            for mode in StoryMode.allCases {
                let p56Mode = try XCTUnwrap(P56Mode(rawValue: mode.rawValue))
                for id in P56Support.companionIDs(age: age, mode: p56Mode, package: package) {
                    let awaited2 = await router().decide(request(age: age, mode: mode, companionID: id)).route
                    XCTAssertEqual(awaited2,
                                   .p56(reference), "\(age) \(mode) \(id)")
                }
            }
        }
    }

    func testFamilyGoesLegacy() async {
        let family = FamilyCharacter(childID: UUID(), name: "Ela", relation: .sibling)
        let awaited3 = await router().decide(request(family: family))
        XCTAssertEqual(awaited3,
                       StoryRuntimeDecision(route: .legacy, reason: .unsupportedRequest))
    }

    func testTopicAndOccasionGoLegacy() async {
        let awaited4 = await router().decide(request(topicID: "topic_jobs")).reason
        XCTAssertEqual(awaited4, .unsupportedRequest)
        let awaited5 = await router().decide(request(occasion: "birthday")).reason
        XCTAssertEqual(awaited5, .unsupportedRequest)
    }

    /// Profillerin varsayılanı `.mostProtective` (`UserProfile.effectiveSafety`). v2 (C3) bunu
    /// inceler: kitap kalan arkadaş × mod P56'ya, hiç kitap kalmayan eski motora gider.
    func testDefaultProfileSafetyRoutesByAdmissibleBooks() async throws {
        let (reference, package) = try Self.fixture.get()
        var admitted = 0
        for mode in StoryMode.allCases {
            let p56Mode = try XCTUnwrap(P56Mode(rawValue: mode.rawValue))
            for id in P56Support.companionIDs(age: 5, mode: p56Mode, package: package) {
                let decision = await router().decide(request(mode: mode, companionID: id, safety: .mostProtective))
                let reasons = P56Support.unsupportedReasons(for: StoryRuntimeRouter.p56Request(
                    for: request(mode: mode, companionID: id, safety: .mostProtective)), package: package)
                if reasons.isEmpty {
                    admitted += 1
                    XCTAssertEqual(decision, StoryRuntimeDecision(route: .p56(reference), reason: nil))
                } else {
                    XCTAssertEqual(decision, StoryRuntimeDecision(route: .legacy, reason: .unsupportedRequest))
                }
            }
        }
        XCTAssertGreaterThan(admitted, 0, "en korumalı politikada P56 en az bir arkadaşla yazar")
        let awaited6 = await router().decide(request(companionID: nil, safety: .mostProtective)).route
        XCTAssertEqual(awaited6, .p56(reference))
    }

    func testAgeAloneIsUnsupportedAge() async {
        let awaited7 = await router().decide(request(age: 3))
        XCTAssertEqual(awaited7, StoryRuntimeDecision(route: .legacy, reason: .unsupportedAge))
        let awaited8 = await router().decide(request(age: 7)).reason
        XCTAssertEqual(awaited8, .unsupportedAge)
    }

    func testAgeWithOtherReasonsIsUnsupportedRequest() async {
        let family = FamilyCharacter(childID: UUID(), name: "Ela", relation: .sibling)
        let awaited9 = await router().decide(request(age: 3, family: family)).reason
        XCTAssertEqual(awaited9, .unsupportedRequest)
    }

    func testArchiveOutcomeIsKeptApartFromTheDecision() async throws {
        let (reference, _) = try Self.fixture.get()
        struct Full: Error {}
        let failing = StoryRuntimeRouter(isEnabled: true, loadSource: { P56VerifiedSource(try Self.fixture.get()) },
                                         archive: { _ in throw Full() })
        let awaited10 = await failing.decide(request()).route
        XCTAssertEqual(awaited10, .p56(reference), "arşiv hatası kararı değiştirmez")
        let done = expectation(description: "arşiv sonucu")
        DispatchQueue.global().async {
            while failing.archiveOutcome == nil { usleep(10_000) }
            done.fulfill()
        }
        await fulfillment(of: [done], timeout: 10)
        XCTAssertEqual(failing.archiveOutcome, .failed)

        let ok = StoryRuntimeRouter(isEnabled: true, loadSource: { P56VerifiedSource(try Self.fixture.get()) }, archive: { _ in })
        _ = await ok.decide(request())
        let okDone = expectation(description: "arşiv tamam")
        DispatchQueue.global().async {
            while ok.archiveOutcome == nil { usleep(10_000) }
            okDone.fulfill()
        }
        await fulfillment(of: [okDone], timeout: 10)
        XCTAssertEqual(ok.archiveOutcome, .archived)
    }

    func testUnknownCompanionGoesLegacy() async {
        let awaited11 = await router().decide(request(companionID: "companion_dolphin_pilot_001")).reason
        XCTAssertEqual(awaited11, .unsupportedRequest)
    }

    func testBrokenPayloadGoesLegacy() async {
        struct Broken: Error {}
        let awaited12 = await router(load: { throw Broken() }).decide(request())
        XCTAssertEqual(awaited12,
                       StoryRuntimeDecision(route: .legacy, reason: .payloadUnavailable))
    }

    func testSourceLoadsOnceAndDecisionIsDeterministic() async {
        var loads = 0
        let router = router(load: { loads += 1; return try Self.fixture.get() })
        let awaited13 = await router.decide(request())
        let awaited13b = await router.decide(request())
        XCTAssertEqual(awaited13, awaited13b)
        XCTAssertEqual(loads, 1)
    }

    func testPrewarmLoadsOffTheMainThreadOnce() async throws {
        let loaded = expectation(description: "kaynak arka planda yüklendi")
        let lock = NSLock()
        var loads = 0
        var onMain = true
        let router = router(load: {
            lock.lock(); loads += 1; onMain = Thread.isMainThread; lock.unlock()
            loaded.fulfill()
            return try Self.fixture.get()
        })
        router.prewarm()
        await fulfillment(of: [loaded], timeout: 10)
        let (reference, _) = try Self.fixture.get()
        let awaited14 = await router.decide(request()).route
        XCTAssertEqual(awaited14, .p56(reference))
        lock.lock(); defer { lock.unlock() }
        XCTAssertFalse(onMain, "ön yükleme ana iş parçacığını tutmaz")
        XCTAssertEqual(loads, 1, "karar ön yüklenen kaynağı kullanır")
    }

    func testPrewarmDoesNothingWhenFlagIsOff() async {
        let notLoaded = expectation(description: "bayrak kapalıyken yüklenmez")
        notLoaded.isInverted = true
        router(enabled: false, load: { notLoaded.fulfill(); return try Self.fixture.get() }).prewarm()
        await fulfillment(of: [notLoaded], timeout: 1)
    }

    func testPackageIsHandedOnlyForTheDecidedSource() async throws {
        let (reference, _) = try Self.fixture.get()
        let router = router()
        XCTAssertNil(router.package(for: reference), "okunmadan paket verilmez, beklenmez de")
        await router.waitUntilReady()
        XCTAssertNotNil(router.package(for: reference))
        XCTAssertNil(router.package(for: P56SourceReference(payloadSHA256: String(repeating: "0", count: 64))))
    }

    func testSupportRequestCarriesNoChildData() async {
        let p56 = StoryRuntimeRouter.p56Request(for: request(family: FamilyCharacter(childID: UUID(), name: "Gizli", relation: .sibling),
                                                            topicID: "t", occasion: "o", safety: .mostProtective))
        XCTAssertEqual(p56.childID, "support-check")
        XCTAssertEqual(p56.name, "Deniz")
        XCTAssertEqual(p56.seed, 0)
        XCTAssertEqual(Set(p56.contexts), ["family", "topic", "occasion"])
        XCTAssertEqual(p56.contentSafety, .mostProtective, "güvenlik politikası olduğu gibi taşınır")
        XCTAssertFalse(p56.contexts.contains("Gizli"))
    }

    /// Kod düzeltmeleri (26 Kasım): yükleme sürerken kilit tutulmaz. Ana iş
    /// parçacığı durumu sorabilir, karar beklemez; okuma bitince karar gelir.
    func testLoadingNeverHoldsTheLock() async throws {
        let (reference, _) = try Self.fixture.get()
        let gate = DispatchSemaphore(value: 0)
        let started = expectation(description: "okuma başladı")
        let router = router(load: {
            started.fulfill()
            gate.wait()
            return try Self.fixture.get()
        })
        router.prewarm()
        await fulfillment(of: [started], timeout: 10)
        XCTAssertFalse(router.isReady)
        XCTAssertNil(router.decideIfReady(request()), "okunurken karar beklemez, nil döner")
        XCTAssertNil(router.archiveOutcome)
        gate.signal()
        let decision = await router.decide(request())
        XCTAssertEqual(decision.route, .p56(reference))
        XCTAssertTrue(router.isReady)
        XCTAssertEqual(router.decideIfReady(request())?.route, .p56(reference))
    }

    func testManyWaitersAreAllResumedByOneRead() async throws {
        let (reference, _) = try Self.fixture.get()
        let lock = NSLock()
        var loads = 0
        let router = router(load: { lock.lock(); loads += 1; lock.unlock(); return try Self.fixture.get() })
        let routes = await withTaskGroup(of: StoryRuntimeRoute.self) { group in
            for _ in 0..<8 { group.addTask { await router.decide(self.request()).route } }
            return await group.reduce(into: []) { $0.append($1) }
        }
        XCTAssertEqual(routes, Array(repeating: .p56(reference), count: 8))
        lock.lock(); defer { lock.unlock() }
        XCTAssertEqual(loads, 1)
    }

    func testFlagOffIsReadyAtOnce() {
        let router = router(enabled: false)
        XCTAssertTrue(router.isReady)
        XCTAssertEqual(router.decideIfReady(request()), StoryRuntimeDecision(route: .legacy, reason: .flagOff))
    }

    /// Arşiv, yükleyicinin doğruladığı baytları alır; yeniden okumaz.
    func testArchiveReceivesTheLoadersVerifiedBytes() async throws {
        let bytes = Data("dogrulanmis".utf8)
        let received = expectation(description: "arşiv baytları aldı")
        let router = StoryRuntimeRouter(isEnabled: true,
                                        loadSource: { P56VerifiedSource(try Self.fixture.get(), payload: bytes) },
                                        archive: { source in
                                            XCTAssertEqual(source.payload, bytes)
                                            received.fulfill()
                                        })
        _ = await router.decide(request())
        await fulfillment(of: [received], timeout: 10)
    }

    func testReleaseFlagIsOff() async {
        #if !DEBUG
        XCTAssertFalse(StoryRuntimeFlags.fiveFriendsPilot)
        #endif
    }

    func testDebugPilotIsOnByDefaultAndLaunchArgumentWins() {
        XCTAssertTrue(StoryRuntimeFlags.resolve(debug: true, launchValue: nil, underTests: false),
                      "Debug'da ana ekrandan açılış beşliyi gösterir")
        XCTAssertFalse(StoryRuntimeFlags.resolve(debug: true, launchValue: false, underTests: false),
                       "-mpFiveFriendsPilot NO kapatır")
        XCTAssertTrue(StoryRuntimeFlags.resolve(debug: true, launchValue: true, underTests: true))
        XCTAssertFalse(StoryRuntimeFlags.resolve(debug: true, launchValue: nil, underTests: true),
                       "testlerde varsayılan bugünkü akış")
        XCTAssertFalse(StoryRuntimeFlags.resolve(debug: false, launchValue: true, underTests: false),
                       "Release her zaman kapalı")
    }
}
