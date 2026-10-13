// MPNavigationChrome.swift
// Kid tab bar (Ana sayfa · Kitaplık · + Yarat · Köşem), parent tab bar (Özet · Güvenlik · Ayarlar),
// kid header (avatar → Benim köşem, kilit → Ebeveyn kapısı), top bar, parent header.
// Screens: AnaSayfa, Kutuphane, BosKitaplik, InternetYok, BenimKosem (kid tab bar); EbeveynPaneli,
// IcerikGuvenligi, Ayarlar (parent tab bar).

import SwiftUI

enum KidTab: Hashable { case home, library, corner }

/// Custom bar: the system TabView bar cannot host the raised 64 pt "Yarat" button.
/// Hide the system bar (`.toolbar(.hidden, for: .tabBar)`) and overlay this at the bottom of the kid root.
struct KidTabBar: View {
    @Binding var selection: KidTab
    let onCreate: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            tab(.home, "Ana sayfa", "house")
            tab(.library, "Kitaplık", "books.vertical")
            Button(action: onCreate) {
                VStack(spacing: 4) {
                    MPIcon("plus", size: 28, weight: .bold)
                        .foregroundStyle(.white)
                        .frame(width: MPSize.createFab, height: MPSize.createFab)
                        .background(LinearGradient.mpPrimary, in: Circle())
                        .overlay(Circle().strokeBorder(MPColor.backgroundKid, lineWidth: 4))
                        .mpShadow(.primaryGlow)
                        .offset(y: -26)
                        .padding(.bottom, -26)
                    Text("Yarat").mpText(.caption).fontWeight(.black).foregroundStyle(MPColor.textPrimary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(MPPressStyle())
            .accessibilityLabel("Masal yarat")
            .accessibilityShowsLargeContentViewer { MPIcon("plus", size: 22, weight: .bold); Text("Yarat") }
            tab(.corner, "Köşem", "person")
        }
        .padding(.horizontal, MPSpacing.xl)
        .padding(.top, MPSpacing.md)
        .frame(height: MPSize.kidTabBarHeight - 20, alignment: .top)
        // Sistem sekme çubuğu gibi: yazı en fazla xLarge büyür, daha büyük
        // boyutta basılı tutunca büyük içerik görüntüleyici gösterir.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .background(alignment: .top) {
            Color.white.opacity(0.97).ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) { Rectangle().fill(MPColor.borderKidDivider).frame(height: 1) }
        }
    }

    private func tab(_ t: KidTab, _ label: String, _ icon: String) -> some View {
        let on = selection == t
        return Button { selection = t } label: {
            VStack(spacing: 3) {
                MPIcon(icon, size: 22, weight: on ? .bold : .regular).frame(height: 26)
                Text(label).mpText(.tabLabel).fontWeight(on ? .black : .bold)
                    .lineLimit(1)
            }
            .foregroundStyle(on ? MPColor.actionPrimary : MPColor.textTertiary)
            .frame(maxWidth: .infinity, minHeight: MPSize.minTouchParent)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
        .accessibilityShowsLargeContentViewer {
            MPIcon(icon, size: 22, weight: .bold)
            Text(label)
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
