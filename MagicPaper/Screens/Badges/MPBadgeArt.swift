import SwiftUI

// Rozet arması (rozet planı 4.1). Bugün kodla çizilen yer tutucu: simge, dünya
// tonu ve kademeli rozetlerde dikiş halkası + kat numarası. İllüstratörün
// armaları gelince yalnızca bu dosya değişir; ekranlar `MPBadgeArt` çizer.
//
// Kat bilgisi yalnızca renkle verilmez: halka ve numara ikisi birden taşır.

struct MPBadgeArt: View {
    let icon: String
    let tone: MPWorldTone
    /// Kademeli ailede kat (1'den). Nil: tek rozet, halka yok.
    var tier: Int? = nil
    var isUnlocked = true
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle().fill(isUnlocked ? MPColor.backgroundSurface : MPColor.lockedCircle)
            if isUnlocked, tier != nil {
                // Nakış dikişi: kademeli yolun işareti.
                Circle()
                    .strokeBorder(tone.deep.opacity(0.45), style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                    .padding(MPSpacing.xxs)
            }
            MPIcon(icon, size: size >= 96 ? MP.G.hero : MP.G.lg, weight: .semibold)
                .foregroundStyle(isUnlocked ? tone.deep : MPColor.lockedIcon)
        }
        .frame(width: size, height: size)
        .overlay(alignment: .bottomTrailing) {
            if isUnlocked, let tier, tier > 1 {
                Text("\(tier)")
                    .mpText(.footnote).fontWeight(.heavy).monospacedDigit()
                    .foregroundStyle(tone.deep)
                    .padding(.horizontal, MPSpacing.xs)
                    .background(tone.soft, in: Capsule())
                    .overlay(Capsule().strokeBorder(MPColor.backgroundSurface, lineWidth: 2))
            }
        }
        .accessibilityHidden(true)
    }
}

extension MPBadgeArt {
    init(badge: MPBadge, unlocked: Bool, size: CGFloat = 56) {
        self.init(icon: badge.displayIcon(unlocked: unlocked), tone: badge.tone,
                  tier: badge.family.isTiered ? badge.tier : nil, isUnlocked: unlocked, size: size)
    }
}

/// Yıldız katının arması: markanın yıldızı ve kat numarası. Kat yoksa
/// (10 yıldızın altı) sönük yıldız.
struct MPStarLevelArt: View {
    let level: MPStarLevel?
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle().fill(level == nil ? MPColor.lockedCircle : MPWorldTone.yellow.soft)
            Circle()
                .strokeBorder(MPColor.yellowText.opacity(level == nil ? 0 : 0.35),
                              style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                .padding(MPSpacing.xxs)
            MPStarMark(size: size * 0.5)
                .opacity(level == nil ? 0.4 : 1)
        }
        .frame(width: size, height: size)
        .overlay(alignment: .bottomTrailing) {
            if let level {
                Text("\(level.tier)")
                    .mpText(.footnote).fontWeight(.heavy).monospacedDigit()
                    .foregroundStyle(MPColor.yellowText)
                    .padding(.horizontal, MPSpacing.xs)
                    .background(MPWorldTone.yellow.soft, in: Capsule())
                    .overlay(Capsule().strokeBorder(MPColor.backgroundSurface, lineWidth: 2))
            }
        }
        .accessibilityHidden(true)
    }
}

/// Dokunulan rozet kartı: arma + ad. Kilitli rozet gri ve kilit işaretli;
/// gizli rozet "?" ve "Gizli rozet" (rozet planı 4.3).
struct MPBadgeTile: View {
    let badge: MPBadge
    let unlocked: Bool
    let action: () -> Void

    var body: some View {
        Button {
            MPHaptics.tap()
            action()
        } label: {
            VStack(spacing: MPSpacing.xs) {
                MPBadgeArt(badge: badge, unlocked: unlocked)
                // İki satırlık yer ayrılır: kartlar satırda eşit yükseklikte.
                Text(badge.displayTitle(unlocked: unlocked))
                    .mpText(.footnote).multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
                    .foregroundStyle(unlocked ? MPColor.textPrimary : MPColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MPSpacing.md)
            .padding(.horizontal, MPSpacing.xs)
            .mpKidSurface(unlocked ? badge.tone.soft : MPColor.lockedFill,
                          edge: unlocked ? badge.tone.edge : MPColor.lockedCircle)
            .overlay(alignment: .topTrailing) {
                if !unlocked {
                    MPIcon("lock.fill", size: MP.G.xs).foregroundStyle(MPColor.textSecondary)
                        .padding(MPSpacing.sm)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(badge.displayTitle(unlocked: unlocked))
        .accessibilityValue(MPBadgeTile.spokenState(badge, unlocked: unlocked))
        .accessibilityHint("Rozetin ayrıntısını açar")
        .accessibilityAddTraits(.isButton)
    }

    static func spokenState(_ badge: MPBadge, unlocked: Bool) -> String {
        guard unlocked else { return "Kilitli" }
        return badge.family.isTiered ? "Kazanıldı, \(badge.tier). kat" : "Kazanıldı"
    }
}
