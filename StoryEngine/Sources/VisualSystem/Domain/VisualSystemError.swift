import Foundation
import EngineFoundation

public enum VisualSystemError: Error, Equatable, Sendable {
    case stylePresetNotFound(String)
    case illustrationStyleNotFound(String)
    case paletteNotFound(String)
    case typographyNotFound(String)
    case compositionRuleNotFound(String)
    case layoutRuleNotFound(String)
    case noLayoutRuleMatches(pageIndex: Int, beatRole: String)
    case catalogUnavailable(String)
}

extension VisualSystemError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .stylePresetNotFound(let id): return "No visual style preset '\(id)'."
        case .illustrationStyleNotFound(let id): return "No illustration style '\(id)'."
        case .paletteNotFound(let id): return "No palette preset '\(id)'."
        case .typographyNotFound(let id): return "No typography preset '\(id)'."
        case .compositionRuleNotFound(let id): return "No composition rule '\(id)'."
        case .layoutRuleNotFound(let id): return "No page layout rule '\(id)'."
        case .noLayoutRuleMatches(let index, let role):
            return "No layout rule matches page \(index) with beat role '\(role)'."
        case .catalogUnavailable(let reason): return "Visual catalog unavailable: \(reason)"
        }
    }
}
