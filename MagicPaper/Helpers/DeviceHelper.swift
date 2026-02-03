import SwiftUI

struct DeviceHelper {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    // Horizontal padding - iPad'de daha fazla
    static var horizontalPadding: CGFloat {
        isIPad ? 60 : 20
    }
    
    // Vertical padding
    static var verticalPadding: CGFloat {
        isIPad ? 32 : 20
    }
    
    // Card spacing
    static var cardSpacing: CGFloat {
        isIPad ? 24 : 16
    }
    
    // Font scale
    static var fontScale: CGFloat {
        isIPad ? 1.15 : 1.0
    }
    
    // Tab bar bottom padding
    static var tabBarBottomPadding: CGFloat {
        isIPad ? 90 : 80
    }
    
    // Minimum touch target size (Apple HIG: 44x44pt)
    static var minTouchTarget: CGFloat {
        44
    }
    
    // Adaptive font sizes
    static func fontSize(_ base: CGFloat) -> CGFloat {
        base * fontScale
    }
    
    // Adaptive spacing
    static func spacing(_ base: CGFloat) -> CGFloat {
        isIPad ? base * 1.5 : base
    }
    
    // Grid columns for iPad
    static var gridColumns: Int {
        isIPad ? 2 : 1
    }
    
    // Card corner radius
    static var cornerRadius: CGFloat {
        isIPad ? 24 : 20
    }
    
    // Icon size
    static var iconSize: CGFloat {
        isIPad ? 32 : 24
    }
}

// SwiftUI View extension
extension View {
    func adaptivePadding() -> some View {
        self.padding(.horizontal, DeviceHelper.horizontalPadding)
    }
    
    func adaptiveFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.font(.system(size: DeviceHelper.fontSize(size), weight: weight))
    }
    
    func minTouchSize() -> some View {
        self.frame(minWidth: DeviceHelper.minTouchTarget, minHeight: DeviceHelper.minTouchTarget)
    }
}

