import SwiftUI

/// 25 · Masal sonu (`MasalSonu`): kitabın kapanış yaprağı, tam ekran bir an (8 Kasım 2026).
///
/// Son sayfayı çevirerek varılır; okuyucu kendini kapatmaz. Sayfa kaymaz: her şey tek
/// ekrana sığar, yalnızca en büyük yazı boyutlarında kaydırmaya düşer.
///
/// Gündüz bir başarı anı: Ragi sevinçle zıplar, arkasında kâğıt yıldızlar bir kez
/// patlar, kısa ses ve tek titreşim; kazanılanlar (ilk kez bitiyorsa yıldız, üst üste
/// günler, yeni kelimeler, rozet) tek tek sesle belirir. Sonra Ragi'nin balonu bir soru
/// sorar ("Birlikte konuşalım", puansız). Yollar: "Bir masal daha", "Bitir". FAZ 13:
/// seri devam ettirilebiliyorsa "Devam ettir" burada. Künye kazanılanların altında.
///
/// Uyku vaktinde bir kitabın son sayfası kadar sade: uyuyan Ragi, "Son", "İyi geceler,
/// <ad>." ve varsa tek satır rozet. Ses, titreşim, patlama ve soru yok; "İyi geceler"
/// ekranı karartıp kapatır. Reduce Motion'da her şey yalnızca belirir.
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
    @State private var burst = false
    @State private var fadingToNight = false

    var body: some View {
        ZStack {
            ReaderPaper(theme: theme)
            ViewThatFits(in: .vertical) {
                column
                ScrollView(showsIndicators: false) { column }
            }
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

    @ViewBuilder
    private var column: some View {
        if isBedtime { nightColumn } else { dayColumn }
    }

    // MARK: - Kazanılanlar

    private struct Earned: Identifiable {
        let id: String, icon: String, tone: MPWorldTone, value: String, label: String
    }

    /// Masal okuyucu açılmadan önce bitmemişse yıldız yenidir (karar 13 Ekim:
    /// her biten masal bir yıldız). Tekrar okumada yıldız sözü verilmez.
    private var earned: [Earned] {
        var items: [Earned] = []
        if !story.isFinished {
            items.append(.init(id: "star", icon: "star.fill", tone: .yellow, value: "+1", label: "yıldız"))
        }
        if streak.currentStreak > 0 {
            items.append(.init(id: "streak", icon: "flame", tone: .peach, value: "\(streak.currentStreak) gün",
                               label: streak.currentStreak > 1 ? "üst üste" : "okuma günü"))
        }
        let others = StoryGenerationManager.shared.stories.filter {
            $0.id != story.id && $0.childProfileID == story.childProfileID
        }
        let words = MPVocabulary.newWordCount(in: story, comparedTo: others)
        if words > 0 {
            items.append(.init(id: "words", icon: "book.closed", tone: .mint, value: "\(words)", label: "yeni kelime"))
        }
        if let badge = news.fresh.first {
            items.append(.init(id: "badge", icon: badge.icon, tone: badge.tone, value: badge.title, label: "yeni rozet"))
        }
        return items
    }

    private var question: String? { StoryTalkPrompts.questions(for: story).first }

    /// Sıra: 1 Ragi ve başlık, sonra her kazanılan, en son Ragi'nin sorusu.
    private func celebrate() async {
        let total = earned.count + 2
        if reduceMotion || isBedtime {
            withAnimation(MP.M.slow) { revealed = total }
            return
        }
        MPHaptics.success()
        MPSound.play(.ending)
        burst = true
        withAnimation(MP.M.spring) { revealed = 1 }
        try? await Task.sleep(for: .seconds(MP.M.RagiBeat.reveal * 2))
        for step in 2...total {
            if Task.isCancelled { return }
            withAnimation(MP.M.spring) { revealed = step }
            if step <= earned.count + 1 { MPSound.play(.earned) }
            try? await Task.sleep(for: .seconds(MP.M.RagiBeat.reveal))
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

    // MARK: - Gündüz

    private var dayColumn: some View {
        VStack(spacing: MPSpacing.lg) {
            Spacer(minLength: MP.S.navBarHeight)

            ZStack {
                Circle().fill(MPWorldTone.yellow.soft)
                    .frame(width: 230, height: 230)
                    .scaleEffect(revealed > 0 ? 1 : 0.4)
                    .opacity(revealed > 0 ? 1 : 0)
                    .accessibilityHidden(true)
                if burst && !reduceMotion { PaperBurst().accessibilityHidden(true) }
                MascotImage(mascot: .happy, width: 180, act: isCurrent ? .cheer : .still)
                    .scaleEffect(revealed > 0 || reduceMotion ? 1 : 0.7)
                    .opacity(revealed > 0 ? 1 : 0)
            }
            .frame(height: 230)
            .overlay(alignment: .topTrailing) {
                if !typeSize.isAccessibilitySize { bubble.frame(maxWidth: 190, alignment: .trailing)
                    .offset(x: MPSpacing.sm, y: -MPSpacing.md) }
            }

            // En büyük yazıda balon Ragi'nin üstüne değil altına: başlığı örtmesin.
            if typeSize.isAccessibilitySize { bubble }

            VStack(spacing: MPSpacing.xs) {
                Text(StoryEndingCopy.bravo(story.childName)).mpText(.cover).foregroundStyle(theme.foreground)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text("\(story.title) masalını bitirdin.")
                    .mpText(.body).foregroundStyle(theme.muted)
                    .multilineTextAlignment(.center)
            }
            .opacity(revealed > 0 ? 1 : 0)

            earnedRow

            if StoryColophon.hasDedication(story) { colophon }

            SeriesEndingSection(story: story, theme: theme, accent: accent)

            Spacer(minLength: MPSpacing.md)

            VStack(spacing: MPSpacing.xs) {
                MPButton(title: "Bir masal daha", systemImage: "wand.and.sparkles", size: .hero, fullWidth: true,
                         action: onAnother)
                    .padding(.horizontal, MPSpacing.lg)
                MPButton(title: "Bitir", kind: .ghost, action: onClose)
            }
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, StoryPageView.gutter)
        .padding(.bottom, MPSpacing.xl)
    }

    /// Önce "Harika bir masaldı!", kazanılanlar bitince Ragi'nin sorusu (Birlikte konuşalım).
    private var bubble: some View {
        let asks = revealed >= earned.count + 2 && question != nil
        let text = asks ? question ?? "" : "Harika bir masaldı!"
        return SpeechBubble(text: text, style: asks ? .supporting : .cardTitle)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(revealed > 0 ? 1 : 0)
            .contentTransition(.opacity)
            .animation(MP.M.gated(MP.M.base), value: asks)
            .accessibilityLabel(asks ? "Birlikte konuşalım: \(text)" : text)
    }

    @ViewBuilder
    private var earnedRow: some View {
        let items = earned
        if !items.isEmpty {
            // Az öğe ortada sıkı durur; dört öğe ve en büyük yazıda iki sütun.
            let columns = typeSize.isAccessibilitySize || items.count > 3 ? 2 : items.count
            LazyVGrid(columns: Array(repeating: GridItem(columns > 1 || items.count > 1 ? .flexible() : .fixed(132),
                                                         spacing: MPSpacing.sm), count: columns),
                      spacing: MPSpacing.sm) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let shown = revealed >= index + 2
                    tile(item, shown: shown)
                        .opacity(shown ? 1 : 0)
                        .scaleEffect(shown || reduceMotion ? 1 : 0.6)
                        .offset(y: shown || reduceMotion ? 0 : MPSpacing.md)
                }
            }
        }
    }

    private func tile(_ item: Earned, shown: Bool) -> some View {
        VStack(spacing: MP.S.x1) {
            Group {
                if item.id == "star" {
                    // Yıldız dolu ve büyük: kazanılanın en parlak anı. Yerine dönerek oturur.
                    PaperStar().fill(MPWorldTone.yellow.deep)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(shown || reduceMotion ? 0 : -120))
                } else {
                    MPIconTile(systemImage: item.icon, tone: item.tone, size: 44, filled: true)
                }
            }
            .accessibilityHidden(true)
            Text(item.value).mpText(.section).foregroundStyle(MPColor.textPrimary)
                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
            Text(item.label).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.md)
        .padding(.horizontal, MPSpacing.xs)
        .mpKidSurface(item.tone.soft, edge: item.tone.edge)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Gece

    private var nightColumn: some View {
        VStack(spacing: MPSpacing.xl) {
            Spacer(minLength: MP.S.navBarHeight)
            MascotImage(mascot: .sleeping, width: 150)
                .opacity(revealed > 0 ? 1 : 0)
                .accessibilityHidden(true)

            VStack(spacing: MPSpacing.sm) {
                Text("Son").mpText(.cover).foregroundStyle(theme.foreground)
                    .accessibilityAddTraits(.isHeader)
                Text(StoryEndingCopy.goodNight(story.childName))
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

            Spacer(minLength: MPSpacing.md)

            MPButton(title: "İyi geceler", systemImage: "moon", size: .hero, fullWidth: true, action: sayGoodNight)
                .padding(.horizontal, MPSpacing.lg)
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, StoryPageView.gutter)
        .padding(.bottom, MPSpacing.xl)
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

    /// Kitabın son sayfasındaki künye: "MagicPaper Kitaplığı · İrem'in 12. masalı".
    private var colophon: some View {
        let ordinal = StoryColophon.ordinal(of: story, among: StoryGenerationManager.shared.stories)
        return Text(StoryColophon.colophon(childName: story.childName, ordinal: ordinal))
            .font(MP.F.labelSM(.semibold))
            .foregroundStyle(theme.muted)
            .multilineTextAlignment(.center)
    }
}

/// Masal sonunda Ragi'nin arkasından bir kez fırlayan kâğıt yıldızlar ve kâğıt
/// parçaları. Parıltı değil, kâğıt: marka tonlarında, yerçekimiyle düşer, söner.
/// Sonsuz değil; bir kez oynar ve çizim durur.
private struct PaperBurst: View {
    @State private var start = Date()

    private struct Piece {
        let angle: Double, speed: Double, spin: Double, size: Double, star: Bool, tone: MPWorldTone
    }

    private static let pieces: [Piece] = {
        var rng = SystemRandomNumberGenerator()
        let tones: [MPWorldTone] = [.yellow, .peach, .pink, .lav, .mint, .sky]
        return (0..<30).map { i in
            Piece(angle: -.pi / 2 + Double.random(in: -1.25...1.25, using: &rng),
                  speed: Double.random(in: 260...480, using: &rng),
                  spin: Double.random(in: -6...6, using: &rng),
                  size: Double.random(in: 8...15, using: &rng),
                  star: i % 3 == 0,
                  tone: tones[i % tones.count])
        }
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: MP.M.RagiBeat.frame)) { context in
            let t = context.date.timeIntervalSince(start)
            Canvas { canvas, size in
                guard t < MP.M.RagiBeat.burst else { return }
                let origin = CGPoint(x: size.width / 2, y: size.height * 0.55)
                let fade = max(0, 1 - max(0, t - MP.M.RagiBeat.burst * 0.55) / (MP.M.RagiBeat.burst * 0.45))
                for piece in Self.pieces {
                    let x = origin.x + cos(piece.angle) * piece.speed * t
                    let y = origin.y + sin(piece.angle) * piece.speed * t + 420 * t * t
                    var c = canvas
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .radians(piece.spin * t))
                    c.opacity = fade
                    let s = piece.size
                    let path = piece.star ? Self.star(s) : Path(roundedRect: CGRect(x: -s / 2, y: -s / 3, width: s, height: s * 0.66),
                                                              cornerRadius: s * 0.15)
                    c.fill(path, with: .color(piece.star ? MPWorldTone.yellow.deep : piece.tone.deep))
                }
            }
        }
        .frame(width: 360, height: 360)
        .allowsHitTesting(false)
    }

    private static func star(_ r: Double) -> Path {
        PaperStar().path(in: CGRect(x: -r, y: -r, width: r * 2, height: r * 2))
    }
}

/// Beş köşeli, köşeleri hafif yuvarlak kâğıt yıldız.
struct PaperStar: Shape {
    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) / 2
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        for i in 0..<10 {
            let a = -Double.pi / 2 + Double(i) * .pi / 5
            let rr = i % 2 == 0 ? r : r * 0.48
            let pt = CGPoint(x: c.x + cos(a) * rr, y: c.y + sin(a) * rr)
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.closeSubpath()
        return p.strokedPath(StrokeStyle(lineWidth: r * 0.12, lineJoin: .round)).union(p)
    }
}

/// Masal sonunun sözleri. Klasiklerde çocuğun adı yok: "Bravo, !" yazılmaz.
enum StoryEndingCopy {
    static func bravo(_ name: String) -> String {
        let n = name.trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? "Bravo!" : "Bravo, \(n)!"
    }

    static func goodNight(_ name: String) -> String {
        let n = name.trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? "İyi geceler." : "İyi geceler, \(n)."
    }
}
