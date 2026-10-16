import SwiftUI

/// Masalın kapağı — uygulamadaki **tek** kapak.
///
/// Eskiden iki ayrı kapak vardı: yaratma akışında kart içine yerleştirilmiş
/// bir "görsel kapak", okuyucuda ise tam sayfa bir kapak yaprağı. Aynı masalın
/// iki farklı kapağı olması, kapağı kitabın kapağı değil ekranın süsü hâline
/// getiriyordu. Artık tek bileşen: kapak neredeyse orada aynı kapak.
///
/// Kapak, masalın birinci sayfası değildir. Okuyucuda künye "1 / 8"e kapaktan
/// *sonra* başlar; kapak çevrilerek geçilir, tıpkı basılı kitapta olduğu gibi.
///
/// ## Başlık nerede durur — ve illüstrasyonun sessiz bandı
///
/// Düzen: illüstrasyon üstte (yaklaşık üst %56), hemen altında yay başlık,
/// marka satırı, en altta künye. **Başlık illüstrasyonun ALTINDA kalır ve
/// illüstrasyonun ÜSTÜNE BİNMEZ.** Bu bilinçli: başlık, kitabın tipografisine
/// girişin ilk cümlesi; resmin üstüne konduğunda kapak bir afişe, resim de
/// başlığın arka planına dönüşür. Aşağıda durduğunda ise resim resim olarak,
/// başlık da bir levha yazısı olarak okunur.
///
/// Buna rağmen üretilecek illüstrasyonun `textSafeArea`'sı **alt bant**tır
/// (`Cover.textSafeBand`). Başlık resmin içine girmiyorsa neden bir bant
/// ayrılıyor:
///
/// 1. **Kırpma.** `artwork` görseli `scaledToFill` + `clipped` ile
///    `width × min(width·1.32, height·0.56)` çerçevesine oturtuyor; bu çerçeve
///    cihaza göre 3:4 civarında oynuyor. Merkezden kırpma, alt kenara yakın
///    duran bir yüzü ya da odak nesnesini kesebilir. Alt bandın boş tutulması,
///    kırpmanın hiçbir cihazda bir şeyin başını kesmemesini sağlar.
/// 2. **Bitişiklik.** Kalabalık bir alt kenarın hemen altına oturan yay
///    başlık, resimle yarışır. Bant "buraya yazı gelecek" demiyor; "burası
///    sakin kalsın" diyor — detaysız, yüzsüz, düşük kontrastlı bir zemin.
///
/// Kapak V1 **3:4** ile çıkar. `AspectRatio`'ya 2:3 eklenmedi: o enum
/// sağlayıcı tarafında exhaustive `switch`lerle tüketiliyor ve buradaki
/// çerçeve zaten 3:4'e oturuyor.
///
/// Yay başlık (`MPArcText`) illüstrasyonlu kapakta da kalır: kart yüzüyle
/// (`StoryCoverFace`) aynı tipografik imza, rafta ve okuyucuda aynı kitap.
struct StoryCover: View {

    /// İllüstrasyonun sessiz bırakılması istenen bandı — kadraj kesirleri,
    /// sol üstten. İllüstrasyon üretimi tarafındaki kompozisyon kuralı bunu
    /// `SafeArea` olarak taşır.
    enum Cover {
        static let textSafeBand = (x: 0.06, y: 0.76, width: 0.88, height: 0.20)
    }


    let title: String
    let childName: String
    let pageCount: Int
    /// Kapak illüstrasyonu. Yoksa masalın dünya işareti çizilir.
    let coverAsset: String?
    /// Görseli olmayan masalın kapağı için.
    var symbol: String = "book"
    var accent: Color = MP.C.brand
    /// Generative mosaic cover for text-only stories.
    var mosaicCover: MagicPaperCoverConfiguration? = nil
    var theme: MP.ReadTheme = .light

    var body: some View {
        ZStack {
            ReaderPaper(theme: theme)

            GeometryReader { geo in
                let gutter = StoryPageView.gutter
                let width = geo.size.width - gutter * 2

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    artwork(width: width, height: geo.size.height)

                    Spacer(minLength: MP.S.x5)

                    MPArcText(
                        text: title,
                        size: 28,
                        color: theme.foreground,
                        availableWidth: width
                    )

                    Spacer(minLength: MP.S.x3)

                    MPBrandLine(color: theme.muted)

                    Spacer(minLength: 0)

                    Text(footer)
                        .font(MP.F.labelSM(.semibold))
                        .foregroundStyle(theme.muted.opacity(0.8))
                        .padding(.bottom, MP.S.x4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, gutter)
                .padding(.vertical, MP.S.x6)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Kapak. \(title). \(footer).")
    }

    /// Kimin için yazıldığı; Günlük masalları kimse için yazılmadı (ad boş).
    private var footer: String {
        childName.isEmpty ? "\(pageCount) sayfa" : "\(childName) için · \(pageCount) sayfa"
    }

    /// Kapağın ağırlık merkezi: illüstrasyon, mozaik kapak, veya dünya ikonu.
    @ViewBuilder
    private func artwork(width: CGFloat, height: CGFloat) -> some View {
        let side = min(width * 1.32, height * 0.56)

        if let coverAsset {
            Image(coverAsset)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: side)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: MP.R.lg, style: .continuous))
                .accessibilityHidden(true)
        } else if let mosaicCover {
            // Generative paper-mosaic cover for text-only stories.
            MagicPaperCoverView(configuration: mosaicCover, title: title)
                .frame(width: width, height: side)
                .clipShape(RoundedRectangle(cornerRadius: MP.R.lg, style: .continuous))
                .accessibilityHidden(true)
        } else {
            // Görselli masal kendi kapağını taşıyana kadar: dünya işareti,
            // kapak ölçeğinde. Liste satırındaki küçük ikonun büyütülmüşü
            // değil — kapak alanının tamamını kaplayan sakin bir yüzey.
            RoundedRectangle(cornerRadius: MP.R.lg, style: .continuous)
                .fill(accent.mpMixedWithWhite(0.86))
                .frame(width: width, height: side)
                .overlay {
                    MPIcon(symbol, size: side * 0.28, weight: .semibold)
                        .foregroundStyle(accent.opacity(0.75))
                }
                .accessibilityHidden(true)
        }
    }
}

extension StoryCover {
    /// Okuyucunun kapak yaprağı.
    init(story: ReaderStory, theme: MP.ReadTheme) {
        self.init(title: story.title,
                  childName: story.childName,
                  pageCount: story.pageCount,
                  coverAsset: story.coverAsset,
                  symbol: story.symbol,
                  accent: story.accent,
                  mosaicCover: story.mosaicCover,
                  theme: theme)
    }

    /// Yaratma akışının kapak ekranı.
    init(story: Story, childName: String) {
        self.init(title: story.title,
                  childName: childName,
                  pageCount: story.pages.count,
                  coverAsset: story.mpDefaultCoverAsset,
                  symbol: story.mpSymbol,
                  accent: story.mpAccent,
                  mosaicCover: story.mpCoverStyle == .magicPaperMosaic ? story.mpMosaicCover : nil,
                  theme: .light)
    }
}
