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
            // E4: kitap karakteri ayrı bir kimlik değil; kahraman düzenleyicisine gider.
            if let profile = profile(id) { HeroDressingRoom(profile: profile) }
        case .specialDays(let id):
            if let profile = profile(id) { SpecialDaysView(profile: profile) }
        case .profileHub(let id):
            if let profile = profile(id) { ProfileHubView(profile: profile) }
        case .safety:
            ParentSafetyView(onBack: close)
        case .settings:
            SettingsView(onBack: close)
        case .profileEdit(let id):
            if let profile = profile(id) {
                ProfileCreationView(mode: .addAnother, onCreated: { _ in
                    app.showToast("Profil güncellendi", symbol: "checkmark")
                }, editing: profile)
            }
        }
    }

    private func close() { app.router.parentRoute = nil }

    private func profile(_ id: UUID) -> UserProfile? {
        profileManager.profiles.first { $0.id == id }
    }
}
