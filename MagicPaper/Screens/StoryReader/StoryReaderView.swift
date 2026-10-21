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
    /// Bu açılışın okuma kaydı (FAZ 14).
    @State private var recorder: ReadingSessionRecorder
    @StateObject private var favorites = MPFavorites.shared
    @StateObject private var streak = MPStreak.shared
    @StateObject private var speech = MPSpeech.shared
    @StateObject private var words = ReaderWordSelection.shared

    @State private var showReaderSettings = false
    @State private var openedAt: Date?
    /// Bu oturumda ön planda geçen, diske yazılmış süre. Arka plana geçip
    /// dönmek oturumu bölmez — parçalar burada toplanır.
    @State private var sessionSeconds: Double = 0
    /// Bu oturumda tamamlanan yaprak geçişi sayısı.
    @State private var pagesTurned: Int = 0
    /// Gün bir kez işaretlenir; sonraki değerlendirmeler boşa çalışmasın.
    @State private var streakMarked = false
    /// Kontrolleri kendiliğinden gizleyen sayaç.
    @State private var autoHideTask: Task<Void, Never>?
    /// Günlük okuma bütçesini izleyen sayaç.
    @State private var budgetTask: Task<Void, Never>?
    /// Bugünün payı bitti — okuma burada durur.
    @State private var budgetSpent = false
    /// "Az kaldı" bir kez söylenir.
    @State private var warnedAboutBudget = false

    init(story: Story, startingPage: Int? = nil) {
        self.story = story
        self.startingPage = startingPage
        _model = StateObject(wrappedValue: StoryReaderModel(
            story: ReaderStory(from: story),
            startingAt: startingPage,
            savedPage: story.lastReadPage
        ))
        _recorder = State(initialValue: ReadingSessionRecorder(story: story))
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
            // `transitionStyle` yalnızca init'te verilebilir, sonradan
            // değiştirilemez. `.id` olmadan, okuyucu açıkken "Hareketi Azalt"ı
            // açan biri sayfa kıvrımıyla okumaya devam ederdi — ayarı tam da
            // o kıvrımı istemediği için açmış olmasına rağmen. Değer değişince
            // SwiftUI denetleyiciyi baştan kurar, koordinatör de bulunduğu
            // yaprakta yeniden bağlanır.
            .id(reduceMotion)
            .ignoresSafeArea()

            // Koşulsuz. Kapat düğmesinin kendisi hep burada, geri kalanı
            // `showsSecondary` ile geliyor gidiyor.
            ReaderChrome(
                theme: theme,
                isFavorite: favorites.contains(story.id),
                isSpeaking: speech.isSpeaking && !speech.isPaused,
                showsSecondary: model.controlsVisible,
                pageLabel: model.folio.map { "Sayfa \($0)" },
                progress: model.currentPage.map { Double($0.index + 1) / Double(max(story.pages.count, 1)) } ?? 0,
                canGoPrevious: model.canGoPrevious,
                canGoNext: model.canGoNext,
                isLastPage: model.currentPage.map { $0.index == story.pages.count - 1 } ?? false,
                onClose: close,
                onToggleFavorite: toggleFavorite,
                onToggleSpeech: toggleSpeech,
                onOpenSettings: openSettings,
                onPrevious: { model.previous(); scheduleAutoHide() },
                onNext: { model.next(); scheduleAutoHide() },
                pagePreviews: model.story.pagePreviews,
                pageIndex: model.currentPage?.index,
                onSeek: { page in
                    model.go(toLeaf: model.story.leafIndex(forPage: page))
                    scheduleAutoHide()
                },
                onScrubbing: { active in
                    if active { autoHideTask?.cancel() } else { scheduleAutoHide() }
                }
            )
            // Kontroller her zaman sayfanın üstünde dokunulur. Sıra tek başına
            // yetmiyordu: sol kenar şeridinde (genişliğin %15'i) sayfanın
            // dokunma işleyicisi Kapat'ı yutuyor ve sayfayı geri çeviriyordu;
            // okuyucudan çıkılamıyordu. Açık z sırası bunu kapatır.
            .zIndex(1)
        }
        .background(theme.paper.ignoresSafeArea())
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .animation(MP.M.gated(MP.M.easeOut), value: model.controlsVisible)
        .animation(MP.M.gated(MP.M.base), value: theme)
        .statusBarHidden(!model.controlsVisible)
        // Bütçe biterse okuma yerinde durur: sayfa arkada kalır, üstüne sakin
        // bir kapanış gelir. Masalı yarıda kesmek hoş değil ama bir limitin
        // "masalın sonuna kadar" beklemesi limit olmaktan çıkar — bu yüzden
        // beş dakika önceden haber veriliyor.
        .overlay(alignment: .bottom) {
            if let word = words.selected {
                NewWordCard(word: word.term, meaning: word.meaning,
                            isSpeaking: false,
                            onSpeak: { speech.speak("\(word.term). \(word.meaning)") },
                            onClose: { words.selected = nil })
                    .padding(.horizontal, MPSpacing.screenH)
                    .padding(.bottom, model.controlsVisible ? 190 : MPSpacing.xxl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .animation(MP.M.gated(MP.M.base), value: words.selected)
        .overlay {
            if budgetSpent {
                ReaderTimeUpLeaf(theme: theme, onClose: close)
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showReaderSettings, onDismiss: scheduleAutoHide) {
            ReaderSettingsSheet(hasFamilyVoice: MPNarration.isAvailable(for: story.id),
                                onClose: { showReaderSettings = false })
                .environmentObject(app)
                .environmentObject(settings)
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
            if phase != .active {
                model.persistProgress()
                // Ve okuma sayacı orada durur.
                //
                // Süre bugüne kadar "okuyucu açıldı → kapandı" arası duvar
                // saatiydi: masalı açık bırakıp telefonu cebe koyan biri bir
                // saat "okumuş" sayılıyordu. Ebeveyn panelindeki rakam yanlış
                // oluyordu ama kimseye bir şey yapmıyordu — günlük limit bu
                // sayının üstüne kurulduğu anda, yanlış rakam çocuğun bugünkü
                // okumasını yiyen bir şeye dönüşüyor.
                pauseReading()
            } else {
                resumeReading()
            }
        }
        .onChange(of: model.leafIndex) { _, _ in pageChanged() }
    }

    // MARK: - Yapraklar

    /// Yaprak, durumu kendisi dinler — değer olarak verilmez.
    /// Gerekçe `StoryLeafView`'ın başında.
    private func leaf(at index: Int) -> some View {
        StoryLeafView(
            index: index,
            story: story,
            model: model,
            onReadAgain: {
                recorder.readAgain()
                model.restart()
            },
            onClose: close,
            onAnother: {
                app.afterReader = .create
                close()
            },
            onGoodNight: {
                app.sayGoodNight(after: story)
                close()
            }
        )
        .environmentObject(app)
        // Tavan AX3.
        //
        // Sistemin yazı boyutu `MP.ReadSize`'ın üstüne çarpan olarak biniyor,
        // yani en büyük okuma boyutu AX5 ile birleştiğinde sayfada satır başına
        // dört kelime kalıyor ve sayfa sayfa olmaktan çıkıyor. Metin
        // kaybolmuyor — sütun kaydırılabiliyor — ama kitap görüntüsü bitiyor.
        // AX3'te hem ölçek gerçekten büyük hem sayfa hâlâ sayfa.
        //
        // Ortam değerleri `UIHostingController`'a kendiliğinden geçmediği için
        // okuyucunun gövdesine değil, yaprağın kendisine uygulanıyor.
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    // MARK: - Yaşam döngüsü

    private func open() {
        // Burada seri İŞARETLENMEZ. Açmak okumak değildir; günü işaretleyen
        // olay anlamlı bir okuma oturumudur (`MPReadingSession`), ve o karar
        // ilk sayfa çevriminde ya da oturum kapanırken verilir.
        //
        // "En son hangi masal" sorusunun cevabı ise burada yazılır: kütüphane
        // için açmak gerçekten bir olaydır — kaldığı yerden devam edebilmek
        // için masalın açıldığını bilmek gerekir (`markOpened`'ın gerekçesi).
        // İki defter, iki farklı soru.
        StoryGenerationManager.shared.markOpened(storyId: story.id)
        openedAt = Date()
        MPHaptics.prepare()
        if settings.readAloud || app.readerListens, let text = model.currentPage?.spokenText {
            speech.speak(text, recording: familyRecording)
        }
        // Ailenin sesi başka cihazda kaydedildiyse sayfalar şimdi iner (FAZ 18).
        Task { await VoiceRecordingStore.shared.prefetch(story.id) }
        scheduleAutoHide()
        startBudgetWatch()
    }

    private func closeDown() {
        autoHideTask?.cancel()
        budgetTask?.cancel()
        model.persistProgress()
        commitReadingTime()
        recordSession()
        speech.stop()
    }

    private func close() {
        model.persistProgress()
        dismiss()
    }

    /// Arka plana geçerken: o ana kadarki süre yazılır, sayaçlar durur.
    private func pauseReading() {
        budgetTask?.cancel()
        commitReadingTime()
    }

    /// Öne dönerken: sayaç yeniden başlar, bütçe bugünün güncel toplamıyla
    /// yeniden hesaplanır (arada gün değişmiş bile olabilir).
    private func resumeReading() {
        guard !budgetSpent, openedAt == nil else { return }
        openedAt = Date()
        startBudgetWatch()
    }

    private func commitReadingTime() {
        guard let openedAt else { return }
        let elapsed = max(Date().timeIntervalSince(openedAt), 0)
        self.openedAt = nil
        sessionSeconds += elapsed
        streak.addReadingTime(elapsed)
        markStreakIfEarned()
    }

    // MARK: - Okuma oturumu

    /// Şu ana kadarki oturum. Ön planda geçen ve henüz yazılmamış süre de
    /// sayılır — yoksa bir sayfa çevrilmeden okunan masal yalnızca kapanışta
    /// değerlendirilirdi.
    private var readingSession: MPReadingSession {
        let live = openedAt.map { max(Date().timeIntervalSince($0), 0) } ?? 0
        return MPReadingSession(secondsRead: sessionSeconds + live,
                                pagesTurned: pagesTurned)
    }

    /// Günü işaretlemenin tek yeri. Kural `MPReadingSession`'da; burada
    /// yalnızca "bir kez" garantisi var.
    private func markStreakIfEarned() {
        guard !streakMarked else { return }
        if streak.markReadingSession(readingSession) { streakMarked = true }
    }

    // MARK: - Günlük okuma bütçesi

    /// Ebeveynin koyduğu limitin okuyucudaki karşılığı.
    ///
    /// `secondsBeforeSession` okuyucu açılırken dondurulur: bu oturumun süresi
    /// henüz diske yazılmadığı için, geçen süre ayrıca elde sayılır. İkisini
    /// birden `streak`ten okumak, bu oturumu iki kez saymak olurdu.
    private func budget(startedAt: Double) -> MPReadingBudget {
        MPReadingBudget(
            isEnabled: settings.screenLimit,
            dailyLimitMinutes: settings.screenLimitMinutes,
            secondsBeforeSession: startedAt
        )
    }

    /// Beş dakikalık uyarı — bir çocuğa "bitti" demeden önce "az kaldı" demek.
    private static let budgetWarningSeconds: Double = 5 * 60
    private static let budgetTickNanoseconds: UInt64 = 20_000_000_000

    private func startBudgetWatch() {
        guard settings.screenLimit else { return }
        let before = streak.secondsToday
        let opened = Date()
        let plan = budget(startedAt: before)

        // Gün zaten dolmuşsa masal hiç açılmaz: kapanış yaprağı en baştan.
        if plan.isExhausted(sessionSeconds: 0) {
            endForToday()
            return
        }

        budgetTask?.cancel()
        budgetTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: StoryReaderView.budgetTickNanoseconds)
                guard !Task.isCancelled else { return }
                let elapsed = Date().timeIntervalSince(opened)
                guard let remaining = plan.remainingSeconds(sessionSeconds: elapsed) else { return }

                if remaining <= 0 {
                    endForToday()
                    return
                }
                if remaining <= StoryReaderView.budgetWarningSeconds, !warnedAboutBudget {
                    warnedAboutBudget = true
                    app.showToast("Bugünkü masal vaktinden 5 dakika kaldı", symbol: "hourglass")
                }
            }
        }
    }

    /// Bugünlük bitiş.
    ///
    /// Süre burada hemen diske yazılıyor: kapanış yaprağına bakarak geçen
    /// dakikalar okuma değildir, ve yazmadan beklemek yarınki bütçeden çalardı.
    private func endForToday() {
        budgetTask?.cancel()
        speech.stop()
        model.persistProgress()
        commitReadingTime()
        // Süre bittiyse oturum da bitti; okuyucu kapanınca ikinci kez yazılmaz.
        // Masalı çocuk bırakmadı, gün bitti: yarıda bırakma sayılmaz.
        recordSession(interrupted: true)
        withAnimation(MP.M.gated(MP.M.easeOut)) { budgetSpent = true }
    }

    /// Oturumun kaydı: çocuğun kendi okuma kaydı ve, ebeveyn izin verdiyse,
    /// anonim bir okuma olayı (FAZ 14).
    private func recordSession(interrupted: Bool = false) {
        recorder.close(furthestPage: model.furthestPageReached, session: readingSession,
                       interrupted: interrupted)
    }

    // MARK: - Sayfa çevirme

    /// Yalnızca tamamlanmış bir çevirmede. Sürüklerken değil.
    private func turnCompleted() {
        MPHaptics.pageTurn()
    }

    private func pageChanged() {
        model.persistProgress()
        words.selected = nil

        // Bir yaprağın çevrilmesi, o masalın okunduğunun kitaba ait kanıtıdır.
        // Süre eşiğini beklemeden günü işaretler: çocuk okurken serinin
        // yanmasını okuyucunun kapanmasına bağlamak, olayı yine yanlış ana
        // taşımak olurdu.
        pagesTurned += 1
        markStreakIfEarned()

        if model.isOnEndingLeaf {
            speech.stop()
            recorder.reachedEnding()
            // Rozetler (FAZ 17): yalnızca okuyarak, aynı masal bir kez.
            if let profile = ProfileManager.shared.currentProfile, story.belongs(to: profile) {
                let fresh = MPBadgeStore().recordFinished(story, profile: profile,
                                                          stories: StoryGenerationManager.shared.stories)
                MPBadgeNews.shared.fresh = fresh
            }
            // The last page was reached: for a series episode, that is what
            // the next episode waits on (FAZ 13).
            SeriesManager.shared.markRead(story)
            return
        }

        // Sesli okuma açıksa yeni sayfa kendiliğinden okunur.
        let wasSpeaking = speech.isSpeaking && !speech.isPaused
        if let text = model.currentPage?.spokenText, wasSpeaking || settings.readAloud {
            speech.speak(text, recording: familyRecording)
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
        showReaderSettings = true
    }

    private func toggleFavorite() {
        let now = favorites.toggle(story.id)
        MPHaptics.tap()
        app.showToast(now ? "Favorilere eklendi" : "Favorilerden çıkarıldı",
                      symbol: "heart.fill")
        scheduleAutoHide()
    }

    /// Bu sayfanın ailenin sesiyle kaydı, "Kim okusun?" ailenin sesiyse.
    private var familyRecording: URL? {
        model.currentPage.flatMap { MPNarration.recording(story.id, page: $0.index) }
    }

    private func toggleSpeech() {
        speech.toggle(model.currentPage?.spokenText ?? "", recording: familyRecording)
        scheduleAutoHide()
    }
}
