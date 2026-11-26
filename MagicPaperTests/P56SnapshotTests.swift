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
        XCTAssertThrowsError(try store.save(payload: bytes, expectedSHA256: digest(bytes)))
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
        XCTAssertFalse(P56InternalService.productionEnabled)
    }

    func testInternalReplayKeepsExactSourceAndPersonalization() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = P56InternalService(store: P56SnapshotStore(root: directory))
        let bytes = try payload()
        let reference = try service.prepare(payload: bytes, expectedSHA256: digest(bytes))
        let request = P56Request(childID: "synthetic-child", name: "Işıl", age: 5, seed: 42)
        let draft = try service.compose(request, source: reference)
        XCTAssertEqual(draft.sourceReference, reference)
        XCTAssertEqual(draft, try service.compose(request, source: reference))
        XCTAssertTrue(draft.pages.contains { $0.text.contains("Işıl") })
        XCTAssertFalse(draft.pages.contains { $0.text.contains("Deniz") })
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path).count, 1)
        try Data("lost".utf8).write(to: directory.appendingPathComponent(reference.payloadSHA256 + ".p56catalog"))
        XCTAssertThrowsError(try service.compose(request, source: reference))
    }
}
