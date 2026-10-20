import XCTest
@testable import MagicPaper

/// Okuma konumu: kaydedilmesi, geri gitmemesi, ve tek sayfalık masalın
/// bitebilmesi.
@MainActor
final class ReaderProgressTests: XCTestCase {

    // 14 — kayıtlı masal kaydedildiği sayfada açılır
    func testReopensAtSavedPage() {
        let m = StoryReaderModel(
            story: ReaderFixtures.reader(ReaderFixtures.textStory(pages: 8)),
            savedPage: 4,
            progressStore: SpyProgressStore()
        )
        XCTAssertEqual(m.currentPage?.index, 4)
        XCTAssertEqual(m.folio, "5 / 8")
    }

    /// Açıkça istenen sayfa, kayıtlı sayfayı geçersiz kılar.
    func testRequestedPageWinsOverSavedPage() {
        let m = StoryReaderModel(
            story: ReaderFixtures.reader(ReaderFixtures.textStory(pages: 8)),
            startingAt: 2, savedPage: 6,
            progressStore: SpyProgressStore()
        )
        XCTAssertEqual(m.currentPage?.index, 2)
    }

    // 20 — aralık dışı kayıtlı sayfa çökmez, kırpılır
    func testOutOfRangeSavedPageIsClamped() {
        let high = StoryReaderModel(
            story: ReaderFixtures.reader(ReaderFixtures.textStory(pages: 8)),
            savedPage: 99, progressStore: SpyProgressStore()
        )
        XCTAssertEqual(high.currentPage?.index, 7)

        let low = StoryReaderModel(
            story: ReaderFixtures.reader(ReaderFixtures.textStory(pages: 8)),
            savedPage: -5, progressStore: SpyProgressStore()
        )
        XCTAssertEqual(low.currentPage?.index, 0)
    }

    // 8 — ilerleme diske en ileri sayfayla yazılır, bulunulan sayfayla değil
    func testPersistsFurthestPageNotCurrentPage() {
        let spy = SpyProgressStore()
        let m = StoryReaderModel(
            story: ReaderFixtures.reader(ReaderFixtures.textStory(pages: 8)),
            savedPage: 0, progressStore: spy
        )
        for _ in 0..<5 { m.next() }
        for _ in 0..<5 { m.previous() }
        m.persistProgress()

        XCTAssertEqual(spy.lastWrittenPage, 5,
                       "geri sayfalayıp çıkmak ilerlemeyi 0'a düşürmemeli")
    }

    /// Aynı sayfa iki kez yazılmaz.
    ///
    /// Her yazma bütün `[Story]` dizisini yeniden JSON'a çeviriyor, o yüzden
    /// gereksiz yazma ucuz değil.
    func testRepeatedPersistWritesOnce() {
        let spy = SpyProgressStore()
        let m = StoryReaderModel(
            story: ReaderFixtures.reader(ReaderFixtures.textStory(pages: 8)),
            savedPage: 0, progressStore: spy
        )
        m.next()
        m.persistProgress()
        m.persistProgress()
        m.persistProgress()
        XCTAssertEqual(spy.writeCount, 1)
    }

    /// Hiç okunmamış bir masalın İLK sayfası da bir ilerlemedir.
    ///
    /// Bu, "okuma ilerlemesi diske yazılmıyor" şikâyetinin yarısıydı:
    /// `lastPersistedPage` açılış sayfasıyla (0) başlatılıyordu, dolayısıyla
    /// ilk sayfaya gelmek 0 == 0 karşılaştırmasına takılıp hiç yazılmıyordu.
    /// Bir masalı açıp ilk sayfasını okuyan çocuk, kütüphanede o masalı hiç
    /// açmamış gibi görünüyordu — ve ikinci sayfaya geçmeden kapatılan her
    /// masal için bu kalıcıydı.
    func testOpeningAFreshStoryRecordsItsFirstPage() {
        let spy = SpyProgressStore()
        let m = StoryReaderModel(
            story: ReaderFixtures.reader(ReaderFixtures.textStory(pages: 8)),
            progressStore: spy
        )
        m.next()                 // kapaktan ilk sayfaya
        m.persistProgress()
        XCTAssertEqual(spy.writeCount, 1, "ilk sayfa da yazılmalı")
        XCTAssertEqual(spy.lastWrittenPage, 0)
    }

    /// Ve bir kez yazıldıktan sonra aynı sayfa tekrar yazılmaz — üstteki
    /// düzeltme, gereksiz yazmayı önleyen kuralı bozmamalı.
    func testTheFirstPageIsStillOnlyWrittenOnce() {
        let spy = SpyProgressStore()
        let m = StoryReaderModel(
            story: ReaderFixtures.reader(ReaderFixtures.textStory(pages: 8)),
            progressStore: spy
        )
        m.next()
        m.persistProgress()
        m.persistProgress()
        XCTAssertEqual(spy.writeCount, 1)
    }

    func testNoWriteWhenNothingWasRead() {
        let spy = SpyProgressStore()
        let m = StoryReaderModel(
            story: ReaderFixtures.reader(ReaderFixtures.textStory(pages: 8)),
            savedPage: 3, progressStore: spy
        )
        m.persistProgress()
        XCTAssertEqual(spy.writeCount, 0, "açıp kapatmak yazma üretmemeli")
    }

    /// Kapanış yaprağı ilerleme değildir: son sayfadan büyük bir numara
    /// kaydedilmez.
    func testEndingLeafDoesNotPersistBeyondLastPage() {
        let spy = SpyProgressStore()
        let m = StoryReaderModel(
            story: ReaderFixtures.reader(ReaderFixtures.textStory(pages: 4)),
            savedPage: 0, progressStore: spy
        )
        m.go(toLeaf: 5)   // kapak + 4 sayfa → kapanış
        m.persistProgress()
        XCTAssertEqual(spy.lastWrittenPage, 3)
    }

    func testEmptyStoryNeverPersists() {
        let spy = SpyProgressStore()
        let m = StoryReaderModel(
            story: ReaderFixtures.reader(ReaderFixtures.textStory(pages: 0)),
            progressStore: spy
        )
        m.persistProgress()
        XCTAssertEqual(spy.writeCount, 0)
    }

    // MARK: - Tek sayfalık masal (D5)

    /// Tek sayfalık masal okunduğunda bitmiş sayılır.
    ///
    /// Önceki `mpProgress` biçimi `guard pages.count > 1` diyordu: tek sayfalık
    /// bir masal okunmuş olsa bile sonsuza kadar `0` dönüyor, kütüphanede hep
    /// "Oku" kalıyordu.
    func testSinglePageStoryCanBeCompleted() {
        var story = ReaderFixtures.textStory(pages: 1)
        XCTAssertEqual(story.mpProgress, 0, "hiç okunmamışken 0")
        XCTAssertFalse(story.isFinished)

        story.lastReadPage = 0
        XCTAssertEqual(story.mpProgress, 1, "tek sayfa okunduysa masal bitmiştir")
        XCTAssertTrue(story.isFinished)
    }

    func testMultiPageProgressUnchanged() {
        var story = ReaderFixtures.textStory(pages: 8)
        story.lastReadPage = 0
        XCTAssertEqual(story.mpProgress, 0)
        story.lastReadPage = 7
        XCTAssertEqual(story.mpProgress, 1)
        XCTAssertTrue(story.isFinished)
    }

    func testStoryWithNoPagesIsNeverFinished() {
        var story = ReaderFixtures.textStory(pages: 0)
        story.lastReadPage = 0
        XCTAssertEqual(story.mpProgress, 0)
        XCTAssertFalse(story.isFinished)
    }

    // 13 — okuyucudan kütüphaneye dönüş, model tarafı
    func testSinglePageStoryReachesEndingInOneTurn() {
        let m = StoryReaderModel(
            story: ReaderFixtures.reader(ReaderFixtures.textStory(pages: 1)),
            progressStore: SpyProgressStore()
        )
        XCTAssertTrue(m.currentLeaf.isCover)
        XCTAssertTrue(m.next())              // ithaf
        XCTAssertTrue(m.next())
        XCTAssertEqual(m.folio, "1 / 1")
        XCTAssertTrue(m.next())
        XCTAssertTrue(m.isOnEndingLeaf)
        XCTAssertTrue(m.hasReachedEnding)
    }
}
