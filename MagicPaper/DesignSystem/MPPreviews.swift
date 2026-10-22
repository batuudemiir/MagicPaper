#if DEBUG
import SwiftUI

// Handoff 1. adım: temel bileşenlerin 02-COMPONENTS.md'deki ölçülerle
// karşılaştırılabilmesi için önizlemeler. Beklenen değerler yorumlarda.

#Preview("MPChoiceTile — satır ve ızgara") {
    // row: padding 16/18 · ikon kutusu 46 · radyo 26 · yarıçap 22 · 4px kenar
    // column: padding 18 · ikon kutusu 52 · sağ üstte 24px işaret
    ScrollView {
        VStack(spacing: 12) {
            MPChoiceTile(title: "Kısa", description: "5 sayfa · 3 dakika",
                         symbol: "clock") {}
            MPChoiceTile(title: "Orta", description: "8 sayfa · 6 dakika",
                         symbol: "book", isSelected: true) {}
            MPChoiceTile(title: "Uzun", description: "12 sayfa · 9 dakika",
                         symbol: "bookmark", isLocked: true) {}

            HStack(spacing: 12) {
                MPChoiceTile(title: "Uzay Macerası", symbol: "airplane.departure",
                             accent: MP.World.uzay.accent, layout: .column) {}
                MPChoiceTile(title: "Orman Macerası", symbol: "tree",
                             accent: MP.World.orman.accent,
                             isSelected: true, layout: .column) {}
            }
        }
        .padding(MP.S.screenGutter)
    }
    .background(MP.C.surfaceApp)
}

#Preview("Diğer bileşenler") {
    ScrollView {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                MPStarPill(count: 3)
                MPBadge(title: "Görselli", tone: .reward, symbol: "crown.fill")
                MPBadge(title: "8 sayfa", tone: .neutral)
            }
            HStack(spacing: 10) {
                MPAvatar(name: "elif", size: 48)
                MPAvatar(name: "İnci", size: 48, ring: true)
            }
            MPStepDots(total: 3, current: 1)
            MPProgressRing(value: 0.62, size: 120, color: MP.C.brand,
                           label: "%62", caption: "hazırlanıyor")
            MPStoryCard(title: "Elif ve Kayıp Yıldız Gemisi", meta: "8 sayfa · Dün",
                        symbol: "airplane.departure", accent: MP.World.uzay.accent,
                        badge: "Görselli", progress: 0.4, layout: .row) {}
        }
        .padding(MP.S.screenGutter)
    }
    .background(MP.C.surfaceApp)
}
#endif
