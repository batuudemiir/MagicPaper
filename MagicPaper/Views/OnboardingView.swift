import SwiftUI

/// 02-04 · Karşılama (`Main`, `Onboarding2`, `Onboarding3`).
///
/// Üç sayfa, yana kaydırılır ya da "Devam et" ile ilerler. "Geç" ve son
/// sayfanın "Başlayalım"ı girişe geçer. Her sayfada tek maskot, tek birincil
/// buton. Metinler `docs/SCREENS.md`'den aynen; 03'teki dünya listesi
/// tasarımın sözü, motor bugün modları sunuyor (İrem'e not).
struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool

    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var page = 0

    private struct Page {
        let title: String
        let body: String
        let cta: String
        let background: MPGlowBackground.Style
    }

    private let pages: [Page] = [
        Page(title: "Kahramanı çocuğun olan masallar",
             body: "Adını ve sevdiği dünyayı seç, masalı birlikte yazalım.",
             cta: "Devam et", background: .dawn),
        Page(title: "Her akşam başka bir dünya",
             body: "Uzay, orman, deniz altı, korsanlar. Masal her gece yeniden yazılır.",
             cta: "Devam et", background: .night),
        Page(title: "Kontrol her zaman sende",
             body: "Reklam yok, satın alma çocuğa kapalı. Her masal güvenlik kontrolünden geçer.",
             cta: "Başlayalım", background: .lilac)
    ]

    private var onDark: Bool { page == 1 }

    var body: some View {
        ZStack {
            ForEach(pages.indices, id: \.self) { index in
                MPGlowBackground(style: pages[index].background)
                    .opacity(index == page ? 1 : 0)
            }
            .animation(MP.M.gated(MP.M.base), value: page)

            VStack(spacing: 0) {
                HStack {
                    Spacer(minLength: 0)
                    Button("Geç", action: finish)
                        .mpText(.bodyStrong)
                        .foregroundStyle(onDark ? Color.white : MPColor.textPrimary)
                        .frame(minWidth: MPSize.minTouchKid, minHeight: MPSize.minTouchParent)
                        .accessibilityHint("Karşılamayı atlar")
                }
                .padding(.horizontal, MPSpacing.screenH)

                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageView(index).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack(spacing: MPSpacing.xxl) {
                    MPPageDots(count: pages.count, current: page, onDark: onDark)
                    MPButton(title: pages[page].cta, fullWidth: true) {
                        if page < pages.count - 1 {
                            withAnimation(MP.M.gated(MP.M.base)) { page += 1 }
                        } else {
                            finish()
                        }
                    }
                    .padding(.horizontal, MPSpacing.xxxl)
                }
                .padding(.bottom, MPSpacing.lg)
            }
        }
    }

    @ViewBuilder
    private func pageView(_ index: Int) -> some View {
        let page = pages[index]
        VStack(spacing: MPSpacing.xl) {
            Spacer(minLength: 0)
            art(index)
            Spacer(minLength: 0)
            VStack(spacing: MPSpacing.md) {
                Text(page.title)
                    .mpText(.largeTitle)
                    .foregroundStyle(index == 1 ? Color.white : MPColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(page.body)
                    .mpText(.body)
                    .foregroundStyle(index == 1 ? Color.white.opacity(0.82) : MPColor.textSecondary)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, MPSpacing.xxxl)
        }
        .padding(.bottom, MPSpacing.xxl)
    }

    @ViewBuilder
    private func art(_ index: Int) -> some View {
        switch index {
        case 0:
            VStack(spacing: MPSpacing.xxl) {
                Image("Brand/wordmarkLight")
                    .resizable().scaledToFit()
                    .frame(maxWidth: 230)
                    .accessibilityLabel("MagicPaper")
                MascotImage(mascot: .onBook, width: 270)
                    .accessibilityHidden(true)
            }
        case 1:
            Image("Brand/sceneNight")
                .resizable().scaledToFill()
                .frame(width: 300, height: 246)
                .clipShape(RoundedRectangle(cornerRadius: MPRadius.hero, style: .continuous))
                .mpShadow(.card)
                .accessibilityHidden(true)
        default:
            MascotImage(mascot: .walking, width: 200)
                .frame(width: 260, height: 260)
                .background(MPColor.backgroundSurface, in: Circle())
                .mpShadow(.card)
                .accessibilityHidden(true)
        }
    }

    private func finish() {
        profileManager.completeOnboarding()
        isOnboardingComplete = true
    }
}
