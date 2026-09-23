import Foundation

// MARK: - Succession

/// How one identity snapshot becomes the next one.
///
/// Before this existed, every caller assembled the successor version by hand.
/// That put two rules — "carry the seed forward" and "never let an omitted
/// list erase what the parent already told us" — on the *calling* side, where
/// each new call site has to remember them independently. One call site did
/// remember (`StoryEngineContainer.ensureCharacter` guarded the empty
/// descriptor array); the model did not require it.
///
/// These helpers move both rules into the model. An omitted parameter means
/// "unchanged", and the only way to clear a list is to pass an explicit empty
/// one — which reads as a decision in the diff instead of an oversight.
extension CharacterAssetSet {
    /// A copy pointing at a new master reference.
    ///
    /// `nil` keeps the current master rather than clearing it: a character that
    /// is re-described without a new photo must not silently lose the reference
    /// image every illustration of them has been conditioned on. `isUsable`
    /// gates generation on exactly that field, so dropping it by omission would
    /// take the child out of their own books.
    ///
    /// `identitySeed` is not a parameter. It is what makes the same child
    /// render the same way twice, so a successor can never be handed a
    /// different one.
    public func adoptingMasterReference(_ asset: CharacterAsset?) -> CharacterAssetSet {
        CharacterAssetSet(
            masterReference: asset ?? masterReference,
            fullBodyReference: fullBodyReference,
            faceReference: faceReference,
            expressionReferences: expressionReferences,
            identitySeed: identitySeed,
            stylePresetID: stylePresetID
        )
    }
}

extension CharacterVersion {
    /// The next snapshot in this character's history.
    ///
    /// Everything not named is carried forward verbatim, including
    /// `identitySeed` — which is deliberately not a parameter at all. A caller
    /// that wants to change only the child's age changes only the child's age.
    ///
    /// The returned version has a fresh `CharacterVersionID`, because it is a
    /// genuinely new snapshot: books pinned to the previous one keep resolving
    /// to the previous one. See `CharacterProfile.preservesVersionIdentity(of:)`
    /// for why that must never be confused with re-encoding an existing record.
    public func next(
        versionNumber: Int? = nil,
        createdAt: Date,
        ageYears: Int? = nil,
        pronouns: Pronouns? = nil,
        descriptors: [CharacterDescriptor]? = nil,
        doNotDepict: [String]? = nil,
        styleProfile: CharacterStyleProfile? = nil,
        masterReference: CharacterAsset? = nil,
        provenance: IdentityProvenance
    ) -> CharacterVersion {
        CharacterVersion(
            versionNumber: versionNumber ?? (self.versionNumber + 1),
            createdAt: createdAt,
            identity: CharacterIdentity(
                ageYears: ageYears ?? identity.ageYears,
                pronouns: pronouns ?? identity.pronouns,
                descriptors: descriptors ?? identity.descriptors,
                identitySeed: identity.identitySeed,
                doNotDepict: doNotDepict ?? identity.doNotDepict
            ),
            styleProfile: styleProfile ?? self.styleProfile,
            assetSet: assetSet.adoptingMasterReference(masterReference),
            provenance: provenance
        )
    }
}

extension CharacterProfile {
    /// A rename, with the version history untouched.
    ///
    /// `displayName` sits on the profile rather than on a version on purpose: a
    /// child who is called something else from today is called something else
    /// in the library too, and a name is not an appearance fact — it changes
    /// nothing about how the child is drawn. Minting a version for it would
    /// dirty the history with entries that no illustration can distinguish.
    ///
    /// Stories already written keep the name they were written with, because
    /// the text is stored generated, not re-rendered from the profile.
    public func renamed(to newName: String) -> CharacterProfile {
        guard newName != displayName else { return self }
        return CharacterProfile(
            id: id,
            ownerProfileID: ownerProfileID,
            displayName: newName,
            versions: versions,
            activeVersionID: activeVersionID,
            createdAt: createdAt,
            schemaVersion: schemaVersion
        )
    }
}
