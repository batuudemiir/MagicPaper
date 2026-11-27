import XCTest
@testable import MagicPaper

final class ReaderPageCompositionTests: XCTestCase {
    func testSceneLeavesMoreRoomForLargeText() {
        let regular = ReaderPageLayout.sceneHeight(width: 393, height: 760, readPoints: 19, accessibility: false)
        let large = ReaderPageLayout.sceneHeight(width: 393, height: 760, readPoints: 26, accessibility: false)
        let accessible = ReaderPageLayout.sceneHeight(width: 393, height: 760, readPoints: 26, accessibility: true)
        XCTAssertLessThan(large, regular)
        XCTAssertLessThan(accessible, large)
        XCTAssertLessThanOrEqual(regular, 760 * 0.4)
    }

    func testCompactLandscapeCannotBeMostlyArtwork() {
        let height = ReaderPageLayout.sceneHeight(width: 760, height: 300, readPoints: 19, accessibility: false)
        XCTAssertLessThanOrEqual(height, 300 * 0.26)
    }

    func testSpotIsOmittedWhenTextNeedsTheViewport() {
        XCTAssertEqual(ReaderPageLayout.spotSize(width: 320, height: 300, accessibility: true).height, 0)
        XCTAssertEqual(ReaderPageLayout.spotSize(width: 320, height: 180, accessibility: false).height, 0)
    }

    func testPortraitSpotUsesPageHeightWhileProtectingTextBudget() {
        let usable = 760 - ReaderPageLayout.topChromeClearance
            - ReaderPageLayout.bottomChromeClearance(accessibility: false)
        let size = ReaderPageLayout.spotHeaderSize(width: 393, pageHeight: 760,
                                                    contentHeight: usable, accessibility: false)
        XCTAssertEqual(size.height, min(760 * 0.28, usable * 0.45), accuracy: 0.01)
        XCTAssertGreaterThan(size.height, 160)
        XCTAssertGreaterThan(size.width, 240)
        XCTAssertLessThanOrEqual(size.width, 393)
    }

    func testSpotReducesInLandscapeAndDisappearsWhenTight() {
        let landscape = ReaderPageLayout.spotSize(width: 760, height: 360, accessibility: false)
        XCTAssertLessThanOrEqual(landscape.height, 360 * 0.20)
        XCTAssertEqual(ReaderPageLayout.spotSize(width: 760, height: 300, accessibility: false), .zero)
    }

    func testScrollingSpotRemainsVisibleWithAccessibilityAndCompactChrome() {
        for (width, height, accessibility, compact) in [
            (CGFloat(320), CGFloat(568), true, false),
            (CGFloat(760), CGFloat(300), false, true),
            (CGFloat(760), CGFloat(300), true, true)
        ] {
            let size = ReaderPageLayout.scrollingSpotSize(width: width, pageHeight: height)
            XCTAssertGreaterThan(size.width, 0)
            XCTAssertGreaterThan(size.height, 0)
            XCTAssertLessThanOrEqual(size.width, width)
            let viewport = height - ReaderPageLayout.topChromeClearance
                - ReaderPageLayout.bottomChromeClearance(accessibility: accessibility, compactHeight: compact)
            let remainder = ReaderPageLayout.spotNarrativeMinimumHeight(viewportHeight: viewport,
                                                                       artHeight: size.height)
            XCTAssertGreaterThanOrEqual(remainder, 0)
            if viewport >= size.height + MP.S.x6 {
                XCTAssertEqual(size.height + MP.S.x6 + remainder, viewport, accuracy: 0.01)
            }
        }
        XCTAssertEqual(ReaderPageLayout.spotNarrativeMinimumHeight(viewportHeight: 10, artHeight: 80), 0)
        XCTAssertEqual(ReaderPageLayout.scrollingSpotSize(width: 0, pageHeight: 300), .zero)
    }

    func testInvalidSpotGeometryNeverReservesSpace() {
        XCTAssertEqual(ReaderPageLayout.spotSize(width: -1, height: 700, accessibility: false), .zero)
        XCTAssertEqual(ReaderPageLayout.spotSize(width: 393, height: -1, accessibility: false), .zero)
    }

    func testCompactChromeIsOneRowAndAccessibilityKeepsTwo() {
        let normal = ReaderPageLayout.bottomChromeClearance(accessibility: false)
        XCTAssertGreaterThanOrEqual(normal, MPSize.minTouchHero)
        XCTAssertLessThan(normal, MP.S.tapMin + MPSize.minTouchHero, "olağan yazıda tek satır")
        XCTAssertGreaterThanOrEqual(ReaderPageLayout.bottomChromeClearance(accessibility: true),
                                    MP.S.tapMin + MPSize.minTouchHero)
    }

    func testTextStartsBelowCloseButtonEvenWithoutPageSafeArea() {
        XCTAssertGreaterThan(ReaderPageLayout.topChromeClearance, MP.S.tapMin)
        // Yaprak güvenli alanı aldıysa eksik yok; almadıysa okuyucununki eklenir.
        XCTAssertEqual(ReaderPageLayout.missingTopInset(readerSafeTop: 59, pageTop: 59), 0)
        XCTAssertEqual(ReaderPageLayout.missingTopInset(readerSafeTop: 59, pageTop: 0), 59)
        XCTAssertEqual(ReaderPageLayout.missingTopInset(readerSafeTop: 0, pageTop: 20), 0)
    }
    func testSeekThumbTracksFirstAndLastPageRatherThanCompletionFraction() {
        XCTAssertEqual(ReaderPageLayout.seekFraction(page: 0, count: 8), 0)
        XCTAssertEqual(ReaderPageLayout.seekFraction(page: 7, count: 8), 1)
        XCTAssertEqual(ReaderPageLayout.seekFraction(page: 1, count: 3), 0.5)
        XCTAssertEqual(ReaderPageLayout.seekFraction(page: -1, count: 8), 0)
        XCTAssertEqual(ReaderPageLayout.seekFraction(page: 9, count: 8), 1)
        XCTAssertEqual(ReaderPageLayout.seekFraction(page: 0, count: 1), 0)
        XCTAssertEqual(ReaderPageLayout.seekFraction(page: 0, count: 0), 0)
    }

    func testAccessibilityChromeLeavesAReadableLineInCompactLandscape() {
        let portrait = ReaderPageLayout.bottomChromeClearance(accessibility: true)
        let compact = ReaderPageLayout.bottomChromeClearance(accessibility: true, compactHeight: true)
        XCTAssertLessThan(compact, portrait)
        XCTAssertGreaterThanOrEqual(375 - 21 - 80 - compact, 96)
    }

}
