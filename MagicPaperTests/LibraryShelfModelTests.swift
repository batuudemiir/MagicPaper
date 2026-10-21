import XCTest
@testable import MagicPaper

/// Kitaplığın içeriği (20 Ekim 2026): raflar, süzgeçler, sıralama, arama,
/// rozet önceliği ve Günlük klasikleri.
@MainActor
final class LibraryShelfModelTests: XCTestCase {

    // MARK: Zaman çizgisi (21 Ekim)

    private static let now = Date(timeIntervalSince1970: 1792573200) // 21 Ekim 2026 Çarşamba 12:00
    private static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        c.firstWeekday = 2
        return c
    }

    private static func daysAgo(_ n: Double) -> Date { now.addingTimeInterval(-n * 86_400) }

    func testSectionTitlesTodayYesterdayWeeksAndMonths() {
        let t = { (d: Date) in LibraryShelfModel.sectionTitle(for: d, now: Self.now, calendar: Self.calendar) }
        XCTAssertEqual(t(Self.now.addingTimeInterval(-60)), "Bugün")
        XCTAssertEqual(t(Self.daysAgo(1)), "Dün")
        XCTAssertEqual(t(Self.daysAgo(2)), "Bu hafta", "Pazartesi, aynı hafta")
        XCTAssertEqual(t(Self.daysAgo(5)), "Geçen hafta")
        XCTAssertEqual(t(Self.daysAgo(30)), "Eylül")
        XCTAssertEqual(t(Self.daysAgo(400)), "Eylül 2025")
    }

    func testEachBookAppearsOnceNewestFirstInSections() {
        var today = Self.story("Bugünkü", mode: "bedtime"); today.lastReadAt = Self.now.addingTimeInterval(-60)
        var yesterday = Self.story("Dünkü", mode: "adventure"); yesterday.createdAt = Self.daysAgo(1)
        var older = Self.story("Eski", mode: "bedtime"); older.createdAt = Self.daysAgo(30)
        let model = Self.model([older, yesterday, today], favorites: [today.id],
                               classics: [Self.classic(1, "Rapunzel", openedAt: Self.daysAgo(1).timeIntervalSince1970 - 60)])
        let sections = model.sections(for: .all, now: Self.now, calendar: Self.calendar)
        XCTAssertEqual(sections.map(\.title), ["Bugün", "Dün", "Eylül"])
        XCTAssertEqual(sections.flatMap(\.items).map(\.title), ["Bugünkü", "Dünkü", "Rapunzel", "Eski"])
        XCTAssertEqual(Set(sections.flatMap(\.items).map(\.id)).count, 4, "favori de olsa bir kez")
    }

    /// Okunan eski masal en üste çıkar: sıralama son okunmaya göre.
    func testReadingMovesABookToTheTop() {
        var old = Self.story("Eski ama dün okundu", mode: "bedtime")
        old.createdAt = Self.daysAgo(40); old.lastReadAt = Self.daysAgo(1)
        var new = Self.story("Yeni", mode: "bedtime"); new.createdAt = Self.daysAgo(3)
        let model = Self.model([new, old])
        XCTAssertEqual(model.items.map(\.title), ["Eski ama dün okundu", "Yeni"])
    }

    func testFilterAndSearchKeepSections() {
        var a = Self.story("Ay Dede", mode: "adventure"); a.lastReadAt = Self.now.addingTimeInterval(-60)
        var b = Self.story("Ay", mode: "bedtime"); b.lastReadAt = Self.now.addingTimeInterval(-120)
        let model = Self.model([a, b])
        let sections = model.sections(for: .mode(.adventure), query: "ay", now: Self.now, calendar: Self.calendar)
        XCTAssertEqual(sections.map(\.title), ["Bugün"])
        XCTAssertEqual(sections.first?.items.map(\.title), ["Ay Dede"])
        XCTAssertTrue(model.sections(for: .all, query: "zzz", now: Self.now, calendar: Self.calendar).isEmpty)
    }

    func testStoryWithoutModeIsUnderAllOnly() {
        let model = Self.model([ReaderFixtures.textStory(pages: 2)])
        XCTAssertEqual(model.items(for: .all).count, 1)
        XCTAssertEqual(model.availableFilters, [.all])
        XCTAssertEqual(model.items.first?.meta.hasPrefix("Masal ·"), true)
    }

    /// Eski "growth" kaydı Öğrenelim süzgecinde.
    func testLegacyGrowthStoryIsUnderLearning() {
        let model = Self.model([Self.story("Eski", mode: "growth")])
        XCTAssertEqual(model.items(for: .mode(.learning)).count, 1)
    }

    // MARK: Süzgeçler

    func testFiltersListOnlyNonEmptyCategoriesInFixedOrder() {
        let half = Self.story("Öğren", mode: "learning")
        let model = Self.model([half, Self.story("Ay", mode: "bedtime")], favorites: [half.id],
                               classics: [Self.classic(1, "Rapunzel")])
        XCTAssertEqual(model.availableFilters,
                       [.all, .favorites, .mode(.bedtime), .mode(.learning), .classics])
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
        XCTAssertEqual(model.continueItems().map(\.title), ["B"], "varsayılan: tek kart")
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
