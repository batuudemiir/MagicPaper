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
        case .dawn:  Color(red: 0xFD / 255, green: 0xF5 / 255, blue: 0xEE / 255)
        case .night: Color(red: 0x3A / 255, green: 0x24 / 255, blue: 0x58 / 255)
        case .lilac: Color(red: 0xF3 / 255, green: 0xE6 / 255, blue: 0xF8 / 255)
        }
    }

    private var glows: [Glow] {
        switch style {
        case .dawn:
            [Glow(color: Color(red: 230 / 255, green: 199 / 255, blue: 242 / 255).opacity(0.75), x: 0.5, y: 0.34, radius: 0.46),
             Glow(color: Color(red: 242 / 255, green: 163 / 255, blue: 195 / 255).opacity(0.35), x: 0.12, y: 0.7, radius: 0.38),
             Glow(color: Color(red: 244 / 255, green: 183 / 255, blue: 53 / 255).opacity(0.25), x: 0.9, y: 0.18, radius: 0.34)]
        case .night:
            [Glow(color: Color(red: 143 / 255, green: 107 / 255, blue: 214 / 255).opacity(0.55), x: 0.5, y: 0.34, radius: 0.46),
             Glow(color: Color(red: 92 / 255, green: 58 / 255, blue: 143 / 255).opacity(0.6), x: 0.12, y: 0.7, radius: 0.38),
             Glow(color: Color(red: 244 / 255, green: 183 / 255, blue: 53 / 255).opacity(0.18), x: 0.9, y: 0.18, radius: 0.34)]
        case .lilac:
            [Glow(color: Color.white.opacity(0.85), x: 0.5, y: 0.34, radius: 0.46),
             Glow(color: Color(red: 242 / 255, green: 163 / 255, blue: 195 / 255).opacity(0.35), x: 0.12, y: 0.7, radius: 0.38),
             Glow(color: Color(red: 143 / 255, green: 107 / 255, blue: 214 / 255).opacity(0.25), x: 0.9, y: 0.18, radius: 0.34)]
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
