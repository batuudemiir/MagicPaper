import Foundation
import EngineFoundation

/// Type settings for page text.
///
/// The engine renders nothing, but it carries these so the eventual UI and the
/// illustration's text-safe area come from one source. A layout that reserves
/// the lower third for six lines of 17pt type is making a promise the
/// illustration has to keep.
public struct TypographyPreset: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let version: SemanticVersion
    public let fontRole: String
    public let pointSize: Double
    public let lineHeightMultiple: Double
    public let tracking: Double
    /// Line ceiling per layout, keyed by `PageLayout.rawValue`.
    public let maximumLinesByLayout: [String: Int]

    public init(
        id: String,
        version: SemanticVersion,
        fontRole: String,
        pointSize: Double,
        lineHeightMultiple: Double,
        tracking: Double = 0,
        maximumLinesByLayout: [String: Int] = [:]
    ) {
        self.id = id
        self.version = version
        self.fontRole = fontRole
        self.pointSize = pointSize
        self.lineHeightMultiple = lineHeightMultiple
        self.tracking = tracking
        self.maximumLinesByLayout = maximumLinesByLayout
    }

    public func maximumLines(for layout: PageLayout) -> Int? {
        maximumLinesByLayout[layout.rawValue]
    }
}
