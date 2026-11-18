import XCTest
@testable import StoryEngine

/// H0 (`docs/HAVUZ_PLANI.md`): the pool's coverage, printed and locked.
///
/// The floors below are minimums. A content change that lowers a cell breaks
/// this test; one that raises it does not. A cell that has not reached the
/// plan's target is locked at today's value, and the phase that fills it
/// raises its floor to the target.
///
/// Target, in every band at the most protective setting: adventure ≥ 4,
/// learning ≥ 4, bedtime ≥ 3 blueprints, ≥ 3 mechanisms each, and a series
/// continuation.
final class CoverageReportTests: XCTestCase {

    private struct Floor {
        let blueprints: Int
        let mechanisms: Int
        let continues: Bool
    }

    private static let b34 = AgeBand(lowerBound: 3, upperBound: 4)
    private static let b56 = AgeBand(lowerBound: 5, upperBound: 6)
    private static let b78 = AgeBand(lowerBound: 7, upperBound: 8)
    private static let b910 = AgeBand(lowerBound: 9, upperBound: 10)

    /// The most protective setting (the default). H0 values: today's, from
    /// the plan's table (17 Kasım 2026); none of these cells is at target yet
    /// except 5-6 learning and 5-6 bedtime. H1 (17 Kasım 2026) raised every
    /// adventure cell to the target's blueprints and mechanisms (calm shapes);
    /// continuation stays where it was, H1 wrote no series. H2 (18 Kasım 2026)
    /// raised every learning cell to the target: 3-4 gained one shape each of
    /// `unexplained`, `misreading` and `appeal` (5/5 by the Python estimate),
    /// 7-8 and 9-10 one `appeal` and one `charge` (4/4).
    private static let mostProtective: [String: Floor] = [
        "3-4 adventure": .init(blueprints: 4, mechanisms: 3, continues: false),
        "3-4 learning": .init(blueprints: 4, mechanisms: 3, continues: false),
        "3-4 bedtime": .init(blueprints: 2, mechanisms: 2, continues: true),
        "5-6 adventure": .init(blueprints: 4, mechanisms: 3, continues: true),
        "5-6 learning": .init(blueprints: 12, mechanisms: 3, continues: true),
        "5-6 bedtime": .init(blueprints: 3, mechanisms: 3, continues: true),
        "7-8 adventure": .init(blueprints: 4, mechanisms: 3, continues: false),
        "7-8 learning": .init(blueprints: 4, mechanisms: 3, continues: false),
        "7-8 bedtime": .init(blueprints: 2, mechanisms: 2, continues: false),
        "9-10 adventure": .init(blueprints: 4, mechanisms: 3, continues: false),
        "9-10 learning": .init(blueprints: 4, mechanisms: 3, continues: false),
        "9-10 bedtime": .init(blueprints: 2, mechanisms: 2, continues: false),
    ]

    private func report() throws -> CoverageReport {
        CoverageReport(catalog: try ContentCatalogLoader().load().catalog)
    }

    /// Prints the matrix for a person to read, and checks it is whole.
    func testTheMatrixIsPrintedAndComplete() throws {
        let report = try report()
        print("\n" + report.table + "\n")
        XCTAssertEqual(report.cells.count, AgeBandResolver.bands.count * StoryMode.allCases.count
                       * CoverageReport.Safety.allCases.count)
    }

    func testNoCellFallsBelowItsFloor() throws {
        let report = try report()
        for band in [Self.b34, Self.b56, Self.b78, Self.b910] {
            for mode in StoryMode.allCases {
                let key = "\(band) \(mode.rawValue)"
                let floor = try XCTUnwrap(Self.mostProtective[key], key)
                let cell = try XCTUnwrap(report.cell(band: band, mode: mode, safety: .mostProtective), key)
                XCTAssertGreaterThanOrEqual(cell.blueprints.count, floor.blueprints, "\(key): \(cell.blueprints)")
                XCTAssertGreaterThanOrEqual(cell.mechanisms.count, floor.mechanisms, "\(key): \(cell.mechanisms.sorted())")
                if floor.continues { XCTAssertTrue(cell.continues, "\(key): lost its series continuation") }
            }
        }
    }

    /// No filter never offers less than the most protective setting.
    func testTheUnfilteredSettingNeverOffersLess() throws {
        let report = try report()
        for band in AgeBandResolver.bands {
            for mode in StoryMode.allCases {
                let calm = try XCTUnwrap(report.cell(band: band, mode: mode, safety: .mostProtective))
                let open = try XCTUnwrap(report.cell(band: band, mode: mode, safety: .unfiltered))
                XCTAssertTrue(Set(calm.blueprints).isSubset(of: Set(open.blueprints)), "\(band) \(mode)")
            }
        }
    }

    /// The topic gate and the report count mechanisms the same way: a topic
    /// is offered only where its cell has at least three.
    func testOfferedTopicsSitInCellsWithEnoughMechanisms() throws {
        for cell in try report().cells where !cell.topics.isEmpty {
            XCTAssertGreaterThanOrEqual(cell.mechanisms.count, CatalogStoryTopic.minimumMechanisms,
                                        "\(cell.band) \(cell.mode) \(cell.safety)")
        }
    }
}
