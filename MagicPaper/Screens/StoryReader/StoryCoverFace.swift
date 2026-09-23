import SwiftUI

/// Kapağın **tipografik yüzü**: kâğıt, yay biçiminde başlık, marka satırı.
///
/// `StoryCover`'ın küçültülmüş hâli değil, onun yazı tarafı. Kütüphane ve ana
/// sayfa kartlarında illüstrasyon yerine bu görünür: bir masalı ayırt eden şey
/// hepsinde aynı olan ortak resim değil, kendi adıdır. Raf, aynı görselden beş
/// tane değil, beş farklı kitap sırtı gibi okunmalı.
///
/// Boyuta göre uyarlanır. Yay, dar kartta okunmaz hâle geldiği için belli bir
/// genişliğin altında düz iki satıra döner — kavis, okunurluk pahasına
/// korunacak bir şey değil.
struct StoryCoverFace: View {

    let title: String
    var theme: MP.ReadTheme = .light
    /// Marka satırı çok küçük kartlarda gizlenir.
    var showsBrand: Bool = true

    /// Yayın okunaklı sayıldığı en küçük punto.
    ///
    /// Karar genişliğe göre değil, *başlığın sığmak için ineceği puntoya* göre
    /// veriliyor. Kısa bir ad dar kartta bile yayda güzel durur; uzun bir ad
    /// geniş kartta bile 9 puntoya iner ve okunmaz. Ölçüt punto olmalı.
    private static let legibleArcSize: CGFloat = 13

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let inset = max(w * 0.09, 6)
            let usable = w - inset * 2
            let arcSize = MPArcText.fittedSize(text: title, size: w * 0.145,
                                               availableWidth: usable, minimumSize: 6)
            let usesArc = arcSize >= Self.legibleArcSize

            ZStack {
                theme.paper

                // Cilt payı — kartta da kitap kenarı hissi.
                HStack(spacing: 0) {
                    LinearGradient(colors: [theme.spine, theme.spine.opacity(0)],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(width: max(w * 0.045, 3))
                    Spacer(minLength: 0)
                }

                VStack(spacing: max(w * 0.045, 4)) {
                    Spacer(minLength: 0)

                    if usesArc {
                        MPArcText(
                            text: title,
                            size: w * 0.145,
                            sweep: 0.42,
                            color: theme.foreground,
                            availableWidth: usable,
                            minimumSize: Self.legibleArcSize
                        )
                    } else {
                        // Yay okunmayacak kadar küçülüyorsa düz dizgi: üç
                        // satıra kadar, kapak alanının hakkını verecek
                        // puntoda. Kavis, okunurluk pahasına korunmaz.
                        Text(title)
                            .font(.custom(MP.F.display, size: max(w * 0.155, 11)).weight(.bold))
                            .foregroundStyle(theme.foreground)
                            .multilineTextAlignment(.center)
                            .lineSpacing(w * 0.018)
                            .lineLimit(3)
                            .minimumScaleFactor(0.62)
                            .frame(width: usable)
                    }

                    if showsBrand && w >= 86 {
                        Text("MagicPaper Kids")
                            .font(.custom(MP.F.body, size: max(w * 0.052, 6)).weight(.bold))
                            .tracking(w * 0.012)
                            .foregroundStyle(theme.muted.opacity(0.65))
                            .textCase(.uppercase)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            // Dünya rozeti sağ altta duruyor ve marka satırını
                            // kesiyordu. Satır rozetin soluna değil, üstüne
                            // çekiliyor: kısaltmak markayı yarım yazmak olurdu.
                            .padding(.trailing, w * 0.20)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, inset)
                // Rozetin oturduğu bant boş kalsın.
                .padding(.bottom, w * 0.13)
            }
        }
        .accessibilityHidden(true)   // başlık kartın metin bloğunda zaten var
    }
}
