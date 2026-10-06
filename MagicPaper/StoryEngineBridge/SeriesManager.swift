import Foundation
import OSLog
import StoryEngine

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "SeriesManager")

/// Everything the app does with a series (FAZ 13), behind one door.
///
/// Views ask it whether a story can be continued, start a series, report that
/// an episode was read, and read the series card's state. The rules live here
/// and in `SeriesClock`; the plan and the text come from the engine through
/// `OfflineStoryService`. No notification is ever scheduled (calm UX): an
/// episode that has opened is simply on the shelf and the card the next time
/// the app is opened.
@MainActor
final class SeriesManager: ObservableObject {

    static let shared = SeriesManager()

    /// Bumped whenever a series changes, so screens that read it redraw.
    @Published private(set) var revision = 0

    enum Eligibility: Equatable {
        /// "Devam ettir" is offered.
        case available
        /// This child already has a series open; the calm line explains.
        case blockedByOpenSeries
        /// Not continuable: a surprise, an episode, a story from before modes,
        /// a story already continued, or a mode and band no continuation serves.
        case unavailable
    }

    enum ReadOutcome: Equatable {
        case notAnEpisode
        case episodeRead
        /// Episode 5 was read: the series is complete.
        case seriesCompleted
    }

    enum StartFailure: Error, Equatable {
        case notEligible
        case couldNotWrite
    }

    private let store: StorySeriesStore
    private let clock: SeriesClock
    private let familyStore: FamilyCharacterStore
    private let library: StoryGenerationManager
    private let service: OfflineStoryService

    init(
        store: StorySeriesStore = StorySeriesStore(),
        clock: SeriesClock = SeriesClock(),
        familyStore: FamilyCharacterStore = FamilyCharacterStore(),
        library: StoryGenerationManager? = nil,
        service: OfflineStoryService? = nil
    ) {
        self.store = store
        self.clock = clock
        self.familyStore = familyStore
        self.library = library ?? .shared
        self.service = service ?? .shared
    }

    // MARK: - Reading state

    func openSeries(for childID: UUID) -> StorySeries? { list(for: childID).first(where: \.isOpen) }

    func allSeries(for childID: UUID) -> [StorySeries] { list(for: childID) }

    /// What the child's file holds, decoded once until the file changes.
    /// Screens ask from `body`; without this every redraw read and decoded
    /// the file, episode text included.
    private var cache: [UUID: (stamp: Date?, list: [StorySeries])] = [:]

    private func list(for childID: UUID) -> [StorySeries] {
        let stamp = store.modificationDate(for: childID)
        if let cached = cache[childID], cached.stamp == stamp { return cached.list }
        let list = store.series(for: childID)
        cache[childID] = (stamp, list)
        return list
    }

    /// Writes a series. A failed write is logged and reported, never shown as
    /// if it had happened.
    @discardableResult
    private func save(_ series: StorySeries) -> Bool {
        defer { cache[series.childID] = nil }
        do {
            try store.save(series)
            return true
        } catch {
            logger.notice("Seri: kaydedilemedi")
            return false
        }
    }

    /// The series a story belongs to: as its first story or as an episode.
    func series(containing story: Story) -> StorySeries? {
        guard let childID = story.childProfileID else { return nil }
        let id = story.origin?.seriesID
        return list(for: childID).first {
            $0.id.uuidString == id || $0.firstStoryID == story.id
        }
    }

    // MARK: - What the screens show

    /// The series part of a story's last page.
    enum EndingState: Equatable {
        case none
        /// "Devam ettir".
        case offer
        /// Another series of this child is open: the calm line.
        case blocked
        /// This story started the open series.
        case started
        /// An episode of the open series.
        case episode(Int)
        /// The last episode of a finished series: "Seri tamamlandı".
        case completed
    }

    func endingState(for story: Story) -> EndingState {
        if let series = series(containing: story) {
            if story.id == series.firstStoryID { return series.isOpen ? .started : .none }
            let number = story.origin?.seriesEpisode ?? 0
            switch series.status {
            case .completed:
                return number == SeriesPlanner.episodeNumbers.last ? .completed : .none
            case .open:
                return .episode(number)
            case .closed:
                return .none
            }
        }
        switch eligibility(for: story) {
        case .available: return .offer
        case .blockedByOpenSeries: return .blocked
        case .unavailable: return .none
        }
    }

    /// The series card on Home and in the Library.
    enum CardState: Equatable {
        /// An episode has opened and is waiting to be read.
        case ready(storyID: UUID, episode: Int, title: String)
        /// The next episode opens on a later day.
        case waiting(episode: Int, title: String)
    }

    func cardState(for childID: UUID) -> CardState? {
        guard let series = openSeries(for: childID) else { return nil }
        if let ready = series.episodes.first(where: { $0.isUnlocked && $0.read == nil }),
           let id = ready.storyID {
            return .ready(storyID: id, episode: ready.number, title: series.firstStoryTitle)
        }
        if let next = series.nextLocked {
            return .waiting(episode: next.number, title: series.firstStoryTitle)
        }
        return nil
    }

    // MARK: - Eligibility

    func eligibility(for story: Story) -> Eligibility {
        guard story.status == .completed,
              let origin = story.origin,
              origin.selectionStrategy == StorySelectionStrategy.direct.rawValue,
              origin.seriesID == nil,
              let childID = story.childProfileID,
              let mode = origin.mode,
              let band = origin.ageBand.flatMap(AgeBand.init),
              service.seriesAvailable(mode: mode, band: band)
        else { return .unavailable }
        let all = list(for: childID)
        // A story continues once. Whether a finished series' first story may
        // start another is not decided; today it may not.
        if all.contains(where: { $0.firstStoryID == story.id }) { return .unavailable }
        if all.contains(where: \.isOpen) { return .blockedByOpenSeries }
        return .available
    }

    // MARK: - Starting

    /// Plans the series, writes all four episodes and saves them. Episode 2
    /// opens on the next calendar day.
    @discardableResult
    func startSeries(from story: Story) throws -> StorySeries {
        guard eligibility(for: story) == .available,
              let origin = story.origin, let childID = story.childProfileID
        else { throw StartFailure.notEligible }

        // The character the first story was written with, if it still exists.
        // Its name today goes into the episodes; a deleted one is left out.
        let family = origin.familyCharacterID
            .flatMap(UUID.init(uuidString:))
            .flatMap { id in familyStore.characters(for: childID).first { $0.id == id } }

        let planned = try service.planSeries(from: origin, childName: story.childName, family: family)
        let id = UUID()
        let episodes = zip(planned.plan.episodes, planned.episodes).map { entry, composed in
            Self.episode(
                number: entry.number, composed: composed, seriesID: id, childName: story.childName,
                childID: childID, plan: planned.plan, strategy: origin.selectionStrategy,
                family: planned.plan.family == nil ? nil : family)
        }
        let series = StorySeries(
            id: id, childID: childID, childName: story.childName,
            firstStoryID: story.id, firstStoryTitle: story.title,
            plan: planned.plan, episodes: episodes, firstRead: clock.mark(), createdAt: clock.now())
        guard save(series) else { throw StartFailure.couldNotWrite }
        logger.info("Seri başladı (4 bölüm)")
        revision += 1
        return series
    }

    // MARK: - Reading

    /// The child reached the last page of a story. For an episode, that is
    /// what the next episode waits on.
    @discardableResult
    func markRead(_ story: Story) -> ReadOutcome {
        guard let childID = story.childProfileID,
              let seriesID = story.origin?.seriesID,
              let number = story.origin?.seriesEpisode,
              var series = list(for: childID).first(where: { $0.id.uuidString == seriesID }),
              let index = series.episodes.firstIndex(where: { $0.number == number })
        else { return .notAnEpisode }
        guard series.episodes[index].read == nil else {
            return series.status == .completed && number == SeriesPlanner.episodeNumbers.last
                ? .seriesCompleted : .episodeRead
        }
        series.episodes[index].read = clock.mark()
        var outcome = ReadOutcome.episodeRead
        // Only an open series with all its episodes completes: a series that
        // closed early (its unopened episodes gone) stays closed.
        if series.status == .open,
           series.episodes.count == SeriesPlanner.episodeNumbers.count,
           series.episodes.allSatisfy({ $0.read != nil }) {
            series.status = .completed
            series.completedAt = clock.now()
            outcome = .seriesCompleted
            logger.info("Seri tamamlandı")
        }
        guard save(series) else { return .episodeRead }
        revision += 1
        return outcome
    }

    /// Opens the next episode when its day has come, and puts back an opened
    /// episode that was deleted from the library before it was read. At most
    /// one episode opens: the one after it waits for this one to be read.
    func refreshUnlocks(for childID: UUID) {
        guard var series = openSeries(for: childID) else { return }
        var changed = false

        for index in series.episodes.indices {
            let episode = series.episodes[index]
            guard let storyID = episode.storyID, episode.read == nil,
                  library.getStory(id: storyID) == nil else { continue }
            library.addStoryToLibrary(Self.story(for: episode, of: series, id: storyID))
            changed = true
        }

        if let next = series.nextLocked,
           let index = series.episodes.firstIndex(where: { $0.number == next.number }),
           let waitingOn = series.readMark(before: next.number),
           clock.dayHasPassed(since: waitingOn) {
            let storyID = UUID()
            series.episodes[index].storyID = storyID
            series.episodes[index].unlockedAt = clock.now()
            library.addStoryToLibrary(Self.story(for: series.episodes[index], of: series, id: storyID))
            logger.info("Seri: yeni bölüm açıldı")
            changed = true
        }

        guard changed, save(series) else { return }
        revision += 1
    }

    // MARK: - Deletion

    /// A Masal ailem character was deleted (karar: 6 Ekim 2026). Opened
    /// episodes stay as they were written. Unopened ones are written again from
    /// the same plan without the character; if the catalog can no longer do
    /// that, the series ends calmly with what has opened.
    func familyCharacterRemoved(id: UUID, childID: UUID) {
        for var series in list(for: childID)
        where series.isOpen && series.plan.family?.characterID == id.uuidString {
            let plan = series.plan.withoutFamily()
            do {
                let composed = try service.composeSeries(plan, childName: series.childName, family: nil)
                for (entry, story) in zip(plan.episodes, composed) {
                    guard let index = series.episodes.firstIndex(where: { $0.number == entry.number }),
                          !series.episodes[index].isUnlocked else { continue }
                    series.episodes[index] = Self.episode(
                        number: entry.number, composed: story, seriesID: series.id,
                        childName: series.childName, childID: childID, plan: plan,
                        strategy: series.episodes[index].origin.selectionStrategy, family: nil)
                }
                series.plan = plan
                logger.info("Seri: Masal ailem karakteri çıkarıldı, açılmamış bölümler yeniden yazıldı")
            } catch {
                series.episodes.removeAll { !$0.isUnlocked }
                series.status = .closed
                series.completedAt = clock.now()
                logger.notice("Seri: açılmamış bölümler yazılamadı, seri kapandı")
            }
            if save(series) { revision += 1 }
        }
    }

    /// Every series of a deleted profile.
    func deleteAll(for childID: UUID) {
        store.delete(for: childID)
        cache[childID] = nil
        revision += 1
    }

    // MARK: - Mapping

    private static func episode(
        number: Int,
        composed: ComposedStory,
        seriesID: UUID,
        childName: String,
        childID: UUID,
        plan: SeriesPlan,
        strategy: String?,
        family: FamilyCharacter?
    ) -> SeriesEpisode {
        let story = OfflineStoryMapper.appStory(
            from: composed,
            childName: childName,
            childProfileID: childID,
            storyIdeaID: nil,
            catalogVersion: plan.catalogVersion,
            mode: plan.mode,
            selectionStrategy: strategy.flatMap(StorySelectionStrategy.init(rawValue:)),
            ageBand: plan.ageBand,
            familyCharacter: family,
            series: (seriesID, number))
        guard let origin = story.origin else {
            preconditionFailure("OfflineStoryMapper always writes an origin")
        }
        return SeriesEpisode(
            number: number, title: story.title, theme: story.theme, pages: story.pages,
            origin: origin,
            storyID: nil, unlockedAt: nil, read: nil)
    }

    /// The library copy of an opened episode.
    static func story(for episode: SeriesEpisode, of series: StorySeries, id: UUID) -> Story {
        Story(
            id: id, title: episode.title, childName: series.childName,
            childProfileID: series.childID, theme: episode.theme, language: .turkish,
            status: .completed, pages: episode.pages, origin: episode.origin)
    }
}
