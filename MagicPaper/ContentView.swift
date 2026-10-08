import StoryEngine
import SwiftUI

/// Kök ekran (FAZ 17, Pastel Masal).
///
/// Çocuk modu: krem zemin, iki sekme ve ortada yükseltilmiş "Yarat"
/// (`KidTabBar`, 11 · Ana sayfa, 16 · Kitaplık). Ebeveyn modu: gri zemin,
/// sistem sekme çubuğuyla Özet · Güvenlik · Ayarlar (`ParentTabs`, 29, 31, 32).
/// Ebeveyn moduna yalnızca kapıdan geçilir; arka plana gidince çocuk moduna
/// dönülür.
struct ContentView: View {
    @StateObject private var app = MPAppState()
    @StateObject private var settings = MPSettingsStore.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 09 + 10: ilk profil oluştuktan sonra bir kez.
    @State private var firstRun: FirstRunName?
    /// İlk masal hazırsa, kapak kapandıktan sonra okunur.
    @State private var firstStory: Story?

    var body: some View {
        content
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
                if let tab = MPDebugLaunch.startTab { app.tab = tab }
                if MPDebugLaunch.startsInParent { app.unlockParent() }
                if let tab = MPDebugLaunch.parentTab { app.parentTab = tab }
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
                MPStreak.shared.activate(profileID: id)
            // İçerik güvenliği (FAZ 17) çocuk başına: her sorgu ve masal bunu okur.
            OfflineStoryService.shared.currentSafety = profileManager.currentProfile?.effectiveSafety
                // A series episode whose day has come opens here (FAZ 13); no
                // notification announces it.
                if let id { SeriesManager.shared.refreshUnlocks(for: id) }
                DailyStoryManager.shared.refreshForToday()
            }
            // Ebeveyn modu oturumluk: uygulama arka plana gidince çocuk moduna döner.
            .onChange(of: scenePhase) { _, phase in
                if phase == .background {
                    app.enterChildMode()
                    RemoteContentService.scheduleBackgroundRefresh()
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
            .overlay { sheetLayer }
            .fullScreenCover(item: $app.sleepSession) { session in
                SleepModeView(session: session).environmentObject(app)
            }
            .fullScreenCover(isPresented: $app.showStoryCreation, onDismiss: {
                app.creationPreset = nil
                app.creationFamilyID = nil
                app.runAfterReader()
            }) {
                StoryCreationFlow(preset: app.creationPreset, family: app.creationFamilyID).environmentObject(app).environmentObject(settings)
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
                app.runAfterReader()
            }) { story in
                StoryReaderView(story: story, startingPage: app.readerStartPage).environmentObject(app).environmentObject(settings)
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
            .fullScreenCover(item: voiceRoute) { _ in
                if let profile = profileManager.currentProfile {
                    VoiceRecordingView(profile: profile) { app.parentRoute = nil }
                }
            }
            .fullScreenCover(isPresented: $app.showProfileAdd) {
                ProfileCreationView(mode: .addAnother) { name in
                    app.showToast("\(name) eklendi", symbol: "sparkles")
                }
            }
    }

    // MARK: - Sekme içeriği

    /// Mod değişince tüm içerik çapraz geçer: ebeveyn sayfaları çocuğun
    /// ekranlarının üstüne açılan bir katman değil, başka bir menü.
    private var content: some View {
        Group {
            if app.isParentMode {
                parentRoot.transition(.opacity)
            } else {
                kidRoot.transition(.opacity)
            }
        }
        .animation(reduceMotion ? MP.M.easeOut : MP.M.base, value: app.isParentMode)
    }

    private var kidRoot: some View {
        ZStack(alignment: .bottom) {
            MPColor.backgroundKid.ignoresSafeArea()

            Group {
                switch app.tab {
                case .home:    HomeView()
                case .library: LibraryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                KidTabBar(
                    selection: Binding(
                        get: { app.tab.kidTab },
                        set: { next in
                            guard MPTab(next) != app.tab else { return }
                            MPHaptics.selection()
                            app.tab = MPTab(next)
                        }
                    ),
                    onCreate: { app.startStoryCreation() }
                )
            }

            if let child = app.seriesChildID {
                SeriesView(childID: child)
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing))
                    .zIndex(2)
            }

            if app.showKidCorner {
                KidCornerView()
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .animation(reduceMotion ? MP.M.easeOut : MP.M.base, value: app.showKidCorner)
        .animation(reduceMotion ? MP.M.easeOut : MP.M.base, value: app.seriesChildID)
    }

    private var parentRoot: some View {
        ParentTabs(
            selection: Binding(
                get: { app.parentTab.parentTab },
                set: { app.parentTab = MPParentTab($0) }
            ),
            summary: { ParentOverviewView() },
            safety: { ParentSafetyView() },
            settings: { SettingsView() }
        )
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
            case .bookCharacter(let id):
                if let profile = profileManager.profiles.first(where: { $0.id == id }) {
                    BookCharacterView(profile: profile).environmentObject(app)
                }
            case .familyCharacters(let id):
                if let profile = profileManager.profiles.first(where: { $0.id == id }) {
                    FamilyCharactersView(profile: profile).environmentObject(app)
                }
            case .newWords(let id):
                if let profile = profileManager.profiles.first(where: { $0.id == id }) {
                    NewWordsView(profile: profile) { app.sheet = nil }
                }
            case .interests(let id):
                if let profile = profileManager.profiles.first(where: { $0.id == id }) {
                    InterestsEditorSheet(profile: profile).environmentObject(app)
                }
            case .signOut:
                AccountSignOutSheet(onClose: { app.sheet = nil })
            }
        }
    }
}

#Preview {
    ContentView()
}

extension ContentView {
    /// 33 · Kendi sesin. Diğer aile yolları (34, 36) henüz ekran açmaz.
    fileprivate var voiceRoute: Binding<MPParentRoute?> {
        Binding(get: { app.parentRoute == .voiceRecording ? .voiceRecording : nil },
                set: { app.parentRoute = $0 })
    }
}

/// İlk kurulum kapağının kimliği (09 + 10).
private struct FirstRunName: Identifiable {
    let name: String
    var id: String { name }
}
