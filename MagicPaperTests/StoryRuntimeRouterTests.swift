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
        StoryRuntimeRouter(isEnabled: enabled, loadSource: load, archive: nil)
    }

    private func request(age: Int = 5, mode: StoryMode = .learning,
                         companionID: String? = "companion_fox_pilot_001",
                         family: FamilyCharacter? = nil, topicID: String? = nil,
                         occasion: String? = nil, safety: ContentSafety? = nil) -> StoryRuntimeRequest {
        StoryRuntimeRequest(age: age, mode: mode, companionID: companionID, family: family,
                            topicID: topicID, occasion: occasion, safety: safety)
    }

    func testFlagOffAlwaysLegacyWithoutLoading() {
        var loaded = false
        let decision = router(enabled: false, load: { loaded = true; return try Self.fixture.get() }).decide(request())
        XCTAssertEqual(decision, StoryRuntimeDecision(route: .legacy, reason: .flagOff))
        XCTAssertFalse(loaded, "bayrak kapalıyken payload okunmaz")
    }

    func testSupportedRequestRoutesToP56() throws {
        let (reference, _) = try Self.fixture.get()
        XCTAssertEqual(router().decide(request()), StoryRuntimeDecision(route: .p56(reference), reason: nil))
    }

    func testEveryModeAndFriendIsSupportedAtFiveAndSix() throws {
        let (reference, package) = try Self.fixture.get()
        for age in [5, 6] {
            for mode in StoryMode.allCases {
                let p56Mode = try XCTUnwrap(P56Mode(rawValue: mode.rawValue))
                for id in P56Support.companionIDs(age: age, mode: p56Mode, package: package) {
                    XCTAssertEqual(router().decide(request(age: age, mode: mode, companionID: id)).route,
                                   .p56(reference), "\(age) \(mode) \(id)")
                }
            }
        }
    }

    func testFamilyGoesLegacy() {
        let family = FamilyCharacter(childID: UUID(), name: "Ela", relation: .sibling)
        XCTAssertEqual(router().decide(request(family: family)),
                       StoryRuntimeDecision(route: .legacy, reason: .unsupportedRequest))
    }

    func testTopicAndOccasionGoLegacy() {
        XCTAssertEqual(router().decide(request(topicID: "topic_jobs")).reason, .unsupportedRequest)
        XCTAssertEqual(router().decide(request(occasion: "birthday")).reason, .unsupportedRequest)
    }

    /// Profillerin varsayılanı `.mostProtective` (`UserProfile.effectiveSafety`). v2 (C3) bunu
    /// inceler: kitap kalan arkadaş × mod P56'ya, hiç kitap kalmayan eski motora gider.
    func testDefaultProfileSafetyRoutesByAdmissibleBooks() throws {
        let (reference, package) = try Self.fixture.get()
        var admitted = 0
        for mode in StoryMode.allCases {
            let p56Mode = try XCTUnwrap(P56Mode(rawValue: mode.rawValue))
            for id in P56Support.companionIDs(age: 5, mode: p56Mode, package: package) {
                let decision = router().decide(request(mode: mode, companionID: id, safety: .mostProtective))
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
        XCTAssertEqual(router().decide(request(companionID: nil, safety: .mostProtective)).route, .p56(reference))
    }

    func testAgeAloneIsUnsupportedAge() {
        XCTAssertEqual(router().decide(request(age: 3)), StoryRuntimeDecision(route: .legacy, reason: .unsupportedAge))
        XCTAssertEqual(router().decide(request(age: 7)).reason, .unsupportedAge)
    }

    func testAgeWithOtherReasonsIsUnsupportedRequest() {
        let family = FamilyCharacter(childID: UUID(), name: "Ela", relation: .sibling)
        XCTAssertEqual(router().decide(request(age: 3, family: family)).reason, .unsupportedRequest)
    }

    func testArchiveOutcomeIsKeptApartFromTheDecision() throws {
        let (reference, _) = try Self.fixture.get()
        struct Full: Error {}
        let failing = StoryRuntimeRouter(isEnabled: true, loadSource: { try Self.fixture.get() },
                                         archive: { throw Full() })
        XCTAssertEqual(failing.decide(request()).route, .p56(reference), "arşiv hatası kararı değiştirmez")
        let done = expectation(description: "arşiv sonucu")
        DispatchQueue.global().async {
            while failing.archiveOutcome == nil { usleep(10_000) }
            done.fulfill()
        }
        wait(for: [done], timeout: 10)
        XCTAssertEqual(failing.archiveOutcome, .failed)

        let ok = StoryRuntimeRouter(isEnabled: true, loadSource: { try Self.fixture.get() }, archive: {})
        _ = ok.decide(request())
        let okDone = expectation(description: "arşiv tamam")
        DispatchQueue.global().async {
            while ok.archiveOutcome == nil { usleep(10_000) }
            okDone.fulfill()
        }
        wait(for: [okDone], timeout: 10)
        XCTAssertEqual(ok.archiveOutcome, .archived)
    }

    func testUnknownCompanionGoesLegacy() {
        XCTAssertEqual(router().decide(request(companionID: "companion_dolphin_pilot_001")).reason, .unsupportedRequest)
    }

    func testBrokenPayloadGoesLegacy() {
        struct Broken: Error {}
        XCTAssertEqual(router(load: { throw Broken() }).decide(request()),
                       StoryRuntimeDecision(route: .legacy, reason: .payloadUnavailable))
    }

    func testSourceLoadsOnceAndDecisionIsDeterministic() {
        var loads = 0
        let router = router(load: { loads += 1; return try Self.fixture.get() })
        XCTAssertEqual(router.decide(request()), router.decide(request()))
        XCTAssertEqual(loads, 1)
    }

    func testPrewarmLoadsOffTheMainThreadOnce() throws {
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
        wait(for: [loaded], timeout: 10)
        let (reference, _) = try Self.fixture.get()
        XCTAssertEqual(router.decide(request()).route, .p56(reference))
        lock.lock(); defer { lock.unlock() }
        XCTAssertFalse(onMain, "ön yükleme ana iş parçacığını tutmaz")
        XCTAssertEqual(loads, 1, "karar ön yüklenen kaynağı kullanır")
    }

    func testPrewarmDoesNothingWhenFlagIsOff() {
        let notLoaded = expectation(description: "bayrak kapalıyken yüklenmez")
        notLoaded.isInverted = true
        router(enabled: false, load: { notLoaded.fulfill(); return try Self.fixture.get() }).prewarm()
        wait(for: [notLoaded], timeout: 1)
    }

    func testPackageIsHandedOnlyForTheDecidedSource() throws {
        let (reference, _) = try Self.fixture.get()
        let router = router()
        XCTAssertNotNil(router.package(for: reference))
        XCTAssertNil(router.package(for: P56SourceReference(payloadSHA256: String(repeating: "0", count: 64))))
    }

    func testSupportRequestCarriesNoChildData() {
        let p56 = StoryRuntimeRouter.p56Request(for: request(family: FamilyCharacter(childID: UUID(), name: "Gizli", relation: .sibling),
                                                            topicID: "t", occasion: "o", safety: .mostProtective))
        XCTAssertEqual(p56.childID, "support-check")
        XCTAssertEqual(p56.name, "Deniz")
        XCTAssertEqual(p56.seed, 0)
        XCTAssertEqual(Set(p56.contexts), ["family", "topic", "occasion"])
        XCTAssertEqual(p56.contentSafety, .mostProtective, "güvenlik politikası olduğu gibi taşınır")
        XCTAssertFalse(p56.contexts.contains("Gizli"))
    }

    func testReleaseFlagIsOff() {
        #if !DEBUG
        XCTAssertFalse(StoryRuntimeFlags.fiveFriendsPilot)
        #endif
    }
}
