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
    @EnvironmentObject private var settings: MPSettingsStore

    private var theme: MP.ReadTheme { settings.readingTheme(chosen: app.readTheme) }

    let onReadAgain: () -> Void
    let onClose: () -> Void
    var onAnother: () -> Void = {}
    var onGoodNight: () -> Void = {}

    var body: some View {
        switch leaf {
        case .cover:
            StoryCover(story: model.story, theme: theme)

        case .dedication:
            StoryDedicationLeaf(dedication: model.story.dedication, theme: theme, readSize: app.readSize)

        case .page(let page):
            StoryPageView(
                page: page,
                theme: theme,
                readSize: app.readSize,
                spacing: settings.readSpacing,
                easyReading: settings.easyReading,
                layout: model.story.textLayout,
                childName: model.story.childName,
                folio: "\(page.index + 1) / \(model.story.pageCount)",
                // Kontroller görünürken sayfa numarası alt çubukta ("Sayfa X / Y",
                // 23); çekilince sayfanın altında sessiz künye.
                showsFolio: !model.controlsVisible,
                accent: model.story.accent,
                symbol: model.story.symbol
            )
        case .ending:
            StoryEndingLeaf(
                story: story,
                theme: theme,
                accent: model.story.accent,
                onReadAgain: onReadAgain,
                onClose: onClose,
                onAnother: onAnother,
                onGoodNight: onGoodNight
            )
        }
    }

    private var leaf: ReaderLeaf {
        guard model.story.leaves.indices.contains(index) else { return .ending }
        return model.story.leaves[index]
    }
}
