import XCTest
@testable import StoryEngine

/// Hangi mod hangi yaş bandında bir blueprint'e ulaşıyor (FAZ 10).
///
/// Bu matris içerik kararıdır ve bilerek burada sabitlenir: bir bant için
/// içerik yazıldığında bu test kırmızıya döner ve güncellenir. Kurulamayan mod
/// o bantta gösterilmez; bu bir hata değil, bir eksik.
final class ModeBandCoverageTests: XCTestCase {

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    private let b34 = AgeBand(lowerBound: 3, upperBound: 4)
    private let b56 = AgeBand(lowerBound: 5, upperBound: 6)
    private let b78 = AgeBand(lowerBound: 7, upperBound: 8)
    private let b910 = AgeBand(lowerBound: 9, upperBound: 10)

    func testTheShippedMatrix() throws {
        let coverage = BlueprintSelector().modeCoverage(catalog: try catalog())
        XCTAssertEqual(Set(coverage.keys), Set(AgeBandResolver.bands))
        // 22 Ekim 2026: `charge` "Yeni şeyler öğrenelim"e eklenince (karar:
        // Batuhan) 3-4 bandı ikinci moduna kavuştu. O bant bu güne kadar tek
        // bir uyku şeklinden ibaretti; `lookingAfter` yazılmıştı, korpusu
        // tamdı ve hiçbir çocuk ona ulaşamıyordu.
        // H1 (17 Kasım 2026): 3-4 maceraya kavuştu; dört sakin şekil.
        XCTAssertEqual(coverage[b34], [.learning, .adventure, .bedtime])
        XCTAssertEqual(coverage[b56], [.learning, .adventure, .bedtime])
        // Faz 10 (11 Kasım 2026): 7-8 kendi korpusuyla üç moda da kavuştu.
        XCTAssertEqual(coverage[b78], [.learning, .adventure, .bedtime])
        // 13 Kasım 2026: 9-10 yazıldı; dört standart, iki uyku kurgusu.
        XCTAssertEqual(coverage[b910], [.learning, .adventure, .bedtime])
    }

    func testCoverageAgreesWithAvailableModes() throws {
        let catalog = try catalog()
        let selector = BlueprintSelector()
        let coverage = selector.modeCoverage(catalog: catalog)
        for band in AgeBandResolver.bands {
            XCTAssertEqual(coverage[band], selector.availableModes(catalog: catalog, ageBand: band), "\(band)")
        }
    }

    /// Bir bantta ulaşılamayan mod uyarıdır, hata değil: mod o bant için düşer.
    ///
    /// H1 (17 Kasım 2026): 3-4 maceraya kavuştu ve gönderilen katalogda eksik
    /// mod kalmadı. Uyarının kendisi hâlâ sınanıyor: 3-4'ün dört macera şekli
    /// çıkarılmış bir katalogda uyarı geri gelir, yalnızca o kesit için.
    func testAModeMissingFromABandIsAWarning() throws {
        let shipped = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        let shippedMissing = shipped.issues(withCode: "mode_unavailable_in_band")
        XCTAssertTrue(shippedMissing.isEmpty, shippedMissing.map(\.message).joined(separator: "\n"))

        let youngAdventure: Set<String> = [
            "bp_adventure_lookingtogether_age3_001", "bp_adventure_lookingback_age3_001",
            "bp_adventure_together_age3_001", "bp_adventure_asking_age3_001",
        ]
        let full = try catalog()
        let reduced = InterestFixtures.rebuilding(
            full, blueprints: full.blueprints.filter { !youngAdventure.contains($0.id.rawValue) })
        let missing = CatalogIntegrityChecker().check(reduced).issues(withCode: "mode_unavailable_in_band")
        XCTAssertFalse(missing.isEmpty)
        XCTAssertTrue(missing.allSatisfy { $0.severity == .warning })
        let messages = missing.map(\.message).joined(separator: "\n")
        XCTAssertTrue(messages.contains("'adventure'") && messages.contains("3-4"), messages)
        XCTAssertFalse(messages.contains("'bedtime'"), messages)
        XCTAssertFalse(messages.contains("'learning'"), messages)
    }

    func testABandWithNoContentIsReportedOnce() throws {
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        let empty = report.issues(withCode: "band_without_content")
        // 7-8 Faz 10'da, 9-10 13 Kasım 2026'da yazıldı; boş bant kalmadı.
        XCTAssertEqual(empty.count, 0, empty.map(\.message).joined(separator: "\n"))
        XCTAssertTrue(empty.allSatisfy { $0.severity == .warning })
        // Boş bant, mod başına ayrıca raporlanmaz.
        let perMode = report.issues(withCode: "mode_unavailable_in_band").map(\.message)
        XCTAssertFalse(perMode.contains { $0.contains("7-8") || $0.contains("9-10") })
    }

    /// Uzunluk yaş bandından gelir: bandını tutmayan blueprint artık hata.
    func testEveryShippedBlueprintHasItsBandsPageCount() throws {
        let catalog = try catalog()
        for blueprint in catalog.blueprints {
            XCTAssertEqual(blueprint.pageCount, blueprint.ageRange.pageCount, blueprint.id.rawValue)
        }
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        XCTAssertTrue(report.issues(withCode: "page_count_off_band").isEmpty)
    }

    func testBandPageCounts() {
        XCTAssertEqual(b34.pageCount, 6)
        XCTAssertEqual(b56.pageCount, 8)
        XCTAssertEqual(b78.pageCount, 8)
        XCTAssertEqual(b910.pageCount, 10)
    }

    // MARK: - Alt seçenek

    /// Yer tutucu dönemi bitti (16 Ekim 2026).
    ///
    /// FAZ 10 `subOption`'ı açıp boş bıraktı ve buradaki test "hiçbir şeyi
    /// değiştirmemeli" diyordu — doğru bir kayıttı, çünkü alanın ne anlama
    /// geleceği henüz ürün kararı değildi. Karar verildi: alan artık bir konu
    /// kimliği ve bir süzgeç (`CatalogStoryTopic`). Test o yüzden gevşetilmedi,
    /// yeni sözleşmeye çevrildi.
    ///
    /// Değişmeyen tek şey: alt seçenek **yokken** masal eskisinin aynısı.
    func testNoSubOptionStillBuildsTheSameStory() throws {
        let catalog = try catalog()
        let composer = OfflineStoryComposer()
        for seed in (0..<6).map({ "sub-\($0)" }) {
            let once = try composer.compose(catalog: catalog, intent: OfflineStoryIntent(
                childName: "Ece", seed: seed, mode: .learning, ageBand: b56))
            let twice = try composer.compose(catalog: catalog, intent: OfflineStoryIntent(
                childName: "Ece", seed: seed, mode: .learning, ageBand: b56, subOption: nil))
            XCTAssertEqual(once.fingerprint, twice.fingerprint, seed)
        }
    }

    /// Tanınmayan bir alt seçenek artık sessizce yok sayılmıyor.
    func testAnUnknownSubOptionIsNoLongerIgnored() throws {
        let catalog = try catalog()
        XCTAssertThrowsError(try OfflineStoryComposer().compose(
            catalog: catalog,
            intent: OfflineStoryIntent(childName: "Ece", seed: "sub-x", mode: .learning,
                                       ageBand: b56, subOption: "x")))
    }

    func testSubOptionDefaultsToNil() {
        XCTAssertNil(OfflineStoryIntent(childName: "Ece", seed: "s").subOption)
    }
}
