import SwiftUI

/// Kitap sayfasının yüzeyi.
///
/// Sistemde kâğıt "düz sıcak renk + sert alt kenar"dır; `mpScreenBackground`
/// bunu açıkça söylüyor. Okuyucu o kuralı korur ve uygulamanın geri kalanının
/// ihtiyaç duymadığı tek bir şey ekler: cilt payı.
///
/// Sayfa güvenli alanı yok sayar ve baştan başa doldurur. Bu yalnızca tasarım
/// tercihi değil, teknik bir zorunluluk: sayfa kıvrımı yaprağın *arkasını*
/// gösterir, saydam bir sayfa kıvrıldığında arkasındaki her ne varsa görünür ve
/// hata gibi okunur.
struct ReaderPaper: View {

    let theme: MP.ReadTheme

    /// Kâğıt dokusu.
    ///
    /// Tek sabit. Cihazda §28 testini geçmezse burası `false` olur ve doku
    /// tamamen çıkar — düz sıcak kâğıt, cilt payı ve kıvrımın kendi ışığı
    /// etkinin çoğunu zaten veriyor.
    static let showsGrain = true

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            theme.paper

            if ReaderPaper.showsGrain && !reduceTransparency {
                Image(uiImage: ReaderGrain.tile)
                    .resizable(resizingMode: .tile)
                    .opacity(theme == .night ? 0.05 : 0.035)
                    .blendMode(theme == .night ? .plusLighter : .multiply)
                    .allowsHitTesting(false)
            }

            // Cilt payı — kitabın dikişe yakın kenarındaki ince gölge.
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [theme.spine, theme.spine.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 14)
                Spacer(minLength: 0)
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

/// Doku karosu.
///
/// Süreç başına bir kez üretilir ve saklanır: sayfa başına değil, kare başına
/// hiç değil. Hareketli bir doku hem §19'un yasakladığı sürekli efekt olurdu
/// hem de sayfa denetleyicisi kıvrım sırasında görüntüleri anlık kopyaladığı
/// için çevirme boyunca yırtılırdı.
enum ReaderGrain {

    static let tile: UIImage = make()

    private static func make(side: Int = 64) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        return UIGraphicsImageRenderer(
            size: CGSize(width: side, height: side), format: format
        ).image { context in
            // Sabit tohumlu üretim: her açılışta aynı karo. Rastgele olsaydı
            // aynı masal iki açılışta iki farklı kâğıda basılırdı.
            var seed: UInt64 = 0x9E3779B97F4A7C15
            func nextUnit() -> Double {
                seed ^= seed << 13
                seed ^= seed >> 7
                seed ^= seed << 17
                return Double(seed % 1000) / 1000.0
            }

            for y in 0..<side {
                for x in 0..<side {
                    let value = nextUnit()
                    // Yalnızca lifin koyu tarafı çizilir; aradaki her şey kâğıt.
                    guard value > 0.82 else { continue }
                    let alpha = (value - 0.82) / 0.18 * 0.5
                    context.cgContext.setFillColor(
                        UIColor(white: 0.35, alpha: alpha).cgColor
                    )
                    context.cgContext.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
    }
}
