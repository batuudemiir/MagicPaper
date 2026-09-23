import XCTest
@testable import StoryEngine

/// Story Mode ve yaş bandı: ebeveynin niyeti ve çocuğun yaşı hikâyeyi gerçekten
/// yönlendiriyor mu?
///
/// Ürün kararları (2026-09-23): üç mod var — Gelişelim, Maceraya Çıkalım, Uyku
/// Zamanı. "Bana sürpriz yap" bir mod değil, bir seçim biçimi. Yaş tek bir
/// çözümleyiciden banda dönüşür: 3-4, 5-6, 7-8, 9-10.
final class StoryModeTests: XCTestCase {

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    private let young = AgeBand(lowerBound: 3, upperBound: 4)
    private let mvp = AgeBand(lowerBound: 5, upperBound: 6)

    // MARK: - AgeBandResolver

    func testEveryAgeResolvesToOneCanonicalBand() {
        XCTAssertEqual(AgeBandResolver.band(forAge: 3), young)
        XCTAssertEqual(AgeBandResolver.band(forAge: 4), young)
        XCTAssertEqual(AgeBandResolver.band(forAge: 5), mvp)
        XCTAssertEqual(AgeBandResolver.band(forAge: 6), mvp)
        XCTAssertEqual(AgeBandResolver.band(forAge: 7), AgeBand(lowerBound: 7, upperBound: 8))
        XCTAssertEqual(AgeBandResolver.band(forAge: 10), AgeBand(lowerBound: 9, upperBound: 10))
    }

    func testAgesOutsideTheProductClampToTheNearestEnd() {
        XCTAssertEqual(AgeBandResolver.band(forAge: 2), young)
        XCTAssertEqual(AgeBandResolver.band(forAge: 11), AgeBand(lowerBound: 9, upperBound: 10))
    }

    func testMVPBandIsFiveToSix() {
        XCTAssertEqual(AgeBandResolver.mvp, mvp)
        XCTAssertTrue(AgeBandResolver.bands.contains(AgeBandResolver.mvp))
    }

    func testABandWithoutContentIsServedFromTheNearestYoungerOne() {
        let seven = AgeBand(lowerBound: 7, upperBound: 8)
        let nine = AgeBand(lowerBound: 9, upperBound: 10)
        XCTAssertEqual(AgeBandResolver.servedBand(for: mvp, available: [young, mvp]), mvp)
        XCTAssertEqual(AgeBandResolver.servedBand(for: seven, available: [young, mvp]), mvp)
        // Eşit uzaklık: küçük bant.
        XCTAssertEqual(AgeBandResolver.servedBand(for: seven, available: [mvp, nine]), mvp)
        XCTAssertNil(AgeBandResolver.servedBand(for: seven, available: []))
    }

    // MARK: - StoryModeResolver

    func testDirectChoiceIsHonouredAsIs() throws {
        let mode = try StoryModeResolver().resolve(
            strategy: .direct, requested: .bedtime,
            available: StoryMode.allCases, recent: [.bedtime, .bedtime], seed: "s")
        XCTAssertEqual(mode, .bedtime)
    }

    func testDirectChoiceWithoutAModeIsAnError() {
        XCTAssertThrowsError(try StoryModeResolver().resolve(
            strategy: .direct, requested: nil,
            available: StoryMode.allCases, recent: [], seed: "s"))
    }

    /// Macera, Macera, Gelişelim → yeniden Macera sürpriz değil, tekrardır.
    func testSurpriseAvoidsWhatWasJustRead() throws {
        let mode = try StoryModeResolver().resolve(
            strategy: .surprise, requested: nil,
            available: StoryMode.allCases,
            recent: [.adventure, .adventure, .growth], seed: "s")
        XCTAssertEqual(mode, .bedtime)
    }

    func testSurpriseWeighsTheMostRecentStoryHeaviest() throws {
        // Uyku bu pencerede yok ama kurulamıyor; kalan ikisi birer kez geçti.
        // En yeni Gelişelim olduğu için Macera seçilmeli.
        let mode = try StoryModeResolver().resolve(
            strategy: .surprise, requested: nil,
            available: [.growth, .adventure],
            recent: [.growth, .adventure], seed: "s")
        XCTAssertEqual(mode, .adventure)
    }

    func testSurpriseLooksOnlyAtTheRecentWindow() throws {
        // Dördüncü ve sonrası pencerenin dışında: Uyku orada ne kadar geçerse
        // geçsin, son üçte hiç yok ve seçilmeli.
        let mode = try StoryModeResolver().resolve(
            strategy: .surprise, requested: nil,
            available: StoryMode.allCases,
            recent: [.growth, .adventure, .growth, .bedtime, .bedtime, .bedtime], seed: "s")
        XCTAssertEqual(mode, .bedtime)
    }

    func testSurpriseNeverPicksAnUnavailableMode() throws {
        for seed in (0..<40).map({ "seed-\($0)" }) {
            let mode = try StoryModeResolver().resolve(
                strategy: .surprise, requested: nil,
                available: [.bedtime], recent: [.bedtime, .bedtime, .bedtime], seed: seed)
            XCTAssertEqual(mode, .bedtime)
        }
    }

    func testSurpriseIsReproducibleAndStillVaries() throws {
        let resolver = StoryModeResolver()
        let picks = try (0..<40).map { i in
            try resolver.resolve(strategy: .surprise, requested: nil,
                                 available: StoryMode.allCases, recent: [], seed: "seed-\(i)")
        }
        let again = try (0..<40).map { i in
            try resolver.resolve(strategy: .surprise, requested: nil,
                                 available: StoryMode.allCases, recent: [], seed: "seed-\(i)")
        }
        XCTAssertEqual(picks, again, "Same seed, same history → same mode.")
        XCTAssertGreaterThan(Set(picks).count, 1, "With no history every mode should be reachable.")
    }

    func testSurpriseWithNothingAvailableIsAnError() {
        XCTAssertThrowsError(try StoryModeResolver().resolve(
            strategy: .surprise, requested: nil, available: [], recent: [], seed: "s"))
    }

    // MARK: - Catalog

    func testEveryModeHasAProfileInTheCatalog() throws {
        let catalog = try catalog()
        for mode in StoryMode.allCases {
            let profile = try XCTUnwrap(catalog.modeProfile(mode), mode.rawValue)
            XCTAssertFalse(profile.families.isEmpty, mode.rawValue)
        }
    }

    func testModeProfilesDoNotOverlap() throws {
        let catalog = try catalog()
        let families = catalog.storyModes.flatMap(\.families)
        XCTAssertEqual(families.count, Set(families).count,
                       "A family serving two intents makes the modes indistinguishable.")
    }

    func testTheShippedCatalogHasNoModeFaults() throws {
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        let modeErrors = report.issues.filter { (issue: CatalogIssue) in
            issue.code.hasPrefix("mode_") && issue.severity >= .error
        }
        XCTAssertTrue(modeErrors.isEmpty, modeErrors.map { $0.message }.joined(separator: "\n"))
    }

    func testEveryModeIsAvailableInTheMVPBand() throws {
        let modes = BlueprintSelector().availableModes(catalog: try catalog(), ageBand: mvp)
        XCTAssertEqual(modes, StoryMode.allCases)
    }

    // MARK: - Selection

    func testAModeOnlyReceivesItsOwnFamilies() throws {
        let catalog = try catalog()
        let composer = OfflineStoryComposer()
        for mode in StoryMode.allCases {
            let families = Set(try XCTUnwrap(catalog.modeProfile(mode)).families)
            for seed in (0..<12).map({ "\(mode.rawValue)-\($0)" }) {
                let story = try composer.compose(
                    catalog: catalog,
                    intent: OfflineStoryIntent(childName: "Yeliz", seed: seed, mode: mode, ageBand: mvp))
                let family = try XCTUnwrap(story.family)
                XCTAssertTrue(families.contains(family),
                              "\(mode.rawValue) received '\(family.rawValue)' for seed \(seed)")
            }
        }
    }

    /// Denetimin F3 bulgusu: 3 yaşındaki bir çocuğun sürprizi 8 sayfalık bir
    /// 5-6 masalı getirebiliyordu, çünkü seçici yaşa hiç bakmıyordu.
    func testABandIsNeverServedAnotherBandsBlueprint() throws {
        let catalog = try catalog()
        let composer = OfflineStoryComposer()
        for seed in (0..<20).map({ "young-\($0)" }) {
            let story = try composer.compose(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "Ece", seed: seed, ageBand: young))
            let blueprint = try XCTUnwrap(catalog.blueprint(story.blueprintID))
            XCTAssertEqual(blueprint.ageRange, young, "seed \(seed)")
        }
    }

    func testIdeasAreGroupedUnderTheirMode() throws {
        let catalog = try catalog()
        let selector = BlueprintSelector()
        for mode in StoryMode.allCases {
            let families = Set(try XCTUnwrap(catalog.modeProfile(mode)).families)
            for idea in selector.storyIdeas(catalog: catalog, mode: mode, ageBand: mvp) {
                XCTAssertFalse(families.isDisjoint(with: idea.preferredFamilies),
                               "\(idea.id.rawValue) under \(mode.rawValue)")
                XCTAssertEqual(idea.ageRange, mvp)
            }
        }
    }

    func testAnIntentWithoutModeOrBandBehavesAsBefore() throws {
        let catalog = try catalog()
        let before = try OfflineStoryComposer().compose(
            catalog: catalog, intent: OfflineStoryIntent(childName: "Yeliz", seed: "unchanged"))
        let after = try OfflineStoryComposer().compose(
            catalog: catalog,
            intent: OfflineStoryIntent(childName: "Yeliz", seed: "unchanged", mode: nil, ageBand: nil))
        XCTAssertEqual(before.fingerprint, after.fingerprint)
    }
}
