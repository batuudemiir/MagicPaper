import XCTest
@testable import CharacterEngine

final class CharacterProfileTests: XCTestCase {
    func testAppendingVersionActivatesItAndKeepsHistory() {
        let v1 = CharacterFixtures.version(number: 1)
        let profile = CharacterFixtures.profile(versions: [v1])
        let v2 = CharacterFixtures.version(number: 2)

        let updated = profile.appending(v2)

        XCTAssertEqual(updated.activeVersionID, v2.id)
        XCTAssertEqual(updated.versions.count, 2)
        XCTAssertNotNil(updated.version(id: v1.id), "Old versions stay resolvable for already-generated stories")
    }

    func testAppendingWithoutActivatingKeepsCurrentActive() {
        let v1 = CharacterFixtures.version(number: 1)
        let profile = CharacterFixtures.profile(versions: [v1])
        let updated = profile.appending(CharacterFixtures.version(number: 2), activate: false)

        XCTAssertEqual(updated.activeVersionID, v1.id)
    }

    func testLatestVersionIsByNumberNotOrder() {
        let v3 = CharacterFixtures.version(number: 3)
        let v1 = CharacterFixtures.version(number: 1)
        let profile = CharacterFixtures.profile(versions: [v3, v1])

        XCTAssertEqual(profile.latestVersion?.id, v3.id)
    }

    func testIdentityAuthorizedPhrasesAreNormalized() {
        let identity = CharacterFixtures.identity(descriptors: [
            CharacterDescriptor(category: .hair, value: "  Curly   Black Hair "),
            CharacterDescriptor(category: .hair, value: "ponytail")
        ])
        XCTAssertEqual(identity.authorizedPhrases[.hair], ["curly black hair", "ponytail"])
    }

    func testDescriptorConfidenceIsClamped() {
        XCTAssertEqual(CharacterDescriptor(category: .eyes, value: "brown eyes", confidence: 5).confidence, 1)
        XCTAssertEqual(CharacterDescriptor(category: .eyes, value: "brown eyes", confidence: -2).confidence, 0)
    }
}
