// MPNavigationChrome.swift
// Kid tab bar (Ana sayfa · + Yarat · Kitaplık), parent tab bar (Özet · Onaylar · Güvenlik · Ayarlar),
// kid header (avatar → Benim köşem, yıldız sayacı, kilit → Ebeveyn kapısı), top bar, parent header.
// Screens: AnaSayfa, Kutuphane, BosKitaplik, InternetYok (kid tab bar); EbeveynPaneli, OnayBekleyenler,
// IcerikGuvenligi, Ayarlar (parent tab bar).

import SwiftUI

enum KidTab: Hashable { case home, library }

/// Custom bar: the system TabView bar cannot host the raised 64 pt "Yarat" button.
/// Hide the system bar (`.toolbar(.hidden, for: .tabBar)`) and overlay this at the bottom of the kid root.
struct KidTabBar: View {
    @Binding var selection: KidTab
    let onCreate: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            tab(.home, "Ana sayfa", "house")
            Button(action: onCreate) {
                VStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: MPSize.createFab, height: MPSize.createFab)
                        .background(LinearGradient.mpPrimary, in: Circle())
                        .overlay(Circle().strokeBorder(MPColor.backgroundKid, lineWidth: 4))
                        .mpShadow(.primaryGlow)
                        .offset(y: -26)
                        .padding(.bottom, -26)
                    Text("Yarat").mpText(.caption).fontWeight(.black).foregroundStyle(MPColor.textPrimary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(MPPressStyle())
            .accessibilityLabel("Masal yarat")
            tab(.library, "Kitaplık", "books.vertical")
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .frame(height: MPSize.kidTabBarHeight - 20, alignment: .top)
        .background(alignment: .top) {
            Color.white.opacity(0.97).ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) { Rectangle().fill(MPColor.borderKidDivider).frame(height: 1) }
        }
    }

    private func tab(_ t: KidTab, _ label: String, _ icon: String) -> some View {
        let on = selection == t
        return Button { selection = t } label: {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 22, weight: on ? .bold : .regular))
                Text(label).font(.custom("Nunito", size: 12, relativeTo: .caption).weight(on ? .black : .bold))
            }
            .foregroundStyle(on ? MPColor.actionPrimary : MPColor.textTertiary)
            .frame(maxWidth: .infinity, minHeight: MPSize.minTouchParent)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

enum ParentTab: Hashable, CaseIterable {
    case summary, approvals, safety, settings
    var title: String { switch self { case .summary: "Özet"; case .approvals: "Onaylar"; case .safety: "Güvenlik"; case .settings: "Ayarlar" } }
    var icon: String { switch self { case .summary: "square.grid.2x2"; case .approvals: "tray"; case .safety: "checkmark.shield"; case .settings: "gearshape" } }
}

/// Parent area uses the system TabView with these items, tint = actionPrimary, background white.
/// `pendingApprovals` drives the red badge on Onaylar.
struct ParentTabs<Summary: View, Approvals: View, Safety: View, Settings: View>: View {
    @Binding var selection: ParentTab
    var pendingApprovals: Int
    @ViewBuilder var summary: Summary
    @ViewBuilder var approvals: Approvals
    @ViewBuilder var safety: Safety
    @ViewBuilder var settings: Settings

    var body: some View {
        TabView(selection: $selection) {
            summary.tabItem { Label(ParentTab.summary.title, systemImage: ParentTab.summary.icon) }.tag(ParentTab.summary)
            approvals.tabItem { Label(ParentTab.approvals.title, systemImage: ParentTab.approvals.icon) }.tag(ParentTab.approvals)
                .badge(pendingApprovals)
            safety.tabItem { Label(ParentTab.safety.title, systemImage: ParentTab.safety.icon) }.tag(ParentTab.safety)
            settings.tabItem { Label(ParentTab.settings.title, systemImage: ParentTab.settings.icon) }.tag(ParentTab.settings)
        }
        .tint(MPColor.actionPrimary)
    }
}

/// Kid header used on Ana sayfa and İnternet yok.
struct KidHeader: View {
    let greeting: String          // "İyi akşamlar,"
    let childName: String         // "İrem"
    let avatar: HeroAvatar
    let stars: Int
    let onAvatar: () -> Void      // → Benim köşem
    let onStars: () -> Void       // → Benim köşem (stars explained there)
    let onLock: () -> Void        // → Ebeveyn kapısı

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onAvatar) {
                HStack(spacing: 12) {
                    HeroAvatarView(avatar: avatar, size: MPSize.headerAvatar)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                        .mpShadow(.control)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(greeting).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                        Text(childName).font(.custom("Nunito", size: 20, relativeTo: .title3).weight(.black)).foregroundStyle(MPColor.textPrimary)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Benim köşem, \(childName)")
            Spacer()
            Button(action: onStars) {
                HStack(spacing: 6) {
                    Image(systemName: "star").font(.system(size: 18, weight: .bold)).foregroundStyle(MPColor.statusStarIcon)
                    Text("\(stars)").font(.custom("Nunito", size: 16, relativeTo: .body).weight(.black)).monospacedDigit()
                }
                .foregroundStyle(MPColor.textPrimary)
                .padding(.leading, 10).padding(.trailing, 14)
                .frame(height: 40)
                .background(MPColor.backgroundSurface, in: Capsule())
                .mpShadow(.control)
            }
            .buttonStyle(MPPressStyle())
            .accessibilityLabel("\(stars) yıldızın var")
            MPCircleButton(systemImage: "lock", accessibilityLabel: "Ebeveyn bölümü", size: 40, action: onLock)
        }
    }
}

/// Rainbow band behind the kid header (Ana sayfa, Benim köşem, Paywall): 150–300 pt tall, bottom corners curved.
struct HeaderWash: View {
    var height: CGFloat = 170
    var colors: [Color] = [Color(red: 0xFB / 255, green: 0xD3 / 255, blue: 0xE0 / 255), Color(red: 0xFC / 255, green: 0xE8 / 255, blue: 0xB6 / 255),
                           Color(red: 0xD7 / 255, green: 0xEF / 255, blue: 0xD0 / 255), Color(red: 0xCF / 255, green: 0xE5 / 255, blue: 0xFA / 255)]
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
            if let onBack { MPCircleButton(systemImage: "chevron.left", accessibilityLabel: "Geri", action: onBack) } else { Color.clear.frame(width: MPSize.circleButton) }
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
                        .padding(.horizontal, 12).frame(height: 36)
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
