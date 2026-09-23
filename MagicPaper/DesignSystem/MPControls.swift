import SwiftUI
import UIKit

// MARK: - MPButton

struct MPButton: View {
    enum Variant { case solid, soft, outline, ghost }
    enum Tone { case brand, reward, play, calm }
    enum Size {
        case sm, md, lg
        var height: CGFloat { self == .sm ? 40 : self == .md ? 52 : 60 }
        var hPad: CGFloat { self == .sm ? 16 : self == .md ? 22 : 28 }
        var font: CGFloat { self == .sm ? 15 : self == .md ? 16 : 18 }
        var icon: CGFloat { self == .sm ? 18 : self == .md ? 20 : 22 }
        var radius: CGFloat { self == .sm ? MP.R.md : MP.R.button }
    }

    let title: String
    var variant: Variant = .solid
    var tone: Tone = .brand
    var size: Size = .md
    var icon: String? = nil
    var iconAfter: String? = nil
    var fullWidth: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    private var toneColors: (bg: Color, edge: Color, fg: Color) {
        switch tone {
        case .brand:  return (MP.C.brand, MP.C.brandEdge, MP.C.textOnBrand)
        case .reward: return (MP.C.reward, MP.C.rewardEdge, MP.Palette.murekkep900)
        case .play:   return (MP.C.play, MP.C.playEdge, MP.Palette.kagit0)
        case .calm:   return (MP.C.calm, MP.C.calmEdge, MP.Palette.kagit0)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon { MPIcon(icon, size: size.icon, weight: .semibold) }
                // Buton yüksekliği sabit (40/52/60). Etiket ikinci satıra
                // taşarsa geometri bozulur — bu yüzden tek satır, gerekirse
                // hafifçe küçültülür.
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if let iconAfter { MPIcon(iconAfter, size: size.icon, weight: .semibold) }
            }
            .font(.custom(MP.F.display, size: size.font).weight(.bold))
            .mpTightTracking(size.font)
            .foregroundStyle(foreground)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.hPad)
            .modifier(Skin(variant: variant, tone: toneColors, radius: size.radius, isDisabled: isDisabled))
        }
        .buttonStyle(MPPressStyle())
        .disabled(isDisabled)
    }

    private var foreground: Color {
        if isDisabled { return MP.C.textFaint }
        switch variant {
        case .solid: return toneColors.fg
        case .soft: return MP.Palette.gul600
        case .outline: return MP.C.textTitle
        case .ghost: return MP.C.textLink
        }
    }

    private struct Skin: ViewModifier {
        let variant: Variant
        let tone: (bg: Color, edge: Color, fg: Color)
        let radius: CGFloat
        let isDisabled: Bool

        @ViewBuilder func body(content: Content) -> some View {
            switch variant {
            case .solid:
                if isDisabled {
                    content.background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(MP.Palette.kagit300))
                } else {
                    content
                        .mpEdge(fill: tone.bg, edge: tone.edge, radius: radius)
                        .overlay(   // inset 0 1px 0 rgba(255,255,255,.5)
                            RoundedRectangle(cornerRadius: radius, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                                .mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center))
                        )
                }
            case .soft:
                content.mpEdge(fill: MP.C.brandSoft, edge: MP.Palette.gul100, radius: radius)
            case .outline:
                content
                    .mpEdge(fill: MP.C.surfaceCard, edge: MP.C.borderStrong, radius: radius, width: MP.E.widthLG)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(MP.C.borderHairline, lineWidth: 2)
                            .padding(.bottom, MP.E.widthLG)
                    )
            case .ghost:
                content
            }
        }
    }
}

// MARK: - MPIconButton

struct MPIconButton: View {
    enum Tone { case paper, brand, sunken, glass }

    let symbol: String
    /// Türkçe erişilebilirlik etiketi — zorunlu.
    let label: String
    var size: CGFloat = 44
    var tone: Tone = .paper
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MPIcon(symbol, size: size * 0.48, weight: .semibold)
                .foregroundStyle(fg)
                .frame(width: size, height: size)
                .modifier(Skin(tone: tone))
        }
        .buttonStyle(MPPressStyle(scales: false))
        .accessibilityLabel(label)
    }

    private var fg: Color {
        switch tone {
        case .paper, .glass: return MP.C.textTitle
        case .brand: return MP.C.textOnBrand
        case .sunken: return MP.C.textBody
        }
    }

    private struct Skin: ViewModifier {
        let tone: Tone
        @ViewBuilder func body(content: Content) -> some View {
            switch tone {
            case .paper:
                content.mpEdge(fill: MP.C.surfaceCard, edge: MP.C.edgeCard, radius: MP.R.md)
            case .brand:
                content.mpEdge(fill: MP.C.brand, edge: MP.C.brandEdge, radius: MP.R.md)
            case .sunken:
                content.mpEdge(fill: MP.C.surfaceSunken, edge: MP.C.borderStrong, radius: MP.R.md)
            case .glass:
                content
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: MP.R.md, style: .continuous))
                    .mpEdge(fill: Color.white.opacity(0.82), edge: MP.C.edgeGlass, radius: MP.R.md)
            }
        }
    }
}

// MARK: - MPChip

struct MPChip: View {
    let title: String
    var symbol: String? = nil
    var isSelected: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let symbol { MPIcon(symbol, size: 16, weight: .semibold) }
                // Chip yüksekliği sabit 42px — etiket asla ikinci satıra inmez.
                Text(title).lineLimit(1).fixedSize(horizontal: true, vertical: false)
            }
            .font(MP.F.labelMD())
            .foregroundStyle(isSelected ? MP.C.textOnBrand : (isDisabled ? MP.C.textFaint : MP.C.textBody))
            .frame(height: 42)
            .padding(.horizontal, 16)
            .mpEdge(
                fill: isSelected ? MP.C.brand : MP.C.surfaceCard,
                edge: isSelected ? MP.C.brandEdge : MP.C.borderStrong,
                radius: MP.R.pill
            )
            .overlay(
                Capsule().strokeBorder(MP.C.borderHairline, lineWidth: isSelected ? 0 : 2)
                    .padding(.bottom, MP.E.width)
            )
        }
        .buttonStyle(MPPressStyle(scales: false))
        .disabled(isDisabled)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

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
        case .brand:   return (MP.C.brandSoft, MP.Palette.gul600)
        case .reward:  return (MP.C.rewardSoft, MP.C.premiumInk)
        case .calm:    return (MP.C.calmSoft, MP.Palette.yesim600)
        case .play:    return (MP.C.playSoft, MP.Palette.mercan600)
        case .neutral: return (MP.C.surfaceSunken, MP.C.textMuted)
        case .solid:   return (MP.C.brand, MP.C.textOnBrand)
        }
    }
}

// MARK: - MPSwitch

/// Sistemin kendi anahtarı. iOS'un yerleşik `Toggle` görünümü kullanılmamalı.
struct MPSwitch: View {
    @Binding var isOn: Bool
    var label: String = ""
    var isDisabled: Bool = false

    var body: some View {
        Button {
            withAnimation(MP.M.gated(MP.M.spring)) { isOn.toggle() }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? MP.C.calm : MP.Palette.kagit400)
                    .overlay(alignment: .bottom) {
                        Capsule()
                            .fill(isOn ? MP.C.calmEdge : MP.Palette.kagit500)
                            .frame(height: 3)
                            .padding(.horizontal, 4)
                    }
                    .frame(width: 56, height: 34)
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(MP.Palette.kagit0)
                    .frame(width: 28, height: 25)
                    .mpShadow(MP.Sh.knob)
                    .padding(3)
            }
            .frame(width: 56, height: 34)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? "Açık" : "Kapalı")
    }
}

// MARK: - MPSegmentedControl

struct MPSegmentedControl<T: Hashable>: View {
    let options: [(value: T, label: String)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.value) { opt in
                Button {
                    withAnimation(MP.M.gated(MP.M.easeOut)) { selection = opt.value }
                } label: {
                    Text(opt.label)
                        .font(.custom(MP.F.display, size: 15).weight(.bold))
                        .foregroundStyle(selection == opt.value ? MP.C.textTitle : MP.C.textMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .modifier(ActiveSkin(isActive: selection == opt.value))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == opt.value ? .isSelected : [])
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: MP.R.md, style: .continuous)
                .fill(MP.C.surfaceSunken)
                .overlay(RoundedRectangle(cornerRadius: MP.R.md, style: .continuous).strokeBorder(MP.C.borderHairline, lineWidth: 2))
        )
    }

    private struct ActiveSkin: ViewModifier {
        let isActive: Bool
        @ViewBuilder func body(content: Content) -> some View {
            if isActive {
                content.mpEdge(fill: MP.C.surfaceCard, edge: MP.C.edgeCard, radius: MP.R.sm)
            } else {
                content
            }
        }
    }
}

// MARK: - MPInput

struct MPInput: View {
    var label: String? = nil
    var hint: String? = nil
    var placeholder: String = ""
    @Binding var text: String
    var symbol: String? = nil
    var error: String? = nil
    var maxLength: Int? = nil
    var keyboard: UIKeyboardType = .default

    @FocusState private var focused: Bool

    private var borderColor: Color {
        if error != nil { return MP.C.danger }
        return focused ? MP.C.brand : MP.C.borderHairline
    }
    private var edgeColor: Color {
        if error != nil { return MP.C.danger }
        return focused ? MP.C.brandEdge : MP.C.borderStrong
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let label {
                Text(label).font(MP.F.labelMD()).foregroundStyle(MP.C.textTitle)
            }
            HStack(spacing: 10) {
                if let symbol {
                    MPIcon(symbol, size: 20, weight: .semibold).foregroundStyle(MP.C.textFaint)
                }
                TextField(placeholder, text: $text)
                    .font(MP.F.bodyMD(.semibold))
                    .foregroundStyle(MP.C.textTitle)
                    .keyboardType(keyboard)
                    .focused($focused)
                    .onChange(of: text) { _, new in
                        if let maxLength, new.count > maxLength { text = String(new.prefix(maxLength)) }
                    }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 54)
            .mpEdge(fill: MP.C.surfaceCard, edge: edgeColor, radius: MP.R.input)
            .overlay(
                RoundedRectangle(cornerRadius: MP.R.input, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 2)
                    .padding(.bottom, MP.E.width)
            )
            .animation(MP.M.gated(MP.M.easeOut), value: focused)

            if let text = error ?? hint {
                Text(text)
                    .font(MP.F.caption(.regular))
                    .lineSpacing(12 * 0.35)
                    .foregroundStyle(error != nil ? MP.C.danger : MP.C.textMuted)
            }
        }
    }
}
