import SwiftUI

/// Kitabın kapanış yaprağı.
///
/// Son sayfayı çevirerek varılır, çünkü bir kitabın son yaprağı da öyledir.
/// Okuyucu burada kendini kapatmaz: çocuk hâlâ bakıyor olabilir, ve masalın
/// bitmesiyle ekranın kapanması aynı şey değil.
///
/// §16: rozet yok, konfeti yok, puan yok. Duygusal durum "masal bitti" —
/// kutlanacak bir başarı değil, tamamlanmış bir şey. FAZ 13: masal seri olarak
/// devam ettirilebiliyorsa "Devam ettir" burada; o da sakin, geri sayımsız
/// (`SeriesEndingSection`).
struct StoryEndingLeaf: View {

    let story: Story
    let theme: MP.ReadTheme
    let accent: Color
    let onReadAgain: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            ReaderPaper(theme: theme)

            // A continuable story adds a few lines (FAZ 13), and at the
            // largest text sizes the column no longer fits: it then scrolls
            // instead of sliding under the reader's close button.
            ViewThatFits(in: .vertical) {
                column
                ScrollView(showsIndicators: false) { column }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Hikâyenin sonu")
    }

    private var column: some View {
        VStack(alignment: .leading, spacing: MP.S.x6) {
            Spacer(minLength: 0)

            MPIcon("moon", size: MP.G.xl, weight: .semibold)
                .foregroundStyle(accent.opacity(0.8))

            Text("Hikâyenin sonu")
                .font(MP.F.displayMD())
                .mpTightTracking(26)
                .foregroundStyle(theme.foreground)
                .fixedSize(horizontal: false, vertical: true)

            Text("İyi geceler.")
                .font(MP.F.bodyMD())
                .foregroundStyle(theme.muted)

            SeriesEndingSection(story: story, theme: theme, accent: accent)

            Spacer(minLength: 0)

            VStack(spacing: MP.S.x3) {
                // Dolu marka rengi yerine yumuşak varyant. Yatmadan önce
                // biten bir masalın sonunda tam doygunlukta pembe bir düğme
                // sessiz anın ortasında sesini yükseltmek olurdu (§16);
                // yumuşak varyant hâlâ açıkça dokunulabilir bir düğme.
                LegacyMPButton(title: "Tekrar oku", variant: .soft, size: .lg,
                         icon: "book", fullWidth: true) {
                    onReadAgain()
                }
                LegacyMPButton(title: "Kitaplığıma dön", variant: .ghost, size: .lg,
                         fullWidth: true) {
                    onClose()
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, StoryPageView.gutter)
        // Below the reader's close button, which floats over the leaf.
        .padding(.top, MP.S.navBarHeight + MP.S.x8)
        .padding(.bottom, MP.S.x8)
    }
}
