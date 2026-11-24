import XCTest
@testable import MagicPaper

/// Masal sonunun kazanılanları (24 Kasım 2026): okuma süresi çocuğa gösterilmez.
final class StoryEndingEarnedTests: XCTestCase {

    func testAFirstFinishEarnsStickerBadgeStarAndWordsButNeverMinutes() {
        XCTAssertEqual(StoryEndingEarned.ids(isFinished: false, hasBadge: true, newWords: 3),
                       ["sticker", "badge", "star", "words"])
    }

    func testARereadEarnsNoStickerAndNoStar() {
        XCTAssertEqual(StoryEndingEarned.ids(isFinished: true, hasBadge: false, newWords: 0), [])
    }

    func testARereadStillShowsANewBadgeAndNewWords() {
        XCTAssertEqual(StoryEndingEarned.ids(isFinished: true, hasBadge: true, newWords: 2), ["badge", "words"])
    }
}
