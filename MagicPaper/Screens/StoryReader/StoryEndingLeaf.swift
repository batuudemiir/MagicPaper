import SwiftUI

/// 25 · Masal sonu (`MasalSonu`): kitabın kapanış yaprağı.
///
/// Son sayfayı çevirerek varılır; okuyucu kendini kapatmaz. El sallayan
/// Ragi, "Masal bitti!", okumanın sakin sayıları (üst üste günler, yeni
/// kelimeler, yeni rozet varsa o) ve iki yol: "Bir masal daha", "İyi geceler"
/// (uyku modu). Yıldız yok; kutlama 400 ms, Reduce Motion'da yalnızca belirme.
/// FAZ 13: masal seri olarak devam ettirilebiliyorsa "Devam ettir" burada.
struct StoryEndingLeaf: View {

    let story: Story
    let theme: MP.ReadTheme
    let accent: Color
    let onReadAgain: () -> Void
    let onClose: () -> Void
    var onAnother: () -> Void = {}
    var onGoodNight: () -> Void = {}

    @StateObject private var streak = MPStreak.shared
    @StateObject private var news = MPBadgeNews.shared
    @StateObject private var settings = MPSettingsStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            ReaderPaper(theme: theme)
            ScrollView(showsIndicators: false) { column }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Masal bitti")
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: MPMotion.tap) : MPMotion.spring) { appeared = true }
        }
    }

    private var isBedtime: Bool { MPBedtime.isBedtime(settings: settings) }

    private var wordCount: Int {
        Set(story.pages.flatMap { $0.words ?? [] }.map(\.id)).count
    }

    private var column: some View {
        VStack(spacing: MPSpacing.xl) {
            HStack(alignment: .center, spacing: MPSpacing.sm) {
                MascotImage(mascot: .waving, width: 150)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.85)
                    .opacity(appeared ? 1 : 0)
                SpeechBubble(text: "Harika bir masaldı!")
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Harika bir masaldı!")

            VStack(spacing: MPSpacing.sm) {
                Text("Masal bitti!").mpText(.display).foregroundStyle(theme.foreground)
                    .accessibilityAddTraits(.isHeader)
                Text("\(story.title) burada bitiyor.")
                    .mpText(.body).foregroundStyle(theme.muted)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: MPSpacing.md) {
                if streak.currentStreak > 0 {
                    tile(icon: "flame", tone: .peach, value: "\(streak.currentStreak) gün",
                         label: streak.currentStreak > 1 ? "üst üste okudun" : "okuma yolculuğun")
                }
                if wordCount > 0 {
                    tile(icon: "book.closed", tone: .mint, value: "\(wordCount)", label: "yeni kelime")
                }
                if let badge = news.fresh.first {
                    tile(icon: badge.icon, tone: badge.tone, value: badge.title, label: "yeni rozet")
                }
            }

            SeriesEndingSection(story: story, theme: theme, accent: accent)

            // Uyku vaktinde birincil yol "İyi geceler"; gündüz "Bir masal daha".
            VStack(spacing: MPSpacing.xs) {
                if isBedtime {
                    MPButton(title: "İyi geceler", systemImage: "moon", fullWidth: true, action: onGoodNight)
                        .padding(.horizontal, MPSpacing.lg)
                    MPButton(title: "Bir masal daha", systemImage: "wand.and.sparkles", kind: .ghost,
                             action: onAnother)
                } else {
                    MPButton(title: "Bir masal daha", systemImage: "wand.and.sparkles", fullWidth: true,
                             action: onAnother)
                        .padding(.horizontal, MPSpacing.lg)
                    MPButton(title: "İyi geceler", systemImage: "moon", kind: .ghost, action: onGoodNight)
                }
                MPButton(title: "Tekrar oku", kind: .ghost, size: .small, action: onReadAgain)
            }
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, StoryPageView.gutter)
        // Okuyucunun kapat düğmesinin altından başlar.
        .padding(.top, MP.S.navBarHeight + MPSpacing.xxxl)
        .padding(.bottom, MPSpacing.xxxl)
    }

    private func tile(icon: String, tone: MPWorldTone, value: String, label: String) -> some View {
        VStack(spacing: MPSpacing.xs) {
            MPIconTile(systemImage: icon, tone: tone, size: 42, filled: false)
                .accessibilityHidden(true)
            Text(value).mpText(.headline).foregroundStyle(MPColor.textPrimary)
                .multilineTextAlignment(.center)
            Text(label).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.lg)
        .padding(.horizontal, MPSpacing.xs)
        .background(tone.soft, in: RoundedRectangle(cornerRadius: MPRadius.card))
        .accessibilityElement(children: .combine)
    }
}
