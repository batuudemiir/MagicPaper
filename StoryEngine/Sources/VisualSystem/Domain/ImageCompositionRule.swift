import Foundation
import EngineFoundation

/// Where things sit in frame, and what must stay clear for text.
public struct ImageCompositionRule: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let version: SemanticVersion
    public let displayName: String
    public let subjectAnchor: Anchor
    public let textSafeArea: SafeArea
    public let cameraDistance: CameraDistance
    public let aspectRatio: AspectRatio
    public let headroomRules: [String]

    public init(
        id: String,
        version: SemanticVersion,
        displayName: String,
        subjectAnchor: Anchor,
        textSafeArea: SafeArea,
        cameraDistance: CameraDistance,
        aspectRatio: AspectRatio,
        headroomRules: [String] = []
    ) {
        self.id = id
        self.version = version
        self.displayName = displayName
        self.subjectAnchor = subjectAnchor
        self.textSafeArea = textSafeArea
        self.cameraDistance = cameraDistance
        self.aspectRatio = aspectRatio
        self.headroomRules = headroomRules
    }

    /// Deterministic clause list. Order is fixed because it feeds fingerprints.
    public var clauses: [String] {
        var result: [String] = []
        switch subjectAnchor {
        case .left: result.append("subject positioned on the left third of the frame")
        case .right: result.append("subject positioned on the right third of the frame")
        case .center: result.append("subject centered in frame")
        case .fullBleed: result.append("subject filling the frame edge to edge")
        }
        switch cameraDistance {
        case .closeUp: result.append("close-up shot")
        case .medium: result.append("medium shot")
        case .wide: result.append("wide shot")
        case .establishing: result.append("establishing shot of the whole setting")
        }
        if !textSafeArea.isEmpty { result.append(textSafeArea.clause) }
        result.append(aspectRatio.clause)
        result.append(contentsOf: headroomRules)
        return result
    }
}
