import XCTest
import StoryEngine
@testable import MagicPaper

/// Kullanıcının yazdığı ad log'a düşmemeli (FAZ 11, kabul kriteri).
///
/// Log satırları ad içermiyor; bu test, birisi ileride bir modeli olduğu gibi
/// loglarsa (`\(character)`) adın yine çıkmadığını sabitler.
final class FamilyCharacterPrivacyTests: XCTestCase {

    private let secretName = "Gizliad"

    func testTheModelNeverPrintsTheName() {
        let character = FamilyCharacter(childID: UUID(), name: secretName, relation: .animal(kindID: "family_animal_cat"))
        XCTAssertFalse(String(describing: character).contains(secretName))
        XCTAssertFalse(String(reflecting: character).contains(secretName))
        XCTAssertFalse("\(character)".contains(secretName))
        var dumped = ""
        dump(character, to: &dumped)
        XCTAssertFalse(dumped.contains(secretName), dumped)
        XCTAssertTrue(String(describing: character).contains("animal"))
    }

    func testTheEngineCastNeverPrintsTheName() {
        let cast = FamilyCast(name: secretName, relation: .sibling)
        XCTAssertFalse(String(describing: cast).contains(secretName))
        var dumped = ""
        dump(cast, to: &dumped)
        XCTAssertFalse(dumped.contains(secretName), dumped)
    }

    /// The text the service logs when a story cannot be built.
    @MainActor
    func testAFailedBuildDoesNotCarryTheName() throws {
        let pet = FamilyCharacter(childID: UUID(), name: secretName, relation: .animal(kindID: "no_such_kind"))
        XCTAssertThrowsError(try OfflineStoryService.shared.compose(
            childName: "Yeliz", ideaID: nil, companionID: nil, mode: .bedtime, age: 6, family: pet)
        ) { error in
            XCTAssertFalse(String(describing: error).contains(self.secretName), "\(error)")
        }
    }
}
