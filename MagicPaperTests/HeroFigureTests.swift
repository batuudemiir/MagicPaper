import SwiftUI
import XCTest
@testable import MagicPaper

/// Tam boy kahraman (22 Kasım 2026). Teslimdeki `kontrol.cjs`'in kuralları,
/// ayrıca kayıt uyumluluğu, eski alanlara yansıma ve çizimin yardımcıları.
final class HeroFigureTests: XCTestCase {

    private let catalog = HeroFigureCatalog.shared

    // MARK: Katalog

    func testTheBundledCatalogHasEveryShelf() {
        for slot in HeroFigure.Slot.allCases {
            XCTAssertFalse(catalog.options(slot).isEmpty, "\(slot) boş")
            let ids = catalog.options(slot).map(\.id)
            XCTAssertEqual(Set(ids).count, ids.count, "\(slot) kimlikleri tekrar ediyor")
        }
        XCTAssertEqual(catalog.outfits.count, 16)
        XCTAssertEqual(catalog.starters.count, 8)
        XCTAssertEqual(catalog.options(.skin).count, 10)
        XCTAssertEqual(catalog.options(.top).count, 12)
    }

    func testEveryPaintedPartIsInTheAssetCatalog() {
        for slot in [HeroFigure.Slot.top, .bottom, .one, .shoe, .hair, .head] {
            for option in catalog.options(slot) {
                let parts = option.id.split(separator: "-")
                guard parts.count == 2, let n = Int(parts[1]), n <= 6,
                      ["top", "bottom", "one", "shoe", "hair", "hat"].contains(String(parts[0])) else { continue }
                XCTAssertNotNil(UIImage(named: "HeroFigure/\(option.id)"), "\(option.id) görseli yok")
            }
        }
    }

    func testEveryStarterIsAlreadyNormal() {
        for starter in catalog.starters {
            let figure = HeroFigure(values: starter.values)
            for slot in HeroFigure.Slot.allCases {
                XCTAssertEqual(figure[slot], starter.values[slot.rawValue], "\(starter.name) · \(slot)")
            }
        }
    }

    // MARK: Seçim kuralları (`secim.js`)

    func testChoosingAnyItemWearsIt() {
        for starter in catalog.starters {
            let base = HeroFigure(values: starter.values)
            for slot in HeroFigure.Slot.allCases {
                for option in catalog.options(slot) {
                    XCTAssertEqual(base.selecting(.item(slot, option.id))[slot], option.id)
                }
            }
        }
    }

    func testAnOutfitChangesOnlyClothes() {
        let keep: [HeroFigure.Slot] = HeroFigure.Slot.identity + [.glasses, .head, .bag]
        for starter in catalog.starters {
            let base = HeroFigure(values: starter.values)
            for outfit in catalog.outfits {
                let dressed = base.selecting(.outfit(outfit.id))
                for slot in keep { XCTAssertEqual(dressed[slot], base[slot], "\(outfit.name) \(slot) değiştirdi") }
                XCTAssertTrue(dressed.isSelected(.outfit(outfit.id)))
            }
        }
    }

    func testOnePieceRules() {
        let dressed = HeroFigure.starter.selecting(.outfit("set-2"))
        let single = dressed.selecting(.item(.one, "one-1"))
        XCTAssertEqual(single.selecting(.item(.shoe, "shoe-4"))[.one], "one-1", "ayakkabı tek parçayı korur")
        XCTAssertEqual(single.selecting(.item(.bottom, "bottom-3"))[.one], "none", "alt seçmek iki parçaya döner")
        XCTAssertEqual(single.selecting(.item(.one, "none"))[.top], dressed[.top], "üst ve alta dön")
        XCTAssertFalse(single.isSelected(.item(.top, dressed[.top])), "tek parçadayken üst tikli değil")
    }

    func testAStarterFaceKeepsTheClothes() {
        let base = HeroFigure.starter.selecting(.outfit("set-12")).selecting(.item(.glasses, "glass-3"))
        for i in catalog.starters.indices {
            let face = base.selecting(.starter(i))
            for slot in [HeroFigure.Slot.one, .shoe, .bag, .head, .glasses, .top, .bottom] {
                XCTAssertEqual(face[slot], base[slot])
            }
            XCTAssertTrue(face.isSelected(.starter(i)))
        }
    }

    func testAHijabKeepsTheHairChoice() {
        let covered = HeroFigure.starter.selecting(.item(.head, "scarf-3"))
        let rehaired = covered.selecting(.item(.hair, "hair-4"))
        XCTAssertEqual(rehaired[.head], "scarf-3")
        XCTAssertEqual(rehaired[.hair], "hair-4")
        XCTAssertTrue(rehaired.isHijab)
        XCTAssertEqual(rehaired.selecting(.item(.head, "none"))[.hair], "hair-4")
    }

    func testAnUnknownValueFallsBackOnlyInItsOwnSlot() {
        var raw = catalog.starters[4].values
        raw["eye"] = "eski"
        let figure = HeroFigure(values: raw)
        XCTAssertEqual(figure[.skin], catalog.starters[4].values["skin"])
        XCTAssertEqual(figure[.eye], catalog.starters[0].values["eye"])
    }

    func testAnUnknownChoiceChangesNothing() {
        let figure = HeroFigure.starter
        XCTAssertEqual(figure.selecting(.item(.top, "top-99")), figure)
        XCTAssertEqual(figure.selecting(.outfit("set-99")), figure)
        XCTAssertEqual(figure.selecting(.starter(99)), figure)
    }

    // MARK: Kayıt

    func testTheFigureRoundTripsInsideTheHero() throws {
        let figure = HeroFigure.starter.selecting(.outfit("set-12")).selecting(.item(.head, "scarf-2"))
        let look = HeroLook.standard.wearing(figure)
        let decoded = try JSONDecoder().decode(HeroLook.self, from: JSONEncoder().encode(look))
        XCTAssertEqual(decoded, look)
        XCTAssertEqual(decoded.figure, figure)
        XCTAssertTrue(decoded.drawsFigure)
    }

    func testAnOldHeroWithoutAFigureStaysAsItWas() throws {
        let old = #"{"kind":"child","skin":3,"hair":"curly","hairColor":0,"top":"hoodie","topColor":2}"#
        let look = try JSONDecoder().decode(HeroLook.self, from: Data(old.utf8))
        XCTAssertNil(look.figure)
        XCTAssertFalse(look.drawsFigure)
        XCTAssertEqual(look.hair, .curly)
    }

    func testAnAnimalKeepsTheChildsFigureButIsNotDrawnWithIt() {
        var look = HeroLook.standard.wearing(.starter)
        look.kind = .fox
        XCTAssertNotNil(look.figure)
        XCTAssertFalse(look.drawsFigure)
    }

    func testWearingAFigureReflectsIntoTheOldFields() {
        let figure = HeroFigure(values: catalog.starters[4].values)   // Göl kenarı: başörtüsü, mor gözlük
        let look = HeroLook(kind: .cat, headwear: .beanie).wearing(figure)
        XCTAssertEqual(look.kind, .child)
        XCTAssertEqual(look.headwear, .hijab)
        XCTAssertEqual(look.glasses, .round)
        XCTAssertEqual(look.skin, HeroFigureLegacy.skin[figure[.skin]])
        XCTAssertNil(HeroBookCharacter.spec(for: look, kit: nil), "başörtülü çocuk kitapta çizilmez")
        let bare = look.wearing(figure.selecting(.item(.head, "none")))
        XCTAssertEqual(bare.headwear, .none, "başörtüsü çıkınca eski alan da temizlenir")
        XCTAssertNotNil(HeroBookCharacter.spec(for: bare, kit: nil))
    }

    func testEveryOptionHasALegacyMappingWhereOneIsNeeded() {
        for option in catalog.options(.skin) { XCTAssertNotNil(HeroFigureLegacy.skin[option.id], option.id) }
        for option in catalog.options(.hair) { XCTAssertNotNil(HeroFigureLegacy.hair[option.id], option.id) }
        for option in catalog.options(.dye) { XCTAssertNotNil(HeroFigureLegacy.hairColor[option.id], option.id) }
        for option in catalog.options(.top) { XCTAssertNotNil(HeroFigureLegacy.clothColor[option.id], option.id) }
        for option in catalog.options(.one) where option.id != "none" {
            XCTAssertNotNil(HeroFigureLegacy.clothColor[option.id], option.id)
        }
    }

    // MARK: Çizim yardımcıları

    func testThePathReaderUnderstandsRelativeAndImplicitCommands() {
        let square = HeroSVGPath.path("M10 10l20 0 0 20 -20 0z").boundingRect
        XCTAssertEqual(square, CGRect(x: 10, y: 10, width: 20, height: 20))
        let horizontal = HeroSVGPath.path("M99 221h39").boundingRect
        XCTAssertEqual(horizontal.maxX, 138, accuracy: 0.001)
        let pants = HeroSVGPath.path("M96 214H144L144 314Q136 318 126 314L119 251L113 314Q103 317 95 313Z").boundingRect
        XCTAssertEqual(pants.minY, 214, accuracy: 0.001)
        XCTAssertEqual(pants.maxX, 144, accuracy: 0.001)
        let star = HeroSVGPath.path("M120 173l3 8 9 1 -7 6 2 9 -7 -5 -8 5 2 -9 -6 -6 8 -1z").boundingRect
        XCTAssertEqual(star.maxX, 132, accuracy: 0.001)
    }

    func testTintMatchesTheJavaScript() {
        // tint('#DB9D71', '#713F32', .27) → #be8460 (kahraman.js: 219·.73+113·.27 = 190,38 → 190)
        let shade = HeroRGB(0xDB9D71).tint(HeroRGB(0x713F32), 0.27)
        XCTAssertEqual(shade, HeroRGB(0xBE8460))
    }

    func testTheDyeCubeMapsBlackAndWhiteToTheTableEnds() {
        let colors = [HeroRGB(0x101010), HeroRGB(0x404040), HeroRGB(0x808080), HeroRGB(0xF0E0D0)]
        let data = HeroHairDye.cube(colors)
        let floats = data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
        XCTAssertEqual(floats.count, 32 * 32 * 32 * 4)
        XCTAssertEqual(floats[0], Float(0x10) / 255, accuracy: 0.001)
        let last = floats.count - 4
        XCTAssertEqual(floats[last], Float(0xF0) / 255, accuracy: 0.001)
        XCTAssertEqual(floats[last + 2], Float(0xD0) / 255, accuracy: 0.001)
        XCTAssertEqual(floats[last + 3], 1)
    }
}
