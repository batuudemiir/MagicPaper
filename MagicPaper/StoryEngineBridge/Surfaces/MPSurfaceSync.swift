import Foundation
import OSLog
import WidgetKit

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "Surfaces")

// MARK: - Bu akşamın masalı, uygulamanın verisiyle

/// `MPTonight`'ın girdileri, uygulamanın canlı verisinden (FAZ 19).
///
/// Ana sayfa kartı, widget'a yazılan kayıt ve Siri/widget bağlantısı aynı
/// girdileri buradan alır; "hangi masal" sorusunun tek cevabı olsun diye.
@MainActor
enum MPTonightSource {
    struct Resolved {
        let inputs: MPTonight.Inputs
        /// Yarım masal (okuyucuda açılır).
        let resumeStory: Story?
        /// Günün masalı (kendi okuyucusunda açılır).
        let daily: DailyStory?

        func tonight(at date: Date = Date()) -> MPTonight { MPTonight.resolve(inputs, now: date) }
    }

    /// Çocuğun görmeye hakkı olan masalları. Onay kapısı burada da geçerli:
    /// kitaplıktan gizlenen bir masal bu kartta, widget'ta duramaz.
    static func visibleStories(settings: MPSettingsStore? = nil,
                               library: StoryGenerationManager? = nil,
                               profiles: ProfileManager? = nil) -> [Story] {
        let settings = settings ?? .shared
        let profile = (profiles ?? .shared).currentProfile
        return MPStoryGate.visible((library ?? .shared).stories, approvalRequired: settings.approve,
                                   isApproved: { settings.isApproved($0) })
            .filter { $0.belongs(to: profile) }
    }

    static func current(settings: MPSettingsStore? = nil,
                        streak: MPStreak? = nil,
                        dailyManager: DailyStoryManager? = nil) -> Resolved {
        let settings = settings ?? .shared
        let streak = streak ?? .shared
        let dailyManager = dailyManager ?? .shared
        let stories = visibleStories(settings: settings)
        let unfinished = MPContinueReading.pick(from: stories)
        let daily = dailyManager.todaysStory ?? dailyManager.dailyStories.first
        let inputs = MPTonight.Inputs(
            bedtime: settings.bedtime
                ? .init(hour: settings.bedtimeHour, minute: settings.bedtimeMinute) : nil,
            resume: unfinished.map(resume(for:)),
            readToday: streak.readToday,
            daily: daily.map { .init(title: $0.title, minutes: $0.readingTime) })
        return Resolved(inputs: inputs, resumeStory: unfinished, daily: daily)
    }

    static func resume(for story: Story) -> MPTonight.Resume {
        .init(storyID: story.id, title: story.title,
              page: min((story.lastReadPage ?? 0) + 1, story.pages.count),
              pageCount: story.pages.count, progress: story.mpProgress)
    }

    /// 26 · Uyku modu'nun masalı: çocuğun en son okunan uyku masalı, yoksa
    /// günün masalı. İkisi de yoksa nil; çağıran Uyku öncesi modunda yeni
    /// bir masal açar.
    static func sleepSession(settings: MPSettingsStore? = nil,
                             dailyManager: DailyStoryManager? = nil) -> MPSleepSession? {
        let dailyManager = dailyManager ?? .shared
        if let story = visibleStories(settings: settings)
            .filter({ $0.mpMode == .bedtime })
            .max(by: { ($0.lastReadAt ?? $0.createdAt) < ($1.lastReadAt ?? $1.createdAt) }) {
            return MPSleepSession(story: story)
        }
        if let daily = dailyManager.todaysStory ?? dailyManager.dailyStories.first {
            return MPSleepSession(daily: daily)
        }
        return nil
    }
}

// MARK: - Widget kaydı

/// Widget'ların okuduğu kaydı yazar ve değiştiyse zaman çizelgelerini yeniler.
///
/// Uygulama arka plana giderken, çocuk değişince ve okuyucu ya da uyku
/// modu kapanınca çağrılır. Kayıt aynıysa hiçbir şey yapmaz.
@MainActor
enum MPSurfaceSync {
    static var store = MPSurfaceStore()

    static func refresh(now: Date = Date()) {
        let snapshot = snapshot(now: now)
        guard store.save(snapshot) else { return }
        WidgetCenter.shared.reloadAllTimelines()
        logger.debug("Widget kaydı yenilendi")
    }

    /// Aile verisi silinince (çıkış, hesap silme): widget'lar boş durumuna döner.
    static func erase() {
        store.erase()
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func snapshot(now: Date = Date(),
                         profiles: ProfileManager? = nil,
                         streak: MPStreak? = nil,
                         series: SeriesManager? = nil) -> MPSurfaceSnapshot {
        let streak = streak ?? .shared
        guard let child = (profiles ?? .shared).currentProfile else { return .empty }
        let tonight = MPTonightSource.current(streak: streak)
        return MPSurfaceSnapshot(
            hasChild: true,
            bedtime: tonight.inputs.bedtime,
            resume: tonight.inputs.resume,
            daily: tonight.inputs.daily,
            readDays: MPReadingWeek.recent(streak.readDays, now: now),
            series: seriesSnapshot(childID: child.id, manager: series ?? .shared))
    }

    static func seriesSnapshot(childID: UUID, manager: SeriesManager) -> MPSurfaceSnapshot.Series? {
        guard let open = manager.openSeries(for: childID),
              let state = manager.cardState(for: childID),
              let progress = manager.readProgress(for: childID) else { return nil }
        switch state {
        case .ready(_, let episode, let title):
            return .init(title: title, episode: episode, isReady: true, opensAt: nil,
                         read: progress.read, total: progress.total)
        case .waiting(let episode, let title):
            return .init(title: title, episode: episode, isReady: false,
                         opensAt: open.readMark(before: episode).flatMap(dayAfter),
                         read: progress.read, total: progress.total)
        }
    }

    /// Bir önceki bölümün okunduğu günün ertesi, okunduğu saat diliminde
    /// (`SeriesClock.dayHasPassed` ile aynı sınır).
    static func dayAfter(_ mark: SeriesReadMark) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: mark.timeZone) ?? .current
        return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: mark.at))
    }
}

// MARK: - Bekleyen bağlantı

/// Widget, Live Activity ya da Siri'nin açtığı yer, uygulama ona varana dek.
///
/// Uygulama giriş, onay ya da profil seçimindeyken gelen bağlantı bekler;
/// kök ekran (`ContentView`) açılınca işlenir.
@MainActor
final class MPSurfaceRouter: ObservableObject {
    static let shared = MPSurfaceRouter()
    @Published var pending: MPSurfaceLink?
}
