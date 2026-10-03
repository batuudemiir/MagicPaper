import XCTest
@testable import MagicPaper

/// Kaldırılan bulut hattından kalan, hiç bitmeyecek masallar.
///
/// Karar: metni olan açılır (metin masalı olarak), metni olmayan rafta
/// gizlenir. Hiçbiri silinmez ve saklanan durum yeniden yazılmaz.
@MainActor
final class StalledStoryTests: XCTestCase {

    private func stalled(_ status: StoryStatus, texts: [String] = ["Bir varmış, bir yokmuş."]) -> Story {
        var s = ReaderFixtures.textStory(pages: 0)
        s.status = status
        s.pages = texts.map { StoryPage(title: "", text: $0, imagePrompt: "p",
                                        imageFileName: "x.jpg", imageUrl: "x.jpg") }
        s.coverImageUrl = "https://example.invalid/cover.jpg"
        return s
    }

    private func gate(_ stories: [Story], approval: Bool = false) -> [Story] {
        MPStoryGate.visible(stories, approvalRequired: approval, isApproved: { _ in true })
    }

    func testCompletedIsReadableAndNotTextOnly() {
        let s = ReaderFixtures.textStory(pages: 2)
        XCTAssertTrue(s.isReadable)
        XCTAssertFalse(s.opensAsTextOnly)
        XCTAssertEqual(gate([s]).count, 1)
    }

    func testStalledWithTextIsVisibleAndOpensAsTextOnly() {
        for status in [StoryStatus.uploading, .writingStory, .generatingImages, .failed] {
            let s = stalled(status)
            XCTAssertTrue(s.hasReadableText)
            XCTAssertTrue(s.isReadable)
            XCTAssertTrue(s.opensAsTextOnly)
            XCTAssertEqual(gate([s]).count, 1)
        }
    }

    func testStalledWithoutTextIsHiddenEvenWhenApprovalIsOff() {
        for texts in [[], [""], ["  \n\t "]] {
            for status in [StoryStatus.uploading, .writingStory] {
                let s = stalled(status, texts: texts)
                XCTAssertFalse(s.isReadable)
                XCTAssertTrue(gate([s], approval: false).isEmpty)
                XCTAssertTrue(gate([s], approval: true).isEmpty)
            }
        }
    }

    func testReadableStalledStoryFollowsTheApprovalGateLikeCompleted() {
        let s = stalled(.generatingImages)
        let hidden = MPStoryGate.visible([s], approvalRequired: true, isApproved: { _ in false })
        XCTAssertTrue(hidden.isEmpty)
        XCTAssertEqual(gate([s], approval: true).count, 1)
    }

    func testReaderGetsNoImagesAndStoryIsNotIllustrated() {
        let s = stalled(.generatingImages, texts: ["Bir.", "İki."])
        let reader = ReaderFixtures.reader(s)
        XCTAssertEqual(reader.pageCount, 2)
        for leaf in reader.leaves {
            guard let page = leaf.page else { continue }
            XCTAssertNil(page.imageRef)
            XCTAssertNil(page.scene)
            XCTAssertFalse(page.hasIllustration)
        }
        XCTAssertFalse(s.isIllustrated)
        XCTAssertEqual(s.mpCoverStyle, .magicPaperMosaic, "uzak kapak beklenmez")
        XCTAssertNotNil(reader.coverAsset ?? reader.mosaicCover.map { _ in "mosaic" })
    }

    func testCompletedIllustratedStoryIsUnchanged() {
        let s = ReaderFixtures.illustratedStory(pages: 2)
        XCTAssertTrue(s.isIllustrated)
        XCTAssertEqual(ReaderFixtures.reader(s).leaves[0].page?.imageRef, "page-0.jpg")
    }

    func testStalledStoryIsResumableWhenPartlyRead() {
        var s = stalled(.generatingImages, texts: ["Bir.", "İki.", "Üç."])
        s.lastReadPage = 0
        XCTAssertTrue(MPContinueReading.isResumable(s))
        var empty = stalled(.writingStory, texts: [" "])
        empty.lastReadPage = 0
        XCTAssertFalse(MPContinueReading.isResumable(empty))
    }

    func testPersistedStatusIsNotRewritten() throws {
        let s = stalled(.generatingImages)
        let data = try JSONEncoder().encode(s)
        let back = try JSONDecoder().decode(Story.self, from: data)
        XCTAssertEqual(back.status, .generatingImages)
        XCTAssertEqual(back.pages.count, 1)
        XCTAssertEqual(back.pages[0].imageUrl, "x.jpg", "kayıtlı sayfa verisi olduğu gibi kalır")
        XCTAssertEqual(back.coverImageUrl, s.coverImageUrl)
    }
}
