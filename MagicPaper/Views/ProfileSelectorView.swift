import SwiftUI

/// Profil seçimi — 03-SCREENS.md §8'deki "Kim okuyacak?" listesinin tam ekran hâli.
/// `MainContentView`, profiller varken hiçbiri seçili değilse buraya düşer.
struct ProfileSelectorView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @State private var showAddProfile = false

    var body: some View {
        VStack(spacing: 0) {
            MPNavBar(title: "Kim okuyacak?")

            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(profileManager.profiles) { profile in
                        MPListRow(
                            symbol: "person.crop.circle",
                            iconColor: profile.mpColor,
                            title: profile.name,
                            description: "\(profile.mpAgeRange.shortLabel) yaş · \(storyCount(profile)) masal",
                            action: { profileManager.switchProfile(to: profile) }
                        ) {
                            if profileManager.currentProfile?.id == profile.id {
                                MPIcon("checkmark", size: 20, weight: .bold)
                                    .foregroundStyle(MP.C.brand)
                            }
                        }
                    }
                }
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }

            MPButton(title: "Yeni profil ekle", variant: .outline, icon: "plus", fullWidth: true) {
                showAddProfile = true
            }
            .padding(.horizontal, MP.S.screenGutter)
            .padding(.bottom, 12)
        }
        .mpScreenBackground()
        .fullScreenCover(isPresented: $showAddProfile) {
            ProfileCreationView(mode: .addAnother)
        }
    }

    private func storyCount(_ p: UserProfile) -> Int {
        storyManager.stories.filter { $0.childName == p.name }.count
    }
}
