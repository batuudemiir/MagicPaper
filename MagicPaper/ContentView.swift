import StoryEngine
import SwiftUI

/// Kök ekran (FAZ 17, Pastel Masal).
///
/// Çocuk kökü: dört sekme ve "Masal yaz". Ebeveyn odası üstüne açılır, sistem
/// sekme çubuğuyla Özet · Güvenlik · Ayarlar (`ParentTabs`, 29, 31, 32). Odaya
/// yalnızca kapıdan girilir (Profil > Büyükler için); uygulama arka plana gidince
/// oda kapanır. Harita: `docs/SAYFA_MIMARISI.md`.
struct ContentView: View {
    @StateObject private var app = MPAppState()
    @StateObject private var settings = MPSettingsStore.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var account = AccountService.shared
    /// Widget, Live Activity ve Siri'nin açtığı yer (FAZ 19).
    @ObservedObject private var surfaceRouter = MPSurfaceRouter.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Masal yaz dairesinden masal yazma ekranına yakınlaşma.
    @Namespace private var createZoom
    /// Kitaplıktaki kapaktan okuyucuya yakınlaşma (Faz 13).
    @Namespace private var readerZoom
    /// Masal yazma ekranı Masal yaz dairesinden mi açıldı. Başka yerden
    /// (ana sayfa kartları) açılınca daireden büyümez.
    @State private var createFromBar = false
    /// 09 + 10: ilk profil oluştuktan sonra bir kez.
    @State private var firstRun: FirstRunName?
    /// İlk masal hazırsa, kapak kapandıktan sonra okunur.
    @State private var firstStory: Story?

    var body: some View {
        content
            .mpReaderZoom(reduceMotion ? nil : readerZoom)
            .ignoresSafeArea(.keyboard)
            .environmentObject(app)
            .environmentObject(settings)
            .mpToast($app.toast)
            .task {
                // İçerik akışı (FAZ 15): yeni günün masalı yeniden başlatmadan gelir.
                await RemoteContentService.shared.refresh()
            }
            #if DEBUG
            .onAppear {
                if let tab = MPDebugLaunch.startTab { app.router.tab = tab }
                if MPDebugLaunch.startsInParent { app.router.unlockParent() }
                if let tab = MPDebugLaunch.parentTab { app.router.parentTab = tab }
                if let route = MPDebugLaunch.parentRoute { app.router.parentRoute = route }
            }
            #endif
            .task {
                // Akış 1: ilk profil oluşturulduysa ana sayfada karşılama toast'ı.
                if let name = MPWelcome.consume() {
                    firstRun = FirstRunName(name: name)
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
            .onChange(of: profileManager.currentProfile?.safety) { _, _ in
                OfflineStoryService.shared.currentSafety = profileManager.currentProfile?.effectiveSafety
            }
            .onChange(of: profileManager.currentProfile?.id, initial: true) { _, id in
                app.router.closePagesOfPreviousChild()
                MPStreak.shared.activate(profileID: id)
            // İçerik güvenliği (FAZ 17) çocuk başına: her sorgu ve masal bunu okur.
            OfflineStoryService.shared.currentSafety = profileManager.currentProfile?.effectiveSafety
                // A series episode whose day has come opens here (FAZ 13); no
                // notification announces it.
                if let id { SeriesManager.shared.refreshUnlocks(for: id) }
                DailyStoryManager.shared.refreshForToday()
                // Widget'lar o an seçili çocuğu gösterir (FAZ 19).
                MPSurfaceSync.refresh()
            }
            // Ebeveyn modu oturumluk: uygulama arka plana gidince çocuk moduna döner.
            .onChange(of: scenePhase) { _, phase in
                if phase == .background {
                    app.router.enterChildMode()
                    RemoteContentService.scheduleBackgroundRefresh()
                    MPSurfaceSync.refresh()
                }
                if phase == .active, let id = profileManager.currentProfile?.id {
                    SeriesManager.shared.refreshUnlocks(for: id)
                }
                if phase == .active {
                    // Gün dönmüş olabilir; akış yarım saatte bir yoklanır.
                    DailyStoryManager.shared.refreshForToday()
                    Task { await RemoteContentService.shared.refreshIfDue() }
                }
            }
            // Aile daveti bağlantısı (FAZ 18): kapıdan geçip Aile üyeleri'nde açılır.
            .onChange(of: account.pendingInviteCode, initial: true) { _, code in
                guard code != nil else { return }
                if app.router.isParentMode { app.router.parentRoute = .familyMembers } else { app.router.requestParentMode() }
            }
            .onChange(of: app.router.isParentMode) { _, parent in
                if parent && account.pendingInviteCode != nil { app.router.parentRoute = .familyMembers }
            }
            // Widget, Live Activity ve Siri (FAZ 19): uygulama kök ekrana
            // varınca işlenir; giriş ya da profil seçimi sırasında bekler.
            .onChange(of: surfaceRouter.pending, initial: true) { _, link in
                guard let link else { return }
                surfaceRouter.pending = nil
                app.open(link, childID: profileManager.currentProfile?.id)
            }
            .sheet(item: $app.router.sheet, onDismiss: { app.router.runAfterSheet() }) { route in
                sheetContent(route).environmentObject(app)
            }
            .fullScreenCover(item: $app.sleepSession, onDismiss: { MPSurfaceSync.refresh() }) { session in
                SleepModeView(session: session).environmentObject(app)
            }
            .sheet(isPresented: $app.showBedtimeSheet, onDismiss: { app.runBedtimeChoice() }) {
                BedtimeStorySheet(resumeStory: MPTonightSource.current().resumeStory,
                                  canListen: MPFeatures.sleepMode && MPTonightSource.sleepSession() != nil) { choice in
                    app.pendingBedtimeChoice = choice
                }
            }
            .fullScreenCover(isPresented: $app.showStoryCreation, onDismiss: {
                app.creationPreset = nil
                app.creationFamilyID = nil
                createFromBar = false
                app.runAfterReader()
            }) {
                StoryCreationFlow(preset: app.creationPreset, family: app.creationFamilyID).environmentObject(app).environmentObject(settings)
                    .mpZoomDestination(KidTabBar.createZoomID,
                                       in: createFromBar && !reduceMotion ? createZoom : nil)
            }
            .sheet(item: $app.actionsStory, onDismiss: {
                if let next = app.pendingRead {
                    app.pendingRead = nil
                    app.read(next.story, fromStart: next.startPage == 0)
                }
            }) { story in
                StoryActionsSheet(story: story) { chosen, fromStart in
                    app.pendingRead = (chosen, fromStart ? 0 : nil)
                }
                .environmentObject(app)
            }
            .fullScreenCover(item: $app.readerStory, onDismiss: {
                app.readerStartPage = nil
                app.readerZoomID = nil
                MPSurfaceSync.refresh()
                app.runAfterReader()
            }) { story in
                StoryReaderView(story: story, startingPage: app.readerStartPage).environmentObject(app).environmentObject(settings)
                    .mpZoomDestination(story.id.uuidString,
                                       in: app.readerZoomID == story.id && !reduceMotion ? readerZoom : nil)
            }
            .fullScreenCover(isPresented: $app.showPaywall) {
                PaywallView().environmentObject(app)
            }
            .fullScreenCover(isPresented: $app.router.showGate, onDismiss: { app.router.gateDismissed() }) {
                ParentalGateView(onSuccess: { app.router.gateSucceeded() }, onCancel: { app.router.showGate = false })
            }
            .fullScreenCover(item: $firstRun, onDismiss: {
                if let story = firstStory {
                    firstStory = nil
                    app.read(story, fromStart: true)
                }
            }) { run in
                FirstRunView(childName: run.name) { story in
                    firstStory = story
                    firstRun = nil
                }
            }
            .fullScreenCover(isPresented: $app.router.showProfileAdd) {
                ProfileCreationView(mode: .addAnother) { name in
                    app.showToast("\(name) eklendi", symbol: "sparkles")
                }
            }
    }

    // MARK: - Sekme içeriği

    /// Uygulama çocuğundur; ebeveyn alanı üstüne açılan bir odadır (karar: 7 Kasım
    /// 2026, `docs/SAYFA_MIMARISI.md`). Çocuk kökü hep canlı: oda kapanınca açık
    /// sekme ve sayfa yerinde durur. Oda açıkken çocuk kökü dokunmaya ve
    /// VoiceOver'a kapalı. Sunumlar (`body`) iki alanın da üstüne açılabilsin diye
    /// oda bir `fullScreenCover` değil.
    private var content: some View {
        ZStack {
            kidRoot
                .allowsHitTesting(!app.router.isParentMode)
                .accessibilityHidden(app.router.isParentMode)

            if app.router.isParentMode {
                parentRoot
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .animation(reduceMotion ? MP.M.easeOut : MP.M.base, value: app.router.isParentMode)
    }

    private var tabTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .offset(y: MP.S.x3))
    }

    private var kidRoot: some View {
        ZStack(alignment: .bottom) {
            MPColor.backgroundKid.ignoresSafeArea()

            if #available(iOS 26.0, *) {
                systemKidTabs
            } else {
                customKidTabs
            }
        }
    }

    /// Alt çubuğun yuvası: dört sekme ve "Masal yaz".
    private enum KidTabSlot: Hashable {
        case tab(KidTab)
        case create
    }

    /// iOS 26: sistemin Liquid Glass sekme çubuğu (22 Ekim 2026, Batuhan).
    ///
    /// Sürükleyerek seçme, mercek, cam ve erişilebilirlik sistemden gelir.
    /// "Masal yaz" `createTabRole` ile ayrı durur. Bir yer değil eylem olduğu için seçimi hiç tutulmaz:
    /// bağlama ona geçmek istediğinde masal yazma açılır, seçili sekme aynı
    /// kalır. Sistem dairesi yakınlaşma kaynağı olamadığından masal yazma
    /// burada olağan geçişle açılır.
    @available(iOS 26.0, *)
    private var systemKidTabs: some View {
        TabView(selection: Binding<KidTabSlot>(
            get: { .tab(app.router.tab.kidTab) },
            set: { next in
                switch next {
                case .tab(let tab): selectKidTab(tab)
                case .create:
                    MPHaptics.tap()
                    app.startStoryCreation()
                }
            }
        )) {
            Tab("Ana sayfa", systemImage: "house", value: KidTabSlot.tab(.home)) { KidTabStack(tab: .home) { HomeView() } }
            Tab("Masallar", systemImage: "book", value: KidTabSlot.tab(.gunluk)) { GunlukView() }
            Tab("Kitaplık", systemImage: "books.vertical", value: KidTabSlot.tab(.library)) { KidTabStack(tab: .library) { LibraryView() } }
            Tab("Odam", systemImage: "person.crop.circle", value: KidTabSlot.tab(.corner)) { KidTabStack(tab: .corner) { KidCornerView() } }
            Tab("Masal yaz", systemImage: "pencil.and.scribble", value: KidTabSlot.create, role: createTabRole) {
                Color.clear
            }
        }
        .tint(MP.C.brand)
    }

    /// iOS 27'de öne çıkan sekme rolü; öncesinde tek yol arama rolünün dairesi.
    @available(iOS 26.0, *)
    private var createTabRole: TabRole {
        // `.prominent` iOS 27 SDK'sında (Swift 6.4); eski Xcode da derleyebilsin.
        #if compiler(>=6.4)
        if #available(iOS 27.0, *) { return .prominent }
        #endif
        return .search
    }

    /// iOS 26 öncesi: kendi yüzen çubuğumuz (`KidTabBar`).
    private var customKidTabs: some View {
        // Sekmeler yumuşak bir kayma ve solmayla değişir; Reduce Motion'da
        // yalnızca solma.
        ZStack {
            switch app.router.tab {
            case .home:    KidTabStack(tab: .home) { HomeView() }.transition(tabTransition)
            case .gunluk:  GunlukView().transition(tabTransition)
            case .library: KidTabStack(tab: .library) { LibraryView() }.transition(tabTransition)
            case .corner:  KidTabStack(tab: .corner) { KidCornerView() }.transition(tabTransition)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(reduceMotion ? MP.M.easeOut : MP.M.base, value: app.router.tab)
        .mpFloatingBar {
            KidTabBar(
                selection: Binding(get: { app.router.tab.kidTab }, set: selectKidTab),
                onCreate: {
                    createFromBar = true
                    app.startStoryCreation()
                },
                zoom: createZoom
            )
        }
    }

    /// Seçili sekmeye yeniden dokunmak sayfayı başa alır.
    private func selectKidTab(_ next: KidTab) {
        guard MPTab(next) != app.router.tab else { app.router.reselectTab(); return }
        MPHaptics.selection()
        app.router.tab = MPTab(next)
    }

    private var parentRoot: some View {
        ParentTabs(
            selection: Binding(
                get: { app.router.parentTab.parentTab },
                set: { app.router.parentTab = MPParentTab($0) }
            ),
            summary: { ParentTabStack(tab: .overview) { ParentOverviewView() } },
            safety: { ParentTabStack(tab: .safety) { ParentSafetyView() } },
            settings: { ParentTabStack(tab: .settings) { SettingsView() } }
        )
    }

    // MARK: - Sheet'ler

    @ViewBuilder
    private func sheetContent(_ route: MPSheetRoute) -> some View {
        switch route {
        case .interests(let id):
            if let profile = profileManager.profiles.first(where: { $0.id == id }) {
                InterestsEditorSheet(profile: profile)
            }
        case .signOut:
            AccountSignOutSheet(onClose: { app.router.sheet = nil })
        case .reminder:
            ReminderSheet(childName: profileManager.currentProfile?.name ?? "")
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Sekme yığınları

/// Çocuk sekmesinin kendi yığını (7 Kasım 2026): alt sayfalar push ile açılır,
/// alt çubuk görünür kalır, sekme değişince yol korunur (SCREENS.md, HIG). Masallar
/// kendi yığınını `GunlukRoute` ile kurar.
private struct KidTabStack<Root: View>: View {
    let tab: MPTab
    @ViewBuilder var root: Root

    @EnvironmentObject private var app: MPAppState

    var body: some View {
        NavigationStack(path: Binding(get: { app.router.kidPaths[tab] ?? [] },
                                      set: { app.router.kidPaths[tab] = $0 })) {
            root
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: MPKidRoute.self) { route in
                    KidPageView(route: route)
                }
        }
    }
}

/// Çocuk alt sayfası (`MPKidRoute`): her sekmenin yığınında aynı.
struct KidPageView: View {
    let route: MPKidRoute

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var profileManager = ProfileManager.shared

    var body: some View {
        page
            .kidTabBarClearance()
            .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var page: some View {
        switch route {
        case .series(let child):
            SeriesView(childID: child)
        case .newWords(let id):
            if let profile = profile(id) {
                NewWordsView(profile: profile) { app.router.closeKidPage() }
            }
        case .familyCharacters(let id):
            if let profile = profile(id) { FamilyCharactersView(profile: profile) }
        case .bookCharacter(let id):
            if let profile = profile(id) { BookCharacterView(profile: profile) }
        case .stickers(let id):
            if let profile = profile(id) { StickerAlbumView(profile: profile) }
        case .decor(let id):
            if let profile = profile(id) { DecorShopView(profile: profile) }
        case .wardrobe(let id):
            if let profile = profile(id) { HeroWardrobeView(profile: profile) }
        case .storyMap(let id):
            if let profile = profile(id) { StoryMapView(profile: profile) }
        }
    }

    private func profile(_ id: UUID) -> UserProfile? {
        profileManager.profiles.first { $0.id == id }
    }
}

/// Ebeveyn sekmesinin yığını: alt sayfalar (`MPParentRoute`) açık olan sekmeye
/// itilir; "Geri" `app.router.parentRoute`'u temizler.
private struct ParentTabStack<Root: View>: View {
    let tab: MPParentTab
    @ViewBuilder var root: Root

    @EnvironmentObject private var app: MPAppState

    var body: some View {
        NavigationStack(path: Binding(
            get: { app.router.parentTab == tab ? app.router.parentPath : [] },
            set: { if app.router.parentTab == tab { app.router.parentPath = $0 } }
        )) {
            root
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: MPParentRoute.self) { route in
                    ParentRouteView(route: route)
                        .toolbar(.hidden, for: .navigationBar)
                }
        }
    }
}

private extension View {
    /// iOS 26 öncesinde kendi alt çubuğumuzun boşluğu yığının içine ulaşmaz
    /// (`GunlukLayout`); itilen sayfanın alt düğmesi çubuğun altında kalmasın.
    @ViewBuilder
    func kidTabBarClearance() -> some View {
        if #available(iOS 26.0, *) {
            self
        } else {
            safeAreaPadding(.bottom, MPSize.kidTabBarHeight)
        }
    }
}

/// İlk kurulum kapağının kimliği (09 + 10).
private struct FirstRunName: Identifiable {
    let name: String
    var id: String { name }
}
