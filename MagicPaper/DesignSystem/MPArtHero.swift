import SwiftUI

/// Bir ekranda çizilecek sanat: teslim edilmiş bir illüstrasyon ya da o gelene
/// kadar zaten onaylı süs motifleri.
enum MPArt: Equatable {
    case image(String)
    /// İlki alt kenara tam genişlik oturur (tepe, dalga), ikincisi sağ üstte
    /// küçük durur (ay, güneş). Fazlası çizilmez.
    case motifs([String])
}

/// Tam genişlik sahne ve üstünde metin — masal detayının başı.
///
/// Tasarım sisteminde illüstrasyonun üstüne metin binen tek bileşen. Kapak
/// (`StoryCover`) başlığı bilerek resmin altında tutar; burada ise başlık
/// sahnenin içindedir, bu yüzden okunurluğu karartma (`MP.Scrim`) taşır.
///
/// Yükseklik genişlikten gelir (`aspect`) ya da sabittir (`height`, Günlük'ün
/// boyalı sahneleri). Oranlı hâlde içerik uzarsa bileşen de uzar: en büyük
/// Dynamic Type'ta başlık kesilmez, sahne arkada büyür. Sabit hâlde çağıran
/// metni sınırlar (`dynamicTypeSize`, `lineLimit`).
///
/// Arka plan genelde bir sanat seti görselidir (`init(art:)`). Görseli henüz
/// olmayan bir masal kendi kapağını verebilir (`init(backdrop:)`); karartma
/// iki durumda da aynıdır. Arka plan VoiceOver'dan gizlidir; sahneye dokununca
/// bir şey açılıyorsa eylem içerikte ya da sahnenin üstünde durur.
struct MPArtHero<Backdrop: View, Content: View>: View {
    let backdrop: Backdrop
    /// Genişlik / yükseklik. Sanat seti hero'su 3:4 üretilir.
    let aspect: CGFloat
    /// Verilirse oran yerine bu yükseklik.
    let height: CGFloat?
    let content: Content

    init(aspect: CGFloat = 3.0 / 4.0,
         @ViewBuilder backdrop: () -> Backdrop,
         @ViewBuilder content: () -> Content) {
        self.backdrop = backdrop()
        self.aspect = aspect
        self.height = nil
        self.content = content()
    }

    init(height: CGFloat,
         @ViewBuilder backdrop: () -> Backdrop,
         @ViewBuilder content: () -> Content) {
        self.backdrop = backdrop()
        self.aspect = 3.0 / 4.0
        self.height = height
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let height {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
            } else {
                Color.clear
                    .aspectRatio(aspect, contentMode: .fit)
                    .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: MP.S.x2) {
                content
            }
            .foregroundStyle(MP.C.textOnArt)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, MP.S.screenGutter)
            .padding(.top, MP.S.x4)
            .padding(.bottom, MP.S.x7)
            .background(alignment: .top) {
                VStack(spacing: 0) {
                    MP.Scrim.feather.frame(height: MP.Scrim.featherHeight)
                    MP.Scrim.body
                }
                .padding(.top, -MP.Scrim.featherHeight)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
        .background { backdrop.accessibilityHidden(true) }
        .clipped()
        .accessibilityElement(children: .contain)
    }
}

extension MPArtHero where Backdrop == MPArtLayer {
    init(art: MPArt, aspect: CGFloat = 3.0 / 4.0, @ViewBuilder content: () -> Content) {
        self.init(aspect: aspect, backdrop: { MPArtLayer(art: art) }, content: content)
    }
}

/// `MPArt`'ın çizimi: görsel ya da yer tutucu.
struct MPArtLayer: View {
    let art: MPArt

    var body: some View {
        switch art {
        case .image(let name):
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        case .motifs(let names):
            MPArtPlaceholder(motifs: names)
        }
    }
}

/// Görseli henüz gelmemiş sahne: gece zemini ve setin kendi motifleri.
///
/// Boş bir kutu değil, setin karakterini taşıyan sakin bir yer tutucu —
/// tasarım gözden geçirmesi gerçek oranlarla ve gerçek karartmayla yapılsın
/// diye. Motifler şablon olarak boyanır; parlamaz, hareket etmez.
struct MPArtPlaceholder: View {
    let motifs: [String]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                MP.C.surfaceNight

                if let ground = motifs.first {
                    Image(ground)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(MP.C.textOnArtMuted.opacity(0.22))
                        .frame(width: geo.size.width)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                if motifs.count > 1 {
                    Image(motifs[1])
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(MP.C.textOnArt.opacity(0.7))
                        .frame(width: geo.size.width * 0.26)
                        // Sahne kompozisyonu: kadraj kesri, boşluk değil.
                        .position(x: geo.size.width * 0.73, y: geo.size.height * 0.24)
                }
            }
        }
    }
}

#if DEBUG
#Preview("MPArtHero — gece seti, görsel bekliyor") {
    ScrollView {
        MPArtHero(art: StoryArtKitCatalog.bundled.kits.first?.art(for: .hero)
                  ?? .motifs(["Storybook/bedtime_night_hills_01", "Storybook/bedtime_moon_01"])) {
            Text("Uyku Zamanı")
                .font(MP.F.labelSM())
                .foregroundStyle(MP.C.textOnArtMuted)
            Text("Yeliz ve Ay Işığı Feneri")
                .font(MP.F.displayLG())
            Text("Yeliz için · 8 sayfa")
                .font(MP.F.bodySM(.semibold))
                .foregroundStyle(MP.C.textOnArtMuted)
        }
    }
    .background(MP.C.surfaceApp)
}
#endif
