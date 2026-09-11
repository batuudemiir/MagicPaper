import XCTest
@testable import CharacterEngine

final class CharacterAssetSetTests: XCTestCase {
    func testMasterOnlySetIsUsableButNotComplete() {
        let set = CharacterFixtures.assetSet()
        XCTAssertTrue(set.isUsable, "V1 ships with only a master reference and must still work")
        XCTAssertFalse(set.isComplete)
    }

    func testEmptySetIsNotUsable() {
        let set = CharacterAssetSet(identitySeed: 1, stylePresetID: "magic_paper_v1")
        XCTAssertFalse(set.isUsable)
    }

    func testMissingSlotsDegradeToMaster() {
        let master = CharacterFixtures.asset()
        let set = CharacterAssetSet(masterReference: master, identitySeed: 1, stylePresetID: "magic_paper_v1")

        XCTAssertEqual(set.reference(preferring: .fullBody)?.id, master.id)
        XCTAssertEqual(set.reference(preferring: .face)?.id, master.id)
        XCTAssertEqual(set.reference(preferring: .expression, expression: .happy)?.id, master.id)
    }

    func testSpecificSlotsWinWhenPresent() {
        let master = CharacterFixtures.asset(locator: "master.jpg")
        let face = CharacterFixtures.asset(role: .face, locator: "face.jpg")
        let happy = CharacterFixtures.asset(role: .expression, locator: "happy.jpg")
        let set = CharacterAssetSet(
            masterReference: master,
            faceReference: face,
            expressionReferences: [.happy: happy],
            identitySeed: 1,
            stylePresetID: "magic_paper_v1"
        )

        XCTAssertEqual(set.reference(preferring: .face)?.locator, "face.jpg")
        XCTAssertEqual(set.reference(preferring: .expression, expression: .happy)?.locator, "happy.jpg")
        XCTAssertEqual(set.reference(preferring: .expression, expression: .sad)?.locator, "face.jpg",
                       "An unknown expression falls back to the face reference")
    }

    func testReferenceChainIsDeduplicated() {
        let master = CharacterFixtures.asset()
        let set = CharacterAssetSet(masterReference: master, identitySeed: 1, stylePresetID: "magic_paper_v1")
        XCTAssertEqual(set.referenceChain(preferring: .fullBody).count, 1, "Master must not be listed twice")
    }

    func testReferenceChainPrefersSpecificThenMaster() {
        let master = CharacterFixtures.asset(locator: "master.jpg")
        let body = CharacterFixtures.asset(role: .fullBody, locator: "body.jpg")
        let set = CharacterAssetSet(masterReference: master, fullBodyReference: body, identitySeed: 1, stylePresetID: "magic_paper_v1")

        XCTAssertEqual(set.referenceChain(preferring: .fullBody).map(\.locator), ["body.jpg", "master.jpg"])
    }
}
