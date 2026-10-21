// MPNavigationChrome.swift
// Kid tab bar (Ana sayfa · Günlük · Kitaplık · Köşem + ayrı Masal yaz dairesi), parent tab bar (Özet · Güvenlik · Ayarlar),
// kid header (avatar → Benim köşem, kilit → Ebeveyn kapısı), top bar, parent header.
// Screens: AnaSayfa, Kutuphane, BosKitaplik, InternetYok, BenimKosem (kid tab bar); EbeveynPaneli,
// IcerikGuvenligi, Ayarlar (parent tab bar).

import SwiftUI

enum KidTab: Hashable { case home, gunluk, library, corner }

/// Çocuk modunun alt çubuğu, iOS 26 sekme çubuğunun ölçüsünde (21 Ekim 2026):
/// dört sekme içeriğin üstünde yüzen cam bir kapsülde, "Masal yaz" yanında
/// ayrı bir cam dairede (Apple Music'teki arama dairesi gibi). İkisi tek cam
/// grubunda (`MPGlassGroup`); daire marka renginde tonlu ve dokununca esner,
/// masal yazma ekranı dairenin içinden büyüyerek açılır (`mpZoomSource`).
///
/// Özel çubuk, sistem `TabView` değil: Masal yaz bir yer değil eylem, sistem
/// çubuğunda seçilebilir bir sekme gibi davranırdı.
///
/// Sistemdeki gibi tek renk: seçili sekmenin ikonu dolar, ikon ve adı marka
/// renginde olur, arkasında nötr bir mercek belirir. Seçim renkle birlikte
/// dolu şekil ve mercekle de belli. Zıplama, ölçek ya da yaylanma yok.
/// `ContentView.kidRoot` bunu `mpFloatingBar` ile yerleştirir.
struct KidTabBar: View {
    @Binding var selection: KidTab
    let onCreate: () -> Void
    /// Masal yazma ekranının yakınlaşma kaynağı; `nil` ise olağan geçiş.
    var zoom: Namespace.ID? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Kimlik: `ContentView` aynı adla yakınlaşma hedefini işaretler.
    static let createZoomID = "masalYaz"

    /// Çubuğun ve dairenin yüksekliği: sistemin yüzen sekme çubuğu kadar.
    private let barHeight: CGFloat = MP.S.tapMin + MP.S.x2

    private struct Item {
        let tab: KidTab
        let label: String
        let symbol: String
    }

    private let items: [Item] = [
        Item(tab: .home,    label: "Ana sayfa", symbol: "house"),
        Item(tab: .gunluk,  label: "Günlük",    symbol: "sun.max"),
        Item(tab: .library, label: "Kitaplık",  symbol: "books.vertical"),
        Item(tab: .corner,  label: "Köşem",     symbol: "face.smiling"),
    ]

    var body: some View {
        MPGlassGroup(spacing: MP.S.x3) {
            HStack(spacing: MP.S.x3) {
                HStack(spacing: 0) {
                    ForEach(items, id: \.tab) { tab($0) }
                }
                .padding(MP.S.x1)
                .frame(height: barHeight)
                .mpGlassSurface(in: Capsule(style: .continuous))

                createButton
            }
        }
        // Sistem sekme çubuğu gibi: yazı en fazla xLarge büyür, daha büyük
        // boyutta basılı tutunca büyük içerik görüntüleyici adı gösterir.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .padding(.horizontal, MP.S.x5)
    }

    /// Masal yaz: sekmelerin dışında, marka renginde tonlu cam daire. Sekme
    /// değil, eylem; adı VoiceOver'da ve basılı tutunca okunur.
    private var createButton: some View {
        Button(action: onCreate) {
            MPIcon("pencil.and.scribble", size: MP.G.lg, weight: .semibold, symbolOnly: true)
                .foregroundStyle(MP.C.textOnBrand)
                .frame(width: barHeight, height: barHeight)
                .mpGlassAction(in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(MPPressStyle(.highlight))
        .mpZoomSource(Self.createZoomID, in: reduceMotion ? nil : zoom)
        .accessibilityLabel("Masal yaz")
        .accessibilityShowsLargeContentViewer {
            MPIcon("pencil.and.scribble", size: MP.G.lg, weight: .bold, symbolOnly: true)
            Text("Masal yaz")
        }
    }

    private func tab(_ item: Item) -> some View {
        let on = selection == item.tab
        return Button { selection = item.tab } label: {
            VStack(spacing: 0) {
                MPIcon(on ? "\(item.symbol).fill" : item.symbol, size: MP.G.md,
                       weight: on ? .semibold : .regular, symbolOnly: true)
                    // Hareketi Azalt'ta dolgu animasyonsuz değişir.
                    .contentTransition(reduceMotion ? .identity : .opacity)
                    .frame(height: MP.S.x6)
                Text(item.label)
                    .font(MP.F.caption(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(on ? MP.C.brand : MP.C.textTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Capsule(style: .continuous)
                    .fill(MP.C.textTitle.opacity(on ? 0.07 : 0))
            }
            .contentShape(Capsule(style: .continuous))
            .animation(MP.M.gated(MP.M.easeOut), value: on)
        }
        .buttonStyle(MPPressStyle(.highlight))
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
