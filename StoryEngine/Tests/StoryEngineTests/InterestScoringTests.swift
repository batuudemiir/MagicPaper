import XCTest
@testable import StoryEngine

/// İlgi alanı ağırlığı ve cooldown (FAZ 12).
///
/// Kabul: aynı çocuk için sabit tohumla 20 ardışık masalda ilgi alanı payı
/// artıyor ama tek konuya çökmüyor. Her masalın içeriği bir sonrakinin
/// `recent`'ine girer, uygulamanın yaptığı gibi.
///
/// Etiketleme teste aittir (`music` İnce Ses'te ve Şenlik Çayırı'nda): bugünkü
/// görünür kelimeler (Hayvanlar, Doğa) neredeyse her masalla eşleştiği için
/// bir payın artışını gösteremez, ve motor testi içerik değiştikçe oynamamalı.
final class InterestScoringTests: XCTestCase {

    private let b56 = AgeBand(lowerBound: 5, upperBound: 6)

    private func catalog() throws -> ContentCatalog {
        try InterestFixtures.retagging(ContentCatalogLoader().load().catalog, [
            "object_faint_sound_001": ["music"],
            "setting_festival_meadow_001": ["music"]
        ])
    }

    private struct Run {
        let stories: [ComposedStory]
        let wanted: Set<InterestTag>

        func matches(_ story: ComposedStory) -> Bool {
            story.content.setting.matches(wanted)
                || story.content.companion.matches(wanted)
                || story.content.discovery.matches(wanted)
        }
        var share: Double { Double(stories.filter(matches).count) / Double(stories.count) }
        var settings: [ContentID] { stories.map(\.content.setting.id) }
        var longestSettingRun: Int {
            var longest = 0, current = 0
            var previous: ContentID?
            for id in settings {
                current = id == previous ? current + 1 : 1
                longest = max(longest, current)
                previous = id
            }
            return longest
        }
        /// The most stories in a row that were all about the interest.
        var longestInterestRun: Int {
            var longest = 0, current = 0
            for story in stories {
                current = matches(story) ? current + 1 : 0
                longest = max(longest, current)
            }
            return longest
        }
    }

    /// Twenty stories in a row for one child, each one's content fed back as
    /// history for the next, newest first.
    private func run(
        _ catalog: ContentCatalog,
        interests: [InterestTag],
        history: Bool = true,
        seeds: String = "faz12",
        count: Int = 20
    ) throws -> Run {
        let composer = OfflineStoryComposer()
        var stories: [ComposedStory] = []
        for index in 0..<count {
            let recent = history
                ? stories.reversed().prefix(SelectionScoring.cooldownWindow).map {
                    RecentContent(blueprintID: $0.blueprintID, settingID: $0.content.setting.id,
                                  companionID: $0.content.companion.id, discoveryID: $0.content.discovery.id)
                }
                : []
            let intent = OfflineStoryIntent(
                childName: "Yeliz", seed: "\(seeds)-\(index)", ageBand: b56,
                interests: interests, recent: Array(recent))
            stories.append(try composer.compose(catalog: catalog, intent: intent))
        }
        return Run(stories: stories, wanted: Set(interests))
    }

    // MARK: - Acceptance

    /// Three fixed seed sets, so the claim is not one lucky sequence.
    private let seedSets = ["faz12-0", "faz12-1", "faz12-2"]

    func testAnInterestRaisesItsShareWithoutCollapsingOntoIt() throws {
        let catalog = try catalog()
        for seeds in seedSets {
            let baseline = try run(catalog, interests: [], seeds: seeds)
            let liked = try run(catalog, interests: ["music"], seeds: seeds)
            let baselineShare = Run(stories: baseline.stories, wanted: ["music"]).share

            XCTAssertGreaterThan(liked.share, baselineShare,
                                 "\(seeds): baseline \(baselineShare), with interest \(liked.share)")
            XCTAssertLessThanOrEqual(liked.share, 0.6, "\(seeds): most stories stay about other things")
            XCTAssertLessThanOrEqual(liked.longestInterestRun, 4, seeds)
            XCTAssertGreaterThanOrEqual(Set(liked.settings).count, 3, "\(seeds): \(liked.settings)")
            XCTAssertGreaterThanOrEqual(Set(liked.stories.compactMap(\.family)).count, 2, seeds)
            XCTAssertLessThanOrEqual(liked.longestSettingRun, 3, "\(seeds): \(liked.settings)")
            XCTAssertTrue(liked.stories.allSatisfy(\.isClean), seeds)
        }
    }

    /// Cooldown works for every child, with or without interests: with history
    /// no place comes back more than twice in a row.
    func testHistoryAloneSpreadsStoriesOut() throws {
        let catalog = try catalog()
        for seeds in seedSets {
            let withHistory = try run(catalog, interests: [], seeds: seeds)
            XCTAssertLessThanOrEqual(withHistory.longestSettingRun, 2, "\(seeds): \(withHistory.settings)")
        }
    }

    func testTheSameChildAndSeedsGiveTheSameBooks() throws {
        let catalog = try catalog()
        let first = try run(catalog, interests: ["music"])
        let second = try run(catalog, interests: ["music"])
        XCTAssertEqual(first.stories.map(\.fingerprint), second.stories.map(\.fingerprint))
    }

    // MARK: - Nothing changes when nothing is asked

    /// No interests and no history is every story before FAZ 12.
    func testNoInterestsAndNoHistoryIsTheOldBook() throws {
        let catalog = try catalog()
        let composer = OfflineStoryComposer()
        for index in 0..<20 {
            let old = OfflineStoryIntent(childName: "Yeliz", seed: "same-\(index)", ageBand: b56)
            let new = OfflineStoryIntent(childName: "Yeliz", seed: "same-\(index)", ageBand: b56,
                                         interests: [], recent: [])
            XCTAssertEqual(try composer.compose(catalog: catalog, intent: old).fingerprint,
                           try composer.compose(catalog: catalog, intent: new).fingerprint)
        }
    }

    /// An interest every candidate matches weighs them all the same, so it
    /// changes nothing — which is today's "Hayvanlar": every companion is an
    /// animal.
    func testAnInterestEverythingMatchesChangesNothing() throws {
        let base = try ContentCatalogLoader().load().catalog
        var everything: [String: [String]] = [:]
        base.settings.forEach { everything[$0.id.rawValue] = ["animals"] }
        base.companions.forEach { everything[$0.id.rawValue] = ["animals"] }
        base.objects.forEach { everything[$0.id.rawValue] = ["animals"] }
        base.blueprints.forEach { everything[$0.id.rawValue] = ["animals"] }
        let tagged = try InterestFixtures.retagging(base, everything)
        let composer = OfflineStoryComposer()
        for index in 0..<20 {
            let plain = OfflineStoryIntent(childName: "Yeliz", seed: "all-\(index)", ageBand: b56)
            let liked = OfflineStoryIntent(childName: "Yeliz", seed: "all-\(index)", ageBand: b56,
                                           interests: ["animals"])
            XCTAssertEqual(try composer.compose(catalog: base, intent: plain).fingerprint,
                           try composer.compose(catalog: tagged, intent: liked).fingerprint)
        }
    }

    /// An interest the catalog cannot serve leaves the story as it was.
    func testAnInterestNothingCarriesChangesNothing() throws {
        let catalog = try catalog()
        let composer = OfflineStoryComposer()
        for index in 0..<10 {
            let plain = OfflineStoryIntent(childName: "Yeliz", seed: "none-\(index)", ageBand: b56)
            let liked = OfflineStoryIntent(childName: "Yeliz", seed: "none-\(index)", ageBand: b56,
                                           interests: ["dinosaurs"])
            XCTAssertEqual(try composer.compose(catalog: catalog, intent: plain).fingerprint,
                           try composer.compose(catalog: catalog, intent: liked).fingerprint)
        }
    }

    // MARK: - Pins win

    /// A companion the child chose is honoured even when it was in the last
    /// story: weight orders the pool, it never overrides a choice.
    func testAChosenCompanionIsKeptEvenWhenItIsCooling() throws {
        let catalog = try catalog()
        let rabbit: ContentID = "companion_rabbit_pilot_001"
        let intent = OfflineStoryIntent(
            childName: "Yeliz", companionID: rabbit, seed: "pin", ageBand: b56,
            interests: ["music"], recent: [RecentContent(companionID: rabbit)])
        XCTAssertEqual(try OfflineStoryComposer().compose(catalog: catalog, intent: intent).content.companion.id,
                       rabbit)
    }

    // MARK: - Scoring

    func testWeights() {
        let id: ContentID = "a"
        XCTAssertEqual(SelectionScoring.weight(id: id, matchesInterest: false, recent: []), 1)
        XCTAssertEqual(SelectionScoring.weight(id: id, matchesInterest: true, recent: []), 3)
        XCTAssertEqual(SelectionScoring.weight(id: id, matchesInterest: false, recent: [id]), 0.1, accuracy: 1e-9)
        XCTAssertEqual(SelectionScoring.weight(id: id, matchesInterest: false, recent: [nil, id]), 0.325, accuracy: 1e-9)
        XCTAssertEqual(SelectionScoring.weight(id: id, matchesInterest: false, recent: [nil, nil, nil, id]), 0.775, accuracy: 1e-9)
        XCTAssertEqual(SelectionScoring.weight(id: id, matchesInterest: false, recent: [nil, nil, nil, nil, id]), 1)
        XCTAssertEqual(SelectionScoring.weight(id: id, matchesInterest: true, recent: [id]), 0.3, accuracy: 1e-9)
        // An authored cooldown of 0 never cools.
        XCTAssertEqual(SelectionScoring.weight(id: id, matchesInterest: false, cooldown: 0, recent: [id]), 1)
    }

    func testEqualWeightsKeepTheSeededRotation() {
        let items: [ContentID] = ["a", "b", "c", "d", "e"]
        for seed in ["x", "y", "z", "w"] {
            let start = DeterministicPicker.index(count: items.count, seed: seed, salt: "s")
            let ordered = SelectionScoring.ordered(items, weights: [2, 2, 2, 2, 2], id: { $0 }, seed: seed, salt: "s")
            XCTAssertEqual(ordered, Array(items[start...] + items[..<start]))
        }
    }

    /// A heavier item comes first more often, but not always.
    func testAHeavierItemLeadsMoreOftenButNotAlways() {
        let items: [ContentID] = ["a", "b", "c", "d"]
        var leads = 0
        for index in 0..<200 {
            let ordered = SelectionScoring.ordered(
                items, weights: [3, 1, 1, 1], id: { $0 }, seed: "lead-\(index)", salt: "s")
            if ordered.first == "a" { leads += 1 }
        }
        // Expected share 3/6 = 0.5 against 1/4 for an even pick.
        XCTAssertGreaterThan(leads, 70)
        XCTAssertLessThan(leads, 140)
    }
}
