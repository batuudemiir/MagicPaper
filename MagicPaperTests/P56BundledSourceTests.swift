import XCTest
import CryptoKit
import StoryEngine
@testable import MagicPaper

/// B2 (beş arkadaş B hattı): uygulamayla gelen P56 payload'ı tam baytlarıyla doğrulanır;
/// bozuk ya da eksikse hata verir, güncel içerikle yer değiştirmez.
final class P56BundledSourceTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func contentCopy() throws -> Data {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        return try Data(contentsOf: root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-v1/payload.json"))
    }

    func testBundledBytesMatchPinnedAndContentCopy() throws {
        let bundled = try P56BundledSource.bundledBytes()
        XCTAssertEqual(digest(bundled), P56PinnedSource.sha256)
        XCTAssertEqual(bundled, try contentCopy(), "uygulamadaki kopya içerik kaynağıyla bayt bayt aynı")
    }

    func testLoadReturnsVerifiedReference() throws {
        let source = P56BundledSource(store: P56SnapshotStore(root: directory))
        let reference = try source.load()
        XCTAssertEqual(reference.payloadSHA256, P56PinnedSource.sha256)
        XCTAssertEqual(reference.engineBehaviorID, P56Engine.behaviorID)
        XCTAssertEqual(reference.packageVersion, P56BundledSource.packageVersion)
        XCTAssertEqual(try P56SnapshotStore(root: directory).load(reference).sourceReference, reference)
    }

    func testLoadIsIdempotent() throws {
        let source = P56BundledSource(store: P56SnapshotStore(root: directory))
        XCTAssertEqual(try source.load(), try source.load())
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path).count, 1)
    }

    func testTamperedBytesThrowAndStoreNothing() throws {
        var bytes = try P56BundledSource.bundledBytes()
        bytes[bytes.startIndex + 10] ^= 0x01
        let source = P56BundledSource(bytes: { bytes }, store: P56SnapshotStore(root: directory))
        XCTAssertThrowsError(try source.load())
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path), "bozuk kaynak arşive yazılmaz")
    }

    func testMissingResourceThrows() {
        let source = P56BundledSource(bytes: { throw P56BundledSource.SourceError.missingResource },
                                      store: P56SnapshotStore(root: directory))
        XCTAssertThrowsError(try source.load()) { error in
            XCTAssertEqual(error as? P56BundledSource.SourceError, .missingResource)
        }
    }

    func testEmptyBundleHasNoResource() {
        XCTAssertThrowsError(try P56BundledSource.bundledBytes(in: Bundle(for: Self.self))) { error in
            XCTAssertEqual(error as? P56BundledSource.SourceError, .missingResource)
        }
    }
}
