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

    /// Okuma geçmişi destek koşulu değildir; başka modun kitapları seçimi etkilemez.
    func testHistoryNeverMakesARequestUnsupportedAndIgnoresOtherCells() throws {
        let package = try Self.package.get()
        let cell = try cellBooks()
        XCTAssertTrue(P56Support.unsupportedReasons(for: request(seed: 1, recent: cell), package: package).isEmpty)
        let other = package.books.filter { $0.mode != .adventure }.map(\.id)
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

    // MARK: - Daha akıllı seçim (27 Kasım 2026)

    /// Yalnız göz atılan (ilk üçte birde kapatılan) kitap, hiç verilmemiş
    /// kitaplar bitince, okunanlardan önce gelir.
    func testGlancedBooksComeBackBeforeReadOnes() throws {
        let package = try Self.package.get()
        let composer = P56StoryComposer(package: package)
        let cell = try cellBooks()
        let glanced = cell[2]
        for seed in [UInt64(0), 3, 77, 9_001] {
            let book = try composer.compose(P56Request(childID: "recent-fixture", name: "İrem", age: 6, seed: seed,
                mode: .adventure, companionID: "companion_hedgehog_pilot_001",
                recentBookIDs: cell, glancedBookIDs: [glanced])).bookID
            XCTAssertEqual(book, glanced)
        }
    }

    /// Başka arkadaşla okunan son olay örgüsü, yeni arkadaşla hemen tekrar anlatılmaz.
    func testLastPlotInTheModeIsNotRetoldWithAnotherFriend() throws {
        let package = try Self.package.get()
        let composer = P56StoryComposer(package: package)
        let foxBooks = package.books.filter { $0.mode == .adventure && $0.companionID == "companion_fox_pilot_001" }
        for last in foxBooks {
            for seed in UInt64(0)..<12 {
                let book = try composer.compose(request(seed: seed, recent: [last.id]))
                XCTAssertNotEqual(book.structureID, last.structureID, "\(last.id) sonrası \(book.bookID)")
            }
        }
    }

    /// Ağırlıklar eşitse çekiliş bugünküyle aynıdır; arkadaş seçilmişse ağırlık bir şey değiştirmez.
    func testEqualWeightsKeepTheDrawAndChosenFriendIgnoresWeights() throws {
        let composer = P56StoryComposer(package: try Self.package.get())
        for seed in UInt64(0)..<20 {
            let plain = P56Request(childID: "w", name: "İrem", age: 6, seed: seed, mode: .bedtime)
            let even = P56Request(childID: "w", name: "İrem", age: 6, seed: seed, mode: .bedtime,
                                  companionWeights: ["companion_fox_pilot_001": 2, "companion_bear_001": 2])
            XCTAssertEqual(try composer.compose(plain).bookID, try composer.compose(even).bookID)
            let chosen = try composer.compose(request(seed: seed, recent: []))
            let weighted = try composer.compose(P56Request(childID: "recent-fixture", name: "İrem", age: 6, seed: seed,
                mode: .adventure, companionID: "companion_hedgehog_pilot_001",
                companionWeights: ["companion_hedgehog_pilot_001": 3]))
            XCTAssertEqual(chosen.bookID, weighted.bookID)
        }
    }

    /// Sürpriz'de sonuna kadar okunan arkadaş daha sık, yarıda bırakılan daha seyrek gelir; hiçbiri kapanmaz.
    func testSurpriseLeansTowardLovedFriendsWithoutShuttingAnyOut() throws {
        let composer = P56StoryComposer(package: try Self.package.get())
        let weights = ["companion_owl_pilot_001": 3, "companion_city_cat_001": 1]
        var counts: [String: Int] = [:]
        for seed in UInt64(0)..<600 {
            let story = try composer.compose(P56Request(childID: "w", name: "İrem", age: 6, seed: seed &* 2_654_435_761,
                                                        mode: .learning, companionWeights: weights))
            counts[story.companion.id, default: 0] += 1
        }
        XCTAssertEqual(counts.count, 5, "her arkadaş gelebilir: \(counts)")
        XCTAssertGreaterThan(counts["companion_owl_pilot_001", default: 0], counts["companion_fox_pilot_001", default: 0])
        XCTAssertGreaterThan(counts["companion_fox_pilot_001", default: 0], counts["companion_city_cat_001", default: 0])
    }
}
