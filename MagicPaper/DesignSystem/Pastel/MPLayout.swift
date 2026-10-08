// MPLayout.swift
// Spacing, radius, component sizes, shadows and motion from design-system/tokens.json.

import SwiftUI

enum MPSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 6
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    /// Horizontal screen gutter on every phone screen.
    static let screenH: CGFloat = 20
    /// Gap between page sections (Özet, Ayarlar, Benim köşem).
    static let section: CGFloat = 22
}

enum MPRadius {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 14
    static let input: CGFloat = 18
    static let tile: CGFloat = 22
    static let card: CGFloat = 24
    static let cardLarge: CGFloat = 26
    static let hero: CGFloat = 30
    static let sheet: CGFloat = 32
}

enum MPSize {
    static let buttonHeight: CGFloat = 52
    static let buttonHeightAuth: CGFloat = 54
    static let buttonHeightSmall: CGFloat = 44
    static let chipHeight: CGFloat = 38
    static let circleButton: CGFloat = 42
    static let headerAvatar: CGFloat = 48
    static let kidTabBarHeight: CGFloat = 86
    static let createFab: CGFloat = 64
    static let parentTabBarHeight: CGFloat = 84
    /// Minimum hit area. Kid area 56, parent area 44.
    static let minTouchKid: CGFloat = 56
    static let minTouchParent: CGFloat = 44
    static let iconTile: CGFloat = 52
    static let segmentHeight: CGFloat = 40
    static let inputHeight: CGFloat = 52
}

enum MPShadow {
    case card, raised, control, primaryGlow, sheet

    fileprivate var spec: (color: Color, radius: CGFloat, y: CGFloat) {
        let ink = MPColor.shadowInk
        switch self {
        case .card: return (ink.opacity(0.06), 9, 6)
        case .raised: return (ink.opacity(0.10), 14, 12)
        case .control: return (ink.opacity(0.08), 6, 4)
        case .primaryGlow: return (MPColor.actionGradientBottom.opacity(0.32), 11, 10)
        case .sheet: return (ink.opacity(0.18), 15, -10)
        }
    }
}

extension View {
    /// CSS blur radius 2r ≈ SwiftUI shadow radius r, so tokens are halved here on purpose.
    func mpShadow(_ s: MPShadow) -> some View {
        let spec = s.spec
        return shadow(color: spec.color, radius: spec.radius, x: 0, y: spec.y)
    }
}

enum MPMotion {
    static let tap: Double = 0.15
    static let transition: Double = 0.25
    static let celebration: Double = 0.40
    static let pressScale: CGFloat = 0.96
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
}

// Basma davranışı: mevcut `MPPressStyle` (DesignSystem/MPTheme.swift) kullanılır.
