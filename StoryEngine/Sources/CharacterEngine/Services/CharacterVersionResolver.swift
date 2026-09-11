import Foundation

/// Picks which identity snapshot a story should be generated against.
///
/// Split out from `CharacterResolver` because the rule is worth testing on its
/// own: pinning must be exact, and falling back must never silently hand back
/// a version that cannot be illustrated.
public struct CharacterVersionResolver: Sendable {
    public init() {}

    public func resolve(profile: CharacterProfile, pinned versionID: CharacterVersionID?) throws -> CharacterVersion {
        if let versionID {
            // An explicit pin is exact. If it is gone, that is an error, not a
            // reason to quietly substitute a different-looking child.
            guard let version = profile.version(id: versionID) else {
                throw CharacterEngineError.versionNotFound(profile.id, versionID)
            }
            return version
        }

        if let active = profile.activeVersion, active.isUsable {
            return active
        }

        // Active version is missing or has no reference image: fall back to the
        // newest usable snapshot rather than failing the whole story.
        let usable = profile.versions
            .filter(\.isUsable)
            .sorted { $0.versionNumber > $1.versionNumber }

        guard let best = usable.first else {
            throw CharacterEngineError.noUsableVersion(profile.id)
        }
        return best
    }
}
