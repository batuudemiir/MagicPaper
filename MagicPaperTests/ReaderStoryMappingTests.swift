import XCTest
@testable import MagicPaper

/// `Story` → `ReaderStory`: okuyucunun gördüğü şeyin doğru şey olması.
@MainActor
final class ReaderStoryMappingTests: XCTestCase {

    func testLegacyPageJSONDecodesWithoutArtMetadata() throws {
        let json = """
        {"id":"00000000-0000-0000-0000-000000000001","title":"","text":"Metin.","imagePrompt":""}
        """
        let page = try JSONDecoder().decode(StoryPage.self, from: Data(json.utf8))
        XCTAssertNil(page.art)
    }

    func testArtMetadataRoundTripsAndUnknownRoleRemainsReadable() throws {
        var page = StoryPage(title: "", text: "Metin.", imagePrompt: "", imageFileName: "spot.png")
        page.art = StoryPageArt(role: "future-role", altText: "Bir filiz.", sourceID: "page-specific-art")
        let decoded = try JSONDecoder().decode(StoryPage.self, from: JSONEncoder().encode(page))
        XCTAssertEqual(decoded.art?.role, "future-role")
        XCTAssertEqual(decoded.art?.altText, "Bir filiz.")
        XCTAssertEqual(decoded.art?.sourceID, "page-specific-art")
        var story = ReaderFixtures.illustratedStory(pages: 1)
        story.pages = [decoded]
        XCTAssertEqual(ReaderStory(from: story).leaves.compactMap(\.page).first?.composition, .scene)
    }

    func testSpotRequiresArtAndSemanticMetadata() throws {
        var story = ReaderFixtures.illustratedStory(pages: 1)
        story.pages[0].art = StoryPageArt(role: "spot", altText: "Bir filiz.", sourceID: "page-specific-art")
        let reader = ReaderStory(from: story)
        let page = try XCTUnwrap(reader.leaves.compactMap(\.page).first)
        XCTAssertEqual(page.composition, .spot)
        XCTAssertEqual(page.imageLabel, "Bir filiz.")
        XCTAssertEqual(page.spokenText, "Sayfa 1.")
        XCTAssertEqual(reader.leafIndex(forPage: 0), 0)
        story.pages[0].imageFileName = ""
        story.pages[0].imageUrl = ""
        XCTAssertEqual(ReaderStory(from: story).leaves.compactMap(\.page).first?.composition, .text)
    }

    func testUnlabelledSpotKeepsLegacyScene() {
        var story = ReaderFixtures.illustratedStory(pages: 1)
        XCTAssertEqual(ReaderStory(from: story).leaves.compactMap(\.page).first?.composition, .scene)
        story.pages[0].art = StoryPageArt(role: "spot", altText: nil, sourceID: nil)
        XCTAssertEqual(ReaderStory(from: story).leaves.compactMap(\.page).first?.composition, .scene)
    }

    // 9 — yalnızca metin masalı
    func testTextOnlyStoryHasNoImages() {
        let reader = ReaderFixtures.reader(ReaderFixtures.textStory(pages: 8))
        XCTAssertEqual(reader.pageCount, 8)
        // Ortak "StoryCoverDefault" görseli kaldırıldı (Batuhan, 20 Ekim):
        // her metin masalı kendi mozaik kapağını taşır.
        XCTAssertNil(reader.coverAsset, "metin masalı ortak görseli almaz")
        XCTAssertNotNil(reader.mosaicCover, "metin masalı kendi mozaik kapağını alır")
        XCTAssertEqual(reader.leaves.first?.isCover, true, "mozaik kapak yaprağı kitabın başında")
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
    func testLegacyPageDecodesWithoutArtMetadata() throws {
        let page = StoryPage(title: "", text: "Metin.", imagePrompt: "")
        let decoded = try JSONDecoder().decode(StoryPage.self, from: JSONEncoder().encode(page))
        XCTAssertEqual(decoded.text, "Metin.")
        XCTAssertNil(decoded.art)
    }

    func testSpotMetadataSurvivesSavingAndMapping() throws {
        var story = ReaderFixtures.illustratedStory(pages: 1)
        story.pages[0].art = StoryPageArt(role: "spot", altText: "Küçük bir sulama kabı.", sourceID: "watering-v1")
        let decoded = try JSONDecoder().decode(StoryPage.self, from: JSONEncoder().encode(story.pages[0]))
        XCTAssertEqual(decoded.art?.sourceID, "watering-v1")
        XCTAssertEqual(decoded.art?.role, "spot")
        story.pages[0] = decoded
        let page = try XCTUnwrap(ReaderFixtures.reader(story).leaves.first?.page)
        XCTAssertEqual(page.composition, .spot)
        XCTAssertEqual(page.imageLabel, "Küçük bir sulama kabı.")
    }

    func testUnknownFutureArtRoleKeepsLegacyScene() throws {
        var story = ReaderFixtures.illustratedStory(pages: 1)
        story.pages[0].art = StoryPageArt(role: "future-layout", altText: "Çizim.", sourceID: nil)
        let data = try JSONEncoder().encode(story.pages[0])
        story.pages[0] = try JSONDecoder().decode(StoryPage.self, from: data)
        XCTAssertEqual(ReaderFixtures.reader(story).leaves.first?.page?.composition, .scene)
    }

    func testSpotWithoutFileOrDescriptionCannotInventArt() {
        var story = ReaderFixtures.textStory(pages: 1)
        story.pages[0].art = StoryPageArt(role: "spot", altText: "Çizim.", sourceID: "test")
        XCTAssertEqual(ReaderFixtures.reader(story).leaves.compactMap(\.page).first?.composition, .text)
        XCTAssertNil(ReaderFixtures.reader(story).leaves.compactMap(\.page).first?.imageLabel)
        story.pages[0].imageFileName = "a.png"
        story.pages[0].art = StoryPageArt(role: "spot", altText: "   ", sourceID: "test")
        XCTAssertEqual(ReaderFixtures.reader(story).leaves.compactMap(\.page).first?.composition, .scene)
    }

    func testResolvedSceneTakesPrecedenceOverSpotMetadata() throws {
        var story = ReaderFixtures.illustratedStory(pages: 1)
        story.illustration = StoryIllustration(
            avatar: AvatarSpec(skinTone: "skin_olive", hairStyle: "hair_short", hairColor: "haircolor_brown", outfit: "outfit_blue"),
            avatarKitVersion: "1.0.0", avatarArtVersion: 1, sceneLibraryVersion: "1.0.0")
        story.pages[0].scene = ScenePlate(sceneID: "scene_forest_hook_01", sceneVersion: 1,
                                         pose: "standing", facing: "right", companionID: nil)
        story.pages[0].art = StoryPageArt(role: "spot", altText: "Küçük resim.", sourceID: "spot-v1")
        let page = try XCTUnwrap(ReaderFixtures.reader(story).leaves.compactMap(\.page).first)
        XCTAssertNotNil(page.scene)
        XCTAssertEqual(page.composition, .scene)
        XCTAssertEqual(page.imageLabel, page.scene?.altText)
        XCTAssertEqual(page.spokenText, story.pages[0].text)
    }

    func testUnfinishedStorySuppressesArtWithoutLosingWordsOrText() throws {
        var story = ReaderFixtures.illustratedStory(pages: 1)
        story.status = .generatingImages
        story.pages[0].art = StoryPageArt(role: "spot", altText: "Küçük resim.", sourceID: "spot-v1")
        let word = StoryWord(id: "test", term: "Sayfa", meaning: "Kitabın bir yüzü.", surface: "Sayfa")
        story.pages[0].words = [word]
        let page = try XCTUnwrap(ReaderFixtures.reader(story).leaves.compactMap(\.page).first)
        XCTAssertEqual(page.composition, .text)
        XCTAssertNil(page.scene)
        XCTAssertNil(page.imageRef)
        XCTAssertNil(page.imageLabel)
        XCTAssertNil(page.art)
        XCTAssertEqual(page.words, [word])
        XCTAssertEqual(page.spokenText, story.pages[0].text)
    }

    func testMalformedArtMetadataCannotMakeThePageUnreadable() throws {
        let page = StoryPage(title: "", text: "Metin korunur.", imagePrompt: "", imageFileName: "a.png")
        let data = try JSONEncoder().encode(page)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["art"] = ["role": 42, "altText": ["unexpected": true]]
        let decoded = try JSONDecoder().decode(StoryPage.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(decoded.text, page.text)
        XCTAssertEqual(decoded.imageFileName, "a.png")
        XCTAssertFalse(decoded.art?.isSpot ?? true)
        XCTAssertNil(decoded.art?.description)
    }

    func testSavedBundledSpotDoesNotNeedALegacyImageFileName() throws {
        var story = ReaderFixtures.illustratedStory(pages: 1)
        story.pages[0].imageFileName = nil
        story.pages[0].imageUrl = nil
        story.pages[0].art = bundledSpot()
        let page = try XCTUnwrap(ReaderStory(from: story).leaves.compactMap(\.page).first)
        XCTAssertNil(page.imageRef)
        XCTAssertTrue(page.hasIllustration)
        XCTAssertEqual(page.composition, .spot)
        XCTAssertEqual(page.imageLabel, "Altın anahtar.")
        XCTAssertEqual(page.spokenText, "Sayfa 1.")
        story.status = .generatingImages
        let opening = try XCTUnwrap(ReaderStory(from: story).leaves.compactMap(\.page).first)
        XCTAssertEqual(opening.composition, .text)
        XCTAssertNil(opening.art)
        XCTAssertNil(opening.imageLabel)
    }

    func testUnknownBundledSpotSchemaCannotReserveAnArtPanel() throws {
        var story = ReaderFixtures.illustratedStory(pages: 1)
        story.pages[0].imageFileName = nil
        story.pages[0].imageUrl = nil
        story.pages[0].art = bundledSpot(schema: 9)
        let page = try XCTUnwrap(ReaderStory(from: story).leaves.compactMap(\.page).first)
        XCTAssertFalse(page.hasIllustration)
        XCTAssertEqual(page.composition, .text)
        XCTAssertNil(page.imageLabel)
    }

    func testInvalidBundleMetadataCannotFallBackToLegacyImage() throws {
        let cases: [[String: Any]] = [["schemaVersion": 9], ["schemaVersion": "invalid", "bundledFileName": 42]]
        for fields in cases {
            var json = fields
            json["role"] = "spot"
            json["altText"] = "Geçersiz yeni çizim."
            let art = try JSONDecoder().decode(StoryPageArt.self, from: JSONSerialization.data(withJSONObject: json))
            var story = ReaderFixtures.illustratedStory(pages: 1)
            story.pages[0].art = art
            let page = try XCTUnwrap(ReaderStory(from: story).leaves.compactMap(\.page).first)
            XCTAssertEqual(page.composition, .text)
            XCTAssertNil(page.imageRef)
            XCTAssertNil(page.imageLabel)
        }
    }

    private func bundledSpot(schema: Int = 1) -> StoryPageArt {
        StoryPageArt(role: "spot", altText: "Altın anahtar.", sourceID: "spot.golden-key",
                     schemaVersion: schema, assetRevision: 1,
                     assetDigest: String(repeating: "a", count: 64), styleRevision: "gouache-social-v1",
                     bundledFileName: "mp-story-spot-golden-key-r1.png", subjectID: "object_key_001",
                     subjectState: ["gold", "intact"], variantIDs: ["na_neutral_01"],
                     authoredSourceFingerprint: "test-source", bindingPolicyVersion: 1, catalogVersion: "test")
    }

}
