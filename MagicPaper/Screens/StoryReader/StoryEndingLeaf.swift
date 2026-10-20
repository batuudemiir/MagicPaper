import SwiftUI

/// 25 · Masal sonu (`MasalSonu`): kitabın kapanış yaprağı.
///
/// Son sayfayı çevirerek varılır; okuyucu kendini kapatmaz. El sallayan
/// Ragi, "Masal bitti!", okumanın sakin sayıları (üst üste günler, yeni
/// kelimeler, yeni rozet varsa o) ve iki yol: "Bir masal daha", "İyi geceler"
/// (uyku modu). Yıldız yok; kutlama 400 ms, Reduce Motion'da yalnızca belirme.
/// FAZ 13: masal seri olarak devam ettirilebiliyorsa "Devam ettir" burada.
/// Çocuğun kendi masalında künye (`StoryColophon`) kutucukların altında.
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
    @Environment(\.dynamicTypeSize) private var typeSize
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

            // En büyük yazı boyutlarında döşemeler alt alta: kelime ortasından bölünmesin.
            (typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: MPSpacing.md))
                                          : AnyLayout(HStackLayout(spacing: MPSpacing.md))) {
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

            if StoryColophon.hasDedication(story) { colophon }

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

    /// Kitabın son sayfasındaki künye: "MagicPaper Kitaplığı · İrem'in 12. masalı".
    /// Kutucuk ya da rozet değil, ince bir çizginin altında sessiz bir satır.
    private var colophon: some View {
        let ordinal = StoryColophon.ordinal(of: story, among: StoryGenerationManager.shared.stories)
        return VStack(spacing: MP.S.x3) {
            Rectangle().fill(theme.muted.opacity(0.3))
                .frame(width: MP.S.x9, height: 1)
                .accessibilityHidden(true)
            Text(StoryColophon.colophon(childName: story.childName, ordinal: ordinal))
                .font(MP.F.labelSM(.semibold))
                .foregroundStyle(theme.muted)
                .multilineTextAlignment(.center)
        }
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
