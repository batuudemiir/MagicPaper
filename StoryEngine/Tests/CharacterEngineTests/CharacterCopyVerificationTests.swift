import XCTest
@testable import CharacterEngine

/// Can a migration prove it copied a character rather than remaking one?
///
/// The hazard is specific: `CharacterVersionID` and `CharacterAsset.id` are
/// fresh UUIDs, so a store-to-store move that decodes and reconstructs looks
/// correct in every field a human would check, and silently breaks every story
/// pinned to the old version id.
final class CharacterCopyVerificationTests: XCTestCase {

    // MARK: - Fingerprint

    func testFingerprintIgnoresIdentifiers() {
        let a = CharacterFixtures.version(number: 1)
        let b = CharacterFixtures.version(number: 1)

        XCTAssertNotEqual(a.id, b.id)
        XCTAssertEqual(a.contentFingerprint, b.contentFingerprint)
    }

    func testFingerprintIsStableAcrossSerialization() throws {
        let version = CharacterFixtures.version(number: 1)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(CharacterVersion.self, from: encoder.encode(version))

        XCTAssertEqual(decoded.contentFingerprint, version.contentFingerprint)
    }

    /// Descriptor order is presentation. A store that returns them in a
    /// different order has still copied faithfully.
    func testFingerprintIsOrderIndependentForDescriptors() {
        let forward = CharacterFixtures.identity(descriptors: [
            CharacterDescriptor(category: .hair, value: "curly black hair"),
            CharacterDescriptor(category: .eyes, value: "brown eyes")
        ])
        let reversed = CharacterFixtures.identity(descriptors: [
            CharacterDescriptor(category: .eyes, value: "brown eyes"),
            CharacterDescriptor(category: .hair, value: "curly black hair")
        ])

        XCTAssertEqual(
            CharacterFixtures.version(number: 1, identity: forward).contentFingerprint,
            CharacterFixtures.version(number: 1, identity: reversed).contentFingerprint
        )
    }

    func testFingerprintMovesWhenTheChildDoes() {
        let base = CharacterFixtures.version(number: 1)

        let olderChild = CharacterFixtures.version(
            number: 1,
            identity: CharacterFixtures.identity(ageYears: 9)
        )
        let differentHair = CharacterFixtures.version(
            number: 1,
            identity: CharacterFixtures.identity(descriptors: [
                CharacterDescriptor(category: .hair, value: "short blonde hair")
            ])
        )
        let differentPhoto = CharacterFixtures.version(
            number: 1,
            assetSet: CharacterFixtures.assetSet(
                master: CharacterFixtures.asset(locator: "https://example.test/other.jpg")
            )
        )

        XCTAssertNotEqual(base.contentFingerprint, olderChild.contentFingerprint)
        XCTAssertNotEqual(base.contentFingerprint, differentHair.contentFingerprint)
        XCTAssertNotEqual(base.contentFingerprint, differentPhoto.contentFingerprint)
    }

    /// The seed is invisible to a human reading a JSON diff, so it has to be
    /// visible to the check.
    func testFingerprintCatchesADriftedSeed() {
        let original = CharacterFixtures.version(number: 1)
        let reseeded = CharacterVersion(
            versionNumber: 1,
            createdAt: CharacterFixtures.referenceDate,
            identity: CharacterIdentity(
                ageYears: original.identity.ageYears,
                pronouns: original.identity.pronouns,
                descriptors: original.identity.descriptors,
                identitySeed: 43
            ),
            styleProfile: original.styleProfile,
            assetSet: original.assetSet,
            provenance: original.provenance
        )

        XCTAssertNotEqual(reseeded.contentFingerprint, original.contentFingerprint)
    }

    // MARK: - Copy verification

    func testAFaithfulCopyHasNoDefects() throws {
        let original = CharacterFixtures.profile()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let copy = try decoder.decode(CharacterProfile.self, from: encoder.encode(original))

        XCTAssertEqual(copy.copyDefects(from: original), [])
        XCTAssertTrue(copy.preservesVersionIdentity(of: original))
    }

    /// The case this whole file exists for: identical content, new ids.
    func testRebuildingAVersionIsReportedAsARebuild() {
        let original = CharacterFixtures.profile()
        let source = original.versions[0]

        let rebuilt = CharacterVersion(
            versionNumber: source.versionNumber,
            createdAt: source.createdAt,
            identity: source.identity,
            styleProfile: source.styleProfile,
            assetSet: source.assetSet,
            provenance: source.provenance
        )
        let remade = CharacterProfile(
            id: original.id,
            ownerProfileID: original.ownerProfileID,
            displayName: original.displayName,
            versions: [rebuilt],
            activeVersionID: rebuilt.id,
            createdAt: original.createdAt
        )

        XCTAssertEqual(
            remade.copyDefects(from: original),
            [.rebuiltVersion(original: source.id, fingerprint: source.contentFingerprint)]
        )
        XCTAssertFalse(remade.preservesVersionIdentity(of: original))
    }

    /// A dropped version is a different failure from a rebuilt one, and the
    /// fix is different too, so they are reported apart.
    func testADroppedVersionIsReportedAsMissing() {
        let v1 = CharacterFixtures.version(number: 1)
        let v2 = CharacterFixtures.version(
            number: 2,
            identity: CharacterFixtures.identity(ageYears: 7)
        )
        let original = CharacterFixtures.profile(versions: [v1, v2], activeVersionID: v2.id)
        let truncated = CharacterProfile(
            id: original.id,
            ownerProfileID: original.ownerProfileID,
            displayName: original.displayName,
            versions: [v2],
            activeVersionID: v2.id,
            createdAt: original.createdAt
        )

        XCTAssertEqual(truncated.copyDefects(from: original), [.missingVersion(v1.id)])
    }

    /// History is append-only. A version that kept its id but changed content
    /// rewrites a book that is already on the shelf.
    func testRewritingAVersionInPlaceIsReported() {
        let original = CharacterFixtures.profile()
        let source = original.versions[0]
        let tampered = CharacterVersion(
            id: source.id,
            versionNumber: source.versionNumber,
            createdAt: source.createdAt,
            identity: CharacterFixtures.identity(ageYears: 11),
            styleProfile: source.styleProfile,
            assetSet: source.assetSet,
            provenance: source.provenance
        )
        let rewritten = CharacterProfile(
            id: original.id,
            ownerProfileID: original.ownerProfileID,
            displayName: original.displayName,
            versions: [tampered],
            activeVersionID: tampered.id,
            createdAt: original.createdAt
        )

        XCTAssertEqual(rewritten.copyDefects(from: original), [.rewrittenVersion(source.id)])
    }

    func testAChangedCharacterIDIsReported() {
        let original = CharacterFixtures.profile()
        let rekeyed = CharacterProfile(
            id: CharacterID(),
            ownerProfileID: original.ownerProfileID,
            displayName: original.displayName,
            versions: original.versions,
            activeVersionID: original.activeVersionID,
            createdAt: original.createdAt
        )

        XCTAssertEqual(rekeyed.copyDefects(from: original), [.characterIDChanged])
    }

    func testADanglingActivePointerIsReported() {
        let original = CharacterFixtures.profile()
        let orphaned = CharacterProfile(
            id: original.id,
            ownerProfileID: original.ownerProfileID,
            displayName: original.displayName,
            versions: original.versions,
            activeVersionID: CharacterVersionID(),
            createdAt: original.createdAt
        )

        XCTAssertEqual(orphaned.copyDefects(from: original).count, 1)
        XCTAssertTrue(orphaned.copyDefects(from: original).contains { defect in
            if case .danglingActiveVersion = defect { return true }
            return false
        })
    }

    /// A migration that also brings the child forward — renamed, aged — is
    /// still a faithful copy as long as it left the old versions alone.
    func testAddingAVersionAndRenamingStaysFaithful() {
        let original = CharacterFixtures.profile(displayName: "Deniz")
        let grown = original
            .renamed(to: "Deniz Ada")
            .appending(
                original.versions[0].next(
                    createdAt: CharacterFixtures.referenceDate.addingTimeInterval(86_400),
                    ageYears: 7,
                    provenance: .authoredByParent
                )
            )

        XCTAssertTrue(grown.preservesVersionIdentity(of: original))
    }
}
