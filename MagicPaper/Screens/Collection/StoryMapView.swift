import SwiftUI

/// Masal haritası (Faz 10): çocuğun masallarda gittiği yerler. Her yer bir iğne:
/// adı, kaç masal ve orada tanıştığı yol arkadaşları. Gidilmemiş yerler soluk bir
/// "?" olarak durur; sayı ya da "kaldı" sözü yok (CLAUDE.md ilke 7).
struct StoryMapPlace: Identifiable, Equatable {
    let id: String
    let name: String
    let world: MP.World?
    let storyCount: Int
    let friends: [String]
    var visited: Bool { storyCount > 0 }
}

enum StoryMapModel {
    /// Gidilen yerler önce (en çok gidilen başta), sonra gidilmemişler katalog sırasıyla.
    static func places(stories: [Story],
                       catalog: [(id: String, place: StoryMemory.Place, tags: [String])],
                       companionName: (String) -> String?) -> [StoryMapPlace] {
        let finished = stories.filter { $0.isFinished }
        var visited: [StoryMapPlace] = []
        var unvisited: [StoryMapPlace] = []
        for entry in catalog {
            let here = finished.filter { $0.origin?.settingID == entry.id }
            var friends: [String] = []
            for story in here {
                if let id = story.origin?.companionID, let name = companionName(id), !friends.contains(name) {
                    friends.append(name)
                }
            }
            let place = StoryMapPlace(id: entry.id, name: entry.place.name,
                                      world: MP.World.from(settingTags: entry.tags),
                                      storyCount: here.count, friends: friends)
            if place.visited { visited.append(place) } else { unvisited.append(place) }
        }
        return visited.sorted { $0.storyCount > $1.storyCount } + unvisited
    }
}

struct StoryMapView: View {
    let profile: UserProfile

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @Environment(\.dynamicTypeSize) private var typeSize

    private var places: [StoryMapPlace] {
        let service = OfflineStoryService.shared
        return StoryMapModel.places(stories: storyManager.stories.filter { $0.belongs(to: profile) },
                                    catalog: service.allPlaces(),
                                    companionName: { service.companionName(id: $0) })
    }

    var body: some View {
        let all = places
        let visitedCount = all.filter(\.visited).count
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                MPTopBar(title: "Masal haritam",
                         subtitle: visitedCount == 0 ? nil : "\(visitedCount) yere gittin",
                         onBack: { app.router.closeKidPage() }) { EmptyView() }

                if visitedCount == 0 {
                    MPStateView(mascot: .walking, title: "Haritan seni bekliyor",
                                message: "Her masal bir yere götürür. İlk masalını yaz, ilk iğne buraya düşsün.") {
                        MPButton(title: "Masal yaz", systemImage: "wand.and.sparkles") { app.startStoryCreation() }
                    }
                } else {
                    MascotSays(mascot: .walking, text: "Gittiğin her yer burada. Yeniden gidince seni hatırlarlar.",
                               mascotWidth: 64)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.md),
                                             count: typeSize.isAccessibilitySize ? 1 : 2),
                              spacing: MPSpacing.md) {
                        ForEach(all) { place in pin(place) }
                    }
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.lg)
            .padding(.bottom, GunlukLayout.bottomClearance)
        }
        .background(MPColor.backgroundSurface.ignoresSafeArea())
    }

    @ViewBuilder
    private func pin(_ place: StoryMapPlace) -> some View {
        let tone = place.world?.tone ?? .lav
        if place.visited {
            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                MPIconTile(systemImage: place.world?.icon ?? "mappin", tone: tone, size: 44, filled: true)
                    .accessibilityHidden(true)
                Text(place.name).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(place.storyCount == 1 ? "1 masal" : "\(place.storyCount) masal")
                    .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                if !place.friends.isEmpty {
                    Text(place.friends.joined(separator: ", "))
                        .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(MPSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .mpKidSurface(tone.soft, edge: tone.edge)
            .accessibilityElement(children: .combine)
        } else {
            VStack(spacing: MPSpacing.xs) {
                Text("?").mpText(.page).foregroundStyle(MPColor.textSecondary.opacity(0.6))
                Text("Henüz gidilmedi").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 132)
            .background(RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous)
                .strokeBorder(MPColor.borderDashed, style: StrokeStyle(lineWidth: 2, dash: [6, 5])))
            .accessibilityLabel("Henüz gidilmemiş bir yer")
        }
    }
}
