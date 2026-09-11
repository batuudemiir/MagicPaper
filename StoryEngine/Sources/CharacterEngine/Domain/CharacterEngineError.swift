import Foundation

public enum CharacterEngineError: Error, Equatable, Sendable {
    case profileNotFound(CharacterID)
    case versionNotFound(CharacterID, CharacterVersionID)
    case noUsableVersion(CharacterID)
    case emptyCast
    case duplicateCastRole(String)
    case extractionUnavailable(String)
}

extension CharacterEngineError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .profileNotFound(let id):
            return "No character profile for \(id)."
        case .versionNotFound(let character, let version):
            return "Character \(character) has no version \(version)."
        case .noUsableVersion(let id):
            return "Character \(id) has no version with a usable reference image."
        case .emptyCast:
            return "A cast binding must name at least a protagonist."
        case .duplicateCastRole(let role):
            return "Cast role '\(role)' was bound more than once."
        case .extractionUnavailable(let reason):
            return "Character extraction unavailable: \(reason)"
        }
    }
}
