import XCTest
@testable import StoryEngine

/// İçerik güvenliği (FAZ 17): what a parent allows is a rule, not a weight.
///
/// The shipped corpus carries no topic tags yet (the content draft waits for
/// review), so the tag tests tag a copy of the real catalog. What they guard is
/// the mechanism: a tagged line, record or blueprint is never read by a child
/// whose parent avoids the topic, and a mode the setting empties is not offered.
final class ContentSafetyTests: XCTestCase {

    private static let band = AgeBand(lowerBound: 5, upperBound: 6)
    private static let seeds = (0..<24).map { "safety-\($0)" }

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    // MARK: - Tagging helpers

    /// The same record with `topics` set, through its own Codable form, so the
    /// test cannot build a record the loader would not.
    private func tagged<T: Codable>(_ value: T, _ topics: [String]) throws -> T {
        let data = try JSONEncoder().encode(value)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["topics"] = topics
        return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: object))
    }

    private func rebuilt(
        _ full: ContentCatalog,
        settings: [CatalogSetting]? = nil,
        blueprints: [CatalogBlueprint]? = nil,
        templates: [CatalogTemplate]? = nil
    ) -> ContentCatalog {
        ContentCatalog(
            version: full.version,
            settings: settings ?? full.settings, companions: full.companions, objects: full.objects,
            events: full.events, challenges: full.challenges, endings: full.endings,
            templates: templates ?? full.templates,
            blueprints: blueprints ?? full.blueprints,
            storyIdeas: full.storyIdeas, storyModes: full.storyModes,
            familyMoments: full.familyMoments, familyAnimalKinds: full.familyAnimalKinds,
            interests: full.interests,
            safetyTopics: [CatalogSafetyTopic(id: "darkness", name: "Karanlık")] + full.safetyTopics,
            glossary: full.glossary, series: full.series)
    }

    private func compose(
        _ catalog: ContentCatalog, mode: StoryMode, seed: String, safety: ContentSafety?
    ) -> ComposedStory? {
        try? OfflineStoryComposer().compose(catalog: catalog, intent: OfflineStoryIntent(
            childName: "Yeliz", seed: seed, mode: mode, ageBand: Self.band, safety: safety))
    }

    // MARK: - The default

    func testTheDefaultIsCalmAndAvoidsEveryTopicEvenOnesAddedLater() {
        let safety = ContentSafety.mostProtective
        XCTAssertEqual(safety.level, .calm)
        XCTAssertTrue(safety.avoids("darkness"))
        XCTAssertTrue(safety.avoids("a-topic-the-catalog-adds-next-year"))
        XCTAssertFalse(ContentSafety.unfiltered.avoids("darkness"))
    }

    /// Calm is decided by the feeling of each page, by name: effort and
    /// patience are the work of nearly every story and stay.
    func testCalmRulesOutUneaseAndHesitationOnly() throws {
        let catalog = try catalog()
        for blueprint in catalog.blueprints where blueprint.isBeatAuthored {
            let emotions = Set(blueprint.pagePlan.compactMap(\.emotion))
            XCTAssertEqual(
                ContentSafety.mostProtective.admits(blueprint: blueprint),
                emotions.isDisjoint(with: [.unease, .hesitation]), "\(blueprint.id)")
            XCTAssertTrue(ContentSafety.unfiltered.admits(blueprint: blueprint), "\(blueprint.id)")
        }
    }

    func testACalmStoryNeverHasAnUneasyPage() throws {
        let catalog = try catalog()
        var excitedThresholds = 0
        for mode in StoryMode.allCases {
            for seed in Self.seeds {
                if let story = compose(catalog, mode: mode, seed: seed, safety: .mostProtective) {
                    let blueprint = try XCTUnwrap(catalog.blueprint(story.blueprintID))
                    XCTAssertTrue(ContentSafety.mostProtective.admits(blueprint: blueprint), "\(blueprint.id)")
                    XCTAssertTrue(story.pages.allSatisfy {
                        $0.emotion.map { !ContentSafety.tenseEmotions.contains($0) } ?? true
                    }, "\(blueprint.id)")
                }
                if let story = compose(catalog, mode: mode, seed: seed, safety: .unfiltered),
                   story.family == .threshold {
                    excitedThresholds += 1
                }
            }
        }
        // "Biraz heyecan" still gets the stories calm leaves out.
        XCTAssertGreaterThan(excitedThresholds, 0)
    }

    /// No setting and "nothing filtered" are the same book: the setting is a
    /// filter, never part of the seed.
    func testNothingFilteredIsTheBookWithoutASetting() throws {
        let catalog = try catalog()
        for mode in StoryMode.allCases {
            for seed in Self.seeds.prefix(8) {
                let plain = compose(catalog, mode: mode, seed: seed, safety: nil)
                let open = compose(catalog, mode: mode, seed: seed, safety: .unfiltered)
                XCTAssertEqual(plain?.fingerprint, open?.fingerprint, "\(mode) \(seed)")
                XCTAssertEqual(plain?.pages.map(\.text), open?.pages.map(\.text), "\(mode) \(seed)")
            }
        }
    }

    // MARK: - Acceptance: every mode is built or hidden

    /// Under the default setting, in every band the product offers, each mode
    /// either builds a story or is not offered. Today no mode is hidden by it.
    func testEveryModeIsBuiltOrHiddenUnderTheDefault() throws {
        let catalog = try catalog()
        let selector = BlueprintSelector()
        let available = Set(catalog.blueprints.filter(\.isBeatAuthored).map(\.ageRange))
        for requested in AgeBandResolver.bands {
            guard let band = AgeBandResolver.servedBand(for: requested, available: available) else { continue }
            let offered = selector.availableModes(catalog: catalog, ageBand: band, safety: .mostProtective)
            XCTAssertEqual(Set(offered), Set(selector.availableModes(catalog: catalog, ageBand: band)),
                           "the default hides a mode in \(band)")
            for mode in offered {
                let built = Self.seeds.prefix(6).contains { seed in
                    (try? OfflineStoryComposer().compose(catalog: catalog, intent: OfflineStoryIntent(
                        childName: "Can", seed: seed, mode: mode, ageBand: band,
                        safety: .mostProtective))) != nil
                }
                XCTAssertTrue(built, "\(mode) offered in \(band) but never built")
            }
        }
        let report = CatalogIntegrityChecker().check(catalog)
        XCTAssertTrue(report.issues(withCode: "mode_hidden_by_default_safety").isEmpty)
    }

    // MARK: - Tags

    func testALineThatTouchesAnAvoidedTopicIsNeverRead() throws {
        let full = try catalog()
        // Half of every 5-6 warm_close line is in the dark.
        var darkLines = Set<ContentID>()
        let templates = try full.templates.map { template -> CatalogTemplate in
            guard template.realizesBeat == .warmClose, template.suits(band: Self.band) else { return template }
            let variants = try template.variants.enumerated().map { index, variant in
                guard index.isMultiple(of: 2), !variant.isFamilyLine else { return variant }
                darkLines.insert(variant.id)
                return try tagged(variant, ["darkness"])
            }
            return CatalogTemplate(
                id: template.id, role: template.role, realizesBeat: template.realizesBeat,
                compatibleThemes: template.compatibleThemes, variants: variants, ageBand: template.ageBand)
        }
        XCTAssertFalse(darkLines.isEmpty)
        let catalog = rebuilt(full, templates: templates)
        let avoiding = ContentSafety(level: .someExcitement, avoided: ["darkness"])

        var heardWhenAllowed = false
        for mode in StoryMode.allCases {
            for seed in Self.seeds {
                if let story = compose(catalog, mode: mode, seed: seed, safety: avoiding) {
                    let used = Set(story.pages.flatMap(\.variantIDs))
                    XCTAssertTrue(used.isDisjoint(with: darkLines), "\(mode) \(seed)")
                }
                if let story = compose(catalog, mode: mode, seed: seed, safety: nil),
                   !Set(story.pages.flatMap(\.variantIDs)).isDisjoint(with: darkLines) {
                    heardWhenAllowed = true
                }
            }
        }
        XCTAssertTrue(heardWhenAllowed, "the tagged lines are reachable without the setting")
    }

    /// Every line of a beat tagged: the blueprints that need the beat are ruled
    /// out by name, not written with the line anyway.
    func testABeatWithEveryLineAvoidedRulesItsBlueprintsOut() throws {
        let full = try catalog()
        let templates = try full.templates.map { template -> CatalogTemplate in
            guard template.realizesBeat == .warmClose else { return template }
            return CatalogTemplate(
                id: template.id, role: template.role, realizesBeat: template.realizesBeat,
                compatibleThemes: template.compatibleThemes,
                variants: try template.variants.map { try tagged($0, ["darkness"]) },
                ageBand: template.ageBand)
        }
        let catalog = rebuilt(full, templates: templates)
        let avoiding = ContentSafety(level: .someExcitement, avoided: ["darkness"])
        let intent = OfflineStoryIntent(
            childName: "Yeliz", seed: "dark", mode: .bedtime, ageBand: Self.band, safety: avoiding)
        let (admitted, rejections) = BlueprintSelector().admissible(catalog: catalog, intent: intent)
        XCTAssertTrue(admitted.isEmpty)
        XCTAssertTrue(rejections.allSatisfy { $0.contains("every 'warm_close' line carries a topic") }, "\(rejections)")
        XCTAssertTrue(BlueprintSelector().availableModes(
            catalog: catalog, ageBand: Self.band, safety: avoiding).isEmpty)
        XCTAssertTrue(BlueprintSelector().availableFamilyRelations(
            catalog: catalog, mode: .bedtime, ageBand: Self.band, safety: avoiding).isEmpty)
    }

    func testARecordThatTouchesAnAvoidedTopicIsNeverBound() throws {
        let full = try catalog()
        // The setting unfiltered stories land on most, so avoiding it is seen.
        var counts: [ContentID: Int] = [:]
        for mode in StoryMode.allCases {
            for seed in Self.seeds {
                if let id = compose(full, mode: mode, seed: seed, safety: nil)?.content.setting.id {
                    counts[id, default: 0] += 1
                }
            }
        }
        let darkID = try XCTUnwrap(counts.max { $0.value < $1.value }?.key)
        let settings = try full.settings.map { $0.id == darkID ? try tagged($0, ["darkness"]) : $0 }
        let catalog = rebuilt(full, settings: settings)
        let avoiding = ContentSafety(level: .someExcitement, avoided: ["darkness"])

        var boundWhenAllowed = false
        for mode in StoryMode.allCases {
            for seed in Self.seeds {
                if let story = compose(catalog, mode: mode, seed: seed, safety: avoiding) {
                    XCTAssertNotEqual(story.content.setting.id, darkID, "\(mode) \(seed)")
                }
                if compose(catalog, mode: mode, seed: seed, safety: nil)?.content.setting.id == darkID {
                    boundWhenAllowed = true
                }
            }
        }
        XCTAssertTrue(boundWhenAllowed)

        // Asked for by name, it is refused with the topic, not swapped.
        let pinned = OfflineStoryIntent(
            childName: "Yeliz", settingID: darkID, seed: "pin", ageBand: Self.band, safety: avoiding)
        XCTAssertThrowsError(try OfflineStoryComposer().compose(catalog: catalog, intent: pinned)) { error in
            XCTAssertTrue(String(describing: error).contains("darkness"), "\(error)")
        }
    }

    func testABlueprintAboutAnAvoidedTopicIsRuledOutWithItsReason() throws {
        let full = try catalog()
        let blueprints = try full.blueprints.map {
            $0.family == .absence ? try tagged($0, ["darkness"]) : $0
        }
        let catalog = rebuilt(full, blueprints: blueprints)
        let avoiding = ContentSafety(level: .someExcitement, avoided: ["darkness"])
        let intent = OfflineStoryIntent(
            childName: "Yeliz", seed: "x", mode: .adventure, ageBand: Self.band, safety: avoiding)
        let (admitted, rejections) = BlueprintSelector().admissible(catalog: catalog, intent: intent)
        XCTAssertFalse(admitted.contains { $0.family == .absence })
        XCTAssertTrue(rejections.contains { $0.contains("tells of 'darkness'") }, "\(rejections)")
    }

    /// A mode the setting empties is not offered, and the content pipeline is
    /// told when the default does it.
    func testAModeTheDefaultEmptiesIsHiddenAndReported() throws {
        let full = try catalog()
        let blueprints = try full.blueprints.map {
            $0.family == .absence || $0.family == .threshold ? try tagged($0, ["darkness"]) : $0
        }
        let catalog = rebuilt(full, blueprints: blueprints)
        let selector = BlueprintSelector()
        XCTAssertTrue(selector.availableModes(catalog: catalog, ageBand: Self.band).contains(.adventure))
        XCTAssertFalse(selector.availableModes(
            catalog: catalog, ageBand: Self.band, safety: .mostProtective).contains(.adventure))
        let warnings = CatalogIntegrityChecker().check(catalog).issues(withCode: "mode_hidden_by_default_safety")
        XCTAssertTrue(warnings.contains { $0.message.contains("adventure") }, "\(warnings)")
    }

    // MARK: - Vocabulary

    func testDeathAndLossAreNeverAChoice() throws {
        let catalog = ContentCatalog(version: "0", safetyTopics: [
            CatalogSafetyTopic(id: "death", name: "Ölüm ve kayıp")
        ])
        let report = CatalogIntegrityChecker().check(catalog)
        XCTAssertFalse(report.issues(withCode: "safety_topic_not_offered").isEmpty)
    }

    func testAnUndefinedTopicIsAnError() throws {
        let full = try catalog()
        let settings = try full.settings.enumerated().map { $0.offset == 0 ? try tagged($0.element, ["spiders"]) : $0.element }
        let report = CatalogIntegrityChecker().check(rebuilt(full, settings: settings))
        XCTAssertTrue(report.issues(withCode: "unknown_safety_topic").contains { $0.message.contains("spiders") })
    }

    func testTheShippedCatalogsTopicsAreClean() throws {
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        for code in ["duplicate_safety_topic", "safety_topic_without_name", "safety_topic_not_offered",
                     "unknown_safety_topic"] {
            XCTAssertTrue(report.issues(withCode: code).isEmpty, "\(code): \(report.issues(withCode: code))")
        }
    }

    // MARK: - Series

    /// A series planned before FAZ 17 has no setting and still opens.
    func testAPlanWrittenBeforeFaz17StillDecodes() throws {
        let plan = SeriesPlan(
            seed: "s", catalogVersion: "1", mode: .bedtime, ageBand: Self.band,
            anchor: SeriesAnchor(settingID: "a", companionID: "b", keepsakeID: "c"),
            family: nil, episodes: [])
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(plan)) as? [String: Any])
        XCTAssertNil(object["safety"])
        object.removeValue(forKey: "safety")
        let decoded = try JSONDecoder().decode(
            SeriesPlan.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(decoded.safety)

        let kept = SeriesPlan(
            seed: "s", catalogVersion: "1", mode: .bedtime, ageBand: Self.band,
            anchor: plan.anchor, family: nil, episodes: [], safety: .mostProtective)
        XCTAssertEqual(try JSONDecoder().decode(SeriesPlan.self, from: JSONEncoder().encode(kept)).safety,
                       .mostProtective)
    }
}
