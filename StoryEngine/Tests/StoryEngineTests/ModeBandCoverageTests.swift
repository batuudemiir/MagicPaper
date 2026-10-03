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
        XCTAssertEqual(coverage[b34], [.bedtime])
        XCTAssertEqual(coverage[b56], [.learning, .adventure, .bedtime])
        XCTAssertEqual(coverage[b78], [])
        XCTAssertEqual(coverage[b910], [])
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
    func testAModeMissingFromABandIsAWarning() throws {
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        let missing = report.issues(withCode: "mode_unavailable_in_band")
        XCTAssertFalse(missing.isEmpty)
        XCTAssertTrue(missing.allSatisfy { $0.severity == .warning })
        let messages = missing.map(\.message).joined(separator: "\n")
        XCTAssertTrue(messages.contains("'learning'") && messages.contains("3-4"), messages)
        XCTAssertTrue(messages.contains("'adventure'") && messages.contains("3-4"), messages)
        XCTAssertFalse(messages.contains("'bedtime'"), messages)
    }

    func testABandWithNoContentIsReportedOnce() throws {
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        let empty = report.issues(withCode: "band_without_content")
        XCTAssertEqual(empty.count, 2, empty.map(\.message).joined(separator: "\n"))
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

    /// `subOption` yalnızca yer tutucu: bugün hiçbir şeyi değiştirmemeli.
    func testSubOptionDoesNotChangeTheStoryYet() throws {
        let catalog = try catalog()
        let composer = OfflineStoryComposer()
        for seed in (0..<6).map({ "sub-\($0)" }) {
            let plain = try composer.compose(catalog: catalog, intent: OfflineStoryIntent(
                childName: "Ece", seed: seed, mode: .learning, ageBand: b56))
            let withOption = try composer.compose(catalog: catalog, intent: OfflineStoryIntent(
                childName: "Ece", seed: seed, mode: .learning, ageBand: b56, subOption: "x"))
            XCTAssertEqual(plain.fingerprint, withOption.fingerprint, seed)
        }
    }

    func testSubOptionDefaultsToNil() {
        XCTAssertNil(OfflineStoryIntent(childName: "Ece", seed: "s").subOption)
    }
}
