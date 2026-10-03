import SwiftUI

/// Adım 1 — bu akşam nasıl bir hikâye?
///
/// Ebeveynin tek zorunlu kararı. Üç niyet ve "Bana sürpriz yap". Sürpriz bir
/// dördüncü mod değil: MagicPaper'ın ebeveyn adına üç moddan birini seçmesi
/// (`StoryModeResolver`). Bu yüzden ayrı bir geri çağrıyla bildirilir.
///
/// Kurulamayan bir mod gösterilmez. Seçildiğinde hiçbir şey üretemeyecek bir
/// kart, verdiği sözü sessizce başka bir hikâyeye çevirir.
struct StoryModeStep: View {

    let modes: [StoryMode]
    let onChoose: (StoryMode) -> Void
    let onSurprise: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: MP.S.x2) {
                    Text("Bu akşam nasıl bir hikâye olsun?")
                        .font(MP.F.displayLG())
                        .mpTightTracking(32)
                        .foregroundStyle(MP.C.textTitle)
                    Text("Birini seç, gerisini biz hazırlayalım.")
                        .font(MP.F.bodyMD())
                        .foregroundStyle(MP.C.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, MP.S.x3)
                .padding(.bottom, MP.S.x5)

                VStack(spacing: MP.S.stackGap) {
                    ForEach(StoryCreationSteps.shownModes(modes), id: \.self) { mode in
                        MPChoiceTile(
                            title: mode.title,
                            description: mode.promise,
                            symbol: mode.symbol,
                            accent: mode.accent,
                            layout: .column
                        ) {
                            onChoose(mode)
                        }
                        .accessibilityLabel("\(mode.title). \(mode.promise)")
                    }

                    // Tek bir mod kaldıysa sürprizin seçeceği bir şey yok (K6).
                    if StoryCreationSteps.showsSurprise(availableModes: modes) {
                        MPChoiceTile(
                            title: "Bana sürpriz yap",
                            description: "Bugünün hikâyesini biz seçelim.",
                            symbol: "wand.and.stars",
                            accent: MP.C.reward,
                            layout: .column,
                            action: onSurprise
                        )
                        .accessibilityLabel("Bana sürpriz yap. Bugünün hikâyesini biz seçelim.")
                    }
                }
            }
            .mpGutter()
            .padding(.bottom, MP.S.x6)
        }
    }
}

// MARK: - Sunum

/// Modların ekrandaki karşılığı. Motor modun ne *olduğunu* bilir; nasıl
/// göründüğü uygulamanın işi.
extension StoryMode {
    /// Ekrandaki sıra (karar K5, 3 Ekim 2026). Motorun `allCases` sırası
    /// sürprizin eşitlik bozması için sabit kalır; kart, süzgeç ve ana sayfa
    /// sırası buradan okunur.
    static let displayOrder: [StoryMode] = [.bedtime, .learning, .adventure]

    var title: String {
        switch self {
        case .bedtime:   return "Uyku öncesi"
        case .learning:  return "Yeni şeyler öğrenelim"
        case .adventure: return "Maceraya çıkalım"
        }
    }

    var promise: String {
        switch self {
        case .learning:  return "Yeni bir şey keşfedelim."
        case .adventure: return "Birlikte bir maceraya çıkalım."
        case .bedtime:   return "Günü sakin bir hikâyeyle kapatalım."
        }
    }

    var symbol: String {
        switch self {
        case .learning:  return "sparkles"
        case .adventure: return "tent"
        case .bedtime:   return "moon"
        }
    }

    var accent: Color {
        switch self {
        case .learning:  return MP.C.brand
        case .adventure: return MP.C.play
        case .bedtime:   return MP.C.calm
        }
    }
}
