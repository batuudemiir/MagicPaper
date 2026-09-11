import SwiftUI

/// Kök ekran. 4 sekme + ortada yükseltilmiş (+) — `TabView` kullanılmaz,
/// ortadaki buton yüzünden bar özel çizilir (05-SWIFTUI-MAPPING.md).
struct ContentView: View {
    @StateObject private var app = MPAppState()
    @StateObject private var settings = MPSettingsStore.shared
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var storyManager = StoryGenerationManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            MP.C.surfaceApp.ignoresSafeArea()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, MP.S.tabBarHeight)

            MPTabBar(
                items: tabItems,
                selection: Binding(
                    get: { app.tab.rawValue },
                    set: { raw in
                        guard let next = MPTab(rawValue: raw) else { return }
                        app.selectTab(next, childModeOn: settings.childMode)
                    }
                ),
                onCreate: { app.startWizard() }
            )
        }
        .ignoresSafeArea(.keyboard)
        .environmentObject(app)
        .environmentObject(settings)
        .mpToast($app.toast)
        .task {
            // Akış 1: ilk profil oluşturulduysa ana sayfada karşılama toast'ı.
            if let name = MPWelcome.consume() {
                app.showToast("\(name) için hazırız", symbol: "sparkles")
            }
        }
        .overlay { sheetLayer }
        .fullScreenCover(isPresented: $app.showWizard) {
            StoryWizardView(preset: app.wizardPreset).environmentObject(app).environmentObject(settings)
        }
        .fullScreenCover(item: $app.readerStory) { story in
            StoryViewerView(story: story).environmentObject(app).environmentObject(settings)
        }
        .fullScreenCover(isPresented: $app.showPaywall) {
            PaywallView().environmentObject(app)
        }
        .fullScreenCover(isPresented: $app.showGate) {
            ParentalGateView(onSuccess: { app.unlockParent() }, onCancel: { app.showGate = false })
        }
        .fullScreenCover(isPresented: $app.showSettings) {
            SettingsView().environmentObject(app).environmentObject(settings)
        }
        .fullScreenCover(isPresented: $app.showProfileAdd) {
            ProfileCreationView(mode: .addAnother) { name in
                app.showToast("\(name) eklendi", symbol: "sparkles")
            }
        }
    }

    // MARK: - Sekme içeriği

    @ViewBuilder
    private var content: some View {
        switch app.tab {
        case .home:    HomeView()
        case .library: LibraryView()
        case .daily:   DailyStoriesView()
        case .parent:  ParentPanelView()
        }
    }

    private var tabItems: [MPTabBar.Item] {
        MPTab.allCases.map { tab in
            MPTabBar.Item(
                value: tab.rawValue,
                label: tab.label,
                // Çocuk modunda ebeveyn sekmesi kilitli görünür
                symbol: (tab == .parent && settings.childMode) ? "lock.fill" : tab.symbol
            )
        }
    }

    // MARK: - Alt sayfa katmanı
    //
    // MPSheet kendi geometrisini çizer (32px üst köşe, %86 max yükseklik),
    // bu yüzden `.sheet` yerine ekranın üstünde bir katman olarak durur.

    @ViewBuilder
    private var sheetLayer: some View {
        if let route = app.sheet {
            switch route {
            case .profilePicker:
                ProfilePickerSheet()
                    .environmentObject(app)
            case .storyActions(let id):
                if let story = storyManager.stories.first(where: { $0.id == id }) {
                    StoryActionsSheet(story: story).environmentObject(app)
                }
            case .profileEdit(let id):
                if let profile = profileManager.profiles.first(where: { $0.id == id }) {
                    ProfileEditSheet(profile: profile).environmentObject(app)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
