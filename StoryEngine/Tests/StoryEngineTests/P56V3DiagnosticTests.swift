import Foundation
import XCTest
@testable import StoryEngine

/// Inspect untrusted authored inputs even when the production loader refuses them.
/// This test-only decoder never makes a candidate an accepted runtime package.
final class P56V3DiagnosticTests: XCTestCase {
    func testReportEveryPageAndBookWithoutHidingLoaderFailures() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-v3/payload.json"))
        let raw = try JSONDecoder().decode(P56V2PackageLoader.Payload.self, from: bytes)
        var loaderError: String?
        do { _ = try P56PackageLoader.load(payload: bytes, expectedSHA256: P56Digest.sha256(bytes)) }
        catch { loaderError = String(describing: error) }
        let diagnostic = P56Package(sourceReference: .init(packageVersion: raw.packageVersion, payloadSHA256: P56Digest.sha256(bytes)),
            books: raw.books, structures: raw.structures, companions: raw.companions, settings: raw.settings,
            worldID: raw.worldID, safetyReview: raw.safetyReview)
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
                    if !(18...38).contains(words) || sentence > 14 {
                        pageIssues.append(["bookID": book.id, "pageNumber": page.number, "name": name,
                            "wordCount": words, "longestSentenceWords": sentence, "text": rendered])
                    }
                }
                do {
                    _ = try P56StoryComposer(package: diagnostic).composeFixture(book: book,
                        request: P56Request(childID: "diagnostic", name: name, age: 6, seed: 0))
                    attempts.append(["bookID": book.id, "name": name, "success": true])
                } catch { attempts.append(["bookID": book.id, "name": name, "success": false, "error": String(describing: error)]) }
            }
        }
        let reviewError: String?
        do { try raw.safetyReview?.validate(against: raw.books); reviewError = nil }
        catch { reviewError = String(describing: error) }
        // N1500 can be invoked only after a real loader success. Never sample an unvalidated package as if accepted.
        var sampling: P56SamplingReport?
        if loaderError == nil { sampling = P56Sampler.run(package: diagnostic) }
        if let directory = ProcessInfo.processInfo.environment["P56_V3_REPORT_DIRECTORY"] {
            let out = URL(fileURLWithPath: directory)
            try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
            let report: [String: Any] = ["productionLoaderError": loaderError as Any? ?? NSNull(),
                "safetyBindingError": reviewError as Any? ?? NSNull(), "books": raw.books.count,
                "pages": raw.books.flatMap(\.pages).count, "fixtureAttempts": attempts,
                "pageBudgetIssuesAcrossNames": pageIssues, "traceIssues": traces,
                "samplingStatus": loaderError == nil ? "executed" : "blocked-by-production-loader",
                "diagnosticOnly": true, "activationApproved": false]
            try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
                .write(to: out.appendingPathComponent("diagnostic.json"))
            if let sampling { try JSONEncoder().encode(sampling).write(to: out.appendingPathComponent("sampling.json")) }
        }
        XCTAssertEqual(raw.books.count, 90)
        XCTAssertEqual(attempts.count, 630)
    }
}
