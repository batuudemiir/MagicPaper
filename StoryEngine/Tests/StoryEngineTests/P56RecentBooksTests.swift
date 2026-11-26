import Foundation
import XCTest
@testable import StoryEngine

/// Tekrar çözümü (Batuhan, 26 Kasım 2026): motor çocuğun son okuduğu kitapları
/// atlar; hücrede okunmamış kitap kalmayınca en uzun süre önce okunanı verir.
final class P56RecentBooksTests: XCTestCase {
    private static let package: Result<P56Package, Error> = Result {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let bytes = try Data(contentsOf: root.appendingPathComponent(
            "Content/Pilots/\(P56PinnedSource.packageVersion)/payload.json"))
        return try P56PackageLoader.load(payload: bytes, expectedSHA256: P56PinnedSource.sha256)
    }

    private func request(seed: UInt64, recent: [String], safety: ContentSafety? = nil) -> P56Request {
        P56Request(childID: "recent-fixture", name: "İrem", age: 6, seed: seed, mode: .adventure,
                   companionID: "companion_hedgehog_pilot_001", contentSafety: safety, recentBookIDs: recent)
    }

    private func cellBooks(safety: ContentSafety? = nil) throws -> [String] {
        P56Support.candidates(for: request(seed: 0, recent: [], safety: safety), package: try Self.package.get()).map(\.id)
    }

    /// Her seferinde son okunanlar verilirse hücredeki her kitap tekrarsız bir kez çıkar.
    func testEveryBookInTheCellBeforeAnyRepeat() throws {
        let composer = P56StoryComposer(package: try Self.package.get())
        for safety in [nil, ContentSafety.mostProtective] {
            let cell = try cellBooks(safety: safety)
            XCTAssertGreaterThan(cell.count, 1)
            var read: [String] = []
            for seed in 0..<UInt64(cell.count) {
                let book = try composer.compose(request(seed: seed * 7919, recent: read, safety: safety)).bookID
                XCTAssertFalse(read.contains(book), "\(book) tekrar etti, \(read.count). okuma")
                read.insert(book, at: 0)
            }
            XCTAssertEqual(Set(read), Set(cell))
        }
    }

    /// Hepsi okunduysa en uzun süre önce okunan gelir; tohum bunu değiştirmez.
    func testWhenAllAreReadTheOldestComesBack() throws {
        let composer = P56StoryComposer(package: try Self.package.get())
        let cell = try cellBooks()
        let recent = cell.reversed() as [String]   // cell[0] en eski
        for seed in [UInt64(0), 1, 99, 123_456] {
            XCTAssertEqual(try composer.compose(request(seed: seed, recent: recent)).bookID, cell[0])
        }
    }

    /// Okuma geçmişi destek koşulu değildir; başka hücrenin kitapları seçimi etkilemez.
    func testHistoryNeverMakesARequestUnsupportedAndIgnoresOtherCells() throws {
        let package = try Self.package.get()
        let cell = try cellBooks()
        XCTAssertTrue(P56Support.unsupportedReasons(for: request(seed: 1, recent: cell), package: package).isEmpty)
        let other = package.books.filter { !cell.contains($0.id) }.map(\.id)
        let composer = P56StoryComposer(package: package)
        XCTAssertEqual(try composer.compose(request(seed: 5, recent: other)).bookID,
                       try composer.compose(request(seed: 5, recent: [])).bookID)
    }

    func testEmptyHistoryKeepsTodaysDeterministicDraw() throws {
        let composer = P56StoryComposer(package: try Self.package.get())
        let today = P56Request(childID: "recent-fixture", name: "İrem", age: 6, seed: 42, mode: .adventure,
                               companionID: "companion_hedgehog_pilot_001")
        XCTAssertEqual(try composer.compose(today).bookID, try composer.compose(request(seed: 42, recent: [])).bookID)
    }
}
