// MPControls.swift
// Chips, segmented control, switch style, text field, checkbox.
// Screens: Yarat 2 (ton chips), Okuma ayarları (segment), İçerik güvenliği (segment, chips, switch),
// Profil oluşturma (text field, yaş chips), Ebeveyn onayı (checkbox).

import SwiftUI

/// Selectable pill. Selected: purple fill, white text. Unselected: white, kid border.
struct MPChip: View {
    let title: String
    var systemImage: String? = nil
    var isSelected: Bool = false
    var style: Style = .solid
    let action: () -> Void

    enum Style { case solid, dashed }

    var body: some View {
        Button(action: action) {
            HStack(spacing: MPSpacing.xxs) {
                if let systemImage { MPIcon(systemImage, size: 14, weight: .bold).accessibilityHidden(true) }
                Text(title).mpText(.callout)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(isSelected ? MPColor.textOnAction : (style == .dashed ? MPColor.textSecondary : MPColor.textPrimary))
            .padding(.horizontal, MPSpacing.lg)
            .padding(.vertical, MPSpacing.xs)
            // En büyük yazı boyutunda çip uzar, metin kesilmez.
            .frame(minHeight: MPSize.chipHeight)
            .background(isSelected ? MPColor.actionPrimary : (style == .dashed ? Color.clear : MPColor.backgroundSurface),
                        in: RoundedRectangle(cornerRadius: MPSize.chipHeight / 2, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MPSize.chipHeight / 2, style: .continuous).strokeBorder(isSelected ? MPColor.actionPrimary : (style == .dashed ? MPColor.borderDashed : MPColor.borderKid),
                                       style: StrokeStyle(lineWidth: 1.5, dash: style == .dashed ? [5, 4] : []))
            }
        }
        .buttonStyle(MPPressStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// Sarmalanan satır: mevcut `MPFlowLayout` (Screens/MPWrapRow.swift) kullanılır.

/// Pill segmented control. Kid area track = border kid tone, parent area track = #E7E9EE.
struct MPSegmented<Value: Hashable>: View {
    let options: [(Value, String)]
    @Binding var selection: Value
    var track: Color = MPColor.segmentTrack
    /// Gece yüzeyi (Uyku modu): seçili dolgu ve yazı renkleri değişir.
    var selectedFill: Color = MPColor.actionPrimary
    var selectedText: Color = MPColor.textOnAction
    var text: Color = MPColor.textPrimary
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // En büyük yazı boyutlarında seçenekler alt alta: kelime bölünmez.
        (typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: MPSpacing.xxs))
                                      : AnyLayout(HStackLayout(spacing: MPSpacing.xxs))) {
            ForEach(options, id: \.0) { value, label in
                let on = value == selection
                Button { withAnimation(MPMotion.spring) { selection = value } } label: {
                    Text(label).mpText(.callout)
                        .foregroundStyle(on ? selectedText : text)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, MPSpacing.xs)
                        .padding(.vertical, MPSpacing.xxs)
                        .frame(maxWidth: .infinity, minHeight: MPSize.segmentHeight)
                        .background(on ? selectedFill : .clear,
                                    in: RoundedRectangle(cornerRadius: MPSize.segmentHeight / 2, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(MPSpacing.xxs)
        .background(track, in: RoundedRectangle(cornerRadius: (MPSize.segmentHeight + MPSpacing.sm) / 2, style: .continuous))
    }
}

/// Toggle tint = action purple; off track = actionDisabled.
struct MPSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { withAnimation(MPMotion.spring) { configuration.isOn.toggle() } } label: {
            HStack {
                configuration.label
                Spacer(minLength: 12)
                Capsule()
                    .fill(configuration.isOn ? MPColor.actionPrimary : MPColor.actionDisabled)
                    .frame(width: 52, height: 30)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle().fill(MPColor.backgroundSurface).frame(width: 24, height: 24).mpShadow(.control).padding(MPSpacing.xxs)
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? "Açık" : "Kapalı")
    }
}

/// 52 pt rounded field. Kid: sunken cream border; parent: #E2E5EA border.
struct MPTextField: View {
    let label: String?
    let placeholder: String
    @Binding var text: String
    var helper: String? = nil
    var isError: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label { Text(label).mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary) }
            TextField(placeholder, text: $text)
                .font(MPTextStyle.button.font).fontWeight(.bold)
                .padding(.horizontal, MPSpacing.lg)
                .frame(height: MPSize.inputHeight)
                .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.input))
                .overlay(RoundedRectangle(cornerRadius: MPRadius.input).strokeBorder(isError ? MPColor.statusDanger : MPColor.borderKid, lineWidth: 1.5))
            if let helper { Text(helper).mpText(.caption).foregroundStyle(isError ? MPColor.statusDanger : MPColor.textSecondary) }
        }
    }
}

/// Square check (26 pt, radius 8). Used for consent and book story picker.
struct MPCheckbox: View {
    @Binding var isOn: Bool
    let label: String
    var body: some View {
        Button { isOn.toggle() } label: {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isOn ? MPColor.actionPrimary : MPColor.backgroundSurface)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(isOn ? MPColor.actionPrimary : MPColor.borderDashed, lineWidth: 2.5))
                    .overlay { if isOn { MPIcon("checkmark", size: 14, weight: .heavy).foregroundStyle(.white) } }
                    .frame(width: 26, height: 26)
                Text(label).mpText(.footnote).foregroundStyle(MPColor.textPrimary).multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}
