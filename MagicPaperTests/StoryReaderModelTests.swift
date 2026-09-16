import XCTest
@testable import MagicPaper

/// Sayfa mantığının tamamı.
///
/// Hepsi düz birim testi olabiliyor çünkü `StoryReaderModel` içinde ne SwiftUI
/// ne UIKit var. Sayfa çevirmeyi UI testiyle doğrulamaya çalışmak, animasyonla
/// yarışan ve yanlış sebeplerle yeşile dönen testler üretirdi.
@MainActor
final class StoryReaderModelTests: XCTestCase {

    private func model(pages: Int = 8,
                       savedPage: Int? = nil,
                       store: ReaderProgressStore? = nil) -> StoryReaderModel {
        StoryReaderModel(
            story: ReaderFixtures.reader(ReaderFixtures.textStory(pages: pages)),
            savedPage: savedPage,
            progressStore: store ?? SpyProgressStore()
        )
    }

    // 1 — hiç okunmamış masal kapaktan açılır, kapağı çevirince 1. sayfa gelir
    func testOpensOnCoverThenFirstPage() {
        let m = model()
        XCTAssertTrue(m.currentLeaf.isCover, "kitap kapağından açılır")
        XCTAssertNil(m.currentPage)
        XCTAssertNil(m.folio, "kapak sayfa değildir, künyesi yoktur")

        m.next()
        XCTAssertEqual(m.currentPage?.index, 0)
        XCTAssertEqual(m.folio, "1 / 8", "künye kapaktan sonra 1'den başlar")
    }

    // 2 — yaprak sayısı masalla uyuşur: kapak + sayfalar + kapanış
    func testLeafCountMatchesStoryPlusCoverAndEnding() {
        XCTAssertEqual(model(pages: 8).leafCount, 10)
        XCTAssertEqual(model(pages: 1).leafCount, 3)
        XCTAssertEqual(model(pages: 8).story.pageCount, 8,
                       "kapak sayfa sayısına dâhil değildir")
        XCTAssertEqual(model(pages: 8).story.pageLeafOffset, 1)
    }

    // 3 — sonraki sayfa
    func testNextPage() {
        let m = model(savedPage: 0)
        XCTAssertTrue(m.next())
        XCTAssertEqual(m.currentPage?.index, 1)
        XCTAssertEqual(m.folio, "2 / 8")
    }

    // 4 — önceki sayfa
    func testPreviousPage() {
        let m = model(savedPage: 0)
        m.next()
        XCTAssertTrue(m.previous())
        XCTAssertEqual(m.currentPage?.index, 0)
    }

    // 5 — kapaktan geri gidilemez; 1. sayfadan geri kapağa dönülür
    func testFirstLeafBoundary() {
        let m = model()
        XCTAssertFalse(m.canGoPrevious)
        XCTAssertFalse(m.previous())
        XCTAssertEqual(m.leafIndex, 0)

        m.next()
        XCTAssertTrue(m.previous(), "1. sayfadan kapağa dönülebilir")
        XCTAssertTrue(m.currentLeaf.isCover)
    }

    // 6 — son yapraktan ileri gidilemez
    func testLastLeafBoundary() {
        let m = model(pages: 3)
        for _ in 0..<4 { m.next() }          // kapak, 0, 1, 2 → kapanış
        XCTAssertTrue(m.isOnEndingLeaf)
        XCTAssertFalse(m.canGoNext)
        XCTAssertFalse(m.next())
        XCTAssertEqual(m.leafIndex, 4)
    }

    // 7 — programlı gezinme, geçersiz indeksler dâhil
    func testProgrammaticNavigation() {
        let m = model()
        XCTAssertTrue(m.go(toLeaf: 5))
        XCTAssertEqual(m.currentPage?.index, 4, "5. yaprak, kapak kaydığı için 4. sayfa")

        XCTAssertFalse(m.go(toLeaf: -1), "negatif indeks reddedilmeli")
        XCTAssertFalse(m.go(toLeaf: 99), "aralık dışı indeks reddedilmeli")
        XCTAssertFalse(m.go(toLeaf: 5), "aynı yaprağa gitmek hareket değildir")
        XCTAssertEqual(m.currentPage?.index, 4, "reddedilen istekler konumu bozmamalı")
    }

    // 8 — geçerli sayfa durumu geri sayfalamada kaybolmaz
    func testFurthestPageIsMonotonic() {
        let m = model(savedPage: 0)
        for _ in 0..<5 { m.next() }
        XCTAssertEqual(m.furthestPageReached, 5)
        for _ in 0..<5 { m.previous() }
        XCTAssertEqual(m.currentPage?.index, 0)
        XCTAssertEqual(m.furthestPageReached, 5, "geri sayfalamak ilerlemeyi silmez")
    }

    // 12 — kapaktan gelen okuyucu ilk sayfada başlar
    func testCoverHandoffStartsAtFirstPage() {
        let m = StoryReaderModel(
            story: ReaderFixtures.reader(ReaderFixtures.textStory(pages: 8)),
            startingAt: nil, savedPage: nil, progressStore: SpyProgressStore()
        )
        XCTAssertEqual(m.leafIndex, 0)
    }

    // 17 — gezinme, geçiş biçiminden bağımsızdır
    func testNavigationIsIndependentOfTransitionStyle() {
        // Model geçiş biçimini hiç bilmez; "Hareketi Azalt" yalnızca
        // StoryReaderContainer'ın seçtiği transitionStyle'ı değiştirir.
        let m = model(pages: 4, savedPage: 0)
        m.next(); m.next()
        XCTAssertEqual(m.currentPage?.index, 2)
    }

    // 18 — hızlı ve tekrarlı gezinme
    func testRapidNavigationNeverGoesOutOfBounds() {
        let m = model(pages: 5)
        for i in 0..<200 {
            if i.isMultiple(of: 3) { m.previous() } else { m.next() }
            XCTAssertTrue((0..<m.leafCount).contains(m.leafIndex),
                          "yaprak indeksi her zaman geçerli aralıkta kalmalı")
        }
    }

    // Kontroller
    func testControlsStartVisibleAndToggle() {
        let m = model()
        XCTAssertTrue(m.controlsVisible)
        m.toggleControls()
        XCTAssertFalse(m.controlsVisible)
        m.toggleControls()
        XCTAssertTrue(m.controlsVisible)
    }

    // Kapanış
    func testReachingEndingMarksStoryFinished() {
        let m = model(pages: 3)
        XCTAssertFalse(m.hasReachedEnding)
        m.go(toLeaf: 4)
        XCTAssertTrue(m.hasReachedEnding)
        XCTAssertEqual(m.furthestPageReached, 2, "kapanış son sayfayı ilerleme sayar")
    }

    func testRestartReturnsToCover() {
        let m = model(pages: 3)
        m.go(toLeaf: 4)
        m.restart()
        XCTAssertEqual(m.leafIndex, 0)
        XCTAssertTrue(m.currentLeaf.isCover)
        XCTAssertTrue(m.hasReachedEnding, "bir kez bitmiş masal bitmiş kalır")
    }

    // Kapanış yaprağında folio gösterilmez
    func testEndingLeafHasNoFolio() {
        let m = model(pages: 2, savedPage: 0)
        XCTAssertNotNil(m.folio)
        m.go(toLeaf: 3)
        XCTAssertNil(m.folio)
    }
}
