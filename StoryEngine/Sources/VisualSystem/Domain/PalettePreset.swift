import Foundation
import EngineFoundation

/// A colour world. `dominantHexes` exist so the app's own design tokens and the
/// illustration palette can be checked against each other rather than drifting.
public struct PalettePreset: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let version: SemanticVersion
    public let displayName: String
    public let paletteClauses: [String]
    public let dominantHexes: [String]

    public init(id: String, version: SemanticVersion, displayName: String, paletteClauses: [String], dominantHexes: [String] = []) {
        self.id = id
        self.version = version
        self.displayName = displayName
        self.paletteClauses = paletteClauses
        self.dominantHexes = dominantHexes
    }
}
