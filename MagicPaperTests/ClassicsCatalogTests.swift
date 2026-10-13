import XCTest
@testable import MagicPaper

/// FAZ 20 · Günlük: katalog sorguları, doğrulama ve günün masalı.
final class ClassicsCatalogTests: XCTestCase {

    // MARK: - Örnek katalog

    static let seriesID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!

    static func tale(
        _ n: Int, _ title: String, origin: ClassicOrigin = .grimm, shelves: [ClassicShelf] = [.klasikler],
        ages: ClosedRange<Int> = 5...7, minutes: Int = 8, classic: Bool = false,
        series: UUID? = nil, episode: Int? = nil, cover: String? = nil
    ) -> ClassicTale {
        ClassicTale(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", n))!,
            slug: "masal-\(n)", title: title, origin: origin, byline: "Grimm",
            ageMin: ages.lowerBound, ageMax: ages.upperBound, minutes: minutes,
            summary: "Özet", shelves: series == nil ? shelves : [],
            cover: cover ?? "kapak-\(n)", coverFocus: .center,
            attribution: "Grimm Kardeşler, 1812.", coverCredit: "Görsel: Johnny Gruelle, 1914. Kamu malı.",
            soft: ClassicText(pages: ["Bir varmış.", "Bir yokmuş."]),
            classic: classic ? ClassicText(pages: ["Bir.", "İki.", "Üç."]) : nil,
            seriesID: series, episode: episode)
    }

    static var file: ClassicsCatalogFile {
        let tales = [
            tale(1, "Rapunzel", classic: true),
            tale(2, "Kırmızı Başlıklı Kız", ages: 3...7, classic: true),
            tale(3, "Külkedisi", origin: .perrault),
            tale(4, "Tavşan ile Kaplumbağa", origin: .aesop, shelves: [.fabllar, .hayvanlar], ages: 3...6, minutes: 4),
            tale(5, "Üç Turunçlar", origin: .anadolu, shelves: [.anadolu], ages: 7...10),
            tale(6, "Keloğlan ile Dev Anası", origin: .anadolu, series: seriesID, episode: 1),
            tale(7, "Keloğlan ve Sihirli Değnek", origin: .anadolu, series: seriesID, episode: 2),
        ]
        let series = ClassicSeries(
            id: seriesID, slug: "keloglan", title: "Keloğlan Masalları", byline: "Anadolu",
            ageMin: 5, ageMax: 8, summary: "Saçı yok ama aklı çok.", shelves: [.anadolu],
            cover: "kapak-keloglan", coverFocus: .center, attribution: "Anadolu sözlü halk anlatısı.",
            coverCredit: "Görsel: MagicPaper.", bookTitle: "1. Kitap", unitName: "masal")
        return ClassicsCatalogFile(
            version: 1, tales: tales, series: [series],
            weeklyPicks: ClassicWeeklyPicks(weekOf: "2026-10-12", ids: [tales[1].id, seriesID, tales[0].id]),
            originals: [])
    }

    var catalog: ClassicsCatalog { ClassicsCatalog(file: Self.file) }

    // MARK: - Raflar

    func testStandaloneTalesLeaveOutEpisodes() {
        XCTAssertEqual(catalog.standaloneTales.map(\.title),
                       ["Rapunzel", "Kırmızı Başlıklı Kız", "Külkedisi", "Tavşan ile Kaplumbağa", "Üç Turunçlar"])
    }

    func testAnadoluShelfHoldsTalesAndSeries() {
        let titles = catalog.items(in: .anadolu).map(\.title)
        XCTAssertEqual(titles, ["Üç Turunçlar", "Keloğlan Masalları"])
    }

    func testSeriesShelfIsDerived() {
        XCTAssertEqual(catalog.items(in: .seriler).map(\.title), ["Keloğlan Masalları"])
        if case .series(_, let count) = catalog.items(in: .seriler)[0] {
            XCTAssertEqual(count, 2)
        } else { XCTFail("seri bekleniyordu") }
    }

    func testFiveMinuteShelfComesFromLength() {
        XCTAssertEqual(catalog.items(in: .besDakika).map(\.title), ["Tavşan ile Kaplumbağa"])
    }

    func testVoicedShelfIsEmptyUntilNarrationExists() {
        XCTAssertTrue(catalog.items(in: .sesli).isEmpty)
    }

    func testAgeFilterKeepsOnlyFittingItems() {
        XCTAssertEqual(catalog.items(in: .anadolu, age: 5).map(\.title), ["Keloğlan Masalları"])
        XCTAssertEqual(catalog.items(in: nil, age: 3).map(\.title), ["Kırmızı Başlıklı Kız", "Tavşan ile Kaplumbağa"])
    }

    func testSeriesMetaCountsEpisodes() {
        XCTAssertEqual(catalog.item(Self.seriesID)?.meta, "Anadolu · 2 masal")
        XCTAssertEqual(catalog.tale(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)?.fullMeta,
                       "Grimm · 8 dk · 5-7 yaş")
    }

    func testEpisodesAreInOrder() {
        XCTAssertEqual(catalog.episodes(of: Self.seriesID).compactMap(\.episode), [1, 2])
    }

    func testWeeklyPicksKeepEditorOrder() {
        XCTAssertEqual(catalog.weeklyPicks.map(\.title), ["Kırmızı Başlıklı Kız", "Keloğlan Masalları", "Rapunzel"])
    }

    func testSimilarPrefersSameOriginAndSkipsItself() {
        let rapunzel = catalog.standaloneTales[0]
        let similar = catalog.similar(to: rapunzel).map(\.title)
        XCTAssertFalse(similar.contains("Rapunzel"))
        XCTAssertEqual(similar.first, "Kırmızı Başlıklı Kız")
    }

    func testSearchIgnoresCaseAndTurkishMarks() {
        XCTAssertEqual(catalog.search("kulkedisi").map(\.title), ["Külkedisi"])
        XCTAssertEqual(catalog.search("RAPUNZEL").map(\.title), ["Rapunzel"])
        // Bölüm adı serinin kendisini bulur.
        XCTAssertEqual(catalog.search("değnek").map(\.title), ["Keloğlan Masalları"])
    }

    func testNarrationFallsBackToSoft() {
        let kulkedisi = catalog.standaloneTales[2]
        XCTAssertEqual(kulkedisi.text(.classic), kulkedisi.soft)
        let rapunzel = catalog.standaloneTales[0]
        XCTAssertEqual(rapunzel.text(.classic).pages.count, 3)
    }

    // MARK: - Günün masalı

    func testTodaysTaleIsDeterministic() {
        let a = catalog.todaysTale(day: "2026-10-13", age: 6, read: [], pinned: nil)
        let b = catalog.todaysTale(day: "2026-10-13", age: 6, read: [], pinned: nil)
        XCTAssertNotNil(a)
        XCTAssertEqual(a, b)
    }

    func testTodaysTaleFitsAgeAndIsNeverAnEpisode() {
        for offset in 0..<30 {
            let day = String(format: "2026-11-%02d", offset % 28 + 1)
            let tale = catalog.todaysTale(day: day, age: 9, read: [], pinned: nil)
            XCTAssertEqual(tale?.title, "Üç Turunçlar", day)
        }
        for offset in 1...28 {
            let tale = catalog.todaysTale(day: String(format: "2026-12-%02d", offset), age: 5, read: [], pinned: nil)
            XCTAssertFalse(tale?.isEpisode ?? true)
        }
    }

    func testTodaysTalePrefersUnread() {
        let fiveYearOld = catalog.standaloneTales.filter { $0.fits(age: 5) }
        let readAllButOne = Set(fiveYearOld.dropLast().map(\.id))
        let tale = catalog.todaysTale(day: "2026-10-13", age: 5, read: readAllButOne, pinned: nil)
        XCTAssertEqual(tale?.id, fiveYearOld.last?.id)
    }

    func testPinnedTaleStaysForTheDay() {
        let pinned = catalog.standaloneTales[2]
        let tale = catalog.todaysTale(day: "2026-10-13", age: 6, read: [pinned.id], pinned: pinned.id)
        XCTAssertEqual(tale, pinned)
    }

    func testTodaysTaleFallsBackWhenNothingFitsAge() {
        XCTAssertNotNil(catalog.todaysTale(day: "2026-10-13", age: 12, read: [], pinned: nil))
    }

    func testTodaysTaleSkipsTalesWaitingForACover() {
        let base = Self.file
        let pending = base.tales.filter { !$0.isEpisode && $0.title != "Külkedisi" }.map(\.cover)
        let file = ClassicsCatalogFile(version: 1, tales: base.tales, series: base.series,
                                       weeklyPicks: base.weeklyPicks, originals: [], pendingCovers: pending)
        for day in 1...20 {
            let tale = ClassicsCatalog(file: file).todaysTale(day: String(format: "2026-10-%02d", day),
                                                              age: 6, read: [], pinned: nil)
            XCTAssertEqual(tale?.title, "Külkedisi")
        }
    }

    func testFeaturedTaleIsTodaysTale() {
        let base = Self.file
        let rapunzel = base.tales[0]
        let file = ClassicsCatalogFile(version: 1, tales: base.tales, series: base.series,
                                       weeklyPicks: base.weeklyPicks, originals: [], featuredID: rapunzel.id)
        let tale = ClassicsCatalog(file: file).todaysTale(day: "2026-10-13", age: 9, read: [rapunzel.id], pinned: nil)
        XCTAssertEqual(tale, rapunzel)
    }

    func testDayOrdinalCountsDays() {
        XCTAssertEqual(ClassicsCatalog.dayOrdinal("1970-01-02"), 1)
        XCTAssertEqual(ClassicsCatalog.dayOrdinal("2026-10-14") - ClassicsCatalog.dayOrdinal("2026-10-13"), 1)
        XCTAssertEqual(ClassicsCatalog.dayOrdinal("bozuk"), 0)
    }

    // MARK: - Doğrulama

    func testValidCatalogHasNoIssues() {
        XCTAssertEqual(catalog.validate(assetExists: { _ in true }), [])
    }

    func testValidationFindsMissingCoversAndBrokenSeries() {
        var file = Self.file
        var tales = file.tales
        tales[0] = Self.tale(1, "Rapunzel", cover: "yok")
        tales[6] = Self.tale(7, "Keloğlan ve Sihirli Değnek", series: Self.seriesID, episode: 3)
        file = ClassicsCatalogFile(version: 1, tales: tales, series: file.series,
                                   weeklyPicks: ClassicWeeklyPicks(weekOf: "2026-10-12", ids: [UUID()]),
                                   originals: [])
        let problems = ClassicsCatalog(file: file).validate(assetExists: { $0 != "yok" }).map(\.problem)
        XCTAssertTrue(problems.contains("kapak yok: yok"))
        XCTAssertTrue(problems.contains("bölümler 1'den ardışık değil"))
        XCTAssertTrue(problems.contains { $0.hasPrefix("katalogda olmayan id") })
    }

    /// Pakete giren gerçek katalog: her kapak asset catalog'da, her masalın
    /// kaynak bilgisi ve sayfaları var.
    func testBundledCatalogIsValid() {
        let bundled = ClassicsCatalog.load(from: Bundle(for: ClassicProgressStore.self))
        XCTAssertFalse(bundled.tales.isEmpty, "classics_catalog.json pakette değil ya da okunamadı")
        let issues = bundled.validate(assetExists: { UIImage(named: $0) != nil })
        XCTAssertEqual(issues.map(\.description), [])
    }
}
