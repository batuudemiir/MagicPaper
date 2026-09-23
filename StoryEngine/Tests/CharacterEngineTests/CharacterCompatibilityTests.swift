import XCTest
@testable import CharacterEngine

/// Decoding a character record that was written by an older build.
///
/// This is not a hypothetical. The app is moving its domain records out of
/// `UserDefaults` and into per-record JSON files (D4), and `FileBackedStore`
/// answers a decode failure with `nil` — silently. A `nil` here does not
/// surface as an error a parent could retry; it reads as "this child has no
/// character yet", and the next generation mints a brand-new
/// `CharacterVersionID`. Every book already pinned to the old version keeps
/// resolving, but the child stops looking like herself in new ones.
///
/// So: a field this package adds later must never be the reason an existing
/// record stops decoding. Collections that were absent before default to
/// empty rather than throwing.
final class CharacterCompatibilityTests: XCTestCase {

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: Data(json.utf8))
    }

    // MARK: - Identity

    func testIdentityDecodesWithoutDoNotDepict() throws {
        let identity = try decode(CharacterIdentity.self, """
        {
          "ageYears": 6,
          "pronouns": {"subject": "o", "object": "onu", "possessive": "onun"},
          "descriptors": [],
          "identitySeed": 42
        }
        """)
        XCTAssertEqual(identity.ageYears, 6)
        XCTAssertTrue(identity.doNotDepict.isEmpty)
    }

    func testIdentityDecodesWithoutDescriptors() throws {
        let identity = try decode(CharacterIdentity.self, """
        {
          "ageYears": 6,
          "pronouns": {"subject": "o", "object": "onu", "possessive": "onun"},
          "identitySeed": 42
        }
        """)
        XCTAssertTrue(identity.descriptors.isEmpty)
    }

    /// The seed is the one field that must never be defaulted: it is what makes
    /// the same child render the same way twice. A record without it is broken,
    /// and saying so is better than inventing a number.
    func testIdentityWithoutSeedStillThrows() {
        XCTAssertThrowsError(try decode(CharacterIdentity.self, """
        {
          "ageYears": 6,
          "pronouns": {"subject": "o", "object": "onu", "possessive": "onun"},
          "descriptors": []
        }
        """))
    }

    // MARK: - Asset set

    func testAssetSetDecodesWithoutExpressionReferences() throws {
        let set = try decode(CharacterAssetSet.self, """
        {"identitySeed": 42, "stylePresetID": "magic_paper_v1"}
        """)
        XCTAssertTrue(set.expressionReferences.isEmpty)
        XCTAssertNil(set.masterReference)
        XCTAssertFalse(set.isUsable)
    }

    // MARK: - Style profile

    func testStyleProfileDecodesWithoutOptionalLists() throws {
        let style = try decode(CharacterStyleProfile.self, """
        {"illustrationStyleID": "storybook_painted_v1", "palettePresetID": "paper_warm"}
        """)
        XCTAssertTrue(style.renderingNotes.isEmpty)
        XCTAssertTrue(style.negativeTraits.isEmpty)
    }

    // MARK: - Profile

    /// A file written before `schemaVersion` existed is a v1 file, not a
    /// corrupt one.
    func testProfileWithoutSchemaVersionReadsAsVersionOne() throws {
        let versionID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let profile = try decode(CharacterProfile.self, """
        {
          "id": "22222222-2222-2222-2222-222222222222",
          "ownerProfileID": "11111111-1111-1111-1111-111111111111",
          "displayName": "Deniz",
          "activeVersionID": "\(versionID.uuidString)",
          "createdAt": "2023-11-14T22:13:20Z",
          "versions": [
            {
              "id": "\(versionID.uuidString)",
              "versionNumber": 1,
              "createdAt": "2023-11-14T22:13:20Z",
              "provenance": "seeded",
              "identity": {
                "ageYears": 6,
                "pronouns": {"subject": "o", "object": "onu", "possessive": "onun"},
                "identitySeed": 42
              },
              "styleProfile": {
                "illustrationStyleID": "storybook_painted_v1",
                "palettePresetID": "paper_warm"
              },
              "assetSet": {
                "identitySeed": 42,
                "stylePresetID": "magic_paper_v1",
                "masterReference": {
                  "id": "44444444-4444-4444-4444-444444444444",
                  "role": "master",
                  "locator": "profile_deniz.jpg",
                  "createdAt": "2023-11-14T22:13:20Z"
                }
              }
            }
          ]
        }
        """)

        XCTAssertEqual(profile.schemaVersion, 1)
        XCTAssertEqual(profile.displayName, "Deniz")
        XCTAssertEqual(profile.activeVersion?.id.rawValue, versionID)
        XCTAssertEqual(profile.activeVersion?.identity.identitySeed, 42)
        XCTAssertTrue(profile.activeVersion?.isUsable == true)
    }

    /// The whole point of the above: a sparse record still resolves to a cast,
    /// so a migrated child keeps her identity instead of being re-minted.
    func testSparseProfileStillResolves() async throws {
        let version = CharacterVersion(
            versionNumber: 1,
            createdAt: CharacterFixtures.referenceDate,
            identity: CharacterIdentity(ageYears: 6, pronouns: .turkish, descriptors: [], identitySeed: 7),
            styleProfile: CharacterStyleProfile(illustrationStyleID: "s", palettePresetID: "p"),
            assetSet: CharacterFixtures.assetSet(),
            provenance: .seeded
        )
        let profile = CharacterFixtures.profile(versions: [version])
        let resolver = CharacterResolver(store: InMemoryCharacterStore([profile]))

        let cast = try await resolver.resolveCast(for: CastBinding(protagonist: profile.id))
        XCTAssertEqual(cast.protagonist.identity.identitySeed, 7)
        XCTAssertTrue(cast.protagonist.identity.descriptors.isEmpty)
    }
}
