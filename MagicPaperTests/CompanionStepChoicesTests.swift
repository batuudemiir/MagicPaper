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
        let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-v1/payload.json"))
        let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        let package = try P56PackageLoader.load(payload: bytes, expectedSHA256: digest)
        return (package.sourceReference, package)
    }

    private let five = ["companion_fox_pilot_001", "companion_hedgehog_pilot_001", "companion_owl_pilot_001",
                        "companion_city_cat_001", "companion_bear_001"]
    private var base: OfflineStoryService { OfflineStoryService.shared }

    private func source(safety: ContentSafety? = nil, enabled: Bool = true) -> FiveFriendsChoiceSource {
        FiveFriendsChoiceSource(base: base,
                                router: StoryRuntimeRouter(isEnabled: enabled, loadSource: { try Self.fixture.get() }),
                                safety: { safety })
    }

    private func ids(_ source: any StoryChoiceSource, idea: String? = nil, mode: StoryMode? = .learning,
                     age: Int? = 5, topic: String? = nil, family: FamilyCharacter? = nil) -> [String] {
        let limit = source.companionDisplayLimit(age: age, mode: mode, topicID: topic, family: family)
        return Array(source.companionChoices(forIdeaID: idea, mode: mode, age: age, topicID: topic, family: family)
            .prefix(limit)).map(\.id)
    }

    func testFlagOffListIsTodays() {
        if !StoryRuntimeFlags.fiveFriendsPilot {
            XCTAssertTrue(StoryChoiceSources.current is OfflineStoryService)
        }
        XCTAssertEqual(base.companionDisplayLimit(age: 5, mode: .learning, topicID: nil, family: nil), 3)
        XCTAssertEqual(ids(source(enabled: false)), ids(base), "bayrak kapalı sarmalayıcı bugünkü listeyi verir")
    }

    func testP56ListsFiveInCanonicalOrder() {
        for mode in StoryMode.allCases {
            XCTAssertEqual(ids(source(), mode: mode), five, "\(mode)")
            XCTAssertEqual(source().companionDisplayLimit(age: 5, mode: mode, topicID: nil, family: nil), 5)
        }
    }

    func testNamesAndLinesComeFromTheCatalogNotAuthoringNotes() throws {
        let choices = source().companionChoices(forIdeaID: nil, mode: .learning, age: 5, topicID: nil, family: nil)
        XCTAssertEqual(choices.map(\.name), ["Tarçın", "Kestane", "Yıldız", "Simit", "Böğürtlen"])
        let (_, package) = try Self.fixture.get()
        let notes = Set(package.companions.map(\.personality))
        XCTAssertTrue(choices.allSatisfy { !notes.contains($0.personality) }, "P56 yazar notu ekranda görünmez")
    }

    func testFamilyRestoresLegacyList() {
        let family = FamilyCharacter(childID: UUID(), name: "Ela", relation: .sibling)
        XCTAssertEqual(ids(source(), family: family), ids(base, family: family))
        XCTAssertEqual(source().companionDisplayLimit(age: 5, mode: .learning, topicID: nil, family: family), 3)
    }

    func testDefaultSafetyRestoresLegacyList() {
        XCTAssertEqual(ids(source(safety: .mostProtective)), ids(base), "C3 öncesi varsayılan güvenlik eski listeyi verir")
    }

    func testTopicIdeaAgeAndMissingModeRestoreLegacyList() throws {
        let topic = base.topicChoices(forAge: 5, mode: .learning).first?.id
        if let topic { XCTAssertEqual(ids(source(), topic: topic), ids(base, topic: topic)) }
        let idea = try XCTUnwrap(base.storyIdeas(forAge: 5, mode: .learning).first?.id.rawValue)
        XCTAssertEqual(ids(source(), idea: idea), ids(base, idea: idea))
        XCTAssertEqual(ids(source(), age: 3), ids(base, age: 3))
        XCTAssertEqual(ids(source(), mode: nil), ids(base, mode: nil))
    }

    func testEverythingElseIsForwarded() {
        let wrapped = source()
        XCTAssertEqual(wrapped.authoredBands(), base.authoredBands())
        XCTAssertEqual(wrapped.availableModes(forAge: 5), base.availableModes(forAge: 5))
        XCTAssertEqual(wrapped.occasionChoices(forAge: 5, mode: .learning), base.occasionChoices(forAge: 5, mode: .learning))
        XCTAssertEqual(wrapped.ideaChoices(forAge: 5, mode: .learning).map(\.id), base.ideaChoices(forAge: 5, mode: .learning).map(\.id))
    }
}
