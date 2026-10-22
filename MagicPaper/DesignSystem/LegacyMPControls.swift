import SwiftUI
import UIKit

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

// MARK: - MPSwitch

/// Sistemin kendi anahtarı. iOS'un yerleşik `Toggle` görünümü kullanılmamalı.
struct MPSwitch: View {
    @Binding var isOn: Bool
    var label: String = ""
    var isDisabled: Bool = false

    var body: some View {
        Button {
            MPHaptics.selection()
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

    @Namespace private var thumb
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.value) { opt in
                let isActive = selection == opt.value
                Button {
                    guard !isActive else { return }
                    MPHaptics.selection()
                    // Seçili zemin bir seçenekten ötekine kayar; Hareketi
                    // Azalt açıkken yerinde belirip söner.
                    withAnimation(reduceMotion ? MP.M.easeOut : MP.M.base) { selection = opt.value }
                } label: {
                    Text(opt.label)
                        .font(.custom(MP.F.display, size: 15).weight(.bold))
                        .foregroundStyle(isActive ? MP.C.textTitle : MP.C.textMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background { activeThumb(isActive) }
                        .contentShape(Rectangle())
                }
                .buttonStyle(MPPressStyle(.highlight))
                .accessibilityAddTraits(isActive ? .isSelected : [])
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: MP.R.md, style: .continuous)
                .fill(MP.C.surfaceSunken)
                .overlay(RoundedRectangle(cornerRadius: MP.R.md, style: .continuous).strokeBorder(MP.C.borderHairline, lineWidth: 2))
        )
    }

    @ViewBuilder
    private func activeThumb(_ isActive: Bool) -> some View {
        if isActive {
            let shape = Color.clear.mpEdge(fill: MP.C.surfaceCard, edge: MP.C.edgeCard, radius: MP.R.sm)
            if reduceMotion {
                shape.transition(.opacity)
            } else {
                shape.matchedGeometryEffect(id: "segment-thumb", in: thumb)
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
