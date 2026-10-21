import SwiftUI

/// Okuyucuda yeni kelimeye dokununca açılan kâğıt kart (21 Ekim 2026).
///
/// Kelime (Baloo 2), tek cümlelik anlamı ve "dinle" dairesi. İçerik olduğu
/// için cam değil kâğıt: `mpEdge` ile sert alt kenar, gölge yok. Kapat düğmesi
/// yok; kartın dışında bir yere dokununca kapanır (`StoryReaderView`), o
/// dokunuş sayfayı çevirmez. VoiceOver'da kaçış hareketi kapatır.
struct ReaderWordCard: View {
    let word: StoryWord
    let theme: MP.ReadTheme
    let onSpeak: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MP.S.x1) {
            HStack(alignment: .center, spacing: MP.S.x3) {
                Text(word.term)
                    .font(MP.F.displaySM())
                    .foregroundStyle(MP.C.textTitle)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: MP.S.x2)
                Button(action: onSpeak) {
                    MPIcon("speaker.wave.2", size: MP.G.md, weight: .semibold)
                        .foregroundStyle(MP.C.brandInk)
                        .frame(width: MP.S.tapMin, height: MP.S.tapMin)
                        .background(MP.C.brandSoft, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(MPPressStyle())
                .accessibilityLabel("\(word.term) kelimesini dinle")
            }
            Text(word.meaning)
                .font(MP.F.bodyMD())
                .foregroundStyle(MP.C.textBody)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, MP.S.x4)
        .padding(.vertical, MP.S.x3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mpEdge(fill: MP.C.surfaceCard, edge: MP.C.edgeCard, radius: MP.R.card)
        // Gece kâğıdında kart da koyu tona geçer.
        .environment(\.colorScheme, theme == .night ? .dark : .light)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Yeni kelime: \(word.term)")
        .accessibilityAction(.escape, onClose)
    }
}
