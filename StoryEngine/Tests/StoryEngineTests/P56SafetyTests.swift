import XCTest
@testable import StoryEngine

final class P56SafetyTests: XCTestCase {
    private var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
    }
    private func loadV2(_ transform: ((inout [String: Any]) -> Void)? = nil) throws -> P56Package {
        let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-v2/payload.json"))
        if let transform {
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
            transform(&object)
            let changed = try JSONSerialization.data(withJSONObject: object)
            return try P56PackageLoader.load(payload: changed, expectedSHA256: P56Digest.sha256(changed))
        }
        return try P56PackageLoader.load(payload: bytes, expectedSHA256: P56PinnedSource.sha256)
    }
    func testReviewAggregatesEveryPageAndEnforcesExistingSafetyPolicy() throws {
        let package = try loadV2()
        let review = try XCTUnwrap(package.safetyReview)
        XCTAssertEqual(review.books.count, 90)
        XCTAssertEqual(review.books.flatMap(\.pages).count, 720)
        XCTAssertEqual(package.books.filter { review.admits($0, safety: .mostProtective) }.count, 70)
        XCTAssertEqual(package.books.filter { review.admits($0, safety: ContentSafety(level: .calm, avoided: [])) }.count, 81)
        XCTAssertEqual(package.books.filter { review.admits($0, safety: .unfiltered) }.count, 90)
        XCTAssertEqual(package.books.filter { review.admits($0, safety: ContentSafety(level: .someExcitement, avoided: nil)) }.count, 79)
    }
    func testEverySelectedBookRespectsProtectionWithoutRetries() throws {
        let package = try loadV2(), composer = P56StoryComposer(package: package)
        var attempts = 0
        for mode in P56Mode.allCases {
            for companion in package.companions {
                for seed in 0..<100 {
                    let request = P56Request(childID: "safety-fixture", name: "İrem", age: 6, seed: UInt64(seed),
                        mode: mode, companionID: companion.id, contentSafety: .mostProtective)
                    XCTAssertEqual(P56Support.unsupportedReasons(for: request, package: package), [])
                    let draft = try composer.compose(request)
                    let book = try XCTUnwrap(package.books.first { $0.id == draft.bookID })
                    XCTAssertTrue(try XCTUnwrap(package.safetyReview).admits(book, safety: .mostProtective))
                    attempts += 1
                }
            }
        }
        XCTAssertEqual(attempts, 1500)
    }
    func testUnavailableMechanismAndUnknownTopicAreExplicitUnsupported() throws {
        let package = try loadV2()
        let blocked = P56Request(childID: "x", name: "İrem", age: 5, seed: 1,
            mode: .adventure, forcedStructure: "A1", contentSafety: .mostProtective)
        XCTAssertEqual(P56Support.unsupportedReasons(for: blocked, package: package), ["content-safety-no-admissible-book"])
        XCTAssertThrowsError(try P56StoryComposer(package: package).compose(blocked)) {
            XCTAssertEqual($0 as? P56Error, .unsupported("content-safety-no-admissible-book"))
        }
        let unknown = P56Request(childID: "x", name: "İrem", age: 5, seed: 1,
            contentSafety: ContentSafety(level: .calm, avoided: [SafetyTopic("future-topic")]))
        XCTAssertEqual(P56Support.unsupportedReasons(for: unknown, package: package), ["content-safety-topic-not-reviewed"])
        let v1 = try loadP56ContractPackage()
        XCTAssertEqual(P56Support.unsupportedReasons(for: blocked, package: v1), ["content-safety-not-reviewed"])
    }
    func testInternalExactFixtureCannotBypassSafetyOrSourceIdentity() throws {
        let package = try loadV2()
        let blocked = try XCTUnwrap(package.books.first { $0.structureID == "A1" })
        let request = P56Request(childID: "x", name: "İrem", age: 5, seed: 0, contentSafety: .mostProtective)
        XCTAssertThrowsError(try P56StoryComposer(package: package).composeFixture(book: blocked, request: request))
    }
    func testNilAvoidanceCoversFutureTagsAndNewVocabularyFailsClosed() throws {
        XCTAssertTrue(ContentSafety.mostProtective.avoids(SafetyTopic("future-topic")))
        XCTAssertThrowsError(try loadV2 { object in
            var review = object["safetyReview"] as! [String: Any]
            var catalog = review["canonicalCatalog"] as! [String: Any]
            var topics = catalog["safetyTopics"] as! [[String: Any]]
            topics.append(["id": "future-topic"]); catalog["safetyTopics"] = topics
            review["canonicalCatalog"] = catalog; object["safetyReview"] = review
        }) { XCTAssertEqual($0 as? P56Error, .integrity("safety-review-coverage")) }
    }
    func testExplicitUnfilteredPolicyKeepsTheSameSingleDraw() throws {
        let package = try loadV2(), composer = P56StoryComposer(package: package)
        for seed in 0..<100 {
            let a = P56Request(childID: "x", name: "İrem", age: 6, seed: UInt64(seed))
            let b = P56Request(childID: "x", name: "İrem", age: 6, seed: UInt64(seed), contentSafety: .unfiltered)
            XCTAssertEqual(try composer.compose(a), try composer.compose(b))
        }
    }
    func testListedCompanionsHaveMostProtectiveBooksInEveryMode() throws {
        let package = try loadV2()
        for mode in P56Mode.allCases {
            for id in P56Support.companionIDs(age: 5, mode: mode, package: package) {
                let request = P56Request(childID: "x", name: "İrem", age: 5, seed: 0,
                    mode: mode, companionID: id, contentSafety: .mostProtective)
                XCTAssertFalse(P56Support.candidates(for: request, package: package).isEmpty)
            }
        }
    }
    func testIncompleteSourceOrNoncanonicalReviewCannotLoad() throws {
        for field in ["missing-book", "source-sha", "emotion", "evidence"] {
            XCTAssertThrowsError(try loadV2 { object in
                var review = object["safetyReview"] as! [String: Any]
                var books = review["books"] as! [[String: Any]]
                if field == "missing-book" { books.removeLast() }
                else {
                    var pages = books[0]["pages"] as! [[String: Any]]
                    if field == "source-sha" { pages[0]["sourceSHA256UTF8"] = String(repeating: "a", count: 64) }
                    if field == "emotion" { pages[0]["emotion"] = "invented-safe" }
                    if field == "evidence" { pages[0]["evidence"] = [] }
                    books[0]["pages"] = pages
                }
                review["books"] = books; object["safetyReview"] = review
            }, field)
        }
    }
}
