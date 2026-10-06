import Foundation
import SwiftUI
import Combine
import OSLog

/// `print` reaches the shared device console verbatim. `Logger` redacts
/// interpolated values as `<private>` outside a debugger by default.
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "DailyStoryManager")

/// Günlük hikayeleri yöneten servis
///
/// Masallar içerik akışından gelir (FAZ 15, `RemoteContentService`); akış henüz
/// hiç gelmediyse uygulamayla gelen yedek (`daily_feed_fallback.json`) okunur.
/// Günün masalı `TodaysStoryPicker` ile seçilir — rastgele değil: aynı gün, yaş
/// ve okuma geçmişi her zaman aynı masalı verir. Gün boyunca seçilen masal
/// kalır; yeni akış bugüne yeni bir masal getirirse o geçer.
@MainActor
class DailyStoryManager: ObservableObject {

    static let shared: DailyStoryManager = {
        let manager = DailyStoryManager(feed: RemoteContentService.shared.feed)
        manager.follow(RemoteContentService.shared.$feed.eraseToAnyPublisher())
        return manager
    }()

    @Published private(set) var dailyStories: [DailyStory] = []
    @Published private(set) var todaysStory: DailyStory?

    enum Key {
        static let readDates = "dailyStoryReadDates"
        static let todaysStoryID = "todaysStoryId"
        static let todaysStoryDay = "todaysStoryDay"
        /// Before FAZ 15: the whole story list, read flags inside, random ids.
        static let legacyStories = "dailyStories"
        static let legacyRotation = "lastStoryRotation"
    }

    private let defaults: UserDefaults
    private let now: () -> Date
    private let calendar: Calendar
    private let currentAge: () -> Int?
    private let fallback: [FeedStory]
    private var source: [FeedStory] = []
    private var readDates: [UUID: Date] = [:]
    private var feedSubscription: AnyCancellable?

    init(
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current,
        currentAge: (() -> Int?)? = nil,
        feed: ContentFeed?,
        fallback: [FeedStory] = DailyStoryManager.bundledFallback()
    ) {
        self.defaults = defaults
        self.now = now
        self.calendar = calendar
        self.currentAge = currentAge ?? { ProfileManager.shared.currentProfile?.age }
        self.fallback = fallback
        readDates = Self.loadReadDates(defaults)
        source = Self.stories(of: feed, fallback: fallback)
        migrateLegacyReadFlags()
        refreshForToday()
    }

    // MARK: - Public Methods

    /// A new verified feed. `nil` or empty keeps the bundled stories.
    func apply(feed: ContentFeed?) {
        source = Self.stories(of: feed, fallback: fallback)
        refreshForToday()
    }

    /// The day, the child or the stories may have changed: choose again.
    func refreshForToday() {
        let today = TodaysStoryPicker.day(now(), calendar: calendar)
        let published = TodaysStoryPicker.published(source, today: today)
        dailyStories = published.map { $0.dailyStory(readOn: readDates[$0.id]) }

        let pinned = defaults.string(forKey: Key.todaysStoryDay) == today
            ? defaults.string(forKey: Key.todaysStoryID).flatMap(UUID.init(uuidString:))
            : nil
        let age = currentAge()
        let chosen = TodaysStoryPicker.pick(
            from: source, today: today, age: age, read: Set(readDates.keys), pinned: pinned)
        if let age, let chosen, !chosen.dailyStory(readOn: nil).matches(age: age) {
            // Bir içerik boşluğu: kayda geçer, ekranı boş bırakmaz.
            logger.warning("Günlük: \(age, privacy: .private) yaşına uygun masal yok, tüm havuzdan seçildi.")
        }
        todaysStory = chosen.flatMap { story in dailyStories.first { $0.id == story.id } }
        if let chosen {
            defaults.set(chosen.id.uuidString, forKey: Key.todaysStoryID)
            defaults.set(today, forKey: Key.todaysStoryDay)
        }
    }

    func markAsRead(storyId: UUID) {
        let date = now()
        readDates[storyId] = date
        saveReadDates()
        if let index = dailyStories.firstIndex(where: { $0.id == storyId }) {
            dailyStories[index].isRead = true
            dailyStories[index].lastReadDate = date
        }
        if todaysStory?.id == storyId {
            todaysStory?.isRead = true
            todaysStory?.lastReadDate = date
        }
    }

    func getStoriesByCategory(_ category: DailyStoryCategory) -> [DailyStory] {
        return dailyStories.filter { $0.category == category }
    }

    func getStoryOfTheDay() -> DailyStory? {
        return todaysStory
    }

    /// "Tüm verileri sil": what was read, and today's choice.
    func eraseReadingState() {
        Self.eraseAll(in: defaults)
        readDates = [:]
        refreshForToday()
    }

    static func eraseAll(in defaults: UserDefaults) {
        for key in [Key.readDates, Key.todaysStoryID, Key.todaysStoryDay, Key.legacyStories, Key.legacyRotation] {
            defaults.removeObject(forKey: key)
        }
    }

    // MARK: - Private Methods

    private func follow(_ feeds: AnyPublisher<ContentFeed?, Never>) {
        feedSubscription = feeds
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] feed in self?.apply(feed: feed) }
    }

    private static func stories(of feed: ContentFeed?, fallback: [FeedStory]) -> [FeedStory] {
        guard let stories = feed?.stories, !stories.isEmpty else { return fallback }
        return stories
    }

    private static func loadReadDates(_ defaults: UserDefaults) -> [UUID: Date] {
        guard let data = defaults.data(forKey: Key.readDates),
              let decoded = try? JSONDecoder().decode([String: Date].self, from: data) else { return [:] }
        return decoded.reduce(into: [:]) { result, entry in
            if let id = UUID(uuidString: entry.key) { result[id] = entry.value }
        }
    }

    private func saveReadDates() {
        let encoded = Dictionary(uniqueKeysWithValues: readDates.map { ($0.key.uuidString, $0.value) })
        if let data = try? JSONEncoder().encode(encoded) {
            defaults.set(data, forKey: Key.readDates)
        }
    }

    /// Once: the old list gave every story a fresh random id, so what was read
    /// is carried over by title onto the stable ids.
    private func migrateLegacyReadFlags() {
        guard let data = defaults.data(forKey: Key.legacyStories) else { return }
        if let legacy = try? JSONDecoder().decode([DailyStory].self, from: data) {
            let byTitle = Dictionary((source + fallback).map { ($0.title, $0.id) }, uniquingKeysWith: { first, _ in first })
            for story in legacy where story.isRead {
                guard let id = byTitle[story.title], readDates[id] == nil else { continue }
                readDates[id] = story.lastReadDate ?? now()
            }
            saveReadDates()
        }
        defaults.removeObject(forKey: Key.legacyStories)
        defaults.removeObject(forKey: Key.legacyRotation)
    }

    // MARK: - Bundled stories

    static let fallbackResourceName = "daily_feed_fallback"

    /// The stories the app ships with. Read only until the first feed arrives.
    nonisolated static func bundledFallback(bundle: Bundle = .main) -> [FeedStory] {
        guard let url = bundle.url(forResource: fallbackResourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let feed = try? JSONDecoder().decode(ContentFeed.self, from: data) else {
            logger.error("🛑 Günlük masal yedeği okunamadı")
            return []
        }
        return feed.stories
    }
}
