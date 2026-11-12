import XCTest
@testable import MagicPaper

/// MagicPaper Original (spec 2026-11-12): akış masalının klasiğe çevrilmesi
/// ve Masallar rafları.
@MainActor
final class OriginalTalesTests: XCTestCase {

    private func library(_ originals: [FeedOriginal], today: String = "2026-11-20") -> ClassicsLibrary {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.date(from: today)!
        let suite = "OriginalTalesTests-\(UUID().uuidString)"
        return ClassicsLibrary(catalog: ClassicsCatalog(file: ClassicsCatalogTests.file),
                               defaults: UserDefaults(suiteName: suite)!, now: { date },
                               currentAge: { nil }, dailyStories: { [] }, remoteOriginals: { originals })
    }

    func testABedtimeOriginalSitsOnTheOriginalAndBedtimeShelves() {
        let tale = TestPublisher.original("fener", mode: "bedtime").classicTale
        XCTAssertEqual(tale.origin, .orijinal)
        XCTAssertEqual(tale.shelves, [.orijinal, .uyku])
        XCTAssertEqual(tale.shortMeta, "Original · 4 dk")
        XCTAssertEqual(tale.soft.pages, ["Bir.", "İki.", "Üç."])
        XCTAssertFalse(tale.creditLine.contains("uyarlaması"))
        XCTAssertEqual(TestPublisher.original("orman", mode: "adventure").classicTale.shelves, [.orijinal])
    }

    func testTheCoverNameCarriesSlugAndDigest() {
        let original = TestPublisher.original("fener")
        XCTAssertEqual(OriginalCovers.slug(in: original.classicTale.cover), "fener")
        XCTAssertNil(OriginalCovers.slug(in: "classic-rapunzel"))
    }

    func testTheOriginalShelfHoldsOnlyOriginalsNewestFirst() {
        let old = TestPublisher.original("eski", day: "2026-11-01")
        let new = TestPublisher.original("yeni", day: "2026-11-15")
        let titles = library([old, new]).items(in: .orijinal).map(\.id)
        XCTAssertEqual(titles, [new.id, old.id])
    }

    func testAnOriginalIsNotShownBeforeItsDay() {
        XCTAssertTrue(library([TestPublisher.original("yarin", day: "2026-11-21")]).items(in: .orijinal).isEmpty)
    }

    func testBedtimeOriginalsJoinTheBedtimeShelf() {
        let original = TestPublisher.original("fener", mode: "bedtime")
        XCTAssertTrue(library([original]).items(in: .uyku).contains { $0.id == original.id })
        XCTAssertFalse(library([original]).items(in: .klasikler).contains { $0.id == original.id })
    }

    func testAnOriginalOpensByID() {
        let original = TestPublisher.original("fener")
        XCTAssertEqual(library([original]).tale(original.id)?.title, "Fenerin Sesi")
    }

    func testTheBundledCatalogMayNotWriteTheOriginalShelf() {
        XCTAssertTrue(ClassicShelf.orijinal.isDerived)
        XCTAssertEqual(ClassicsCatalog(file: ClassicsCatalogTests.file).items(in: .orijinal), [])
    }

    // MARK: - Uygulamayla gelen Original'ler (13 Kasım 2026)

    func testBundledOriginalsFillTheOriginalShelfFromTheirOrigin() {
        var file = ClassicsCatalogTests.file
        let original = ClassicsCatalogTests.tale(90, "Saatin İçindeki Ninni", origin: .orijinal, shelves: [.uyku])
        file = catalogFile(adding: original, to: file)
        let catalog = ClassicsCatalog(file: file)

        XCTAssertEqual(catalog.items(in: .orijinal).map(\.id), [original.id])
        XCTAssertTrue(catalog.items(in: .uyku).contains { $0.id == original.id })
        XCTAssertFalse(catalog.items(in: .klasikler).contains { $0.id == original.id })
    }

    func testTheShippedCatalogCarriesTheFirstOriginal() {
        let titles = ClassicsCatalog.bundled.items(in: .orijinal).map(\.title)
        XCTAssertTrue(titles.contains("Saatin İçindeki Ninni"))
    }

    func testAnOriginalInBothCatalogAndFeedAppearsOnce() {
        let feed = TestPublisher.original("fener")
        var file = ClassicsCatalogTests.file
        file = catalogFile(adding: feed.classicTale, to: file)
        let suite = "OriginalTalesTests-\(UUID().uuidString)"
        let library = ClassicsLibrary(catalog: ClassicsCatalog(file: file), defaults: UserDefaults(suiteName: suite)!,
                                      currentAge: { nil }, dailyStories: { [] }, remoteOriginals: { [feed] })
        XCTAssertEqual(library.items(in: .orijinal).filter { $0.id == feed.id }.count, 1)
    }

    func testTheReaderRecognisesAnOriginalAndItsCover() {
        let original = TestPublisher.original("fener")
        OriginalIndex.update([original])
        defer { OriginalIndex.update([]) }
        XCTAssertTrue(ClassicsCatalog.contains(original.id))
        XCTAssertEqual(ClassicsCatalog.coverAsset(for: original.id), original.classicTale.cover)
    }
}

/// Örnek katalog dosyasına bir masal ekler.
private func catalogFile(adding tale: ClassicTale, to file: ClassicsCatalogFile) -> ClassicsCatalogFile {
    ClassicsCatalogFile(version: file.version, tales: file.tales + [tale], series: file.series,
                        weeklyPicks: file.weeklyPicks, originals: file.originals,
                        pendingCovers: file.pendingCovers, featuredID: file.featuredID)
}
