import Foundation

/// How an identity snapshot came to exist.
public enum IdentityProvenance: String, Codable, Sendable, Hashable {
    case extractedFromPhoto
    case authoredByParent
    case seeded
}

/// One immutable snapshot of who a character is and how they are drawn.
///
/// Versions are append-only. A story pins the version id it generated against,
/// so re-deriving a character from a new photo can never silently change a book
/// that is already on the shelf.
public struct CharacterVersion: Codable, Sendable, Hashable, Identifiable {
    public let id: CharacterVersionID
    public let versionNumber: Int
    public let createdAt: Date
    public let identity: CharacterIdentity
    public let styleProfile: CharacterStyleProfile
    public let assetSet: CharacterAssetSet
    public let provenance: IdentityProvenance

    public init(
        id: CharacterVersionID = CharacterVersionID(),
        versionNumber: Int,
        createdAt: Date,
        identity: CharacterIdentity,
        styleProfile: CharacterStyleProfile,
        assetSet: CharacterAssetSet,
        provenance: IdentityProvenance
    ) {
        self.id = id
        self.versionNumber = versionNumber
        self.createdAt = createdAt
        self.identity = identity
        self.styleProfile = styleProfile
        self.assetSet = assetSet
        self.provenance = provenance
    }

    /// A version can front a story only if it can actually be illustrated.
    public var isUsable: Bool { assetSet.isUsable }
}
