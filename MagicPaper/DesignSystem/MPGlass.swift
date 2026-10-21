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

/// Yüzen eylem dairesi (Masal yaz, 21 Ekim 2026): marka renginde tonlu,
/// dokununca sistemin kendisi gibi esneyen cam (iOS 26 `interactive`). Apple'ın
/// öne çıkan cam düğmesi. iOS 26 öncesi düz marka rengi.
struct MPGlassAction<S: Shape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(MP.Glass.action, in: shape)
        } else {
            content.background(MP.C.brand, in: shape)
        }
    }
}

/// Yan yana yüzen cam parçaları tek grupta: iOS 26'da birbirine yaklaşınca
/// sistemin camı onları birlikte çizer (Apple'ın sekme çubuğu + arama dairesi).
struct MPGlassGroup<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}

extension View {
    func mpGlassSurface<S: Shape>(in shape: S) -> some View {
        modifier(MPGlassSurface(shape: shape))
    }

    func mpGlassAction<S: Shape>(in shape: S) -> some View {
        modifier(MPGlassAction(shape: shape))
    }

    /// Bu düğmeden açılan ekran düğmenin içinden büyür (iOS 18+ yakınlaşma).
    /// `namespace` nil ise (Hareketi Azalt) kaynak işaretlenmez, ekran
    /// sistemin olağan geçişiyle açılır.
    @ViewBuilder
    func mpZoomSource(_ id: String, in namespace: Namespace.ID?) -> some View {
        if #available(iOS 18.0, *), let namespace {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    /// `mpZoomSource` ile işaretlenmiş düğmeden büyüyerek açılan ekran.
    @ViewBuilder
    func mpZoomDestination(_ id: String, in namespace: Namespace.ID?) -> some View {
        if #available(iOS 18.0, *), let namespace {
            navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}

extension View {
    /// Ekranın altına yüzen bir gezinme çubuğu yerleştirir.
    ///
    /// `safeAreaInset`: içerik çubuğun altından kayar, cam renkli sahne ve
    /// kapakların üstünde de okunur kalır. `safeAreaBar` kullanılmıyor
    /// (21 Ekim 2026): kaydırma kenarı efekti çubuğun arkasında tam genişlikte
    /// şeffaf bir kutu gibi görünüyordu; sistemin sekme çubuğunda böyle bir
    /// kutu yok.
    ///
    /// Ana ekran göstergesi olan cihazlarda çubuk güvenli alanın içine iner:
    /// alt kenarı ekranın altından `MP.S.x4` yukarıda, göstergenin hemen
    /// üstünde durur (sistemin yüzen sekme çubuğu gibi). Göstergesi olmayan
    /// cihazda alttan `MP.S.x2` boşluk bırakır.
    func mpFloatingBar<Bar: View>(@ViewBuilder _ bar: @escaping () -> Bar) -> some View {
        GeometryReader { proxy in
            let inset = proxy.safeAreaInsets.bottom
            let bottom = inset > MP.S.x4 ? -(inset - MP.S.x4) : MP.S.x2
            self.safeAreaInset(edge: .bottom, spacing: 0) { bar().padding(.bottom, bottom) }
        }
    }
}
