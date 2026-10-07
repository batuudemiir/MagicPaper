import SwiftUI

/// Ebeveyn alanındaki her kök sayfanın üst satırı (29 · Özet, 31 · Güvenlik,
/// 32 · Ayarlar): solda büyük başlık ve alt satır, sağda "Çocuk modu".
///
/// Çocuk moduna dönüş kapısızdır. Erişilebilirlik boyutlarında düğme
/// başlığın üstüne çıkar, aynı satırda başlık kesiliyordu (FAZ 10).
struct MPParentHeader: View {
    @EnvironmentObject private var app: MPAppState

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    var subtitle: String? = nil

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: MPSpacing.sm) {
                    exitButton
                    titleBlock
                }
            } else {
                HStack(alignment: .top, spacing: MPSpacing.md) {
                    titleBlock
                    Spacer(minLength: 0)
                    exitButton
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.top, MPSpacing.lg)
        .padding(.bottom, MPSpacing.xs)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: MPSpacing.xxs) {
            Text(title)
                .mpText(.largeTitle)
                .foregroundStyle(MPColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .mpText(.footnote)
                    .foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var exitButton: some View {
        Button { app.enterChildMode() } label: {
            Label("Çocuk modu", systemImage: "rectangle.portrait.and.arrow.right")
                .mpText(.footnote)
                .fontWeight(.heavy)
                .foregroundStyle(MPColor.textPrimary)
                .padding(.horizontal, MPSpacing.md)
                .frame(minHeight: MPSize.minTouchParent)
                .background(MPColor.backgroundSurface, in: Capsule())
                .overlay(Capsule().strokeBorder(MPColor.borderParentControl, lineWidth: 1.5))
        }
        .buttonStyle(MPPressStyle())
        .accessibilityHint("Çocuğun ana sayfasına döner")
    }
}

/// Ebeveyn alanındaki bir bölüm: başlık + gruplanmış kart.
struct ParentSection<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                Text(title).mpText(.headline).foregroundStyle(MPColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                }
            }
            MPGroupedList(area: .parent) { content }
        }
    }
}

/// Ebeveyn alanında dokunulabilir satır: `MPListRow` + chevron, 44 pt.
struct ParentRowButton: View {
    let systemImage: String
    var tone: MPWorldTone = .lav
    let title: String
    var subtitle: String? = nil
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MPListRow(systemImage: systemImage, tone: tone, title: title,
                      subtitle: subtitle, isDestructive: isDestructive)
                .frame(minHeight: MPSize.minTouchParent)
        }
        .buttonStyle(MPPressStyle(.highlight))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// Ebeveyn alanında anahtarlı satır.
struct ParentToggleRow: View {
    let systemImage: String
    var tone: MPWorldTone = .lav
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        MPListRow(systemImage: systemImage, tone: tone, title: title, subtitle: subtitle) {
            Toggle(isOn: $isOn) { EmptyView() }.toggleStyle(MPSwitchStyle()).fixedSize()
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(isOn ? "Açık" : "Kapalı")
        .accessibilityAction { isOn.toggle() }
    }
}
