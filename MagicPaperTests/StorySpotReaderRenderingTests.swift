import StoryEngine
import SwiftUI
import UIKit
import XCTest
@testable import MagicPaper

/// Real SwiftUI page/chrome/settings evidence. Fixed viewport sizes are rendered
/// inside the installed simulator, not presented as separate physical devices.
@MainActor
final class StorySpotReaderRenderingTests: XCTestCase {
    private func pageFixture() async throws -> ReaderPage {
        let catalog = try ContentCatalogLoader().load().catalog
        let blueprint = try XCTUnwrap(catalog.blueprints.first { $0.id.rawValue == "blueprint_absence_looking_001" })
        let composed = try OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog,
            intent: OfflineStoryIntent(childName: "Deniz", settingID: ContentID("setting_forest_001"),
                discoveryID: ContentID("object_torn_map_001"), seed: "story-art-audit-23"))
        let story = OfflineStoryMapper.appStory(from: composed, childName: "Deniz", childProfileID: UUID(),
            storyIdeaID: nil, catalogVersion: catalog.version, ageBand: blueprint.ageRange)
        let reader = ReaderStory(from: story)
        XCTAssertEqual(reader.textLayout, .breath)
        let page = try XCTUnwrap(reader.leaves.compactMap(\.page).first)
        XCTAssertEqual(page.composition, .spot)
        let art = try XCTUnwrap(page.art)
        let image = await ReaderImageLoader.shared.image(art: art, targetPixelWidth: 1200)
        XCTAssertNotNil(image)
        return page
    }

    func testReviewedSpotPageOnPapersAndAdaptiveViewports() async throws {
        let page = try await pageFixture()
        let scene = try windowScene()
        let oldWindow = scene.windows.first(where: \.isKeyWindow)
        let grain = MPSettingsStore.shared.paperGrain
        MPSettingsStore.shared.paperGrain = false
        defer { oldWindow?.makeKey(); MPSettingsStore.shared.paperGrain = grain }
        for paper in MP.ReadTheme.allCases {
            try await render(reader(page, paper: paper), paper: paper, size: CGSize(width: 375, height: 667),
                             type: .large, regular: false, scene: scene, name: "se-" + paper.rawValue)
        }
        try await render(reader(page, paper: .light), paper: .light, size: CGSize(width: 440, height: 956),
                         type: .large, regular: false, scene: scene, name: "pro-max-day")
        try await render(reader(page, paper: .night), paper: .night, size: CGSize(width: 440, height: 956),
                         type: .large, regular: false, scene: scene, name: "pro-max-night")
        try await render(reader(page, paper: .light), paper: .light, size: CGSize(width: 375, height: 667),
                         type: .accessibility5, regular: false, scene: scene, name: "se-ax5-text-priority")
        try await render(reader(page, paper: .light), paper: .light, size: CGSize(width: 667, height: 375),
                         type: .accessibility5, regular: false, scene: scene, name: "se-landscape-ax5")
        try await render(reader(page, paper: .night), paper: .night, size: CGSize(width: 1024, height: 768),
                         type: .large, regular: true, scene: scene, name: "ipad-landscape-night")
    }

    func testWholeBookPilotOpeningMiddleClosingAndTextOnlyMatrix() async throws {
        let policy = try XCTUnwrap(WholeBookArtPolicy.bundled)
        for entry in policy.assets {
            let rule = try XCTUnwrap(policy.rules.first { $0.assetID == entry.asset.assetID })
            let art = WholeBookArtBinder.art(entry: entry, rule: rule, policy: policy)
            let image = await ReaderImageLoader.shared.image(art: art, targetPixelWidth: 1200)
            XCTAssertNotNil(image, entry.asset.assetID)
        }
        let pages = try wholeBookFixtures()
        let scene = try windowScene()
        let oldWindow = scene.windows.first(where: \.isKeyWindow)
        let grain = MPSettingsStore.shared.paperGrain
        MPSettingsStore.shared.paperGrain = false
        defer { oldWindow?.makeKey(); MPSettingsStore.shared.paperGrain = grain }
        for (name, page) in pages {
            if let art = page.art {
                let image = await ReaderImageLoader.shared.image(art: art, targetPixelWidth: 1200)
                XCTAssertNotNil(image, name)
            }
            for paper in [MP.ReadTheme.light, .night] {
                for size in [CGSize(width: 375, height: 667), CGSize(width: 440, height: 956)] {
                    for type in [DynamicTypeSize.large, .accessibility5] {
                        try await render(reader(page, paper: paper, pageIndex: page.index), paper: paper,
                            size: size, type: type, regular: false, scene: scene,
                            name: "whole-book-\(name)-\(paper.rawValue)-\(Int(size.width))-\(type)",
                            captureBottom: type.isAccessibilitySize)
                    }
                }
            }
        }
        let middle = try XCTUnwrap(pages.first { $0.0 == "middle" }?.1)
        try await render(reader(middle, paper: .light, pageIndex: middle.index), paper: .light,
            size: CGSize(width: 667, height: 375), type: .accessibility5, regular: false,
            scene: scene, name: "whole-book-middle-compact-ax5", captureBottom: true)
    }

    private func wholeBookFixtures() throws -> [(String, ReaderPage)] {
        let catalog = try ContentCatalogLoader().load().catalog
        let fixtures = [
            ("opening", "blueprint_absence_looking_001", "whole-book-art-v1-002", 1),
            ("middle", "bp_threshold_together_003", "whole-book-art-v1-069", 5),
            ("closing", "blueprint_threshold_crossing_001", "whole-book-art-v1-055", 7)
        ]
        var result: [(String, ReaderPage)] = []
        for (name, id, seed, index) in fixtures {
            let blueprint = try XCTUnwrap(catalog.blueprints.first { $0.id.rawValue == id })
            let composed = try OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog,
                intent: OfflineStoryIntent(childName: "Deniz", seed: seed, mode: .adventure,
                    ageBand: AgeBand(lowerBound: 5, upperBound: 6)))
            let story = OfflineStoryMapper.appStory(from: composed, childName: "Deniz", childProfileID: UUID(),
                storyIdeaID: nil, catalogVersion: catalog.version, ageBand: blueprint.ageRange)
            let pages = ReaderStory(from: story).leaves.compactMap(\.page)
            let page = try XCTUnwrap(pages.first { $0.index == index })
            XCTAssertEqual(page.composition, .spot, name)
            XCTAssertEqual(page.art?.bindingPolicyVersion, 3, name)
            XCTAssertEqual(story.pages[index].text, composed.pages[index].text)
            result.append((name, page))
            if name == "opening" {
                let text = try XCTUnwrap(pages.first { $0.art == nil && $0.composition == .text })
                result.append(("text-only", text))
            }
        }
        return result
    }

    func testTextOnlyAndWithdrawnChromeKeepTheSameReadingStyle() async throws {
        var page = try await pageFixture()
        page.art = nil
        XCTAssertEqual(page.composition, .text)
        let scene = try windowScene()
        let oldWindow = scene.windows.first(where: \.isKeyWindow)
        defer { oldWindow?.makeKey() }
        try await render(reader(page, paper: .light), paper: .light, size: CGSize(width: 440, height: 956),
                         type: .large, regular: false, scene: scene, name: "text-only-day")
        try await render(reader(page, paper: .night, controls: false), paper: .night,
                         size: CGSize(width: 440, height: 956), type: .large, regular: false,
                         scene: scene, name: "text-only-night-withdrawn")
    }

    func testSettingsUseTheSameTypographyAndRemainReachableAtAX5() async throws {
        let settings = MPSettingsStore.shared
        let oldTheme = settings.readTheme
        let oldSpacing = settings.readSpacing
        let oldAutoNight = settings.autoNight
        let oldWindow = try windowScene().windows.first(where: \.isKeyWindow)
        defer {
            settings.readTheme = oldTheme
            settings.readSpacing = oldSpacing
            settings.autoNight = oldAutoNight
            oldWindow?.makeKey()
        }
        settings.autoNight = false
        settings.readSpacing = .rahat
        let app = MPAppState()
        app.readSize = .cokBuyuk
        let scene = try windowScene()
        for paper in [MP.ReadTheme.light, .night] {
            app.readTheme = paper
            let view = ReaderSettingsSheet(textLayout: .breath, onClose: {})
                .environmentObject(app).environmentObject(settings)
            try await render(view, paper: paper, size: CGSize(width: 440, height: 956),
                             type: .large, regular: false, scene: scene, name: "settings-" + paper.rawValue)
        }
        app.readTheme = .light
        let accessible = ReaderSettingsSheet(textLayout: .breath, onClose: {})
            .environmentObject(app).environmentObject(settings)
        try await render(accessible, paper: .light, size: CGSize(width: 440, height: 956),
                         type: .accessibility5, regular: false, scene: scene, name: "settings-ax5")
        XCTAssertEqual(settings.readSpacing, .rahat)
        XCTAssertEqual(app.readSize, .cokBuyuk)
    }

    private func reader(_ page: ReaderPage, paper: MP.ReadTheme, controls: Bool = true,
                        pageIndex: Int = 0) -> some View {
        ZStack {
            StoryPageView(page: page, theme: paper, readSize: .cokBuyuk, spacing: .rahat,
                          layout: .breath, childName: "Deniz", folio: "\(pageIndex + 1) / 8", showsFolio: !controls,
                          accent: MP.C.brand, symbol: "book")
            ReaderChrome(theme: paper, isFavorite: false, isSpeaking: false, showsSecondary: controls,
                         pageLabel: "Sayfa \(pageIndex + 1) / 8", progress: Double(pageIndex + 1) / 8,
                         canGoPrevious: pageIndex > 0, canGoNext: pageIndex < 7,
                         onClose: {}, onToggleFavorite: {}, onToggleSpeech: {}, onOpenSettings: {},
                         pagePreviews: ["Birinci", "İkinci", "Üçüncü", "Dördüncü", "Beşinci", "Altıncı", "Yedinci", "Sekizinci"],
                         pageIndex: pageIndex)
        }
    }

    private func windowScene() throws -> UIWindowScene {
        try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    }

    private func render<Content: View>(_ content: Content, paper: MP.ReadTheme, size: CGSize,
                                      type: DynamicTypeSize, regular: Bool, scene: UIWindowScene,
                                      name: String, captureBottom: Bool = false) async throws {
        let view = content.environment(\.dynamicTypeSize, type)
            .environment(\.horizontalSizeClass, regular ? .regular : .compact)
            .environment(\.verticalSizeClass, !regular && size.width > size.height ? .compact : .regular)
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
        try await Task.sleep(nanoseconds: 900_000_000)
        host.view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            host.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
        }
        let data = try XCTUnwrap(image.pngData())
        XCTAssertGreaterThan(data.count, 1_000)
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
        attachment.name = "reader-reference-" + name
        attachment.lifetime = .keepAlways
        add(attachment)
        if captureBottom {
            for scroll in scrollViews(in: host.view) where scroll.contentSize.height > scroll.bounds.height {
                let bottom = scroll.contentSize.height - scroll.bounds.height + scroll.adjustedContentInset.bottom
                scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: bottom), animated: false)
                XCTAssertEqual(scroll.contentOffset.y, bottom, accuracy: 1)
            }
            host.view.layoutIfNeeded()
            let bottomImage = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                host.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
            }
            let bottom = XCTAttachment(data: try XCTUnwrap(bottomImage.pngData()), uniformTypeIdentifier: "public.png")
            bottom.name = "reader-reference-" + name + "-scrolled-bottom"
            bottom.lifetime = .keepAlways
            add(bottom)
        }
    }

    private func scrollViews(in view: UIView) -> [UIScrollView] {
        ((view as? UIScrollView).map { [$0] } ?? [])
            + view.subviews.flatMap { scrollViews(in: $0) }
    }
}
