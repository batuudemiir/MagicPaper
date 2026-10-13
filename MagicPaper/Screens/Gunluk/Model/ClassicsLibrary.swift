import Foundation
import Combine

/// Günlük ekranlarının okuduğu tek yer (FAZ 20).
///
/// Katalog (`ClassicsCatalog`), çocuğun defteri (`ClassicProgressStore`) ve
/// günlük akışın kendi masalları (`DailyStoryManager`) burada birleşir.
/// Kurallar katalogda; burada yalnızca "bugün", "bu çocuk" ve "bu yaş".
@MainActor
final class ClassicsLibrary: ObservableObject {

    static let shared = ClassicsLibrary()

    let catalog: ClassicsCatalog
    let progress: ClassicProgressStore

    private let defaults: UserDefaults
    private let now: () -> Date
    private let calendar: Calendar
    private let currentAge: () -> Int?
    private let dailyStories: () -> [DailyStory]
    private var cancellables: Set<AnyCancellable> = []

    enum Key {
        static let todayID = "mp_classicTodayID"
        static let todayDay = "mp_classicTodayDay"
    }

    init(
        catalog: ClassicsCatalog = .bundled,
        progress: ClassicProgressStore? = nil,
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current,
        currentAge: (() -> Int?)? = nil,
        dailyStories: (() -> [DailyStory])? = nil
    ) {
        self.catalog = catalog
        self.progress = progress ?? .shared
        self.defaults = defaults
        self.now = now
        self.calendar = calendar
        self.currentAge = currentAge ?? { ProfileManager.shared.currentProfile?.age }
        self.dailyStories = dailyStories ?? { DailyStoryManager.shared.dailyStories }
        // Defter değişince ekranlar yenilensin.
        self.progress.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var age: Int? { currentAge() }

    // MARK: - Günün masalı

    /// Bugünün masalı. Gün içinde sabit: okununca başkasına geçmez.
    var todaysTale: ClassicTale? {
        let today = TodaysStoryPicker.day(now(), calendar: calendar)
        let pinned = defaults.string(forKey: Key.todayDay) == today
            ? defaults.string(forKey: Key.todayID).flatMap(UUID.init(uuidString:))
            : nil
        guard let tale = catalog.todaysTale(day: today, age: age, read: progress.finishedIDs, pinned: pinned) else {
            return nil
        }
        if pinned != tale.id {
            defaults.set(today, forKey: Key.todayDay)
            defaults.set(tale.id.uuidString, forKey: Key.todayID)
        }
        return tale
    }

    // MARK: - Kaldığın yerden

    struct InProgress: Identifiable, Equatable {
        let id: UUID
        let title: String
        let cover: String
        let coverFocus: ClassicFocus
        let fraction: Double
        let minutesLeft: Int
    }

    var continueReading: [InProgress] {
        progress.inProgress().compactMap { id, entry in
            if let tale = catalog.tale(id) {
                let left = max(1, Int((Double(tale.minutes) * (1 - entry.fraction)).rounded(.up)))
                return InProgress(id: id, title: tale.title, cover: tale.cover, coverFocus: tale.coverFocus,
                                  fraction: entry.fraction, minutesLeft: left)
            }
            if let original = original(id) {
                let left = max(1, Int((Double(original.story.readingTime) * (1 - entry.fraction)).rounded(.up)))
                return InProgress(id: id, title: original.story.title, cover: original.cover.cover,
                                  coverFocus: original.cover.coverFocus, fraction: entry.fraction, minutesLeft: left)
            }
            return nil
        }
    }

    // MARK: - Raflar

    func items(in shelf: ClassicShelf?, ageBand: MPAgeRange? = nil) -> [ClassicItem] {
        let items = catalog.items(in: shelf)
        guard let ageBand else { return items }
        return items.filter { $0.ageMin <= ageBand.band.upperBound && $0.ageMax >= ageBand.band.lowerBound }
    }

    var weeklyPicks: [ClassicItem] { catalog.weeklyPicks }

    // MARK: - Orijinal masallar (günlük akış)

    struct Original: Identifiable, Equatable {
        let story: DailyStory
        let cover: ClassicOriginalCover
        var id: UUID { story.id }
        var meta: String { "Orijinal · \(story.readingTime) dk" }
    }

    /// Kapağı olan akış masalları, rafıyla. Kapaksız masal Günlük'te
    /// gösterilmez: her kapak boyalı bir illüstrasyon (Rapunzel kuralı).
    func originals(in shelf: ClassicShelf) -> [Original] {
        dailyStories().compactMap { story in
            guard let cover = catalog.originalCover(feedID: story.id), cover.shelves.contains(shelf) else { return nil }
            return Original(story: story, cover: cover)
        }
    }

    func original(_ id: UUID) -> Original? {
        guard let story = dailyStories().first(where: { $0.id == id }),
              let cover = catalog.originalCover(feedID: id) else { return nil }
        return Original(story: story, cover: cover)
    }

    // MARK: - Bölümler

    struct EpisodeState: Equatable {
        enum Status: Equatable { case finished, current, unread }
        let status: Status
        let fraction: Double
    }

    func state(of episode: ClassicTale) -> EpisodeState {
        guard let entry = progress.entry(episode.id) else { return EpisodeState(status: .unread, fraction: 0) }
        if entry.isFinished { return EpisodeState(status: .finished, fraction: 1) }
        if entry.page > 0 { return EpisodeState(status: .current, fraction: entry.fraction) }
        return EpisodeState(status: .unread, fraction: 0)
    }

    /// Serinin devam edilecek bölümü: yarım kalan, yoksa ilk bitmemiş, hepsi
    /// bittiyse ilki.
    func nextEpisode(of seriesID: UUID) -> ClassicTale? {
        let episodes = catalog.episodes(of: seriesID)
        return episodes.first { state(of: $0).status == .current }
            ?? episodes.first { state(of: $0).status != .finished }
            ?? episodes.first
    }
}
