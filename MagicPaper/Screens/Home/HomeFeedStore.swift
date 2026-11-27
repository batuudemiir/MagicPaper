import Combine
import Foundation
import UIKit

/// Ana sayfanın canlı verisi (21 Kasım 2026, `docs/ANA_SAYFA_HAZIRLIK.md` A3, A4).
///
/// Ana sayfa eskiden yalnızca masal listesi ve profil değişince yenileniyordu;
/// günün masalı, seri, abonelik, yıldız ve saat değişince eski kalıyordu.
/// Bu depo ekranın okuduğu her kaynağı dinler, değişiklikleri kısa bir
/// bekleyişle toplayıp `HomeFeed`'i bir kez hesaplar ve bir sonraki değişim
/// anına (yatma saati, 05.00, gece yarısı, selam saatleri, ücretsiz hakkın
/// açılması) kadar bekleyip kendiliğinden yeniler. Kural `HomeFeed`'te; burada
/// yalnızca toplama ve zamanlama.
@MainActor
final class HomeFeedStore: ObservableObject {
    @Published private(set) var feed: HomeFeed

    private let now: () -> Date
    private let calendar: Calendar
    private var cancellables = Set<AnyCancellable>()
    private var tick: Task<Void, Never>?
    /// Son hesaplanan gün: gün dönünce günün masalı ve seri yeniden seçilir.
    private var computedDay: Date

    init(now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.now = now
        self.calendar = calendar
        let date = now()
        computedDay = calendar.startOfDay(for: date)
        feed = HomeFeed.make(Self.liveInputs(now: date), now: date, calendar: calendar)
        listen()
        scheduleNextChange()
    }

    deinit { tick?.cancel() }

    /// Girdileri yeniden toplar. Sonuç aynıysa yayın yapılmaz: ekran boşuna
    /// yeniden çizilmez.
    func refresh() {
        let date = now()
        let day = calendar.startOfDay(for: date)
        if day != computedDay {
            computedDay = day
            dayDidTurn()
        }
        let next = HomeFeed.make(Self.liveInputs(now: date), now: date, calendar: calendar)
        if next != feed { feed = next }
        scheduleNextChange()
    }

    // MARK: - Dinleme

    /// `objectWillChange` değişimden önce gelir; 80 ms'lik bekleyiş hem değişimin
    /// yazılmasını bekler hem de aynı anda gelen birkaç duyuruyu tek hesaba indirir.
    private func listen() {
        let center = NotificationCenter.default
        let signals: [AnyPublisher<Void, Never>] = [
            StoryGenerationManager.shared.objectWillChange.map { _ in () }.eraseToAnyPublisher(),
            ProfileManager.shared.objectWillChange.map { _ in () }.eraseToAnyPublisher(),
            MPStreak.shared.objectWillChange.map { _ in () }.eraseToAnyPublisher(),
            DailyStoryManager.shared.objectWillChange.map { _ in () }.eraseToAnyPublisher(),
            SeriesManager.shared.objectWillChange.map { _ in () }.eraseToAnyPublisher(),
            LiveEntitlementService.shared.objectWillChange.map { _ in () }.eraseToAnyPublisher(),
            MPSettingsStore.shared.objectWillChange.map { _ in () }.eraseToAnyPublisher(),
            // Rozet defteri (yıldız puanı) yazılınca.
            center.publisher(for: .mpFamilyDataChanged).map { _ in () }.eraseToAnyPublisher(),
            // Saat ya da saat dilimi elle değişti, gün döndü, uygulama öne geldi.
            center.publisher(for: UIApplication.significantTimeChangeNotification).map { _ in () }.eraseToAnyPublisher(),
            center.publisher(for: UIApplication.willEnterForegroundNotification).map { _ in () }.eraseToAnyPublisher(),
        ]
        Publishers.MergeMany(signals)
            .debounce(for: .milliseconds(80), scheduler: RunLoop.main)
            .sink { [weak self] in self?.refresh() }
            .store(in: &cancellables)
    }

    // MARK: - Zamanlama

    /// Bir sonraki değişim anında yeniden hesaplar. Her hesapta yeniden kurulur;
    /// öncekini iptal eder. Uygulama askıdayken kaçırılan an, öne gelince
    /// (`willEnterForeground`) yakalanır.
    private func scheduleNextChange() {
        tick?.cancel()
        let date = now()
        let canWrite = MPAppState.canWriteNewStoryToday
        let settings = MPSettingsStore.shared
        let bedtime = settings.bedtime
            ? MPTonight.Bedtime(hour: settings.bedtimeHour, minute: settings.bedtimeMinute) : nil
        let next = HomeFeed.nextChange(after: date, bedtime: bedtime,
                                       writeOpensAt: canWrite ? nil : Self.freeStoryOpensAt,
                                       calendar: calendar)
        // Bir saniye pay: sınırın tam üstünde uyanıp eski tarafta kalmasın.
        let delay = max(1, next.timeIntervalSince(date) + 1)
        tick = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.refresh()
        }
    }

    /// Gün döndü: günün masalı ve günü gelen seri bölümü yeniden seçilir
    /// (`ContentView` bunu uygulama öne gelince yapar; uygulama gece yarısı
    /// açıkken de olsun). İkisi de aynı günde ikinci kez çağrılınca bir şey
    /// değiştirmez.
    private func dayDidTurn() {
        DailyStoryManager.shared.refreshForToday()
        if let child = ProfileManager.shared.currentProfile?.id {
            SeriesManager.shared.refreshUnlocks(for: child)
        }
    }

    // MARK: - Canlı girdiler

    private static func liveInputs(now: Date) -> HomeFeed.Inputs {
        let profile = ProfileManager.shared.currentProfile
        let stories = StoryGenerationManager.shared.stories
        let resolved = MPTonightSource.current()
        let tonight = resolved.tonight(at: now)
        let original = resolved.daily.flatMap { ClassicsLibrary.shared.original($0.id)?.cover }
        return HomeFeed.Inputs(
            tonight: tonight,
            canWriteNewStory: MPAppState.canWriteNewStoryToday,
            stars: profile.map { MPStars.score(for: $0, stories: stories, now: now) } ?? 0,
            streak: MPStreak.shared.currentStreak,
            hasSeriesCard: profile.map { SeriesManager.shared.cardState(for: $0.id) != nil } ?? false,
            cover: HomeFeed.cover(for: tonight, resume: resolved.resumeStory, daily: resolved.daily,
                                  original: original),
            stories: MPTonightSource.visibleStories().count)
    }

    /// Ücretsiz günün masalı yazıldıysa yenisinin açılacağı an.
    private static var freeStoryOpensAt: Date? {
        LiveEntitlementService.shared.context.lastFreeTextStoryAt?
            .addingTimeInterval(EntitlementPolicy.freeTextStoryCooldownHours * 60 * 60)
    }
}
