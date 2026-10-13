import SwiftUI

/// Bir masal sayfası, dizilmiş hâlde.
///
/// Kart değil. Yuvarlak köşesi, kenar boşluğu içinde ikinci bir yüzeyi, gölgesi
/// yok — sayfanın kendisi baştan başa kâğıt, metin doğrudan onun üstünde. §7'nin
/// "sayfayı yuvarlak bir uygulama kartı gibi ele alma" dediği şey bu, ve sayfa
/// kıvrımının da çalışması için gereken şey aynı şey.
struct StoryPageView: View {

    let page: ReaderPage
    let theme: MP.ReadTheme
    let readSize: MP.ReadSize
    let folio: String?
    /// Kontroller görünürken alt künye de görünür (§11).
    let showsFolio: Bool
    /// Masalın dünya rengi — süslemeler bunu kullanır.
    let accent: Color
    /// Masalın dünya işareti — başlık vinyeti bunu kullanır.
    let symbol: String
    let ornament: ReaderPageOrnament
    /// Sayfanın süsleme bağlamı. Nil ise süsleme çizilmez.
    var decoration: StoryDecorationContext? = nil
    /// Geliştirici katmanı.
    var showsDecorationDebug: Bool = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ZStack {
            ReaderPaper(theme: theme)

            // Süsleme kâğıdın üstünde, metnin altında: okuma her zaman önde.
            // En büyük yazı boyutlarında metin sayfayı doldurur; süs çizilmez.
            if let decoration, !typeSize.isAccessibilitySize {
                StoryPageDecorationLayer(
                    context: decoration,
                    tint: theme.muted,
                    showsDebug: showsDecorationDebug
                )
            }

            if ornament == .spot {
                VStack {
                    HStack {
                        Spacer(minLength: 0)
                        SpotOrnament(symbol: symbol, accent: accent)
                            .padding(.trailing, MP.S.x5)
                            .padding(.top, MP.S.x8)
                    }
                    Spacer(minLength: 0)
                }
            }

            if ornament == .cerceve {
                PageFrameOrnament(accent: accent)
                    .padding(.horizontal, StoryPageView.gutter - MP.S.x3)
                    .padding(.vertical, MP.S.x7)
            }

            GeometryReader { geo in
                if isSpread(geo) {
                    spread(in: geo)
                } else {
                VStack(spacing: 0) {
                    if page.hasIllustration {
                        illustration(in: geo)
                        Spacer(minLength: MP.S.x6)
                    }
                    textColumn(in: geo)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, StoryPageView.gutter + ornament.contentInset)
                // Üst denetimlerin (kapat, kalp, Aa) altından başlar; en büyük
                // yazı boyutunda metin kapat düğmesinin altına akmaz.
                .padding(.top, MP.S.navBarHeight + ornament.contentInset)
                .padding(.bottom, MP.S.x7 + ornament.contentInset)
                }
            }

            folioLine
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(pageAccessibilityLabel)
    }

    /// Dış kenar boşluğu.
    ///
    /// `MPStoryPDF` A5'i 40/420 ≈ %9,5 ile basıyor; 393 puntoluk bir iPhone'da
    /// bu ~37 punto eder. `MP.S.x7` en yakın token ve her boyutta doğru okunuyor.
    static let gutter: CGFloat = MP.S.x7

    /// Satır uzunluğu sınırı.
    ///
    /// Geniş bir iPhone'da 20 kelimelik satırlar basılmasın diye: göz satır
    /// sonundan başına dönerken yerini kaybeder ve çocuk için bu, okumayı
    /// bırakma sebebidir.
    private var measure: CGFloat { readSize.points * 30 }

    // MARK: - Çizim

    @ViewBuilder
    private func illustration(in geo: GeometryProxy) -> some View {
        if let scene = page.scene {
            StorySceneView(scene: scene)
                .frame(height: sceneHeight(in: geo))
                .frame(maxWidth: .infinity)
        } else {
            fileIllustration(in: geo)
        }
    }

    /// Hazır sahnenin yüksekliği (B2): sütun genişliğinde 4:3, ama hiçbir
    /// zaman kullanılabilir yüksekliğin %55'inden fazla değil. Kare kutuyu
    /// doldurmaz; metne yer bırakır (docs/B2_SCENE_LIBRARY_PLAN.md §5.2).
    private func sceneHeight(in geo: GeometryProxy) -> CGFloat {
        let column = geo.size.width - 2 * (StoryPageView.gutter + ornament.contentInset)
        return min(column / StorySceneView.aspectRatio, geo.size.height * 0.55)
    }

    /// Metin sütununun çizime bıraktığı yükseklik.
    private func illustrationReserve(in geo: GeometryProxy) -> CGFloat {
        page.scene != nil ? sceneHeight(in: geo) : geo.size.height * 0.55
    }

    @ViewBuilder
    private func fileIllustration(in geo: GeometryProxy) -> some View {
        // §8'in hedefi kullanılabilir yüksekliğin %45–55'i. Hedef, katı kural
        // değil: yazı boyutu büyüdükçe önce çizim yer verir, çünkü §14 hiçbir
        // durumda okunabilirliğin feda edilmemesini söylüyor.
        let height = min(max(geo.size.height * 0.50, geo.size.height * 0.34),
                         geo.size.height * 0.55)

        PageIllustration(
            fileName: page.imageRef ?? "",
            label: page.imageLabel,
            theme: theme
        )
        .frame(height: height)
    }

    // MARK: - 27 · iPad yatay açık kitap

    /// iPad yatayda (geniş boyut sınıfı, yatay sayfa) sayfa açık kitap olur:
    /// solda resim, sağda metin, ortada sırt gölgesi. En büyük yazı
    /// boyutlarında metin tüm genişliği alır.
    private func isSpread(_ geo: GeometryProxy) -> Bool {
        sizeClass == .regular && geo.size.width > geo.size.height * 1.15 && !typeSize.isAccessibilitySize
    }

    private func spread(in geo: GeometryProxy) -> some View {
        let half = geo.size.width / 2
        return HStack(spacing: 0) {
            spreadArt
                .frame(width: half, height: geo.size.height)
                .clipped()
                .accessibilityHidden(page.imageLabel == nil)
            GeometryReader { right in
                textColumn(in: right, reservesArt: false)
                    .padding(.horizontal, StoryPageView.gutter + MP.S.x4)
                    .padding(.top, MP.S.navBarHeight)
                    .padding(.bottom, MP.S.x7)
            }
            .frame(width: half, height: geo.size.height)
            // Kitabın sırtı: kâğıt gölgelemesi (malzeme taklidi).
            .overlay(alignment: .leading) {
                LinearGradient(colors: [MPColor.shadowInk.opacity(0.10), MPColor.shadowInk.opacity(0)],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(width: MP.S.x8)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    /// Sol sayfa: masalın resmi; resimsiz masalda dünyanın işareti, dünya
    /// renginde bir kapak sanatı gibi.
    @ViewBuilder
    private var spreadArt: some View {
        if let scene = page.scene {
            StorySceneView(scene: scene)
                .aspectRatio(StorySceneView.aspectRatio, contentMode: .fill)
        } else if let file = page.imageRef {
            PageIllustration(fileName: file, label: page.imageLabel, theme: theme)
        } else {
            ZStack {
                LinearGradient(colors: [accent.opacity(0.22), accent.opacity(0.55)],
                               startPoint: .top, endPoint: .bottom)
                MPIcon(symbol, size: 120, weight: .light)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }

    // MARK: - Metin

    /// Metin sütunu.
    ///
    /// Kaydırılabilir olması, eski üretim hattından gelen masallar yüzünden:
    /// onların sayfaları 1500 karaktere kadar çıkabiliyor ve sabit bir sayfada
    /// alt kısmı okunamadan kesiliyordu. Yeni motor sayfaları zaten kısa
    /// kesiyor, dolayısıyla tipik masalda kaydırma hiç devreye girmez —
    /// `.basedOnSize` içerik sığdığında sekmeyi de kapatır, yani sığan sayfa
    /// sabit bir sayfa gibi davranır.
    ///
    /// Sığan metin optik olarak ortalanır; sığmayan metin yukarıdan akar.
    /// Yeni kelimenin rengi: okuma temasının kahraman adı tonu (teslimde
    /// `reader.*.heroName`), üç temada da kâğıda karşı okunur.
    private var wordHighlight: Color {
        switch theme {
        case .light: return MPColor.readerDayHeroName
        case .sepia: return MPColor.readerSepiaHeroName
        case .night: return MPColor.readerNightHeroName
        }
    }

    private func textColumn(in geo: GeometryProxy, reservesArt: Bool = true) -> some View {
        let available = geo.size.height
            - (reservesArt && page.hasIllustration ? illustrationReserve(in: geo) + MP.S.x6 : 0)

        return ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: readSize.points * 0.55) {
                if !page.title.isEmpty {
                    Text(page.title)
                        .font(MP.F.displaySM())
                        .mpTightTracking(21)
                        .foregroundStyle(theme.foreground)
                        .padding(.bottom, MP.S.x1)
                }

                // Paragraflar ayrı ayrı dizilir. `lineSpacing` tek başına
                // paragrafı satırdan ayırt edemez; diyalog da böylece balonsuz
                // ve ikinci bir yazı stili olmadan ayrılır (§15).
                ForEach(Array(page.paragraphs.enumerated()), id: \.offset) { index, paragraph in
                    if ornament == .versal && index == 0 {
                        VersalParagraph(
                            text: paragraph,
                            size: readSize.points,
                            accent: accent,
                            ink: theme.body,
                            words: page.words,
                            highlight: wordHighlight
                        )
                        .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(ReaderWords.attributed(paragraph, words: page.words, size: readSize.points,
                                                    ink: theme.body, highlight: wordHighlight))
                            .lineSpacing(readSize.lineSpacing)
                            .tint(wordHighlight)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if ornament == .versal {
                    TailpieceOrnament(accent: accent)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, MP.S.x3)
                }
            }
            .frame(maxWidth: measure, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Sığdığında ortalanır, taştığında yukarıdan başlar.
            .frame(minHeight: max(available, 0),
                   alignment: reservesArt && page.hasIllustration ? .top : .center)
            // Sayfa VoiceOver için tek parça: dört ayrı parça yerine sürekli
            // metin.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(page.spokenText)
            .accessibilityAddTraits(.isStaticText)
            .accessibilityTextContentType(.narrative)
            .modifier(WordActions(words: ReaderWords.words(in: page.paragraphs, from: page.words)))
            .environment(\.openURL, OpenURLAction { url in
                ReaderWordSelection.shared.handle(url, in: page.words)
            })
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }

    // MARK: - Künye

    @ViewBuilder
    private var folioLine: some View {
        if let folio {
            VStack {
                Spacer(minLength: 0)
                Text(folio)
                    .font(MP.F.caption())
                    .foregroundStyle(theme.muted)
                    .opacity(showsFolio ? 0.75 : 0)
                    .animation(MP.M.gated(MP.M.easeOut), value: showsFolio)
                    .padding(.bottom, MP.S.x2)
            }
            .accessibilityHidden(true)   // konum, sayfa etiketinde zaten var
        }
    }

    private var pageAccessibilityLabel: String {
        guard let folio else { return "Masalın sonu" }
        return "Sayfa \(folio.replacingOccurrences(of: " / ", with: ", toplam "))"
    }
}

// MARK: - Çizim yükleme

/// Sayfanın çizimi.
///
/// Yükleme asenkron; beklerken dönen bir çark değil kâğıt gösterilir. Bir
/// kitabın sayfası yüklenmez, oradadır — ve 200 ms'lik bir çark o izlenimi
/// bozacak tek şeydir.
private struct PageIllustration: View {

    let fileName: String
    let label: String?
    let theme: MP.ReadTheme

    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        // Çerçevesiz, neredeyse köşesiz: çizim kâğıdın üstünde
                        // metinle aynı kenar boşluklarını paylaşır, listedeki
                        // bir küçük resim gibi kutulanmaz (§12).
                        .clipShape(RoundedRectangle(cornerRadius: MP.R.sm, style: .continuous))
                } else {
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task(id: fileName) {
                guard !fileName.isEmpty else { return }
                let width = geo.size.width * UIScreen.main.scale
                let loaded = await ReaderImageLoader.shared.image(
                    named: fileName, targetPixelWidth: width
                )
                withAnimation(MP.M.gated(MP.M.easeOut)) { image = loaded }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(label ?? "")
        .accessibilityHidden(label == nil)
    }
}


/// VoiceOver: sayfa tek parça okunur; her yeni kelime bir eylem olarak
/// eklenir ("Yeni kelime: müjdelemek"), seçilince kartı açar.
private struct WordActions: ViewModifier {
    let words: [StoryWord]
    func body(content: Content) -> some View {
        words.reduce(AnyView(content)) { view, word in
            AnyView(view.accessibilityAction(named: "Yeni kelime: \(word.term)") {
                ReaderWordSelection.shared.selected = word
            })
        }
    }
}
