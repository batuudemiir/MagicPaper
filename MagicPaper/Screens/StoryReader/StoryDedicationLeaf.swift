import SwiftUI

/// İthaf yaprağı: kapağı çevirince ilk görülen sessiz sayfa.
///
/// "Bu masal İrem için yazıldı. 16 Ekim 2026, Cuma akşamı." Süs yok, Ragi
/// yok; gerçek bir kitabın ithaf sayfası gibi bol boşluk ve iki satır.
/// Metin `StoryColophon`'dan gelir.
struct StoryDedicationLeaf: View {

    let dedication: StoryColophon.Dedication?
    let theme: MP.ReadTheme
    var readSize: MP.ReadSize = .normal

    var body: some View {
        ZStack {
            ReaderPaper(theme: theme)
            if let dedication {
                VStack(spacing: MP.S.x4) {
                    Text(dedication.line)
                        .font(MP.F.read(readSize.points))
                        .lineSpacing(readSize.lineSpacing)
                        .italic()
                        .foregroundStyle(theme.foreground)
                    Text(dedication.date)
                        .font(MP.F.caption(.semibold))
                        .foregroundStyle(theme.muted)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, MP.S.screenGutter)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

#Preview("İthaf") {
    StoryDedicationLeaf(
        dedication: .init(line: "Bu masal İrem için yazıldı.", date: "16 Ekim 2026, Cuma akşamı"),
        theme: .light
    )
}
