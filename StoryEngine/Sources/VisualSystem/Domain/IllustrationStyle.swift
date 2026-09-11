import Foundation
import EngineFoundation

/// How an illustration is painted. The "medium and light" half of the design
/// system, versioned so a restyle never silently rewrites existing books.
public struct IllustrationStyle: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let version: SemanticVersion
    public let displayName: String
    public let mediumClauses: [String]
    public let lightingClauses: [String]
    public let renderingConstraints: [String]
    /// Things that must never appear. Compiled into every negative prompt.
    public let forbiddenClauses: [String]

    public init(
        id: String,
        version: SemanticVersion,
        displayName: String,
        mediumClauses: [String],
        lightingClauses: [String],
        renderingConstraints: [String] = [],
        forbiddenClauses: [String] = []
    ) {
        self.id = id
        self.version = version
        self.displayName = displayName
        self.mediumClauses = mediumClauses
        self.lightingClauses = lightingClauses
        self.renderingConstraints = renderingConstraints
        self.forbiddenClauses = forbiddenClauses
    }
}
