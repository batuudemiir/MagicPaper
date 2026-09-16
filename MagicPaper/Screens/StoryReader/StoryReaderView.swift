import SwiftUI

/// Masal okuyucusu.
///
/// Kitabın kendisi. Etrafındaki ortam, sunum, durum ve erişilebilirlik burada;
/// sayfa çevirme hareketi `StoryReaderContainer` üzerinden UIKit'te (§4).
struct StoryReaderView: View {

    let story: Story
    /// Belirli bir sayfadan açmak için — kapaktan gelirken hep baştan.
    var startingPage: Int?

    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var model: StoryReaderModel
    @StateObject private var favorites = MPFavorites.shared
    @StateObject private var streak = MPStreak.shared
    @StateObject private var speech = MPSpeech.shared

    @State private var showReaderSettings = false
    @State private var openedAt: Date?
    /// Kontrolleri kendiliğinden gizleyen sayaç.
    @State private var autoHideTask: Task<Void, Never>?

    init(story: Story, startingPage: Int? = nil) {
        self.story = story
        self.startingPage = startingPage
        _model = StateObject(wrappedValue: StoryReaderModel(
            story: ReaderStory(from: story),
            startingAt: startingPage,
            savedPage: story.lastReadPage
        ))
    }

    private var theme: MP.ReadTheme { app.readTheme }

    var body: some View {
        ZStack {
            // Kâğıt en altta ve kesintisiz: sayfa denetleyicisi geçiş sırasında
            // ne yaparsa yapsın arkasında hep kâğıt var.
            ReaderPaper(theme: theme)

            StoryReaderContainer(
                model: model,
                theme: theme,
                page: leaf(at:),
                onTurnCompleted: turnCompleted,
                onTap: toggleControls,
                reduceMotion: reduceMotion
            )
            .ignoresSafeArea()

            if model.controlsVisible {
                ReaderChrome(
                    theme: theme,
                    isFavorite: favorites.contains(story.id),
                    isSpeaking: speech.isSpeaking && !speech.isPaused,
                    onClose: close,
                    onToggleFavorite: toggleFavorite,
                    onToggleSpeech: toggleSpeech,
                    onOpenSettings: openSettings
                )
                .transition(.opacity)
            }
        }
        .background(theme.paper.ignoresSafeArea())
        .animation(MP.M.gated(MP.M.easeOut), value: model.controlsVisible)
        .animation(MP.M.gated(MP.M.base), value: theme)
        .statusBarHidden(!model.controlsVisible)
        .overlay {
            if showReaderSettings {
                ReaderSettingsSheet(onClose: {
                    withAnimation(MP.M.gated(MP.M.easeOut)) { showReaderSettings = false }
                    scheduleAutoHide()
                })
                .environmentObject(app)
                .environmentObject(settings)
            }
        }
        // VoiceOver kaydırma jestini tüketir; sayfa çevirme yine de çalışmalı.
        .accessibilityScrollAction { edge in
            switch edge {
            case .leading:  model.previous()
            case .trailing: model.next()
            default: break
            }
        }
        .accessibilityAction(named: "Sonraki sayfa") { model.next() }
        .accessibilityAction(named: "Önceki sayfa") { model.previous() }
        .onAppear(perform: open)
        .onDisappear(perform: closeDown)
        .onChange(of: scenePhase) { _, phase in
            // Sayfa çevrilirken arka plana geçilebilir (§25).
            if phase != .active { model.persistProgress() }
        }
        .onChange(of: model.leafIndex) { _, _ in pageChanged() }
    }

    // MARK: - Yapraklar

    /// Yaprak, durumu kendisi dinler — değer olarak verilmez.
    /// Gerekçe `StoryLeafView`'ın başında.
    private func leaf(at index: Int) -> some View {
        StoryLeafView(
            index: index,
            model: model,
            onReadAgain: { model.restart() },
            onClose: close
        )
        .environmentObject(app)
    }

    // MARK: - Yaşam döngüsü

    private func open() {
        streak.markReadToday()
        openedAt = Date()
        MPHaptics.prepare()
        if settings.readAloud, let text = model.currentPage?.spokenText {
            speech.speak(text)
        }
        scheduleAutoHide()
    }

    private func closeDown() {
        autoHideTask?.cancel()
        model.persistProgress()
        commitReadingTime()
        speech.stop()
    }

    private func close() {
        model.persistProgress()
        dismiss()
    }

    private func commitReadingTime() {
        guard let openedAt else { return }
        streak.addReadingTime(Date().timeIntervalSince(openedAt))
        self.openedAt = nil
    }

    // MARK: - Sayfa çevirme

    /// Yalnızca tamamlanmış bir çevirmede. Sürüklerken değil.
    private func turnCompleted() {
        MPHaptics.pageTurn()
    }

    private func pageChanged() {
        model.persistProgress()

        if model.isOnEndingLeaf {
            speech.stop()
            return
        }

        // Sesli okuma açıksa yeni sayfa kendiliğinden okunur.
        let wasSpeaking = speech.isSpeaking && !speech.isPaused
        if let text = model.currentPage?.spokenText, wasSpeaking || settings.readAloud {
            speech.speak(text)
        }

        if let folio = model.folio {
            UIAccessibility.post(notification: .pageScrolled, argument: folio)
        }
    }

    // MARK: - Kontroller

    private func toggleControls() {
        withAnimation(MP.M.gated(MP.M.easeOut)) { model.toggleControls() }
        if model.controlsVisible { scheduleAutoHide() } else { autoHideTask?.cancel() }
    }

    /// Kontroller okuma başlayınca kendiliğinden çekilir.
    ///
    /// 4,5 saniye. Önce 3 denendi ve telefonu tutan bir ebeveyn için fazla
    /// hızlıydı: kapatmak isteyen kişi düğmeyi kaybediyor, geri getirmek için
    /// önce bir kez dokunmak zorunda kalıyordu.
    private static let autoHideDelay: UInt64 = 4_500_000_000

    private func scheduleAutoHide() {
        autoHideTask?.cancel()
        autoHideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: StoryReaderView.autoHideDelay)
            guard !Task.isCancelled, !showReaderSettings else { return }
            withAnimation(MP.M.gated(MP.M.easeOut)) { model.hideControls() }
        }
    }

    private func openSettings() {
        autoHideTask?.cancel()
        withAnimation(MP.M.gated(MP.M.spring)) { showReaderSettings = true }
    }

    private func toggleFavorite() {
        let now = favorites.toggle(story.id)
        MPHaptics.tap()
        app.showToast(now ? "Favorilere eklendi" : "Favorilerden çıkarıldı",
                      symbol: "heart.fill")
        scheduleAutoHide()
    }

    private func toggleSpeech() {
        speech.toggle(model.currentPage?.spokenText ?? "")
        scheduleAutoHide()
    }
}
