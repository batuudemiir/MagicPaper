import XCTest
@testable import StoryEngine

/// This verifies authored bytes and age budgets only, not runtime or editorial acceptance.
final class P56ExpansionAuthoringTests: XCTestCase {
    func testSixtyDraftBooksHaveExactSourcesAndAgeBudgets() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Content/Pilots/five-friends-56-expansion-v1")
        let manifest = try object(Data(contentsOf: root.appendingPathComponent("manifest.json")))
        let entries = try XCTUnwrap(manifest["books"] as? [[String: Any]])
        XCTAssertEqual(entries.count, 60)
        XCTAssertEqual(manifest["productionEnabled"] as? Bool, false)
        let sourceBytes = try Data(contentsOf: root.appendingPathComponent("sources.json"))
        XCTAssertEqual(P56Digest.sha256(sourceBytes), manifest["sourcePayloadSHA256FileBytes"] as? String)
        let sources = try XCTUnwrap(try object(sourceBytes)["sources"] as? [[String: Any]])
        let byID = Dictionary(sources.map { ($0["id"] as! String, $0) }, uniquingKeysWith: { first, _ in first })
        XCTAssertEqual(byID.count, sources.count)
        for source in sources {
            let text = try XCTUnwrap(source["text"] as? String)
            XCTAssertEqual(P56Digest.sha256(Data(text.utf8)), source["sha256UTF8"] as? String)
        }
        let evidence = try XCTUnwrap(try object(Data(contentsOf: root.appendingPathComponent("causal-evidence.json")))["records"] as? [[String: Any]])
        XCTAssertEqual(evidence.count, 480)
        var evidenceKeys: Set<String> = []
        for record in evidence {
            let key = (record["bookID"] as! String) + ":" + String(record["pageNumber"] as! Int)
            XCTAssertTrue(evidenceKeys.insert(key).inserted)
            let source = try XCTUnwrap(byID[record["parentSourceID"] as! String])
            let quote = record["quote"] as! String
            XCTAssertTrue((source["text"] as! String).contains(quote), key)
            XCTAssertEqual(P56Digest.sha256(Data(quote.utf8)), record["quoteSHA256"] as? String, key)
            let attribution = try XCTUnwrap(byID[record["attributionSourceID"] as! String])
            XCTAssertTrue((attribution["text"] as! String).contains(record["attributionQuote"] as! String), key)
        }

        var ids: Set<String> = [], pairs: [String: Int] = [:]
        let band = AgeBandResolver.mvp
        for entry in entries {
            let path = try XCTUnwrap(entry["file"] as? String)
            let bytes = try Data(contentsOf: root.appendingPathComponent(path))
            XCTAssertEqual(P56Digest.sha256(bytes), entry["sha256FileBytes"] as? String, path)
            let book = try object(bytes)
            XCTAssertTrue(ids.insert(book["id"] as! String).inserted)
            let pages = try XCTUnwrap(book["pages"] as? [[String: Any]])
            XCTAssertEqual(pages.count, 8)
            let context = book["context"] as! [String: Any]
            let key = (book["planLabel"] as! String) + "/" + (context["companionID"] as! String)
            pairs[key, default: 0] += 1
            for page in pages {
                let label = path + ":p" + String(page["pageNumber"] as! Int)
                let text = page["text"] as! String
                let count = TextMetrics.wordCount(text)
                XCTAssertTrue((band.pageBudget.lower...band.pageBudget.upper).contains(count), label + " words=" + String(count))
                XCTAssertLessThanOrEqual(TextMetrics.longestSentenceWordCount(text), band.maxSentenceWords, label)
                let provenance = page["provenance"] as! [String: Any]
                let parts = provenance["parts"] as! [[String: Any]]
                XCTAssertEqual(parts.count, 1)
                let part = parts[0], sourceID = parts[0]["sourceID"] as! String
                let source = try XCTUnwrap(byID[sourceID], label)
                XCTAssertEqual(source["text"] as? String, text, label)
                XCTAssertEqual(P56Digest.sha256(Data(text.utf8)), source["sha256UTF8"] as? String, label)
                XCTAssertEqual(part["sourceTextDigest"] as? String, source["sha256UTF8"] as? String, label)
                let pointer = part["sourcePointer"] as! String
                let index = try XCTUnwrap(Int(pointer.split(separator: "/").last ?? ""))
                XCTAssertEqual(sources[index]["id"] as? String, sourceID, label)
                let art = page["artHandoff"] as! [String: Any]
                XCTAssertEqual(art["assetRuleApproval"] as? Bool, false)
                if page["pageNumber"] as? Int == 8, context["mode"] as? String == "bedtime" {
                    XCTAssertTrue(CalmEnding.isCalm(text), label)
                }
            }
        }
        XCTAssertEqual(pairs.count, 30)
        XCTAssertTrue(pairs.values.allSatisfy { $0 == 2 })
    }
    private func object(_ bytes: Data) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
    }
}
