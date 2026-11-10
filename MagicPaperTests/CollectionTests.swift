import XCTest
@testable import MagicPaper

/// Faz 9: sakin koleksiyon. Yıldız eksiye düşmez, alınan kaybolmaz, şans yok.
final class CollectionTests: XCTestCase {

    private let lav = MPDecor.item("shelf_lav")!

    func testBuyingSpendsStarsOnce() {
        var wallet = MPStarWallet()
        XCTAssertEqual(wallet.buy(lav, earned: 10, easyPrices: false), .bought)
        XCTAssertEqual(wallet.balance(earned: 10), 2)
        XCTAssertEqual(wallet.buy(lav, earned: 10, easyPrices: false), .alreadyOwned)
        XCTAssertEqual(wallet.spent, 8)
    }

    func testStarsNeverGoNegative() {
        var wallet = MPStarWallet()
        XCTAssertEqual(wallet.buy(lav, earned: 3, easyPrices: false), .notEnough(missing: 5))
        XCTAssertTrue(wallet.purchases.isEmpty)
        XCTAssertEqual(wallet.balance(earned: 0), 0)
    }

    func testEasyPricesHalveRoundingUp() {
        XCTAssertEqual(lav.price(easy: true), 4)
        XCTAssertEqual(MPDecor(id: "x", kind: .shelf, title: "X", tone: .sky, price: 7).price(easy: true), 4)
        XCTAssertEqual(MPDecor.defaultShelf.price(easy: true), 0)
    }

    func testDefaultShelfIsFreeAndOwned() {
        let wallet = MPStarWallet()
        XCTAssertTrue(wallet.owns(.defaultShelf))
        XCTAssertEqual(wallet.equippedItem(.shelf), .defaultShelf)
    }

    func testCannotEquipWhatIsNotOwned() {
        var wallet = MPStarWallet()
        wallet.equip(lav)
        XCTAssertEqual(wallet.equippedItem(.shelf), .defaultShelf)
        _ = wallet.buy(lav, earned: 20, easyPrices: false)
        wallet.equip(lav)
        XCTAssertEqual(wallet.equippedItem(.shelf), lav)
    }

    func testMergeKeepsBothDevicesPurchases() {
        var a = MPStarWallet(), b = MPStarWallet()
        _ = a.buy(lav, earned: 20, easyPrices: false)
        _ = b.buy(MPDecor.item("shelf_mint")!, earned: 20, easyPrices: false)
        _ = b.buy(lav, earned: 20, easyPrices: false)
        let merged = a.merged(with: b)
        XCTAssertEqual(Set(merged.purchases.map(\.itemID)), ["shelf_lav", "shelf_mint"])
    }

    func testEveryItemHasAVisiblePriceAndNoDuplicates() {
        XCTAssertEqual(Set(MPDecor.catalog.map(\.id)).count, MPDecor.catalog.count)
        XCTAssertTrue(MPDecor.catalog.allSatisfy { $0.price >= 0 })
    }

    func testWalletPersistsPerChild() {
        let defaults = UserDefaults(suiteName: "CollectionTests")!
        defaults.removePersistentDomain(forName: "CollectionTests")
        let store = MPStarWalletStore(defaults: defaults)
        let child = UUID()
        var wallet = store.wallet(for: child)
        _ = wallet.buy(lav, earned: 9, easyPrices: false)
        store.save(wallet, for: child)
        XCTAssertEqual(store.wallet(for: child).spent, 8)
        XCTAssertEqual(store.wallet(for: UUID()).spent, 0)
    }

    func testAlbumGroupsByMonthNewestFirst() {
        let cal = Calendar(identifier: .gregorian)
        let nov = cal.date(from: DateComponents(year: 2026, month: 11, day: 10))!
        let oct = cal.date(from: DateComponents(year: 2026, month: 10, day: 3))!
        let art = MPBookCover.Art.title("A", tone: .sky, modeSymbol: nil, worldSymbol: "star")
        let groups = MPStickerAlbum.byMonth([
            MPSticker(id: "1", title: "A", art: art, date: nov),
            MPSticker(id: "2", title: "B", art: art, date: nov),
            MPSticker(id: "3", title: "C", art: art, date: oct)
        ], calendar: cal)
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0].stickers.count, 2)
        XCTAssertTrue(groups[0].title.hasPrefix("Kasım"))
    }
}

/// Faz 9: kahraman ve Dolap kuralları.
final class HeroWardrobeTests: XCTestCase {

    func testIdentityAndFaithItemsAreFree() {
        XCTAssertEqual(HeroShop.price(.hijab), 0, "Başörtüsü kimliğin parçası: hep ücretsiz")
        XCTAssertEqual(HeroShop.price(.round), 0, "Gözlük kimliğin parçası: ücretsiz")
        XCTAssertEqual(HeroShop.price(.tshirt), 0)
        XCTAssertTrue(HeroShop.paidItems(in: .standard).isEmpty)
    }

    func testPaidCosmeticsAreListedOnce() {
        var look = HeroLook.standard
        look.headwear = .crown
        look.top = .hoodie
        look.glasses = .sun
        let items = HeroShop.paidItems(in: look)
        XCTAssertEqual(items.map(\.price), [14, 8, 6])
    }

    func testBuyingSeveralItemsIsAllOrNothing() {
        var wallet = MPStarWallet()
        XCTAssertEqual(wallet.buy(itemIDs: ["a", "b"], total: 20, earned: 10), .notEnough(missing: 10))
        XCTAssertTrue(wallet.purchases.isEmpty)
        XCTAssertEqual(wallet.buy(itemIDs: ["a", "b"], total: 15, earned: 20), .bought)
        XCTAssertEqual(wallet.spent, 15, "Fiyat eşyalara bölünür, toplam korunur")
        XCTAssertTrue(wallet.owns(itemID: "a") && wallet.owns(itemID: "b"))
    }

    func testIdentityChangeNeedsAGrownUp() {
        var look = HeroLook.standard
        look.headwear = .crown
        XCTAssertFalse(HeroShop.identityChanged(from: .standard, to: look), "Şapka kozmetik")
        look.kind = .fox
        XCTAssertTrue(HeroShop.identityChanged(from: .standard, to: look))
    }

    func testLookRoundTripsAndOldDataStillDecodes() throws {
        let data = try JSONEncoder().encode(HeroLook.samples[3])
        XCTAssertEqual(try JSONDecoder().decode(HeroLook.self, from: data), HeroLook.samples[3])
        // Eski ya da eksik kayıt: tanınan alanlar kalır, gerisi varsayılan.
        let partial = Data(#"{"kind":"fox","hair":"unknownStyle"}"#.utf8)
        let decoded = try JSONDecoder().decode(HeroLook.self, from: partial)
        XCTAssertEqual(decoded.kind, .fox)
        XCTAssertEqual(decoded.hair, HeroLook.standard.hair)
    }

    func testPalettesCoverEverySample() {
        for look in HeroLook.samples {
            XCTAssertLessThan(look.skin, MP.C.heroSkin.count)
            XCTAssertLessThan(look.hairColor, MP.C.heroHair.count)
            XCTAssertLessThan(look.topColor, MP.C.heroCloth.count)
            XCTAssertLessThan(look.fur, MP.C.heroFur.count)
        }
    }
}
