import SwiftUI

/// Bugünün okuma vakti dolduğunda gelen yaprak.
///
/// Kapanış yaprağının (`StoryEndingLeaf`) kardeşi ve kasıtlı olarak ona
/// benziyor: aynı kâğıt, aynı sessizlik, aynı tek hareket. Ama iki şeyi
/// söylemek zorunda ve kapanış yaprağı bunları söylemez — masal **bitmedi**,
/// ve kalınan yer kayıtlı.
///
/// §16'nın tersi burada da geçerli: bir çocuğa "süren doldu" demek bir ceza
/// gibi okunabilir, bu yüzden metin kaybedilen bir şeyden değil yarın devam
/// edecek bir şeyden bahsediyor. Suçlayan bir dil ("çok okudun") ya da bir
/// sayaç ("30/30 dk") yok: sayı ebeveynin bilgisi, çocuğun değil.
struct ReaderTimeUpLeaf: View {

    let theme: MP.ReadTheme
    let onClose: () -> Void

    var body: some View {
        ZStack {
            ReaderPaper(theme: theme)

            VStack(alignment: .leading, spacing: MP.S.x6) {
                Spacer(minLength: 0)

                // Kapanış yaprağı ay çiziyor; bu yaprak kum saati çiziyor.
                // Aynı kâğıt, farklı sebep: masal bitmedi, gün bitti. Ve bu,
                // ebeveynin Ayarlar'da dokunduğu simgenin aynısı.
                MPIcon("hourglass", size: 26, weight: .semibold)
                    .foregroundStyle(theme.muted)

                Text("Bugünlük bu kadar")
                    .font(MP.F.displayMD())
                    .mpTightTracking(26)
                    .foregroundStyle(theme.foreground)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Masal kaldığı yerde bekliyor. Yarın devam ederiz.")
                    .font(MP.F.bodyMD())
                    .lineSpacing(16 * 0.55)
                    .foregroundStyle(theme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                LegacyMPButton(title: "Tamam", variant: .soft, size: .lg, fullWidth: true) {
                    onClose()
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, StoryPageView.gutter)
            .padding(.vertical, MP.S.x8)
        }
        // Arkadaki sayfa hâlâ ekranda duruyor; dokunuşun oraya geçmemesi
        // gerekiyor, yoksa kapanmış bir okuma sayfa çevirmeye devam eder.
        .contentShape(Rectangle())
        .onTapGesture { }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Bugünün okuma vakti doldu")
    }
}
