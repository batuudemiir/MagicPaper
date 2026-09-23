import XCTest
@testable import CharacterEngine

/// What a successor version is allowed to move, and what it must carry.
///
/// These rules used to live in the calling code. The point of the tests is that
/// they now live in the model, so a new call site inherits them instead of
/// having to rediscover them.
final class CharacterVersionSuccessionTests: XCTestCase {

    private let later = CharacterFixtures.referenceDate.addingTimeInterval(86_400)

    // MARK: - Age, the bug this closes

    /// A birthday has to reach the identity every illustration is drawn from.
    func testAgeChangeAppearsInTheNextVersion() {
        let v1 = CharacterFixtures.version(number: 1, identity: CharacterFixtures.identity(ageYears: 5))
        let v2 = v1.next(createdAt: later, ageYears: 6, provenance: .authoredByParent)

        XCTAssertEqual(v1.identity.ageYears, 5)
        XCTAssertEqual(v2.identity.ageYears, 6)
        XCTAssertEqual(v2.versionNumber, 2)
    }

    /// The book drawn last year keeps depicting last year's child. This is why
    /// an age change appends rather than edits.
    func testAgeChangeLeavesTheOlderVersionAlone() {
        let profile = CharacterFixtures.profile(
            versions: [CharacterFixtures.version(number: 1, identity: CharacterFixtures.identity(ageYears: 5))]
        )
        let v1 = profile.versions[0]
        let updated = profile.appending(v1.next(createdAt: later, ageYears: 6, provenance: .authoredByParent))

        XCTAssertEqual(updated.version(id: v1.id)?.identity.ageYears, 5)
        XCTAssertEqual(updated.activeVersion?.identity.ageYears, 6)
        XCTAssertEqual(updated.versions.count, 2)
    }

    /// Ageing a child must not change how the child is drawn in any other way.
    func testAgeChangeCarriesEverythingElseForward() {
        let v1 = CharacterFixtures.version(number: 1)
        let v2 = v1.next(createdAt: later, ageYears: 9, provenance: .authoredByParent)

        XCTAssertEqual(v2.identity.identitySeed, v1.identity.identitySeed)
        XCTAssertEqual(v2.identity.descriptors, v1.identity.descriptors)
        XCTAssertEqual(v2.identity.pronouns, v1.identity.pronouns)
        XCTAssertEqual(v2.identity.doNotDepict, v1.identity.doNotDepict)
        XCTAssertEqual(v2.styleProfile, v1.styleProfile)
        XCTAssertEqual(v2.assetSet, v1.assetSet)
    }

    // MARK: - Omission is not erasure

    /// The rule that used to be a guard in `ensureCharacter`: a successor built
    /// without descriptors keeps the parent's descriptors.
    func testOmittedDescriptorsAreKeptNotCleared() {
        let v1 = CharacterFixtures.version(number: 1)
        XCTAssertFalse(v1.identity.descriptors.isEmpty)

        let v2 = v1.next(createdAt: later, provenance: .authoredByParent)

        XCTAssertEqual(v2.identity.descriptors, v1.identity.descriptors)
    }

    /// Clearing is still possible — it just has to be said out loud.
    func testExplicitlyEmptyDescriptorsDoClear() {
        let v2 = CharacterFixtures.version(number: 1)
            .next(createdAt: later, descriptors: [], provenance: .authoredByParent)

        XCTAssertTrue(v2.identity.descriptors.isEmpty)
    }

    /// Safety exclusions must not evaporate because a caller did not repeat them.
    func testOmittedDoNotDepictIsKept() {
        let v1 = CharacterFixtures.version(
            number: 1,
            identity: CharacterFixtures.identity(doNotDepict: ["weapons"])
        )
        let v2 = v1.next(createdAt: later, ageYears: 7, provenance: .authoredByParent)

        XCTAssertEqual(v2.identity.doNotDepict, ["weapons"])
    }

    // MARK: - Reference images

    /// A child re-described without a new photo keeps the photo. Losing it
    /// would make the version unusable and take the child out of their books.
    func testOmittedMasterReferenceIsKept() {
        let v1 = CharacterFixtures.version(number: 1)
        let v2 = v1.next(createdAt: later, ageYears: 7, provenance: .authoredByParent)

        XCTAssertEqual(v2.assetSet.masterReference, v1.assetSet.masterReference)
        XCTAssertTrue(v2.isUsable)
    }

    func testNewMasterReferenceReplacesTheOldOne() {
        let v1 = CharacterFixtures.version(number: 1)
        let fresh = CharacterFixtures.asset(locator: "https://example.test/new.jpg")
        let v2 = v1.next(createdAt: later, masterReference: fresh, provenance: .authoredByParent)

        XCTAssertEqual(v2.assetSet.masterReference?.locator, "https://example.test/new.jpg")
        XCTAssertEqual(v2.assetSet.identitySeed, v1.assetSet.identitySeed)
        XCTAssertEqual(v2.assetSet.stylePresetID, v1.assetSet.stylePresetID)
    }

    /// The seed is not reachable from the successor API at all — the only way
    /// to change it is to build a version from scratch, which is a decision, not
    /// an accident.
    func testSeedSurvivesEveryKindOfEdit() {
        let v1 = CharacterFixtures.version(number: 1)
        let v2 = v1.next(
            createdAt: later,
            ageYears: 99,
            pronouns: .sheHer,
            descriptors: [],
            doNotDepict: ["fire"],
            styleProfile: CharacterStyleProfile(illustrationStyleID: "other", palettePresetID: "other"),
            masterReference: CharacterFixtures.asset(locator: "https://example.test/other.jpg"),
            provenance: .seeded
        )

        XCTAssertEqual(v2.identity.identitySeed, v1.identity.identitySeed)
        XCTAssertEqual(v2.assetSet.identitySeed, v1.assetSet.identitySeed)
    }

    // MARK: - Renaming

    /// A name is not an appearance fact, so it does not mint a version.
    func testRenameDoesNotTouchHistory() {
        let profile = CharacterFixtures.profile(displayName: "Deniz")
        let renamed = profile.renamed(to: "Deniz Ada")

        XCTAssertEqual(renamed.displayName, "Deniz Ada")
        XCTAssertEqual(renamed.id, profile.id)
        XCTAssertEqual(renamed.versions, profile.versions)
        XCTAssertEqual(renamed.activeVersionID, profile.activeVersionID)
        XCTAssertEqual(renamed.createdAt, profile.createdAt)
    }

    func testRenamingToTheSameNameIsIdentity() {
        let profile = CharacterFixtures.profile(displayName: "Deniz")
        XCTAssertEqual(profile.renamed(to: "Deniz"), profile)
    }
}
