import SwiftUI

/// UIKit'in taşıdığı yaprağın SwiftUI karşılığı.
///
/// Sayfa içeriğini *değer olarak* almaz, durumu kendisi dinler. Sebebi
/// `UIHostingController.rootView`'ın kurulumda bir kez yazılması: sayfa
/// denetleyicisi yaprakları bir kez üretip elinde tuttuğu için, değer olarak
/// verilen tema, yazı boyutu ve kontrol görünürlüğü o yaprakta donup kalıyordu.
/// Okuma ayarlarından yazı boyutunu değiştirmek açık sayfayı değiştirmiyor,
/// kontroller gizlendiğinde künye ekranda kalıyordu.
///
/// `model` ve `app` birer `ObservableObject` olduğu için, onları buradan
/// gözlemlemek yaprağı canlı tutar.
struct StoryLeafView: View {

    let index: Int
    /// The saved story, for what its last leaf offers (FAZ 13 series).
    let story: Story
    @ObservedObject var model: StoryReaderModel
    @EnvironmentObject private var app: MPAppState

    let onReadAgain: () -> Void
    let onClose: () -> Void
    var onAnother: () -> Void = {}
    var onGoodNight: () -> Void = {}

    var body: some View {
        switch leaf {
        case .cover:
            StoryCover(story: model.story, theme: app.readTheme)

        case .page(let page):
            StoryPageView(
                page: page,
                theme: app.readTheme,
                readSize: app.readSize,
                folio: "\(page.index + 1) / \(model.story.pageCount)",
                // Sayfa numarası alt kontrol çubuğunda ("Sayfa X / Y", 23).
                showsFolio: false,
                accent: model.story.accent,
                symbol: model.story.symbol,
                ornament: ReaderPageOrnament.current,
                decoration: decorationContext(for: page)
            )
        case .ending:
            StoryEndingLeaf(
                story: story,
                theme: app.readTheme,
                accent: model.story.accent,
                onReadAgain: onReadAgain,
                onClose: onClose,
                onAnother: onAnother,
                onGoodNight: onGoodNight
            )
        }
    }

    /// Sayfanın süsleme bağlamı.
    ///
    /// Güvenli bölgeler burada kabaca veriliyor: metin sayfanın orta bandını,
    /// çizim varsa üst yarısını tutar. Motor bu dikdörtgenlerin dışında kalır.
    private func decorationContext(for page: ReaderPage) -> StoryDecorationContext {
        let hasImage = page.imageRef != nil
        let hasScene = page.scene != nil
        // Hazır sahne (B2) 4:3 ve sayfanın üst ~%40'ında kalır; metin hemen
        // altından başlar, bu yüzden metin bölgesi daha yukarıdan açılır.
        let textRect = hasScene
            ? CGRect(x: 0.06, y: 0.42, width: 0.88, height: 0.52)
            : hasImage
                ? CGRect(x: 0.06, y: 0.58, width: 0.88, height: 0.34)
                : CGRect(x: 0.06, y: 0.30, width: 0.88, height: 0.42)
        let illoRect = hasScene
            ? CGRect(x: 0.04, y: 0.03, width: 0.92, height: 0.40)
            : hasImage
                ? CGRect(x: 0.04, y: 0.05, width: 0.92, height: 0.50)
                : nil
        let seed = StoryDecorationContext.seed(storyID: model.story.id, page: page.index)
        let env = StoryEnvironment.resolve(scene: page.sceneHint, world: model.story.world)
        // Sahneli sayfa zaten resimli: süs seyrek kalır ki sahneyle yarışmasın.
        let density = hasScene
            ? DecorationDensity.sparse
            : DecorationDensity.forPage(index: page.index,
                                        pageCount: model.story.pageCount,
                                        environment: env, seed: seed)
        return .make(story: model.story, page: page,
                     density: density,
                     textSafeRect: textRect,
                     illustrationSafeRect: illoRect)
    }

    private var leaf: ReaderLeaf {
        guard model.story.leaves.indices.contains(index) else { return .ending }
        return model.story.leaves[index]
    }
}
