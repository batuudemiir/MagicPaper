import Foundation
import CharacterEngine

/// Builds a V1 `CharacterProfile` from what the app already knows about a child.
///
/// This is the seam a real Character Engine drops into later. Today there is no
/// vision step, so the identity is whatever a parent entered plus the reference
/// photo the app already uploads — deliberately sparse rather than guessed.
/// Every descriptor here is `.parentProvided`; nothing is inferred from a face.
public struct ProfileCharacterSource {
    private let fileManager: FileManagerService

    public init(fileManager: FileManagerService = .shared) {
        self.fileManager = fileManager
    }

    /// Turns a profile and its uploaded photo into a character.
    ///
    /// `referenceLocator` should be the remote URL the app uploaded the photo
    /// to, because the image provider conditions on it directly.
    public func makeProfile(
        from profile: UserProfile,
        referenceLocator: String?,
        pronouns: Pronouns,
        parentProvidedDescriptors: [CharacterDescriptor] = [],
        doNotDepict: [String] = [],
        illustrationStyleID: String = "storybook_painted_v1",
        palettePresetID: String = "paper_warm",
        stylePresetID: String = "magic_paper_v1",
        now: Date = Date()
    ) -> CharacterProfile {
        // Derived from the profile id, so the same child seeds identically on
        // every device and every regeneration.
        let identitySeed = Self.seed(from: profile.id)

        let assetSet = CharacterAssetSet(
            masterReference: referenceLocator.map {
                CharacterAsset(role: .master, locator: $0, createdAt: now)
            },
            identitySeed: identitySeed,
            stylePresetID: stylePresetID
        )

        let version = CharacterVersion(
            versionNumber: 1,
            createdAt: now,
            identity: CharacterIdentity(
                ageYears: profile.age,
                pronouns: pronouns,
                descriptors: parentProvidedDescriptors,
                identitySeed: identitySeed,
                doNotDepict: doNotDepict
            ),
            styleProfile: CharacterStyleProfile(
                illustrationStyleID: illustrationStyleID,
                palettePresetID: palettePresetID
            ),
            assetSet: assetSet,
            provenance: parentProvidedDescriptors.isEmpty ? .seeded : .authoredByParent
        )

        return CharacterProfile(
            id: CharacterID(profile.id),
            ownerProfileID: profile.id,
            displayName: profile.name,
            versions: [version],
            activeVersionID: version.id,
            createdAt: profile.createdAt
        )
    }

    /// Appends a new identity version rather than editing the old one, so books
    /// already generated keep resolving to the child they were drawn with.
    public func updating(
        _ profile: CharacterProfile,
        referenceLocator: String?,
        descriptors: [CharacterDescriptor],
        doNotDepict: [String] = [],
        now: Date = Date()
    ) -> CharacterProfile {
        guard let current = profile.latestVersion else { return profile }

        let version = CharacterVersion(
            versionNumber: current.versionNumber + 1,
            createdAt: now,
            identity: CharacterIdentity(
                ageYears: current.identity.ageYears,
                pronouns: current.identity.pronouns,
                descriptors: descriptors,
                identitySeed: current.identity.identitySeed,
                doNotDepict: doNotDepict
            ),
            styleProfile: current.styleProfile,
            assetSet: CharacterAssetSet(
                masterReference: referenceLocator.map { CharacterAsset(role: .master, locator: $0, createdAt: now) }
                    ?? current.assetSet.masterReference,
                fullBodyReference: current.assetSet.fullBodyReference,
                faceReference: current.assetSet.faceReference,
                expressionReferences: current.assetSet.expressionReferences,
                identitySeed: current.assetSet.identitySeed,
                stylePresetID: current.assetSet.stylePresetID
            ),
            provenance: .authoredByParent
        )
        return profile.appending(version)
    }

    static func seed(from id: UUID) -> UInt64 {
        var result: UInt64 = 0
        withUnsafeBytes(of: id.uuid) { bytes in
            for byte in bytes.prefix(8) {
                result = (result << 8) | UInt64(byte)
            }
        }
        return result
    }
}
