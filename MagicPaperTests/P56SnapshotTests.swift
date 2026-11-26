import XCTest
import CryptoKit
import StoryEngine
@testable import MagicPaper

final class P56SnapshotTests: XCTestCase {
    private func payload() throws -> Data {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        return try Data(contentsOf: root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-v1/payload.json"))
    }

    private func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    func testExactSnapshotRoundTripAndTamperingCannotFallBack() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = P56SnapshotStore(root: directory)
        let bytes = try payload()
        let reference = try store.save(payload: bytes, expectedSHA256: digest(bytes))
        XCTAssertEqual(try store.load(reference).sourceReference, reference)
        XCTAssertEqual(try store.save(payload: bytes, expectedSHA256: digest(bytes)), reference)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path).count, 1)
        try Data("corrupt".utf8).write(to: directory.appendingPathComponent(reference.payloadSHA256 + ".p56catalog"))
        XCTAssertThrowsError(try store.load(reference))
        // Aynı özetin doğrulanmış baytları bozuk kaydı onarır; başka içerik yerine geçmez.
        XCTAssertEqual(try store.save(payload: bytes, expectedSHA256: digest(bytes)), reference)
        XCTAssertEqual(try store.load(reference).sourceReference, reference)
    }

    func testMissingSourceAndFailedWritesNeverSubstituteCurrentContent() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        var store = P56SnapshotStore(root: directory)
        let bytes = try payload()
        let reference = try store.save(payload: bytes, expectedSHA256: digest(bytes))
        var alternative = bytes
        alternative.append(10)
        store.writeAtomically = { _, _ in throw CocoaError(.fileWriteOutOfSpace) }
        XCTAssertThrowsError(try store.save(payload: alternative, expectedSHA256: digest(alternative)))
        XCTAssertEqual(try store.load(reference).sourceReference, reference)
        let missing = P56SourceReference(payloadSHA256: String(repeating: "a", count: 64))
        XCTAssertThrowsError(try store.load(missing))
    }

    func testUntrustedBytesAndUnsupportedBehaviorCreateNoSnapshot() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = P56SnapshotStore(root: directory)
        XCTAssertThrowsError(try store.save(payload: payload(), expectedSHA256: String(repeating: "0", count: 64)))
        let invalid = P56SourceReference(payloadSHA256: "../../escape", engineBehaviorID: "future")
        XCTAssertThrowsError(try store.load(invalid))
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }

    /// Kod düzeltmeleri (26 Kasım): doğrulanmış baytlar arşive yeniden çözülmeden yazılır;
    /// yalnız özet denetlenir, sağlam kayıt yerinde kalır, bozuk kayıt yenilenir.
    func testVerifiedBytesAreArchivedWithoutDecodingAgain() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        var store = P56SnapshotStore(root: directory)
        let bytes = try payload()
        let reference = try P56PackageLoader.load(payload: bytes, expectedSHA256: digest(bytes)).sourceReference
        try store.save(data: bytes, reference: reference)
        XCTAssertEqual(try store.load(reference).sourceReference, reference)

        var writes = 0
        store.writeAtomically = { data, url in writes += 1; try data.write(to: url, options: .atomic) }
        try store.save(data: bytes, reference: reference)
        XCTAssertEqual(writes, 0, "sağlam kayıt yeniden yazılmaz")

        let file = directory.appendingPathComponent(reference.payloadSHA256 + ".p56catalog")
        try Data("corrupt".utf8).write(to: file)
        try store.save(data: bytes, reference: reference)
        XCTAssertEqual(writes, 1, "bozuk kayıt doğrulanmış baytlarla yenilenir")
        XCTAssertEqual(try store.load(reference).sourceReference, reference)

        var other = bytes
        other.append(10)
        XCTAssertThrowsError(try store.save(data: other, reference: reference), "özeti tutmayan bayt yazılmaz")
    }

    /// Pin geçişleri (v3, v4; 26 Kasım): arşiv bütün sürümleri tanır, eskiler yerinde kalır.
    func testArchiveKeepsEveryRuntimeVersion() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = P56SnapshotStore(root: directory)
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let versions = ["v1", "v2", "v3", "v4"]
        var references: [P56SourceReference] = []
        for version in versions {
            let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-\(version)/payload.json"))
            let reference = try store.save(payload: bytes, expectedSHA256: digest(bytes))
            XCTAssertEqual(reference.packageVersion, "five-friends-56-runtime-\(version)")
            references.append(reference)
        }
        XCTAssertEqual(references[0].payloadSHA256, P56PinnedSource.v1SHA256)
        XCTAssertEqual(references[1].payloadSHA256, P56PinnedSource.v2SHA256)
        XCTAssertTrue(references.contains { $0.packageVersion == P56PinnedSource.packageVersion
            && $0.payloadSHA256 == P56PinnedSource.sha256 }, "etkin pin arşivde")
        for reference in references { XCTAssertEqual(try store.load(reference).sourceReference, reference) }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path).count, versions.count)
    }
}
