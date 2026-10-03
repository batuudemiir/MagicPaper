import SwiftUI

/// Ebeveyn modu · **Çocuklar**.
///
/// Profiller ve her çocuğun döndüğü dünyalar. Eski Ebeveyn panelinde
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
                    favoriteWorlds
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

    // MARK: - Favori dünyalar

    private var favoriteWorlds: some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: "Favori dünyalar")
            MPWrapRow(spacing: 10) {
                ForEach(topWorlds, id: \.self) { world in
                    // Tıklanabilir görünen bir kontrol bir şey yapmalı:
                    // dokunmak masal oluşturma akışını açar.
                    MPChip(title: world.name, symbol: world.symbol, isSelected: true) {
                        app.startStoryCreation()
                    }
                    .accessibilityHint("Masal oluşturmayı açar")
                }
            }
        }
    }

    private var topWorlds: [MP.World] {
        let counts = Dictionary(grouping: storyManager.stories, by: { $0.mpWorld })
            .mapValues(\.count)
        let sorted = counts.sorted { $0.value > $1.value }.map(\.key)
        return sorted.isEmpty ? Array(MP.World.ordered.prefix(3)) : Array(sorted.prefix(3))
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
        storyManager.stories.filter { $0.belongs(to: p) }.count
    }
}
