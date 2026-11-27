import SwiftUI
import UIKit
import XCTest
@testable import MagicPaper

@MainActor
final class CompanionPortraitCatalogTests: XCTestCase {
    private let portraits = [
        ("companion_fox_pilot_001", "companion_portrait_tarcin_v4", "Tarçın"),
        ("companion_hedgehog_pilot_001", "companion_portrait_kestane_v4", "Kestane"),
        ("companion_owl_pilot_001", "companion_portrait_yildiz_v4", "Yıldız"),
        ("companion_city_cat_001", "companion_portrait_simit_v4", "Simit"),
        ("companion_bear_001", "companion_portrait_bogurtlen_v4", "Böğürtlen")
    ]

    func testOnlyCanonicalIdentitiesResolveToDistinctDecodablePortraits() throws {
        var names = Set<String>()
        for (id, expected, _) in portraits {
            let name = try XCTUnwrap(CompanionPortraitCatalog.assetName(for: id))
            XCTAssertEqual(name, expected)
            XCTAssertTrue(names.insert(name).inserted)
            let image = try XCTUnwrap(UIImage(named: name), name)
            XCTAssertGreaterThan(image.size.width, 0)
            XCTAssertGreaterThan(image.size.height, 0)
            XCTAssertNotNil(image.cgImage)
        }
    }

    func testLegacyAndUnknownIdentitiesKeepSymbolFallback() {
        for id in ["fox", "owl", "hedgehog", "cat", "companion_fox_001", "companion_owl_001",
                   "companion_hedgehog_001", "companion_cat_001", "", "unknown"] {
            XCTAssertNil(CompanionPortraitCatalog.assetName(for: id), id)
        }
    }

    func testPortraitRowsRenderAcrossAppearanceWidthAndDynamicType() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let oldWindow = scene.windows.first(where: \.isKeyWindow)
        defer { oldWindow?.makeKey() }
        for scheme in [ColorScheme.light, .dark] {
            for width in [375.0, 440.0] {
                for type in [DynamicTypeSize.large, .accessibility5] {
                    try await renderRows(scene: scene, scheme: scheme, width: width, type: type)
                }
            }
        }
    }

    private func renderRows(scene: UIWindowScene, scheme: ColorScheme, width: Double,
                            type: DynamicTypeSize) async throws {
        let fixtures = portraits + [("unknown", "", "Yeni arkadaş")]
        let view = ScrollView {
            VStack(spacing: MPSpacing.md) {
                ForEach(fixtures, id: \.0) { id, _, name in
                    CreationChoiceRow(title: name, subtitle: "Masala birlikte katılır.",
                        isSelected: id == "companion_fox_pilot_001", accessibilityLabel: name,
                        action: {}, leading: { MPCompanionPortrait(companionID: id, fallbackSymbol: "pawprint") })
                }
            }.padding(MPSpacing.screenH)
        }
        .background(MPColor.backgroundSurface)
        .environment(\.colorScheme, scheme)
        .environment(\.dynamicTypeSize, type)
        let host = UIHostingController(rootView: view)
        let window = UIWindow(windowScene: scene)
        let size = CGSize(width: width, height: width == 375 ? 667 : 956)
        window.frame = CGRect(origin: .zero, size: size)
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        try await Task.sleep(nanoseconds: 900_000_000)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            host.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
        }
        let data = try XCTUnwrap(image.pngData())
        XCTAssertGreaterThan(data.count, 1_000)
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
        attachment.name = "companion-portraits-\(scheme)-\(width)-\(type)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
