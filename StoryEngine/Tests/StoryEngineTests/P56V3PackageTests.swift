import Foundation
import XCTest
@testable import StoryEngine

final class P56V3PackageTests: XCTestCase {
    private func payload(_ version: Int = 3) throws -> Data {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try Data(contentsOf: root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-v\(version)/payload.json"))
    }

    private func rejected(_ change: (inout [String: Any]) throws -> Void) throws {
        let control = try payload()
        _ = try P56PackageLoader.load(payload: control, expectedSHA256: P56Digest.sha256(control))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: control) as? [String: Any])
        try change(&object)
        let bytes = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        XCTAssertThrowsError(try P56PackageLoader.load(payload: bytes, expectedSHA256: P56Digest.sha256(bytes)))
    }

    func testV3ExactLoadAndReferenceRoundTrip() throws {
        let bytes = try payload()
        let package = try P56PackageLoader.load(payload: bytes, expectedSHA256: P56Digest.sha256(bytes))
        XCTAssertEqual(package.books.count, 90)
        XCTAssertEqual(package.books.flatMap(\.pages).count, 720)
        XCTAssertEqual(package.sourceReference.packageVersion, "five-friends-56-runtime-v3")
        let metadata = ContentSourceMetadata(p56: package.sourceReference)
        XCTAssertEqual(try JSONDecoder().decode(ContentSourceMetadata.self,
            from: JSONEncoder().encode(metadata)).p56Reference, package.sourceReference)
    }

    func testV3RequiresCompleteReviewedSafetyAndNoReleaseApproval() throws {
        for field in ["safetyReview", "productionEnabled", "artApproved"] {
            try rejected { $0[field] = field == "safetyReview" ? NSNull() : true }
        }
        try rejected { object in
            var review = try XCTUnwrap(object["safetyReview"] as? [String: Any])
            var books = try XCTUnwrap(review["books"] as? [[String: Any]])
            books.removeLast(); review["books"] = books; object["safetyReview"] = review
        }
    }

    func testV3RejectsLineageSourceAndAuthoredCorruption() throws {
        for field in ["corpusID", "eventID", "baseBookID"] {
            try rejected { object in
                var values = try XCTUnwrap(object["bookLineages"] as? [[String: Any]])
                values[0][field] = "corrupt"; object["bookLineages"] = values
            }
        }
        for field in ["parentPointer", "parentText", "parentSHA256", "templateText"] {
            try rejected { object in
                var books = try XCTUnwrap(object["books"] as? [[String: Any]])
                var pages = try XCTUnwrap(books[0]["pages"] as? [[String: Any]])
                pages[0][field] = "corrupt"; books[0]["pages"] = pages; object["books"] = books
            }
        }
        try rejected { object in
            var books = try XCTUnwrap(object["books"] as? [[String: Any]])
            books[0]["titleTemplate"] = "corrupt"; object["books"] = books
        }
    }

    func testHistoricalPackagesRemainExplicitlyLoadable() throws {
        for version in [1, 2] {
            let bytes = try payload(version)
            let package = try P56PackageLoader.load(payload: bytes, expectedSHA256: P56Digest.sha256(bytes))
            XCTAssertEqual(package.sourceReference.packageVersion, "five-friends-56-runtime-v\(version)")
            XCTAssertEqual(package.books.count, version == 1 ? 30 : 90)
        }
    }
}
