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
/// Pastel görünüm (FAZ 17): uykulu Ragi, ortalanmış metin, tek birincil buton.
struct ReaderTimeUpLeaf: View {

    let theme: MP.ReadTheme
    let onClose: () -> Void

    var body: some View {
        ZStack {
            ReaderPaper(theme: theme)

            VStack(spacing: MPSpacing.xl) {
                Spacer(minLength: 0)

                // Kapanış yaprağında Ragi el sallar; burada uykulu. Masal
                // bitmedi, gün bitti.
                MascotImage(mascot: .sleepy, width: 150)
                    .accessibilityHidden(true)

                VStack(spacing: MPSpacing.sm) {
                    Text("Bugünlük bu kadar")
                        .mpText(.display)
                        .foregroundStyle(theme.foreground)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("Masal kaldığı yerde bekliyor. Yarın devam ederiz.")
                        .mpText(.body)
                        .foregroundStyle(theme.muted)
                        .multilineTextAlignment(.center)
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                MPButton(title: "Tamam", fullWidth: true, action: onClose)
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, StoryPageView.gutter)
            .padding(.vertical, MPSpacing.xxxl)
        }
        // Arkadaki sayfa hâlâ ekranda duruyor; dokunuşun oraya geçmemesi
        // gerekiyor, yoksa kapanmış bir okuma sayfa çevirmeye devam eder.
        .contentShape(Rectangle())
        .onTapGesture { }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Bugünün okuma vakti doldu")
    }
}
