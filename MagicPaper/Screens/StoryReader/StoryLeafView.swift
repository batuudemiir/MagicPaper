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

    let onClose: () -> Void
    var onGoodNight: () -> Void = {}

    var body: some View {
        switch leaf {
        case .cover:
            // "Kim okusun?" yalnızca okunacak bir ses varsa: cihaz anlatıcısı
            // kapalıyken (`MPFeatures.deviceNarration`) kayıtlı ses gerekir.
            StoryCover(story: model.story, theme: theme,
                       listens: canListen ? app.readerShouldSpeak(settings: settings) : nil) { listen in
                MPHaptics.selection()
                app.readerVoiceChoice = listen
                // Ayarın kendisi değişmez: seçim bu okumaya ait.
                if !listen { MPSpeech.shared.stop() }
            }

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
                symbol: model.story.symbol,
                readerSafeTop: model.readerSafeTop
            )
        case .ending:
            StoryEndingLeaf(
                story: story,
                theme: theme,
                accent: model.story.accent,
                isCurrent: model.leafIndex == index,
                onClose: onClose,
                onGoodNight: onGoodNight
            )
        }
    }

    private var canListen: Bool {
        MPFeatures.deviceNarration || MPNarration.audio(model.story.id, page: 0) != nil
    }

    private var leaf: ReaderLeaf {
        guard model.story.leaves.indices.contains(index) else { return .ending }
        return model.story.leaves[index]
    }
}
