import StoryEngine
import SwiftUI
import UIKit
import XCTest
@testable import MagicPaper

/// Actual SwiftUI page renders in the simulator; attachments are visual evidence,
/// separate from the binding assertions and image integrity tests.
@MainActor
final class StorySpotReaderRenderingTests: XCTestCase {
    func testReviewedSpotPageOnPapersAndAdaptiveViewports() async throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let blueprint = try XCTUnwrap(catalog.blueprints.first { $0.id.rawValue == "blueprint_absence_looking_001" })
        let composed = try OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog,
            intent: OfflineStoryIntent(childName: "Deniz", settingID: ContentID("setting_forest_001"),
                discoveryID: ContentID("object_torn_map_001"), seed: "story-art-audit-23"))
        let story = OfflineStoryMapper.appStory(from: composed, childName: "Deniz", childProfileID: UUID(),
            storyIdeaID: nil, catalogVersion: catalog.version)
        let page = try XCTUnwrap(ReaderStory(from: story).leaves.compactMap(\.page).first)
        XCTAssertEqual(page.composition, .spot)
        let art = try XCTUnwrap(page.art)
        let loaded = await ReaderImageLoader.shared.image(art: art, targetPixelWidth: 600)
        XCTAssertNotNil(loaded)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let warmed = await ReaderImageLoader.shared.image(art: art, targetPixelWidth: MP.S.x10 * 3 * scene.screen.scale)
        XCTAssertNotNil(warmed)
        let oldWindow = scene.windows.first(where: \.isKeyWindow)
        defer { oldWindow?.makeKey() }
        for paper in MP.ReadTheme.allCases {
            try await render(page, paper: paper, size: CGSize(width: 375, height: 667),
                             type: .large, regular: false, scene: scene, name: "se-" + paper.rawValue)
        }
        try await render(page, paper: .night, size: CGSize(width: 440, height: 956),
                         type: .large, regular: false, scene: scene, name: "pro-max-night")
        try await render(page, paper: .light, size: CGSize(width: 375, height: 667),
                         type: .accessibility5, regular: false, scene: scene, name: "se-ax5-text-priority")
        try await render(page, paper: .night, size: CGSize(width: 1024, height: 768),
                         type: .large, regular: true, scene: scene, name: "ipad-landscape-night")
    }

    private func render(_ page: ReaderPage, paper: MP.ReadTheme, size: CGSize,
                        type: DynamicTypeSize, regular: Bool, scene: UIWindowScene, name: String) async throws {
        let view = StoryPageView(page: page, theme: paper, readSize: .normal, childName: "Deniz",
                                 folio: "1", showsFolio: true, accent: MP.C.brand, symbol: "book")
            .environment(\.dynamicTypeSize, type)
            .environment(\.horizontalSizeClass, regular ? .regular : .compact)
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
        try await Task.sleep(nanoseconds: 750_000_000)
        host.view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            host.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
        }
        let data = try XCTUnwrap(image.pngData())
        XCTAssertGreaterThan(data.count, 1_000)
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
        attachment.name = "story-spot-" + name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
