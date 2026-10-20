import XCTest
@testable import MagicPaper

/// `Story` → `ReaderStory`: okuyucunun gördüğü şeyin doğru şey olması.
@MainActor
final class ReaderStoryMappingTests: XCTestCase {

    // 9 — yalnızca metin masalı
    func testTextOnlyStoryHasNoImages() {
        let reader = ReaderFixtures.reader(ReaderFixtures.textStory(pages: 8))
        XCTAssertEqual(reader.pageCount, 8)
        // Ortak "StoryCoverDefault" görseli kaldırıldı (Batuhan, 20 Ekim):
        // her metin masalı kendi mozaik kapağını taşır.
        XCTAssertNil(reader.coverAsset, "metin masalı ortak görseli almaz")
        XCTAssertNotNil(reader.mosaicCover, "metin masalı kendi mozaik kapağını alır")
        XCTAssertEqual(reader.pageLeafOffset, 1, "mozaik kapak yaprağı kitabın başında")
        for leaf in reader.leaves {
            guard let page = leaf.page else { continue }
            XCTAssertNil(page.imageRef, "metin masalında görsel olmamalı")
            XCTAssertNil(page.imageLabel, "görsel yokken erişilebilirlik etiketi de olmamalı")
        }
    }

    func testTwoTextStoriesGetDifferentCovers() {
        let a = ReaderFixtures.reader(ReaderFixtures.textStory(pages: 2))
        let b = ReaderFixtures.reader(ReaderFixtures.textStory(pages: 2))
        XCTAssertNotEqual(a.mosaicCover?.seed, b.mosaicCover?.seed, "her masalın kapağı kendine")
    }

    // 10 — çizimli masal; dosya adı URL'den önce gelir
    func testIllustratedStoryPrefersFileNameOverUrl() {
        let story = ReaderFixtures.illustratedStory(pages: 3)
        let reader = ReaderFixtures.reader(story)
        // Görselli masalın kendi kapağı vardır, kapak yaprağı eklenmez.
        XCTAssertNil(reader.coverAsset)
        XCTAssertEqual(reader.leaves[0].page?.imageRef, "page-0.jpg")
        XCTAssertNotNil(reader.leaves[0].page?.imageLabel)
    }

    func testImageRefFallsBackToUrlWhenFileNameMissing() {
        let page = StoryPage(title: "", text: "t", imagePrompt: "p",
                             imageFileName: nil, imageUrl: "uzak.jpg")
        XCTAssertEqual(ReaderStory.imageRef(for: page), "uzak.jpg")
    }

    func testEmptyImageStringsCountAsNoImage() {
        let page = StoryPage(title: "", text: "t", imagePrompt: "p",
                             imageFileName: "", imageUrl: "")
        XCTAssertNil(ReaderStory.imageRef(for: page))
    }

    // 11 — bazı sayfası görselli, bazısı değil
    func testMixedStoryKeepsEachPageIndependent() {
        let reader = ReaderFixtures.reader(ReaderFixtures.mixedStory())
        XCTAssertEqual(reader.pageCount, 3)
        XCTAssertEqual(reader.leaves[0].page?.imageRef, "a.jpg")
        XCTAssertNil(reader.leaves[1].page?.imageRef)
        XCTAssertNil(reader.leaves[2].page?.imageRef, "boş dosya adı görsel değildir")
    }

    /// `imagePrompt` erişilebilirlik etiketi olarak kullanılmaz.
    ///
    /// Alan motorun `visualScene`'ini taşıyor ve İngilizce yazılmış sahne
    /// yönergesi. Alt metin gibi görünüyor; VoiceOver'a verilseydi Türkçe bir
    /// masalın ortasında İngilizce okunurdu.
    func testImagePromptIsNeverUsedAsAccessibilityLabel() {
        let story = ReaderFixtures.illustratedStory(pages: 1)
        let reader = ReaderFixtures.reader(story)
        let label = reader.leaves[0].page?.imageLabel
        XCTAssertNotNil(label)
        XCTAssertFalse(label!.contains("a scene"), "etiket imagePrompt'tan gelmemeli")
        XCTAssertTrue(label!.contains("Çizimli Masal"))
    }

    // Paragraflar
    func testParagraphsSplitOnBlankLines() {
        let p = ReaderStory.paragraphs(of: "Birinci paragraf.\n\n“İkinci.” dedi.\n\n\nÜçüncü.")
        XCTAssertEqual(p.count, 3)
        XCTAssertEqual(p[1], "“İkinci.” dedi.")
    }

    func testParagraphsJoinSoftWrappedLines() {
        let p = ReaderStory.paragraphs(of: "Tek paragrafın\nikinci satırı.")
        XCTAssertEqual(p, ["Tek paragrafın ikinci satırı."])
    }

    func testEmptyTextProducesNoParagraphs() {
        XCTAssertTrue(ReaderStory.paragraphs(of: "").isEmpty)
        XCTAssertTrue(ReaderStory.paragraphs(of: "\n\n  \n").isEmpty)
    }

    // 20 — geçersiz masal verisi
    func testStoryWithNoPagesYieldsOnlyTheEndingLeaf() {
        let story = ReaderFixtures.textStory(pages: 0)
        let reader = ReaderFixtures.reader(story)
        XCTAssertEqual(reader.pageCount, 0)
        XCTAssertEqual(reader.leaves.count, 2, "kapak ve kapanış")
        XCTAssertTrue(reader.leaves[0].isCover)
        XCTAssertTrue(reader.leaves[1].isEnding)
        XCTAssertTrue(reader.isEmpty)
    }

    func testEmptyStoryOpensOnEndingWithoutCrashing() {
        let m = StoryReaderModel(
            story: ReaderFixtures.reader(ReaderFixtures.textStory(pages: 0)),
            progressStore: SpyProgressStore()
        )
        XCTAssertTrue(m.currentLeaf.isCover)
        XCTAssertNil(m.folio)
        XCTAssertTrue(m.next(), "kapaktan kapanışa geçilebilir")
        XCTAssertTrue(m.isOnEndingLeaf)
        XCTAssertFalse(m.next())
    }

    func testPageWithEmptyTextStillRenders() {
        var story = ReaderFixtures.textStory(pages: 1)
        story.pages[0].text = ""
        let reader = ReaderFixtures.reader(story)
        XCTAssertEqual(reader.pageCount, 1)
        let first = reader.leaves.compactMap(\.page)[0]
        XCTAssertTrue(first.paragraphs.isEmpty)
        XCTAssertTrue(first.isBlank)
    }

    /// Çevrimdışı motor sayfa başlığı yazmaz; düzen boş başlığa yer ayırmamalı.
    func testOfflineStoriesCarryEmptyPageTitles() {
        let reader = ReaderFixtures.reader(ReaderFixtures.textStory(pages: 3))
        XCTAssertTrue(reader.leaves.compactMap(\.page).allSatisfy { $0.title.isEmpty })
    }
}
