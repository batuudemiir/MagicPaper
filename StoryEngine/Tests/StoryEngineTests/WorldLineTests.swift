import XCTest
@testable import StoryEngine

/// Dünya satırları (19 Kasım 2026): bir satır yalnızca belirli bir dünyanın
/// mekânında okunabilir (`settingTags`). Kural esnemiyor: şehir satırı
/// ormanda yanlış bir sayfa değil, başka bir masalın sayfası. O dünyanın
/// mekânındaysa seçici satırı öne alır; havuz sayımı değişmez.
final class WorldLineTests: XCTestCase {

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    private func line(_ id: String, world: String? = nil) throws -> CatalogVariant {
        let worldKey = world.map { ",\"settingTags\":[\"\($0)\"]" } ?? ""
        return try JSONDecoder().decode(CatalogVariant.self, from: Data("""
        {"id":"\(id)","text":"{{child.name}} durdu.","lengthClass":"solo"\(worldKey)}
        """.utf8))
    }

    private func content(settingID: String, _ catalog: ContentCatalog) throws -> BoundContent {
        BoundContent(
            setting: try XCTUnwrap(catalog.settings.first { $0.id.rawValue == settingID }),
            companion: try XCTUnwrap(catalog.companions.first { $0.castRoles.contains(.guide) }),
            discovery: try XCTUnwrap(catalog.objects.first { !$0.traits.isEmpty }),
            castRole: .guide)
    }

    func testTheKeyIsReadAndAPlainLineSuitsEveryWorld() throws {
        XCTAssertTrue(CatalogVariant.decodedKeys.contains("settingTags"))
        let catalog = try catalog()
        let square = try XCTUnwrap(catalog.settings.first { $0.id.rawValue == "setting_clock_square_001" })
        let forest = try XCTUnwrap(catalog.settings.first { $0.id.rawValue == "setting_whispering_forest_001" })
        let plain = try line("plain")
        let city = try line("city", world: "city")
        XCTAssertTrue(plain.suits(world: square))
        XCTAssertTrue(plain.suits(world: forest))
        XCTAssertTrue(city.suits(world: square))
        XCTAssertFalse(city.suits(world: forest))
    }

    /// Esnemiyor: havuzda başka satır kalmasa bile şehir satırı ormana gitmez.
    func testAWorldLineNeverReachesAnotherWorld() throws {
        let catalog = try catalog()
        let forest = try content(settingID: "setting_whispering_forest_001", catalog)
        let pool = try OfflineStoryComposer.pool(
            from: [try line("plain"), try line("city", world: "city")],
            realizing: .noticeAnomaly, wanting: .solo, after: nil,
            onPage: 1, content: forest, register: nil)
        XCTAssertEqual(pool.map(\.id.rawValue), ["plain"])
        XCTAssertThrowsError(try OfflineStoryComposer.pool(
            from: [try line("city", world: "city")],
            realizing: .noticeAnomaly, wanting: .solo, after: nil,
            onPage: 1, content: forest, register: nil))
    }

    /// Kendi dünyasında havuz iki satırı da sayar, seçim dünya satırını alır.
    func testInItsOwnWorldTheWorldLineIsPreferredButThePoolIsUnchanged() throws {
        let catalog = try catalog()
        let square = try content(settingID: "setting_clock_square_001", catalog)
        let lines = [try line("plain_a"), try line("plain_b"), try line("city", world: "city")]
        let pool = try OfflineStoryComposer.pool(
            from: lines, realizing: .noticeAnomaly, wanting: .solo, after: nil,
            onPage: 1, content: square, register: nil)
        XCTAssertEqual(pool.count, 3)
        for seed in ["a", "b", "c", "d", "e"] {
            let chosen = try OfflineStoryComposer.chooseVariant(
                from: lines, realizing: .noticeAnomaly, wanting: .solo, after: nil,
                onPage: 1, content: square, register: nil, seed: seed, salt: "t")
            XCTAssertEqual(chosen.id.rawValue, "city")
        }
    }

    /// Yeni üç dünya her bantta sayfa 1'i ve kapanışı kendi satırıyla taşıyor.
    func testEveryNewWorldHasItsOwnOpeningAndClosingInEveryBand() throws {
        let catalog = try catalog()
        for world in ["city", "country", "history"] {
            for band in ["3-4", "5-6", "7-8", "9-10"] {
                for beat in [StoryBeat.noticeAnomaly, .warmClose] {
                    let count = catalog.templates
                        .filter { $0.realizesBeat == beat && $0.ageBand.map { "\($0.lowerBound)-\($0.upperBound)" } == band }
                        .flatMap(\.variants)
                        .filter { $0.settingTags.contains(ContentTag(world)) }
                        .count
                    XCTAssertGreaterThanOrEqual(count, 3, "\(world) \(band) \(beat.rawValue)")
                }
            }
        }
    }
}
