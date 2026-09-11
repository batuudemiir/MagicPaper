import Foundation

/// How a page is built. Deterministic: chosen by rule, never by a model.
public enum PageLayout: String, Codable, Sendable, CaseIterable, Hashable {
    case fullBleedImage
    case imageTopTextBottom
    case imageBottomTextTop
    case sideBySide
    case spread
    case textOnly

    /// Whether this layout needs an illustration at all. `textOnly` pages cost
    /// nothing to draw, which the budget and the validator both care about.
    public var requiresImage: Bool { self != .textOnly }
}

/// Where the subject sits in frame.
public enum Anchor: String, Codable, Sendable, CaseIterable, Hashable {
    case left, right, center, fullBleed
}

public enum CameraDistance: String, Codable, Sendable, CaseIterable, Hashable {
    case closeUp, medium, wide, establishing
}

public enum AspectRatio: String, Codable, Sendable, CaseIterable, Hashable {
    case square          // 1:1
    case portrait        // 3:4
    case landscape       // 4:3
    case wideLandscape   // 16:9

    public var ratio: Double {
        switch self {
        case .square: return 1.0
        case .portrait: return 3.0 / 4.0
        case .landscape: return 4.0 / 3.0
        case .wideLandscape: return 16.0 / 9.0
        }
    }

    /// Vendor-neutral wording; providers map it to their own parameter.
    public var clause: String {
        switch self {
        case .square: return "square 1:1 framing"
        case .portrait: return "portrait 3:4 framing"
        case .landscape: return "landscape 4:3 framing"
        case .wideLandscape: return "wide 16:9 framing"
        }
    }
}

/// The region of the frame typography will sit on, as fractions of width and
/// height. Illustrations must keep it uncluttered or the text becomes unreadable.
public struct SafeArea: Codable, Sendable, Hashable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public static let none = SafeArea(x: 0, y: 0, width: 0, height: 0)
    public var isEmpty: Bool { width <= 0 || height <= 0 }

    /// Human-readable placement used when telling an image model where to keep
    /// the frame quiet.
    public var clause: String {
        guard !isEmpty else { return "no reserved text area" }
        let vertical = y < 0.34 ? "upper" : (y > 0.5 ? "lower" : "middle")
        let horizontal = x < 0.34 ? "left" : (x > 0.5 ? "right" : "center")
        return "keep the \(vertical) \(horizontal) area uncluttered for text"
    }
}
