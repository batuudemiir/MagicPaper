import SwiftUI

/// Karşılama ve başlangıç ekranlarının arka planı: düz zemin üstünde üç
/// yumuşak radyal ışık (reference/html/Main, Onboarding2, Onboarding3).
/// Gradyan yalnızca bu malzeme taklidinde; içerik yüzeyleri düz kalır.
struct MPGlowBackground: View {
    enum Style { case dawn, night, lilac }
    var style: Style = .dawn

    private struct Glow { let color: Color; let x: CGFloat; let y: CGFloat; let radius: CGFloat }

    private var base: Color {
        switch style {
        case .dawn:  MPColor.glowDawnBase
        case .night: MPColor.glowNightBase
        case .lilac: MPColor.glowLilacBase
        }
    }

    private var glows: [Glow] {
        switch style {
        case .dawn:
            [Glow(color: MPColor.glowLilac.opacity(0.75), x: 0.5, y: 0.34, radius: 0.46),
             Glow(color: MPColor.glowPink.opacity(0.35), x: 0.12, y: 0.7, radius: 0.38),
             Glow(color: MPColor.glowGold.opacity(0.25), x: 0.9, y: 0.18, radius: 0.34)]
        case .night:
            [Glow(color: MPColor.glowViolet.opacity(0.55), x: 0.5, y: 0.34, radius: 0.46),
             Glow(color: MPColor.glowPlum.opacity(0.6), x: 0.12, y: 0.7, radius: 0.38),
             Glow(color: MPColor.glowGold.opacity(0.18), x: 0.9, y: 0.18, radius: 0.34)]
        case .lilac:
            [Glow(color: Color.white.opacity(0.85), x: 0.5, y: 0.34, radius: 0.46),
             Glow(color: MPColor.glowPink.opacity(0.35), x: 0.12, y: 0.7, radius: 0.38),
             Glow(color: MPColor.glowViolet.opacity(0.25), x: 0.9, y: 0.18, radius: 0.34)]
        }
    }

    var body: some View {
        GeometryReader { geo in
            let side = max(geo.size.width, geo.size.height)
            ZStack {
                base
                ForEach(Array(glows.enumerated()), id: \.offset) { _, glow in
                    RadialGradient(colors: [glow.color, glow.color.opacity(0)],
                                   center: UnitPoint(x: glow.x, y: glow.y),
                                   startRadius: 0, endRadius: side * glow.radius)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Sayfa noktaları: seçili olan uzun kapsül (02-04, 07-08 adım göstergesi).
struct MPPageDots: View {
    let count: Int
    let current: Int
    var onDark: Bool = false

    var body: some View {
        HStack(spacing: MPSpacing.xs) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(color(selected: index == current))
                    .frame(width: index == current ? 22 : 8, height: 8)
            }
        }
        .animation(MP.M.gated(MP.M.base), value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sayfa \(current + 1) / \(count)")
    }

    private func color(selected: Bool) -> Color {
        if onDark { return selected ? .white : Color.white.opacity(0.35) }
        return selected ? MPColor.actionPrimary : MPColor.actionPrimary.opacity(0.18)
    }
}
