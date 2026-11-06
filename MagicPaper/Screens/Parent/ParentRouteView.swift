import SwiftUI

/// Ebeveyn sekmesinin yığınına itilen sayfaların kabı (`MPParentRoute`).
/// Yığın: `ParentTabStack` (`ContentView`).
struct ParentRouteView: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var profileManager = ProfileManager.shared
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
        case .familyCharacters(let id):
            if let profile = profile(id) { FamilyCharactersView(profile: profile) }
        case .bookCharacter(let id):
            if let profile = profile(id) { BookCharacterView(profile: profile) }
        }
    }

    private func close() { app.parentRoute = nil }

    private func profile(_ id: UUID) -> UserProfile? {
        profileManager.profiles.first { $0.id == id }
    }
}
