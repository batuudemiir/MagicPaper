import Foundation

/// The default `CharacterEngineContract` implementation: reads profiles from a
/// store, resolves each member to a pinned version, and returns a read-only cast.
public struct CharacterResolver: CharacterEngineContract {
    private let store: CharacterStore
    private let versionResolver: CharacterVersionResolver

    public init(store: CharacterStore, versionResolver: CharacterVersionResolver = CharacterVersionResolver()) {
        self.store = store
        self.versionResolver = versionResolver
    }

    public func resolveCast(for binding: CastBinding) async throws -> ResolvedCast {
        guard !binding.members.isEmpty else { throw CharacterEngineError.emptyCast }

        let protagonists = binding.members.filter { $0.role == .protagonist }
        guard let protagonistMember = protagonists.first else { throw CharacterEngineError.emptyCast }
        guard protagonists.count == 1 else {
            throw CharacterEngineError.duplicateCastRole(CastRole.protagonist.rawValue)
        }

        let protagonist = try await resolve(member: protagonistMember)
        var supporting: [ResolvedCharacter] = []
        for member in binding.members where member.role != .protagonist {
            supporting.append(try await resolve(member: member))
        }

        return ResolvedCast(protagonist: protagonist, supporting: supporting)
    }

    private func resolve(member: CastBinding.Member) async throws -> ResolvedCharacter {
        guard let profile = try await store.profile(id: member.characterID) else {
            throw CharacterEngineError.profileNotFound(member.characterID)
        }
        let version = try versionResolver.resolve(profile: profile, pinned: member.versionID)
        return ResolvedCharacter(
            characterID: profile.id,
            displayName: profile.displayName,
            role: member.role,
            version: version
        )
    }
}
