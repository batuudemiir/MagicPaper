import XCTest
import StoryEngine
@testable import MagicPaper

final class CatalogSnapshotStoreTests: XCTestCase {
    func testVerifiedSnapshotIsIdempotentAndChecksBytesOnEveryRead() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CatalogSnapshotStore(root: directory)
        let sources = ContentPackage.bundledSources()
        let version = try ContentCatalogLoader().load().catalog.version
        let payload = try ContentPackage.build(version: version, libraries: sources.libraries, beats: sources.beats)
        let reference = try store.saveVerified(payload: payload)
        XCTAssertEqual(try store.saveVerified(payload: payload), reference)
        XCTAssertEqual(try store.load(reference).catalog.version, version)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path).count, 1)
        try Data("corrupt".utf8).write(to: directory.appendingPathComponent(reference.payloadSHA256 + ".mpcatalog"))
        XCTAssertThrowsError(try store.load(reference))
    }

    func testFailedAtomicWritePreservesPreviouslySavedPayload() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CatalogSnapshotStore(root: directory)
        let sources = ContentPackage.bundledSources()
        let version = try ContentCatalogLoader().load().catalog.version
        let payload = try ContentPackage.build(version: version, libraries: sources.libraries, beats: sources.beats)
        let reference = try store.saveVerified(payload: payload)
        var failing = store
        failing.writeAtomically = { _, _ in throw CocoaError(.fileWriteOutOfSpace) }
        var alternative = payload
        alternative.append(contentsOf: [10])
        XCTAssertThrowsError(try failing.saveVerified(payload: alternative))
        XCTAssertEqual(try store.load(reference).catalog.version, version)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path).count, 1)
    }

    func testInvalidPayloadCreatesNoSnapshot() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        XCTAssertThrowsError(try CatalogSnapshotStore(root: directory).saveVerified(payload: Data("{}".utf8)))
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }
}
