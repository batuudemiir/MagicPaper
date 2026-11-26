import XCTest
@testable import StoryEngine

func loadP56ContractPackage() throws -> P56Package {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Content/Pilots/five-friends-56-runtime-v1")
    let payload = try Data(contentsOf: root.appendingPathComponent("payload.json"))
    let manifest = try JSONDecoder().decode(P56RuntimeManifest.self,
        from: Data(contentsOf: root.appendingPathComponent("manifest.json")))
    XCTAssertEqual(P56Digest.sha256(payload), P56PinnedSource.v1SHA256)
    XCTAssertEqual(manifest.payloadSHA256, P56PinnedSource.v1SHA256)
    XCTAssertEqual(manifest.engineBehaviorID, P56Engine.behaviorID)
    return try P56PackageLoader.load(payload: payload, expectedSHA256: P56PinnedSource.v1SHA256)
}

final class P56ContractTests: XCTestCase {
    func testSupportReasonsMatchComposerAndAreUniqueSorted() throws {
        let package = try loadP56ContractPackage()
        let requests = [
            P56Request(childID: "", name: "", age: 7, seed: 1, companionID: "outside",
                forcedStructure: "outside", contexts: ["family", "family", "series"], contentSafety: .mostProtective),
            P56Request(childID: "test", name: "İrem", age: 5, seed: 1, contexts: ["family"])
        ]
        for request in requests {
            let reasons = P56Support.unsupportedReasons(for: request, package: package)
            XCTAssertEqual(reasons, Array(Set(reasons)).sorted())
            XCTAssertThrowsError(try P56StoryComposer(package: package).compose(request)) {
                XCTAssertEqual($0 as? P56Error, reasons.count == 1 ? .unsupported(reasons[0]) : .unsupportedContexts(reasons))
            }
        }
        XCTAssertEqual(P56Support.unsupportedReasons(for: requests[0], package: package),
            ["age", "child-id", "child-name", "companion", "content-safety-not-reviewed", "family",
             "selection-outside-pilot", "series", "structure"])
    }

    func testCanonicalCompanionsUseOnlySupportedBooks() throws {
        let package = try loadP56ContractPackage()
        let canonical = ["companion_fox_pilot_001", "companion_hedgehog_pilot_001", "companion_owl_pilot_001",
                         "companion_city_cat_001", "companion_bear_001"]
        for mode in P56Mode.allCases {
            let supported = Set(package.books.filter { $0.mode == mode }.map(\.companionID))
            XCTAssertEqual(P56Support.companionIDs(age: 5, mode: mode, package: package), canonical.filter(supported.contains))
            XCTAssertEqual(P56Support.companionIDs(age: 6, mode: mode, package: package), canonical.filter(supported.contains))
            XCTAssertEqual(P56Support.companionIDs(age: 7, mode: mode, package: package), [])
        }
        XCTAssertEqual(P56Support.unsupportedReasons(for: P56Request(childID: "test", name: "İrem", age: 5, seed: 1),
            package: package), [])
    }
}
