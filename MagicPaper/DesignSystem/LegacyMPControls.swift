import SwiftUI
import UIKit

// MARK: - MPBadge

struct MPBadge: View {
    enum Tone { case brand, reward, calm, play, neutral, solid }

    let title: String
    var tone: Tone = .brand
    var symbol: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            if let symbol { MPIcon(symbol, size: 13, weight: .bold) }
            Text(title)
        }
        .font(MP.F.labelSM())
        .foregroundStyle(colors.fg)
        .padding(.horizontal, 11)
        .padding(.vertical, 5)
        .background(Capsule().fill(colors.bg))
        .fixedSize()
    }

    private var colors: (bg: Color, fg: Color) {
        switch tone {
        case .brand:   return (MP.C.brandSoft, MP.C.brandInk)
        case .reward:  return (MP.C.rewardSoft, MP.C.premiumInk)
        case .calm:    return (MP.C.calmSoft, MP.Palette.yesim600)
        case .play:    return (MP.C.playSoft, MP.Palette.mercan600)
        case .neutral: return (MP.C.surfaceSunken, MP.C.textMuted)
        case .solid:   return (MP.C.brand, MP.C.textOnBrand)
        }
    }
}
