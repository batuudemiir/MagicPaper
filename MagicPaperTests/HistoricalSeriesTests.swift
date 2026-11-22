import XCTest
import StoryEngine
@testable import MagicPaper

@MainActor
final class HistoricalSeriesTests: XCTestCase {
    private var directory: URL!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("HistoricalSeries-\(UUID())")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    private func source() throws -> (CatalogSnapshotStore, CatalogSourceResolver.Resolved) {
        let files = ContentPackage.bundledSources()
        let catalog = try ContentCatalogLoader().load()
        let payload = try ContentPackage.build(version: catalog.catalog.version, libraries: files.libraries, beats: files.beats)
        let store = CatalogSnapshotStore(root: directory)
        let reference = try store.saveVerified(payload: payload)
        return (store, .init(result: catalog, fromPackage: false, contentSource: ContentSourceMetadata(reference)))
    }

    func testCompositionCarriesTheSameSourceThroughMapping() throws {
        let (store, resolved) = try source()
        let service = OfflineStoryService(currentSource: { resolved }, historical: HistoricalCatalogResolver(store: store))
        let result = try service.compose(childName: "Deniz", ideaID: nil, companionID: nil,
                                         mode: .adventure, age: 6, seed: "source-carry")
        let story = OfflineStoryMapper.appStory(from: result.story, childName: "Deniz", childProfileID: UUID(),
            storyIdeaID: nil, catalogVersion: result.catalogVersion, contentSource: result.contentSource)
        XCTAssertEqual(story.origin?.contentSource, resolved.contentSource)
        XCTAssertEqual(story.pages.map(\.text), result.story.pages.map(\.text))
    }

    func testHistoricalPlanningDoesNotAskForCurrentCatalog() throws {
        let (store, resolved) = try source()
        let writer = OfflineStoryService(currentSource: { resolved }, historical: HistoricalCatalogResolver(store: store))
        let first = try writer.compose(childName: "Deniz", ideaID: nil, companionID: nil,
                                      mode: .adventure, age: 6, seed: "history-plan")
        let book = OfflineStoryMapper.appStory(from: first.story, childName: "Deniz", childProfileID: UUID(),
            storyIdeaID: nil, catalogVersion: first.catalogVersion, contentSource: first.contentSource,
            mode: .adventure, selectionStrategy: .direct, ageBand: AgeBand(lowerBound: 5, upperBound: 6))
        var currentCalls = 0
        let service = OfflineStoryService(currentSource: {
            currentCalls += 1
            throw NSError(domain: "CurrentMustNotBeUsed", code: 1)
        }, historical: HistoricalCatalogResolver(store: store))
        let origin = try XCTUnwrap(book.origin)
        let planned = try service.planSeries(from: origin, childName: "Deniz", family: nil)
        XCTAssertEqual(currentCalls, 0)
        XCTAssertEqual(planned.plan.contentSource, first.contentSource)
        let rewritten = try service.composeSeries(planned.plan, childName: "Deniz", family: nil)
        XCTAssertEqual(currentCalls, 0)
        XCTAssertEqual(rewritten.map { $0.pages.map(\.text) }, planned.episodes.map { $0.pages.map(\.text) })
    }

    func testAnUnprovenLegacyOriginNeverFallsBackToCurrent() throws {
        let (store, resolved) = try source()
        let writer = OfflineStoryService(currentSource: { resolved }, historical: HistoricalCatalogResolver(store: store))
        let first = try writer.compose(childName: "Deniz", ideaID: nil, companionID: nil,
                                      mode: .adventure, age: 6, seed: "legacy-missing")
        var book = OfflineStoryMapper.appStory(from: first.story, childName: "Deniz", childProfileID: UUID(),
            storyIdeaID: nil, catalogVersion: first.catalogVersion, mode: .adventure,
            selectionStrategy: .direct, ageBand: AgeBand(lowerBound: 5, upperBound: 6))
        book.origin?.contentSource = nil
        let origin = try XCTUnwrap(book.origin)
        var calls = 0
        let service = OfflineStoryService(currentSource: { calls += 1; return resolved },
                                         historical: HistoricalCatalogResolver(store: store))
        XCTAssertFalse(service.seriesAvailable(from: origin))
        XCTAssertThrowsError(try service.planSeries(from: origin, childName: "Deniz", family: nil))
        XCTAssertEqual(calls, 0)
        XCTAssertEqual(book.pages.map(\.text), first.story.pages.map(\.text))
    }

    func testCacheResetRequiresTheCurrentSourceToBeArchivedAgain() throws {
        let (store, resolved) = try source()
        let files = ContentPackage.bundledSources()
        let payload = try ContentPackage.build(version: resolved.result.catalog.version,
                                               libraries: files.libraries, beats: files.beats)
        var lookups = 0
        let service = OfflineStoryService(currentSource: {
            lookups += 1
            _ = try store.saveVerified(payload: payload)
            return resolved
        }, historical: HistoricalCatalogResolver(store: store))
        _ = try service.compose(childName: "Deniz", ideaID: nil, companionID: nil,
                                mode: .adventure, age: 6, seed: "cache-before-erase")
        try store.eraseAll()
        service.resetSourceCache()
        _ = try service.compose(childName: "Deniz", ideaID: nil, companionID: nil,
                                mode: .adventure, age: 6, seed: "cache-after-erase")
        XCTAssertEqual(lookups, 2)
        let reference = try XCTUnwrap(resolved.contentSource.reference)
        XCTAssertEqual(try store.load(reference).catalog.version, reference.catalogVersion)
    }
    func testEmptyHistoryResolvesThisBuildsExactBundledSource() throws {
        let (store, resolved) = try source()
        let reference = try XCTUnwrap(resolved.contentSource.reference)
        try store.eraseAll()
        let resolver = HistoricalCatalogResolver.forThisBuild(store: store)
        if case .exact(let loaded, let exact) = resolver.resolve(reference: reference) {
            XCTAssertEqual(exact, reference)
            XCTAssertEqual(loaded.catalog.version, resolved.result.catalog.version)
        } else { XCTFail("Exact shipped source must resolve without a populated archive") }
    }

    func testMalformedAndExplicitNullSourceSurviveOriginAndPlanRoundTrip() throws {
        let originJSON = #"{"seed":"s","blueprintID":"b","settingID":"forest","companionID":"old-friend","discoveryID":"map","fingerprint":"f","catalogVersion":"2.1.0","modeID":"growth","selectionStrategy":"direct","ageBand":"5-6"}"#
        let baseOrigin = try JSONSerialization.jsonObject(with: Data(originJSON.utf8)) as! [String: Any]
        let plan = SeriesPlan(seed: "s", catalogVersion: "2.1.0", mode: .learning,
            ageBand: AgeBand(lowerBound: 5, upperBound: 6),
            anchor: SeriesAnchor(settingID: "forest", companionID: "old-friend", keepsakeID: "map"),
            family: nil, episodes: [])
        let basePlan = try JSONSerialization.jsonObject(with: JSONEncoder().encode(plan)) as! [String: Any]
        for raw in [NSNull(), ["schemaVersion": "broken", "unknown": ["preserved": true]]] as [Any] {
            var object = baseOrigin
            object["contentSource"] = raw
            let origin = try JSONDecoder().decode(StoryOrigin.self, from: JSONSerialization.data(withJSONObject: object))
            XCTAssertNotNil(origin.contentSource)
            XCTAssertEqual(origin.contentSource?.status, .malformed)
            let restored = try JSONDecoder().decode(StoryOrigin.self, from: JSONEncoder().encode(origin))
            XCTAssertEqual(restored, origin)
            var planObject = basePlan
            planObject["contentSource"] = raw
            let decoded = try JSONDecoder().decode(SeriesPlan.self, from: JSONSerialization.data(withJSONObject: planObject))
            XCTAssertNotNil(decoded.contentSource)
            XCTAssertEqual(decoded.contentSource?.status, .malformed)
            XCTAssertEqual(try JSONDecoder().decode(SeriesPlan.self, from: JSONEncoder().encode(decoded)), decoded)
            XCTAssertEqual(decoded.withoutFamily().contentSource, decoded.contentSource)
        }
    }

    func testStoredEpisodeUnlockAndReinsertNeedNoResolvableSource() throws {
        let folder = "HistoricalUnlock-\(UUID())"
        let suite = "HistoricalUnlockClock-\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let store = StorySeriesStore(subdirectory: folder)
        let library = StoryGenerationManager.shared
        let before = Set(library.stories.map(\.id))
        defer {
            store.eraseAll()
            defaults.removePersistentDomain(forName: suite)
            library.deleteStories(ids: Set(library.stories.map(\.id)).subtracting(before))
        }
        let originJSON = #"{"seed":"stored","blueprintID":"b","settingID":"forest","companionID":"old-friend","discoveryID":"map","fingerprint":"saved","catalogVersion":"2.1.0","modeID":"adventure","selectionStrategy":"direct","ageBand":"5-6"}"#
        var origin = try JSONDecoder().decode(StoryOrigin.self, from: Data(originJSON.utf8))
        let source = ContentSourceMetadata(try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: "a", count: 64)))
        origin.contentSource = source
        let child = UUID()
        let id = UUID()
        origin.seriesID = id.uuidString
        origin.seriesEpisode = 2
        var page = StoryPage(title: "Saklanan sayfa", text: "Özgün metin aynen kalır.", imagePrompt: "")
        page.art = StoryPageArt(role: "spot", altText: "Harita", sourceID: "historical-pin", assetRevision: 5,
                                assetDigest: String(repeating: "b", count: 64))
        page.provenance = StoryPageProvenance(parts: [
            .init(sourceKind: "beat_line", sourceID: "historical-line", sourceTextDigest: "digest", contexts: ["series"])
        ])
        let episode = SeriesEpisode(number: 2, title: "Kaydedilen bölüm", theme: .fantasy, pages: [page], origin: origin)
        let plan = SeriesPlan(seed: "stored", catalogVersion: "2.1.0", mode: .adventure,
            ageBand: AgeBand(lowerBound: 5, upperBound: 6),
            anchor: SeriesAnchor(settingID: "forest", companionID: "old-friend", keepsakeID: "map"),
            family: nil, episodes: [], contentSource: source)
        let clock = TestClock("2026-11-23 09:00")
        let firstRead = SeriesReadMark(at: clock.now.addingTimeInterval(-86400), day: "2026-11-22", timeZone: "Europe/Istanbul")
        try store.save(StorySeries(id: id, childID: child, childName: "Deniz", firstStoryID: UUID(),
            firstStoryTitle: "İlk kitap", plan: plan, episodes: [episode], firstRead: firstRead, createdAt: firstRead.at))
        var calls = 0
        let service = OfflineStoryService(currentSource: {
            calls += 1
            XCTFail("Stored unlock must never ask for current source")
            throw NSError(domain: "NoCurrentSource", code: 1)
        }, historical: HistoricalCatalogResolver(store: CatalogSnapshotStore(root: directory)))
        let manager = SeriesManager(store: store,
            clock: SeriesClock(wallClock: { clock.now }, timeZone: { clock.zone }, defaults: defaults),
            library: library, service: service, episodeAllowed: { _ in true })
        for _ in 0..<2 {
            manager.refreshUnlocks(for: child)
            let opened = try XCTUnwrap(store.openSeries(for: child)?.episodes.first)
            let bookID = try XCTUnwrap(opened.storyID)
            let book = try XCTUnwrap(library.getStory(id: bookID))
            XCTAssertEqual(book.pages.map(\.text), [page.text])
            XCTAssertEqual(book.pages.map(\.art), [page.art])
            XCTAssertEqual(book.pages.map(\.provenance), [page.provenance])
            XCTAssertEqual(book.origin, origin)
            library.deleteStory(id: bookID)
        }
        XCTAssertEqual(calls, 0)
    }

    func testFamilyRemovalPreservesOpenedArtAndExactSourceOfLockedRewrites() throws {
        let (history, resolved) = try source()
        let service = OfflineStoryService(currentSource: { resolved }, historical: HistoricalCatalogResolver(store: history))
        let folder = "HistoricalFamily-\(UUID())"
        let suite = "HistoricalFamilyClock-\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let store = StorySeriesStore(subdirectory: folder)
        let family = FamilyCharacterStore(subdirectory: folder + "-family")
        let library = StoryGenerationManager.shared
        let before = Set(library.stories.map(\.id))
        defer {
            store.eraseAll()
            family.eraseAll()
            defaults.removePersistentDomain(forName: suite)
            library.deleteStories(ids: Set(library.stories.map(\.id)).subtracting(before))
        }
        let child = UUID()
        let character = FamilyCharacter(childID: child, name: "Ela", relation: .sibling)
        try family.save(character)
        let composed = try service.compose(childName: "Deniz", ideaID: nil, companionID: nil,
            mode: .learning, age: 5, seed: "s1", family: character)
        var book = OfflineStoryMapper.appStory(from: composed.story, childName: "Deniz", childProfileID: child,
            storyIdeaID: nil, catalogVersion: composed.catalogVersion, contentSource: composed.contentSource,
            mode: .learning, selectionStrategy: .direct, ageBand: AgeBand(lowerBound: 5, upperBound: 6), familyCharacter: character)
        book.lastReadPage = book.pages.count - 1
        let clock = TestClock("2026-11-22 09:00")
        let manager = SeriesManager(store: store,
            clock: SeriesClock(wallClock: { clock.now }, timeZone: { clock.zone }, defaults: defaults),
            familyStore: family, library: library, service: service, episodeAllowed: { _ in true })
        var started = try manager.startSeries(from: book)
        started.episodes[0].pages[0].art = StoryPageArt(role: "spot", altText: "Saklanan sanat", sourceID: "opened-pin")
        try store.save(started)
        // A fresh manager reads the injected saved pin rather than a cached copy.
        let fresh = SeriesManager(store: store,
            clock: SeriesClock(wallClock: { clock.now }, timeZone: { clock.zone }, defaults: defaults),
            familyStore: family, library: library, service: service, episodeAllowed: { _ in true })
        clock.set("2026-11-23 09:00")
        fresh.refreshUnlocks(for: child)
        let opened = try XCTUnwrap(store.openSeries(for: child)?.episodes.first)
        try family.delete(id: character.id, childID: child)
        fresh.familyCharacterRemoved(id: character.id, childID: child)
        let after = try XCTUnwrap(store.openSeries(for: child))
        XCTAssertEqual(after.status, .open)
        XCTAssertEqual(after.plan.contentSource, composed.contentSource)
        XCTAssertEqual(after.episodes[0].pages.map(\.text), opened.pages.map(\.text))
        XCTAssertEqual(after.episodes[0].pages.map(\.art), opened.pages.map(\.art))
        XCTAssertEqual(after.episodes[0].pages.map(\.provenance), opened.pages.map(\.provenance))
        XCTAssertEqual(after.episodes[0].origin, opened.origin)
        for episode in after.episodes.dropFirst() {
            XCTAssertEqual(episode.origin.contentSource, composed.contentSource)
            XCTAssertNil(episode.origin.familyCharacterID)
        }
    }

}
