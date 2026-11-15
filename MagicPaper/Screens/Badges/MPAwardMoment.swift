import SwiftUI

/// Tam ekran rozet ve kat anı (rozet planı 4.2, karar 15 Kasım 2026).
///
/// Gündüz masal sonu yaprağından önce gelir. Yeni bir modal değil: okuyucunun
/// içinde, kapanış yaprağının üstünde bir sahne (bir modal açıkken başka
/// modal açılmaz). Büyük arma `MP.M.spring` ile büyür, Ragi sevinir, tek ses,
/// tek titreşim; birden çok rozet aynı ekranda, küçük armalarla. Otomatik
/// kapanma ve geri sayım yok: "Devam" ya da ekrana dokunmak masal sonuna geçer.
/// Reduce Motion'da büyüme yerine yalnızca belirir. Uyku vaktinde hiç açılmaz.
struct MPAwardMoment: View {
    let badges: [MPBadge]
    let levels: [MPStarLevel]
    let theme: MP.ReadTheme
    /// Kutlama yaprak gerçekten açılınca başlar (okuyucu önceden çizebilir).
    let isCurrent: Bool
    let onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    private var level: MPStarLevel? { levels.last }
    private var lead: MPBadge? { badges.first }
    /// Büyük armanın altında küçük durenlar: kat varsa bütün rozetler, yoksa ilkinden sonrakiler.
    private var rest: [MPBadge] { level == nil ? Array(badges.dropFirst()) : badges }

    var body: some View {
        ZStack {
            ReaderPaper(theme: theme)
            VStack(spacing: MPSpacing.lg) {
                Spacer(minLength: MP.S.navBarHeight)

                ZStack {
                    Circle().fill(level == nil ? (lead?.tone.soft ?? MPWorldTone.lav.soft) : MPWorldTone.yellow.soft)
                        .frame(width: 220, height: 220)
                    Group {
                        if let level {
                            MPStarLevelArt(level: level, size: 140)
                        } else if let lead {
                            MPBadgeArt(badge: lead, unlocked: true, size: 140)
                        }
                    }
                    .scaleEffect(shown || reduceMotion ? 1 : 0.5)
                }
                .opacity(shown ? 1 : 0)
                .accessibilityHidden(true)

                MascotImage(mascot: .happy, width: 110, act: isCurrent ? .cheer : .still)
                    .opacity(shown ? 1 : 0)
                    .accessibilityHidden(true)

                VStack(spacing: MPSpacing.xs) {
                    Text(MPBadgeCopy.momentHeadline(badge: lead, level: level))
                        .mpText(.page).foregroundStyle(theme.foreground)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    if let detail = MPBadgeCopy.momentDetail(badge: lead, level: level) {
                        Text(detail).mpText(.body).foregroundStyle(theme.muted)
                            .multilineTextAlignment(.center)
                    }
                }
                .opacity(shown ? 1 : 0)

                if rest.count > (level == nil ? 0 : 1) {
                    others
                }

                Spacer(minLength: MPSpacing.md)

                MPButton(title: "Devam", size: .hero, fullWidth: true, action: onContinue)
                    .padding(.horizontal, MPSpacing.lg)
                    .accessibilityHint("Masalın sonuna geçer")
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, StoryPageView.gutter)
            .padding(.bottom, MPSpacing.xl)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onContinue)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(spokenSummary)
        .task(id: isCurrent) {
            guard isCurrent, !shown else { return }
            MPHaptics.storyEnding()
            MPSound.play(.ending)
            withAnimation(MP.M.gated(MP.M.spring) ?? MP.M.slow) { shown = true }
        }
    }

    /// Küçük armalar ve "ve N rozet daha"; kalan değil, kazanılan söylenir.
    private var others: some View {
        let small = level == nil ? rest : Array(rest.dropFirst())
        return VStack(spacing: MPSpacing.xs) {
            HStack(spacing: MPSpacing.sm) {
                ForEach(small.prefix(4)) { MPBadgeArt(badge: $0, unlocked: true, size: 44) }
            }
            Text(small.count == 1 ? "ve 1 rozet daha" : "ve \(small.count) rozet daha")
                .mpText(.footnote).foregroundStyle(theme.muted)
        }
        .opacity(shown ? 1 : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(small.map(\.title).joined(separator: ", "))
    }

    /// VoiceOver: "Yeni rozet: Ay arkadaşı, 2. kat."
    private var spokenSummary: String {
        var parts: [String] = []
        if let level { parts.append("Yeni yıldız katı: \(level.title)") }
        for badge in badges {
            parts.append(badge.family.isTiered
                         ? "Yeni rozet: \(badge.family.title), \(badge.tier). kat"
                         : "Yeni rozet: \(badge.title)")
        }
        return parts.joined(separator: ". ") + "."
    }
}
