import SwiftUI

/// 25 · Masal sonu (`MasalSonu`): kitabın kapanış yaprağı (Faz 4).
///
/// Son sayfayı çevirerek varılır; okuyucu kendini kapatmaz.
///
/// Gündüz: Ragi sevinçle zıplar, kısa ses ve tek titreşim, kazanılanlar tek tek belirir
/// (üst üste günler, yeni kelimeler, rozet), "Birlikte konuşalım" ve iki yol: "Bir masal
/// daha", "Bitir". FAZ 13: masal seri olarak devam ettirilebiliyorsa "Devam ettir" burada.
/// Çocuğun kendi masalında künye (`StoryColophon`) kutucukların altında.
///
/// Uyku vaktinde bir kitabın son sayfası kadar sade (21 Ekim 2026): uyuyan Ragi, "Son",
/// "İyi geceler, <ad>." ve varsa tek satır rozet. Ses, titreşim, soru ve zıplama yok;
/// "İyi geceler" ekranı karartıp kapatır. Reduce Motion'da her şey yalnızca belirir.
struct StoryEndingLeaf: View {

    let story: Story
    let theme: MP.ReadTheme
    let accent: Color
    /// Okuyucu sonraki yaprağı önceden çizebilir; kutlama yaprak gerçekten açılınca başlar.
    let isCurrent: Bool
    let onClose: () -> Void
    var onAnother: () -> Void = {}
    var onGoodNight: () -> Void = {}

    @StateObject private var streak = MPStreak.shared
    @StateObject private var news = MPBadgeNews.shared
    @StateObject private var settings = MPSettingsStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Kaçıncı öğeye kadar göründüğü: 0 hiçbiri.
    @State private var revealed = 0
    @State private var celebrated = false
    @State private var fadingToNight = false

    var body: some View {
        ZStack {
            ReaderPaper(theme: theme)
            ScrollView(showsIndicators: false) { column }
            if fadingToNight {
                MP.Palette.murekkep900.ignoresSafeArea()
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Masal bitti")
        .task(id: isCurrent) {
            guard isCurrent, !celebrated else { return }
            celebrated = true
            await celebrate()
        }
    }

    private var isBedtime: Bool { MPBedtime.isBedtime(settings: settings) }

    private var wordCount: Int {
        Set(story.pages.flatMap { $0.words ?? [] }.map(\.id)).count
    }

    private var earnedCount: Int {
        (streak.currentStreak > 0 ? 1 : 0) + (wordCount > 0 ? 1 : 0) + (news.fresh.isEmpty ? 0 : 1)
    }

    /// Kutlamanın sırası. Gece ya da Reduce Motion'da her şey birlikte, yumuşak belirir.
    private func celebrate() async {
        let total = earnedCount + 2
        if reduceMotion || isBedtime {
            withAnimation(MP.M.slow) { revealed = total }
            return
        }
        MPHaptics.success()
        MPSound.play(.ending)
        withAnimation(MP.M.spring) { revealed = 1 }
        for step in 2...total {
            try? await Task.sleep(for: .seconds(MP.M.RagiBeat.reveal))
            if Task.isCancelled { return }
            withAnimation(MP.M.base) { revealed = step }
            // Rozet en sonda: kazanılan tek şey sesle işaretlenir.
            if step == earnedCount + 1, !news.fresh.isEmpty { MPSound.play(.earned) }
        }
    }

    /// Ekran kararır, sonra okuyucu kapanır. Reduce Motion'da da aynı çapraz geçiş.
    private func sayGoodNight() {
        withAnimation(MP.M.page) { fadingToNight = true }
        Task {
            try? await Task.sleep(for: .seconds(MP.M.RagiBeat.nightFade))
            onGoodNight()
        }
    }

    @ViewBuilder
    private var column: some View {
        if isBedtime { nightColumn } else { dayColumn }
    }

    // MARK: - Gece

    private var nightColumn: some View {
        VStack(spacing: MPSpacing.xl) {
            MascotImage(mascot: .sleeping, width: 120)
                .opacity(revealed > 0 ? 1 : 0)
                .accessibilityHidden(true)

            VStack(spacing: MPSpacing.sm) {
                Text("Son").mpText(.cover).foregroundStyle(theme.foreground)
                    .accessibilityAddTraits(.isHeader)
                Text("İyi geceler, \(story.childName).")
                    .mpText(.body).foregroundStyle(theme.muted)
                    .multilineTextAlignment(.center)
                if streak.currentStreak > 1 {
                    Text("\(streak.currentStreak) gün üst üste birlikte okudunuz.")
                        .mpText(.footnote).foregroundStyle(theme.muted)
                        .multilineTextAlignment(.center)
                }
            }

            if let badge = news.fresh.first { badgeRow(badge.icon, tone: badge.tone, title: badge.title) }

            if StoryColophon.hasDedication(story) { colophon }

            SeriesEndingSection(story: story, theme: theme, accent: accent)

            MPButton(title: "İyi geceler", systemImage: "moon", fullWidth: true, action: sayGoodNight)
                .padding(.horizontal, MPSpacing.lg)
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, StoryPageView.gutter)
        .padding(.top, MP.S.navBarHeight + MPSpacing.xxxl)
        .padding(.bottom, MPSpacing.xxxl)
    }

    /// Gece yaprağında rozet: kutucuk değil, kâğıda yakın tek satır.
    private func badgeRow(_ icon: String, tone: MPWorldTone, title: String) -> some View {
        HStack(spacing: MPSpacing.md) {
            MPIconTile(systemImage: icon, tone: tone, size: 42, filled: false)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MP.S.x1) {
                Text(title).mpText(.section).foregroundStyle(theme.foreground)
                Text("Yeni rozet").mpText(.footnote).foregroundStyle(theme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(MPSpacing.md)
        .background(theme.foreground.opacity(0.06), in: RoundedRectangle(cornerRadius: MPRadius.card))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Gündüz

    private var dayColumn: some View {
        VStack(spacing: MPSpacing.xl) {
            HStack(alignment: .center, spacing: MPSpacing.sm) {
                MascotImage(mascot: .happy, width: 150, act: isCurrent ? .cheer : .still)
                    .scaleEffect(revealed > 0 || reduceMotion ? 1 : 0.85)
                    .opacity(revealed > 0 ? 1 : 0)
                SpeechBubble(text: "Harika bir masaldı!")
                    .opacity(revealed > 0 ? 1 : 0)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Harika bir masaldı!")

            VStack(spacing: MPSpacing.sm) {
                Text("Masal bitti!").mpText(.cover).foregroundStyle(theme.foreground)
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
                        .earned(revealed >= 2, reduceMotion: reduceMotion)
                }
                if wordCount > 0 {
                    tile(icon: "book.closed", tone: .mint, value: "\(wordCount)", label: "yeni kelime")
                        .earned(revealed >= (streak.currentStreak > 0 ? 3 : 2), reduceMotion: reduceMotion)
                }
                if let badge = news.fresh.first {
                    tile(icon: badge.icon, tone: badge.tone, value: badge.title, label: "yeni rozet")
                        .earned(revealed >= earnedCount + 1, reduceMotion: reduceMotion)
                }
            }

            talkTogether
                .opacity(revealed >= earnedCount + 2 ? 1 : 0)

            if StoryColophon.hasDedication(story) { colophon }

            SeriesEndingSection(story: story, theme: theme, accent: accent)

            VStack(spacing: MPSpacing.xs) {
                MPButton(title: "Bir masal daha", systemImage: "wand.and.sparkles", fullWidth: true,
                         action: onAnother)
                    .padding(.horizontal, MPSpacing.lg)
                MPButton(title: "Bitir", kind: .ghost, action: onClose)
            }
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, StoryPageView.gutter)
        // Okuyucunun kapat düğmesinin altından başlar.
        .padding(.top, MP.S.navBarHeight + MPSpacing.xxxl)
        .padding(.bottom, MPSpacing.xxxl)
    }

    /// Kâğıdın üstünde: renkler okuma temasından, bu yüzden `MPSectionHeader` değil.
    private var talkTogether: some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            Text("Birlikte konuşalım").mpText(.section).foregroundStyle(theme.foreground)
                .accessibilityAddTraits(.isHeader)
            ForEach(StoryTalkPrompts.questions(for: story), id: \.self) { question in
                Text(question).mpText(.body).foregroundStyle(theme.foreground)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            Text(value).mpText(.section).foregroundStyle(MPColor.textPrimary)
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

private extension View {
    /// Kazanılan öğe yerine oturur. Görünmeden önce yerini tutar, sayfa zıplamaz.
    func earned(_ shown: Bool, reduceMotion: Bool) -> some View {
        self.opacity(shown ? 1 : 0)
            .scaleEffect(shown || reduceMotion ? 1 : 0.9)
    }
}
