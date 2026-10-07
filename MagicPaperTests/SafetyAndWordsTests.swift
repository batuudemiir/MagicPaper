import XCTest
import StoryEngine
@testable import MagicPaper

/// FAZ 17: çocuk başına içerik güvenliği ve sayfa kelimeleri.
final class SafetyAndWordsTests: XCTestCase {

    // MARK: - Güvenlik

    func testAProfileSavedBeforeFaz17OpensMostProtective() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Ada","age":6,"profileType":"child","createdAt":0,"interests":[]}
        """
        let profile = try JSONDecoder().decode(UserProfile.self, from: Data(json.utf8))
        XCTAssertNil(profile.safety)
        XCTAssertEqual(profile.effectiveSafety, .mostProtective)
    }

    func testTheSafetySettingRoundTrips() throws {
        var profile = UserProfile(name: "Ada", age: 6, profileType: .child)
        profile.safety = ContentSafety(level: .someExcitement, avoided: ["darkness"])
        let data = try JSONEncoder().encode(profile)
        let back = try JSONDecoder().decode(UserProfile.self, from: data)
        XCTAssertEqual(back.safety, profile.safety)
    }

    /// A safety value the app cannot read does not lose the profile.
    func testAnUnreadableSafetyValueStillOpensTheProfile() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Ada","age":6,"profileType":"child","createdAt":0,"safety":"bozuk"}
        """
        let profile = try JSONDecoder().decode(UserProfile.self, from: Data(json.utf8))
        XCTAssertEqual(profile.effectiveSafety, .mostProtective)
    }

    // MARK: - Kelimeler

    func testAPageWordKeepsTheSpellingOnThePage() {
        let text = "Kuşlar güzel bir günü müjdeliyordu."
        let start = Array(text).firstIndex(of: "m")!
        let words = OfflineStoryMapper.storyWords(
            [PageWord(glossaryID: "word_mujde", term: "müjdelemek", meaning: "Güzel bir haberi vermek.",
                      start: start, length: "müjdeliyordu".count)], in: text)
        XCTAssertEqual(words.map(\.surface), ["müjdeliyordu"])
        XCTAssertEqual(words.first?.term, "müjdelemek")
    }

    func testAWordOutsideTheTextIsDropped() {
        let words = OfflineStoryMapper.storyWords(
            [PageWord(glossaryID: "x", term: "x", meaning: "y", start: 40, length: 3)], in: "Kısa.")
        XCTAssertTrue(words.isEmpty)
    }

    func testAStoryWrittenBeforeFaz17OpensWithoutWords() throws {
        let page = MagicPaper.StoryPage(title: "", text: "Bir varmış.", imagePrompt: "")
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(page)) as! [String: Any]
        json.removeValue(forKey: "words")
        let back = try JSONDecoder().decode(MagicPaper.StoryPage.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(back.words)
    }

    @MainActor
    func testTheHighlightLinksTheWordInTheParagraph() {
        let word = StoryWord(id: "word_mujde", term: "müjdelemek", meaning: "m", surface: "müjdeliyordu")
        let text = ReaderWords.attributed("Kuşlar MÜJDELİYORDU bunu.", words: [word], size: 19,
                                          ink: .black, highlight: .purple)
        let linked = text.runs.compactMap { $0.link }
        XCTAssertEqual(linked, [URL(string: "mpword://word_mujde")!])
    }

    // MARK: - Okuma ayarları

    func testSpeechRatesGetSlowerToFaster() {
        XCTAssertLessThan(MPSpeechRate.slow.multiplier, MPSpeechRate.normal.multiplier)
        XCTAssertLessThan(MPSpeechRate.normal.multiplier, MPSpeechRate.fast.multiplier)
    }
}
