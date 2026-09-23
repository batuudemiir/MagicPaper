import SwiftUI

enum MagicPaperPageTurnDirection {
    case forward
    case backward
}

enum MagicPaperPageTurnPhase {
    case idle
    case dragging
    case completing
    case cancelling
}

/// Holds transient animation state for the page-turn engine.
struct MagicPaperPageTurnState: Equatable {
    var phase: MagicPaperPageTurnPhase = .idle
    var direction: MagicPaperPageTurnDirection? = nil
    
    /// Normalized progress from 0.0 (completely flat) to 1.0 (completely turned).
    var progress: CGFloat = 0.0
    
    /// Tracks whether the commitment haptic has fired for this interaction.
    var hapticTriggered: Bool = false
    
    mutating func reset() {
        phase = .idle
        direction = nil
        progress = 0.0
        hapticTriggered = false
    }
}
