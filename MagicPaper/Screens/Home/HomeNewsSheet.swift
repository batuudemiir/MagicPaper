import SwiftUI

/// Ana sayfa → zil → "Yenilikler" (26 Kasım 2026, Batuhan). Sistem sheet'i
/// (`MPSheet`), satırlar ana sayfanın `HomeListRow`'u. Açılınca bütün
/// yenilikler görülmüş sayılır, zilin noktası söner. Ragi'siz: arkadaki ana
/// sayfanın Ragi'si yeter (menüdeki gibi).
struct HomeNewsSheet: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var news = HomeNews(items: [])

    var body: some View {
        MPSheet(title: "Yenilikler", onClose: close) {
            if news.isEmpty {
                // Boş durum ebeveyn dili değil ama ikinci Ragi de değil: yalnızca söz.
                VStack(spacing: MPSpacing.sm) {
                    Text("Şimdilik yeni bir şey yok").mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                    Text("Masal okudukça rozetlerin ve serinin yeni bölümleri burada görünür.")
                        .mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MPSpacing.xl)
            } else {
                VStack(spacing: MPSpacing.sm) {
                    ForEach(news.items) { item in
                        HomeListRow(systemImage: item.systemImage, tone: item.tone, title: item.title,
                                    subtitle: item.subtitle) { open(item) }
                    }
                }
            }
        }
        .onAppear {
            let child = profileManager.currentProfile?.id
            news = HomeNews.live(childID: child)
            HomeNewsSeen.markSeen(news, for: child)
        }
    }

    private func open(_ item: HomeNews.Item) {
        guard let child = profileManager.currentProfile?.id else { return }
        MPHaptics.tap()
        app.router.closeSheet {
            switch item.action {
            case .badges:
                MPBadgeNews.shared.clearDot(child)
                app.router.openKidPage(.badges(child))
            case .series:
                SeriesManager.shared.refreshUnlocks(for: child)
                app.router.openKidPage(.series(child))
            case .masallar:
                app.router.tab = .gunluk
                app.router.masallarPath = []
            case .tale(let id):
                app.router.tab = .gunluk
                app.router.masallarPath = [.tale(id)]
            }
        }
    }

    private func close() { app.router.sheet = nil }
}
