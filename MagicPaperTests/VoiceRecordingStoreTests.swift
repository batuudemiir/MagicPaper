import XCTest
@testable import MagicPaper

/// 33 · Kendi sesin: kayıtların yeri, listesi ve silinmesi.
final class VoiceRecordingStoreTests: XCTestCase {
    private var root: URL!
    private var store: VoiceRecordingStore!

    override func setUp() {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("VoiceTests-\(UUID().uuidString)")
        store = VoiceRecordingStore(root: root)
    }

    override func tearDown() { try? FileManager.default.removeItem(at: root) }

    private func record(_ story: UUID, _ page: Int) throws {
        try Data([1, 2, 3]).write(to: try store.destination(story: story, page: page))
    }

    func testRecordedPagesAreListedInOrderAndFoundByPage() throws {
        let id = UUID()
        try record(id, 3); try record(id, 0); try record(id, 1)
        XCTAssertEqual(store.recordedPages(story: id), [0, 1, 3])
        XCTAssertNotNil(store.recording(story: id, page: 1))
        XCTAssertNil(store.recording(story: id, page: 2))
    }

    func testThePathCarriesOnlyIDsNoTextOrName() throws {
        let id = UUID()
        let url = try store.destination(story: id, page: 4)
        XCTAssertEqual(url.lastPathComponent, "4.m4a")
        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, id.uuidString)
    }

    func testDeletingAPageAStoryAndEverything() throws {
        let a = UUID(), b = UUID()
        try record(a, 0); try record(a, 1); try record(b, 0)
        store.delete(story: a, page: 0)
        XCTAssertEqual(store.recordedPages(story: a), [1])
        store.delete(story: a)
        XCTAssertEqual(store.recordedStories(), [b])
        store.deleteAll()
        XCTAssertTrue(store.recordedStories().isEmpty)
    }

    func testRecordingsAreKeptOutOfBackup() throws {
        _ = try store.destination(story: UUID(), page: 0)
        let values = try root.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(values.isExcludedFromBackup, true)
    }
}
