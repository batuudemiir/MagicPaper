import SwiftUI

/// MagicPaper Page Turn Configuration
/// Centralized constants for the page turn physical motion model.
enum MagicPaperPageTurnConfiguration {

    // MARK: - Feature Flag
    
    /// Set to true to use the new custom SwiftUI page turn renderer.
    /// Set to false to fall back to the legacy UIPageViewController (.pageCurl).
    static let useCustomRenderer = true

    // MARK: - Motion Constants

    /// Completion distance threshold (e.g., 25% of screen width).
    static let completionThreshold: CGFloat = 0.25
    
    /// Minimum horizontal velocity to consider a swipe intentional even if distance is short.
    static let intentionalVelocityThreshold: CGFloat = 300.0

    /// Visual rotation at 100% progress.
    static let maximumRotationDegrees: Double = 172

    /// Shadow opacity ranges.
    static let shadowOpacityMinimum: Double = 0.0
    static let shadowOpacityMaximum: Double = 0.12

    /// Subtle fold highlight maximum opacity.
    static let highlightMaximumOpacity: Double = 0.08

    /// Kıvrılan sayfanın arkasında ön yüzün mürekkebi ne kadar seçilir.
    static let backFaceInkOpacity: Double = 0.07

    /// Subtle 3D perspective multiplier.
    static let perspective: CGFloat = 0.75

    /// Tappable area at the edges.
    static let edgeTapWidthRatio: CGFloat = 0.15
}
