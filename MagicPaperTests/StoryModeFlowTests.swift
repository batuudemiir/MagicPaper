import XCTest
import StoryEngine
@testable import MagicPaper

/// Story Mode, uygulamanın kapısından: ekranın soracağı sorular ve kaydedilen
/// masalın niyetini hatırlaması.
@MainActor
final class StoryModeFlowTests: XCTestCase {

    private let service = OfflineStoryService.shared

    private func child(age: Int = 6) -> UserProfile {
        UserProfile(name: "Yeliz", age: age, profileType: .child)
    }

    // MARK: - Yaş

    /// Profil ekranının bantları motorun bantlarıdır; ikisi ayrışırsa ekranın
    /// "5-7" dediği bir çocuk yine hiçbir banda tam oturmaz.
    func testAgeChipsAreTheCanonicalBands() {
        XCTAssertEqual(MPAgeRange.allCases.map(\.band), AgeBandResolver.bands)
        for range in MPAgeRange.allCases {
            XCTAssertEqual(MPAgeRange.from(age: range.representativeAge), range)
            XCTAssertEqual(AgeBandResolver.band(forAge: range.representativeAge), range.band)
        }
    }

    /// Eski chip'lerle kaydedilmiş yaşlar (9 ve 11) yeni bir banda oturur.
    func testAgesSavedByTheOldChipsStillResolve() {
        XCTAssertEqual(MPAgeRange.from(age: 9), .r910)
        XCTAssertEqual(MPAgeRange.from(age: 11), .r910)
    }

    func testABandWithoutContentIsServedFromTheNearestOne() {
        XCTAssertEqual(service.servedBand(forAge: 6), AgeBandResolver.mvp)
        XCTAssertEqual(service.servedBand(forAge: 8), AgeBandResolver.mvp,
                       "7-8 has no content yet; it is served from 5-6.")
    }

    // MARK: - Modlar

    func testEveryModeIsOfferedInTheMVPBand() {
        XCTAssertEqual(service.availableModes(forAge: 6), StoryMode.allCases)
    }

    func testOnlyBuildableModesAreOffered() {
        for age in [3, 4, 6, 8, 10] {
            for mode in service.availableModes(forAge: age) {
                XCTAssertNoThrow(try service.compose(
                    childName: "Yeliz", ideaID: nil, companionID: nil,
                    mode: mode, age: age, seed: "offer-\(age)-\(mode.rawValue)"),
                    "\(mode.rawValue) is offered at \(age) but cannot be built")
            }
        }
    }

    func testIdeasUnderAModeBelongToIt() {
        for mode in StoryMode.allCases {
            for idea in service.storyIdeas(forAge: 6, mode: mode) {
                XCTAssertTrue(idea.suits(age: 6), idea.id.rawValue)
            }
        }
    }

    func testSurpriseResolvesToARealMode() throws {
        let mode = try service.resolveMode(
            strategy: .surprise, requested: nil, forAge: 6,
            recent: [.adventure, .adventure, .learning], seed: "s")
        XCTAssertEqual(mode, .bedtime)
    }

    // MARK: - Kayıt

    func testAStoryRemembersItsIntent() throws {
        let profile = child()
        let composed = try service.compose(
            childName: profile.name, ideaID: nil, companionID: nil,
            mode: .adventure, age: profile.age, seed: "remember")
        let story = OfflineStoryMapper.appStory(
            from: composed.story, childName: profile.name, childProfileID: profile.id,
            storyIdeaID: nil, catalogVersion: composed.catalogVersion,
            mode: .adventure, selectionStrategy: .surprise,
            ageBand: service.servedBand(forAge: profile.age))

        XCTAssertEqual(story.origin?.modeID, "adventure")
        XCTAssertEqual(story.origin?.selectionStrategy, "surprise")
        XCTAssertEqual(story.origin?.ageBand, "5-6")

        let decoded = try JSONDecoder().decode(
            MagicPaper.Story.self, from: JSONEncoder().encode(story))
        XCTAssertEqual(decoded.origin, story.origin)
    }

    /// Modlardan önce kaydedilmiş bir masal hâlâ açılır.
    func testAStorySavedBeforeModesStillDecodes() throws {
        let profile = child()
        let composed = try service.compose(
            childName: profile.name, ideaID: nil, companionID: nil, seed: "old")
        let story = OfflineStoryMapper.appStory(
            from: composed.story, childName: profile.name, childProfileID: profile.id,
            storyIdeaID: nil, catalogVersion: composed.catalogVersion)
        var json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(story)) as? [String: Any])
        var origin = try XCTUnwrap(json["origin"] as? [String: Any])
        origin.removeValue(forKey: "modeID")
        origin.removeValue(forKey: "selectionStrategy")
        origin.removeValue(forKey: "ageBand")
        json["origin"] = origin

        let decoded = try JSONDecoder().decode(
            MagicPaper.Story.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(decoded.origin?.modeID)
        XCTAssertEqual(decoded.origin?.blueprintID, story.origin?.blueprintID)
    }

    // MARK: - FAZ 10: growth → learning

    /// 3 Ekim 2026 öncesi masallar `modeID = "growth"` taşıyor ve yeniden
    /// yazılmıyor. Açılmalı, "Yeni şeyler öğrenelim" olarak görünmeli ve metni
    /// değişmemeli.
    func testAStorySavedAsGrowthOpensAsLearning() throws {
        let story = try storedStory(mode: .learning, seed: "legacy-growth")
        let decoded = try decode(story) { origin in origin["modeID"] = "growth" }

        XCTAssertEqual(decoded.origin?.modeID, "growth", "kayıt yeniden yazılmaz")
        XCTAssertEqual(decoded.origin?.mode, .learning)
        XCTAssertEqual(decoded.mpMode, .learning)
        XCTAssertTrue(MPShelfFilter.mode(.learning).admits(decoded))
        XCTAssertEqual(decoded.pages.map(\.text), story.pages.map(\.text))
        XCTAssertEqual(decoded.origin?.blueprintID, story.origin?.blueprintID)
    }

    func testANewLearningStoryWritesTheNewName() throws {
        let story = try storedStory(mode: .learning, seed: "new-learning")
        XCTAssertEqual(story.origin?.modeID, "learning")
        XCTAssertEqual(story.origin?.mode, .learning)
    }

    // MARK: - FAZ 10: bant × mod

    /// Kabul ölçütü: üç mod ve sürpriz her bantta ya masal üretiyor ya da modu
    /// göstermiyor. 11 ve 12, eski profillerden kalan yaşlar.
    func testEveryBandEitherBuildsOrHidesEachMode() throws {
        for age in 3...12 {
            let offered = service.availableModes(forAge: age)
            XCTAssertFalse(offered.isEmpty, "\(age) yaşında hiç mod yok")
            for mode in offered {
                XCTAssertNoThrow(try service.compose(
                    childName: "Yeliz", ideaID: nil, companionID: nil,
                    mode: mode, age: age, seed: "band-\(age)-\(mode.rawValue)"),
                    "\(mode.rawValue) \(age) yaşında sunuluyor ama kurulamıyor")
            }
            let surprise = try service.resolveMode(
                strategy: .surprise, requested: nil, forAge: age, recent: [], seed: "band-\(age)")
            XCTAssertTrue(offered.contains(surprise), "sürpriz sunulmayan bir moda düştü: \(age)")
        }
    }

    func testTheYoungestBandOffersOnlyBedtimeToday() {
        XCTAssertEqual(service.availableModes(forAge: 3), [.bedtime])
        XCTAssertEqual(service.availableModes(forAge: 4), [.bedtime])
    }

    func testElevenAndTwelveAreServedAsNineToTen() {
        let nineToTen = AgeBand(lowerBound: 9, upperBound: 10)
        XCTAssertEqual(AgeBandResolver.band(forAge: 11), nineToTen)
        XCTAssertEqual(AgeBandResolver.band(forAge: 12), nineToTen)
        XCTAssertEqual(service.servedBand(forAge: 11), service.servedBand(forAge: 10))
        XCTAssertEqual(service.availableModes(forAge: 12), service.availableModes(forAge: 10))
    }

    // MARK: - FAZ 10: sürpriz tek seferlik

    /// Faz 13 seriyi yalnızca doğrudan seçilmiş masaldan açar; bunun için
    /// sürpriz masal stratejisini kaydetmeli.
    func testASurpriseStoryRecordsItsStrategy() throws {
        let profile = child()
        let mode = try service.resolveMode(
            strategy: .surprise, requested: nil, forAge: profile.age, recent: [], seed: "one-off")
        let story = try storedStory(mode: mode, strategy: .surprise, seed: "one-off")
        XCTAssertEqual(story.origin?.selectionStrategy, "surprise")
        XCTAssertEqual(story.origin?.mode, mode)

        let direct = try storedStory(mode: .adventure, strategy: .direct, seed: "chosen")
        XCTAssertEqual(direct.origin?.selectionStrategy, "direct")
    }

    // MARK: - FAZ 10: alt seçenek

    func testANewStoryHasNoSubOption() throws {
        XCTAssertNil(try storedStory(mode: .bedtime, seed: "no-sub").origin?.subOptionID)
    }

    func testAStorySavedBeforeSubOptionsDecodesWithNil() throws {
        let story = try storedStory(mode: .bedtime, seed: "before-sub")
        let decoded = try decode(story) { origin in origin.removeValue(forKey: "subOptionID") }
        XCTAssertNil(decoded.origin?.subOptionID)
        XCTAssertEqual(decoded.origin?.mode, .bedtime)
    }

    func testASubOptionIsRemembered() throws {
        let story = try storedStory(mode: .bedtime, seed: "with-sub", subOption: "x")
        XCTAssertEqual(story.origin?.subOptionID, "x")
        let decoded = try JSONDecoder().decode(MagicPaper.Story.self, from: JSONEncoder().encode(story))
        XCTAssertEqual(decoded.origin?.subOptionID, "x")
    }

    // MARK: - FAZ 10: fikir adımı bayrağı

    func testTheIdeaStepIsOffByDefault() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "faz10-idea-step"))
        defaults.removePersistentDomain(forName: "faz10-idea-step")
        XCTAssertFalse(StoryIdeaStepAccess.isEnabled(defaults: defaults))
    }

    // MARK: - Yardımcılar

    private func storedStory(
        mode: StoryMode,
        strategy: StorySelectionStrategy = .direct,
        seed: String,
        subOption: String? = nil
    ) throws -> MagicPaper.Story {
        let profile = child()
        let composed = try service.compose(
            childName: profile.name, ideaID: nil, companionID: nil,
            mode: mode, age: profile.age, seed: seed, subOption: subOption)
        return OfflineStoryMapper.appStory(
            from: composed.story, childName: profile.name, childProfileID: profile.id,
            storyIdeaID: nil, catalogVersion: composed.catalogVersion,
            mode: mode, selectionStrategy: strategy,
            ageBand: service.servedBand(forAge: profile.age),
            subOption: subOption)
    }

    /// Kaydı JSON düzeyinde değiştirip geri çözer — diskteki eski bir masal gibi.
    private func decode(
        _ story: MagicPaper.Story,
        editingOrigin edit: (inout [String: Any]) -> Void
    ) throws -> MagicPaper.Story {
        var json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(story)) as? [String: Any])
        var origin = try XCTUnwrap(json["origin"] as? [String: Any])
        edit(&origin)
        json["origin"] = origin
        return try JSONDecoder().decode(
            MagicPaper.Story.self, from: JSONSerialization.data(withJSONObject: json))
    }
}
