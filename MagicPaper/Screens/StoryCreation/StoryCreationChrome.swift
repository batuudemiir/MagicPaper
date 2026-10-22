import SwiftUI

/// Masal yazma adımlarının ortak parçaları (22 Ekim 2026).
///
/// Adımlar iOS ayar ve kurulum ekranları gibi dizilir: solda büyük başlık,
/// altında tek cümle; seçenekler ızgara kart yerine tam genişlikte satır,
/// sağda yuvarlak seçim işareti. Seçilen satırın ikinci sorusu (konu) aynı
/// kartın içinde açılır. Altta tek birincil düğme.

/// Adımın başlığı: sola yaslı, altında tek cümle.
struct CreationTitle: View {
    let title: String
    var subtitle: String? = nil
    var note: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.xs) {
            Text(title)
                .mpText(.title1).foregroundStyle(MPColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle).mpText(.body).foregroundStyle(MPColor.textSecondary)
            }
            if let note {
                Text(note).mpText(.footnote).foregroundStyle(MPColor.actionPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Seçenek satırı: solda görsel, ad ve tek satırlık söz, sağda seçim işareti.
/// Beyaz sayfada açık gri yüzey (ana sayfa bölümleri gibi). Seçiliyken kenarı
/// marka renginde ve işaret dolu (seçim yalnızca renkle
/// belli değil). `detail` yalnızca seçiliyken, aynı kartın içinde görünür.
struct CreationChoiceRow<Leading: View, Detail: View>: View {
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    var accessibilityLabel: String? = nil
    let action: () -> Void
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var detail: () -> Detail

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: action) {
                HStack(spacing: MPSpacing.md) {
                    // Süs: en büyük yazı boyutlarında metne yer açar.
                    if !typeSize.isAccessibilitySize {
                        leading().accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                        Text(title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                        if let subtitle {
                            Text(subtitle).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                        }
                    }
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: MPSpacing.sm)
                    CreationCheckmark(isOn: isSelected)
                }
                .frame(maxWidth: .infinity, minHeight: MPSize.minTouchKid, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(MPPressStyle())
            .accessibilityLabel(accessibilityLabel ?? title)
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            if isSelected {
                detail()
                    .padding(.top, MPSpacing.md)
                    .transition(.opacity)
            }
        }
        .padding(MPSpacing.md)
        // Ana sayfanın bölümleri gibi: beyaz zeminde açık gri, gölgesiz.
        .background(MPColor.backgroundSunken,
                    in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous)
                .strokeBorder(isSelected ? MPColor.actionPrimary : .clear, lineWidth: 2)
        }
    }
}

extension CreationChoiceRow where Detail == EmptyView {
    init(title: String, subtitle: String? = nil, isSelected: Bool, accessibilityLabel: String? = nil,
         action: @escaping () -> Void, @ViewBuilder leading: @escaping () -> Leading) {
        self.init(title: title, subtitle: subtitle, isSelected: isSelected,
                  accessibilityLabel: accessibilityLabel, action: action,
                  leading: leading, detail: { EmptyView() })
    }
}

/// Sağdaki yuvarlak seçim işareti (iOS listelerindeki gibi).
struct CreationCheckmark: View {
    let isOn: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(isOn ? MPColor.actionPrimary : MPColor.borderKid, lineWidth: 2)
                .background(Circle().fill(isOn ? MPColor.actionPrimary : .clear))
            if isOn {
                MPIcon("checkmark", size: MP.G.xs, weight: .bold)
                    .foregroundStyle(MPColor.textOnAction)
            }
        }
        .frame(width: MPSpacing.xl, height: MPSpacing.xl)
        .animation(MP.M.gated(MP.M.easeOut), value: isOn)
        .accessibilityHidden(true)
    }
}

/// Adımın altındaki tek birincil düğme.
struct CreationFooter<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.sm)
            .padding(.bottom, MPSpacing.md)
            .background(MPColor.backgroundSurface)
    }
}
