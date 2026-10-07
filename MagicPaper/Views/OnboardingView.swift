import SwiftUI

/// Onboarding — 03-SCREENS.md §1. Üç sayfa, sıfır emoji.
struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool

    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var page = 0
    @State private var cycleIndex = 0
    @State private var cycleVisible = true

    /// 2. sayfanın döngüsel ikonu — her 1000ms'de bir değişir.
    private let cycleSymbols = ["building.columns", "airplane.departure", "tree", "fish",
                                "sailboat", "snowflake", "cpu", "tent"]

    private struct Page {
        let symbol: String
        let title: String
        let body: String
        let cta: String
    }

    private let pages: [Page] = [
        Page(symbol: "wand.and.stars",
             title: "Kendi masalını yarat",
             body: "Çocuğun ismini ve dünyasını seç, gerisini biz yazalım.",
             cta: "Devam et"),
        Page(symbol: "",
             title: "Onlarca dünya",
             body: "Uzay, orman, deniz altı, korsanlar... her akşam farklı bir masal.",
             cta: "Devam et"),
        Page(symbol: "book",
             title: "Uykudan önceki en güzel on dakika",
             body: "Çocuğunun adının geçtiği bir masal, birlikte geçen sakin bir akşam ve mutlu bir uyku.",
             cta: "Başlayalım")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer(minLength: 0)
                LegacyMPButton(title: "Geç", variant: .ghost, size: .sm) { finish() }
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, MP.S.screenGutter)
            .padding(.top, 4)

            Spacer(minLength: 0)

            VStack(spacing: 22) {
                iconBox

                VStack(spacing: 10) {
                    Text(pages[page].title)
                        .font(MP.F.displayLG())
                        .mpTightTracking(32)
                        .foregroundStyle(MP.C.textTitle)
                        .multilineTextAlignment(.center)

                    Text(pages[page].body)
                        .font(MP.F.bodyLG())
                        .lineSpacing(18 * 0.5)
                        .foregroundStyle(MP.C.textMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 290)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 0)

            VStack(spacing: 18) {
                MPStepDots(total: pages.count, current: page)

                LegacyMPButton(title: pages[page].cta,
                         size: .lg,
                         iconAfter: page < pages.count - 1 ? "arrow.right" : nil,
                         fullWidth: true) {
                    if page < pages.count - 1 {
                        withAnimation(MP.M.gated(MP.M.base)) { page += 1 }
                    } else {
                        finish()
                    }
                }
            }
            .padding(.horizontal, MP.S.screenGutter)
            .padding(.bottom, 12)
        }
        .mpScreenBackground()
        .task(id: page) {
            guard page == 1 else { return }
            // 1000ms'de bir ikon değişir; çıkış ease-out, giriş ease-spring.
            while !Task.isCancelled && page == 1 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard page == 1 else { break }
                withAnimation(.easeOut(duration: 0.13)) { cycleVisible = false }
                try? await Task.sleep(nanoseconds: 130_000_000)
                cycleIndex = (cycleIndex + 1) % cycleSymbols.count
                withAnimation(MP.M.gated(MP.M.spring)) { cycleVisible = true }
            }
        }
    }

    private var iconBox: some View {
        MPIcon(page == 1 ? cycleSymbols[cycleIndex] : pages[page].symbol, size: 52, weight: .semibold)
            .foregroundStyle(MP.C.brand)
            .opacity(page == 1 && !cycleVisible ? 0 : 1)
            .scaleEffect(page == 1 && !cycleVisible ? 0.82 : 1)
            .frame(width: 108, height: 108)
            .background(
                RoundedRectangle(cornerRadius: MP.R.xxl, style: .continuous)
                    .fill(MP.C.brandSoft)
            )
    }

    private func finish() {
        profileManager.completeOnboarding()
        isOnboardingComplete = true
    }
}
