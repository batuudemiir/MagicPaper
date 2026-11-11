import SwiftUI

/// Okuyucuda "Konuşalım" (Faz 11): 2-3 sayfada çıkan küçük düğme ve
/// dokununca açılan soru kartı.
///
/// Ebeveyn içindir: çocuk okurken büyüğün sorabileceği tek bir açık soru.
/// Doğru cevabı yok, puanlanmaz, kaydedilmez (`StoryTalkPrompts`). Okuyucu
/// sayfasında Ragi yok (CLAUDE.md, Ragi istisnaları), bu yüzden düğme bir
/// konuşma simgesi taşır. Kart içerik olduğu için cam değil kâğıt
/// (`ReaderWordCard` ile aynı dil); dışına dokununca kapanır.
struct ReaderTalkButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MP.S.x2) {
                MPIcon("bubble.left.and.bubble.right", size: MP.G.sm, weight: .semibold)
                Text("Konuşalım").font(MP.F.labelMD())
            }
            .foregroundStyle(MP.C.brandInk)
            .padding(.horizontal, MP.S.x4)
            .frame(minHeight: MP.S.tapMin)
            .background(MP.C.brandSoft, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel("Konuşalım")
        .accessibilityHint("Bu sayfa için birlikte konuşacağınız bir soru açar")
    }
}

struct ReaderTalkCard: View {
    let question: String
    let theme: MP.ReadTheme
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MP.S.x2) {
            Text("Konuşalım")
                .font(MP.F.labelMD())
                .foregroundStyle(theme.muted)
            Text(question)
                .font(MP.F.displaySM())
                .foregroundStyle(theme.foreground)
                .fixedSize(horizontal: false, vertical: true)
            Text("Cevabın doğrusu yanlışı yok. Konuşunca masala dönebilirsiniz.")
                .font(MP.F.bodyMD())
                .foregroundStyle(theme.body)
                .fixedSize(horizontal: false, vertical: true)
            MPButton(title: "Masala dön", kind: .ghost, action: onClose)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, MP.S.x4)
        .padding(.vertical, MP.S.x3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mpEdge(fill: theme.isDark ? theme.paper : MP.C.surfaceCard,
                edge: theme.isDark ? theme.muted.opacity(0.35) : MP.C.edgeCard,
                radius: MP.R.card)
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape, onClose)
    }
}
