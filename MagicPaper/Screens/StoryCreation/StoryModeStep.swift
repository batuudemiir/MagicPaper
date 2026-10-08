import SwiftUI

/// 19 · Yarat 1 (`SihirbazNerede`): bu akşam nasıl bir masal?
///
/// Teslimdeki dünya ızgarasının yerinde modlar duruyor (karar 7 Ekim 2026):
/// üç niyet ve "Bana sürpriz yap", pastel kartlarda. Kart seçilir, "Devam
/// et" ilerler. Sürpriz dördüncü bir mod değil: MagicPaper'ın üç moddan
/// birini seçmesi (`StoryModeResolver`), bu yüzden ayrı bir geri çağrı.
///
/// Kurulamayan bir mod gösterilmez: seçildiğinde hiçbir şey üretemeyecek
/// bir kart, verdiği sözü sessizce başka bir masala çevirir.
struct StoryModeStep: View {

    let modes: [StoryMode]
    var childName: String = ""
    var childColor: Color? = nil
    let onChoose: (StoryMode) -> Void
    let onSurprise: () -> Void

    private enum Choice: Hashable { case mode(StoryMode), surprise }
    @State private var choice: Choice?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MPSpacing.lg) {
                VStack(spacing: MPSpacing.sm) {
                    Text("Masal nasıl olsun?")
                        .mpText(.title1).foregroundStyle(MPColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("Birini seç, gerisini biz hazırlayalım.")
                        .mpText(.body).foregroundStyle(MPColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                if !childName.isEmpty {
                    HStack(spacing: MPSpacing.sm) {
                        MPAvatar(name: childName, color: childColor, size: 32)
                        Text("Kahraman: \(childName)").mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                    }
                    .padding(.leading, MPSpacing.xs).padding(.trailing, MPSpacing.lg)
                    .frame(minHeight: 44)
                    .background(MPColor.backgroundSurface, in: Capsule())
                    .mpShadow(.control)
                    .accessibilityElement(children: .combine)
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: MPSpacing.md),
                                    GridItem(.flexible(), spacing: MPSpacing.md)],
                          spacing: MPSpacing.lg) {
                    ForEach(StoryCreationSteps.shownModes(modes), id: \.self) { mode in
                        WorldTile(title: mode.title, systemImage: mode.symbol, tone: mode.tone,
                                  isSelected: choice == .mode(mode)) {
                            MPHaptics.selection()
                            choice = .mode(mode)
                        }
                        .accessibilityLabel("\(mode.title). \(mode.promise)")
                    }
                    // Tek bir mod kaldıysa sürprizin seçeceği bir şey yok (K6).
                    if StoryCreationSteps.showsSurprise(availableModes: modes) {
                        WorldTile(title: "Bana sürpriz yap", systemImage: "wand.and.sparkles", tone: .pink,
                                  isSelected: choice == .surprise) {
                            MPHaptics.selection()
                            choice = .surprise
                        }
                        .accessibilityLabel("Bana sürpriz yap. Bugünün masalını biz seçelim.")
                    }
                }
                .padding(.top, MPSpacing.sm)
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MPButton(title: "Devam et", fullWidth: true) {
                switch choice {
                case .mode(let mode): onChoose(mode)
                case .surprise: onSurprise()
                case nil: break
                }
            }
            .disabled(choice == nil)
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.vertical, MPSpacing.md)
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
