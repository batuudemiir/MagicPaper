import SwiftUI

/// 25 · Masal sonu (`MasalSonu`): kitabın kapanış yaprağı, tam ekran bir an (8 Kasım 2026).
///
/// Son sayfayı çevirerek varılır; okuyucu kendini kapatmaz. Sayfa kaymaz: her şey tek
/// ekrana sığar, yalnızca en büyük yazı boyutlarında kaydırmaya düşer.
///
/// Gündüz bir başarı anı: Ragi sevinçle zıplar, arkasında kâğıt yıldızlar bir kez
/// patlar, kısa ses ve tek titreşim; kazanılanlar (ilk kez bitiyorsa yıldız, üst üste
/// günler, yeni kelimeler, rozet) tek tek sesle belirir. Sonra Ragi'nin balonu bir soru
/// sorar ("Birlikte konuşalım", puansız). Tek yol: "Ana sayfaya dön". FAZ 13:
/// seri devam ettirilebiliyorsa "Devam ettir" burada. Künye kazanılanların altında.
///
/// 23 Kasım 2026 (İrem, yeni gündüz tasarımı; prototip `design-preview/app/ending.js`):
/// mor zemin (`MP.C.endingSky`), "Masal bitti!", ışık hüzmeleri önünde sevinçli Ragi
/// (`Mascot.cheer`), "Bravo, <ad>!", yatay kayan kazanılanlar
/// (çıkartma, masalın rozeti, yıldız, kelimeler), Ragi'nin sorusu tek
/// satır, en altta "Ana sayfaya dön" ("Bitir"in yerine). Rozet anı, gece yaprağı, seri,
/// bilgi ve künye aynen; gece yaprağı değişmedi.
///
/// 24 Kasım 2026 (Batuhan): "Bir masal daha" ve haftalık dakika kartı kalktı. Masal
/// bitirmek bir olay; hemen yenisi önerilmez, çocuğa okuma süresi gösterilmez.
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
    var onGoodNight: () -> Void = {}

    @EnvironmentObject private var app: MPAppState
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
    /// Gündüz rozet/kat anı geçildi mi (rozet planı R4).
    @State private var momentDone = false

    var body: some View {
        ZStack {
            // Gündüz mor zemin (23 Kasım 2026, İrem'in yeni masal sonu); gece kâğıt.
            if isBedtime {
                ReaderPaper(theme: theme)
            } else {
                LinearGradient(stops: MP.C.endingSky, startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
            ViewThatFits(in: .vertical) {
                column
                ScrollView(showsIndicators: false) { column }
            }
            // Rozet planı R4: gündüz yeni rozet ya da kat varsa önce tam ekran an.
            if showsMoment {
                MPAwardMoment(badges: news.fresh, levels: news.freshStarLevels, theme: theme,
                              isCurrent: isCurrent, onContinue: finishMoment)
                    .transition(.opacity)
            }
            if fadingToNight {
                MP.Palette.murekkep900.ignoresSafeArea()
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Masal bitti")
        .task(id: "\(isCurrent)-\(momentDone)") {
            guard isCurrent, !celebrated, !showsMoment else { return }
            celebrated = true
            // Gece sessiz satır da bir kez gösterilmiş sayılır.
            if isBedtime { markAwardsSeen() }
            await celebrate(fanfare: !hadMoment)
        }
    }

    private var isBedtime: Bool { MPBedtime.isBedtime(settings: settings) }

    private var hasAwards: Bool { !news.fresh.isEmpty || !news.freshStarLevels.isEmpty }
    /// Anın yalnızca gündüz ve yalnızca bir kez gösterildiği.
    private var hadMoment: Bool { hasAwards && !isBedtime }
    private var showsMoment: Bool { hadMoment && !momentDone }

    private func finishMoment() {
        guard !momentDone else { return }
        markAwardsSeen()
        withAnimation(MP.M.gated(MP.M.base) ?? MP.M.slow) { momentDone = true }
    }

    private func markAwardsSeen() {
        guard let child = story.childProfileID, hasAwards else { return }
        MPBadgeStore().markSeen(news.fresh.map(\.id) + news.freshStarLevels.map(\.id), for: child)
    }

    /// Yıldız puanı (rozet planı 5b): harcamayla düşmez.
    private var starScore: Int? {
        ProfileManager.shared.currentProfile.map {
            MPStars.score(for: $0, stories: StoryGenerationManager.shared.stories)
        }
    }

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
    ///
    /// 23 Kasım 2026 (İrem, yeni masal sonu): sıra çıkartma, masalın rozeti,
    /// yıldız, yeni kelimeler; yatay kayar, ortadan
    /// başlar. Rozet gündüz tam ekran anda söylendiyse de burada küçük kartıyla
    /// durur (kazanılanların hepsi bir arada). Üst üste günler Okuma yolculuğum'da.
    private var earned: [Earned] {
        let others = StoryGenerationManager.shared.stories.filter {
            $0.id != story.id && $0.childProfileID == story.childProfileID
        }
        let words = MPVocabulary.newWordCount(in: story, comparedTo: others)
        let badge = news.fresh.first
        return StoryEndingEarned.ids(isFinished: story.isFinished, hasBadge: badge != nil, newWords: words)
            .compactMap { id -> Earned? in
                switch id {
                case "sticker":
                    // Faz 9: masalın çıkartması albüme girer (okumaya yakın ödül).
                    return .init(id: id, icon: "star", tone: .lav, value: "Çıkartma", label: "albümüne eklendi")
                case "badge":
                    guard let badge else { return nil }
                    return .init(id: id, icon: badge.icon, tone: badge.tone, value: badge.title, label: "yeni rozet")
                case "star":
                    return .init(id: id, icon: "star.fill", tone: .yellow, value: "+1",
                                 label: starScore.map { "yıldız · toplam \($0)" } ?? "yıldız")
                case "words":
                    return .init(id: id, icon: "book.closed", tone: .sky, value: "\(words)", label: "yeni kelime")
                default:
                    return nil
                }
            }
    }

    private var question: String? { StoryTalkPrompts.questions(for: story).first }

    /// Sıra: 1 Ragi ve başlık, sonra her kazanılan, en son Ragi'nin sorusu.
    /// Rozet anı az önce titreşimi ve sesi verdiyse burada tekrar verilmez:
    /// eylem başına bir titreşim.
    private func celebrate(fanfare: Bool = true) async {
        let total = earned.count + 2
        if reduceMotion || isBedtime {
            withAnimation(MP.M.slow) { revealed = total }
            return
        }
        if fanfare {
            MPHaptics.storyEnding()
            MPSound.play(.ending)
        }
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

    /// 23 Kasım 2026 (İrem; referans: oyunlardaki "Level up" ekranı, prototip
    /// `design-preview/app/ending.js`): mor zeminde "Masal bitti!", ışık hüzmeleri
    /// ve sıcak parıltı önünde sevinçli Ragi, "Bravo, <ad>!",
    /// yatay kayan kazanılanlar, Ragi'nin sorusu, bilgi, künye, seri ve en altta
    /// "Ana sayfaya dön". Yazılar `MP.C.textOnArt`; kâğıt dili bileşenler gece
    /// temasıyla (`onSky`) okunur kalır.
    private var dayColumn: some View {
        VStack(spacing: MPSpacing.lg) {
            Spacer(minLength: MP.S.navBarHeight)

            Text("Masal bitti!").font(MP.F.displayXL()).foregroundStyle(MP.C.textOnArt)
                .multilineTextAlignment(.center)
                .opacity(revealed > 0 ? 1 : 0)
                .accessibilityAddTraits(.isHeader)

            hero

            VStack(spacing: MPSpacing.xs) {
                Text(StoryEndingCopy.bravo(story.childName)).mpText(.cover).foregroundStyle(MP.C.textOnArt)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text("\(story.title) masalını bitirdin.")
                    .mpText(.supporting).foregroundStyle(MP.C.textOnArtMuted)
                    .multilineTextAlignment(.center)
            }
            .opacity(revealed > 0 ? 1 : 0)

            earnedRow

            if let question, revealed >= earned.count + 2 { talkLine(question) }

            // Faz 21: masalın tek gerçek bilgisi, yalnızca gündüz.
            if let fact = story.fact { factLeaf(fact) }

            if StoryColophon.hasDedication(story) { colophon }

            SeriesEndingSection(story: story, theme: onSky, accent: MP.C.textOnArt)

            Spacer(minLength: MPSpacing.md)

            MPButton(title: "Ana sayfaya dön", systemImage: "house", kind: .onArt, action: goHome)
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, StoryPageView.gutter)
        .padding(.bottom, MPSpacing.xl)
    }

    /// Mor zemindeki kâğıt dili bileşenler (bilgi, künye, seri) gece temasının
    /// açık yazısıyla okunur; gece masal sonu okuyucunun kendi teması.
    private var onSky: MP.ReadTheme { isBedtime ? theme : .night }

    /// Ragi ve arkasındaki ışık: hüzmeler ve sıcak parıltı yerleşimi büyütmez.
    private var hero: some View {
        ZStack {
            if burst && !reduceMotion { PaperBurst().accessibilityHidden(true) }
            MascotImage(mascot: .cheer, width: MPSize.minTouchHero * 3, act: isCurrent ? .cheer : .still)
                .scaleEffect(revealed > 0 || reduceMotion ? 1 : 0.7)
                .opacity(revealed > 0 ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: MPSize.minTouchHero * 3 + MPSpacing.xl)
        .background {
            ZStack {
                EndingRays().fill(MP.C.textOnArt.opacity(0.1))
                    .frame(width: MPSize.minTouchHero * 7, height: MPSize.minTouchHero * 7)
                    .mask(RadialGradient(colors: [MP.C.textOnArt, MP.C.textOnArt.opacity(0)],
                                         center: .center, startRadius: MPSize.minTouchHero,
                                         endRadius: MPSize.minTouchHero * 3.3))
                Circle()
                    .fill(RadialGradient(colors: [MPWorldTone.yellow.soft.opacity(0.75), MPWorldTone.yellow.soft.opacity(0)],
                                         center: .center, startRadius: MPSpacing.lg, endRadius: MPSize.minTouchHero * 1.8))
                    .frame(width: MPSize.minTouchHero * 3.6, height: MPSize.minTouchHero * 3.6)
            }
            .scaleEffect(revealed > 0 || reduceMotion ? 1 : 0.4)
            .opacity(revealed > 0 ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .accessibilityHidden(true)
    }

    /// Ragi'nin sorusu (Birlikte konuşalım, puansız): kazanılanlar bitince tek satır.
    private func talkLine(_ text: String) -> some View {
        Text(text).mpText(.supporting).fontWeight(.semibold).foregroundStyle(MP.C.textOnArt)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, MPSpacing.lg)
            .padding(.vertical, MPSpacing.sm)
            .background(MP.C.textOnArt.opacity(0.14), in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
            .transition(.opacity)
            .accessibilityLabel("Birlikte konuşalım: \(text)")
    }

    /// Okuyucu kapanır, çocuk ana sayfada.
    private func goHome() {
        app.router.tab = .home
        onClose()
    }

    /// Yatay kayar, ortadan başlar (referanstaki gibi iki yanda kartlar görünür).
    @ViewBuilder
    private var earnedRow: some View {
        let items = earned
        if !items.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MPSpacing.sm) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        let shown = revealed >= index + 2
                        tile(item, shown: shown)
                            .frame(width: MPSize.minTouchHero * 2)
                            .opacity(shown ? 1 : 0)
                            .scaleEffect(shown || reduceMotion ? 1 : 0.6)
                            .offset(y: shown || reduceMotion ? 0 : MPSpacing.md)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .defaultScrollAnchor(.center)
            .contentMargins(.horizontal, MPSpacing.xl, for: .scrollContent)
            .padding(.horizontal, -StoryPageView.gutter)
        }
    }

    private func tile(_ item: Earned, shown: Bool) -> some View {
        VStack(spacing: MP.S.x1) {
            Group {
                if item.id == "sticker" {
                    StickerView(sticker: MPSticker(id: story.id.uuidString, title: story.title,
                                                   art: LibraryShelfModel.coverArt(story), date: Date()),
                                size: 56)
                } else if item.id == "star" {
                    // Yıldız dolu ve büyük: kazanılanın en parlak anı. Yerine dönerek oturur.
                    PaperStar().fill(MPWorldTone.yellow.deep)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(shown || reduceMotion ? 0 : -120))
                } else {
                    MPIconTile(systemImage: item.icon, tone: item.tone, size: 44, filled: true)
                }
            }
            .accessibilityHidden(true)
            Text(item.value).mpText(.cardTitle).foregroundStyle(MP.C.textOnArt)
                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
            Text(item.label).mpText(.footnote).foregroundStyle(MP.C.textOnArtMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: MPSize.minTouchHero * 2)
        .padding(.vertical, MPSpacing.md)
        .padding(.horizontal, MPSpacing.xs)
        // Mor zeminde açık, yarı saydam kart: kâğıt değil gök (23 Kasım 2026).
        .background(MP.C.textOnArt.opacity(0.14), in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous)
            .strokeBorder(MP.C.textOnArt.opacity(0.22), lineWidth: 1))
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

            if let level = news.freshStarLevels.last {
                badgeRow("star.fill", tone: .yellow, title: level.title, caption: "Yeni yıldız katın")
            }
            if let badge = news.fresh.first {
                badgeRow(badge.icon, tone: badge.tone, title: badge.title,
                         caption: news.fresh.count > 1 ? "Yeni rozet, \(news.fresh.count - 1) tane daha" : "Yeni rozet")
            }

            // Faz 11: akşam sırası yankılanır; masal az önce işaretlendi.
            if settings.bedtimeRoutine {
                BedtimeRoutineCard(interactive: false, foreground: theme.foreground, muted: theme.muted)
            }

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
    private func badgeRow(_ icon: String, tone: MPWorldTone, title: String, caption: String) -> some View {
        HStack(spacing: MPSpacing.md) {
            MPIconTile(systemImage: icon, tone: tone, size: 42, filled: false)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MP.S.x1) {
                Text(title).mpText(.section).foregroundStyle(theme.foreground)
                Text(caption).mpText(.footnote).foregroundStyle(theme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(MPSpacing.md)
        .background(theme.foreground.opacity(0.06), in: RoundedRectangle(cornerRadius: MPRadius.card))
        .accessibilityElement(children: .combine)
    }

    /// Masalın sonunda tek bir gerçek bilgi (30 Ekim 2026). Kutucuk değil, sessiz
    /// bir satır. Kaynak yalnızca varsa görünür ve tıklanmaz (çocuk alanında dış
    /// bağlantı yok). Uyku yaprağında yok.
    private func factLeaf(_ fact: StoryFact) -> some View {
        VStack(spacing: MP.S.x2) {
            Text("Bunu biliyor muydun?")
                .font(MP.F.labelSM(.semibold))
                .foregroundStyle(onSky.muted)
            Text(fact.statement)
                .mpText(.supporting)
                .foregroundStyle(onSky.foreground)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let source = fact.sourceName {
                Text("Kaynak: \(source)")
                    .font(MP.F.caption())
                    .foregroundStyle(onSky.muted)
                    .multilineTextAlignment(.center)
            }
        }
        .opacity(revealed >= earned.count + 2 ? 1 : 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bunu biliyor muydun? \(fact.statement)" + (fact.sourceName.map { " Kaynak: \($0)." } ?? ""))
    }

    /// Kitabın son sayfasındaki künye: "MagicPaper Kitaplığı · İrem'in 12. masalı".
    private var colophon: some View {
        let ordinal = StoryColophon.ordinal(of: story, among: StoryGenerationManager.shared.stories)
        return Text(StoryColophon.colophon(childName: story.childName, ordinal: ordinal))
            .font(MP.F.labelSM(.semibold))
            .foregroundStyle(onSky.muted)
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

/// Masal sonunda Ragi'nin arkasındaki ışık hüzmeleri (23 Kasım 2026): merkezden
/// çıkan eşit dilimler. Dönmez; maskeyle kenara doğru söner. Süs.
struct EndingRays: Shape {
    var count = 16

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = max(rect.width, rect.height) / 2
        let step = 2 * Double.pi / Double(count)
        var p = Path()
        for i in 0..<count {
            let start = Double(i) * step
            p.move(to: center)
            p.addArc(center: center, radius: radius, startAngle: .radians(start),
                     endAngle: .radians(start + step * 0.42), clockwise: false)
            p.closeSubpath()
        }
        return p
    }
}

/// Masal sonunda kazanılanların sırası (24 Kasım 2026): çıkartma, masalın rozeti,
/// yıldız, yeni kelimeler. Okuma süresi burada yok; o ebeveynin özetinde.
enum StoryEndingEarned {
    static func ids(isFinished: Bool, hasBadge: Bool, newWords: Int) -> [String] {
        var ids: [String] = []
        if !isFinished { ids.append("sticker") }
        if hasBadge { ids.append("badge") }
        if !isFinished { ids.append("star") }
        if newWords > 0 { ids.append("words") }
        return ids
    }
}
