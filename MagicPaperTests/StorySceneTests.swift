import XCTest
import SwiftUI
import UIKit
@testable import MagicPaper

/// Görselli masalın sahnesi okuyucuda ve PDF'te (B2, Faz 3): çözümleme,
/// okuyucu eşlemesi, avatarın ve yol arkadaşının anchor'da çizilmesi, PDF.
@MainActor
final class StorySceneTests: XCTestCase {

    private var library: SceneLibrary {
        get throws { try XCTUnwrap(SceneLibrary.load(from: .main)) }
    }

    private func avatar(skin: String = "skin_olive") -> AvatarSpec {
        AvatarSpec(skinTone: skin, hairStyle: "hair_short", hairColor: "haircolor_brown", outfit: "outfit_blue")
    }

    private func illustration(_ avatar: AvatarSpec? = nil) -> StoryIllustration {
        StoryIllustration(avatar: avatar ?? self.avatar(), avatarKitVersion: "1.0.0",
                          avatarArtVersion: 1, sceneLibraryVersion: "1.0.0")
    }

    private func plate(_ id: String = "scene_forest_problem_01", pose: String = "standing",
                       companion: Bool = true) -> ScenePlate {
        ScenePlate(sceneID: id, sceneVersion: 1, pose: pose, facing: "right",
                   companionID: companion ? "companion_fox_pilot_001" : nil,
                   companionKind: companion ? "tilki" : nil)
    }

    private func story(plates: [ScenePlate?], illustration: StoryIllustration? = nil) -> Story {
        var story = Story(title: "Orman", childName: "Ada", childProfileID: UUID(),
                          theme: .custom, language: .turkish, status: .completed)
        story.pages = plates.enumerated().map { index, plate in
            var page = StoryPage(title: "", text: "Sayfa \(index + 1).", imagePrompt: "child at the edge")
            page.scene = plate
            return page
        }
        story.illustration = illustration
        return story
    }

    // MARK: - Çözümleme

    func testAPlateResolvesOnlyWithAUsableSnapshotAndAKnownScene() throws {
        let lib = try library
        XCTAssertNotNil(ResolvedScene.resolve(plate(), illustration: illustration(), library: lib))
        XCTAssertNil(ResolvedScene.resolve(nil, illustration: illustration(), library: lib))
        XCTAssertNil(ResolvedScene.resolve(plate(), illustration: nil, library: lib))
        XCTAssertNil(ResolvedScene.resolve(plate(), illustration: .unreadable, library: lib))
        XCTAssertNil(ResolvedScene.resolve(plate("scene_unknown"), illustration: illustration(), library: lib))
        XCTAssertNil(ResolvedScene.resolve(plate(), illustration: illustration(), library: nil))
    }

    /// Sahnenin izin vermediği bir poz çizilmez; sahnenin varsayılanı çizilir.
    func testAnUnknownPoseFallsBackToTheScenesDefault() throws {
        let scene = try XCTUnwrap(ResolvedScene.resolve(plate(pose: "flying"), illustration: illustration(),
                                                        library: try library))
        XCTAssertEqual(scene.pose, scene.scene.defaultPose)
    }

    // MARK: - Okuyucu

    func testReaderPagesWithAPlateBecomeIllustrated() throws {
        let story = story(plates: [plate("scene_forest_hook_01", companion: false), nil], illustration: illustration())
        let reader = ReaderStory(from: story)
        let pages = reader.leaves.compactMap(\.page)
        XCTAssertEqual(pages.count, 2)

        XCTAssertTrue(pages[0].hasIllustration)
        XCTAssertNotNil(pages[0].scene)
        XCTAssertNil(pages[0].imageRef)
        let alt = try XCTUnwrap(try library.scene("scene_forest_hook_01")?.altTextTR)
        XCTAssertEqual(pages[0].imageLabel, alt, "VoiceOver sahnenin Türkçe tarifini okumalı")
        XCTAssertFalse(pages[0].imageLabel?.contains("child") ?? true, "İngilizce sahne notu okunmamalı")

        XCTAssertFalse(pages[1].hasIllustration)
        XCTAssertNil(pages[1].imageLabel)
    }

    /// B2 öncesi masal okuyucuda bugünkü gibi açılır: sahne yok, etiket yok.
    func testAStoryWithoutASnapshotIsReadExactlyAsBefore() {
        let pages = ReaderStory(from: story(plates: [nil, nil])).leaves.compactMap(\.page)
        XCTAssertTrue(pages.allSatisfy { $0.scene == nil && !$0.hasIllustration && $0.imageLabel == nil })
    }

    /// Anlık görüntü okunamıyorsa plate'ler yok sayılır; kitap metin kitabıdır.
    func testAnUnreadableSnapshotLeavesTextPages() {
        let pages = ReaderStory(from: story(plates: [plate()], illustration: .unreadable)).leaves.compactMap(\.page)
        XCTAssertFalse(pages[0].hasIllustration)
    }

    // MARK: - Çizim

    private func render(_ plate: ScenePlate, avatar: AvatarSpec? = nil, width: CGFloat = 400) throws -> TestBitmap {
        let scene = try XCTUnwrap(ResolvedScene.resolve(plate, illustration: illustration(avatar), library: try library))
        let image = try XCTUnwrap(StorySceneView.renderImage(scene, width: width, scale: 1))
        return try TestBitmap(image)
    }

    func testTheSceneIsFourByThree() throws {
        let bmp = try render(plate())
        XCTAssertEqual(bmp.width, 400)
        XCTAssertEqual(bmp.height, 300)
    }

    /// Avatar sahnenin anchor'ında durur ve kitaptaki avatarı izler: aynı
    /// noktada ten değişince piksel değişir.
    func testTheAvatarStandsOnItsAnchor() throws {
        let p = plate(companion: false)
        let version = try XCTUnwrap(try library.scene(p.sceneID)?.versions.first)
        let a = version.characterAnchor
        let (w, h) = (400.0, 300.0)
        let figureHeight = h * a.scale
        let top = h * a.y - figureHeight
        // Avatar tuvalinde çenenin solu: (0.38, 0.407) — göz, ağız ve allığın dışında.
        let x = Int(w * a.x + (0.38 - 0.5) * figureHeight / AvatarFigure.canvasAspect)
        let y = Int(top + 0.407 * figureHeight)

        let light = try render(p, avatar: avatar(skin: "skin_light")).pixel(x, y)
        let dark = try render(p, avatar: avatar(skin: "skin_dark")).pixel(x, y)
        let diff = abs(Int(light.r) - Int(dark.r)) + abs(Int(light.g) - Int(dark.g)) + abs(Int(light.b) - Int(dark.b))
        XCTAssertGreaterThan(diff, 60, "avatar anchor'da çizilmiyor")
    }

    /// Yol arkadaşı yalnızca plate onu taşıyorsa çizilir.
    func testTheCompanionIsDrawnOnlyWhenThePlateCarriesThem() throws {
        let version = try XCTUnwrap(try library.scene("scene_forest_problem_01")?.versions.first)
        let c = try XCTUnwrap(version.companionAnchor)
        let x = Int(400 * c.x), y = Int(300 * c.y - 300 * c.scale * 0.5)
        let with = try render(plate(companion: true)).pixel(x, y)
        let without = try render(plate(companion: false)).pixel(x, y)
        let diff = abs(Int(with.r) - Int(without.r)) + abs(Int(with.g) - Int(without.g)) + abs(Int(with.b) - Int(without.b))
        XCTAssertGreaterThan(diff, 40)
    }

    /// MVP'nin dört yol arkadaşının her birinin yer tutucusu var.
    func testEveryMVPCompanionKindHasAPlaceholder() throws {
        for kind in ["tilki", "kirpi", "tavşan", "baykuş"] {
            let renderer = ImageRenderer(content: CompanionView(kind: kind).frame(width: 120, height: 120))
            renderer.scale = 1
            renderer.isOpaque = false
            let bmp = try TestBitmap(try XCTUnwrap(renderer.uiImage))
            let filled = (0..<60).flatMap { r in (0..<60).map { c in (c * 2, r * 2) } }.filter { bmp.opaque($0.0, $0.1) }.count
            XCTAssertGreaterThan(filled, 300, "\(kind) çizilmiyor")
        }
    }

    func testEveryPlaceholderToneExists() throws {
        for scene in try library.scenes {
            for v in scene.versions {
                if let tone = v.placeholderArt?.tone {
                    XCTAssertNotNil(MP.C.sceneTones[tone], "\(scene.id): \(tone)")
                }
            }
        }
    }

    // MARK: - PDF

    /// PDF'te sahne çıkar: görselli kitabın PDF'i aynı metinli kitabınkinden
    /// belirgin biçimde büyüktür ve sayfa sayısı değişmez.
    func testThePDFCarriesTheScenes() async throws {
        let plates: [ScenePlate?] = [plate("scene_forest_hook_01", companion: false), nil, nil,
                                     plate("scene_forest_problem_01")]
        let illustrated = story(plates: plates, illustration: illustration())
        var plain = illustrated
        plain.illustration = nil

        let madeA = await MPStoryPDF.makePDF(stories: [illustrated], fileName: "b2-illustrated.pdf")
        let madeB = await MPStoryPDF.makePDF(stories: [plain], fileName: "b2-plain.pdf")
        let a = try XCTUnwrap(madeA)
        let b = try XCTUnwrap(madeB)
        defer { try? FileManager.default.removeItem(at: a); try? FileManager.default.removeItem(at: b) }

        let docA = try XCTUnwrap(CGPDFDocument(a as CFURL))
        let docB = try XCTUnwrap(CGPDFDocument(b as CFURL))
        XCTAssertEqual(docA.numberOfPages, 7, "kapak + ithaf + 4 sayfa + künye")
        XCTAssertEqual(docA.numberOfPages, docB.numberOfPages)

        let size = { (url: URL) in (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0 }
        XCTAssertGreaterThan(size(a), size(b) + 50_000, "PDF'te sahne yok gibi")
    }
}
