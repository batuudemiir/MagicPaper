import SwiftUI
import UIKit

/// Decorative selection art; the enclosing choice row owns the spoken label.
struct MPCompanionPortrait: View {
    let companionID: String
    let fallbackSymbol: String
    /// Satırda küçük; küçük kademe ızgarasında karonun büyük resmi (`MPSize.minTouchHero`).
    var size: CGFloat = MPSize.minTouchKid - MPSpacing.xxs

    var body: some View {
        Group {
            if let name = CompanionPortraitCatalog.assetName(for: companionID),
               let image = UIImage(named: name) {
                Image(uiImage: image)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                MPIconTile(systemImage: fallbackSymbol, tone: .lav, size: size)
            }
        }
        .accessibilityHidden(true)
    }
}
