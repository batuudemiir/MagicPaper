import SwiftUI

/// Ebeveyn alanından tam ekran açılan sayfaların kabı (`MPParentRoute`).
/// Ebeveyn kabuğu (`ContentView.parentRoot`) bunu `fullScreenCover` ile açar.
struct ParentRouteView: View {
    @EnvironmentObject private var app: MPAppState
    let route: MPParentRoute

    var body: some View {
        switch route {
        case .bookExport:
            BookExportView(onClose: close)
        case .familyMembers:
            FamilyMembersView(onClose: close)
        case .voiceRecording, .shareLink:
            // FAZ 18 blokları geldikçe dolar; bayraklar kapalıyken buraya gelinmez.
            ParentHeader(title: "Yakında", onBack: close)
                .padding(MPSpacing.screenH)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(MPColor.backgroundParent.ignoresSafeArea())
        }
    }

    private func close() { app.parentRoute = nil }
}
