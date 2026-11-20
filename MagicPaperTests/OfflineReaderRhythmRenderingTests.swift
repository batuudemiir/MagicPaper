import StoryEngine
import SwiftUI
import UIKit
import XCTest
@testable import MagicPaper

/// Real offline prose, paired with its legacy presentation. Fixed viewport
/// evidence in one simulator; callbacks are inert, not an end-to-end gesture test.
@MainActor
final class OfflineReaderRhythmRenderingTests: XCTestCase {
    private func reader(age: Int) throws -> ReaderStory {
        let service = OfflineStoryService.shared
        let draft = try service.compose(childName: "Deniz", ideaID: "idea_follow_the_traces_001",
                                        companionID: nil, age: age, seed: "offline-reader-rhythm-pilot")
        let story = OfflineStoryMapper.appStory(from: draft.story, childName: "Deniz",
            childProfileID: UUID(), storyIdeaID: "idea_follow_the_traces_001",
            catalogVersion: draft.catalogVersion, ageBand: service.servedBand(forAge: age))
        XCTAssertEqual(story.pages.map(\.text), draft.story.pages.sorted { $0.pageNumber < $1.pageNumber }.map(\.text))
        XCTAssertEqual(story.pages.count, draft.story.pages.count)
        return ReaderStory(from: story)
    }

    func testActualOlderBookBeforeAndAfterAtFourNarrativeMoments() async throws {
        let book = try reader(age: 8)
        XCTAssertEqual(book.textLayout, .paragraphs)
        let pages = book.leaves.compactMap(\.page)
        let selected = [0, pages.count / 2 - 1, pages.count / 2, pages.count - 1]
        try await withRenderWindow { scene in
            for index in selected {
                let page = pages[index]
                XCTAssertNotNil(page.reading)
                var legacy = page
                legacy.reading = nil
                XCTAssertEqual(legacy.spokenText, page.spokenText)
                let suffix = "older-p\(index + 1)"
                try await render(legacy, book: book, scene: scene, name: suffix + "-before")
                try await render(page, book: book, scene: scene, name: suffix + "-after")
            }
            let last = try XCTUnwrap(pages.last)
            try await render(last, book: book, paper: .night, scene: scene, name: "older-ending-night")
            try await render(last, book: book, size: CGSize(width: 375, height: 667),
                             type: .accessibility5, scene: scene, name: "older-ending-se-ax5")
        }
    }

    func testActualYoungerEndingPreservesBreathAndCompactFallback() async throws {
        let book = try reader(age: 6)
        XCTAssertEqual(book.textLayout, .breath)
        let page = try XCTUnwrap(book.leaves.compactMap(\.page).last)
        try await withRenderWindow { scene in
            var legacy = page
            legacy.reading = nil
            try await render(legacy, book: book, scene: scene, name: "younger-ending-before")
            try await render(page, book: book, scene: scene, name: "younger-ending-after")
            try await render(page, book: book, size: CGSize(width: 667, height: 375),
                             scene: scene, name: "younger-ending-compact")
        }
    }

    func testExistingReviewedSpotRemainsTheOnlyIllustrationOnItsBoundPage() async throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let blueprint = try XCTUnwrap(catalog.blueprints.first { $0.id.rawValue == "blueprint_absence_looking_001" })
        let composed = try OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog,
            intent: OfflineStoryIntent(childName: "Deniz", settingID: ContentID("setting_forest_001"),
                discoveryID: ContentID("object_torn_map_001"), seed: "story-art-audit-23"))
        let story = OfflineStoryMapper.appStory(from: composed, childName: "Deniz", childProfileID: UUID(),
            storyIdeaID: nil, catalogVersion: catalog.version, ageBand: blueprint.ageRange)
        let book = ReaderStory(from: story)
        let pages = book.leaves.compactMap(\.page)
        let first = try XCTUnwrap(pages.first)
        let art = try XCTUnwrap(first.art)
        XCTAssertEqual(first.composition, .spot)
        XCTAssertTrue(pages.dropFirst().allSatisfy { $0.art == nil && !$0.hasIllustration })
        let image = await ReaderImageLoader.shared.image(art: art, targetPixelWidth: 1200)
        XCTAssertNotNil(image)
        try await withRenderWindow { scene in
            try await render(first, book: book, scene: scene, name: "reviewed-map-opening")
        }
    }

    private func withRenderWindow(_ work: (UIWindowScene) async throws -> Void) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let oldWindow = scene.windows.first(where: \.isKeyWindow)
        let grain = MPSettingsStore.shared.paperGrain
        MPSettingsStore.shared.paperGrain = false
        defer { MPSettingsStore.shared.paperGrain = grain; oldWindow?.makeKey() }
        try await work(scene)
    }

    private func render(_ page: ReaderPage, book: ReaderStory, paper: MP.ReadTheme = .light,
                        size: CGSize = CGSize(width: 440, height: 956), type: DynamicTypeSize = .large,
                        scene: UIWindowScene, name: String) async throws {
        let view = ZStack {
            StoryPageView(page: page, theme: paper, readSize: .cokBuyuk, spacing: .rahat,
                          layout: book.textLayout, childName: book.childName,
                          folio: "\(page.index + 1) / \(book.pageCount)", showsFolio: false,
                          accent: book.accent, symbol: book.symbol)
            ReaderChrome(theme: paper, isFavorite: false, isSpeaking: false,
                         pageLabel: "Sayfa \(page.index + 1) / \(book.pageCount)",
                         progress: Double(page.index + 1) / Double(book.pageCount),
                         canGoPrevious: page.index > 0, canGoNext: true,
                         isLastPage: page.index == book.pageCount - 1,
                         onClose: {}, onToggleFavorite: {}, onToggleSpeech: {}, onOpenSettings: {},
                         pagePreviews: book.pagePreviews, pageIndex: page.index)
        }
        .environment(\.dynamicTypeSize, type)
        .environment(\.horizontalSizeClass, .compact)
        .environment(\.verticalSizeClass, size.width > size.height ? .compact : .regular)
        .environment(\.colorScheme, paper.isDark ? .dark : .light)
        let host = UIHostingController(rootView: view)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: size)
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        host.view.frame = window.bounds
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        try await Task.sleep(nanoseconds: 600_000_000)
        host.view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            host.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
        }
        let data = try XCTUnwrap(image.pngData())
        XCTAssertGreaterThan(data.count, 1_000)
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
        attachment.name = "offline-rhythm-" + name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
