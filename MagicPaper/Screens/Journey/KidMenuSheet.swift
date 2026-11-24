import SwiftUI

/// Ana sayfa → menü (23 Kasım 2026, İrem; prototip `yolculuk.js`). Sistem sheet'i
/// (`MPSheet`): başlıkta soru, altında uygulamanın var olan sayfaları ana
/// sayfanın liste satırlarıyla (`HomeListRow`), en altta ebeveyn kapısı. Seçince
/// sheet kapanır, sayfa açık sekmenin yığınına itilir (`closeSheet(then:)`).
struct KidMenuSheet: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var profileManager = ProfileManager.shared

    private struct Item: Identifiable {
        let id: String
        let systemImage: String
        let tone: MPWorldTone
        let title: String
        let subtitle: String
        let route: (UUID) -> MPKidRoute
    }

    private static let items: [Item] = [
        Item(id: "journey", systemImage: "point.topleft.down.to.point.bottomright.curvepath", tone: .lav,
             title: "Okuma yolculuğum", subtitle: "Haftan, yıldızların ve rozetlerin", route: { .journey($0) }),
        Item(id: "badges", systemImage: "rosette", tone: .yellow,
             title: "Rozetlerim", subtitle: "Okudukça açılan rozetler", route: { .badges($0) }),
        Item(id: "stickers", systemImage: "seal", tone: .pink,
             title: "Çıkartma albümüm", subtitle: "Her masaldan bir çıkartma", route: { .stickers($0) }),
        Item(id: "words", systemImage: "textformat", tone: .mint,
             title: "Yeni kelimelerim", subtitle: "Masallarda öğrendiklerin", route: { .newWords($0) }),
        Item(id: "map", systemImage: "map", tone: .sky,
             title: "Masal haritam", subtitle: "Gezdiğin masal dünyaları", route: { .storyMap($0) }),
        Item(id: "family", systemImage: "person.2", tone: .peach,
             title: "Masal ailem", subtitle: "Masallara katılan ailen", route: { .familyCharacters($0) }),
        Item(id: "decor", systemImage: "paintpalette", tone: .green,
             title: "Kitaplık renklerim", subtitle: "Yıldızlarınla süsle", route: { .decor($0) }),
    ]

    var body: some View {
        // Ragi'siz (24 Kasım 2026): arkadaki ana sayfanın Ragi'si yeter,
        // ekranda tek Ragi. Soru sheet'in başlığı.
        MPSheet(title: "Nereye gidelim, \(name)?", onClose: close) {
            VStack(alignment: .leading, spacing: MPSpacing.lg) {
                VStack(spacing: MPSpacing.sm) {
                    ForEach(Self.items) { item in
                        HomeListRow(systemImage: item.systemImage, tone: item.tone, title: item.title,
                                    subtitle: item.subtitle) { open(item) }
                    }
                }
                MPButton(title: "Büyükler için", systemImage: "lock", kind: .ghost, fullWidth: true) {
                    MPHaptics.tap()
                    app.router.closeSheet { app.router.requestParentMode() }
                }
            }
        }
    }

    private var name: String { profileManager.currentProfile?.name ?? "arkadaşım" }

    private func open(_ item: Item) {
        guard let id = profileManager.currentProfile?.id else { return }
        MPHaptics.tap()
        app.router.closeSheet { app.router.openKidPage(item.route(id)) }
    }

    private func close() { app.router.sheet = nil }
}
