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
        case .voiceRecording:
            VoiceRecordingView(onClose: close)
        case .shareLink:
            ShareLinkView(onClose: close)
        }
    }

    private func close() { app.parentRoute = nil }
}
