import SwiftUI

/// Ebeveyn alanındaki her sayfanın tek üst satırı (Design law, Üst başlıklar).
///
/// - Kök sayfa (29 · Özet, 31 · Güvenlik, 32 · Ayarlar): `MPParentHeader(title:subtitle:)`.
///   Solda büyük başlık ve alt satır, sağda "Çocuk modu". Çocuk moduna dönüş kapısızdır.
/// - Alt sayfa (Masal kitabı, Aile, Kendi sesin…): `MPParentHeader(title:subtitle:onBack:)`.
///   Solda "Geri", yanında küçük başlık. `onBack` nil ise geri düğmesi gizlenir
///   (ör. hesap silinirken), "Çocuk modu" alt sayfada hiç görünmez.
///
/// Yatay ve üst boşluğu sayfa verir (`MPSpacing.screenH`, `MPSpacing.lg`);
/// başlık kendi kenar boşluğunu eklemez. Erişilebilirlik boyutlarında
/// "Çocuk modu" başlığın üstüne çıkar, aynı satırda başlık kesiliyordu (FAZ 10).
struct MPParentHeader: View {
    @EnvironmentObject private var app: MPAppState

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    var subtitle: String? = nil
    private let isRoot: Bool
    private let onBack: (() -> Void)?

    /// Kök sayfa: büyük başlık + "Çocuk modu".
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.isRoot = true
        self.onBack = nil
    }

    /// Alt sayfa: "Geri" + başlık.
    init(title: String, subtitle: String? = nil, onBack: (() -> Void)?) {
        self.title = title
        self.subtitle = subtitle
        self.isRoot = false
        self.onBack = onBack
    }

    var body: some View {
        Group {
            if !isRoot {
                // Büyük yazıda başlık satırlara bölünür; "Geri" ortada asılı kalmasın.
                HStack(alignment: dynamicTypeSize.isAccessibilitySize ? .top : .center, spacing: MPSpacing.md) {
                    if let onBack {
                        MPCircleButton(systemImage: "chevron.left", accessibilityLabel: "Geri", action: onBack)
                    }
                    titleBlock
                }
            } else if dynamicTypeSize.isAccessibilitySize {
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
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: MPSpacing.xxs) {
            Text(title)
                .mpText(isRoot ? .largeTitle : .title3)
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
            Label {
                Text("Çocuk modu")
            } icon: {
                MPIcon("rectangle.portrait.and.arrow.right", size: MP.G.sm, weight: .semibold)
            }
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
            MPSectionHeader(title: title, subtitle: subtitle, area: .parent)
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
