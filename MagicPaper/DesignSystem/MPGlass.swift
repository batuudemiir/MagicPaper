import SwiftUI

/// İçeriğin üstünde yüzen gezinme kontrolünün yüzeyi.
///
/// iOS 26+ sistemin Liquid Glass'ı: Saydamlığı Azalt, Kontrastı Artır ve
/// kullanıcının cam ayarını sistem kendisi izler. iOS 26 öncesinde sistem
/// materyali üstüne kâğıt tonu; Saydamlığı Azalt açıkken opak kâğıt.
/// Kural: CLAUDE.md, Derinlik. Ayar: `MP.Glass`.
struct MPGlassSurface<S: Shape>: ViewModifier {
    let shape: S
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(MP.Glass.bar, in: shape)
        } else {
            content
                .background {
                    if reduceTransparency {
                        shape.fill(MP.C.surfaceCard)
                    } else {
                        shape.fill(.ultraThinMaterial)
                            .overlay(shape.fill(MP.Glass.fallbackFill))
                    }
                }
                .overlay(shape.stroke(MP.Glass.fallbackEdge, lineWidth: 1))
                .mpShadow(MP.Sh.card)
        }
    }
}

extension View {
    func mpGlassSurface<S: Shape>(in shape: S) -> some View {
        modifier(MPGlassSurface(shape: shape))
    }
}

extension View {
    /// Ekranın altına yüzen bir gezinme çubuğu yerleştirir.
    ///
    /// iOS 26+ `safeAreaBar`: içerik çubuğun altından kayarken sistemin
    /// kaydırma kenarı efekti onu yumuşakça siler, cam renkli sahne ve
    /// kapakların üstünde de okunur kalır. Öncesinde `safeAreaInset`.
    @ViewBuilder
    func mpFloatingBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        if #available(iOS 26.0, *) {
            safeAreaBar(edge: .bottom, spacing: 0, content: bar)
        } else {
            safeAreaInset(edge: .bottom, spacing: 0, content: bar)
        }
    }
}
