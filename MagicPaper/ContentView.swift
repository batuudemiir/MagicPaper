import SwiftUI

/// Kök ekran. Çocuk modunda üç sekme + bir eylem öğesi, ebeveyn modunda
/// ebeveynin kendi üç sekmesi — `TabView` kullanılmaz,
/// çünkü eylem öğesi bir sekme değil (05-SWIFTUI-MAPPING.md).
struct ContentView: View {
    @StateObject private var app = MPAppState()
    @StateObject private var settings = MPSettingsStore.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    get: { app.isParentMode ? app.parentTab.rawValue : app.tab.rawValue },
                    set: { raw in
                        if let next = MPParentTab(rawValue: raw) { app.parentTab = next }
                        else if let next = MPTab(rawValue: raw) { app.tab = next }
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
            // Hatırlatma planı iOS'ta kalıcı ama izin Sistem Ayarları'ndan geri
            // alınabilir; ayrıca aktif çocuk değişmiş olabilir ve bildirimde
            // onun adı yazıyor. Her açılışta plan gerçeğe göre yenilenir.
            settings.reminder = await MPReminder.resync(
                enabled: settings.reminder,
                hour: settings.reminderHour,
                minute: settings.reminderMinute,
                childName: profileManager.currentProfile?.name
            )
        }
        // The reading ledger belongs to the child (MPStreak): open the active
        // child's, and switch when the parent switches profiles.
        .onChange(of: profileManager.currentProfile?.id, initial: true) { _, id in
            MPStreak.shared.activate(profileID: id)
        }
        // Ebeveyn modu oturumluk: uygulama arka plana gidince çocuk moduna döner.
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { app.enterChildMode() }
        }
        .overlay { sheetLayer }
        .fullScreenCover(isPresented: $app.showStoryCreation) {
            StoryCreationFlow().environmentObject(app).environmentObject(settings)
        }
        .fullScreenCover(isPresented: $app.showWizard) {
            StoryWizardView(preset: app.wizardPreset).environmentObject(app).environmentObject(settings)
        }
        .fullScreenCover(item: $app.detailStory) { story in
            StoryDetailView(story: story).environmentObject(app).environmentObject(settings)
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
        .fullScreenCover(isPresented: $app.showDecorationGallery) {
            StoryDecorationGallery()
        }
        .fullScreenCover(isPresented: $app.showDecorationDemo) {
            StoryDecorationDemoView().environmentObject(app)
        }
        .fullScreenCover(isPresented: $app.showProfileAdd) {
            ProfileCreationView(mode: .addAnother) { name in
                app.showToast("\(name) eklendi", symbol: "sparkles")
            }
        }
    }

    // MARK: - Sekme içeriği

    /// Mod değişince tüm sekme içeriği çapraz geçer — ebeveyn sayfaları
    /// çocuğun ekranlarının üstüne açılan bir katman değil, başka bir menü.
    private var content: some View {
        Group {
            if app.isParentMode {
                parentContent.transition(.opacity)
            } else {
                childContent.transition(.opacity)
            }
        }
        .animation(reduceMotion ? MP.M.easeOut : MP.M.base, value: app.isParentMode)
    }

    @ViewBuilder
    private var childContent: some View {
        switch app.tab {
        case .home:    HomeView()
        case .library: LibraryView()
        case .daily:   DailyStoriesView()
        }
    }

    @ViewBuilder
    private var parentContent: some View {
        switch app.parentTab {
        case .overview: ParentOverviewView()
        case .children: ParentChildrenView()
        case .settings: SettingsView()
        }
    }

    /// Çocuk: Ana Sayfa · Kütüphane · **Masal yarat** · Günlük
    /// Ebeveyn: Özet · Çocuklar · Ayarlar
    ///
    /// Ebeveyn menüsünde yaratma eylemi yok: masal çocukla birlikte, çocuk
    /// modunda yaratılır. Ebeveyn tarafı bakmak ve ayarlamak için.
    private var tabItems: [MPTabBar.Item] {
        if app.isParentMode {
            return MPParentTab.allCases.map {
                MPTabBar.Item(value: $0.rawValue, label: $0.label, symbol: $0.symbol)
            }
        }
        func item(_ tab: MPTab) -> MPTabBar.Item {
            MPTabBar.Item(value: tab.rawValue, label: tab.label, symbol: tab.symbol)
        }
        return [item(.home), item(.library),
                MPTabBar.Item(value: "create", label: "Masal yarat",
                              symbol: "wand.and.stars", kind: .action),
                item(.daily)]
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
