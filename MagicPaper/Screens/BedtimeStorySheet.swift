import SwiftUI

/// Akşam kartında seçilen yol; pencere kapandıktan sonra `MPAppState`
/// açar (`runBedtimeChoice`).
enum BedtimeChoice: Equatable {
    /// Uyku öncesi modunda yeni masal: doğrudan "Masalda kimler olsun?".
    case bedtimeStory
    /// Yarım kalan masala devam.
    case resume(Story)
    /// Mod adımından, üç mod da seçilebilir.
    case otherStory
}

/// "Bu geceki masal": uyku saatinde Ana sayfa kartının açtığı pencere
/// (karar 15 Ekim 2026, `docs/UYKU_MODU_V2_PLANI.md`).
///
/// Yalnızca karta dokununca açılır; akşam kendiliğinden gelmez (ilke 7).
/// Uyku öncesi öne çıkar, ama akşam başka bir masal da seçilebilir. Ragi
/// burada yok: sahnede zaten uyuyor, ekranda tek maskot.
struct BedtimeStorySheet: View {
    /// Yarım kalan masal, varsa (`MPTonightSource`).
    let resumeStory: Story?
    let onChoose: (BedtimeChoice) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MPSpacing.lg) {
                MPIcon("moon", size: MP.G.xl, weight: .semibold)
                    .foregroundStyle(MPColor.actionPrimary)
                    .frame(width: MPSize.iconTile, height: MPSize.iconTile)
                    .background(MPWorldTone.lav.soft, in: RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
                    .accessibilityHidden(true)

                VStack(spacing: MPSpacing.xs) {
                    Text("Bu geceki masal")
                        .mpText(.title2).foregroundStyle(MPColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("Kısa, sakin ve uykuya hazırlayan bir masal.")
                        .mpText(.body).foregroundStyle(MPColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: MPSpacing.sm) {
                    MPButton(title: "Uyku masalı yaz", systemImage: "moon.fill", fullWidth: true) {
                        choose(.bedtimeStory)
                    }
                    .accessibilityHint("Masalda kimlerin olacağını seçmeye geçer")

                    if let story = resumeStory {
                        VStack(spacing: MPSpacing.xxs) {
                            MPButton(title: "Kaldığın yerden devam et", systemImage: "play.fill",
                                     kind: .soft, fullWidth: true) {
                                choose(.resume(story))
                            }
                            .accessibilityLabel("Kaldığın yerden devam et: \(story.title)")
                            Text(story.title).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                                .multilineTextAlignment(.center)
                                .accessibilityHidden(true)
                        }
                    }

                    MPButton(title: "Başka bir masal seçeyim", kind: .ghost) {
                        choose(.otherStory)
                    }
                    .accessibilityHint("Masal türünü seçmeye geçer")
                }
            }
            .padding(.horizontal, MPSpacing.screenH + MPSpacing.lg)
            .padding(.top, MPSpacing.xxl)
            .padding(.bottom, MPSpacing.lg)
        }
        .presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(MPRadius.sheet)
        .presentationBackground(MPColor.backgroundKid)
    }

    private func choose(_ choice: BedtimeChoice) {
        MPHaptics.tap()
        onChoose(choice)
        dismiss()
    }
}

#Preview("Bu geceki masal") {
    Color.clear.sheet(isPresented: .constant(true)) {
        BedtimeStorySheet(resumeStory: nil) { _ in }
    }
}
