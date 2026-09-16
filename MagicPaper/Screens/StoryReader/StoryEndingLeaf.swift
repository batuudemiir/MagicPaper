import SwiftUI

/// Kitabın kapanış yaprağı.
///
/// Son sayfayı çevirerek varılır, çünkü bir kitabın son yaprağı da öyledir.
/// Okuyucu burada kendini kapatmaz: çocuk hâlâ bakıyor olabilir, ve masalın
/// bitmesiyle ekranın kapanması aynı şey değil.
///
/// §16: rozet yok, seri yok, konfeti yok, puan yok. Duygusal durum "masal
/// bitti" — kutlanacak bir başarı değil, tamamlanmış bir şey.
struct StoryEndingLeaf: View {

    let theme: MP.ReadTheme
    let accent: Color
    let onReadAgain: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            ReaderPaper(theme: theme)

            VStack(alignment: .leading, spacing: MP.S.x6) {
                Spacer(minLength: 0)

                MPIcon("moon", size: 26, weight: .semibold)
                    .foregroundStyle(accent.opacity(0.8))

                Text("Hikâyenin sonu")
                    .font(MP.F.displayMD())
                    .mpTightTracking(26)
                    .foregroundStyle(theme.foreground)
                    .fixedSize(horizontal: false, vertical: true)

                Text("İyi geceler.")
                    .font(MP.F.bodyMD())
                    .foregroundStyle(theme.muted)

                Spacer(minLength: 0)

                VStack(spacing: MP.S.x3) {
                    // Dolu marka rengi yerine yumuşak varyant. Yatmadan önce
                    // biten bir masalın sonunda tam doygunlukta pembe bir düğme
                    // sessiz anın ortasında sesini yükseltmek olurdu (§16);
                    // yumuşak varyant hâlâ açıkça dokunulabilir bir düğme.
                    MPButton(title: "Tekrar oku", variant: .soft, size: .lg,
                             icon: "book", fullWidth: true) {
                        onReadAgain()
                    }
                    MPButton(title: "Kitaplığıma dön", variant: .ghost, size: .lg,
                             fullWidth: true) {
                        onClose()
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, StoryPageView.gutter)
            .padding(.vertical, MP.S.x8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Hikâyenin sonu")
    }
}
