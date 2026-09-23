import Foundation

/// A character the family owns — the child, a sibling, a favourite toy.
///
/// The product premise is "characterize once, reuse in every story", so this is
/// a persistent entity with a version history, not a per-request payload.
public struct CharacterProfile: Codable, Sendable, Hashable, Identifiable {
    public let id: CharacterID
    /// Links back to the host app's profile. Opaque to the Character Engine.
    public let ownerProfileID: UUID
    public let displayName: String
    public let versions: [CharacterVersion]
    public let activeVersionID: CharacterVersionID
    public let createdAt: Date
    public let schemaVersion: Int

    public static let currentSchemaVersion = 1

    public init(
        id: CharacterID = CharacterID(),
        ownerProfileID: UUID,
        displayName: String,
        versions: [CharacterVersion],
        activeVersionID: CharacterVersionID,
        createdAt: Date,
        schemaVersion: Int = CharacterProfile.currentSchemaVersion
    ) {
        self.id = id
        self.ownerProfileID = ownerProfileID
        self.displayName = displayName
        self.versions = versions
        self.activeVersionID = activeVersionID
        self.createdAt = createdAt
        self.schemaVersion = schemaVersion
    }

    /// A record written before this field existed is a v1 record, not a corrupt
    /// one. See `CharacterIdentity.init(from:)` for why refusing it is worse
    /// than reading it.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(CharacterID.self, forKey: .id)
        ownerProfileID = try container.decode(UUID.self, forKey: .ownerProfileID)
        displayName = try container.decode(String.self, forKey: .displayName)
        versions = try container.decode([CharacterVersion].self, forKey: .versions)
        activeVersionID = try container.decode(CharacterVersionID.self, forKey: .activeVersionID)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
    }

    public func version(id versionID: CharacterVersionID) -> CharacterVersion? {
        versions.first { $0.id == versionID }
    }

    public var activeVersion: CharacterVersion? { version(id: activeVersionID) }

    public var latestVersion: CharacterVersion? {
        versions.max { $0.versionNumber < $1.versionNumber }
    }

    /// Appends a new snapshot and makes it active. Existing versions are never
    /// rewritten, so stories pinned to them keep resolving.
    public func appending(_ version: CharacterVersion, activate: Bool = true) -> CharacterProfile {
        CharacterProfile(
            id: id,
            ownerProfileID: ownerProfileID,
            displayName: displayName,
            versions: versions + [version],
            activeVersionID: activate ? version.id : activeVersionID,
            createdAt: createdAt,
            schemaVersion: schemaVersion
        )
    }
}
