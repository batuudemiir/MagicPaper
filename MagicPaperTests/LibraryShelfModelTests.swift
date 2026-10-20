import XCTest
@testable import MagicPaper

/// Kitaplığın içeriği (20 Ekim 2026): raflar, süzgeçler, sıralama, arama,
/// rozet önceliği ve Günlük klasikleri.
@MainActor
final class LibraryShelfModelTests: XCTestCase {

    // MARK: Raflar

    func testShelvesFollowModeOrderThenFavoritesAndClassics() {
        let adventure = Self.story("Orman", mode: "adventure")
        let bedtime = Self.story("Ay", mode: "bedtime")
        let model = Self.model([adventure, bedtime], favorites: [adventure.id],
                               classics: [Self.classic(1, "Rapunzel")])
        XCTAssertEqual(model.shelves.map(\.filter), [.mode(.bedtime), .mode(.adventure), .favorites, .classics])
    }

    func testEmptyShelvesAreHidden() {
        let model = Self.model([Self.story("Ay", mode: "bedtime")])
        XCTAssertEqual(model.shelves.map(\.filter), [.mode(.bedtime)])
    }

    /// Eski "growth" kaydı Öğrenelim rafında durur.
    func testLegacyGrowthStoryLandsOnLearningShelf() {
        let model = Self.model([Self.story("Eski", mode: "growth")])
        XCTAssertEqual(model.shelves.first?.filter, .mode(.learning))
    }

    func testStoryWithoutModeIsOnlyUnderAll() {
        let model = Self.model([ReaderFixtures.textStory(pages: 2)])
        XCTAssertTrue(model.shelves.isEmpty)
        XCTAssertEqual(model.items(for: .all).count, 1)
        XCTAssertEqual(model.items.first?.meta.hasPrefix("Masal ·"), true)
    }

    // MARK: Süzgeçler

    func testFiltersListOnlyNonEmptyCategoriesInFixedOrder() {
        var half = Self.story("Yarım", mode: "learning")
        half.lastReadPage = 1
        half.pages += half.pages
        let model = Self.model([half, Self.story("Ay", mode: "bedtime")],
                               classics: [Self.classic(1, "Rapunzel")])
        XCTAssertEqual(model.availableFilters,
                       [.all, .unfinished, .mode(.bedtime), .mode(.learning), .classics])
    }

    func testModeFilterExcludesClassics() {
        let model = Self.model([Self.story("Ay", mode: "bedtime")], classics: [Self.classic(1, "Rapunzel")])
        XCTAssertEqual(model.items(for: .mode(.bedtime)).map(\.title), ["Ay"])
        XCTAssertEqual(model.items(for: .classics).map(\.title), ["Rapunzel"])
    }

    // MARK: Sıralama ve devam

    func testItemsAreNewestActivityFirst() {
        var old = Self.story("Eski", mode: "bedtime")
        old.createdAt = Date(timeIntervalSince1970: 100)
        var readRecently = Self.story("Dün okunan", mode: "bedtime")
        readRecently.createdAt = Date(timeIntervalSince1970: 50)
        readRecently.lastReadAt = Date(timeIntervalSince1970: 500)
        let model = Self.model([old, readRecently])
        XCTAssertEqual(model.items.map(\.title), ["Dün okunan", "Eski"])
    }

    func testContinueShowsOnlyPartlyReadNewestFirst() {
        var a = Self.story("A", mode: "bedtime", pages: 4)
        a.lastReadPage = 1; a.lastReadAt = Date(timeIntervalSince1970: 10)
        var b = Self.story("B", mode: "bedtime", pages: 4)
        b.lastReadPage = 2; b.lastReadAt = Date(timeIntervalSince1970: 20)
        var done = Self.story("Bitti", mode: "bedtime", pages: 4)
        done.lastReadPage = 3; done.lastReadAt = Date(timeIntervalSince1970: 30)
        let model = Self.model([a, b, done], classics: [Self.classic(1, "Rapunzel", fraction: 0.5, openedAt: 5)])
        XCTAssertEqual(model.continueItems(limit: 2).map(\.title), ["B", "A"])
    }

    // MARK: Arama

    func testSearchMatchesTitleModeAndWorldWithTurkishFolding() {
        let model = Self.model([Self.story("İrem ve Işık", mode: "bedtime"),
                                Self.story("Dağ", mode: "adventure")])
        XCTAssertEqual(model.items(for: .all, query: "irem").map(\.title), ["İrem ve Işık"])
        XCTAssertEqual(model.items(for: .all, query: "ışık").map(\.title), ["İrem ve Işık"])
        XCTAssertEqual(model.items(for: .all, query: "uyku").map(\.title), ["İrem ve Işık"])
        XCTAssertEqual(model.items(for: .all, query: "orman").count, 2, "dünya adı: Orman Macerası")
        XCTAssertTrue(model.items(for: .all, query: "  ").count == 2, "boş arama süzmez")
    }

    func testSearchAndFilterCombine() {
        let model = Self.model([Self.story("Ay", mode: "bedtime"), Self.story("Ay Dede", mode: "adventure")])
        XCTAssertEqual(model.items(for: .mode(.adventure), query: "ay").map(\.title), ["Ay Dede"])
    }

    func testClassicIsFoundByTitleAndWord() {
        let model = Self.model([], classics: [Self.classic(1, "Rapunzel")])
        XCTAssertEqual(model.items(for: .all, query: "rapun").count, 1)
        XCTAssertEqual(model.items(for: .all, query: "klasik").count, 1)
    }

    // MARK: Rozet

    func testBadgePriorityHalfThenEpisodeThenFavorite() {
        var episode = Self.story("Bölüm", mode: "adventure", pages: 4)
        episode.origin?.seriesEpisode = 2
        let fav = Self.story("Favori", mode: "adventure")
        var halfEpisode = Self.story("Yarım bölüm", mode: "adventure", pages: 4)
        halfEpisode.origin?.seriesEpisode = 3
        halfEpisode.lastReadPage = 1
        let model = Self.model([episode, fav, halfEpisode], favorites: [episode.id, fav.id, halfEpisode.id])
        let byID = Dictionary(uniqueKeysWithValues: model.items.map { ($0.id, $0) })
        XCTAssertEqual(byID[episode.id]?.badge, .episode(2, of: 5), "bölüm favoriden önce")
        XCTAssertEqual(byID[fav.id]?.badge, .favorite)
        if case .progress = byID[halfEpisode.id]?.badge {} else { XCTFail("yarım her şeyden önce") }
    }

    // MARK: Kapak

    func testTextStoryCoverIsItsOwnMosaicNotASharedImage() {
        let a = Self.story("A", mode: "bedtime"), b = Self.story("B", mode: "bedtime")
        guard case .mosaic(let ca) = LibraryShelfModel.coverArt(a),
              case .mosaic(let cb) = LibraryShelfModel.coverArt(b) else {
            return XCTFail("metin masalı mozaik kapak almalı")
        }
        XCTAssertNotEqual(ca.seed, cb.seed)
    }

    // MARK: Yardımcılar

    private static func model(_ stories: [Story], favorites: Set<UUID> = [],
                              classics: [(tale: ClassicTale, fraction: Double, openedAt: Date)] = []) -> LibraryShelfModel {
        LibraryShelfModel.build(stories: stories, isFavorite: { favorites.contains($0) },
                                classics: classics, art: { _ in .symbol("book", .lav) })
    }

    private static func story(_ title: String, mode: String, pages: Int = 2) -> Story {
        var story = ReaderFixtures.textStory(pages: pages, title: title)
        story.origin = StoryOrigin(
            seed: "s", storyIdeaID: nil, blueprintID: "b", settingID: "st",
            companionID: "c", discoveryID: "d", fingerprint: "f", catalogVersion: "v",
            worldID: "orman", modeID: mode, selectionStrategy: "direct", ageBand: "5-6"
        )
        return story
    }

    private static func classic(_ n: Int, _ title: String, fraction: Double = 1,
                                openedAt: TimeInterval = 0) -> (tale: ClassicTale, fraction: Double, openedAt: Date) {
        (ClassicsCatalogTests.tale(n, title), fraction, Date(timeIntervalSince1970: openedAt))
    }
}
