import XCTest
import SwiftUI
import UIKit
@testable import MagicPaper

/// Kitap karakterinin çizimi (B2, Faz 2): dışa aktarılan görüntü, renk
/// değişimi, pozların ayırt edilmesi, aynalama, tuvalden taşmama ve gerçek
/// varlık ad sözleşmesi.
@MainActor
final class AvatarViewTests: XCTestCase {

    private var kit: AvatarKit {
        get throws { try XCTUnwrap(AvatarKit.load(from: .main)) }
    }

    private func spec(skin: String = "skin_olive", hairStyle: String = "hair_short",
                      hair: String = "haircolor_brown", outfit: String = "outfit_blue",
                      accessory: String? = nil) -> AvatarSpec {
        AvatarSpec(skinTone: skin, hairStyle: hairStyle, hairColor: hair, outfit: outfit, accessory: accessory)
    }

    // MARK: - Piksel okuma

    private typealias Bitmap = TestBitmap

    private func render(_ spec: AvatarSpec, pose: String = "standing", facing: String = "right") throws -> Bitmap {
        let image = try XCTUnwrap(AvatarView.renderImage(spec: spec, pose: pose, facing: facing, kit: try kit))
        return try Bitmap(image)
    }

    /// Birim koordinattaki bir noktanın pikseli (genişlik = 1).
    private func at(_ bmp: Bitmap, _ p: CGPoint) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        bmp.pixel(Int(p.x * CGFloat(bmp.width)), Int(p.y * CGFloat(bmp.width)))
    }

    private func differ(_ a: (r: UInt8, g: UInt8, b: UInt8, a: UInt8),
                        _ b: (r: UInt8, g: UInt8, b: UInt8, a: UInt8)) -> Bool {
        abs(Int(a.r) - Int(b.r)) + abs(Int(a.g) - Int(b.g)) + abs(Int(a.b) - Int(b.b)) > 30
    }

    // MARK: - Dışa aktarma

    /// B1 köprüsü: tuval boyutunda, şeffaf zeminli bir görüntü.
    func testExportIsTheKitCanvasWithATransparentBackground() throws {
        let bmp = try render(spec())
        XCTAssertEqual(bmp.width, 512)
        XCTAssertEqual(bmp.height, 768)
        XCTAssertEqual(bmp.pixel(4, 4).a, 0, "köşe şeffaf olmalı")
        XCTAssertTrue(bmp.opaque(256, 384), "göğüs dolu olmalı")   // birim (0.5, 0.75)
    }

    // MARK: - Renk değişimi bir bakışta görünür

    func testSkinHairAndOutfitColoursChangeWhatIsDrawn() throws {
        let s = AvatarFigure.skeleton(for: "standing")
        let headCheek = CGPoint(x: s.head.x - 0.12, y: s.head.y + 0.21)   // çenenin solu: göz, ağız ve allığın dışında
        let hairTop = CGPoint(x: s.head.x, y: s.head.y - AvatarFigure.headRadius * 0.85)
        let chest = CGPoint(x: (s.torsoTop.x + s.torsoBottom.x) / 2, y: (s.torsoTop.y + s.torsoBottom.y) / 2)

        let base = try render(spec())
        XCTAssertTrue(differ(at(base, headCheek), at(try render(spec(skin: "skin_dark")), headCheek)), "ten")
        XCTAssertTrue(differ(at(base, hairTop), at(try render(spec(hair: "haircolor_blonde")), hairTop)), "saç")
        XCTAssertTrue(differ(at(base, chest), at(try render(spec(outfit: "outfit_orange")), chest)), "kıyafet")
    }

    /// Yüz her tende okunur: göz beyazı, en koyu tende bile tenden açıkça ayrılır.
    func testEyesReadOnEverySkinTone() throws {
        let s = AvatarFigure.skeleton(for: "standing")
        let eye = AvatarFigure.eyeCenters[1]
        let white = CGPoint(x: s.head.x + eye.x - 0.045, y: s.head.y + eye.y)
        let chin = CGPoint(x: s.head.x - 0.12, y: s.head.y + 0.21)
        for option in try kit.options(.skinTone) {
            let bmp = try render(spec(skin: option.id))
            let w = at(bmp, white), k = at(bmp, chin)
            let lum = { (p: (r: UInt8, g: UInt8, b: UInt8, a: UInt8)) in
                0.2126 * Double(p.r) + 0.7152 * Double(p.g) + 0.0722 * Double(p.b) }
            XCTAssertGreaterThan(lum(w) - lum(k), option.id == "skin_light" ? 15 : 60,
                                 "\(option.id): göz beyazı tenden ayrılmıyor")
        }
    }

    /// Her kıyafet rengi ötekilerden ayırt edilir.
    func testEveryOutfitColourIsDistinct() throws {
        let s = AvatarFigure.skeleton(for: "standing")
        let chest = CGPoint(x: s.torsoTop.x, y: (s.torsoTop.y + s.torsoBottom.y) / 2)
        let colours = try kit.options(.outfit).map { option in at(try render(spec(outfit: option.id)), chest) }
        for i in colours.indices {
            for j in colours.indices where j > i {
                XCTAssertTrue(differ(colours[i], colours[j]), "kıyafet \(i) ve \(j) aynı görünüyor")
            }
        }
    }

    // MARK: - Pozlar siluetinden ayırt edilir

    func testEveryPoseHasItsOwnSilhouette() throws {
        let silhouettes = try AvatarFigure.poseIDs.map { try render(spec(), pose: $0).silhouette() }
        let cells = silhouettes[0].count
        for i in silhouettes.indices {
            for j in silhouettes.indices where j > i {
                let diff = zip(silhouettes[i], silhouettes[j]).filter { $0 != $1 }.count
                XCTAssertGreaterThan(Double(diff) / Double(cells), 0.03,
                                     "\(AvatarFigure.poseIDs[i]) ile \(AvatarFigure.poseIDs[j]) siluette ayırt edilmiyor")
            }
        }
    }

    func testTheKitsPosesAllHaveAPlaceholder() throws {
        XCTAssertEqual(Set(try kit.poses.map(\.id)), Set(AvatarFigure.poseIDs))
    }

    func testAnUnknownPoseDrawsStanding() throws {
        XCTAssertEqual(try render(spec(), pose: "flying").silhouette(),
                       try render(spec(), pose: "standing").silhouette())
    }

    // MARK: - Aynalama

    func testFacingLeftIsTheMirrorImage() throws {
        let right = try render(spec(accessory: "acc_backpack"), pose: "pointing")
        let left = try render(spec(accessory: "acc_backpack"), pose: "pointing", facing: "left")
        var mismatches = 0
        for y in stride(from: 0, to: right.height, by: 8) {
            for x in stride(from: 0, to: right.width, by: 8) where right.opaque(x, y) != left.opaque(right.width - 1 - x, y) {
                mismatches += 1
            }
        }
        XCTAssertLessThan(mismatches, 12, "sola bakış sağa bakışın aynası değil")
    }

    // MARK: - Tuvalden taşmama (sözleşme)

    /// Hiçbir poz, saç biçimi ya da aksesuar tuvalin kenarına değmez.
    func testNothingTouchesTheCanvasEdge() throws {
        let kit = try kit
        let styles = kit.options(.hairStyle).map(\.id)
        let accessories: [String?] = [nil] + kit.options(.accessory).map(\.id)
        for pose in AvatarFigure.poseIDs {
            for style in styles {
                for accessory in accessories {
                    let bmp = try render(spec(hairStyle: style, accessory: accessory), pose: pose)
                    var touches = false
                    for x in stride(from: 0, to: bmp.width, by: 2) where bmp.opaque(x, 0) || bmp.opaque(x, bmp.height - 1) {
                        touches = true
                    }
                    for y in stride(from: 0, to: bmp.height, by: 2) where bmp.opaque(0, y) || bmp.opaque(bmp.width - 1, y) {
                        touches = true
                    }
                    XCTAssertFalse(touches, "\(pose) · \(style) · \(accessory ?? "-") tuvalden taşıyor")
                }
            }
        }
    }

    /// Ayak noktası tuvalin alt ortasında: sahnedeki `characterAnchor` buna
    /// göre yerleştirir.
    func testStandingFeetRestOnTheBottomCentre() throws {
        let bmp = try render(spec())
        let lowest = (0..<bmp.height).last { y in (0..<bmp.width).contains { bmp.opaque($0, y) } } ?? 0
        XCTAssertGreaterThan(Double(lowest) / Double(bmp.height), 0.97)
        let xs = (0..<bmp.width).filter { bmp.opaque($0, lowest - 4) }
        let centre = Double(xs.reduce(0, +)) / Double(max(xs.count, 1)) / Double(bmp.width)
        XCTAssertEqual(centre, 0.5, accuracy: 0.05)
    }

    // MARK: - Renk token'ları

    func testEveryKitColourTokenResolves() throws {
        let kit = try kit
        for group in AvatarKit.Group.allCases {
            for option in kit.options(group) {
                if let token = option.colorToken {
                    XCTAssertNotNil(MP.C.avatarParts[token], "\(option.id): \(token)")
                }
            }
        }
    }

    // MARK: - Gerçek varlık sözleşmesi

    func testAssetNamesFollowTheContract() {
        XCTAssertEqual(AvatarArt.assetName(pose: "walking", layer: "body"), "Avatar/walking_body")
        XCTAssertEqual(AvatarArt.assetName(pose: "walking", layer: "hairFront", variant: "hair_curly"),
                       "Avatar/walking_hairFront_hair_curly")
    }

    /// Zorunlu katmanlardan biri eksikse gerçek varlık hiç kullanılmaz.
    func testMissingRequiredArtFallsBackToThePlaceholder() throws {
        let kit = try kit
        XCTAssertNil(AvatarArt.realLayers(pose: "standing", spec: spec(), kit: kit, assetExists: { _ in false }))
        XCTAssertNil(AvatarArt.realLayers(pose: "standing", spec: spec(), kit: kit,
                                          assetExists: { !$0.contains("_face") }))
    }

    func testRealLayersFollowTheKitOrderAndTints() throws {
        let kit = try kit
        let layers = try XCTUnwrap(AvatarArt.realLayers(pose: "standing", spec: spec(accessory: "acc_glasses"),
                                                        kit: kit, assetExists: { _ in true }))
        XCTAssertEqual(layers.map(\.name), [
            "Avatar/standing_hairBack_hair_short", "Avatar/standing_body",
            "Avatar/standing_outfit_tshirt", "Avatar/standing_face",
            "Avatar/standing_hairFront_hair_short", "Avatar/standing_accessory_acc_glasses"
        ])
        XCTAssertEqual(layers.map(\.tint), [.hair, .skin, .outfit, nil, .hair, nil])

        let noAccessory = try XCTUnwrap(AvatarArt.realLayers(pose: "standing", spec: spec(), kit: kit,
                                                             assetExists: { _ in true }))
        XCTAssertFalse(noAccessory.contains { $0.name.contains("accessory") })
    }
}
