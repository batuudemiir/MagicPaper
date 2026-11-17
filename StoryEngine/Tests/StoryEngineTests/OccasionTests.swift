import XCTest
@testable import StoryEngine

/// E6: special days. Their blueprints and lines live in a layer of their own
/// (`occasion_library_v1.json`), are chosen only when a day is asked for, and
/// leave every other book as it was.
final class OccasionTests: XCTestCase {

    private static let b34 = AgeBand(lowerBound: 3, upperBound: 4)
    private static let b56 = AgeBand(lowerBound: 5, upperBound: 6)
    private static let b78 = AgeBand(lowerBound: 7, upperBound: 8)
    private static let b910 = AgeBand(lowerBound: 9, upperBound: 10)

    private static let birthday: ContentID = "occasion_birthday"
    private static let school: ContentID = "occasion_first_school_day"
    private static let sibling: ContentID = "occasion_new_sibling"
    private static let tooth: ContentID = "occasion_first_lost_tooth"

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    private func mode(of blueprint: CatalogBlueprint, in catalog: ContentCatalog) -> StoryMode? {
        catalog.storyModes.first { $0.admits(blueprint) }?.mode
    }

    private func compose(
        _ kind: ContentID, band: AgeBand, mode: StoryMode?, seed: String,
        sibling: FamilyCast? = nil, recall: RecallHistory? = nil, catalog: ContentCatalog
    ) throws -> ComposedStory {
        try OfflineStoryComposer().compose(
            catalog: catalog,
            intent: OfflineStoryIntent(childName: "İrem", seed: seed, mode: mode, ageBand: band,
                                       recall: recall, occasion: OccasionRequest(kind: kind, sibling: sibling)))
    }

    // MARK: - No occasion, no change

    /// Without an occasion nothing joins the seed or the fingerprint, and no
    /// ordinary story ever picks a special-day blueprint or line.
    func testNoOrdinaryStoryEverUsesTheOccasionLayer() throws {
        let catalog = try catalog()
        XCTAssertEqual(OfflineStoryComposer.occasionKey(nil), [])
        let occasionBlueprints = Set(catalog.occasions.blueprints.map(\.blueprint.id))
        let occasionLines = Set(catalog.occasions.templates.flatMap(\.template.variants).map(\.id))
        XCTAssertFalse(occasionBlueprints.isEmpty)
        for band in [Self.b34, Self.b56, Self.b78, Self.b910] {
            for mode in StoryMode.allCases {
                for seed in (1...30).map({ "ordinary-\($0)" }) {
                    guard let story = try? OfflineStoryComposer().compose(
                        catalog: catalog,
                        intent: OfflineStoryIntent(childName: "İrem", seed: seed, mode: mode, ageBand: band))
                    else { continue }
                    XCTAssertFalse(occasionBlueprints.contains(story.blueprintID), "\(band) \(mode) \(seed)")
                    XCTAssertTrue(occasionLines.isDisjoint(with: story.pages.flatMap(\.variantIDs)), "\(band) \(mode) \(seed)")
                }
            }
        }
    }

    // MARK: - Every day, both bands

    func testEveryOccasionWritesACleanStoryInBothBands() throws {
        let catalog = try catalog()
        var failures: [String] = []
        for entry in catalog.occasions.blueprints {
            let blueprint = entry.blueprint
            let mode = mode(of: blueprint, in: catalog)
            XCTAssertNotNil(mode, blueprint.id.rawValue)
            for seed in ["a", "b", "c", "d"] {
                do {
                    let story = try compose(entry.occasion, band: blueprint.ageRange, mode: mode,
                                            seed: "\(blueprint.id.rawValue)-\(seed)", catalog: catalog)
                    let ids = Set(catalog.occasions.blueprints.filter { $0.occasion == entry.occasion }.map(\.blueprint.id))
                    if !ids.contains(story.blueprintID) { failures.append("\(blueprint.id): wrong blueprint") }
                    if !story.isClean { failures.append("\(blueprint.id) \(seed): not clean") }
                    let first = story.pages.first?.variantIDs ?? []
                    let last = story.pages.last?.variantIDs ?? []
                    if !first.contains(where: { $0.rawValue.hasPrefix("occ_") }) { failures.append("\(blueprint.id): no opening line") }
                    if !last.contains(where: { $0.rawValue.hasPrefix("occ_") }) { failures.append("\(blueprint.id): no closing line") }
                    if blueprint.arc == .bedtime, let text = story.pages.last?.text, !CalmEnding.isCalm(text) {
                        failures.append("\(blueprint.id) \(seed): closing not calm")
                    }
                } catch {
                    failures.append("\(blueprint.id) \(seed): \(error)")
                }
            }
        }
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }

    /// Where each day is offered: birthday and the first school day in
    /// adventure at 5-6, at bedtime at 3-4; a new sibling and the first tooth
    /// at bedtime in both. Nothing at 7-8 and 9-10 yet.
    func testWhereEachDayIsOffered() throws {
        let catalog = try catalog()
        func offered(_ mode: StoryMode, _ band: AgeBand) -> Set<ContentID> {
            Set(BlueprintSelector().availableOccasions(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "İrem", seed: "offer", mode: mode, ageBand: band)).map(\.id))
        }
        XCTAssertEqual(offered(.adventure, Self.b56), [Self.birthday, Self.school])
        XCTAssertEqual(offered(.bedtime, Self.b56), [Self.sibling, Self.tooth])
        XCTAssertEqual(offered(.bedtime, Self.b34), [Self.birthday, Self.school, Self.sibling, Self.tooth])
        XCTAssertEqual(offered(.learning, Self.b56), [])
        for band in [Self.b78, Self.b910] {
            for mode in StoryMode.allCases { XCTAssertEqual(offered(mode, band), [], "\(band) \(mode)") }
        }
    }

    /// The default parent setting (calm, every topic avoided) still offers the
    /// days: their shapes have no tense page.
    func testTheMostProtectiveSettingStillOffersTheDays() throws {
        let catalog = try catalog()
        let offered = BlueprintSelector().availableOccasions(
            catalog: catalog,
            intent: OfflineStoryIntent(childName: "İrem", seed: "offer", mode: .adventure,
                                       ageBand: Self.b56, safety: .mostProtective)).map(\.id)
        XCTAssertEqual(Set(offered), [Self.birthday, Self.school])
    }

    // MARK: - When it cannot be written

    func testAnOccasionThatCannotBeWrittenIsATypedError() throws {
        let catalog = try catalog()
        for (kind, band, mode) in [(Self.birthday, Self.b78, StoryMode.adventure),
                                   (Self.tooth, Self.b56, .adventure),
                                   (ContentID("occasion_unknown"), Self.b56, .bedtime)] {
            XCTAssertThrowsError(try compose(kind, band: band, mode: mode, seed: "x", catalog: catalog)) { error in
                guard case OfflineSelectionError.noOccasionStory = error else {
                    return XCTFail("\(kind) \(band): \(error)")
                }
            }
        }
    }

    // MARK: - The new sibling

    func testTheNewSiblingStoryNamesTheSiblingOrSaysLittleSibling() throws {
        let catalog = try catalog()
        for band in [Self.b34, Self.b56] {
            for seed in ["k1", "k2", "k3"] {
                let named = try compose(Self.sibling, band: band, mode: .bedtime, seed: seed,
                                        sibling: FamilyCast(name: "Ela", relation: .sibling), catalog: catalog)
                let plain = try compose(Self.sibling, band: band, mode: .bedtime, seed: seed, catalog: catalog)
                let namedText = named.pages.map(\.text).joined(separator: " ")
                let plainText = plain.pages.map(\.text).joined(separator: " ")
                XCTAssertTrue(namedText.contains("Ela"), "\(band) \(seed)")
                XCTAssertFalse(plainText.contains("Ela"))
                XCTAssertTrue(plainText.lowercased(with: Locale(identifier: "tr_TR")).contains("kardeş"), "\(band) \(seed)")
                XCTAssertTrue(named.isClean && plain.isClean)
                XCTAssertNotEqual(named.fingerprint, plain.fingerprint)
            }
        }
    }

    // MARK: - No recall on a special day

    func testASpecialDayGetsNoRecallLine() throws {
        let catalog = try catalog()
        let plain = try compose(Self.birthday, band: Self.b56, mode: .adventure, seed: "r1", catalog: catalog)
        let history = RecallHistory(
            companions: [plain.content.companion.id: .init(storyCount: 3, firstSettingID: plain.content.setting.id)],
            visitedSettings: [plain.content.setting.id])
        let withHistory = try compose(Self.birthday, band: Self.b56, mode: .adventure, seed: "r1",
                                      recall: history, catalog: catalog)
        XCTAssertNil(withHistory.recallLineID)
        XCTAssertEqual(withHistory.fingerprint, plain.fingerprint)
    }

    // MARK: - The catalog

    func testTheShippedLayerPassesItsChecks() throws {
        let catalog = try catalog()
        XCTAssertEqual(catalog.occasions.kinds.count, 4)
        XCTAssertEqual(catalog.occasions.blueprints.count, 8)
        let issues = CatalogIntegrityChecker().checkOccasions(catalog)
        XCTAssertTrue(issues.isEmpty, issues.map(\.message).joined(separator: "\n"))
    }

    func testTheCheckerReportsBrokenLines() throws {
        let catalog = try catalog()
        let variant = try JSONDecoder().decode(
            CatalogVariant.self,
            from: Data(#"{"id": "occ_broken_01", "text": "{{family.name}} yarın gelecek mi?"}"#.utf8))
        let broken = OccasionCatalog(
            kinds: catalog.occasions.kinds,
            blueprints: catalog.occasions.blueprints,
            templates: catalog.occasions.templates + [
                OccasionTemplate(occasion: "occasion_nowhere", template: CatalogTemplate(
                    id: "occ_tpl_broken", role: .emotionalEnding, realizesBeat: .warmClose,
                    variants: [variant],
                    ageBand: Self.b56))
            ])
        let rebuilt = ContentCatalog(version: "test", storyModes: catalog.storyModes, occasions: broken)
        let codes = Set(CatalogIntegrityChecker().checkOccasions(rebuilt).map(\.code))
        XCTAssertTrue(codes.isSuperset(of: ["occasion_unknown", "occasion_unknown_slot", "occasion_open_ending"]), "\(codes)")
    }

    func testTheLinesKeepTheLanguageRules() throws {
        let banned = ["—", "üret", "oluştur", "yapay zeka", "hemen", "anında", "saniyeler içinde",
                      "diş perisi", "doktor", "ilaç"]
        for entry in try catalog().occasions.templates {
            for variant in entry.template.variants {
                for word in banned {
                    XCTAssertFalse(variant.text.lowercased(with: Locale(identifier: "tr_TR")).contains(word),
                                   "\(variant.id): \(word)")
                }
            }
        }
    }
}
