import XCTest
import StoryEngine
@testable import MagicPaper

/// Rozet planı R1 (15 Kasım 2026, `docs/ROZET_PLANI.md`): 69 rozetlik katalog,
/// defterin yeni alanları, eski defterin göçü ve sessiz geriye dönük kazanım.
@MainActor
final class BadgePlanTests: XCTestCase {

    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return c
    }()

    private func at(_ month: Int, _ day: Int, _ hour: Int = 15, year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    // MARK: - Katalog

    func testTheCatalogHasSixtyNineUniqueBadges() {
        XCTAssertEqual(MPBadgeCatalog.all.count, 69)
        XCTAssertEqual(Set(MPBadgeCatalog.all.map(\.id)).count, 69)
        XCTAssertEqual(MPBadgeCatalog.all.filter(\.isSecret).count, 4)
    }

    func testTheEightFaz17BadgesKeepTheirIDs() {
        for id in ["firstStory", "fiveStories", "tenStories", "twentyFiveStories",
                   "sevenBedtime", "firstAdventure", "firstLearning", "firstSeriesCompleted"] {
            XCTAssertNotNil(MPBadgeCatalog.badge(id), id)
        }
    }

    func testTiersRiseWithinEachFamily() {
        for family in MPBadgeFamily.allCases where family.isTiered {
            let thresholds = MPBadgeCatalog.badges(in: family).map(\.threshold)
            XCTAssertEqual(thresholds, thresholds.sorted(), family.rawValue)
            XCTAssertEqual(Set(thresholds).count, thresholds.count, family.rawValue)
        }
    }

    /// Kilitli rozet yalnızca eylem söyler: kalan sayı, "kaldı", "az" yok (ilke 7).
    func testLockedHintsNeverCountDown() {
        for badge in MPBadgeCatalog.all {
            XCTAssertFalse(badge.lockedHint.contains("kaldı"), badge.id)
            XCTAssertFalse(badge.lockedHint.lowercased().contains("az "), badge.id)
            XCTAssertNil(badge.lockedHint.rangeOfCharacter(from: .decimalDigits), badge.id)
        }
    }

    func testASecretBadgeHidesItsNameUntilEarned() {
        let secret = MPBadgeCatalog.badge("morningStory")!
        XCTAssertEqual(secret.displayTitle(unlocked: false), "Gizli rozet")
        XCTAssertEqual(secret.displayTitle(unlocked: true), "Sabah masalı")
        XCTAssertEqual(MPBadge.firstStory.displayTitle(unlocked: false), "İlk masal")
    }

    // MARK: - Ölçüler

    func testReadingDaysCountDistinctDaysNotStreaks() {
        var ledger = MPBadgeLedger()
        for d in [1, 3, 9] { ledger.recordFinished(storyID: "s\(d)", mode: nil, at: at(11, d), calendar: calendar) }
        ledger.recordFinished(storyID: "x", mode: nil, at: at(11, 9, 18), calendar: calendar)
        XCTAssertEqual(ledger.value(of: .readingDays), 3)
        XCTAssertTrue(ledger.earnedIDs.contains("readingDays3"))
    }

    func testRereadingCountsOncePerDay() {
        var ledger = MPBadgeLedger()
        for hour in [15, 16, 17] { ledger.recordFinished(storyID: "a", mode: nil, at: at(11, 2, hour), calendar: calendar) }
        XCTAssertEqual(ledger.value(of: .rereadDays), 1, "aynı gün sayfayı ileri geri çevirmek sayılmaz")
        ledger.recordFinished(storyID: "a", mode: nil, at: at(11, 4), calendar: calendar)
        ledger.recordFinished(storyID: "a", mode: nil, at: at(11, 6), calendar: calendar)
        XCTAssertTrue(ledger.earnedIDs.contains("rereadThree"))
        XCTAssertEqual(ledger.finished.count, 1, "tekrar okuma yeni masal sayılmaz")
    }

    func testAMorningStoryIsBeforeNoon() {
        var ledger = MPBadgeLedger()
        ledger.recordFinished(storyID: "a", mode: nil, at: at(11, 2, 15), calendar: calendar)
        XCTAssertFalse(ledger.earnedIDs.contains("morningStory"))
        ledger.recordFinished(storyID: "b", mode: nil, at: at(11, 3, 9), calendar: calendar)
        XCTAssertTrue(ledger.earnedIDs.contains("morningStory"))
    }

    func testTheWeekendBadgeNeedsSaturdayAndSunday() {
        var ledger = MPBadgeLedger()
        // 14 Kasım 2026 cumartesi, 15 Kasım pazar.
        ledger.recordFinished(storyID: "a", mode: nil, at: at(11, 14), calendar: calendar)
        XCTAssertEqual(ledger.value(of: .fullWeekend, calendar: calendar), 0)
        ledger.recordFinished(storyID: "b", mode: nil, at: at(11, 16), calendar: calendar)
        XCTAssertEqual(ledger.value(of: .fullWeekend, calendar: calendar), 0, "pazartesi sayılmaz")
        ledger.recordFinished(storyID: "c", mode: nil, at: at(11, 15), calendar: calendar)
        XCTAssertEqual(ledger.value(of: .fullWeekend, calendar: calendar), 1)
    }

    func testTheAnniversaryComesAYearAfterTheFirstStory() {
        var ledger = MPBadgeLedger()
        ledger.recordFinished(storyID: "a", mode: nil, at: at(11, 15), calendar: calendar)
        ledger.recordFinished(storyID: "b", mode: nil, at: at(11, 14, year: 2027), calendar: calendar)
        XCTAssertFalse(ledger.earnedIDs.contains("anniversary"))
        ledger.recordFinished(storyID: "c", mode: nil, at: at(12, 1, year: 2027), calendar: calendar)
        XCTAssertTrue(ledger.earnedIDs.contains("anniversary"), "tarih geçince de ilk masalda kazanılır")
    }

    func testStoryFactsFillTheirFamilies() {
        var ledger = MPBadgeLedger()
        for i in 0..<3 {
            var facts = MPFinishFacts(storyID: "s\(i)", mode: .adventure)
            facts.placeID = "place\(i)"
            facts.companionIDs = ["friend\(i)"]
            facts.familyMemberIDs = ["anne"]
            facts.newWords = ["kelime\(i)"]
            ledger.recordFinished(facts, at: at(11, 2), calendar: calendar)
        }
        XCTAssertTrue(ledger.earnedIDs.isSuperset(of: ["places3", "friends3", "familyInStory", "firstWord"]))
        XCTAssertFalse(ledger.earnedIDs.contains("bigFamily"), "aynı aile üyesi bir kez sayılır")
        XCTAssertTrue(ledger.recordWordCardOpened().contains { $0.id == "wordCard" })
    }

    // MARK: - Göç ve birleşme

    /// FAZ 17'nin defteri (yeni alanlar yok) okunur, rozet tarihleri kalır.
    func testAFaz17LedgerStillDecodes() throws {
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let json = """
        {"finished":["a"],"finishedBedtime":["a"],"finishedAdventure":[],"finishedLearning":[],
         "completedSeries":[],"earned":{"firstStory":\(date.timeIntervalSinceReferenceDate)}}
        """
        let ledger = try JSONDecoder().decode(MPBadgeLedger.self, from: Data(json.utf8))
        XCTAssertEqual(ledger.earned[MPBadge.firstStory.id], date)
        XCTAssertEqual(ledger.finishedBedtime, ["a"])
        XCTAssertEqual(ledger.catalogVersion, 0)
        XCTAssertNil(ledger.morningRuleSince)
    }

    func testANewLedgerRoundTrips() throws {
        var ledger = MPBadgeLedger()
        var facts = MPFinishFacts(storyID: "a", mode: .learning)
        facts.placeID = "orman"
        ledger.recordFinished(facts, at: at(11, 2), calendar: calendar)
        ledger.morningRuleSince = at(11, 1)
        ledger.awardStarLevels(score: 30)
        let decoded = try JSONDecoder().decode(MPBadgeLedger.self, from: JSONEncoder().encode(ledger))
        XCTAssertEqual(decoded, ledger)
    }

    func testMergingNeverLowersTheScoreOrLosesALevel() {
        var a = MPBadgeLedger(); a.morningRuleSince = at(11, 1); a.starLevels = ["starLevel1": at(11, 5)]
        var b = MPBadgeLedger(); b.morningRuleSince = at(11, 9); b.starLevels = ["starLevel1": at(11, 3)]
        b.wordCardOpened = true
        let merged = a.merged(with: b)
        XCTAssertEqual(merged.morningRuleSince, at(11, 9), "en geç geçiş: eski sabahlar azalmaz")
        XCTAssertEqual(merged.starLevels["starLevel1"], at(11, 3))
        XCTAssertTrue(merged.wordCardOpened)
    }

    /// Güncellemeden sonra ilk açılış: eski defter kitaplıktan doldurulur, yeni
    /// eşiklere ulaşan rozetler sessizce verilir (kutlama yok), eskiler kalır.
    func testUpgradingAwardsNewBadgesSilently() {
        let defaults = UserDefaults(suiteName: "BadgePlanTests-\(UUID().uuidString)")!
        let store = MPBadgeStore(defaults: defaults)
        let profile = UserProfile(name: "Ada", age: 6)
        let oldDate = Date(timeIntervalSinceReferenceDate: 700_000_000)
        var old = MPBadgeLedger()
        old.finished = ["x", "y", "z"]
        old.earned = [MPBadge.firstStory.id: oldDate]
        store.save(old, for: profile.id)

        let ledger = store.ledger(for: profile, stories: [], now: at(11, 16))
        XCTAssertEqual(ledger.earned[MPBadge.firstStory.id], oldDate, "eski rozetin tarihi kalır")
        XCTAssertTrue(ledger.earnedIDs.contains("threeStories"))
        XCTAssertTrue(ledger.seen.contains("threeStories"), "geriye dönük rozet kutlanmaz")
        XCTAssertEqual(ledger.catalogVersion, MPBadgeCatalog.version)
        XCTAssertNotNil(ledger.morningRuleSince)
        XCTAssertEqual(store.ledger(for: profile, stories: [], now: at(11, 17)), ledger, "bir kez göç eder")
    }

    func testAFreshFinishIsNotMarkedSeen() {
        let defaults = UserDefaults(suiteName: "BadgePlanTests-\(UUID().uuidString)")!
        let store = MPBadgeStore(defaults: defaults)
        let profile = UserProfile(name: "Ada", age: 6)
        var story = ReaderFixtures.textStory(pages: 2)
        story.childProfileID = profile.id
        let awards = store.recordFinished(story, profile: profile, stories: [], now: at(11, 16))
        XCTAssertTrue(awards.badges.contains(.firstStory))
        XCTAssertFalse(store.storedLedger(for: profile.id)!.seen.contains(MPBadge.firstStory.id),
                       "masal sonu anı kutlayacak (R4)")
    }

    // MARK: - R2: masalın bilgisi

    private func engineStory(strategy: String = "direct", family: String? = nil) -> MagicPaper.Story {
        var story = MagicPaper.Story(title: "Bir", childName: "Ada", theme: .fantasy, language: .turkish,
                                     status: .completed,
                                     pages: [MagicPaper.StoryPage(title: "", text: "a", imagePrompt: ""),
                                             MagicPaper.StoryPage(title: "", text: "b", imagePrompt: "")])
        story.origin = StoryOrigin(seed: "s", storyIdeaID: nil, blueprintID: "bp", settingID: "orman",
                                   companionID: "baykus", discoveryID: "d", fingerprint: "f",
                                   catalogVersion: "c", worldID: nil, modeID: "adventure",
                                   selectionStrategy: strategy, ageBand: "5-6")
        story.origin?.familyCharacterID = family
        story.pages[0].words = [StoryWord(id: "w1", term: "fener", meaning: "m", surface: "fener")]
        story.pages[1].words = [StoryWord(id: "w1", term: "fener", meaning: "m", surface: "fener"),
                                StoryWord(id: "w2", term: "patika", meaning: "m", surface: "patika")]
        return story
    }

    func testFactsComeFromTheStoryOrigin() {
        let facts = MPBadgeStore.facts(for: engineStory(family: "anneanne"))
        XCTAssertEqual(facts.placeID, "orman")
        XCTAssertEqual(facts.companionIDs, ["baykus"])
        XCTAssertEqual(facts.familyMemberIDs, ["anneanne"])
        XCTAssertEqual(Set(facts.newWords), ["w1", "w2"], "aynı kelime bir kez")
        XCTAssertFalse(facts.isSurprise)
        XCTAssertFalse(facts.heardFamilyVoice)
        XCTAssertNil(facts.classicID)
        XCTAssertNil(facts.originalID)
    }

    func testASurpriseStoryAndTheFamilyVoiceAreRecorded() {
        let facts = MPBadgeStore.facts(for: engineStory(strategy: "surprise"), heardFamilyVoice: true)
        XCTAssertTrue(facts.isSurprise)
        XCTAssertTrue(facts.heardFamilyVoice)
        XCTAssertTrue(facts.familyMemberIDs.isEmpty)
    }

    func testAStoryWithoutOriginGivesOnlyItsWords() {
        var story = ReaderFixtures.textStory(pages: 2)
        story.origin = nil
        let facts = MPBadgeStore.facts(for: story)
        XCTAssertNil(facts.placeID)
        XCTAssertTrue(facts.companionIDs.isEmpty)
        XCTAssertFalse(facts.isSurprise)
    }

    func testFinishingARealStoryFillsTheNewFamilies() {
        let defaults = UserDefaults(suiteName: "BadgePlanTests-\(UUID().uuidString)")!
        let store = MPBadgeStore(defaults: defaults)
        let profile = UserProfile(name: "Ada", age: 6)
        var story = engineStory(strategy: "surprise", family: "dede")
        story.childProfileID = profile.id
        let awards = store.recordFinished(story, profile: profile, stories: [], heardFamilyVoice: true,
                                          now: at(11, 16))
        let ids = Set(awards.badges.map(\.id))
        XCTAssertTrue(ids.isSuperset(of: ["firstStory", "firstAdventure", "firstWord", "surprise",
                                         "familyInStory", "familiarVoice"]))
        let ledger = store.storedLedger(for: profile.id)!
        XCTAssertEqual(ledger.places, ["orman"])
        XCTAssertEqual(ledger.companions, ["baykus"])
    }

    func testTheWordCardFlagWaitsForTheStoryEnding() {
        let defaults = UserDefaults(suiteName: "BadgePlanTests-\(UUID().uuidString)")!
        let store = MPBadgeStore(defaults: defaults)
        let profile = UserProfile(name: "Ada", age: 6)
        store.markWordCardOpened(for: profile.id)
        XCTAssertNil(store.storedLedger(for: profile.id)?.earned["wordCard"], "masal ortasında kutlama yok")
        var story = ReaderFixtures.textStory(pages: 2)
        story.childProfileID = profile.id
        let awards = store.recordFinished(story, profile: profile, stories: [], now: at(11, 16))
        XCTAssertTrue(awards.badges.contains { $0.id == "wordCard" })
    }
}
