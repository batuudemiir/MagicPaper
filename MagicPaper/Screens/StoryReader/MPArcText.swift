import SwiftUI
import UIKit

/// Bir yay boyunca dizilen metin.
///
/// Çocuk kitabı kapaklarının klasik başlık biçimi. `Text` bunu yapamaz: her
/// harf ayrı ayrı, kendi açısında döndürülerek çemberin üstüne yerleştirilmek
/// zorunda.
///
/// Yay derinliği sabit bir açıdan (`sweep`) geliyor, sabit bir yarıçaptan
/// değil: yarıçap metnin ölçülen genişliğinden hesaplanıyor, böylece kısa ve
/// uzun başlıklar aynı kavisle çiziliyor. Sabit yarıçapla kısa başlık düz,
/// uzun başlık yarım daire olurdu.
struct MPArcText: View {

    let text: String
    /// Taban punto. Başlık satıra sığmıyorsa bu değerin altına inilir.
    var size: CGFloat = 26
    /// Yayın toplam açısı (radyan). 0.5 ≈ 29°, kitap kapağı için nazik bir kavis.
    var sweep: CGFloat = 0.5
    var color: Color = MP.C.textTitle
    /// Kullanılabilir genişlik — başlık buna sığacak şekilde küçültülür.
    var availableWidth: CGFloat

    private var characters: [Character] { Array(text) }

    /// Başlığın sığması için gereken punto.
    ///
    /// Uzun Türkçe başlıklar ("Yelız ve Eski Meyve Bahçesi'ndeki Titrek Işık")
    /// tek yayda taban puntoyla taşıyor. Küçülme 15 puntoda durur; altına
    /// inmek başlığı okunmaz yapardı.
    private var fittedSize: CGFloat {
        let measured = width(at: size)
        guard measured > availableWidth, measured > 0 else { return size }
        return max(15, size * (availableWidth / measured))
    }

    private func font(_ points: CGFloat) -> UIFont {
        UIFont(name: "Baloo2-Bold", size: points)
            ?? .systemFont(ofSize: points, weight: .bold)
    }

    private func width(at points: CGFloat) -> CGFloat {
        let f = font(points)
        return characters.reduce(0) { $0 + String($1).size(withAttributes: [.font: f]).width }
    }

    var body: some View {
        let points = fittedSize
        let uiFont = font(points)
        let widths = characters.map { String($0).size(withAttributes: [.font: uiFont]).width }
        let total = max(widths.reduce(0, +), 1)
        // Yay uzunluğu metnin genişliği; açı sabit, dolayısıyla yarıçap türetilir.
        let radius = total / sweep

        return ZStack {
            ForEach(Array(characters.enumerated()), id: \.offset) { index, character in
                let before = widths.prefix(index).reduce(0, +)
                // Harfin merkezinin yay üzerindeki konumu, tepe noktasına göre.
                let angle = (before + widths[index] / 2) / radius - sweep / 2

                Text(String(character))
                    .font(.custom(MP.F.display, size: points).weight(.bold))
                    .foregroundStyle(color)
                    .rotationEffect(.radians(Double(angle)))
                    .offset(
                        x: radius * sin(angle),
                        y: -radius * cos(angle) + radius
                    )
            }
        }
        .frame(width: availableWidth, height: arcHeight(points: points, radius: radius))
        // Yay bir süs; VoiceOver başlığı harf harf okumamalı.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityAddTraits(.isHeader)
    }

    /// Yayın kapladığı yükseklik: harf yüksekliği + kavisin sehimi.
    private func arcHeight(points: CGFloat, radius: CGFloat) -> CGFloat {
        let sagitta = radius * (1 - cos(sweep / 2))
        return points * 1.35 + sagitta
    }
}

/// Kapakların ve ilk sayfanın altındaki marka satırı.
struct MPBrandLine: View {
    var color: Color = MP.C.textMuted

    var body: some View {
        Text("MagicPaper Kids")
            .font(MP.F.labelSM(.bold))
            .tracking(2.2)
            .foregroundStyle(color.opacity(0.7))
            .textCase(.uppercase)
            .accessibilityHidden(true)
    }
}
