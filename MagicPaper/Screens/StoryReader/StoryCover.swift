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
struct StoryCover: View {

    let title: String
    let childName: String
    let pageCount: Int
    /// Kapak illüstrasyonu. Yoksa masalın dünya işareti çizilir.
    let coverAsset: String?
    /// Görseli olmayan masalın kapağı için.
    var symbol: String = "book"
    var accent: Color = MP.C.brand
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

                    Text("\(childName) için · \(pageCount) sayfa")
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
        .accessibilityLabel("Kapak. \(title). \(childName) için, \(pageCount) sayfa.")
    }

    /// Kapağın ağırlık merkezi: illüstrasyon, kitap oranında ve tam genişlikte.
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
                  theme: .light)
    }
}
