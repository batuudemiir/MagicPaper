// MPNavigationChrome.swift
// Kid tab bar (Ana sayfa · Günlük · + Yarat · Kitaplık · Köşem), parent tab bar (Özet · Güvenlik · Ayarlar),
// kid header (avatar → Benim köşem, kilit → Ebeveyn kapısı), top bar, parent header.
// Screens: AnaSayfa, Kutuphane, BosKitaplik, InternetYok, BenimKosem (kid tab bar); EbeveynPaneli,
// IcerikGuvenligi, Ayarlar (parent tab bar).

import SwiftUI

enum KidTab: Hashable { case home, gunluk, library, corner }

/// Çocuk modunun alt çubuğu: içeriğin üstünde yüzen cam bir kapsül
/// (iOS 26+ Liquid Glass, öncesinde sistem materyali; `mpGlassSurface`).
///
/// Özel çubuk, sistem `TabView` değil: Yarat bir yer değil eylem, sistem
/// çubuğunda seçilebilir bir sekme gibi davranırdı.
///
/// Çubukta yazı yok, yalnızca ikon. Her sekmenin kendi rengi var: seçilince
/// ikonun içi o renkle dolar ve bir kez zıplar; diğer sekmeler çizgi ikon.
/// Seçim renkle birlikte dolu/boş şekil farkıyla da belli. Ek görsel yok,
/// hepsi SF Symbol. Sekmelerin adı VoiceOver'da ve basılı tutunca okunur.
/// Yarat marka renginde dolu hapın içinde artı. Cam üstüne cam konmaz, hap
/// düz renk.
/// `ContentView.kidRoot` bunu `mpFloatingBar` ile yerleştirir.
struct KidTabBar: View {
    @Binding var selection: KidTab
    let onCreate: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Sekmenin adı (VoiceOver ve büyük içerik görüntüleyici), ikonu ve
    /// seçiliyken ikonun içini dolduran renk.
    private struct Item {
        let tab: KidTab
        let label: String
        let symbol: String
        let tint: Color
    }

    private let items: [Item] = [
        Item(tab: .home,    label: "Ana sayfa", symbol: "house",          tint: MP.C.brand),
        Item(tab: .gunluk,  label: "Günlük",    symbol: "sun.max",        tint: MP.C.reward),
        Item(tab: .library, label: "Kitaplık",  symbol: "books.vertical", tint: MP.C.play),
        Item(tab: .corner,  label: "Köşem",     symbol: "face.smiling",   tint: MP.C.calm),
    ]

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            tab(items[0])
            tab(items[1])
            createButton
            tab(items[2])
            tab(items[3])
        }
        .padding(.horizontal, MP.S.x1)
        .padding(.vertical, MP.S.x1)
        // Sistem sekme çubuğu gibi: ikonlar en fazla xLarge büyür, daha
        // büyük boyutta basılı tutunca büyük içerik görüntüleyici adı gösterir.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .mpGlassSurface(in: Capsule(style: .continuous))
        .padding(.horizontal, MP.S.x3)
    }

    /// Yarat: yazısız, marka renginde dolu hapın içinde artı. Sekme değil,
    /// eylem; adı VoiceOver'da ve basılı tutunca okunur.
    private var createButton: some View {
        Button(action: onCreate) {
            MPIcon("plus", size: MP.G.lg, weight: .bold, symbolOnly: true)
                .foregroundStyle(MP.C.textOnBrand)
                .frame(width: MP.S.x10, height: MP.S.x8)
                .background(MP.C.brand, in: Capsule(style: .continuous))
                .frame(maxWidth: .infinity, minHeight: MPSize.minTouchKid)
                .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel("Masal yarat")
        .accessibilityShowsLargeContentViewer {
            MPIcon("plus", size: MP.G.lg, weight: .bold, symbolOnly: true)
            Text("Masal yarat")
        }
    }

    private func tab(_ item: Item) -> some View {
        let on = selection == item.tab
        return Button { selection = item.tab } label: {
            MPIcon(on ? "\(item.symbol).fill" : item.symbol, size: MP.G.xl,
                   weight: on ? .semibold : .regular, symbolOnly: true)
                .foregroundStyle(on ? item.tint : MP.C.textMuted)
                // Çizgiden dolguya geçiş sembolün kendi animasyonuyla;
                // seçilince bir kez zıplar. Hareketi Azalt'ta yalnızca
                // dolgu değişir.
                .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                .symbolEffect(.bounce, value: reduceMotion ? false : on)
                .frame(maxWidth: .infinity, minHeight: MPSize.minTouchKid)
                .contentShape(Rectangle())
                .animation(MP.M.gated(MP.M.spring), value: on)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(item.label)
        .accessibilityAddTraits(on ? .isSelected : [])
        .accessibilityShowsLargeContentViewer {
            MPIcon("\(item.symbol).fill", size: MP.G.lg, weight: .bold, symbolOnly: true)
            Text(item.label)
        }
    }
}

enum ParentTab: Hashable, CaseIterable {
    // Onaylar sekmesi yok (karar 7 Ekim 2026: serbest metin ve onay kuyruğu kapalı).
    case summary, safety, settings
    var title: String { switch self { case .summary: "Özet"; case .safety: "Güvenlik"; case .settings: "Ayarlar" } }
    var icon: String { switch self { case .summary: "square.grid.2x2"; case .safety: "checkmark.shield"; case .settings: "gearshape" } }
}

/// Parent area uses the system TabView with these items, tint = actionPrimary, background white.
struct ParentTabs<Summary: View, Safety: View, Settings: View>: View {
    @Binding var selection: ParentTab
    @ViewBuilder var summary: Summary
    @ViewBuilder var safety: Safety
    @ViewBuilder var settings: Settings

    var body: some View {
        TabView(selection: $selection) {
            summary.tabItem { Label(ParentTab.summary.title, systemImage: ParentTab.summary.icon) }.tag(ParentTab.summary)
            safety.tabItem { Label(ParentTab.safety.title, systemImage: ParentTab.safety.icon) }.tag(ParentTab.safety)
            settings.tabItem { Label(ParentTab.settings.title, systemImage: ParentTab.settings.icon) }.tag(ParentTab.settings)
        }
        .tint(MPColor.actionPrimary)
    }
}

/// Kid header used on Ana sayfa and İnternet yok. Yıldız sayacı yok (karar 7 Ekim 2026).
struct KidHeader<Avatar: View>: View {
    let greeting: String          // "İyi akşamlar,"
    let childName: String         // "İrem"
    @ViewBuilder var avatar: Avatar   // çocuğun avatarı, MPSize.headerAvatar boyutunda
    let onAvatar: () -> Void      // → Benim köşem
    let onLock: () -> Void        // → Ebeveyn kapısı

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onAvatar) {
                HStack(spacing: 12) {
                    avatar
                        .dynamicTypeSize(...DynamicTypeSize.large)
                        .frame(width: MPSize.headerAvatar, height: MPSize.headerAvatar)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                        .mpShadow(.control)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(greeting).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                        Text(childName).mpText(.navTitle).fontWeight(.black).foregroundStyle(MPColor.textPrimary)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Benim köşem, \(childName)")
            Spacer()
            MPCircleButton(systemImage: "lock", accessibilityLabel: "Ebeveyn bölümü", size: 40, action: onLock)
        }
    }
}

/// Rainbow band behind the kid header (Ana sayfa, Benim köşem, Paywall): 150–300 pt tall, bottom corners curved.
struct HeaderWash: View {
    var height: CGFloat = 170
    var colors: [Color] = [MPColor.washPink, MPColor.washYellow,
                           MPColor.washGreen, MPColor.washSky]
    var body: some View {
        LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
            .frame(height: height)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 34, bottomTrailingRadius: 34))
            .ignoresSafeArea(edges: .top)
    }
}

/// Centered title with optional back / trailing buttons and subtitle ("Çocuk profili · 1 / 2").
struct MPTopBar<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var onBack: (() -> Void)? = nil
    @ViewBuilder var trailing: Trailing
    var body: some View {
        HStack(spacing: 10) {
            if let onBack { MPCircleButton(systemImage: "chevron.left", accessibilityLabel: "Geri", action: onBack) } else { Color.clear.frame(width: MPSize.circleButton, height: MPSize.circleButton) }
            VStack(spacing: 0) {
                Text(title).mpText(.navTitle).foregroundStyle(MPColor.textPrimary)
                if let subtitle { Text(subtitle).mpText(.footnote).foregroundStyle(MPColor.textSecondary) }
            }
            .frame(maxWidth: .infinity)
            trailing.frame(minWidth: MPSize.circleButton)
        }
        .frame(minHeight: 46)
    }
}

extension MPTopBar where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, onBack: (() -> Void)? = nil) {
        self.init(title: title, subtitle: subtitle, onBack: onBack) { EmptyView() }
    }
}

/// Parent page header: big left title + subtitle; root pages show "Çocuk modu" exit, sub pages show back only.
struct ParentHeader: View {
    let title: String
    var subtitle: String? = nil
    var onBack: (() -> Void)? = nil
    var onExitToKid: (() -> Void)? = nil
    var body: some View {
        HStack(spacing: 10) {
            if let onBack { MPCircleButton(systemImage: "chevron.left", accessibilityLabel: "Geri", action: onBack) }
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.mp(onBack == nil ? .largeTitle : .title3)).foregroundStyle(MPColor.textPrimary)
                if let subtitle { Text(subtitle).mpText(.footnote).foregroundStyle(MPColor.textSecondary) }
            }
            Spacer()
            if onBack == nil, let onExitToKid {
                Button(action: onExitToKid) {
                    Label("Çocuk modu", systemImage: "rectangle.portrait.and.arrow.right")
                        .mpText(.footnote).fontWeight(.heavy)
                        .foregroundStyle(MPColor.textPrimary)
                        .padding(.horizontal, MPSpacing.md).frame(height: 36)
                        .background(MPColor.backgroundSurface, in: Capsule())
                        .overlay(Capsule().strokeBorder(MPColor.borderParentControl, lineWidth: 1.5))
                }
                .buttonStyle(MPPressStyle())
            }
        }
    }
}

/// Bottom sheet chrome (Masal aksiyonları, Okuma ayarları): present with
/// `.sheet { ... .presentationDetents([.medium, .large]).presentationCornerRadius(MPRadius.sheet).presentationBackground(MPColor.backgroundKid) }`.
/// The grabber is the system one (`.presentationDragIndicator(.visible)`); title = `.mpText(.headline)`.
