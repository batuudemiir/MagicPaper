import XCTest
import CharacterEngine
@testable import MagicPaper

/// The bridge from what the parent typed to who the child is in the engine.
///
/// The product promise is "characterize once, reuse in every story", and the
/// whole of that promise rests on one property: the same `UserProfile` has to
/// produce the same character identity every time, on every device, forever.
/// Nothing here may consult the clock, the network, or a random number.
@MainActor
final class ProfileCharacterSourceTests: XCTestCase {

    private let source = ProfileCharacterSource()

    private let childID = UUID(uuidString: "3F2504E0-4F89-11D3-9A0C-0305E82C3301")!
    private let otherID = UUID(uuidString: "3F2504E0-4F89-11D3-9A0C-0305E82C3302")!
    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func profile(id: UUID? = nil, name: String = "Deniz", age: Int = 6) -> UserProfile {
        UserProfile(id: id ?? childID, name: name, age: age, profileType: .child)
    }

    private func character(
        _ profile: UserProfile? = nil,
        reference: String? = "https://example.test/master.jpg",
        descriptors: [CharacterDescriptor] = [
            CharacterDescriptor(category: .hair, value: "curly black hair")
        ]
    ) -> CharacterProfile {
        source.makeProfile(
            from: profile ?? self.profile(),
            referenceLocator: reference,
            pronouns: .turkish,
            parentProvidedDescriptors: descriptors,
            now: referenceDate
        )
    }

    // MARK: - Determinism

    /// Building the character twice from the same profile must agree on
    /// everything that decides how the child is drawn.
    func testSameProfileProducesTheSameIdentityTwice() {
        let input = profile()
        let first = character(input)
        let second = character(input)

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(first.ownerProfileID, second.ownerProfileID)
        XCTAssertEqual(first.activeVersion?.identity.identitySeed,
                       second.activeVersion?.identity.identitySeed)
        XCTAssertEqual(first.activeVersion?.assetSet.identitySeed,
                       second.activeVersion?.assetSet.identitySeed)
        XCTAssertEqual(first.activeVersion?.contentFingerprint,
                       second.activeVersion?.contentFingerprint)
    }

    /// A character is keyed to the profile id, so the app never has to store a
    /// mapping and a reinstall that restores profiles restores characters.
    func testCharacterIDIsTheProfileID() {
        XCTAssertEqual(character().id, CharacterID(childID))
    }

    /// The seed is a pure function of the profile id — no clock, no entropy.
    func testSeedIsDerivedOnlyFromTheProfileID() {
        XCTAssertEqual(ProfileCharacterSource.seed(from: childID),
                       ProfileCharacterSource.seed(from: childID))
        XCTAssertNotEqual(ProfileCharacterSource.seed(from: childID),
                          ProfileCharacterSource.seed(from: otherID))
    }

    /// Two children in the same family must not collide into one look.
    func testDifferentChildrenGetDifferentIdentities() {
        let a = character(profile(id: childID))
        let b = character(profile(id: otherID))

        XCTAssertNotEqual(a.id, b.id)
        XCTAssertNotEqual(a.activeVersion?.identity.identitySeed,
                          b.activeVersion?.identity.identitySeed)
    }

    /// Renaming or ageing must not move the seed: the child is the same child.
    func testIdentityDoesNotDependOnNameOrAge() {
        let a = character(profile(name: "Deniz", age: 5))
        let b = character(profile(name: "Ada", age: 9))

        XCTAssertEqual(a.id, b.id)
        XCTAssertEqual(a.activeVersion?.identity.identitySeed,
                       b.activeVersion?.identity.identitySeed)
    }

    // MARK: - Mapping

    func testProfileFieldsReachTheCharacter() {
        let input = profile(name: "Deniz", age: 7)
        let built = character(input)

        XCTAssertEqual(built.displayName, "Deniz")
        XCTAssertEqual(built.activeVersion?.identity.ageYears, 7)
        XCTAssertEqual(built.ownerProfileID, input.id)
        XCTAssertEqual(built.createdAt, input.createdAt)
        XCTAssertEqual(built.versions.count, 1)
        XCTAssertEqual(built.activeVersion?.versionNumber, 1)
    }

    /// V1 collects no appearance data, so most characters start with none. That
    /// has to produce a valid character, not a broken one.
    func testAProfileWithNoOptionalDataStillProducesACharacter() {
        let built = source.makeProfile(
            from: profile(),
            referenceLocator: nil,
            pronouns: .turkish,
            now: referenceDate
        )

        XCTAssertEqual(built.id, CharacterID(childID))
        XCTAssertTrue(built.activeVersion?.identity.descriptors.isEmpty ?? false)
        XCTAssertTrue(built.activeVersion?.identity.doNotDepict.isEmpty ?? false)
        XCTAssertNil(built.activeVersion?.assetSet.masterReference)
        XCTAssertNotNil(built.activeVersion)
    }

    /// Provenance has to say the appearance was not invented: without a photo
    /// step and without parent input, the character is seeded, not observed.
    func testProvenanceReflectsWhereTheDescriptorsCameFrom() {
        let seeded = source.makeProfile(
            from: profile(), referenceLocator: nil, pronouns: .turkish, now: referenceDate
        )
        let authored = character()

        XCTAssertEqual(seeded.activeVersion?.provenance, .seeded)
        XCTAssertEqual(authored.activeVersion?.provenance, .authoredByParent)
    }

    /// No descriptor may ever carry a source other than `.parentProvided` while
    /// there is no vision step — an inferred appearance would be a guess about
    /// a child's face.
    func testNothingIsInferredAboutAppearance() {
        let built = character()
        for descriptor in built.activeVersion?.identity.descriptors ?? [] {
            XCTAssertEqual(descriptor.source, .parentProvided)
        }
    }

    // MARK: - Syncing a parent's edit

    /// The bug this closes: `ProfileManager.updateProfile(age:)` changed
    /// `UserProfile.age` and nothing carried it into `identity.ageYears`, so
    /// every later illustration kept describing the child at the old age.
    func testAgeEditReachesTheCharacterIdentity() {
        let existing = character(profile(age: 5))
        let synced = source.syncing(existing, with: profile(age: 6), now: referenceDate)

        XCTAssertEqual(synced.activeVersion?.identity.ageYears, 6)
    }

    /// The book drawn at five keeps its five-year-old.
    func testAgeEditAppendsRatherThanRewrites() {
        let existing = character(profile(age: 5))
        let originalVersionID = existing.activeVersionID
        let synced = source.syncing(existing, with: profile(age: 6), now: referenceDate)

        XCTAssertEqual(synced.versions.count, 2)
        XCTAssertEqual(synced.version(id: originalVersionID)?.identity.ageYears, 5)
        XCTAssertNotEqual(synced.activeVersionID, originalVersionID)
        XCTAssertTrue(synced.preservesVersionIdentity(of: existing))
    }

    /// Ageing must not change how the child looks.
    func testAgeEditKeepsTheSeedDescriptorsAndReference() {
        let existing = character(profile(age: 5))
        let synced = source.syncing(existing, with: profile(age: 6), now: referenceDate)

        XCTAssertEqual(synced.id, existing.id)
        XCTAssertEqual(synced.activeVersion?.identity.identitySeed,
                       existing.activeVersion?.identity.identitySeed)
        XCTAssertEqual(synced.activeVersion?.identity.descriptors,
                       existing.activeVersion?.identity.descriptors)
        XCTAssertEqual(synced.activeVersion?.assetSet.masterReference?.locator,
                       existing.activeVersion?.assetSet.masterReference?.locator)
    }

    /// A name is not an appearance fact, so it applies at once and mints no
    /// version — a library full of near-identical snapshots helps nobody.
    func testNameEditAppliesWithoutAddingAVersion() {
        let existing = character(profile(name: "Deniz"))
        let synced = source.syncing(existing, with: profile(name: "Ada"), now: referenceDate)

        XCTAssertEqual(synced.displayName, "Ada")
        XCTAssertEqual(synced.versions.count, 1)
        XCTAssertEqual(synced.activeVersionID, existing.activeVersionID)
    }

    /// Safe to call on every profile save: an edit that changed nothing must
    /// not grow the history, or opening the editor would age the character.
    func testSyncingAnUnchangedProfileIsANoOp() {
        let input = profile()
        let existing = character(input)

        XCTAssertEqual(source.syncing(existing, with: input, now: referenceDate), existing)
    }

    func testSyncingIsIdempotent() {
        let existing = character(profile(age: 5))
        let edited = profile(name: "Ada", age: 6)

        let once = source.syncing(existing, with: edited, now: referenceDate)
        let twice = source.syncing(once, with: edited, now: referenceDate)

        XCTAssertEqual(once, twice)
        XCTAssertEqual(twice.versions.count, 2)
    }

    // MARK: - Updating

    /// Re-describing a child without a new photo must not take away the photo
    /// every illustration of them has been conditioned on.
    func testUpdatingWithoutAReferenceKeepsTheExistingOne() {
        let existing = character()
        let updated = source.updating(
            existing,
            descriptors: [CharacterDescriptor(category: .eyes, value: "brown eyes")],
            now: referenceDate
        )

        XCTAssertEqual(updated.activeVersion?.assetSet.masterReference?.locator,
                       "https://example.test/master.jpg")
        XCTAssertTrue(updated.activeVersion?.isUsable ?? false)
    }

    /// An omitted descriptor list means "unchanged", not "forget what you know".
    func testUpdatingWithoutDescriptorsKeepsThem() {
        let existing = character()
        let updated = source.updating(
            existing,
            referenceLocator: "https://example.test/new.jpg",
            now: referenceDate
        )

        XCTAssertEqual(updated.activeVersion?.identity.descriptors,
                       existing.activeVersion?.identity.descriptors)
        XCTAssertEqual(updated.activeVersion?.assetSet.masterReference?.locator,
                       "https://example.test/new.jpg")
    }

    func testUpdatingCarriesTheSeedForward() {
        let existing = character()
        let updated = source.updating(
            existing,
            referenceLocator: "https://example.test/new.jpg",
            descriptors: [CharacterDescriptor(category: .eyes, value: "green eyes")],
            now: referenceDate
        )

        XCTAssertEqual(updated.activeVersion?.identity.identitySeed,
                       existing.activeVersion?.identity.identitySeed)
        XCTAssertEqual(updated.activeVersion?.assetSet.identitySeed,
                       existing.activeVersion?.assetSet.identitySeed)
        XCTAssertEqual(updated.id, existing.id)
    }

    // MARK: - Reload

    /// A character has to survive the trip to disk unchanged — a store that
    /// cannot decode one is read downstream as "this child has no character",
    /// and a fresh identity gets minted over the top of the real one.
    func testCharacterSurvivesStorageRoundTrip() async throws {
        let built = character()
        let store = InMemoryCharacterStore()

        try await store.save(built)
        let reloaded = try await store.profile(id: built.id)

        XCTAssertEqual(reloaded, built)
        XCTAssertTrue(reloaded?.preservesVersionIdentity(of: built) ?? false)
    }

    func testDeletedCharacterIsGoneAndDeletingTwiceIsFine() async throws {
        let built = character()
        let store = InMemoryCharacterStore([built])

        try await store.delete(id: built.id)
        try await store.delete(id: built.id)

        let reloaded = try await store.profile(id: built.id)
        XCTAssertNil(reloaded)
    }
}
