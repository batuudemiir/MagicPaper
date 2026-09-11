import Foundation
import CharacterEngine

/// A character as the story stores them.
///
/// This is a projection of a `ResolvedCharacter`, and the only way to make one
/// is from a resolved character — there is no memberwise initializer, and the
/// one that exists is `internal`, callable only from `CharacterBinder` inside
/// this module. That is the structural half of "the engine cannot invent how a
/// child looks": there is no expressible way to write an appearance into a
/// story that did not come from the Character Engine.
public struct StoryCharacter: Codable, Sendable, Hashable, Identifiable {
    public let id: CharacterID
    public let versionID: CharacterVersionID
    public let displayName: String
    public let role: CastRole
    public let identity: CharacterIdentity
    public let styleProfile: CharacterStyleProfile
    public let assetSet: CharacterAssetSet

    internal init(resolved: ResolvedCharacter) {
        self.id = resolved.characterID
        self.versionID = resolved.versionID
        self.displayName = resolved.displayName
        self.role = resolved.role
        self.identity = resolved.identity
        self.styleProfile = resolved.styleProfile
        self.assetSet = resolved.assetSet
    }

    /// Rebuilds the read-only form the visual compiler consumes. Lossless:
    /// nothing is added on the way through.
    public var resolved: ResolvedCharacter {
        ResolvedCharacter(
            characterID: id,
            displayName: displayName,
            role: role,
            version: CharacterVersion(
                id: versionID,
                versionNumber: 0,
                createdAt: Date(timeIntervalSince1970: 0),
                identity: identity,
                styleProfile: styleProfile,
                assetSet: assetSet,
                provenance: .seeded
            )
        )
    }

    public var versionPin: String { "character:\(id)@\(versionID)" }
}

public extension Array where Element == StoryCharacter {
    var protagonist: StoryCharacter? { first { $0.role == .protagonist } }
    var resolved: [ResolvedCharacter] { map(\.resolved) }
    var displayNames: [String] { map(\.displayName) }
}
