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
    @ObservedObject var model: StoryReaderModel
    @EnvironmentObject private var app: MPAppState

    let onReadAgain: () -> Void
    let onClose: () -> Void

    var body: some View {
        switch leaf {
        case .page(let page):
            StoryPageView(
                page: page,
                theme: app.readTheme,
                readSize: app.readSize,
                folio: "\(page.index + 1) / \(model.story.pageCount)",
                showsFolio: model.controlsVisible,
                accent: model.story.accent,
                symbol: model.story.symbol,
                ornament: ReaderPageOrnament.current
            )
        case .ending:
            StoryEndingLeaf(
                theme: app.readTheme,
                accent: model.story.accent,
                onReadAgain: onReadAgain,
                onClose: onClose
            )
        }
    }

    private var leaf: ReaderLeaf {
        guard model.story.leaves.indices.contains(index) else { return .ending }
        return model.story.leaves[index]
    }
}
