// MPButtons.swift
// Buttons used across all 45 screens. One primary button per screen.
// Screens: every CTA ("Devam et", "Masalı yaz", "Onaylıyorum"), ghost links ("Şimdi değil"),
// circle buttons (back, close), secondary buttons ("Planlar", "Kopyala").

import SwiftUI

/// Roller: `docs/MARKA.md`. `outline` yalnızca giriş sağlayıcısı içindir.
enum MPButtonKind { case primary, secondary, outline, ghost, danger }
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
            HStack(spacing: MPSpacing.sm) {
                if isLoading {
                    ProgressView().tint(foreground)
                } else {
                    if let systemImage { MPIcon(systemImage, size: 16, weight: .bold).accessibilityHidden(true) }
                    label
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, size == .small ? MPSpacing.lg : 28)
            .padding(.vertical, MPSpacing.xs)
            // En büyük yazı boyutunda düğme uzar, etiket kesilmez.
            .frame(minHeight: height)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(minWidth: kind == .primary && !fullWidth ? 220 : nil)
            .background(background)
            .overlay(border)
            .clipShape(Capsule())
            // Küçük düğme görünürde küçük, dokunma alanı yine tam.
            .padding(.vertical, size == .small ? (MP.S.tapMin - MPSize.buttonHeightSmall) / 2 : 0)
            .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle(kind == .primary && isEnabled ? .onEdge(MPColor.brandNight) : .sink))
        .disabled(isLoading)
        .accessibilityLabel(title)
    }

    @ViewBuilder private var label: some View {
        if size == .small {
            Text(title).mpText(.callout).fontWeight(.bold)
        } else {
            Text(title).mpText(.button)
        }
    }

    private var height: CGFloat {
        switch size {
        case .small: MPSize.buttonHeightSmall
        case .auth: MPSize.buttonHeightAuth
        case .regular:
            switch kind {
            case .primary: MPSize.buttonHeight
            case .ghost: MP.S.tapMin
            case .secondary, .outline, .danger: MPSize.buttonHeightSecondary
            }
        }
    }

    private var foreground: Color {
        guard isEnabled else { return MPColor.textSecondary }
        return switch kind {
        case .primary, .danger: MPColor.textOnAction
        // İkincil düğme lavanta zeminde mor yazı (karar: 22 Ekim 2026, A).
        case .secondary, .outline, .ghost: MPColor.actionPrimary
        }
    }

    /// Devre dışı düz gri ve kenarsız: saydamlık altındaki zemini bulandırıyordu.
    @ViewBuilder private var background: some View {
        switch kind {
        case .ghost: Color.clear
        case _ where !isEnabled: MPColor.actionDisabled
        case .primary: MPColor.actionPrimary
        case .danger: MPColor.statusDanger
        case .outline: MPColor.backgroundSurface
        case .secondary: MPColor.actionSoft
        }
    }

    @ViewBuilder private var border: some View {
        switch kind {
        case .outline: Capsule().strokeBorder(MPColor.borderOutline, lineWidth: 2)
        default: EmptyView()
        }
    }
}

/// 42 pt round icon button: back (chevron.left), close (xmark), lock, settings, favourite.
struct MPCircleButton: View {
    let systemImage: String
    let accessibilityLabel: String
    var size: CGFloat = MPSize.circleButton
    /// Yuvarlak düğme lavanta zeminde mor ikon, çerçevesiz (karar: 22 Ekim
    /// 2026, A; önceden beyaz, gri çerçeve, siyah ikon).
    var bordered: Bool = false
    var tint: Color = MPColor.actionPrimary
    /// Gece yüzeylerinde (Uyku modu) koyu dolgu.
    var fill: Color = MPColor.actionSoft
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

#Preview("Buttons") {
    VStack(spacing: 16) {
        MPButton(title: "Devam et") {}
        MPButton(title: "Masalı yaz", systemImage: "wand.and.sparkles") {}
        MPButton(title: "Planlar", kind: .secondary, fullWidth: true) {}
        MPButton(title: "Düzenle", kind: .secondary, size: .small) {}
        MPButton(title: "Şimdi değil", kind: .ghost) {}
        MPButton(title: "Onaylıyorum") {}.disabled(true)
        MPCircleButton(systemImage: "chevron.left", accessibilityLabel: "Geri") {}
    }
    .padding()
    .background(MPColor.backgroundKid)
}
