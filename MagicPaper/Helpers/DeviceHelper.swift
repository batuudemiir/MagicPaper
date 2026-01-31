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
}

// SwiftUI View extension
extension View {
    func adaptivePadding() -> some View {
        self.padding(.horizontal, DeviceHelper.horizontalPadding)
    }
}
