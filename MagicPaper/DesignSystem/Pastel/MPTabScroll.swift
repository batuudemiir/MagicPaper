import SwiftUI

/// Çocuk kök sekmesinin kaydırması: seçili sekmeye yeniden dokununca başa döner.
/// Açık alt sayfaları `MPRouter.reselectTab` kapatır.
struct MPTabScroll<Content: View>: View {
    let tab: MPTab
    @ViewBuilder var content: Content

    @EnvironmentObject private var app: MPAppState
    private let top = "mp-tab-top"

    var body: some View {
        ScrollViewReader { reader in
            ScrollView(showsIndicators: false) {
                content.id(top)
            }
            .onChange(of: app.router.tabReselections) { _, _ in
                guard app.router.tab == tab else { return }
                withAnimation(MP.M.gated(MP.M.base)) { reader.scrollTo(top, anchor: .top) }
            }
        }
    }
}
