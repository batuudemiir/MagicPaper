import XCTest
@testable import MagicPaper

/// "Kaç masalda göründü" sayacı (FAZ 11): kayıtlı masalın kökenindeki
/// kimlikten sayılır, adla değil.
final class FamilyCharacterAppearancesTests: XCTestCase {

    private func story(familyID: UUID?, readable: Bool = true) -> Story {
        var origin = StoryOrigin(seed: "s", blueprintID: "bp", settingID: "st", companionID: "c",
                                 discoveryID: "d", fingerprint: "f", catalogVersion: "2.0.0")
        origin.familyCharacterID = familyID?.uuidString
        return Story(
            title: "A", childName: "Yeliz", childProfileID: UUID(), theme: .fantasy, language: .turkish,
            status: readable ? .completed : .writingStory,
            pages: readable ? [StoryPage(id: UUID(), title: "", text: "Bir varmış.", imagePrompt: "")] : [],
            origin: origin)
    }

    func testItCountsOnlyThatCharactersReadableStories() {
        let ela = UUID(), deniz = UUID()
        let stories = [story(familyID: ela), story(familyID: ela), story(familyID: deniz),
                       story(familyID: nil), story(familyID: ela, readable: false)]
        XCTAssertEqual(FamilyCharacterAppearances.count(of: ela, in: stories), 2)
        XCTAssertEqual(FamilyCharacterAppearances.count(of: deniz, in: stories), 1)
        XCTAssertEqual(FamilyCharacterAppearances.count(of: UUID(), in: stories), 0)
    }
}
