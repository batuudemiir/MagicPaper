import CryptoKit
import XCTest
import UIKit
@testable import MagicPaper

final class StorySpotAssetResolverTests: XCTestCase {
    private var root: URL!
    private var bundle: Bundle!
    private let bytes = Data("reviewed-art-revision".utf8)
    private let fileName = "mp-story-spot-test-r1.png"

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".bundle")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let plist: [String: Any] = ["CFBundleIdentifier": "tests.story-art", "CFBundlePackageType": "BNDL"]
        try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            .write(to: root.appendingPathComponent("Info.plist"))
        try bytes.write(to: root.appendingPathComponent(fileName))
        bundle = try XCTUnwrap(Bundle(url: root))
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: root)
        bundle = nil
        root = nil
    }

    private var digest: String { SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined() }

    private func art(schema: Int = 1, policy: Int = 1, file: String? = nil, hash: String? = nil) -> StoryPageArt {
        StoryPageArt(role: "spot", altText: "Bir test nesnesi.", sourceID: "spot.test",
                     schemaVersion: schema, assetRevision: 1, assetDigest: hash ?? digest,
                     styleRevision: "gouache-social-v1", bundledFileName: file ?? fileName,
                     subjectID: "object_test", subjectState: ["intact"], variantIDs: ["test_variant"],
                     authoredSourceFingerprint: "source-v1", bindingPolicyVersion: policy,
                     catalogVersion: "test-catalog")
    }

    func testSavedRevisionResolvesWithoutTodaysSelectionRules() throws {
        let url = try XCTUnwrap(StorySpotAssetResolver.url(for: art(), bundle: bundle))
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    func testUnknownSavedSchemaOrPolicyFailsClosed() {
        XCTAssertNil(StorySpotAssetResolver.url(for: art(schema: 2), bundle: bundle))
        XCTAssertNil(StorySpotAssetResolver.url(for: art(policy: 2), bundle: bundle))
    }

    func testMissingFileOrDigestMismatchDoesNotSubstituteArt() {
        XCTAssertNil(StorySpotAssetResolver.url(for: art(file: "missing-r1.png"), bundle: bundle))
        XCTAssertNil(StorySpotAssetResolver.url(for: art(hash: String(repeating: "0", count: 64)), bundle: bundle))
    }

    func testPathTraversalAndRemoteReferencesAreRejected() {
        for path in ["../" + fileName, "/tmp/" + fileName, "https://example.com/art.png", "folder/art.png", "art.JPG"] {
            XCTAssertFalse(StorySpotAssetResolver.isSafeFileName(path), path)
            XCTAssertNil(StorySpotAssetResolver.url(for: art(file: path), bundle: bundle))
        }
    }

    func testLegacyMetadataDoesNotBecomeBundledArt() {
        let legacy = StoryPageArt(role: "spot", altText: "Eski çizim.", sourceID: "old")
        XCTAssertNil(StorySpotAssetResolver.url(for: legacy, bundle: bundle))
    }
    @MainActor
    func testEveryBundledRevisionDecodesWithPreservedAlpha() async throws {
        let catalog = try XCTUnwrap(StorySpotCatalog.bundled)
        XCTAssertEqual(catalog.assets.count, 12)
        for asset in catalog.assets {
            let saved = StoryPageArt(role: "spot", altText: asset.altText, sourceID: asset.assetID,
                schemaVersion: 1, assetRevision: asset.revision, assetDigest: asset.digest,
                styleRevision: asset.styleRevision, bundledFileName: asset.fileName,
                subjectID: asset.subjectID, subjectState: asset.subjectState,
                variantIDs: ["na_neutral_01"], authoredSourceFingerprint: "reviewed",
                bindingPolicyVersion: 1, catalogVersion: "2.1.0")
            let image = await ReaderImageLoader.shared.image(art: saved, targetPixelWidth: 160)
            let decoded = try XCTUnwrap(image, asset.assetID)
            XCTAssertLessThanOrEqual(max(decoded.size.width, decoded.size.height), 160)
            let alpha = try XCTUnwrap(decoded.cgImage?.alphaInfo)
            XCTAssertTrue([CGImageAlphaInfo.premultipliedFirst, .premultipliedLast, .first, .last].contains(alpha), asset.assetID)
        }
    }

}
