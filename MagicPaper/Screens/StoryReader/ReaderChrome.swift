import SwiftUI

/// Okuyucunun kontrolleri.
///
/// Varsayılan hâli az: kapat, ve sayfanın altında bir künye. Eski okuyucudaki
/// tam genişlik ilerleme çubuğu ve üç adet 54 puntoluk ok buradan çıktı — §11
/// belirgin bir sayfa denetimini, §9 kalıcı büyük butonları yasaklıyor. İkisinin
/// yerini künye ve kıvrımın kendisi alıyor.
///
/// Mevcut ürün davranışları (favori, sesli okuma, okuma ayarları) korunur ama
/// yalnızca kontroller görünürken ulaşılabilir.
///
/// Masalın başlığı burada yok. Kapakta söylendi; sayfanın üstünde tekrar etmesi
/// kitaptan çok uygulama gibi durur.
struct ReaderChrome: View {

    let theme: MP.ReadTheme
    let isFavorite: Bool
    let isSpeaking: Bool
    let onClose: () -> Void
    let onToggleFavorite: () -> Void
    let onToggleSpeech: () -> Void
    let onOpenSettings: () -> Void

    private var tone: MPIconButton.Tone { theme == .night ? .glass : .paper }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: MP.S.x2) {
                MPIconButton(symbol: "xmark", label: "Kapat", tone: tone, action: onClose)

                Spacer(minLength: MP.S.x3)

                MPIconButton(
                    symbol: isFavorite ? "heart.fill" : "heart",
                    label: isFavorite ? "Favorilerden çıkar" : "Favorilere ekle",
                    tone: isFavorite ? .brand : tone,
                    action: onToggleFavorite
                )
                MPIconButton(
                    symbol: isSpeaking ? "pause.fill" : "speaker.wave.2",
                    label: isSpeaking ? "Sesli okumayı duraklat" : "Sesli oku",
                    tone: tone,
                    action: onToggleSpeech
                )
                MPIconButton(
                    symbol: "textformat.size",
                    label: "Okuma ayarları",
                    tone: tone,
                    action: onOpenSettings
                )
            }
            .padding(.horizontal, MP.S.screenGutter)
            .padding(.top, MP.S.x1)

            Spacer(minLength: 0)
        }
    }
}
