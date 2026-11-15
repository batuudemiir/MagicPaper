import XCTest
@testable import MagicPaper

/// Arayüz kademesi (`KidLevel`): yaştan türer, ebeveynin seçimi yaşı ezer.
final class KidLevelTests: XCTestCase {

    func testPreschoolBandsAreLittle() {
        for age in 3...6 {
            XCTAssertEqual(KidLevel.resolve(age: age, readsAlone: nil), .little, "yaş \(age)")
        }
    }

    func testSchoolBandsAreBig() {
        for age in 7...10 {
            XCTAssertEqual(KidLevel.resolve(age: age, readsAlone: nil), .big, "yaş \(age)")
        }
    }

    func testParentChoiceOverridesAge() {
        XCTAssertEqual(KidLevel.resolve(age: 5, readsAlone: true), .big)
        XCTAssertEqual(KidLevel.resolve(age: 9, readsAlone: false), .little)
    }

    func testProfileSavedBeforeTheFieldStillLoads() throws {
        let old = #"{"id":"6F1E0C5A-0000-4000-8000-000000000001","name":"İrem","age":5,"profileType":"child","createdAt":0,"interests":[]}"#
        let profile = try JSONDecoder().decode(UserProfile.self, from: Data(old.utf8))
        XCTAssertNil(profile.readsAlone)
        XCTAssertEqual(profile.kidLevel, .little)
    }

    func testParentChoiceSurvivesSaving() throws {
        var profile = UserProfile(name: "Ali", age: 6)
        profile.readsAlone = true
        let loaded = try JSONDecoder().decode(UserProfile.self, from: JSONEncoder().encode(profile))
        XCTAssertEqual(loaded.readsAlone, true)
        XCTAssertEqual(loaded.kidLevel, .big)
    }
}
