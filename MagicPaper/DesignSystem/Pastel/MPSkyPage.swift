import SwiftUI

/// Menü sayfalarının ortak çatısı (23 Kasım 2026, İrem): Okuma yolculuğum,
/// Rozetlerim, Çıkartma albümüm, Yeni kelimelerim, Masal haritam, Masal ailem,
/// Kitaplık renklerim. Ana sayfanın mor göğü (`MP.C.homeSky`) durum çubuğunun
/// altına kadar uzanır; üstünde geri dairesi ve beyaz başlık, altında göğün
/// söndüğü yere oturan beyaz tanıtım kartı (`hero`). İçerik beyaz zeminde,
/// bölümler boşlukla ayrılır.
///
/// Gök sabit yükseklikte çizilir: tanıtım kartı olmayan sayfada da (boş durum)
/// başlık koyu morun üstünde kalır, zemin içeriğin arkasında beyaza söner.
struct MPSkyPage<Trailing: View, Hero: View, Content: View>: View {
    let title: String
    let onBack: () -> Void
    /// Sayfanın alt kenarında sabit bir çubuk varsa (Süsler, Masal ailem) çubuk
    /// kendi boşluğunu taşır; kaydırılan içerik yalnızca kısa bir pay bırakır.
    var bottomPadding: CGFloat = GunlukLayout.bottomClearance
    private let trailing: Trailing
    private let hero: Hero
    private let content: Content

    init(title: String,
         bottomPadding: CGFloat = GunlukLayout.bottomClearance,
         onBack: @escaping () -> Void,
         @ViewBuilder trailing: () -> Trailing,
         @ViewBuilder hero: () -> Hero,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.bottomPadding = bottomPadding
        self.onBack = onBack
        self.trailing = trailing()
        self.hero = hero()
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                    header(topInset: geo.safeAreaInsets.top)
                    VStack(alignment: .leading, spacing: MPSpacing.xxl) { content }
                        .padding(.horizontal, MPSpacing.screenH)
                }
                .padding(.bottom, bottomPadding)
            }
            .ignoresSafeArea(edges: .top)
        }
        .background(MPColor.backgroundSurface.ignoresSafeArea())
    }

    /// İki kat (24 Kasım 2026, ana sayfanınki gibi): başlık satırı koyu gökte
    /// (`homeSkyTop`), tanıtım kartı kâğıda inişin önünde (`homeSkyFade`). Tek
    /// `homeSky` sabit 240 pt'ye yayıldığı için en büyük yazıda iki satırlık
    /// başlık açık mora, sonra beyaza taşıyordu.
    private func header(topInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: MPSpacing.md) {
                MPCircleButton(systemImage: "chevron.left", accessibilityLabel: "Geri", action: onBack)
                Text(title).font(MP.F.displaySM()).foregroundStyle(MP.C.textOnArt)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                trailing
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, topInset + MPSpacing.xs)
            .padding(.bottom, MPSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(stops: MP.C.homeSkyTop, startPoint: .top, endPoint: .bottom))

            hero
                .padding(.horizontal, MPSpacing.screenH)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(alignment: .top) {
                    LinearGradient(stops: MP.C.homeSkyFade, startPoint: .top, endPoint: .bottom)
                        .frame(height: MPSkyLayout.fadeHeight)
                        .accessibilityHidden(true)
                }
        }
    }
}

extension MPSkyPage where Trailing == EmptyView {
    init(title: String,
         bottomPadding: CGFloat = GunlukLayout.bottomClearance,
         onBack: @escaping () -> Void,
         @ViewBuilder hero: () -> Hero,
         @ViewBuilder content: () -> Content) {
        self.init(title: title, bottomPadding: bottomPadding, onBack: onBack,
                  trailing: { EmptyView() }, hero: hero, content: content)
    }
}

enum MPSkyLayout {
    /// Başlığın altındaki kâğıda iniş: tanıtım kartının üst yarısı morda kalır.
    static let fadeHeight: CGFloat = 160
}

/// Göğün altındaki beyaz tanıtım kartı: Ragi yumuşak bir dairede, kısa başlık
/// ve tek cümle. Sayfanın tek Ragi'si buradadır (boş durumda kart yok, Ragi
/// `MPStateView`'da). Sayı yalnızca toplananı söyler; hedef ya da "az kaldı" yok.
struct MPSkyIntro: View {
    let mascot: Mascot
    let headline: String
    let message: String
    var tone: MPWorldTone = .yellow

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            if !typeSize.isAccessibilitySize {
                MascotImage(mascot: mascot, width: MPSize.minTouchHero + MPSpacing.md)
                    .padding(MPSpacing.xs)
                    .background(tone.soft, in: Circle())
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                Text(headline).mpText(.section).foregroundStyle(MPColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message).mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(MPSpacing.lg)
        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Sky page") {
    MPSkyPage(title: "Rozetlerim", onBack: {}) {
        MPSkyIntro(mascot: .happy, headline: "3 / 69 rozet", message: "Okudukça yeni rozetler açılır.")
    } content: {
        MPSectionHeader(title: "Yollar")
    }
}
