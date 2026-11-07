import SwiftUI
import StoryEngine

/// 19 · Yarat 1 (`SihirbazNerede`): bu akşam nasıl bir masal?
///
/// 7 Kasım 2026: moda dokununca geçilir, "Devam et" yok; "Bana sürpriz yap"
/// masalı doğrudan yazar. Konu ikinci adıma taşındı. İki çocuklu evde üstte tek
/// satır "İrem için ▾" (`CreationChildPicker`).
///
/// Sürpriz dördüncü bir mod değil: MagicPaper'ın üç moddan birini seçmesi
/// (`StoryModeResolver`), bu yüzden ayrı bir geri çağrı.
///
/// Kurulamayan bir mod gösterilmez: seçildiğinde hiçbir şey üretemeyecek
/// bir kart, verdiği sözü sessizce başka bir masala çevirir.
struct StoryModeStep: View {

    let modes: [StoryMode]
    /// Uyku saatinde öne çıkan mod: ilk sırada ve vurgulu, diğerleri serbest
    /// (karar 15 Ekim 2026).
    var emphasized: StoryMode? = nil
    var childName: String = ""
    var profiles: [UserProfile] = []
    var authoredBands: [AgeBand] = []
    @Binding var selectedProfileID: UUID?
    let onChoose: (StoryMode) -> Void
    let onSurprise: () -> Void

    private var showsPicker: Bool {
        StoryCreationSteps.showsChildPicker(profileCount: profiles.count)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                VStack(alignment: .leading, spacing: MPSpacing.sm) {
                    if showsPicker {
                        CreationChildPicker(profiles: profiles, authoredBands: authoredBands,
                                            selectedID: $selectedProfileID)
                    }
                    CreationTitle(
                        // Seçici varken ad zaten hemen üstünde.
                        title: childName.isEmpty || showsPicker ? "Nasıl bir masal olsun?" : "\(childName) için nasıl bir masal?",
                        subtitle: "Birini seç, gerisini biz hazırlayalım.",
                        note: emphasized.map { "Bu akşam için önerimiz: \($0.title)." }
                    )
                }

                VStack(spacing: MPSpacing.md) {
                    ForEach(StoryCreationSteps.shownModes(modes, emphasized: emphasized), id: \.self) { mode in
                        CreationChoiceRow(
                            title: mode.title,
                            subtitle: mode.promise,
                            isSelected: mode == emphasized,
                            accessibilityLabel: mode == emphasized
                                ? "\(mode.title), bu akşam için önerilen. \(mode.promise)"
                                : "\(mode.title). \(mode.promise)",
                            action: {
                                MPHaptics.selection()
                                onChoose(mode)
                            },
                            leading: { MPIconTile(systemImage: mode.symbol, tone: mode.tone, size: MPSize.minTouchKid - MPSpacing.xxs) }
                        )
                    }
                }

                // Tek bir mod kaldıysa sürprizin seçeceği bir şey yok (K6).
                if StoryCreationSteps.showsSurprise(availableModes: modes) {
                    MPButton(title: "Bana sürpriz yap", systemImage: "wand.and.sparkles", kind: .ghost, fullWidth: true) {
                        MPHaptics.selection()
                        onSurprise()
                    }
                    .accessibilityHint("Bugünün masalını biz seçip yazalım.")
                }

                // Masal yazmanın ilk adımı: Ragi kalemiyle hazır (23 Ekim 2026).
                // Akışın tek Ragi'si; sonraki "Masalda kimler olsun?" sessiz.
                MascotSays(mascot: .pencil, text: "Sen seç, masalı birlikte yazalım!", mascotWidth: 72)
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.sm)
            .padding(.bottom, MPSpacing.xxxl)
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
