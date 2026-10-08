// MPButtons.swift
// Buttons used across all 45 screens. One primary button per screen.
// Screens: every CTA ("Devam et", "Masalı yaz", "Onaylıyorum"), ghost links ("Şimdi değil"),
// circle buttons (back, close, lock), soft buttons ("Planlar", "Kopyala").

import SwiftUI

enum MPButtonKind { case primary, secondary, soft, outline, ghost, danger }
enum MPButtonSize { case regular, small, auth }

struct MPButton: View {
    let title: String
    var systemImage: String? = nil
    var kind: MPButtonKind = .primary
    var size: MPButtonSize = .regular
    var fullWidth: Bool = false
    var isLoading: Bool = false
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(foreground)
                } else {
                    if let systemImage { MPIcon(systemImage, size: 16, weight: .bold) }
                    Text(title).mpText(kind == .primary || kind == .danger ? .button : .callout)
                }
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, size == .small ? 16 : 28)
            .frame(height: height)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(minWidth: kind == .primary && !fullWidth ? 220 : nil)
            .background(background)
            .overlay(border)
            .clipShape(Capsule())
            .modifier(PrimaryGlow(active: kind == .primary && isEnabled))
            .opacity(isEnabled ? 1 : 0.4)
        }
        .buttonStyle(MPPressStyle())
        .disabled(isLoading)
        .accessibilityLabel(title)
    }

    private var height: CGFloat {
        switch size {
        case .regular: kind == .ghost ? MPSize.buttonHeightSmall : MPSize.buttonHeight
        case .small: 38
        case .auth: MPSize.buttonHeightAuth
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary, .danger: MPColor.textOnAction
        case .secondary: MPColor.textPrimary
        case .soft, .outline, .ghost: MPColor.actionPrimary
        }
    }

    @ViewBuilder private var background: some View {
        switch kind {
        case .primary:
            ZStack {
                LinearGradient.mpPrimary
                // glossy top highlight + bottom inner shade (inset shadows in the prototype)
                VStack(spacing: 0) {
                    Color.white.opacity(0.45).frame(height: 2)
                    Spacer()
                    Color.black.opacity(0.10).frame(height: 3)
                }
            }
        case .danger: MPColor.statusDanger
        case .secondary, .outline: MPColor.backgroundSurface
        case .soft: MPColor.actionSoft
        case .ghost: Color.clear
        }
    }

    @ViewBuilder private var border: some View {
        switch kind {
        case .outline: Capsule().strokeBorder(MPColor.borderOutline, lineWidth: 2)
        case .secondary: Capsule().strokeBorder(MPColor.borderKid, lineWidth: 1.5)
        default: EmptyView()
        }
    }
}

private struct PrimaryGlow: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        if active { content.mpShadow(.primaryGlow) } else { content }
    }
}

/// 42 pt round icon button: back (chevron.left), close (xmark), lock, settings, favourite.
struct MPCircleButton: View {
    let systemImage: String
    let accessibilityLabel: String
    var size: CGFloat = MPSize.circleButton
    var bordered: Bool = true
    var tint: Color = MPColor.textPrimary
    /// Gece yüzeylerinde (Uyku modu) koyu dolgu.
    var fill: Color = MPColor.backgroundSurface
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MPIcon(systemImage, size: size * 0.45, weight: .semibold)
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(fill, in: Circle())
                .overlay(Circle().strokeBorder(bordered ? MPColor.borderKid : .clear, lineWidth: 1.5))
                .contentShape(Circle().inset(by: -6))
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Big round gradient button: reader play/pause, page turn, record.
struct MPRoundActionButton: View {
    let systemImage: String
    let accessibilityLabel: String
    var size: CGFloat = 58
    var fill: AnyShapeStyle = AnyShapeStyle(LinearGradient.mpPrimary)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MPIcon(systemImage, size: size * 0.4, weight: .bold)
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(fill, in: Circle())
                .mpShadow(.primaryGlow)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview("Buttons") {
    VStack(spacing: 16) {
        MPButton(title: "Devam et") {}
        MPButton(title: "Masalı yaz", systemImage: "wand.and.sparkles") {}
        MPButton(title: "Şimdi değil", kind: .outline, fullWidth: true) {}
        MPButton(title: "Planlar", kind: .soft, size: .small) {}
        MPButton(title: "Şimdi değil", kind: .ghost) {}
        MPButton(title: "Onaylıyorum") {}.disabled(true)
        HStack { MPCircleButton(systemImage: "chevron.left", accessibilityLabel: "Geri") {}; MPRoundActionButton(systemImage: "play.fill", accessibilityLabel: "Sesli oku") {} }
    }
    .padding()
    .background(MPColor.backgroundKid)
}
