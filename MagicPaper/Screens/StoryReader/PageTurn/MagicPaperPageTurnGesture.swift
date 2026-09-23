import SwiftUI

/// Calculates page-turn progress based on horizontal translation and velocity.
enum MagicPaperPageTurnGesture {
    
    /// Normalizes horizontal drag translation into a 0.0...1.0 progress range.
    static func progress(translation: CGFloat, totalWidth: CGFloat, direction: MagicPaperPageTurnDirection) -> CGFloat {
        guard totalWidth > 0 else { return 0 }
        
        // translation is negative for right-to-left (forward)
        // translation is positive for left-to-right (backward)
        let rawProgress: CGFloat
        if direction == .forward {
            rawProgress = -translation / totalWidth
        } else {
            rawProgress = translation / totalWidth
        }
        
        return max(0, min(1, rawProgress))
    }
    
    /// Determines whether the drag crosses the commitment threshold.
    /// Incorporates both distance and velocity.
    static func shouldComplete(progress: CGFloat, velocity: CGFloat, direction: MagicPaperPageTurnDirection) -> Bool {
        let isIntentionalVelocity: Bool
        if direction == .forward {
            // Forward means swiping left, so velocity should be negative
            isIntentionalVelocity = velocity < -MagicPaperPageTurnConfiguration.intentionalVelocityThreshold
        } else {
            // Backward means swiping right, so velocity should be positive
            isIntentionalVelocity = velocity > MagicPaperPageTurnConfiguration.intentionalVelocityThreshold
        }
        
        if progress >= MagicPaperPageTurnConfiguration.completionThreshold {
            return true
        }
        
        // If they haven't crossed the distance threshold but swiped very fast in the correct direction
        // and have dragged at least *some* distance (e.g. 10%)
        if isIntentionalVelocity && progress > 0.10 {
            return true
        }
        
        return false
    }
    
    /// Determines if a drag is primarily horizontal (ignoring vertical scrolls)
    static func isHorizontalDrag(translation: CGSize) -> Bool {
        return abs(translation.width) > abs(translation.height) * 1.15
    }
}
