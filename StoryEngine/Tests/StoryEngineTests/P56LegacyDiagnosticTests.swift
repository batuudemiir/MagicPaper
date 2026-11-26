import XCTest
@testable import StoryEngine

/// Opt-in measurement. Production catalogs and selection policy are never modified.
final class P56LegacyDiagnosticTests: XCTestCase {
    struct Row: Codable {
        let arm: String, scenario: String, seed: String, mode: String
        let profile: Int, index: Int
        let selectedCompanion: String?, setting: String?, book: String?, mechanism: String?, failure: String?
        let sourceIDs: [String], pageSHA256: [String]
    }
    let friends = ["companion_fox_pilot_001", "companion_hedgehog_pilot_001", "companion_owl_pilot_001", "companion_city_cat_001", "companion_bear_001"]

    func testFirstAttemptLegacyFilterAndReadingSequences() throws {
        guard let output = ProcessInfo.processInfo.environment["P56_C1_REPORT_DIRECTORY"] else {
            throw XCTSkip("Long first-attempt diagnostic requires explicit output directory")
        }
        let original = try ContentCatalogLoader().load().catalog
        let filtered = ContentCatalog(version: original.version, settings: original.settings,
            companions: original.companions.filter { friends.contains($0.id.rawValue) }, objects: original.objects,
            events: original.events, challenges: original.challenges, endings: original.endings,
            templates: original.templates, blueprints: original.blueprints, storyIdeas: original.storyIdeas,
            storyModes: original.storyModes, storyTopics: original.storyTopics, familyMoments: original.familyMoments,
            familyAnimalKinds: original.familyAnimalKinds, interests: original.interests,
            safetyTopics: original.safetyTopics, glossary: original.glossary, facts: original.facts,
            series: original.series, declaredResolutionCount: original.declaredResolutionCount,
            recallLines: original.recallLines, occasions: original.occasions)
        XCTAssertEqual(filtered.blueprints, original.blueprints)
        XCTAssertEqual(Set(filtered.companions.map { $0.id.rawValue }), Set(friends))
        let package = try loadP56ContractPackage()
        var rows: [Row] = []
        for (arm, catalog) in [("L", original), ("F", filtered)] {
            for mode in StoryMode.allCases {
                let setting = mode == .bedtime ? "setting_moon_window_room_001" : "setting_whispering_forest_001"
                XCTAssertTrue(original.settings.contains { $0.id.rawValue == setting })
                for companion in friends.map(Optional.some) + [nil] {
                    for index in 0..<100 {
                        let scenario = companion == nil ? "unselected" : "pinned-cells"
                        let seed = "c1-" + mode.rawValue + "-" + (companion ?? "unselected") + "-" + String(index)
                        rows.append(measure(catalog, arm: arm, scenario: scenario, profile: 0, index: index,
                            mode: mode, companion: companion, setting: setting, seed: seed).0)
                    }
                }
            }
            for scenario in ["alternating", "bedtime60"] {
                for profile in 0..<3 {
                    var recent: [RecentContent] = [], titles: [String] = []
                    for index in 0..<100 {
                        let mode = readingMode(index, scenario)
                        let seed = "a0-" + scenario + "-c" + String(profile) + "-s" + String(index)
                        let (row, story) = measure(catalog, arm: arm, scenario: scenario, profile: profile,
                            index: index, mode: mode, companion: nil, setting: nil, seed: seed,
                            recent: recent, titles: Set(titles))
                        rows.append(row)
                        if let s = story {
                            recent.insert(RecentContent(blueprintID: s.blueprintID, settingID: s.content.setting.id,
                                companionID: s.content.companion.id, discoveryID: s.content.discovery.id,
                                variantIDs: Set(s.pages.flatMap { $0.variantIDs })), at: 0)
                            recent = Array(recent.prefix(SelectionScoring.lineCooldownWindow))
                            titles.insert(s.title, at: 0); titles = Array(titles.prefix(12))
                        }
                    }
                }
            }
        }
        for scenario in ["alternating", "bedtime60"] {
            for profile in 0..<3 {
                for index in 0..<100 {
                    let mode = readingMode(index, scenario), seed = UInt64(profile * 100 + index)
                    do {
                        let s = try P56StoryComposer(package: package).compose(P56Request(childID: "synthetic-c" + String(profile),
                            name: "İrem", age: 6, seed: seed, mode: P56Mode(rawValue: mode.rawValue)))
                        rows.append(Row(arm: "N", scenario: scenario, seed: String(seed), mode: mode.rawValue,
                            profile: profile, index: index, selectedCompanion: nil, setting: s.pages.first?.settingID,
                            book: s.bookID, mechanism: s.mechanism, failure: nil,
                            sourceIDs: s.pages.map { $0.provenance.templateID }, pageSHA256: s.pages.map { $0.provenance.renderedSHA256 }))
                    } catch {
                        rows.append(Row(arm: "N", scenario: scenario, seed: String(seed), mode: mode.rawValue,
                            profile: profile, index: index, selectedCompanion: nil, setting: nil, book: nil,
                            mechanism: nil, failure: String(describing: error), sourceIDs: [], pageSHA256: []))
                    }
                }
            }
        }
        XCTAssertEqual(rows.count, 5400)
        let directory = URL(fileURLWithPath: output)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(rows).write(to: directory.appendingPathComponent("first-attempts.json"))
        XCTAssertEqual(rows.filter { $0.arm == "N" }.count, 600)
    }

    private func readingMode(_ index: Int, _ scenario: String) -> StoryMode {
        if scenario == "alternating" { return [.bedtime, .learning, .adventure][index % 3] }
        return [.bedtime, .bedtime, .bedtime, .learning, .adventure][index % 5]
    }

    private func measure(_ catalog: ContentCatalog, arm: String, scenario: String, profile: Int, index: Int,
                         mode: StoryMode, companion: String?, setting: String?, seed: String,
                         recent: [RecentContent] = [], titles: Set<String> = []) -> (Row, ComposedStory?) {
        do {
            let s = try OfflineStoryComposer().compose(catalog: catalog, intent: OfflineStoryIntent(childName: "İrem",
                settingID: setting.map { ContentID($0) }, companionID: companion.map { ContentID($0) },
                seed: seed, mode: mode, ageBand: AgeBand(lowerBound: 5, upperBound: 6), recent: recent, recentTitles: titles))
            return (Row(arm: arm, scenario: scenario, seed: seed, mode: mode.rawValue, profile: profile, index: index,
                selectedCompanion: companion, setting: setting, book: s.blueprintID.rawValue,
                mechanism: catalog.blueprints.first { $0.id == s.blueprintID }?.mechanismKey,
                failure: s.isClean ? nil : "unclean-draft", sourceIDs: s.pages.flatMap { $0.variantIDs.map(\.rawValue) },
                pageSHA256: s.pages.map { P56Digest.sha256(Data($0.text.utf8)) }), s.isClean ? s : nil)
        } catch {
            return (Row(arm: arm, scenario: scenario, seed: seed, mode: mode.rawValue, profile: profile, index: index,
                selectedCompanion: companion, setting: setting, book: nil, mechanism: nil,
                failure: String(describing: error), sourceIDs: [], pageSHA256: []), nil)
        }
    }
}
