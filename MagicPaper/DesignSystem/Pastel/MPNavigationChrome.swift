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
/// Özel çubuk, sistem `TabView` değil: "Yarat" bir yer değil eylem, sistem
/// çubuğunda seçilebilir bir sekme gibi davranırdı. Yarat çubuğun içinde,
/// sekmelerle aynı satırda durur; sekmeden ayrımı yükseklikle değil marka
/// rengindeki dolu haptan gelir ve hiçbir zaman "seçili" görünmez.
/// Cam üstüne cam konmaz: Yarat'ın hapı düz renk.
/// `ContentView.kidRoot` bunu `mpFloatingBar` ile yerleştirir; ekranların
/// içeriği kapsülün altından ve çevresinden kayar.
struct KidTabBar: View {
    @Binding var selection: KidTab
    let onCreate: () -> Void

    @Namespace private var indicator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Yazı yalnızca seçili sekmede ve Yarat'ta görünür; diğerleri yalnızca
    /// ikon. Çubuk sakinleşir, "neredeyim" sorusunun cevabı yine yazılı kalır.
    /// Geliştirici ayarındaki anahtar eski biçimi (her sekmede yazı) açar,
    /// iki biçim telefonda karşılaştırılabilsin diye.
    @AppStorage(KidTabBar.allLabelsKey) private var showsAllLabels = false
    static let allLabelsKey = "mp_debug_kidTabAllLabels"

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            tab(.home, "Ana sayfa", "house")
            tab(.gunluk, "Günlük", "sun.max")
            createButton
            tab(.library, "Kitaplık", "books.vertical")
            tab(.corner, "Köşem", "face.smiling")
        }
        .padding(.horizontal, MP.S.x1)
        .padding(.vertical, MP.S.x1)
        // Sistem sekme çubuğu gibi: yazı en fazla xLarge büyür, daha büyük
        // boyutta basılı tutunca büyük içerik görüntüleyici gösterir.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .mpGlassSurface(in: Capsule(style: .continuous))
        .padding(.horizontal, MP.S.x3)
        .padding(.bottom, MP.S.x2)
    }

    /// Yarat: aynı satırda, marka renginde dolu hap. Sekme değil, eylem.
    private var createButton: some View {
        Button(action: onCreate) {
            VStack(spacing: 3) {
                MPIcon("plus", size: MP.G.md, weight: .bold)
                    .foregroundStyle(MP.C.textOnBrand)
                    .frame(width: MP.S.x9, height: MP.S.x7)
                    .background(MP.C.brand, in: Capsule(style: .continuous))
                Text("Yarat").mpText(.tabLabel).fontWeight(.black)
                    .foregroundStyle(MP.C.brand)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: MPSize.minTouchKid)
            .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel("Masal yarat")
        .accessibilityShowsLargeContentViewer { MPIcon("plus", size: MP.G.lg, weight: .bold); Text("Yarat") }
    }

    private func tab(_ t: KidTab, _ label: String, _ icon: String) -> some View {
        let on = selection == t
        return Button { selection = t } label: {
            VStack(spacing: 3) {
                // Seçilen sekmenin ikonu yaylanarak büyür; seçim renkle birlikte
                // kalınlık, ölçek ve arkasındaki hapla da görünür.
                MPIcon(icon, size: MP.G.lg, weight: on ? .bold : .regular)
                    .frame(width: MP.S.x9, height: MP.S.x7)
                    .scaleEffect(on ? 1.12 : 1)
                    .background { activeIndicator(on) }
                if on || showsAllLabels {
                    Text(label).mpText(.tabLabel).fontWeight(on ? .black : .bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        // Yazı ikonun altından açılır; Hareketi Azalt'ta
                        // yalnızca belirir.
                        .transition(reduceMotion ? .opacity
                                    : .opacity.combined(with: .scale(scale: 0.8, anchor: .top)))
                }
            }
            // Pasif sekme `textSecondary`: cam beyaza yakınken `textTertiary`
            // 2.5:1'de kalıyordu, bu 5:1.
            .foregroundStyle(on ? MPColor.actionPrimary : MPColor.textSecondary)
            .frame(maxWidth: .infinity, minHeight: MPSize.minTouchKid)
            .contentShape(Rectangle())
            .animation(MP.M.gated(MP.M.spring), value: on)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(label)
        .accessibilityAddTraits(on ? .isSelected : [])
        .accessibilityShowsLargeContentViewer {
            MPIcon(icon, size: MP.G.lg, weight: .bold)
            Text(label)
        }
    }

    /// Seçili sekmenin simgesinin arkasındaki yumuşak hap. Tek hap sekmeler
    /// arasında kayar; Hareketi Azalt açıkken her sekme kendi hapını çapraz
    /// geçişle gösterir.
    @ViewBuilder
    private func activeIndicator(_ isActive: Bool) -> some View {
        if isActive {
            let pill = Capsule(style: .continuous).fill(MP.C.brandSoft)
            if reduceMotion {
                pill.transition(.opacity)
            } else {
                pill.matchedGeometryEffect(id: "kid-tab-indicator", in: indicator)
            }
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
