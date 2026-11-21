import XCTest
import UIKit
import SwiftUI
@testable import MagicPaper

@MainActor
final class OriginalPageIllustrationTests: XCTestCase {
    func testLegacyTextDecodesWithoutImages() throws {
        let text = try JSONDecoder().decode(ClassicText.self, from: Data(#"{"pages":["Bir.","İki."]}"#.utf8))
        XCTAssertNil(text.illustrations)
        XCTAssertNil(text.illustration(at: 0))
    }

    func testScenesAndTurkishAltTextReachTheReaderWithoutChangingText() {
        var tale = ClassicsCatalogTests.tale(91, "Sabit masal", origin: .orijinal)
        tale = replacingText(in: tale, with: ClassicText(pages: ["Bir.", "İki."], illustrations: [
            .init(asset: "first", altText: "Karlı istasyon."),
            .init(asset: "second", altText: "Saatin içindeki iki fare.")
        ]))
        let story = ClassicReading.story(for: tale, narration: .soft, childID: nil,
                                         childName: "Deneme", savedPage: 1)
        let reader = ReaderStory(from: story)
        let pages = reader.leaves.compactMap(\.page)
        XCTAssertEqual(story.pages.map(\.text), ["Bir.", "İki."])
        XCTAssertEqual(pages.map(\.imageRef), ["asset:first", "asset:second"])
        XCTAssertEqual(pages.map(\.imageLabel), ["Karlı istasyon.", "Saatin içindeki iki fare."])
        XCTAssertTrue(pages.allSatisfy { $0.composition == .scene })
        XCTAssertEqual(story.lastReadPage, 1)
        XCTAssertNil(story.origin)
    }

    func testIncompleteImageSequenceDoesNotAttachWrongSceneToText() {
        let text = ClassicText(pages: ["Bir.", "İki."], illustrations: [
            .init(asset: "wrong-page", altText: "Eksik sıra.")
        ])
        XCTAssertNil(text.illustration(at: 0))
        XCTAssertNil(text.illustration(at: 1))
        XCTAssertNil(text.illustration(at: -1))
        let blank = ClassicText(pages: ["Bir."], illustrations: [.init(asset: " ", altText: " ")])
        XCTAssertNil(blank.illustration(at: 0))
    }

    func testClassicNarrationDoesNotBorrowSoftNarrationImages() {
        let tale = replacingText(in: ClassicsCatalogTests.tale(92, "İki anlatım"),
                                 with: ClassicText(pages: ["Yumuşak."], illustrations: [
                                    .init(asset: "soft-only", altText: "Yumuşak anlatımın sahnesi.")
                                 ]), classic: ClassicText(pages: ["Klasik."]))
        let story = ClassicReading.story(for: tale, narration: .classic, childID: nil,
                                         childName: "Deneme", savedPage: nil)
        XCTAssertEqual(story.pages.map(\.text), ["Klasik."])
        XCTAssertNil(story.pages.first?.imageFileName)
    }

    func testEveryPublishedOriginalPageHasUniqueLoadableArt() async throws {
        let originals = ClassicsCatalog.bundled.file.tales.filter { $0.origin == .orijinal }
        XCTAssertEqual(Set(originals.map(\.slug)), ["saatin-icindeki-ninni", "kirmizi-atkidaki-kar-tanesi"])
        var assets = Set<String>()
        for tale in originals {
            let story = ClassicReading.story(for: tale, narration: .soft, childID: nil,
                                             childName: "Deneme", savedPage: nil)
            let reader = ReaderStory(from: story)
            XCTAssertEqual(reader.pageCount, 7)
            for (index, page) in reader.leaves.compactMap(\.page).enumerated() {
                let art = try XCTUnwrap(tale.soft.illustration(at: index))
                XCTAssertTrue(assets.insert(art.asset).inserted)
                XCTAssertEqual(page.imageLabel, art.altText)
                let ref = try XCTUnwrap(page.imageRef)
                let image = await ReaderImageLoader.shared.image(named: ref, targetPixelWidth: 240)
                let loaded = try XCTUnwrap(image, ref)
                XCTAssertLessThanOrEqual(max(loaded.size.width * loaded.scale, loaded.size.height * loaded.scale), 241)
            }
        }
        XCTAssertEqual(assets.count, 14)
        let missing = await ReaderImageLoader.shared.image(named: "asset:original-missing", targetPixelWidth: 240)
        XCTAssertNil(missing)
    }

    /// Actual reader renders in the installed simulator at fixed SE/Pro Max viewports.
    /// Attachments are visual evidence, not separate physical-device runs.
    func testOriginalScenesOnSmallLargeAndAccessibleReaderPages() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        defer { previous?.makeKey() }
        let originals = ClassicsCatalog.bundled.file.tales.filter { $0.origin == .orijinal }
        for tale in originals {
            let story = ClassicReading.story(for: tale, narration: .soft, childID: nil,
                                             childName: "", savedPage: nil)
            let pages = ReaderStory(from: story).leaves.compactMap(\.page)
            for page in pages {
                try await render(page, in: scene, size: CGSize(width: 440, height: 956),
                                 paper: .light, type: .large, name: "\(tale.slug)-\(page.index + 1)")
            }
            let page = try XCTUnwrap(pages.first)
            for size in [CGSize(width: 375, height: 667), CGSize(width: 440, height: 956)] {
                for paper in [MP.ReadTheme.light, .night] {
                    for type in [DynamicTypeSize.large, .accessibility5] {
                        try await render(page, in: scene, size: size, paper: paper, type: type,
                                         name: "\(tale.slug)-\(Int(size.width))-\(paper.rawValue)-\(type)")
                    }
                }
            }
        }
    }

    private func render(_ page: ReaderPage, in scene: UIWindowScene, size: CGSize,
                        paper: MP.ReadTheme, type: DynamicTypeSize, name: String) async throws {
        let view = StoryPageView(page: page, theme: paper, readSize: .normal, layout: .paragraphs,
                                 folio: "\(page.index + 1) / 7", showsFolio: true,
                                 accent: MP.C.brand, symbol: "book")
            .environment(\.dynamicTypeSize, type)
            .environment(\.horizontalSizeClass, .compact)
            .environment(\.verticalSizeClass, .regular)
            .environment(\.colorScheme, paper.isDark ? .dark : .light)
        let host = UIHostingController(rootView: view)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: size)
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        try await Task.sleep(nanoseconds: 700_000_000)
        host.view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            host.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
        }
        let data = try XCTUnwrap(image.pngData())
        XCTAssertGreaterThan(data.count, 1_000)
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
        attachment.name = "original-reader-" + name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func replacingText(in tale: ClassicTale, with text: ClassicText,
                               classic: ClassicText? = nil) -> ClassicTale {
        ClassicTale(id: tale.id, slug: tale.slug, title: tale.title, origin: tale.origin,
                    byline: tale.byline, ageMin: tale.ageMin, ageMax: tale.ageMax, minutes: tale.minutes,
                    summary: tale.summary, shelves: tale.shelves, cover: tale.cover,
                    coverFocus: tale.coverFocus, attribution: tale.attribution, coverCredit: tale.coverCredit,
                    soft: text, classic: classic, seriesID: tale.seriesID, episode: tale.episode)
    }
}
