import SwiftUI

/// Okuyucunun kontrolleri (23 · Okuyucu, Pastel Masal).
///
/// Üstte kapat, favori ve okuma ayarları; altta teslimdeki kontrol çubuğu:
/// sayfa, ilerleme, önceki · sesli oku · sonraki. Çocuk sayfayı kıvrımla da
/// çevirebilir; çubuk okumayı bilmeyen çocuğun yolu. Kapat dışındaki her şey
/// okumaya dalınca kendiliğinden çekilir, sayfaya dokununca geri gelir.
///
/// **Kapat düğmesi bunun dışındadır ve hiç kaybolmaz.** Geri kalan kontroller
/// 4,5 saniye sonra çekiliyor; çıkış yolu da çekildiğinde, kapatmak isteyen
/// kişi düğmeyi kaybediyor ve geri getirmek için önce sayfaya dokunmak zorunda
/// kalıyor — dokunuşun kendisi de sayfayı çevirebildiği için bu bazen iki kez
/// oluyor. Bir okuma yüzeyi kendini karartabilir; çıkışını karartamaz.
///
/// Süreyi uzatmak bunu çözmez, yalnızca erteler: her sabit gecikmede çıkışın
/// kaybolduğu bir an vardır.
///
/// Yüzeyler iOS 26 düzeninde (21 Ekim 2026): kapat solda tek cam daire,
/// favori ve okuma ayarları sağda tek cam kapsül, altta tek cam çubuk. Cam
/// `mpGlassSurface`; gece temasında koyu cam.
///
/// İlerleme çizgisine basılı tutunca çubuk sayfa kaydırıcısına döner: üstünde
/// sayfaların küçük kâğıtları ve seçilen sayfanın ilk sözcükleri belirir,
/// parmak kalkınca o sayfaya gidilir. Sürüklerken titreşim yok.
///
/// Masalın başlığı burada yok. Kapakta söylendi; sayfanın üstünde tekrar etmesi
/// kitaptan çok uygulama gibi durur.
struct ReaderChrome: View {

    let theme: MP.ReadTheme
    let isFavorite: Bool
    let isSpeaking: Bool
    /// Geri kalan kontroller görünür mü. Kapat bundan bağımsızdır.
    var showsSecondary: Bool = true
    /// "Sayfa 2 / 8"; kapak ve kapanış yaprağında `nil`.
    var pageLabel: String? = nil
    var progress: Double = 0
    var canGoPrevious: Bool = false
    var canGoNext: Bool = false
    /// Son masal sayfasında ileri düğmesi bayrağa döner: masal sonu.
    var isLastPage: Bool = false
    let onClose: () -> Void
    let onToggleFavorite: () -> Void
    let onToggleSpeech: () -> Void
    let onOpenSettings: () -> Void
    var onPrevious: () -> Void = {}
    var onNext: () -> Void = {}

    /// Kaydırıcının önizlemesi: her masal sayfasının ilk sözcükleri.
    var pagePreviews: [String] = []
    /// Şu anki masal sayfası (0'dan); kapak ve kapanış yaprağında `nil`.
    var pageIndex: Int? = nil
    /// Kaydırıcıdan seçilen sayfaya git (0'dan).
    var onSeek: (Int) -> Void = { _ in }
    /// Kaydırma başladı (`true`) ya da bitti: okuyucu bu sırada kontrolleri çekmez.
    var onScrubbing: (Bool) -> Void = { _ in }

    /// Kaydırırken parmağın altındaki sayfa; kaydırılmıyorsa `nil`.
    @State private var scrubPage: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: MPSpacing.sm) {
                glassCircle(symbol: "xmark", label: "Kapat", action: onClose)
                    // Sönükleştirilmez: `.opacity(0.45)` varken dokunuş düğmeye
                    // değil alttaki sayfaya gidiyor, sayfa geri çevriliyordu.
                Spacer(minLength: MPSpacing.md)
                if showsSecondary {
                    HStack(spacing: 0) {
                        iconButton(symbol: isFavorite ? "heart.fill" : "heart",
                                   label: isFavorite ? "Favorilerden çıkar" : "Favorilere ekle",
                                   tint: isFavorite ? MPColor.brandPink : MPColor.textPrimary,
                                   action: onToggleFavorite)
                        iconButton(symbol: "textformat", label: "Okuma ayarları",
                                   tint: MPColor.textPrimary, action: onOpenSettings)
                    }
                    .padding(.horizontal, MP.S.x1)
                    .mpGlassSurface(in: Capsule(style: .continuous))
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.xxs)

            Spacer(minLength: 0)

            if showsSecondary, let pageLabel {
                VStack(spacing: MPSpacing.sm) {
                    if let scrubPage, pagePreviews.indices.contains(scrubPage) {
                        scrubPanel(scrubPage).transition(.opacity)
                    }
                    controlBar(pageLabel)
                }
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(MP.M.gated(MP.M.easeOut), value: scrubPage == nil)
        // Gece kâğıdında cam ve üstündeki yazı koyu tona geçer.
        .environment(\.colorScheme, theme == .night ? .dark : .light)
    }

    // MARK: - Üst

    private func glassCircle(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            MPIcon(symbol, size: MP.G.md, weight: .semibold)
                .foregroundStyle(MPColor.textPrimary)
                .frame(width: MP.S.tapMin, height: MP.S.tapMin)
                .mpGlassSurface(in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(label)
    }

    private func iconButton(symbol: String, label: String, tint: Color,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            MPIcon(symbol, size: MP.G.md, weight: .semibold)
                .foregroundStyle(tint)
                .frame(width: MP.S.tapMin, height: MP.S.tapMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle(.highlight))
        .accessibilityLabel(label)
    }

    // MARK: - Alt çubuk

    /// 23 · Okuyucu alt çubuğu: önceki · (sayfa, sesli oku, ilerleme) · sonraki.
    private func controlBar(_ label: String) -> some View {
        HStack(spacing: MPSpacing.xxs) {
            navButton(symbol: "chevron.left", label: "Önceki sayfa", enabled: canGoPrevious, action: onPrevious)
            VStack(spacing: MPSpacing.xxs) {
                HStack(spacing: MPSpacing.xs) {
                    Text(scrubPage.map { "Sayfa \($0 + 1)" } ?? label)
                        .mpText(.footnote).fontWeight(.heavy)
                        .foregroundStyle(MPColor.textSecondary)
                        .lineLimit(1)
                    Spacer(minLength: MPSpacing.xs)
                    speechButton
                }
                progressLine(label)
            }
            navButton(symbol: isLastPage ? "flag.checkered" : "chevron.right",
                      label: isLastPage ? "Masalı bitir" : "Sonraki sayfa",
                      enabled: canGoNext, action: onNext)
        }
        .padding(.horizontal, MPSpacing.xs)
        .padding(.vertical, MPSpacing.xxs)
        // Kapsül değil: en büyük yazı boyutunda çubuk uzarsa hap gibi şişmesin.
        .mpGlassSurface(in: RoundedRectangle(cornerRadius: MPRadius.hero, style: .continuous))
        .padding(.horizontal, MPSpacing.sm)
    }

    private var speechButton: some View {
        Button(action: onToggleSpeech) {
            HStack(spacing: MPSpacing.xxs) {
                MPIcon(isSpeaking ? "pause.fill" : "play.fill", size: MP.G.md, weight: .bold)
                Text(isSpeaking ? "Duraklat" : "Sesli oku")
                    .mpText(.footnote).fontWeight(.heavy)
                    .lineLimit(1)
            }
            .foregroundStyle(MPColor.actionPrimary)
            .frame(minHeight: MP.S.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle(.highlight))
        .accessibilityLabel(isSpeaking ? "Sesli okumayı duraklat" : "Sesli oku")
    }

    /// İnce ilerleme çizgisi; basılı tutunca kaydırıcı. VoiceOver'da
    /// yukarı/aşağı kaydırma bir sayfa ileri/geri gider.
    private func progressLine(_ label: String) -> some View {
        GeometryReader { geo in
            let count = max(pagePreviews.count, 1)
            let shown = scrubPage.map { Double($0 + 1) / Double(count) } ?? progress
            Capsule().fill(MPColor.readerDayTrack)
                .frame(height: scrubPage == nil ? MP.S.x1 : MP.S.x2)
                .overlay(alignment: .leading) {
                    Capsule().fill(MPColor.actionPrimary)
                        .frame(width: max(MP.S.x2, geo.size.width * shown))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(scrubGesture(width: geo.size.width))
        }
        .frame(height: MP.S.x6)
        .accessibilityElement()
        .accessibilityLabel("Sayfa")
        .accessibilityValue(label)
        .accessibilityAdjustableAction { direction in
            guard let pageIndex else { return }
            switch direction {
            case .increment: if pageIndex + 1 < pagePreviews.count { onSeek(pageIndex + 1) }
            case .decrement: if pageIndex > 0 { onSeek(pageIndex - 1) }
            @unknown default: break
            }
        }
    }

    private func scrubGesture(width: CGFloat) -> some Gesture {
        LongPressGesture(minimumDuration: 0.25)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                guard case .second(true, let drag) = value, !pagePreviews.isEmpty else { return }
                if scrubPage == nil { onScrubbing(true) }
                let page: Int
                if let drag {
                    let fraction = drag.location.x / max(width, 1)
                    page = min(pagePreviews.count - 1, max(0, Int(fraction * CGFloat(pagePreviews.count))))
                } else {
                    page = pageIndex ?? 0
                }
                if scrubPage != page { scrubPage = page }
            }
            .onEnded { _ in
                if let scrubPage, scrubPage != pageIndex { onSeek(scrubPage) }
                scrubPage = nil
                onScrubbing(false)
            }
    }

    /// Kaydırırken çubuğun üstünde: seçilen sayfa çevresindeki küçük kâğıtlar
    /// ve o sayfanın ilk sözcükleri. Sayfaların çoğu çizimsiz, bu yüzden
    /// küçük resim değil sözcük.
    private func scrubPanel(_ page: Int) -> some View {
        let window = max(0, page - 2)...min(pagePreviews.count - 1, page + 2)
        return VStack(alignment: .leading, spacing: MPSpacing.sm) {
            HStack(alignment: .bottom, spacing: MPSpacing.xs) {
                ForEach(Array(window), id: \.self) { i in
                    let on = i == page
                    Text("\(i + 1)")
                        .font(MP.F.caption())
                        .foregroundStyle(on ? theme.foreground : theme.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: on ? MP.S.x9 : MP.S.x8)
                        .background(theme.paper, in: RoundedRectangle(cornerRadius: MPRadius.xs))
                        .overlay(RoundedRectangle(cornerRadius: MPRadius.xs)
                            .strokeBorder(on ? MPColor.actionPrimary : MPColor.borderKid, lineWidth: on ? 2 : 1))
                }
            }
            .accessibilityHidden(true)
            Text(pagePreviews[page])
                .mpText(.body).foregroundStyle(MPColor.textPrimary)
                .lineLimit(2)
        }
        .padding(MPSpacing.md)
        .mpGlassSurface(in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
        .padding(.horizontal, MPSpacing.sm)
        .accessibilityElement(children: .combine)
    }

    private func navButton(symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            MPIcon(symbol, size: 24, weight: .bold)
                .foregroundStyle(enabled ? MPColor.textPrimary : MPColor.textTertiary)
                .frame(width: MPSize.minTouchKid, height: MPSize.minTouchKid)
                .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}
