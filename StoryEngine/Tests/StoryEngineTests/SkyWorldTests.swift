import XCTest
@testable import StoryEngine

/// E5: the first world, "Gökyüzü ve uzay".
///
/// A world is a topic's content pack, not a new record type: three places,
/// two companions and three discoveries that let `topic_adventure_sky` bind
/// at least three adventure mechanisms. Appended to the end of the pilot
/// library, so no existing record moved.
final class SkyWorldTests: XCTestCase {

    private static let topic = "topic_adventure_sky"
    private static let places: Set<String> = [
        "setting_moon_shore_001", "setting_silver_dome_001", "setting_cloud_harbor_001"
    ]
    private static let companions: Set<String> = ["companion_robot_sky_001", "companion_space_cat_001"]
    private static let discoveries: Set<String> = [
        "object_stardust_trail_001", "object_little_comet_001", "object_star_map_001"
    ]

    private static let b34 = AgeBand(lowerBound: 3, upperBound: 4)
    private static let b56 = AgeBand(lowerBound: 5, upperBound: 6)
    private static let b78 = AgeBand(lowerBound: 7, upperBound: 8)
    private static let b910 = AgeBand(lowerBound: 9, upperBound: 10)

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    private func offered(_ catalog: ContentCatalog, band: AgeBand, safety: ContentSafety? = nil) -> [String] {
        BlueprintSelector().availableTopics(
            catalog: catalog,
            intent: OfflineStoryIntent(childName: "İrem", seed: "sky", mode: .adventure,
                                       ageBand: band, safety: safety)
        ).map(\.id.rawValue)
    }

    // MARK: - Where the chip shows

    func testTheSkyTopicIsOfferedInFiveSix() throws {
        let catalog = try catalog()
        XCTAssertTrue(offered(catalog, band: Self.b56).contains(Self.topic))
        // A parent who avoids heights loses Bulut Limanı, and with it the only
        // social threshold; three mechanisms remain.
        let heightsAvoided = ContentSafety(level: .someExcitement, avoided: ["heights"])
        XCTAssertTrue(offered(catalog, band: Self.b56, safety: heightsAvoided).contains(Self.topic))
    }

    /// Recorded, not wished away: 3-4 has no adventure blueprint, and 7-8 and
    /// 9-10 have two adventure mechanisms each (persistence, retracing),
    /// below `CatalogStoryTopic.minimumMechanisms`. The places do reach those
    /// bands' stories; the chip waits for a third mechanism.
    func testWhereTheSkyTopicIsNotYetOffered() throws {
        let catalog = try catalog()
        for band in [Self.b34, Self.b78, Self.b910] {
            XCTAssertFalse(offered(catalog, band: band).contains(Self.topic), "\(band)")
        }
    }

    // MARK: - A story with the topic

    func testAStoryWithTheSkyTopicIsSetInTheSkyAndIsClean() throws {
        let catalog = try catalog()
        for seed in (1...12).map({ "sky-\($0)" }) {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "İrem", seed: seed, mode: .adventure,
                                           ageBand: Self.b56, subOption: Self.topic))
            XCTAssertTrue(Self.places.contains(story.content.setting.id.rawValue), seed)
            XCTAssertTrue(story.isClean, "\(seed): \(story.pages.flatMap(\.missingSlots))")
        }
    }

    /// Every new place, with every standard-arc blueprint of every band that
    /// binds it, writes a clean story.
    func testEveryNewPlaceBuildsCleanlyWhereverItBinds() throws {
        let catalog = try catalog()
        var built = 0
        var failures: [String] = []
        for place in Self.places.sorted() {
            for blueprint in catalog.blueprints where blueprint.isBeatAuthored && blueprint.arc == .standard {
                for seed in ["a", "b", "c"] {
                    let intent = OfflineStoryIntent(
                        childName: "İrem", settingID: ContentID(place), seed: "\(place)-\(seed)",
                        ageBand: blueprint.ageRange)
                    guard (try? OfflineContentBinder().bind(blueprint: blueprint, catalog: catalog, intent: intent)) != nil
                    else { continue }
                    do {
                        let story = try OfflineStoryComposer().compose(
                            blueprint: blueprint, catalog: catalog, intent: intent)
                        built += 1
                        if !story.isClean { failures.append("\(place) · \(blueprint.id.rawValue): not clean") }
                    } catch {
                        failures.append("\(place) · \(blueprint.id.rawValue) · \(seed): \(error)")
                    }
                }
            }
        }
        XCTAssertGreaterThan(built, 0)
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }

    // MARK: - Bedtime keeps its rooms

    func testBedtimeNeverPicksANewPlace() throws {
        let catalog = try catalog()
        for id in Self.places {
            XCTAssertFalse(catalog.setting(ContentID(id))?.traits.contains(.isRestingPlace) ?? true, id)
        }
        for band in [Self.b34, Self.b56, Self.b78, Self.b910] {
            for seed in (1...10).map({ "bed-\($0)" }) {
                guard let story = try? OfflineStoryComposer().compose(
                    catalog: catalog,
                    intent: OfflineStoryIntent(childName: "İrem", seed: seed, mode: .bedtime, ageBand: band))
                else { continue }
                XCTAssertFalse(Self.places.contains(story.content.setting.id.rawValue), "\(band) \(seed)")
            }
        }
    }

    // MARK: - Series

    /// A finished sky story either cannot be continued (the button stays
    /// hidden) or its series plans; never shown and then failing.
    func testASkyStoryContinuesOnlyIfItsSeriesPlans() throws {
        let catalog = try catalog()
        for seed in ["sky-s1", "sky-s2", "sky-s3"] {
            let first = try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "İrem", seed: seed, mode: .adventure,
                                           ageBand: Self.b56, subOption: Self.topic))
            guard SeriesPlanner.isAvailable(
                settingID: first.content.setting.id, mode: .adventure, band: Self.b56, catalog: catalog)
            else { continue }
            XCTAssertNoThrow(try SeriesPlanner().plan(
                anchor: SeriesAnchor(settingID: first.content.setting.id,
                                     companionID: first.content.companion.id,
                                     keepsakeID: first.content.discovery.id),
                mode: .adventure, band: Self.b56, family: nil, familyCharacterID: nil,
                childName: "İrem",
                seed: SeriesPlanner.seed(storySeed: first.seed, fingerprint: first.fingerprint),
                catalog: catalog), seed)
        }
    }

    // MARK: - The catalog

    func testTheNewRecordsPassIntegrity() throws {
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        let ours = Self.places.union(Self.companions).union(Self.discoveries)
        let issues = report.issues.filter {
            ($0.severity == .error || $0.severity == .fatal) && ours.contains($0.recordID?.rawValue ?? "")
        }
        XCTAssertTrue(issues.isEmpty, issues.map(\.message).joined(separator: "\n"))
        XCTAssertTrue(report.isUsable)
    }

    /// Catalog arrays are order-sensitive: new records only at the end.
    func testNoExistingRecordMoved() throws {
        let catalog = try catalog()
        let settings = [
            "setting_forest_001", "setting_meadow_001", "setting_cave_001", "setting_mountain_001",
            "setting_beach_001", "setting_river_001", "setting_garden_001", "setting_village_001",
            "setting_castle_001", "setting_cloud_kingdom_001", "setting_space_station_001",
            "setting_moon_surface_001", "setting_underwater_reef_001", "setting_snowy_valley_001",
            "setting_island_001", "setting_bridge_001", "setting_market_001",
            "setting_whispering_forest_001", "setting_night_garden_001", "setting_cloud_mountain_001",
            "setting_coral_sea_001", "setting_old_orchard_001", "setting_festival_meadow_001",
            "setting_moon_window_room_001", "setting_blue_curtain_room_001",
        ]
        let companions = [
            "companion_fox_001", "companion_rabbit_001", "companion_owl_001", "companion_hedgehog_001",
            "companion_dragon_001", "companion_squirrel_001", "companion_bear_001", "companion_penguin_001",
            "companion_turtle_001", "companion_dolphin_001", "companion_firefly_001", "companion_robot_001",
            "companion_frog_001", "companion_cat_001", "companion_dog_001", "companion_sparrow_001",
            "companion_fox_pilot_001", "companion_hedgehog_pilot_001", "companion_owl_pilot_001",
            "companion_dolphin_pilot_001", "companion_rabbit_pilot_001", "companion_baker_001",
            "companion_postman_001", "companion_teacher_001",
        ]
        let objects = [
            "object_lantern_001", "object_map_001", "object_compass_001", "object_key_001",
            "object_crystal_001", "object_bell_001", "object_feather_001", "object_shell_001",
            "object_tiny_book_001", "object_star_stone_001", "object_ribbon_001",
            "object_magnifying_glass_001", "object_rope_001", "object_flute_001", "object_seed_001",
            "object_coin_001", "object_mirror_001", "object_bag_001", "object_stick_001",
            "object_goggles_001", "object_music_box_001", "object_paper_lantern_001",
            "object_flickering_light_001", "object_faint_sound_001", "object_footprints_001",
            "object_shell_pilot_001", "object_torn_map_001", "object_fallen_nest_001",
            "object_wilting_seedling_001", "object_dropped_mitten_001",
        ]
        XCTAssertEqual(Array(catalog.settings.map(\.id.rawValue).prefix(settings.count)), settings)
        XCTAssertEqual(Array(catalog.companions.map(\.id.rawValue).prefix(companions.count)), companions)
        XCTAssertEqual(Array(catalog.objects.map(\.id.rawValue).prefix(objects.count)), objects)
        XCTAssertEqual(Set(catalog.settings.dropFirst(settings.count).map(\.id.rawValue)), Self.places)
        XCTAssertEqual(Set(catalog.companions.dropFirst(companions.count).map(\.id.rawValue)), Self.companions)
        XCTAssertEqual(Set(catalog.objects.dropFirst(objects.count).map(\.id.rawValue)), Self.discoveries)
    }

    /// Place and companion names take their case endings correctly.
    func testTheNamesInflect() {
        func render(_ template: String, _ slot: TurkishTextRenderer.Slot) -> String {
            TurkishTextRenderer.render(template, slots: ["x": slot]).text
        }
        XCTAssertEqual(render("{{x}}'a", .init("Ay Kıyısı", isProperNoun: true, hasPossessiveEnding: true)), "Ay Kıyısı'na")
        XCTAssertEqual(render("{{x}}'da", .init("Bulut Limanı", isProperNoun: true, hasPossessiveEnding: true)), "Bulut Limanı'nda")
        XCTAssertEqual(render("{{x}}'da", .init("Gümüş Kubbe", isProperNoun: true)), "Gümüş Kubbe'de")
        XCTAssertEqual(render("{{x}}'a", .init("Ayçörek", isProperNoun: true)), "Ayçörek'e")
        XCTAssertEqual(render("{{x}}'in", .init("Vida", isProperNoun: true)), "Vida'nın")
        XCTAssertEqual(render("{{x}}'i", .init("yarım kalmış bir yıldız haritası", isProperNoun: false,
                                                hasPossessiveEnding: true)),
                       "yarım kalmış bir yıldız haritasını")
    }

    func testTheNewTextKeepsTheLanguageRules() throws {
        let catalog = try catalog()
        let texts = catalog.settings.filter { Self.places.contains($0.id.rawValue) }.flatMap { [$0.name, $0.description] }
            + catalog.companions.filter { Self.companions.contains($0.id.rawValue) }
                .flatMap { [$0.name, $0.type, $0.personality, $0.description] }
            + catalog.objects.filter { Self.discoveries.contains($0.id.rawValue) }
                .flatMap { [$0.name, $0.description, $0.titleName, $0.keepsakeName ?? ""] }
        XCTAssertEqual(texts.count, 3 * 2 + 2 * 4 + 3 * 4)
        let banned = ["—", "üret", "oluştur", "yapay zeka", "hemen", "anında", "saniyeler içinde",
                      "karanlık", "kaybol", "boşluk"]
        for text in texts {
            for word in banned {
                XCTAssertFalse(text.lowercased(with: Locale(identifier: "tr_TR")).contains(word), "\(text): \(word)")
            }
        }
    }
}
