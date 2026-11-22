import XCTest
import StoryEngine
@testable import MagicPaper

final class HistoricalCatalogResolverTests: XCTestCase {
    func testMissingAndUnknownSourcesNeverUseCurrentCatalog() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let resolver = HistoricalCatalogResolver(store: CatalogSnapshotStore(root: directory))
        let reference = try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: "a", count: 64))
        if case .missing = resolver.resolve(reference: reference) {} else { XCTFail("Expected missing") }
        if case .missing = resolver.resolveLegacy(catalogVersion: "2.1.0") {} else { XCTFail("Expected missing") }
        let metadata = try JSONDecoder().decode(ContentSourceMetadata.self, from: Data(#"{"bad":true}"#.utf8))
        if case .corrupt = resolver.resolve(metadata: metadata) {} else { XCTFail("Expected corrupt") }
        let future = try ContentSourceReference(schemaVersion: 99, catalogVersion: "2.1.0", payloadSHA256: reference.payloadSHA256)
        if case .unsupported = resolver.resolve(reference: future) {} else { XCTFail("Expected unsupported") }
    }

    func testCompatibilityWithTwoCandidatesStaysAmbiguous() throws {
        let first = try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: "a", count: 64))
        let second = try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: "b", count: 64))
        let manifest = LegacyCatalogCompatibility(verifiedMappings: ["2.1.0": [first, second]])
        let resolver = HistoricalCatalogResolver(compatibility: manifest)
        if case .ambiguous = resolver.resolveLegacy(catalogVersion: "2.1.0") {} else { XCTFail("Expected ambiguous") }
    }

    func testBundledExactResolutionRequiresMatchingDigest() throws {
        let sources = ContentPackage.bundledSources()
        let version = try ContentCatalogLoader().load().catalog.version
        let payload = try ContentPackage.build(version: version, libraries: sources.libraries, beats: sources.beats)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CatalogSnapshotStore(root: directory)
        let reference = try store.saveVerified(payload: payload)
        try store.eraseAll()
        let resolver = HistoricalCatalogResolver(store: store, bundledPayload: payload)
        if case .exact(let result, let resolved) = resolver.resolve(reference: reference) {
            XCTAssertEqual(result.catalog.version, version)
            XCTAssertEqual(resolved, reference)
        } else { XCTFail("Expected exact bundle") }
        let other = try ContentSourceReference(catalogVersion: version, payloadSHA256: String(repeating: "a", count: 64))
        if case .missing = resolver.resolve(reference: other) {} else { XCTFail("Same version must not substitute") }
    }
}
