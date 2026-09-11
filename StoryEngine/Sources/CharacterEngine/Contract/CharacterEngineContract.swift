import Foundation

/// The part a character plays in one particular story.
public enum CastRole: String, Codable, Sendable, Hashable, CaseIterable {
    case protagonist
    case companion
    case supporting
}

/// A request to resolve a cast: which characters, and optionally pinned to
/// which identity versions.
public struct CastBinding: Codable, Sendable, Hashable {
    public struct Member: Codable, Sendable, Hashable {
        public let characterID: CharacterID
        public let role: CastRole
        /// Pin a specific snapshot. `nil` means "use the active version".
        public let versionID: CharacterVersionID?

        public init(characterID: CharacterID, role: CastRole, versionID: CharacterVersionID? = nil) {
            self.characterID = characterID
            self.role = role
            self.versionID = versionID
        }
    }

    public let members: [Member]

    public init(members: [Member]) { self.members = members }

    public init(protagonist: CharacterID, versionID: CharacterVersionID? = nil) {
        self.members = [Member(characterID: protagonist, role: .protagonist, versionID: versionID)]
    }
}

/// A character as the Story Engine receives them: read-only, version-pinned.
///
/// There is deliberately no memberwise initializer. The only way to make one is
/// from a real `CharacterVersion`, so identity fields can never be assembled
/// piecemeal by a caller who "just needs a character with brown hair".
public struct ResolvedCharacter: Codable, Sendable, Hashable {
    public let characterID: CharacterID
    public let versionID: CharacterVersionID
    public let displayName: String
    public let role: CastRole
    public let identity: CharacterIdentity
    public let styleProfile: CharacterStyleProfile
    public let assetSet: CharacterAssetSet

    public init(characterID: CharacterID, displayName: String, role: CastRole, version: CharacterVersion) {
        self.characterID = characterID
        self.versionID = version.id
        self.displayName = displayName
        self.role = role
        self.identity = version.identity
        self.styleProfile = version.styleProfile
        self.assetSet = version.assetSet
    }
}

/// The resolved cast for one story. Exactly one protagonist, by construction.
public struct ResolvedCast: Codable, Sendable, Hashable {
    public let protagonist: ResolvedCharacter
    public let supporting: [ResolvedCharacter]

    public init(protagonist: ResolvedCharacter, supporting: [ResolvedCharacter]) {
        self.protagonist = protagonist
        self.supporting = supporting
    }

    public var all: [ResolvedCharacter] { [protagonist] + supporting }

    public func character(id: CharacterID) -> ResolvedCharacter? {
        all.first { $0.characterID == id }
    }
}

/// The read contract between the Character Engine and everything downstream.
///
/// This is the only door: the Story Engine has no other way to learn what a
/// child looks like, which is what stops it inventing.
public protocol CharacterEngineContract: Sendable {
    func resolveCast(for binding: CastBinding) async throws -> ResolvedCast
}
