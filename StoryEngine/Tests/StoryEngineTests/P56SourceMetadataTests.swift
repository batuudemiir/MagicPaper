import XCTest
@testable import StoryEngine

final class P56SourceMetadataTests: XCTestCase {
    func testP56RoundTripUsesOnlyExactSourceFields() throws {
        let reference = try loadP56ContractPackage().sourceReference
        let metadata = ContentSourceMetadata(p56: reference)
        XCTAssertEqual(metadata.p56Reference, reference)
        XCTAssertNil(metadata.reference)
        XCTAssertEqual(metadata.status, .unsupported)
        let bytes = try JSONEncoder().encode(metadata)
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        XCTAssertEqual(Set(fields.keys), ["schemaVersion", "packageVersion", "payloadSHA256", "engineBehaviorID"])
        XCTAssertEqual(try JSONDecoder().decode(ContentSourceMetadata.self, from: bytes).p56Reference, reference)
    }

    func testBothRuntimeVersionsKeepTheirDistinctReferenceIdentity() throws {
        for version in ["five-friends-56-runtime-v1", "five-friends-56-runtime-v2"] {
            let digest = version.hasSuffix("v1") ? P56PinnedSource.v1SHA256 : P56PinnedSource.sha256
            let reference = P56SourceReference(packageVersion: version, payloadSHA256: digest)
            let metadata = ContentSourceMetadata(p56: reference)
            XCTAssertEqual(metadata.p56Reference, reference)
            XCTAssertEqual(metadata.status, .unsupported)
            XCTAssertNil(metadata.reference)
            XCTAssertEqual(try JSONDecoder().decode(ContentSourceMetadata.self,
                from: JSONEncoder().encode(metadata)).p56Reference, reference)
        }
    }

    func testMalformedAndFutureSourcesRemainLosslessAndNeverResolve() throws {
        let base: [String: Any] = ["schemaVersion": 1, "packageVersion": "five-friends-56-runtime-v1",
            "payloadSHA256": P56PinnedSource.v1SHA256, "engineBehaviorID": P56Engine.behaviorID]
        let cases: [([String: Any], ContentSourceMetadata.Status)] = [
            (["payloadSHA256": "bad"], .malformed), (["payloadSHA256": String(repeating: "A", count: 64)], .malformed),
            (["packageVersion": 3], .malformed), (["schemaVersion": "1"], .malformed),
            (["schemaVersion": 2], .unsupported), (["engineBehaviorID": "offline-p56-v2"], .unsupported),
            (["packageVersion": "future-package"], .unsupported)
        ]
        for (changes, status) in cases {
            let fields = base.merging(changes) { _, new in new }
            let metadata = try JSONDecoder().decode(ContentSourceMetadata.self,
                from: JSONSerialization.data(withJSONObject: fields))
            XCTAssertEqual(metadata.status, status)
            XCTAssertNil(metadata.p56Reference)
            XCTAssertNil(metadata.reference)
            XCTAssertEqual(try JSONDecoder().decode(ContentSourceMetadata.self,
                from: JSONEncoder().encode(metadata)), metadata)
        }
        for raw in ["null", "{}", #"{"engineBehaviorID":"offline-p56-v1"}"#] {
            let metadata = try JSONDecoder().decode(ContentSourceMetadata.self, from: Data(raw.utf8))
            XCTAssertEqual(metadata.status, .malformed)
            XCTAssertNil(metadata.p56Reference)
        }
        let future = try JSONDecoder().decode(ContentSourceMetadata.self,
            from: Data(#"{"engineBehaviorID":"offline-p56-v2","unknown":[true,null]}"#.utf8))
        XCTAssertEqual(future.status, .unsupported)
        XCTAssertNil(future.p56Reference)
    }

    func testLegacyExtensionFieldsKeepOriginalClassification() throws {
        let fields: [String: Any] = ["schemaVersion": 1, "catalogVersion": "2.1.0", "packageSchemaVersion": 2,
            "payloadSHA256": String(repeating: "a", count: 64), "engineBehaviorID": "offline-legacy-v1",
            "packageVersion": "unrelated", "future": ["opaque": true]]
        let metadata = try JSONDecoder().decode(ContentSourceMetadata.self,
            from: JSONSerialization.data(withJSONObject: fields))
        XCTAssertEqual(metadata.status, .known)
        XCTAssertNotNil(metadata.reference)
        XCTAssertNil(metadata.p56Reference)
        XCTAssertEqual(try JSONDecoder().decode(ContentSourceMetadata.self,
            from: JSONEncoder().encode(metadata)), metadata)
        let malformed = try JSONDecoder().decode(ContentSourceMetadata.self,
            from: Data(#"{"engineBehaviorID":"unrelated-future"}"#.utf8))
        XCTAssertEqual(malformed.status, .malformed)
    }

    func testLegacySourceNeverBackfillsP56Reference() throws {
        let legacy = try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: "a", count: 64))
        let metadata = ContentSourceMetadata(known: legacy)
        XCTAssertEqual(metadata.reference, legacy)
        XCTAssertEqual(metadata.status, .known)
        XCTAssertNil(metadata.p56Reference)
    }
}
