import Foundation
import XCTest
@testable import StoryEngine

final class P56V2ReadingTests: XCTestCase {
    private struct Row: Codable {
        let arm: String, scenario: String, mode: String
        let profile: Int, index: Int, seed: UInt64
        let bookID: String?, failure: String?
        let sourceIDs: [String], pageSHA256: [String]
    }
    func testFirstAttemptA0BeforeAfterUsesIdenticalRequestSchedule() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/five-friends-56-runtime-v2/payload.json"))
        let old = try loadP56ContractPackage()
        let new = try P56PackageLoader.load(payload: bytes, expectedSHA256: P56PinnedSource.sha256)
        var rows: [Row] = []
        for (arm, package) in [("N-v1", old), ("N-v2", new)] {
            let composer = P56StoryComposer(package: package)
            for scenario in ["alternating", "bedtime60"] {
                for profile in 0..<3 {
                    for index in 0..<100 {
                        let modes: [P56Mode] = scenario == "alternating"
                            ? [.bedtime, .learning, .adventure] : [.bedtime, .bedtime, .bedtime, .learning, .adventure]
                        let mode = modes[index % modes.count], seed = UInt64(profile * 100 + index)
                        do {
                            let story = try composer.compose(P56Request(childID: "synthetic-c" + String(profile),
                                name: "İrem", age: 6, seed: seed, mode: mode))
                            rows.append(Row(arm: arm, scenario: scenario, mode: mode.rawValue, profile: profile,
                                index: index, seed: seed, bookID: story.bookID, failure: nil,
                                sourceIDs: story.pages.map { $0.provenance.templateID },
                                pageSHA256: story.pages.map { $0.provenance.renderedSHA256 }))
                        } catch {
                            rows.append(Row(arm: arm, scenario: scenario, mode: mode.rawValue, profile: profile,
                                index: index, seed: seed, bookID: nil, failure: String(describing: error),
                                sourceIDs: [], pageSHA256: []))
                        }
                    }
                }
            }
        }
        if let path = ProcessInfo.processInfo.environment["P56_V2_REPORT_DIRECTORY"] {
            let directory = URL(fileURLWithPath: path)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(rows).write(to: directory.appendingPathComponent("a0-before-after.json"))
        }
        XCTAssertEqual(rows.count, 1200)
        XCTAssertEqual(rows.filter { $0.failure != nil }.count, 0)
    }
}
