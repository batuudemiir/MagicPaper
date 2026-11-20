import Foundation
import StoryEngine

let manifestURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let manifest = try JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL)) as! [String: Any]
let rules = manifest["rules"] as! [[String: Any]]
let assets = manifest["assets"] as! [[String: Any]]
let catalog = try ContentCatalogLoader().load().catalog
var results: [[String: Any]] = []
for asset in assets {
    let assetID = asset["assetID"] as! String
    let candidates = rules.filter { $0["assetID"] as? String == assetID }
    var found: [String: Any]?
    var attempts = 0
    let blueprintIDs = Set(candidates.compactMap { $0["blueprintID"] as? String }).sorted()
    search: for id in blueprintIDs {
        guard let blueprint = catalog.blueprints.first(where: { $0.id.rawValue == id }) else { continue }
        let permitted = candidates.filter { $0["blueprintID"] as? String == id }
        for index in 0..<48 {
            attempts += 1
            let seed = "story-art-audit-\(index)"
            let setting = (permitted.first?["settingIDs"] as? [String])?.first
            let intent = OfflineStoryIntent(childName: "Deniz", settingID: setting.map { ContentID($0) },
                discoveryID: ContentID(asset["subjectID"] as! String), seed: seed)
            guard let story = try? OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog, intent: intent),
                  let first = story.pages.sorted(by: { $0.pageNumber < $1.pageNumber }).first,
                  first.role.rawValue == "hook", first.beats.map({ $0.rawValue }) == ["notice_anomaly"],
                  first.refrain == nil, first.missingSlots.isEmpty, first.unrecognisedSuffixes.isEmpty,
                  permitted.contains(where: {
                      ($0["variantIDs"] as? [String]) == first.variantIDs.map { $0.rawValue }
                      && ($0["authoredSourceFingerprint"] as? String) == first.authoredSourceFingerprint
                      && (($0["settingIDs"] as? [String])?.contains(story.content.setting.id.rawValue) ?? true)
                  }) else { continue }
            found = ["assetID": assetID, "status": "eligible-real-composition", "seed": seed,
                "syntheticChildName": "Deniz", "blueprintID": id, "ageBand": "5-6",
                "settingID": story.content.setting.id.rawValue, "discoveryID": story.content.discovery.id.rawValue,
                "companionID": story.content.companion.id.rawValue, "catalogVersion": catalog.version,
                "pageNumber": first.pageNumber, "variantIDs": first.variantIDs.map { $0.rawValue },
                "authoredSourceFingerprint": first.authoredSourceFingerprint ?? "", "text": first.text,
                "title": story.title, "attempts": attempts]
            break search
        }
    }
    results.append(found ?? ["assetID": assetID, "status": candidates.isEmpty ? "no-runtime-rule" : "not-reached-in-bounded-scan", "attempts": attempts])
}
let report: [String: Any] = ["scope": "bounded real composer samples, not exhaustive catalog coverage", "seedLimitPerBlueprint": 48,
    "catalogVersion": catalog.version, "results": results]
try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]).write(to: outputURL)
print("Audited \(results.count) assets; \(results.filter { $0["status"] as? String == "eligible-real-composition" }.count) real eligible samples")
