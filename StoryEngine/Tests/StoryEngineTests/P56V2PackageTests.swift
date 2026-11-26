import Foundation
import XCTest
@testable import StoryEngine

final class P56V2PackageTests: XCTestCase {
    private func payload() throws -> Data {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try Data(contentsOf: root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-v2/payload.json"))
    }
    func testV2CoverageAndEveryExactBookAcrossTurkishNames() throws {
        let bytes = try payload()
        let package = try P56PackageLoader.load(payload: bytes, expectedSHA256: P56PinnedSource.v2SHA256)
        XCTAssertEqual(package.books.count, 90)
        XCTAssertEqual(package.books.flatMap(\.pages).count, 720)
        XCTAssertEqual(package.sourceReference.packageVersion, "five-friends-56-runtime-v2")
        for book in package.books {
            for name in ["İrem", "Çağrı", "Öykü", "Ege", "Ali", "Gül", "Deniz"] {
                let request = P56Request(childID: "fixture-child", name: name, age: 6, seed: 0)
                let story = try P56StoryComposer(package: package).composeFixture(book: book, request: request)
                XCTAssertEqual(story.bookID, book.id)
                XCTAssertEqual(story.pages.count, 8)
                for page in story.pages {
                    XCTAssertTrue((18...38).contains(TextMetrics.wordCount(page.text)))
                    XCTAssertLessThanOrEqual(TextMetrics.longestSentenceWordCount(page.text), 14)
                }
            }
        }
    }
    func testV2RejectsMutatedLineageAndCoverage() throws {
        let bytes = try payload()
        for key in ["parentPointer", "parentSHA256", "parentSourceID"] {
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
            var books = try XCTUnwrap(object["books"] as? [[String: Any]])
            var pages = try XCTUnwrap(books[0]["pages"] as? [[String: Any]])
            pages[0][key] = "tampered"
            books[0]["pages"] = pages; object["books"] = books
            let mutated = try JSONSerialization.data(withJSONObject: object)
            XCTAssertThrowsError(try P56PackageLoader.load(payload: mutated, expectedSHA256: P56Digest.sha256(mutated)))
        }
    }
}

extension P56V2PackageTests {
    private func mutated(_ change: (inout [String: Any]) throws -> Void) throws -> Data {
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: payload()) as? [String: Any])
        try change(&object)
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    private func assertRejected(_ change: (inout [String: Any]) throws -> Void,
                                file: StaticString = #filePath, line: UInt = #line) throws {
        let bytes = try mutated(change)
        XCTAssertThrowsError(try P56PackageLoader.load(payload: bytes,
            expectedSHA256: P56Digest.sha256(bytes)), file: file, line: line)
    }

    func testV2RejectsUnknownSchemaBehaviorAndPackage() throws {
        let mutations: [[String: Any]] = [["schemaVersion": 3], ["packageVersion": "future"],
                                      ["engineBehaviorID": "offline-p56-v2"], ["productionEnabled": true],
                                      ["artApproved": true]]
        for fields in mutations {
            try assertRejected { $0.merge(fields) { _, new in new } }
        }
    }

    func testV2RejectsWrongCorpusAndDuplicateOrMissingEvent() throws {
        for field in ["corpusID", "eventID", "baseBookID"] {
            try assertRejected { object in
                var lineages = try XCTUnwrap(object["bookLineages"] as? [[String: Any]])
                lineages[0][field] = field == "eventID" ? "event02" : "wrong"
                object["bookLineages"] = lineages
            }
        }
        try assertRejected { object in
            var books = try XCTUnwrap(object["books"] as? [[String: Any]])
            books[1] = books[0]; object["books"] = books
        }
        try assertRejected { object in
            var books = try XCTUnwrap(object["books"] as? [[String: Any]])
            books.removeLast(); object["books"] = books
        }
    }

    func testV2RejectsCorpusSnapshotAndBookHashTampering() throws {
        for field in ["sourcesSHA256", "causalEvidenceSHA256", "sourcesJSON", "causalEvidenceJSON"] {
            try assertRejected { object in
                var corpora = try XCTUnwrap(object["corpora"] as? [[String: Any]])
                corpora[0][field] = "tampered"; object["corpora"] = corpora
            }
        }
        for field in ["authoredBookSHA256", "authoredBookJSON"] {
            try assertRejected { object in
                var books = try XCTUnwrap(object["books"] as? [[String: Any]])
                books[0][field] = "tampered"; object["books"] = books
            }
        }
    }

    func testV2RejectsBadActorAndFutureParentIndex() throws {
        let mutations: [(String, Any)] = [("actorIDs", ["outsider"]), ("parentSourceIndex", 999999)]
        for (field, value) in mutations {
            try assertRejected { object in
                var books = try XCTUnwrap(object["books"] as? [[String: Any]])
                var pages = try XCTUnwrap(books[0]["pages"] as? [[String: Any]])
                pages[0][field] = value; books[0]["pages"] = pages; object["books"] = books
            }
        }
    }

    func testV2SamplerUsesOneDrawPerCellSeedAndActualSixBookCount() throws {
        let package = try P56PackageLoader.load(payload: payload(), expectedSHA256: P56PinnedSource.v2SHA256)
        let report = P56Sampler.run(package: package)
        XCTAssertEqual(report.attempts, 1500)
        XCTAssertEqual(report.successes, 1500)
        XCTAssertEqual(report.failures, 0)
        XCTAssertEqual(report.retries, 0)
        XCTAssertEqual(report.fixedBooksPerCell, 6)
        let capacity = Dictionary(grouping: package.books, by: { $0.mode.rawValue + "/" + $0.companionID }).mapValues(\.count)
        XCTAssertEqual(capacity.count, 15)
        XCTAssertEqual(capacity.values.min(), 6)
        XCTAssertEqual(capacity.values.max(), 6)
        if let path = ProcessInfo.processInfo.environment["P56_V2_REPORT_DIRECTORY"] {
            let directory = URL(fileURLWithPath: path)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(report).write(to: directory.appendingPathComponent("sampling.json"))
            try encoder.encode(capacity).write(to: directory.appendingPathComponent("capacity-by-cell.json"))
            let composer = P56StoryComposer(package: package)
            let drafts = try package.books.map { try composer.composeFixture(book: $0,
                request: P56Request(childID: "p56-sampler", name: "İrem", age: 6, seed: 42)) }
            try encoder.encode(drafts).write(to: directory.appendingPathComponent("forced-books.json"))
        }
        XCTAssertEqual(report.cellAttempts.count, 15)
        XCTAssertTrue(report.cellAttempts.values.allSatisfy { $0 == 100 })
        for cell in report.cellAttempts.keys {
            XCTAssertEqual(report.attemptRecords.filter { $0.cell == cell }.map(\.seed), Array(UInt64(0)...99))
        }
    }

    func testHistoricalV1LiteralOutputAndVersionRemainStable() throws {
        let package = try loadP56ContractPackage()
        XCTAssertEqual(package.sourceReference.packageVersion, "five-friends-56-runtime-v1")
        XCTAssertEqual(package.sourceReference.payloadSHA256, P56PinnedSource.v1SHA256)
        let book = try XCTUnwrap(package.books.first { $0.id == "pilot56_book_u1_fox_v1" })
        let story = try P56StoryComposer(package: package).composeFixture(book: book,
            request: P56Request(childID: "fixture", name: "İrem", age: 6, seed: 0))
        XCTAssertEqual(story.pages[0].text,
            "İrem, Orman Kıyısındaki Oda’da yatağına oturdu. Tarçın da odadaydı. Pencere kapalıydı; akşamın soluk ışığı yerde duruyordu. Bu gece hiçbir yere gitmeleri gerekmiyordu.")
    }
}

extension P56V2PackageTests {
    func testUnmodifiedReserializedPackageLoadsAndReferenceRoundTrips() throws {
        let bytes = try mutated { _ in }
        let package = try P56PackageLoader.load(payload: bytes, expectedSHA256: P56Digest.sha256(bytes))
        XCTAssertEqual(package.books.count, 90)
        XCTAssertEqual(try JSONDecoder().decode(P56SourceReference.self,
            from: JSONEncoder().encode(package.sourceReference)), package.sourceReference)
        XCTAssertEqual(P56SourceReference(payloadSHA256: P56PinnedSource.v1SHA256).packageVersion,
            "five-friends-56-runtime-v1")
    }
    func testV2OriginalCorpusExactlyMatchesHistoricalV1Snapshots() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-v1/payload.json"))
        XCTAssertEqual(P56Digest.sha256(bytes), P56PinnedSource.v1SHA256)
        let old = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        let new = try XCTUnwrap(JSONSerialization.jsonObject(with: payload()) as? [String: Any])
        let corpus = try XCTUnwrap((new["corpora"] as? [[String: Any]])?.first { $0["id"] as? String == "five-friends-56-v1" })
        XCTAssertEqual(corpus["sourcesJSON"] as? String, old["authoredSourcesJSON"] as? String)
        XCTAssertEqual(corpus["sourcesSHA256"] as? String, old["authoredSourcePayloadSHA256"] as? String)
        XCTAssertEqual(corpus["causalEvidenceJSON"] as? String, old["causalEvidenceJSON"] as? String)
        XCTAssertEqual(corpus["causalEvidenceSHA256"] as? String, old["causalEvidenceSHA256"] as? String)
    }
    func testCrossCorpusPointerHasExpectedIntegrityFailure() throws {
        let bytes = try mutated { object in
            var books = object["books"] as! [[String: Any]]
            var pages = books[0]["pages"] as! [[String: Any]]
            pages[0]["parentPointer"] = "other-corpus/sources.json#/sources/0"
            books[0]["pages"] = pages; object["books"] = books
        }
        XCTAssertThrowsError(try P56PackageLoader.load(payload: bytes, expectedSHA256: P56Digest.sha256(bytes))) {
            XCTAssertEqual($0 as? P56Error, .integrity("template-parent-lineage"))
        }
    }
}
