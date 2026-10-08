import XCTest
import StoryEngine
@testable import MagicPaper

/// FAZ 17 (MVP deneyimi), ekran dışı mantık: içerik güvenliğinin profilden
/// motora gitmesi, yeni kelimelerin toplanması, sesli okumanın geç gelen
/// haberleri ve rozet defterinin eşitlemeye haber vermesi.
@MainActor
final class MVPExperienceTests: XCTestCase {

    private let service = OfflineStoryService.shared

    override func tearDown() {
        service.currentSafety = nil
        super.tearDown()
    }

    // MARK: - İçerik güvenliği

    /// A profile saved before FAZ 17 has no `safety`: it is read as the most
    /// protective setting, never as nothing filtered.
    func testAProfileSavedBeforeFaz17IsMostProtective() throws {
        let json = """
        { "id": "6F2C1B8E-3D7A-4C55-9F3E-2B1A0C9D8E7F", "name": "Elif", "age": 5,
          "profileType": "child", "createdAt": 780000000, "interests": ["animals"] }
        """
        let profile = try JSONDecoder().decode(UserProfile.self, from: Data(json.utf8))
        XCTAssertNil(profile.safety)
        XCTAssertEqual(profile.effectiveSafety, .mostProtective)
        XCTAssertEqual(profile.interests, ["animals"])
    }

    func testTheSettingSurvivesARoundTrip() throws {
        var profile = UserProfile(name: "Ada", age: 6)
        profile.safety = ContentSafety(level: .someExcitement, avoided: ["darkness"])
        let decoded = try JSONDecoder().decode(UserProfile.self, from: JSONEncoder().encode(profile))
        XCTAssertEqual(decoded.effectiveSafety, ContentSafety(level: .someExcitement, avoided: ["darkness"]))
    }

    func testTheCatalogOffersTheApprovedTopicsAndNoDeath() {
        let ids = service.safetyTopics().map(\.id.rawValue)
        XCTAssertEqual(ids, ["darkness", "alone", "fear", "weather", "heights"])
        XCTAssertFalse(ids.contains { ["death", "loss", "ölüm", "kayıp"].contains($0) })
    }

    /// The default setting hides no mode today.
    func testTheDefaultSettingStillOffersEveryMode() {
        for age in [3, 5, 6, 8] {
            service.currentSafety = nil
            let open = service.availableModes(forAge: age)
            service.currentSafety = .mostProtective
            XCTAssertEqual(service.availableModes(forAge: age), open, "\(age)")
        }
    }

    /// A calm story for a child avoiding every topic: no uneasy page, no line
    /// tagged dark, never the night garden.
    func testAStoryForACalmChildIsCalm() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let darkLines = Set((catalog.templates + catalog.series.templates)
            .flatMap(\.variants).filter { $0.topics.contains("darkness") }.map(\.id))
        XCTAssertFalse(darkLines.isEmpty)
        service.currentSafety = .mostProtective
        for mode in StoryMode.allCases {
            for _ in 0..<4 {
                let built = try service.compose(childName: "Ada", ideaID: nil, companionID: nil, mode: mode, age: 6)
                let blueprint = try XCTUnwrap(catalog.blueprint(built.story.blueprintID))
                XCTAssertTrue(ContentSafety.mostProtective.admits(blueprint: blueprint), "\(blueprint.id)")
                XCTAssertTrue(Set(built.story.pages.flatMap(\.variantIDs)).isDisjoint(with: darkLines))
                XCTAssertNotEqual(built.story.content.setting.id.rawValue, "setting_night_garden_001")
            }
        }
    }

    // MARK: - Yeni kelimeler

    func testAPageSavedBeforeFaz17HasNoWords() throws {
        let json = """
        { "id": "6F2C1B8E-3D7A-4C55-9F3E-2B1A0C9D8E7F", "title": "", "text": "Bir varmış.",
          "imagePrompt": "" }
        """
        XCTAssertNil(try JSONDecoder().decode(MagicPaper.StoryPage.self, from: Data(json.utf8)).words)
    }

    /// A word written without `surface` (an early FAZ 17 build) still opens:
    /// one missing field must not take the whole library down.
    func testAWordWithoutASurfaceStillDecodes() throws {
        let json = #"{"id":"w56_usulca","term":"usulca","meaning":"Yavaşça.","start":4,"length":6}"#
        let word = try JSONDecoder().decode(StoryWord.self, from: Data(json.utf8))
        XCTAssertEqual(word.surface, "usulca")
    }

    /// The surface is the word as the page spells it; a range that does not
    /// fit the text is dropped, never guessed.
    func testTheMapperKeepsTheSurfaceAndDropsABadRange() {
        let text = "Ada usulca baktı."
        let words = OfflineStoryMapper.storyWords([
            PageWord(glossaryID: "w_u", term: "usulca", meaning: "Yavaşça.", start: 4, length: 6),
            PageWord(glossaryID: "w_x", term: "x", meaning: "", start: 15, length: 9),
        ], in: text)
        XCTAssertEqual(words.map(\.id), ["w_u"])
        XCTAssertEqual(words.first?.surface, "usulca")
    }

    private func story(_ title: String, read: Int?, daysAgo: Double, pages: [[StoryWord]]) -> MagicPaper.Story {
        var s = MagicPaper.Story(title: title, childName: "Ada", theme: .fantasy, language: .turkish, status: .completed,
                                 pages: pages.map { words in
                                     var page = MagicPaper.StoryPage(title: "", text: "usulca sabır", imagePrompt: "")
                                     page.words = words
                                     return page
                                 })
        s.lastReadPage = read
        s.lastReadAt = read.map { _ in Date().addingTimeInterval(-daysAgo * 86_400) }
        return s
    }

    /// Only pages the child reached count, each word once, from the first
    /// story it was met in.
    func testCollectedWordsAreFromReadPagesOnce() {
        let usulca = StoryWord(id: "w56_usulca", term: "usulca", meaning: "Yavaşça.", surface: "usulca")
        let sabir = StoryWord(id: "w56_sabir", term: "sabır", meaning: "Beklemek.", surface: "sabır")
        let unread = StoryWord(id: "w_x", term: "x", meaning: "", surface: "x")
        let words = MPVocabulary.collectedWords(in: [
            story("Eski", read: 0, daysAgo: 5, pages: [[usulca]]),
            story("Yeni", read: 1, daysAgo: 1, pages: [[usulca], [sabir]]),
            story("Okunmamış", read: nil, daysAgo: 0, pages: [[unread]]),
            story("Yarım", read: 0, daysAgo: 0, pages: [[], [unread]]),
        ])
        XCTAssertEqual(Set(words.map(\.id)), ["w56_usulca", "w56_sabir"])
        XCTAssertEqual(words.first { $0.id == "w56_usulca" }?.storyTitle, "Eski")
        XCTAssertEqual(words.first?.id, "w56_sabir", "newest first")
        XCTAssertEqual(MPVocabulary.collectedThisWeek(words).count, 2)
        XCTAssertEqual(MPVocabulary.collectedThisWeek(words, now: Date().addingTimeInterval(4 * 86_400)).map(\.id),
                       ["w56_sabir"])
    }

    func testShippedStoriesCarryWordsToTheApp() throws {
        var found = 0
        for seed in (0..<12).map({ "words-\($0)" }) {
            let built = try service.compose(childName: "Ada", ideaID: nil, companionID: nil,
                                            mode: .learning, age: 6, seed: seed)
            for page in built.story.pages {
                for word in OfflineStoryMapper.appPage(from: page).words ?? [] {
                    found += 1
                    XCTAssertTrue(page.text.contains(word.surface), word.surface)
                }
            }
        }
        XCTAssertGreaterThan(found, 0, "no 5-6 learning story in twelve taught a word")
    }

    // MARK: - Sesli okuma

    /// A late "finished" or "cancelled" from a stopped reading is not the
    /// current one: it must not turn the page or clear the new reading.
    func testALateSpeechCallbackIsNotTheCurrentReading() {
        let speech = MPSpeech.shared
        speech.stop()
        let stale = ObjectIdentifier(NSObject())
        XCTAssertFalse(speech.isCurrent(stale))
    }

    // MARK: - Rozetler

    private func badgeStore() -> MPBadgeStore {
        MPBadgeStore(defaults: UserDefaults(suiteName: "MVPExperienceTests-\(UUID().uuidString)")!)
    }

    private func finishedStory(for profile: UserProfile) -> MagicPaper.Story {
        var s = MagicPaper.Story(title: "Bir", childName: profile.name, childProfileID: profile.id, theme: .fantasy,
                                 language: .turkish, status: .completed,
                                 pages: [MagicPaper.StoryPage(title: "", text: "a", imagePrompt: "")])
        s.lastReadPage = 0
        return s
    }

    /// A new badge tells the account sync, like every other family store.
    func testFinishingAStoryTellsTheSync() {
        let profile = UserProfile(name: "Ada", age: 6)
        let story = finishedStory(for: profile)
        let posted = expectation(forNotification: .mpFamilyDataChanged, object: nil)
        XCTAssertEqual(badgeStore().recordFinished(story, profile: profile, stories: []), [.firstStory])
        wait(for: [posted], timeout: 1)
    }

    /// A badge outlives the story that earned it: deleting the story from the
    /// library takes nothing away.
    func testABadgeOutlivesItsStory() {
        let profile = UserProfile(name: "Ada", age: 6)
        let store = badgeStore()
        let story = finishedStory(for: profile)
        _ = store.recordFinished(story, profile: profile, stories: [story])
        XCTAssertEqual(store.ledger(for: profile, stories: []).earnedMilestones, [.firstStory])
    }

    // MARK: - Üretim başarısız (43)

    /// A story the safety setting rules out is told apart from any other
    /// failure, and the sentence blames no one.
    func testASafetyFailureIsToldApart() {
        let calmOnly = OfflineSelectionError.noBlueprintForChoices(
            reasons: ["  bp (threshold): has a 'unease' page and the parent chose calm stories"])
        XCTAssertEqual(StoryFailureReason(OfflineStoryService.Failure.noStoryForChoices(
            detail: calmOnly.explanation)), .safetySetting)
        XCTAssertEqual(StoryFailureReason(OfflineStoryService.Failure.noStoryForChoices(detail: "No template")),
                       .general)
        XCTAssertNotEqual(StoryFailureReason.safetySetting.message, StoryFailureReason.general.message)
    }

    /// The markers the app looks for are the ones the engine writes.
    func testTheSafetyMarkersMatchTheEngine() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let calm = OfflineStoryIntent(childName: "Ada", seed: "s", mode: .adventure,
                                      ageBand: AgeBand(lowerBound: 5, upperBound: 6), safety: .mostProtective)
        let reasons = BlueprintSelector().admissible(catalog: catalog, intent: calm).rejections
        XCTAssertTrue(reasons.contains { line in StoryFailureReason.safetyMarkers.contains(where: line.contains) },
                      "\(reasons)")
    }
}
