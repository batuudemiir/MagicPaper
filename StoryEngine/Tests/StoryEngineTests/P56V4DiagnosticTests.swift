import Foundation
import XCTest
@testable import StoryEngine

/// Inspect untrusted authored inputs even when the production loader refuses them.
/// This test-only decoder never makes a candidate an accepted runtime package.
final class P56V4DiagnosticTests: XCTestCase {
    func testReportEveryPageAndBookWithoutHidingLoaderFailures() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-v4/payload.json"))
        let raw = try JSONDecoder().decode(P56V2PackageLoader.Payload.self, from: bytes)
        var loaderError: String?
        var validated: P56Package?
        do { validated = try P56PackageLoader.load(payload: bytes, expectedSHA256: P56Digest.sha256(bytes)) }
        catch { loaderError = String(describing: error) }
        let diagnostic = P56Package(sourceReference: .init(packageVersion: raw.packageVersion, payloadSHA256: P56Digest.sha256(bytes)),
            books: raw.books, structures: raw.structures, companions: raw.companions, settings: raw.settings,
            worldID: raw.worldID, safetyReview: raw.safetyReview)
        var fixtures: [P56ComposedStory] = []
        var metrics: [[String: Any]] = []
        var pageIssues: [[String: Any]] = [], traces: [[String: Any]] = [], attempts: [[String: Any]] = []
        let names = ["İrem", "Çağrı", "Öykü", "Ege", "Ali", "Gül", "Deniz"]
        for book in raw.books {
            do { _ = try P56StructureValidator.compile(book) }
            catch { traces.append(["bookID": book.id, "error": String(describing: error)]) }
            for name in names {
                for page in book.pages {
                    let rendered = try P56Personalization.render(page.templateText, name: name)
                    let words = TextMetrics.wordCount(rendered)
                    let sentence = TextMetrics.longestSentenceWordCount(rendered)
                    if name == "Deniz" {
                        metrics.append(["bookID": book.id, "pageNumber": page.number,
                            "wordCount": words, "longestSentenceWords": sentence])
                    }
                    if !(18...38).contains(words) || sentence > 14 {
                        pageIssues.append(["bookID": book.id, "pageNumber": page.number, "name": name,
                            "wordCount": words, "longestSentenceWords": sentence, "text": rendered])
                    }
                }
                do {
                    let story = try P56StoryComposer(package: validated ?? diagnostic).composeFixture(book: book,
                        request: P56Request(childID: "diagnostic", name: name, age: 6, seed: 0))
                    if name == "İrem" { fixtures.append(story) }
                    attempts.append(["bookID": book.id, "name": name, "success": true])
                } catch { attempts.append(["bookID": book.id, "name": name, "success": false, "error": String(describing: error)]) }
            }
        }
        let reviewError: String?
        do { try raw.safetyReview?.validate(against: raw.books); reviewError = nil }
        catch { reviewError = String(describing: error) }
        // N1500 can be invoked only after a real loader success. Never sample an unvalidated package as if accepted.
        var sampling: P56SamplingReport?
        if let validated { sampling = P56Sampler.run(package: validated) }
        if let directory = ProcessInfo.processInfo.environment["P56_V4_REPORT_DIRECTORY"] {
            let out = URL(fileURLWithPath: directory)
            try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
            let report: [String: Any] = ["productionLoaderError": loaderError as Any? ?? NSNull(),
                "safetyBindingError": reviewError as Any? ?? NSNull(), "books": raw.books.count,
                "pages": raw.books.flatMap(\.pages).count, "fixtureAttempts": attempts,
                "pageBudgetIssuesAcrossNames": pageIssues, "traceIssues": traces, "sourceTextMetrics": metrics,
                "samplingStatus": loaderError == nil ? "executed" : "blocked-by-production-loader",
                "diagnosticOnly": true, "activationApproved": false]
            try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
                .write(to: out.appendingPathComponent("diagnostic.json"))
            if let sampling { try JSONEncoder().encode(sampling).write(to: out.appendingPathComponent("sampling.json")) }
            try JSONEncoder().encode(fixtures).write(to: out.appendingPathComponent("forced-books.json"))
        }
        XCTAssertEqual(raw.books.count, 90)
        XCTAssertEqual(attempts.count, 630)
        XCTAssertNil(loaderError)
        XCTAssertNil(reviewError)
        XCTAssertTrue(traces.isEmpty, "Typed trace failures: \(traces)")
        XCTAssertTrue(pageIssues.isEmpty, "Every source/name page must satisfy the real TextMetrics budget")
        XCTAssertEqual(attempts.filter { ($0["success"] as? Bool) == false }.count, 0)
        XCTAssertEqual(fixtures.count, 90)
        XCTAssertEqual(sampling?.attempts, 1500)
        XCTAssertEqual(sampling?.successes, 1500)
        XCTAssertEqual(sampling?.failures, 0)
        XCTAssertEqual(sampling?.retries, 0)
    }
}
