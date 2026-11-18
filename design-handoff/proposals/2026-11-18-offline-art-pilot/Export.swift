import Foundation
import StoryEngine

// Controlled content pilot; calls the real package, never edits its resources.
// All names are fictional. Explicit blueprint binding intentionally limits scope.
struct PageExport: Codable {
    let number: Int
    let role: String
    let beats: [String]
    let text: String
    let variantIDs: [String]
    let visualScene: String
}
struct BookExport: Codable {
    let childName: String
    let seed: String
    let title: String
    let blueprintID: String
    let settingID: String
    let companionID: String
    let discoveryID: String
    let fingerprint: String
    let isClean: Bool
    let pages: [PageExport]
}
let catalog = try ContentCatalogLoader().load().catalog
let blueprint = catalog.blueprints.first { $0.id.rawValue == "bp_charge_tending_001" }!
var books: [BookExport] = []
for seedNumber in 0..<12 {
    for name in ["Ela", "Deniz"] {
        let seed = "gouache-pilot-\(seedNumber)"
        let intent = OfflineStoryIntent(
            childName: name,
            settingID: ContentID("setting_old_orchard_001"),
            companionID: ContentID("companion_hedgehog_pilot_001"),
            discoveryID: ContentID("object_wilting_seedling_001"),
            seed: seed, mode: .learning, ageBand: AgeBandResolver.mvp)
        let story = try OfflineStoryComposer().compose(blueprint: blueprint, catalog: catalog, intent: intent)
        books.append(BookExport(childName: name, seed: seed, title: story.title,
            blueprintID: story.blueprintID.rawValue, settingID: story.content.setting.id.rawValue,
            companionID: story.content.companion.id.rawValue, discoveryID: story.content.discovery.id.rawValue,
            fingerprint: story.fingerprint, isClean: story.isClean,
            pages: story.pages.map { PageExport(number: $0.pageNumber, role: $0.role.rawValue,
                beats: $0.beats.map(\.rawValue), text: $0.text,
                variantIDs: $0.variantIDs.map(\.rawValue), visualScene: $0.visualScene) }))
    }
}
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
let data = try encoder.encode(books)
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("Exported \(books.count) controlled books; clean: \(books.filter(\.isClean).count); pages: \(books.reduce(0) { $0 + $1.pages.count })")
