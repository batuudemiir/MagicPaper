import XCTest
@testable import CharacterEngine

final class CharacterVersionResolverTests: XCTestCase {
    private let resolver = CharacterVersionResolver()

    func testExplicitPinResolvesExactly() throws {
        let v1 = CharacterFixtures.version(number: 1)
        let v2 = CharacterFixtures.version(number: 2)
        let profile = CharacterFixtures.profile(versions: [v1, v2], activeVersionID: v2.id)

        let resolved = try resolver.resolve(profile: profile, pinned: v1.id)

        XCTAssertEqual(resolved.id, v1.id, "A pinned version must win over the active one")
    }

    func testMissingPinThrowsRatherThanSubstituting() {
        let v1 = CharacterFixtures.version(number: 1)
        let profile = CharacterFixtures.profile(versions: [v1])
        let ghost = CharacterVersionID()

        XCTAssertThrowsError(try resolver.resolve(profile: profile, pinned: ghost)) { error in
            XCTAssertEqual(error as? CharacterEngineError, .versionNotFound(profile.id, ghost))
        }
    }

    func testUnpinnedResolvesActiveVersion() throws {
        let v1 = CharacterFixtures.version(number: 1)
        let v2 = CharacterFixtures.version(number: 2)
        let profile = CharacterFixtures.profile(versions: [v1, v2], activeVersionID: v1.id)

        XCTAssertEqual(try resolver.resolve(profile: profile, pinned: nil).id, v1.id)
    }

    func testFallsBackToNewestUsableWhenActiveHasNoReference() throws {
        let usable = CharacterFixtures.version(number: 1)
        let unusable = CharacterFixtures.version(
            number: 2,
            assetSet: CharacterAssetSet(masterReference: nil, identitySeed: 42, stylePresetID: "magic_paper_v1")
        )
        let profile = CharacterFixtures.profile(versions: [usable, unusable], activeVersionID: unusable.id)

        XCTAssertEqual(try resolver.resolve(profile: profile, pinned: nil).id, usable.id)
    }

    func testThrowsWhenNoVersionIsUsable() {
        let unusable = CharacterFixtures.version(
            number: 1,
            assetSet: CharacterAssetSet(masterReference: nil, identitySeed: 42, stylePresetID: "magic_paper_v1")
        )
        let profile = CharacterFixtures.profile(versions: [unusable])

        XCTAssertThrowsError(try resolver.resolve(profile: profile, pinned: nil)) { error in
            XCTAssertEqual(error as? CharacterEngineError, .noUsableVersion(profile.id))
        }
    }
}
