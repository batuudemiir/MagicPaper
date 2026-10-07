// MPCards.swift
// Surfaces and lists: card, grouped list rows (Ayarlar, Masal aksiyonları, Benim köşem),
// section header, icon tile, stat tile, badge card, pill badge.

import SwiftUI

enum MPArea { case kid, parent }

/// Kid card: white, radius 24, soft shadow. Parent card (`area: .parent`): white, radius 20, 1 pt #E7E9EE border, no shadow.
struct MPCard<Content: View>: View {
    var area: MPArea = .kid
    var padding: CGFloat = 16
    var background: Color = MPColor.backgroundSurface
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: area == .kid ? MPRadius.card : 20))
            .overlay {
                if area == .parent { RoundedRectangle(cornerRadius: 20).strokeBorder(MPColor.borderParent, lineWidth: 1) }
            }
            .modifier(KidShadow(on: area == .kid))
    }
}

private struct KidShadow: ViewModifier {
    let on: Bool
    func body(content: Content) -> some View { if on { content.mpShadow(.card) } else { content } }
}

/// 40–52 pt rounded square with a tinted SF Symbol. `filled` uses the pastel instead of white.
struct MPIconTile: View {
    let systemImage: String
    var tone: MPWorldTone = .lav
    var size: CGFloat = 40
    var filled: Bool = true
    var body: some View {
        MPIcon(systemImage, size: size * 0.5, weight: .semibold)
            .foregroundStyle(tone.deep)
            .frame(width: size, height: size)
            .background(filled ? tone.soft : MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: size * 0.35))
    }
}

/// List row: icon tile, title, optional subtitle, trailing accessory (chevron, switch, lock, text).
struct MPListRow<Trailing: View>: View {
    let systemImage: String
    var tone: MPWorldTone = .lav
    let title: String
    var subtitle: String? = nil
    var isDestructive: Bool = false
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 14) {
            MPIcon(systemImage, size: 18, weight: .semibold)
                .foregroundStyle(isDestructive ? MPColor.statusDanger : tone.deep)
                .frame(width: 40, height: 40)
                .background(isDestructive ? MPColor.statusDangerSoft : tone.soft, in: RoundedRectangle(cornerRadius: MPRadius.md))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).mpText(.bodyStrong).foregroundStyle(isDestructive ? MPColor.statusDanger : MPColor.textPrimary)
                if let subtitle { Text(subtitle).mpText(.footnote).foregroundStyle(MPColor.textSecondary) }
            }
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

extension MPListRow where Trailing == MPChevron {
    init(systemImage: String, tone: MPWorldTone = .lav, title: String, subtitle: String? = nil, isDestructive: Bool = false) {
        self.init(systemImage: systemImage, tone: tone, title: title, subtitle: subtitle, isDestructive: isDestructive) { MPChevron() }
    }
}

struct MPChevron: View {
    var body: some View { MPIcon("chevron.right", size: 15, weight: .semibold).foregroundStyle(MPColor.textChevron) }
}

/// Grouped rows inside one card (Ayarlar, Masal aksiyonları). Put `MPRowDivider(area:)` between rows.
/// (Kept iOS 17 compatible; on iOS 18 this can insert dividers automatically with `Group(subviews:)`.)
struct MPGroupedList<Content: View>: View {
    var area: MPArea = .kid
    @ViewBuilder let content: Content
    var body: some View {
        MPCard(area: area, padding: 4) { VStack(spacing: 0) { content } }
    }
}

struct MPRowDivider: View {
    var area: MPArea = .kid
    var body: some View {
        Rectangle().fill(area == .kid ? MPColor.borderKidDivider : MPColor.borderParentDivider).frame(height: 1).padding(.horizontal, 14)
    }
}

/// "Son masallar  ·  Tümü" style section header.
struct MPSectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).mpText(.headline).foregroundStyle(MPColor.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action).mpText(.callout).foregroundStyle(MPColor.actionPrimary)
            }
        }
    }
}

/// Small rounded label: "Görselli", "8 sayfa", "Sihirli Krallık".
struct MPPill: View {
    let text: String
    var tone: MPWorldTone = .gray
    var body: some View {
        Text(text).mpText(.caption)
            .foregroundStyle(tone == .yellow ? Color(red: 0x8A / 255, green: 0x64 / 255, blue: 0) : tone.deep)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(tone.soft, in: Capsule())
    }
}

/// Number tile: Benim köşem (yıldız, seri, masal) and Özet (okuma süresi, okunan masal).
struct MPStatTile: View {
    let systemImage: String
    var tone: MPWorldTone = .green
    let value: String
    var unit: String? = nil
    let label: String
    var area: MPArea = .kid
    var body: some View {
        MPCard(area: area, padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                MPIconTile(systemImage: systemImage, tone: tone, size: 34)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value).font(.mp(.largeTitle)).foregroundStyle(MPColor.textPrimary).monospacedDigit()
                    if let unit { Text(unit).mpText(.footnote).foregroundStyle(MPColor.textSecondary) }
                }
                Text(label).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
            }
        }
    }
}

/// Achievement badge (Benim köşem / Rozetlerim). Locked = grey with lock.
struct MPBadgeCard: View {
    let systemImage: String
    let title: String
    var tone: MPWorldTone = .lav
    var isUnlocked: Bool = true
    var body: some View {
        VStack(spacing: 8) {
            MPIcon(systemImage, size: 22, weight: .semibold)
                .foregroundStyle(isUnlocked ? tone.deep : Color(red: 0xA3 / 255, green: 0x9D / 255, blue: 0x94 / 255))
                .frame(width: 50, height: 50)
                .background(isUnlocked ? MPColor.backgroundSurface : Color(red: 0xE4 / 255, green: 0xDE / 255, blue: 0xD4 / 255), in: Circle())
            Text(title).mpText(.caption).multilineTextAlignment(.center)
                .foregroundStyle(isUnlocked ? MPColor.textPrimary : MPColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(isUnlocked ? tone.soft : Color(red: 0xF1 / 255, green: 0xEC / 255, blue: 0xE4 / 255), in: RoundedRectangle(cornerRadius: MPRadius.tile))
        .overlay(alignment: .topTrailing) {
            if !isUnlocked { MPIcon("lock.fill", size: 12).foregroundStyle(MPColor.textSecondary).padding(8) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(isUnlocked ? "Kazanıldı" : "Kilitli")
    }
}

/// Banner for warnings inside the parent area ("2 masal onay bekliyor", "Korku seviyesi ayarının üstünde").
struct MPNotice: View {
    enum Kind { case info, success, warning, danger }
    let kind: Kind
    let text: String
    var systemImage: String? = nil
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let systemImage { MPIcon(systemImage, size: 15, weight: .bold) }
            Text(text).mpText(.footnote)
        }
        .foregroundStyle(fg)
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bg, in: RoundedRectangle(cornerRadius: MPRadius.md))
    }
    private var fg: Color { switch kind { case .info: MPColor.textPrimary; case .success: MPColor.statusSuccess; case .warning: MPColor.textPrimary; case .danger: MPColor.statusDanger } }
    private var bg: Color { switch kind { case .info: MPColor.actionSoft; case .success: MPColor.statusSuccessSoft; case .warning: MPColor.statusWarningSoft; case .danger: MPColor.statusDangerSoft } }
}
