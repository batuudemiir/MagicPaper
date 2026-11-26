import XCTest
@testable import StoryEngine

final class ContentSourceReferenceTests: XCTestCase {
    func testReferenceRoundTripAndDigestIdentity() throws {
        let first = try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: "a", count: 64))
        let second = try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: "b", count: 64))
        XCTAssertNotEqual(first, second)
        XCTAssertEqual(first, try JSONDecoder().decode(ContentSourceReference.self, from: JSONEncoder().encode(first)))
        for digest in ["", "abc", String(repeating: "z", count: 64)] {
            XCTAssertThrowsError(try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: digest))
        }
    }

    func testUnknownAndMalformedMetadataPreserveAllFields() throws {
        for source in [
            #"{"schemaVersion":99,"catalogVersion":"2.1.0","packageSchemaVersion":2,"payloadSHA256":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","engineBehaviorID":"offline-legacy-v1","future":[true,null,12]}"#,
            #"{"schemaVersion":"broken","extra":{"keep":"value"}}"#,
            #"["unexpected",null,42]"#
        ] {
            let bytes = Data(source.utf8)
            let metadata = try JSONDecoder().decode(ContentSourceMetadata.self, from: bytes)
            XCTAssertNil(metadata.reference)
            let encoded = try JSONEncoder().encode(metadata)
            XCTAssertEqual(try JSONDecoder().decode(ContentSourceMetadata.self, from: encoded), metadata)
        }
    }

    func testFutureEnvelopeRemainsUnsupportedWithoutCurrentFields() throws {
        let metadata = try JSONDecoder().decode(ContentSourceMetadata.self, from: Data(#"{"schemaVersion":99,"future":true}"#.utf8))
        XCTAssertEqual(metadata.status, .unsupported)
        XCTAssertNil(metadata.reference)
    }

    func testKnownMetadataAndUnsupportedBehavior() throws {
        let known = try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: "a", count: 64))
        XCTAssertEqual(ContentSourceMetadata(known: known).reference, known)
        let future = try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: "a", count: 64), engineBehaviorID: "future")
        XCTAssertEqual(ContentSourceMetadata(known: future).status, .unsupported)
    }
}
