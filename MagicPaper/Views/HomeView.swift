import SwiftUI

/// Ana sayfa — 03-SCREENS.md §3.
struct HomeView: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var streak = MPStreak.shared

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MP.S.sectionGap) {
                    heroCard
                    worldsSection
                    recentStoriesSection
                    streakCard
                }
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
        }
        .mpScreenBackground()
    }

    // MARK: - Başlık satırı

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                app.sheet = .profilePicker
            } label: {
                HStack(spacing: 10) {
                    MPAvatar(name: activeName, color: profileManager.currentProfile?.mpColor, size: 44)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Merhaba,")
                            .font(MP.F.labelSM())
                            .foregroundStyle(MP.C.textMuted)
                        HStack(spacing: 4) {
                            Text(activeName)
                                .font(MP.F.displaySM())
                                .foregroundStyle(MP.C.textTitle)
                                .lineLimit(1)
                            MPIcon("chevron.down", size: 17, weight: .semibold)
                                .foregroundStyle(MP.C.textFaint)
                        }
                    }
                }
            }
            .buttonStyle(MPPressStyle(scales: false))

            Spacer(minLength: 0)

            MPStarPill(count: starCount) { app.openPaywall() }
        }
        .padding(.horizontal, MP.S.screenGutter)
        .padding(.vertical, 4)
    }

    private var activeName: String {
        profileManager.currentProfile?.name ?? "Arkadaşım"
    }

    /// Kalan görselli masal hakkı. Birim adı her zaman "Yıldız".
    private var starCount: Int {
        subscriptionManager.isPremium
            ? subscriptionManager.remainingImageStories
            : subscriptionManager.freeTrialCount
    }

    // MARK: - Marka hero kartı

    private var heroCard: some View {
        MPPressableCard(tone: .brand, padding: 22, action: { app.startStoryCreation() }) {
            HStack(spacing: 16) {
                MPIcon("wand.and.stars", size: 28, weight: .semibold)
                    .foregroundStyle(MP.C.textOnBrand)
                    .frame(width: 54, height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.2))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Yeni bir masal yarat")
                        .font(MP.F.displaySM())
                        .foregroundStyle(MP.C.textOnBrand)
                    Text("İki seçim yap, gerisini biz yazalım")
                        .font(MP.F.bodySM(.semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                MPIcon("arrow.right", size: 22, weight: .semibold)
                    .foregroundStyle(MP.C.textOnBrand)
            }
        }
    }

    // MARK: - Masal dünyaları

    private var worldsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: "Masal dünyaları",
                            subtitle: "Bir dünya seç, gerisini biz yazalım")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MP.World.ordered) { world in
                        MPChoiceTile(
                            title: world.name,
                            symbol: world.symbol,
                            accent: world.accent,
                            isLocked: world.isPremium && !subscriptionManager.isPremium,
                            layout: .column
                        ) {
                            if world.isPremium && !subscriptionManager.isPremium {
                                app.openPaywall()
                            } else {
                                app.startWizard(world: world)
                            }
                        }
                        .frame(width: 132)
                    }
                }
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.bottom, 6)
            }
            .scrollClipDisabled()
            .padding(.horizontal, -MP.S.screenGutter)
        }
    }

    // MARK: - Son masallar

    private var recentStories: [Story] {
        storyManager.stories
            .filter { $0.belongs(to: profileManager.currentProfile) }
            .prefix(4)
            .map { $0 }
    }

    private var recentStoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: "Son masallar",
                            actionLabel: "Tümü",
                            action: { app.tab = .library })

            if recentStories.isEmpty {
                MPCard(tone: .sunken, padding: 22) {
                    Text("\(activeName) için henüz masal yok.")
                        .font(MP.F.bodyMD(.semibold))
                        .foregroundStyle(MP.C.textMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(recentStories) { story in
                            MPStoryCard(
                                title: story.title,
                                meta: story.mpMeta,
                                symbol: story.mpSymbol,
                                accent: story.mpAccent,
                                badge: story.isIllustrated ? "Görselli" : nil,
                                progress: (story.mpProgress > 0 && story.mpProgress < 1) ? story.mpProgress : nil,
                                layout: .shelf
                            ) {
                                app.sheet = .storyActions(story.id)
                            }
                        }
                    }
                    .padding(.horizontal, MP.S.screenGutter)
                    .padding(.bottom, 6)
                }
                .scrollClipDisabled()
                .padding(.horizontal, -MP.S.screenGutter)
            }
        }
    }

    // MARK: - Seri kartı

    private var streakCard: some View {
        MPCard(padding: 18) {
            HStack(spacing: 14) {
                MPIcon("flame.fill", size: 22, weight: .semibold)
                    .foregroundStyle(MP.C.play)
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(MP.C.playSoft)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(streak.currentStreak) günlük seri")
                        .font(MP.F.bodyMD(.bold))
                        .foregroundStyle(MP.C.textTitle)
                    Text(streak.readToday
                         ? "Bugünün masalını okudunuz"
                         : "Bugünün masalını henüz okumadınız")
                        .font(MP.F.labelSM(.regular))
                        .foregroundStyle(MP.C.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                MPButton(title: "Bak", variant: .soft, size: .sm) {
                    app.tab = .daily
                }
            }
        }
    }
}
