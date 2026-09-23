import Foundation
import CharacterEngine

/// Builds a V1 `CharacterProfile` from what the app already knows about a child.
///
/// This is the seam a real Character Engine drops into later. Today there is no
/// vision step, so the identity is whatever a parent entered plus the reference
/// photo the app already uploads — deliberately sparse rather than guessed.
/// Every descriptor here is `.parentProvided`; nothing is inferred from a face.
struct ProfileCharacterSource {
    private let fileManager: FileManagerService

    init(fileManager: FileManagerService = .shared) {
        self.fileManager = fileManager
    }

    /// Turns a profile and its uploaded photo into a character.
    ///
    /// `referenceLocator` should be the remote URL the app uploaded the photo
    /// to, because the image provider conditions on it directly.
    func makeProfile(
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
    ///
    /// Every parameter is optional and `nil` means "unchanged". That matters
    /// most for `descriptors`: passing `[]` used to wipe a child's entire
    /// appearance into a brand-new version, and the only thing standing between
    /// a parent and that outcome was a guard on the calling side. The guard now
    /// lives in `CharacterVersion.next(_:)`, which also carries `identitySeed`
    /// forward unconditionally so a version bump cannot change how the child
    /// renders.
    func updating(
        _ profile: CharacterProfile,
        referenceLocator: String? = nil,
        ageYears: Int? = nil,
        descriptors: [CharacterDescriptor]? = nil,
        doNotDepict: [String]? = nil,
        now: Date = Date()
    ) -> CharacterProfile {
        guard let current = profile.latestVersion else { return profile }

        return profile.appending(
            current.next(
                createdAt: now,
                ageYears: ageYears,
                descriptors: descriptors,
                doNotDepict: doNotDepict,
                masterReference: referenceLocator.map {
                    CharacterAsset(role: .master, locator: $0, createdAt: now)
                },
                provenance: .authoredByParent
            )
        )
    }

    /// Brings a character back in line with the profile the parent edited.
    ///
    /// `ProfileManager.updateProfile(_:name:age:)` writes the child's new name
    /// and age into `UserProfile` and stops there. Nothing carried either into
    /// the character, so a five-year-old who turned six went on being described
    /// as five to every illustration request for the rest of the child's life
    /// in the app — the exact "redefined per story" failure Principle 5 exists
    /// to prevent, inverted: never redefined at all.
    ///
    /// The two edits are not the same kind of change, so they are not handled
    /// the same way:
    ///
    /// - **Age** is an appearance fact. It belongs to a version, and a book
    ///   drawn when the child was five must keep depicting a five-year-old, so
    ///   the change appends a snapshot instead of rewriting one.
    /// - **Name** is not an appearance fact. It applies to the whole character
    ///   at once and mints no version.
    ///
    /// Returns the character untouched when nothing moved, which makes this
    /// safe to call on every profile save: a no-op edit does not grow history.
    func syncing(
        _ character: CharacterProfile,
        with profile: UserProfile,
        now: Date = Date()
    ) -> CharacterProfile {
        let renamed = character.renamed(to: profile.name)

        guard let current = renamed.latestVersion,
              current.identity.ageYears != profile.age else {
            return renamed
        }

        return updating(renamed, ageYears: profile.age, now: now)
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
