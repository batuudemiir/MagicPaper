import XCTest
@testable import CharacterEngine

/// Does the same child come out the same way twice?
///
/// This is the product promise underneath "the child becomes a recurring
/// character". The parts that must not drift between two generations are the
/// `CharacterID`, the `identitySeed` and — for a story already on the shelf —
/// the `CharacterVersionID` it was drawn against.
final class CharacterIdentityStabilityTests: XCTestCase {

    // MARK: - Repeated resolution

    func testResolvingTwiceYieldsTheSameIdentity() async throws {
        let profile = CharacterFixtures.profile()
        let resolver = CharacterResolver(store: InMemoryCharacterStore([profile]))
        let binding = CastBinding(protagonist: profile.id)

        let first = try await resolver.resolveCast(for: binding)
        let second = try await resolver.resolveCast(for: binding)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.protagonist.versionID, second.protagonist.versionID)
        XCTAssertEqual(first.protagonist.identity.identitySeed, second.protagonist.identity.identitySeed)
    }

    /// A round trip through storage must not change what the engine is told.
    func testIdentitySurvivesSerialization() throws {
        let profile = CharacterFixtures.profile()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(CharacterProfile.self, from: encoder.encode(profile))

        XCTAssertEqual(decoded.id, profile.id)
        XCTAssertEqual(decoded.activeVersionID, profile.activeVersionID)
        XCTAssertEqual(decoded.activeVersion?.identity.identitySeed, profile.activeVersion?.identity.identitySeed)
        XCTAssertEqual(decoded.activeVersion?.assetSet.identitySeed, profile.activeVersion?.assetSet.identitySeed)
    }

    // MARK: - What an update is allowed to move

    /// Appending a version is how a parent edits a child. The character's own
    /// id must not move, or every story ever generated for her is orphaned.
    func testAppendingAVersionKeepsTheCharacterID() {
        let profile = CharacterFixtures.profile()
        let updated = profile.appending(CharacterFixtures.version(number: 2))

        XCTAssertEqual(updated.id, profile.id)
        XCTAssertEqual(updated.ownerProfileID, profile.ownerProfileID)
        XCTAssertEqual(updated.createdAt, profile.createdAt)
    }

    /// A story that pinned version 1 keeps resolving to version 1 after the
    /// parent re-derives the child. This is the guarantee that lets a book
    /// stay the book it was.
    func testPinnedVersionIsUnaffectedByANewerOne() async throws {
        let v1 = CharacterFixtures.version(number: 1)
        let profile = CharacterFixtures.profile(versions: [v1], activeVersionID: v1.id)
        let store = InMemoryCharacterStore([profile])

        let v2 = CharacterFixtures.version(
            number: 2,
            identity: CharacterFixtures.identity(descriptors: [
                CharacterDescriptor(category: .hair, value: "short blonde hair")
            ])
        )
        try await store.save(profile.appending(v2))

        let resolver = CharacterResolver(store: store)
        let pinned = try await resolver.resolveCast(
            for: CastBinding(protagonist: profile.id, versionID: v1.id)
        )
        let current = try await resolver.resolveCast(for: CastBinding(protagonist: profile.id))

        XCTAssertEqual(pinned.protagonist.versionID, v1.id)
        XCTAssertEqual(pinned.protagonist.identity.descriptors, v1.identity.descriptors)
        XCTAssertEqual(current.protagonist.versionID, v2.id)
        XCTAssertNotEqual(pinned.protagonist.identity.descriptors, current.protagonist.identity.descriptors)
    }

    /// The seed is what makes an image request reproducible. A version bump
    /// that carried a new seed would change how the child renders even when
    /// nothing about her description changed — so the bridge copies it forward,
    /// and this states the rule the bridge has to keep.
    func testCarryingTheSeedForwardKeepsRenderingStable() {
        let v1 = CharacterFixtures.version(number: 1)
        let v2 = CharacterVersion(
            versionNumber: 2,
            createdAt: CharacterFixtures.referenceDate.addingTimeInterval(10),
            identity: CharacterIdentity(
                ageYears: v1.identity.ageYears,
                pronouns: v1.identity.pronouns,
                descriptors: [CharacterDescriptor(category: .eyes, value: "green eyes")],
                identitySeed: v1.identity.identitySeed
            ),
            styleProfile: v1.styleProfile,
            assetSet: v1.assetSet,
            provenance: .authoredByParent
        )

        XCTAssertEqual(v2.identity.identitySeed, v1.identity.identitySeed)
        XCTAssertEqual(v2.assetSet.identitySeed, v1.assetSet.identitySeed)
        XCTAssertNotEqual(v2.id, v1.id)
    }

    // MARK: - Where stability is not guaranteed

    /// Names it rather than pretending otherwise: `CharacterVersionID` and
    /// `CharacterAsset.id` are fresh UUIDs, not functions of their content.
    /// Two snapshots built from identical input are *not* interchangeable, so a
    /// migration that rebuilds versions instead of copying them breaks every
    /// pin — and the rebuilt version is not even `==` the original, which is
    /// how a "nothing changed" check would miss it.
    ///
    /// `CharacterID`, by contrast, is supplied by the caller and can be derived
    /// from the app's profile id. That asymmetry is the whole migration rule.
    func testVersionIdentifiersAreNotDerivedFromContent() {
        let a = CharacterFixtures.version(number: 1)
        let b = CharacterFixtures.version(number: 1)

        XCTAssertEqual(a.identity, b.identity)
        XCTAssertEqual(a.assetSet.identitySeed, b.assetSet.identitySeed)
        XCTAssertEqual(a.assetSet.masterReference?.locator, b.assetSet.masterReference?.locator)

        XCTAssertNotEqual(a.id, b.id, "Rebuilding a version mints a new id — migrations must copy, not rebuild.")
        XCTAssertNotEqual(a.assetSet.masterReference?.id, b.assetSet.masterReference?.id)
        XCTAssertNotEqual(a, b, "Identical input does not produce an equal version.")
    }

    /// `CharacterID` carries a UUID the caller chooses, so the app can key a
    /// character to the child's profile id and get the same character every
    /// launch without storing a mapping.
    func testCharacterIDIsStableForTheSameUUID() {
        let profileID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        XCTAssertEqual(CharacterID(profileID), CharacterID(profileID))
    }
}
