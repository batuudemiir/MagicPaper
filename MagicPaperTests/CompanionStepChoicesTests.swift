import XCTest
import CryptoKit
import StoryEngine
@testable import MagicPaper

/// B5 (beş arkadaş B hattı): "Masalda kimler olsun?" P56 yönünde beşliyi gösterir;
/// başka her durumda liste bugünküyle aynı kalır.
@MainActor
final class CompanionStepChoicesTests: XCTestCase {
    private static let fixture: Result<(P56SourceReference, P56Package), Error> = Result {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/\(P56PinnedSource.packageVersion)/payload.json"))
        let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        let package = try P56PackageLoader.load(payload: bytes, expectedSHA256: digest)
        return (package.sourceReference, package)
    }

    private let five = ["companion_fox_pilot_001", "companion_hedgehog_pilot_001", "companion_owl_pilot_001",
                        "companion_city_cat_001", "companion_bear_001"]
    private var base: OfflineStoryService { OfflineStoryService.shared }

    /// A source whose payload has been read: the final list, not the provisional five.
    private func source(safety: ContentSafety? = nil, enabled: Bool = true) async -> FiveFriendsChoiceSource {
        let source = loadingSource(safety: safety, enabled: enabled)
        await source.waitUntilReady()
        return source
    }

    private func loadingSource(safety: ContentSafety? = nil, enabled: Bool = true,
                               load: @escaping () throws -> (P56SourceReference, P56Package) = { try fixture.get() })
        -> FiveFriendsChoiceSource {
        FiveFriendsChoiceSource(base: base,
                                router: StoryRuntimeRouter(isEnabled: enabled, loadSource: { P56VerifiedSource(try load()) },
                                                           archive: nil),
                                safety: { safety })
    }

    private func ids(_ source: any StoryChoiceSource, idea: String? = nil, mode: StoryMode? = .learning,
                     age: Int? = 5, topic: String? = nil, family: FamilyCharacter? = nil) -> [String] {
        let limit = source.companionDisplayLimit(forIdeaID: idea, age: age, mode: mode, topicID: topic, family: family)
        return Array(source.companionChoices(forIdeaID: idea, mode: mode, age: age, topicID: topic, family: family)
            .prefix(limit)).map(\.id)
    }

    func testFlagOffListIsTodays() async {
        let disabled = await source(enabled: false)
        if !StoryRuntimeFlags.fiveFriendsPilot {
            XCTAssertTrue(StoryChoiceSources.current is OfflineStoryService)
        }
        XCTAssertEqual(base.companionDisplayLimit(forIdeaID: nil, age: 5, mode: .learning, topicID: nil, family: nil), 3)
        XCTAssertEqual(ids(disabled), ids(base), "bayrak kapalı sarmalayıcı bugünkü listeyi verir")
    }

    func testP56ListsFiveInCanonicalOrder() async {
        let src = await source()
        for mode in StoryMode.allCases {
            XCTAssertEqual(ids(src, mode: mode), five, "\(mode)")
            XCTAssertEqual(src.companionDisplayLimit(forIdeaID: nil, age: 5, mode: mode, topicID: nil, family: nil), 5)
        }
    }

    func testNamesAndLinesComeFromTheCatalogNotAuthoringNotes() async throws {
        let src = await source()
        let choices = src.companionChoices(forIdeaID: nil, mode: .learning, age: 5, topicID: nil, family: nil)
        XCTAssertEqual(choices.map(\.name), ["Tarçın", "Kestane", "Yıldız", "Simit", "Böğürtlen"])
        let (_, package) = try Self.fixture.get()
        let notes = Set(package.companions.map(\.personality))
        XCTAssertTrue(choices.allSatisfy { !notes.contains($0.personality) }, "P56 yazar notu ekranda görünmez")
    }

    func testFamilyRestoresLegacyList() async {
        let src = await source()
        let family = FamilyCharacter(childID: UUID(), name: "Ela", relation: .sibling)
        XCTAssertEqual(ids(src, family: family), ids(base, family: family))
        XCTAssertEqual(src.companionDisplayLimit(forIdeaID: nil, age: 5, mode: .learning, topicID: nil, family: family), 3)
    }

    /// v2 (C3): varsayılan güvenlikle liste yalnız P56'nın gerçekten yazabileceği arkadaşlar.
    func testDefaultSafetyListsOnlyWritableFriends() async throws {
        let protective = await source(safety: .mostProtective)
        let router = StoryRuntimeRouter(isEnabled: true, loadSource: { P56VerifiedSource(try Self.fixture.get()) }, archive: nil)
        for mode in StoryMode.allCases {
            let listed = ids(protective, mode: mode)
            XCTAssertFalse(listed.isEmpty, "\(mode)")
            XCTAssertEqual(listed, five.filter(listed.contains), "kanonik sıra korunur")
            for id in listed {
                guard case .p56 = await router.decide(StoryRuntimeRequest(age: 5, mode: mode, companionID: id, family: nil,
                                                                    topicID: nil, occasion: nil, safety: .mostProtective)).route
                else { return XCTFail("\(mode) \(id) listede ama P56 yazamaz") }
            }
        }
    }

    func testTopicIdeaAgeAndMissingModeRestoreLegacyList() async throws {
        let src = await source()
        let topic = base.topicChoices(forAge: 5, mode: .learning).first?.id
        if let topic { XCTAssertEqual(ids(src, topic: topic), ids(base, topic: topic)) }
        let idea = try XCTUnwrap(base.storyIdeas(forAge: 5, mode: .learning).first?.id.rawValue)
        XCTAssertEqual(ids(src, idea: idea), ids(base, idea: idea))
        XCTAssertEqual(ids(src, age: 3), ids(base, age: 3))
        XCTAssertEqual(ids(src, mode: nil), ids(base, mode: nil))
    }

    /// Kod düzeltmeleri (26 Kasım): paket okunurken ekran beklemez, beşliyi hemen görür;
    /// okuma bitince son liste gelir. Biçimi P56'ya uymayan istek eski listede kalır.
    func testFiveShowImmediatelyWhileThePayloadIsRead() async throws {
        let gate = DispatchSemaphore(value: 0)
        let source = loadingSource(load: { gate.wait(); return try Self.fixture.get() })
        XCTAssertFalse(source.isReady)
        XCTAssertEqual(ids(source), five, "okunurken beşli hemen görünür")
        XCTAssertEqual(ids(source, age: 3), ids(base, age: 3))
        let family = FamilyCharacter(childID: UUID(), name: "Ela", relation: .sibling)
        XCTAssertEqual(ids(source, family: family), ids(base, family: family))
        gate.signal()
        await source.waitUntilReady()
        XCTAssertTrue(source.isReady)
        XCTAssertEqual(ids(source), five)
    }

    func testProvisionalOrderIsTheEnginesCanonicalOrder() throws {
        let (_, package) = try Self.fixture.get()
        for mode in P56Mode.allCases {
            let canonical = P56Support.companionIDs(age: 5, mode: mode, package: package)
            XCTAssertEqual(FiveFriendsChoiceSource.provisionalIDs.filter(canonical.contains), canonical, "\(mode)")
        }
        XCTAssertEqual(FiveFriendsChoiceSource.provisionalIDs, five)
    }

    /// Küçük kademe ızgarası (LittleSteps) altı karoyu geçmez; bugünkü üç arkadaş korunur.
    func testLittleGridNeverExceedsSixTiles() async {
        XCTAssertEqual(LittleCompanionStep.shownCompanions(limit: 3, familyCount: 0), 3)
        XCTAssertEqual(LittleCompanionStep.shownCompanions(limit: 3, familyCount: 2), 3)
        XCTAssertEqual(LittleCompanionStep.shownCompanions(limit: 5, familyCount: 0), 5)
        XCTAssertEqual(LittleCompanionStep.shownCompanions(limit: 5, familyCount: 1), 4)
        XCTAssertEqual(LittleCompanionStep.shownCompanions(limit: 5, familyCount: 2), 3)
    }

    func testEverythingElseIsForwarded() async {
        let src = await source()
        let wrapped = src
        XCTAssertEqual(wrapped.authoredBands(), base.authoredBands())
        XCTAssertEqual(wrapped.availableModes(forAge: 5), base.availableModes(forAge: 5))
        XCTAssertEqual(wrapped.occasionChoices(forAge: 5, mode: .learning), base.occasionChoices(forAge: 5, mode: .learning))
        XCTAssertEqual(wrapped.ideaChoices(forAge: 5, mode: .learning).map(\.id), base.ideaChoices(forAge: 5, mode: .learning).map(\.id))
    }
}
