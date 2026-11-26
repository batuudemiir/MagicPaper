import XCTest
import CryptoKit
import StoryEngine
@testable import MagicPaper

/// B6 (beş arkadaş B hattı): P56 masalı devam ettirilmez, hatırlamaya girmez ve
/// eski kataloğa düşürülmez; kayıtlı sayfalarıyla okunur.
@MainActor
final class P56GuardTests: XCTestCase {
    private static let composed: Result<P56ComposedStory, Error> = Result {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-v1/payload.json"))
        let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        let package = try P56PackageLoader.load(payload: bytes, expectedSHA256: digest)
        return try P56StoryComposer(package: package).compose(
            P56Request(childID: "guard-child", name: "Deniz", age: 5, seed: 3, mode: .adventure,
                       companionID: "companion_fox_pilot_001"))
    }

    private func finishedP56(daysAgo: Double = 10) throws -> MagicPaper.Story {
        var story = P56StoryMapper.story(from: try Self.composed.get(), childProfileID: UUID(), strategy: nil)
        story.lastReadPage = story.pages.count - 1
        story.lastReadAt = Date(timeIntervalSinceNow: -daysAgo * 86_400)
        story.createdAt = Date(timeIntervalSinceNow: -daysAgo * 86_400)
        return story
    }

    private func finishedLegacy(companion: String, setting: String, daysAgo: Double = 20) -> MagicPaper.Story {
        var story = ReaderFixtures.textStory(pages: 3)
        story.lastReadPage = 2
        story.lastReadAt = Date(timeIntervalSinceNow: -daysAgo * 86_400)
        story.createdAt = Date(timeIntervalSinceNow: -daysAgo * 86_400)
        story.origin = StoryOrigin(seed: "s", storyIdeaID: nil, blueprintID: "b", settingID: setting,
                                   companionID: companion, discoveryID: "d", fingerprint: "f",
                                   catalogVersion: "1")
        return story
    }

    func testP56StoryHasNoSeriesOffer() throws {
        let origin = try XCTUnwrap(finishedP56().origin)
        XCTAssertFalse(OfflineStoryService.shared.seriesAvailable(from: origin), "P56 seriyi desteklemiyor")
    }

    func testHistoricalResolverRefusesP56() throws {
        let reference = try Self.composed.get().sourceReference
        guard case .unsupported = HistoricalCatalogResolver().resolve(metadata: ContentSourceMetadata(p56: reference)) else {
            return XCTFail("P56 kaynağı eski kataloğa çözülmemeli")
        }
    }

    func testP56StoryNotInRecallHistory() throws {
        let story = try finishedP56()
        XCTAssertTrue(story.isFinished)
        XCTAssertNil(StoryContextBuilder.recallHistory(of: [story]))
    }

    func testLegacyRecallUnchanged() throws {
        let legacy = finishedLegacy(companion: "companion_owl_pilot_001", setting: "garden")
        let history = try XCTUnwrap(StoryContextBuilder.recallHistory(of: [try finishedP56(), legacy]))
        XCTAssertEqual(history.companions.keys.map(\.rawValue), ["companion_owl_pilot_001"])
        XCTAssertEqual(history.visitedSettings, [ContentID("garden")])
        XCTAssertNil(history.companions[ContentID("companion_fox_pilot_001")], "P56 masalının arkadaşı sayılmadı")
    }

    func testSourceLostP56StaysOutOfRecallAndSeries() throws {
        var story = try finishedP56()
        story.origin?.contentSource = nil   // örn. eski bir istemci alanı düşürdü
        XCTAssertNil(StoryContextBuilder.recallHistory(of: [story]))
        XCTAssertFalse(OfflineStoryService.shared.seriesAvailable(from: try XCTUnwrap(story.origin)))
    }

    func testSavedP56PagesReadWithoutPayload() throws {
        let composed = try Self.composed.get()
        let story = try finishedP56()
        let decoded = try JSONDecoder().decode(MagicPaper.Story.self, from: JSONEncoder().encode(story))
        XCTAssertEqual(decoded.pages.map(\.text), composed.pages.sorted { $0.number < $1.number }.map(\.text))
    }
}
