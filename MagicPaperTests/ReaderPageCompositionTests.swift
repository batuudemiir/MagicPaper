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
        let usable = 760 - (MP.S.navBarHeight + MP.S.x6)
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

    func testInvalidSpotGeometryNeverReservesSpace() {
        XCTAssertEqual(ReaderPageLayout.spotSize(width: -1, height: 700, accessibility: false), .zero)
        XCTAssertEqual(ReaderPageLayout.spotSize(width: 393, height: -1, accessibility: false), .zero)
    }

    func testTwoRowChromeClearanceIncludesBothControlRows() {
        let normal = ReaderPageLayout.bottomChromeClearance(accessibility: false)
        XCTAssertGreaterThanOrEqual(normal, MP.S.tapMin + MPSize.minTouchHero)
        XCTAssertGreaterThan(ReaderPageLayout.bottomChromeClearance(accessibility: true), normal)
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
