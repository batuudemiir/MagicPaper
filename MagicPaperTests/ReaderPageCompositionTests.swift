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
}
