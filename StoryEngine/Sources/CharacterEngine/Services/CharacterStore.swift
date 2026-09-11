import Foundation

/// Persistence port for character profiles. The host app decides where they live.
public protocol CharacterStore: Sendable {
    func profile(id: CharacterID) async throws -> CharacterProfile?
    func save(_ profile: CharacterProfile) async throws
    func allProfiles(ownedBy ownerProfileID: UUID) async throws -> [CharacterProfile]
    /// Removes a character. Deleting one that is already gone must succeed.
    func delete(id: CharacterID) async throws
}

/// In-memory store. Used by tests and as a safe default in previews.
public actor InMemoryCharacterStore: CharacterStore {
    private var profiles: [CharacterID: CharacterProfile] = [:]

    public init(_ seed: [CharacterProfile] = []) {
        for profile in seed { profiles[profile.id] = profile }
    }

    public func profile(id: CharacterID) async throws -> CharacterProfile? { profiles[id] }

    public func save(_ profile: CharacterProfile) async throws { profiles[profile.id] = profile }

    public func allProfiles(ownedBy ownerProfileID: UUID) async throws -> [CharacterProfile] {
        profiles.values
            .filter { $0.ownerProfileID == ownerProfileID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    public func delete(id: CharacterID) async throws { profiles.removeValue(forKey: id) }
}
