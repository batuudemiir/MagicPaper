import Foundation
import StoryEngine

/// When an episode was read, and in which day (FAZ 13).
///
/// `day` is the calendar day in `timeZone` at the moment of reading, computed
/// from `SeriesClock.now()`. The next episode opens on a later day *in that
/// same time zone*, so flying east does not open it early.
struct SeriesReadMark: Codable, Equatable, Sendable {
    let at: Date
    /// `yyyy-MM-dd`.
    let day: String
    /// `TimeZone.identifier` at the moment of reading.
    let timeZone: String
}

/// One episode after the first story (FAZ 13).
///
/// Its text is written when the series starts and kept here: the catalog can
/// change later and this episode will not. Once its day comes it is copied
/// into the library as an ordinary `Story` (`storyID`); this record stays the
/// source, so an episode deleted from the library before it was read can be
/// put back.
struct SeriesEpisode: Codable, Equatable {
    /// 2…5.
    let number: Int
    var title: String
    /// The library's world for the cover; the same place every episode.
    var theme: StoryTheme
    var pages: [StoryPage]
    var origin: StoryOrigin
    /// The library copy, once the episode has opened.
    var storyID: UUID?
    var unlockedAt: Date?
    var read: SeriesReadMark?

    var isUnlocked: Bool { storyID != nil }
}

/// A liked story continued as four more episodes (FAZ 13).
///
/// Per child, on the device only (`StorySeriesStore`). Holds the child's name
/// and the episode text — the same data a saved `Story` holds — so its
/// `description` and `Mirror` show ids and counts only, never either.
struct StorySeries: Codable, Identifiable, Equatable,
                    CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    static let currentSchemaVersion = 1

    enum Status: String, Codable {
        /// Episodes still to come.
        case open
        /// Episode 5 was read: "Seri tamamlandı".
        case completed
        /// Ended early and calmly: the Masal ailem character was deleted and
        /// the catalog could no longer write the unopened episodes without it.
        case closed
    }

    var schemaVersion: Int
    let id: UUID
    let childID: UUID
    /// The name as the first story wrote it; an episode recomposed later uses
    /// the same spelling.
    let childName: String
    let firstStoryID: UUID
    let firstStoryTitle: String
    var plan: SeriesPlan
    var episodes: [SeriesEpisode]
    /// The first story counts as read when "Devam ettir" is pressed: the
    /// button is on its last page.
    let firstRead: SeriesReadMark
    var status: Status
    let createdAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        childID: UUID,
        childName: String,
        firstStoryID: UUID,
        firstStoryTitle: String,
        plan: SeriesPlan,
        episodes: [SeriesEpisode],
        firstRead: SeriesReadMark,
        createdAt: Date
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        self.id = id
        self.childID = childID
        self.childName = childName
        self.firstStoryID = firstStoryID
        self.firstStoryTitle = firstStoryTitle
        self.plan = plan
        self.episodes = episodes
        self.firstRead = firstRead
        self.status = .open
        self.createdAt = createdAt
        self.completedAt = nil
    }

    var isOpen: Bool { status == .open }

    /// The episode that opens next, or nil when every one has opened.
    var nextLocked: SeriesEpisode? { episodes.first { !$0.isUnlocked } }

    /// The read mark the next episode waits on: the one before it.
    func readMark(before number: Int) -> SeriesReadMark? {
        number == 2 ? firstRead : episodes.first { $0.number == number - 1 }?.read
    }

    /// How many of the five have been read, the first story included.
    var readCount: Int { 1 + episodes.filter { $0.read != nil }.count }

    var description: String {
        "StorySeries(\(id.uuidString.prefix(8)), \(status.rawValue), \(readCount)/5)"
    }
    var debugDescription: String { description }
    var customMirror: Mirror {
        Mirror(self, children: ["id": id, "status": status, "episodes": episodes.count])
    }
}
