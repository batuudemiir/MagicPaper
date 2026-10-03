import XCTest
import SwiftUI
import UIKit
@testable import MagicPaper

/// Sanat setleri: katalog, masala eşleme, yer tutucuya düşme ve görsel üstü
/// metnin okunurluğu.
@MainActor
final class StoryArtKitTests: XCTestCase {

    private var catalog: StoryArtKitCatalog {
        guard let catalog = StoryArtKitCatalog.load(from: .main) else {
            XCTFail("art_kits.json uygulama paketinde yok ya da çözülemiyor")
            return StoryArtKitCatalog(schemaVersion: 1, kits: [])
        }
        return catalog
    }

    private var gece: StoryArtKit? { catalog.kits.first { $0.id == "gece" } }

    // MARK: Katalog

    func testBundledCatalogHasTheNightPilot() throws {
        let kit = try XCTUnwrap(gece)
        XCTAssertEqual(kit.modes, ["bedtime"])
        XCTAssertEqual(kit.slots(.hero).count, 1)
        XCTAssertEqual(kit.slots(.cover).count, 1)
        XCTAssertFalse(kit.slots(.spot).isEmpty)
    }

    func testKitIDsAreUnique() {
        let ids = catalog.kits.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testSlotAssetsLiveInTheArtKitNamespace() {
        for kit in catalog.kits {
            for slot in kit.slots {
                XCTAssertTrue(slot.asset.hasPrefix("ArtKit/"), "\(kit.id): \(slot.asset)")
            }
        }
    }

    /// Yer tutucu, görsel gelmeden ekranın dolu görünmesini sağlar; motif
    /// yoksa bileşen boş bir gece kutusuna düşer.
    func testPlaceholderMotifsExistInTheBundle() {
        for kit in catalog.kits {
            XCTAssertFalse(kit.placeholderMotifs.isEmpty, kit.id)
            for motif in kit.placeholderMotifs {
                XCTAssertTrue(StoryArtKit.bundleHasAsset(motif), "\(kit.id): \(motif) yok")
            }
        }
    }

    func testTextSafeBandsStayInsideTheFrame() {
        for kit in catalog.kits {
            for slot in kit.slots {
                guard let b = slot.textSafe else { continue }
                XCTAssertGreaterThanOrEqual(b.x, 0)
                XCTAssertGreaterThanOrEqual(b.y, 0)
                XCTAssertLessThanOrEqual(b.x + b.width, 1.0001, "\(slot.asset)")
                XCTAssertLessThanOrEqual(b.y + b.height, 1.0001, "\(slot.asset)")
            }
        }
    }

    /// Kapak slotunun bandı `StoryCover`'ın kırpma kuralıyla aynı olmalı;
    /// ikisi ayrı yerde yazıyor ve ayrışırsa kapak yanlış yerden kırpılır.
    func testCoverBandMatchesStoryCover() throws {
        let band = try XCTUnwrap(gece?.slots(.cover).first?.textSafe)
        let cover = StoryCover.Cover.textSafeBand
        XCTAssertEqual(band.x, cover.x, accuracy: 0.0001)
        XCTAssertEqual(band.y, cover.y, accuracy: 0.0001)
        XCTAssertEqual(band.width, cover.width, accuracy: 0.0001)
        XCTAssertEqual(band.height, cover.height, accuracy: 0.0001)
    }

    // MARK: Masala eşleme

    func testBedtimeStoryGetsTheNightKit() {
        let story = Self.story(mode: "bedtime", world: "orman")
        XCTAssertEqual(story.mpArtKit(in: catalog)?.id, "gece")
    }

    func testAdventureStoryHasNoKitYet() {
        let story = Self.story(mode: "adventure", world: "orman")
        XCTAssertNil(story.mpArtKit(in: catalog))
    }

    func testStoryWithoutOriginHasNoKit() {
        let story = ReaderFixtures.textStory(pages: 3)
        XCTAssertNil(story.mpArtKit(in: catalog))
    }

    /// Ormandaki uyku masalı orman değil gece gibi görünmeli.
    func testModeWinsOverWorld() {
        let forest = StoryArtKit(id: "orman", name: "Orman", modes: [], worlds: ["orman"],
                                 placeholderMotifs: [], slots: [])
        let night = StoryArtKit(id: "gece", name: "Gece", modes: ["bedtime"], worlds: [],
                                placeholderMotifs: [], slots: [])
        let catalog = StoryArtKitCatalog(schemaVersion: 1, kits: [forest, night])
        XCTAssertEqual(Self.story(mode: "bedtime", world: "orman").mpArtKit(in: catalog)?.id, "gece")
        XCTAssertEqual(Self.story(mode: "growth", world: "orman").mpArtKit(in: catalog)?.id, "orman")
    }

    // MARK: Sanat çözümü

    func testDeliveredAssetIsDrawn() throws {
        let kit = try XCTUnwrap(gece)
        let hero = try XCTUnwrap(kit.slots(.hero).first)
        XCTAssertEqual(kit.art(for: .hero, assetExists: { $0 == hero.asset }), .image(hero.asset))
    }

    func testMissingAssetFallsBackToMotifs() throws {
        let kit = try XCTUnwrap(gece)
        XCTAssertEqual(kit.art(for: .hero, assetExists: { _ in false }), .motifs(kit.placeholderMotifs))
        XCTAssertEqual(kit.pendingSlots(assetExists: { _ in false }).count, kit.slots.count)
        XCTAssertTrue(kit.pendingSlots(assetExists: { _ in true }).isEmpty)
    }

    // MARK: Görsel üstü metin

    /// En kötü durum: karartmanın altında bembeyaz bir resim. Başlık ve künye
    /// yine de 4.5:1'in üstünde kalmalı (CLAUDE.md, Erişilebilirlik).
    func testTextOnArtIsLegibleOverWhiteArt() {
        let ink = Self.rgb(MP.Scrim.ink)
        let a = MP.Scrim.peak
        let background = (r: a * ink.r + (1 - a), g: a * ink.g + (1 - a), b: a * ink.b + (1 - a))

        for (name, color) in [("textOnArt", MP.C.textOnArt), ("textOnArtMuted", MP.C.textOnArtMuted)] {
            let ratio = Self.contrast(Self.rgb(color), background)
            XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(name): \(ratio)")
        }
    }

    // MARK: Yardımcılar

    private static func story(mode: String, world: String) -> Story {
        var story = ReaderFixtures.textStory(pages: 3)
        story.origin = StoryOrigin(
            seed: "s", storyIdeaID: nil, blueprintID: "b", settingID: "st",
            companionID: "c", discoveryID: "d", fingerprint: "f", catalogVersion: "v",
            worldID: world, modeID: mode, selectionStrategy: "direct", ageBand: "5-6"
        )
        return story
    }

    private static func rgb(_ color: Color) -> (r: Double, g: Double, b: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }

    private static func luminance(_ c: (r: Double, g: Double, b: Double)) -> Double {
        func lin(_ v: Double) -> Double { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
    }

    private static func contrast(_ a: (r: Double, g: Double, b: Double),
                                 _ b: (r: Double, g: Double, b: Double)) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }
}
