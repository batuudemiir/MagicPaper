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
            recent: [.adventure, .adventure, .growth], seed: "s")
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
}
