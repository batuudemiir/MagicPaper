import SwiftUI

/// "Kim okuyor?": profiller varken hiçbiri seçili değilse `MainContentView`
/// buraya düşer. Benim köşem'deki seçiciyle aynı dil: renkli harf madalyonu,
/// ad, yaş bandı ve masal sayısı.
struct ProfileSelectorView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @State private var showAddProfile = false

    var body: some View {
        VStack(spacing: 0) {
            MPTopBar(title: "Kim okuyor?") { EmptyView() }
                .padding(.horizontal, MPSpacing.screenH)

            ScrollView(showsIndicators: false) {
                VStack(spacing: MPSpacing.md) {
                    // Çocuğun açılışta gördüğü ilk ekran: Ragi karşılar (23 Ekim 2026).
                    MascotSays(mascot: .waving, text: "Merhaba! Bugün masalı kim dinleyecek?", mascotWidth: 72)
                        .padding(.bottom, MPSpacing.sm)
                    ForEach(profileManager.profiles) { profile in
                        Button { profileManager.switchProfile(to: profile) } label: {
                            HStack(spacing: MPSpacing.md) {
                                MPInitialAvatar(name: profile.name, color: profile.mpColor)
                                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                                    Text(profile.name).mpText(.headline).foregroundStyle(MPColor.textPrimary)
                                    Text("\(profile.mpAgeRange.shortLabel) yaş · \(storyCount(profile)) masal")
                                        .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                                }
                                Spacer(minLength: 0)
                                MPChevron()
                            }
                            .padding(MPSpacing.lg)
                            .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
                            .mpShadow(.card)
                        }
                        .buttonStyle(MPPressStyle())
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.vertical, MPSpacing.lg)
            }

            MPButton(title: "Yeni profil ekle", systemImage: "plus", kind: .outline, fullWidth: true) {
                showAddProfile = true
            }
            .padding(.horizontal, MPSpacing.xl)
            .padding(.vertical, MPSpacing.md)
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .fullScreenCover(isPresented: $showAddProfile) {
            ProfileCreationView(mode: .addAnother)
        }
    }

    private func storyCount(_ p: UserProfile) -> Int {
        storyManager.stories.filter { $0.isReadable && $0.belongs(to: p) }.count
    }
}
