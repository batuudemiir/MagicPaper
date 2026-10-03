import SwiftUI

/// Ebeveyn modu · **Çocuklar**.
///
/// Çocuk profilleri. Eski Ebeveyn panelinde
/// istatistiklerin ve aboneliğin arasında sıkışmışlardı; oysa bir ebeveynin
/// en sık yaptığı düzenleme budur — kardeş eklemek, yaşı güncellemek.
struct ParentChildrenView: View {
    @EnvironmentObject private var app: MPAppState

    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared

    var body: some View {
        VStack(spacing: 0) {
            MPParentHeader(title: "Çocuklar", subtitle: subtitle)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MP.S.sectionGap) {
                    profilesSection
                }
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.top, MP.S.x3)
                .padding(.bottom, MP.S.x7)
            }
        }
        .mpScreenBackground()
    }

    private var subtitle: String {
        let count = profileManager.profiles.count
        return count == 1 ? "Bir çocuk profili" : "\(count) çocuk profili"
    }

    // MARK: - Profiller

    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: "Çocuk profilleri",
                            actionLabel: "Ekle",
                            action: { app.showProfileAdd = true })

            MPCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(profileManager.profiles.enumerated()), id: \.element.id) { index, profile in
                        if index > 0 { MPRowDivider() }
                        MPListRow(
                            symbol: "person.crop.circle",
                            iconColor: profile.mpColor,
                            title: profile.name,
                            description: "\(profile.mpAgeRange.shortLabel) yaş · \(storyCount(profile)) masal",
                            action: { app.sheet = .profileEdit(profile.id) }
                        )
                    }
                }
            }
        }
    }

    private func storyCount(_ p: UserProfile) -> Int {
        storyManager.stories.filter { $0.isReadable && $0.belongs(to: p) }.count
    }
}
