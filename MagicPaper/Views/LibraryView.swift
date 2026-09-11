import SwiftUI

/// Kütüphane — 03-SCREENS.md §9.
struct LibraryView: View {
    @EnvironmentObject private var app: MPAppState
    @StateObject private var storyManager = StoryGenerationManager.shared
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var favorites = MPFavorites.shared

    enum Filter: String, CaseIterable {
        case all = "Tümü", illustrated = "Görselli", favorite = "Favori"
    }

    @State private var query = ""
    @State private var filter: Filter = .all
    /// Kapsam: yalnızca aktif çocuk ↔ tüm çocuklar.
    @State private var allChildren = false

    var body: some View {
        VStack(spacing: 0) {
            MPNavBar(title: "Kütüphane") {
                MPIconButton(
                    symbol: allChildren ? "person.2.circle" : "person.crop.circle",
                    label: "Kapsam"
                ) {
                    withAnimation(MP.M.gated(MP.M.easeOut)) { allChildren.toggle() }
                }
            }

            filters

            if visibleStories.isEmpty {
                ScrollView(showsIndicators: false) {
                    MPEmptyState(
                        title: "Burada masal yok",
                        description: query.isEmpty
                            ? "İlk masalını yaratınca burada belirecek."
                            : "Aramanla eşleşen bir masal bulamadık.",
                        illustration: "AppLogo",
                        actionLabel: "Masal yarat",
                        action: { app.startWizard() }
                    )
                    .padding(.top, 20)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(visibleStories) { story in
                            MPStoryCard(
                                title: story.title,
                                meta: story.mpMetaWithChild,
                                symbol: story.mpSymbol,
                                accent: story.mpAccent,
                                badge: story.isIllustrated ? "Görselli" : nil,
                                progress: (story.mpProgress > 0 && story.mpProgress < 1) ? story.mpProgress : nil,
                                layout: .row
                            ) {
                                app.sheet = .storyActions(story.id)
                            }
                        }
                    }
                    .padding(.horizontal, MP.S.screenGutter)
                    .padding(.bottom, 24)
                }
            }
        }
        .mpScreenBackground()
    }

    private var filters: some View {
        VStack(spacing: 10) {
            MPInput(placeholder: "Masal ara", text: $query, symbol: "magnifyingglass")

            MPWrapRow(spacing: 10) {
                ForEach(Filter.allCases, id: \.self) { f in
                    MPChip(title: f.rawValue, isSelected: filter == f) {
                        withAnimation(MP.M.gated(MP.M.easeOut)) { filter = f }
                    }
                }
            }
        }
        .padding(.horizontal, MP.S.screenGutter)
        .padding(.top, 4)
        .padding(.bottom, 14)
    }

    private var visibleStories: [Story] {
        var list = storyManager.stories

        if !allChildren, let active = profileManager.currentProfile?.name {
            list = list.filter { $0.childName == active || $0.childName.isEmpty }
        }

        switch filter {
        case .all: break
        case .illustrated: list = list.filter { $0.isIllustrated }
        case .favorite: list = list.filter { favorites.contains($0.id) }
        }

        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            // Türkçe locale ile küçük harfe çevrilir — i/ı ayrımı için zorunlu.
            let needle = MPText.foldedForSearch(trimmed)
            list = list.filter {
                MPText.foldedForSearch($0.title).contains(needle)
                || MPText.foldedForSearch($0.childName).contains(needle)
            }
        }
        return list
    }
}
