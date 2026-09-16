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

    var body: some View {
        ZStack {
            ReaderPaper(theme: theme)

            // Süsleme kâğıdın üstünde, metnin altında: okuma her zaman önde.
            if let decoration {
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
                VStack(spacing: 0) {
                    if page.imageRef != nil {
                        illustration(in: geo)
                        Spacer(minLength: MP.S.x6)
                    }
                    textColumn(in: geo)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, StoryPageView.gutter + ornament.contentInset)
                .padding(.top, MP.S.x5 + ornament.contentInset)
                .padding(.bottom, MP.S.x7 + ornament.contentInset)
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
    private func textColumn(in geo: GeometryProxy) -> some View {
        let available = geo.size.height
            - (page.imageRef != nil ? geo.size.height * 0.55 + MP.S.x6 : 0)

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
                            ink: theme.body
                        )
                        .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(paragraph)
                            .font(MP.F.read(readSize.points))
                            .lineSpacing(readSize.lineSpacing)
                            .foregroundStyle(theme.body)
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
                   alignment: page.imageRef == nil ? .center : .top)
            // Sayfa VoiceOver için tek parça: dört ayrı parça yerine sürekli
            // metin.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(page.spokenText)
            .accessibilityAddTraits(.isStaticText)
            .accessibilityTextContentType(.narrative)
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
