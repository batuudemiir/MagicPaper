import XCTest
import CryptoKit
import StoryEngine
@testable import MagicPaper

/// B4 (beş arkadaş B hattı): `createStory` yönlendiricinin kararına göre yazar;
/// bayrak kapalıyken eski yol değişmez, P56 hatasında aynı girdilerle eski yola döner.
@MainActor
final class P56CompositionPathTests: XCTestCase {
    private static let fixture: Result<(P56SourceReference, P56Package), Error> = Result {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-v1/payload.json"))
        let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        let package = try P56PackageLoader.load(payload: bytes, expectedSHA256: digest)
        return (package.sourceReference, package)
    }

    private let fox = "companion_fox_pilot_001"
    private var suite: String!
    private var savedSafety: ContentSafety?

    override func setUp() async throws {
        suite = "P56CompositionPathTests-\(UUID().uuidString)"
        savedSafety = OfflineStoryService.shared.currentSafety
        // C3 öncesi P56 her güvenlik politikasını reddeder; P56 yolunu sınamak için burada nil.
        OfflineStoryService.shared.currentSafety = nil
    }

    override func tearDown() async throws {
        OfflineStoryService.shared.currentSafety = savedSafety
        UserDefaults().removePersistentDomain(forName: suite)
    }

    private func manager(enabled: Bool, writer: P56StoryWriter = P56StoryWriter()) -> StoryGenerationManager {
        let shelf = LibraryShelf(defaults: UserDefaults(suiteName: suite)!, migration: nil)
        return StoryGenerationManager(library: shelf, notifications: NotificationCenter(),
                                      runtime: StoryRuntimeRouter(isEnabled: enabled, loadSource: { try Self.fixture.get() }),
                                      p56Writer: writer)
    }

    private let profile = UserProfile(name: "Deniz", age: 5)

    func testFlagOffOutputUnchanged() async throws {
        let manager = manager(enabled: false)
        let story = try await manager.createStory(for: profile, mode: .learning, storyIdeaID: nil,
                                                  companionID: fox, seed: "42")
        let context = StoryContextBuilder().build(for: profile, library: [], mode: .learning, strategy: nil,
                                                  storyIdeaID: nil, companionID: fox, subOption: nil,
                                                  family: nil, occasion: nil)
        let direct = try OfflineStoryService.shared.compose(context, seed: "42")
        XCTAssertEqual(story.pages.map(\.text), direct.story.pages.sorted { $0.pageNumber < $1.pageNumber }.map(\.text))
        XCTAssertNil(story.origin?.contentSource?.p56Reference)
        XCTAssertEqual(manager.lastRuntimeDecision, StoryRuntimeDecision(route: .legacy, reason: .flagOff))
    }

    func testP56RouteWritesAndSaves() async throws {
        let manager = manager(enabled: true)
        let story = try await manager.createStory(for: profile, mode: .learning, storyIdeaID: nil,
                                                  companionID: fox, seed: "42")
        let (reference, _) = try Self.fixture.get()
        XCTAssertEqual(story.origin?.contentSource?.p56Reference, reference)
        XCTAssertEqual(story.origin?.companionID, fox)
        XCTAssertEqual(story.pages.count, 8)
        XCTAssertEqual(manager.stories.first?.id, story.id)
        XCTAssertEqual(manager.lastRuntimeDecision, StoryRuntimeDecision(route: .p56(reference), reason: nil))
    }

    func testWriterUsesRealChildForCompose() async throws {
        var seen: P56Request?
        let writer = P56StoryWriter(compose: { request, package in
            seen = request
            return try P56StoryComposer(package: package).compose(request)
        })
        let story = try await manager(enabled: true, writer: writer)
            .createStory(for: profile, mode: .learning, storyIdeaID: nil, companionID: fox, seed: "42")
        XCTAssertEqual(seen?.name, "Deniz")
        XCTAssertEqual(seen?.childID, profile.id.uuidString, "destek kontrolündeki anonim kimlik değil")
        XCTAssertEqual(seen?.seed, 42)
        XCTAssertEqual(seen?.companionID, fox)
        XCTAssertEqual(story.childName, "Deniz")
        XCTAssertEqual(story.childProfileID, profile.id)
    }

    func testComposeFailureFallsBackWithSameInputs() async throws {
        struct Refused: Error {}
        let writer = P56StoryWriter(compose: { _, _ in throw Refused() })
        let manager = manager(enabled: true, writer: writer)
        let story = try await manager.createStory(for: profile, mode: .learning, storyIdeaID: nil,
                                                  companionID: fox, seed: "42")
        XCTAssertNil(story.origin?.contentSource?.p56Reference, "eski motor yazdı")
        XCTAssertEqual(story.origin?.companionID, fox, "başka arkadaşa çevrilmedi")
        XCTAssertEqual(story.origin?.modeID, "learning")
        XCTAssertNil(story.origin?.familyCharacterID)
        let (reference, _) = try Self.fixture.get()
        XCTAssertEqual(manager.lastRuntimeDecision, StoryRuntimeDecision(route: .p56(reference), reason: .composeFailed))
    }

    func testFallbackReasonHasNoChildData() {
        XCTAssertEqual(StoryRuntimeReason.composeFailed.rawValue, "composeFailed")
        XCTAssertFalse(String(describing: StoryRuntimeDecision(route: .legacy, reason: .composeFailed)).contains("Deniz"))
    }

    func testChosenStoryIdeaStaysLegacy() async throws {
        let manager = manager(enabled: true)
        let idea = try XCTUnwrap(OfflineStoryService.shared.storyIdeas(forAge: 5, mode: .learning).first)
        let story = try await manager.createStory(for: profile, mode: .learning, storyIdeaID: idea.id.rawValue,
                                                  companionID: nil, seed: "42")
        XCTAssertNil(story.origin?.contentSource?.p56Reference, "P56 kart sözünü taşıyamaz")
        XCTAssertEqual(manager.lastRuntimeDecision?.reason, .unsupportedRequest)
    }

    func testNoModeStaysLegacyWithoutAsking() async throws {
        let manager = manager(enabled: true)
        _ = try await manager.createStory(for: profile, storyIdeaID: nil, companionID: nil, seed: "42")
        XCTAssertNil(manager.lastRuntimeDecision)
    }

    func testSeedBridgeIsDeterministic() {
        XCTAssertEqual(P56StoryWriter.seed(from: "123"), 123)
        XCTAssertEqual(P56StoryWriter.seed(from: "abc"), P56StoryWriter.seed(from: "abc"))
        XCTAssertNotEqual(P56StoryWriter.seed(from: "abc"), P56StoryWriter.seed(from: "abd"))
    }
}
