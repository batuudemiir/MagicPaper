import XCTest
@testable import StoryEngine

/// Bir çocuğun art arda okuduğu masallarda tekrar (A0, 20 Kasım 2026).
///
/// Eşitlik değil eşik: içerik turu tekrarı kötüleştirirse kırılır, iyileştirirse
/// geçer; iyileşme günlüğe yazılır ve eşik yukarı çekilir. Ölçüm: yaş başına
/// 3 çocuk × 100 masal, modlar dönüşümlü, satır penceresi 20.
final class ReadingSequenceTests: XCTestCase {

    private struct Floor {
        let band: (Int, Int)
        /// Satırlarının yarısı tanıdık olan ilk masal, çocuklar arasında en erken.
        let halfFamiliarAtLeast: Int
        /// 4-10. masallarda tanıdık satır oranı en çok.
        let earlyFamiliarAtMost: Double
    }

    // 20 Kasım 2026 ölçümü (W=20): 3-4 yarı 9 / erken %23; 5-6 13 / %11;
    // 7-8 10 / %16; 9-10 14 / %7. Pay: iki masal, beş puan.
    private let floors = [
        Floor(band: (3, 4), halfFamiliarAtLeast: 7, earlyFamiliarAtMost: 0.28),
        Floor(band: (5, 6), halfFamiliarAtLeast: 11, earlyFamiliarAtMost: 0.16),
        Floor(band: (7, 8), halfFamiliarAtLeast: 8, earlyFamiliarAtMost: 0.21),
        Floor(band: (9, 10), halfFamiliarAtLeast: 12, earlyFamiliarAtMost: 0.12)
    ]

    func testRepetitionDoesNotGetWorse() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        for floor in floors {
            let band = AgeBand(lowerBound: floor.band.0, upperBound: floor.band.1)
            let report = ReadingSequenceReport.measure(catalog: catalog, band: band)
            let label = "\(floor.band.0)-\(floor.band.1)"
            XCTAssertEqual(report.failures, 0, label)
            XCTAssertEqual(report.exactDuplicates, 0, label)
            XCTAssertGreaterThanOrEqual(report.firstHalfFamiliar.min() ?? 0, floor.halfFamiliarAtLeast, label)
            XCTAssertLessThanOrEqual(report.familiar(3..<10), floor.earlyFamiliarAtMost, label)
            print(String(format: "reading sequence %@: plot repeat %@, half familiar %@, "
                         + "familiar 4-10 %.0f%%, 11-25 %.0f%%, 51-100 %.0f%%",
                         label, "\(report.firstPlotRepeat)", "\(report.firstHalfFamiliar)",
                         100 * report.familiar(3..<10), 100 * report.familiar(10..<25),
                         100 * report.familiar(50..<100)))
        }
    }

    /// Geçmiş yokken satır penceresinin uzunluğu hiçbir şeyi değiştirmez.
    func testTheLineWindowIsLongerThanTheContentWindow() {
        XCTAssertGreaterThan(SelectionScoring.lineCooldownWindow, SelectionScoring.cooldownWindow)
        XCTAssertEqual(SelectionScoring.historyWindow, SelectionScoring.lineCooldownWindow)
        XCTAssertEqual(SelectionScoring.variantWeight(id: ContentID("x"), recent: []), 1)
        XCTAssertEqual(SelectionScoring.variantWeight(
            id: ContentID("x"), recent: Array(repeating: [], count: 19) + [[ContentID("x")]]),
            SelectionScoring.cooled(storiesAgo: 19, cooldown: 1, window: SelectionScoring.lineCooldownWindow))
        XCTAssertLessThan(SelectionScoring.variantWeight(
            id: ContentID("x"), recent: Array(repeating: [], count: 19) + [[ContentID("x")]]), 1)
    }
}
