import SwiftUI

/// Kök ekran. Dört sekme + ortada bir eylem öğesi — `TabView` kullanılmaz,
/// çünkü eylem öğesi bir sekme değil (05-SWIFTUI-MAPPING.md).
struct ContentView: View {
    @StateObject private var app = MPAppState()
    @StateObject private var settings = MPSettingsStore.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            MP.C.surfaceApp.ignoresSafeArea()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Yükseltilen eylem düğmesinin taşması dahil. Öncesinde
                // yalnızca bar yüksekliği bırakılıyordu ve düğme her ekranda
                // içeriğin üstüne biniyordu.
                .padding(.bottom, MPTabBar.reservedHeight)

            MPTabBar(
                items: tabItems,
                selection: Binding(
                    get: { app.tab.rawValue },
                    set: { raw in
                        guard let next = MPTab(rawValue: raw) else { return }
                        app.selectTab(next, childModeOn: settings.childMode)
                    }
                ),
                onCreate: { app.startStoryCreation() }
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
        .fullScreenCover(isPresented: $app.showStoryCreation) {
            StoryCreationFlow().environmentObject(app).environmentObject(settings)
        }
        .fullScreenCover(isPresented: $app.showWizard) {
            StoryWizardView(preset: app.wizardPreset).environmentObject(app).environmentObject(settings)
        }
        .fullScreenCover(item: $app.readerStory) { story in
            StoryReaderView(story: story).environmentObject(app).environmentObject(settings)
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

    /// Ana Sayfa · Kütüphane · **Masal yarat** · Günlük · Ebeveyn
    ///
    /// Eylem ortada duruyor: iki yanına ikişer yer düşüyor, yani bar simetrik
    /// ve en çok kullanılan iş baş parmağın doğal yerinde.
    private var tabItems: [MPTabBar.Item] {
        func item(_ tab: MPTab) -> MPTabBar.Item {
            MPTabBar.Item(
                value: tab.rawValue,
                label: tab.label,
                // Çocuk modunda ebeveyn sekmesi kilitli görünür
                symbol: (tab == .parent && settings.childMode) ? "lock.fill" : tab.symbol
            )
        }
        return [item(.home), item(.library),
                MPTabBar.Item(value: "create", label: "Masal yarat",
                              symbol: "wand.and.stars", kind: .action),
                item(.daily), item(.parent)]
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
