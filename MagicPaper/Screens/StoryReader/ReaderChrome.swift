import SwiftUI

/// Okuyucunun kontrolleri (23 · Okuyucu, Pastel Masal).
///
/// Üstte kapat, favori ve okuma ayarları; altta teslimdeki kontrol çubuğu:
/// sayfa, ilerleme, önceki · sesli oku · sonraki. Çocuk sayfayı kıvrımla da
/// çevirebilir; çubuk okumayı bilmeyen çocuğun yolu. Kapat dışındaki her şey
/// okumaya dalınca kendiliğinden çekilir, sayfaya dokununca geri gelir.
///
/// **Kapat düğmesi bunun dışındadır ve hiç kaybolmaz.** Geri kalan kontroller
/// 4,5 saniye sonra çekiliyor; çıkış yolu da çekildiğinde, kapatmak isteyen
/// kişi düğmeyi kaybediyor ve geri getirmek için önce sayfaya dokunmak zorunda
/// kalıyor — dokunuşun kendisi de sayfayı çevirebildiği için bu bazen iki kez
/// oluyor. Bir okuma yüzeyi kendini karartabilir; çıkışını karartamaz.
///
/// Süreyi uzatmak bunu çözmez, yalnızca erteler: her sabit gecikmede çıkışın
/// kaybolduğu bir an vardır.
///
/// Masalın başlığı burada yok. Kapakta söylendi; sayfanın üstünde tekrar etmesi
/// kitaptan çok uygulama gibi durur.
struct ReaderChrome: View {

    let theme: MP.ReadTheme
    let isFavorite: Bool
    let isSpeaking: Bool
    /// Geri kalan kontroller görünür mü. Kapat bundan bağımsızdır.
    var showsSecondary: Bool = true
    /// "Sayfa 2 / 8"; kapak ve kapanış yaprağında `nil`.
    var pageLabel: String? = nil
    var progress: Double = 0
    var canGoPrevious: Bool = false
    var canGoNext: Bool = false
    /// Son masal sayfasında ileri düğmesi bayrağa döner: masal sonu.
    var isLastPage: Bool = false
    let onClose: () -> Void
    let onToggleFavorite: () -> Void
    let onToggleSpeech: () -> Void
    let onOpenSettings: () -> Void
    var onPrevious: () -> Void = {}
    var onNext: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: MPSpacing.sm) {
                MPCircleButton(systemImage: "xmark", accessibilityLabel: "Kapat", action: onClose)
                    // Sönükleştirilmez: `.opacity(0.45)` varken dokunuş düğmeye
                    // değil alttaki sayfaya gidiyor, sayfa geri çevriliyordu.
                Spacer(minLength: MPSpacing.md)
                if showsSecondary {
                    MPCircleButton(systemImage: isFavorite ? "heart.fill" : "heart",
                                   accessibilityLabel: isFavorite ? "Favorilerden çıkar" : "Favorilere ekle",
                                   tint: isFavorite ? MPColor.brandPink : MPColor.textPrimary,
                                   action: onToggleFavorite)
                    MPCircleButton(systemImage: "textformat", accessibilityLabel: "Okuma ayarları",
                                   action: onOpenSettings)
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.xxs)

            Spacer(minLength: 0)

            if showsSecondary, let pageLabel {
                controlBar(pageLabel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    /// 23 · Okuyucu alt çubuğu: sayfa, ilerleme, önceki · sesli oku · sonraki.
    private func controlBar(_ label: String) -> some View {
        VStack(spacing: MPSpacing.md) {
            HStack {
                Text(label).mpText(.footnote).fontWeight(.heavy).foregroundStyle(MPColor.textSecondary)
                Spacer()
                Text(isSpeaking ? "Sesli okunuyor" : "Sesli okuma").mpText(.footnote).fontWeight(.heavy)
                    .foregroundStyle(MPColor.textSecondary)
            }
            GeometryReader { geo in
                Capsule().fill(MPColor.readerDayTrack)
                    .overlay(alignment: .leading) {
                        Capsule().fill(MPColor.actionPrimary)
                            .frame(width: max(MPSpacing.md, geo.size.width * progress))
                    }
            }
            .frame(height: 8)
            .accessibilityHidden(true)
            HStack {
                navButton(symbol: "chevron.left", label: "Önceki sayfa", enabled: canGoPrevious, action: onPrevious)
                Spacer()
                MPRoundActionButton(systemImage: isSpeaking ? "pause.fill" : "play.fill",
                                    accessibilityLabel: isSpeaking ? "Sesli okumayı duraklat" : "Sesli oku",
                                    action: onToggleSpeech)
                Spacer()
                navButton(symbol: isLastPage ? "flag.checkered" : "chevron.right",
                          label: isLastPage ? "Masalı bitir" : "Sonraki sayfa",
                          enabled: canGoNext, action: onNext)
            }
            .padding(.horizontal, MPSpacing.xxl)
        }
        .padding(.horizontal, MPSpacing.xl)
        .padding(.top, MPSpacing.lg)
        .padding(.bottom, MPSpacing.md)
        .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.sheet))
        .mpShadow(.sheet)
        .padding(.horizontal, MPSpacing.sm)
    }

    private func navButton(symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            MPIcon(symbol, size: 24, weight: .bold)
                .foregroundStyle(enabled ? MPColor.textPrimary : MPColor.textTertiary)
                .frame(width: MPSize.minTouchKid, height: MPSize.minTouchKid)
                .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}
