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
    @State private var interestChoices: [InterestChoice] = []

    var body: some View {
        VStack(spacing: 0) {
            MPParentHeader(title: "Çocuklar", subtitle: subtitle)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MP.S.sectionGap) {
                    profilesSection
                    // FAZ 10'da kalkan "Favori dünyalar"ın yeri. Sunulan
                    // kelime eşiğin altındaysa bölüm hiç görünmez.
                    if ChildInterests.isShown(interestChoices) {
                        interestsSection
                    }
                }
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.top, MP.S.x3)
                .padding(.bottom, MP.S.x7)
            }
        }
        .mpScreenBackground()
        .onAppear { interestChoices = StoryChoiceSources.current.interestChoices() }
    }

    private var subtitle: String {
        let count = profileManager.profiles.count
        return count == 1 ? "Bir çocuk profili" : "\(count) çocuk profili"
    }

    // MARK: - Profiller

    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            LegacyMPSectionHeader(title: "Çocuk profilleri",
                            actionLabel: "Ekle",
                            action: { app.showProfileAdd = true })

            LegacyMPCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(profileManager.profiles.enumerated()), id: \.element.id) { index, profile in
                        if index > 0 { LegacyMPRowDivider() }
                        LegacyMPListRow(
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

    // MARK: - İlgi alanları (FAZ 12)

    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: MP.S.x4) {
            LegacyMPSectionHeader(title: InterestCopy.sectionTitle, subtitle: InterestCopy.sectionSubtitle)

            LegacyMPCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(profileManager.profiles.enumerated()), id: \.element.id) { index, profile in
                        if index > 0 { LegacyMPRowDivider() }
                        let names = interestNames(profile)
                        LegacyMPListRow(
                            symbol: InterestCopy.rowSymbol,
                            iconColor: profile.mpColor,
                            title: profile.name,
                            description: InterestCopy.summary(names),
                            action: { app.sheet = .interests(profile.id) }
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(InterestCopy.rowAccessibility(child: profile.name, names: names))
                        .accessibilityHint(InterestCopy.rowHint)
                        .accessibilityAddTraits(.isButton)
                    }
                }
            }
        }
    }

    /// The chip names of what this child has, in catalog order; a stored word
    /// the catalog no longer offers is not shown.
    private func interestNames(_ profile: UserProfile) -> [String] {
        let offered = Set(ChildInterests.offered(profile.interests, from: interestChoices))
        return interestChoices.filter { offered.contains($0.id) }.map(\.name)
    }

    private func storyCount(_ p: UserProfile) -> Int {
        storyManager.stories.filter { $0.isReadable && $0.belongs(to: p) }.count
    }
}
