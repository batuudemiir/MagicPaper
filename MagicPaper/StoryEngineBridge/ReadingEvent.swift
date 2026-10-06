import Foundation

/// One reading session, as it may leave the device (FAZ 14).
///
/// Built so that it can be sent without telling anyone who read it: catalog
/// ids, counts, the band and the day. **Never** the child's name, exact age,
/// a Masal ailem name, the profile id, a device id or the time of day — the
/// day alone is coarse enough that a family's evening routine stays theirs.
/// Masal ailem appears only as its relation kind.
///
/// `storyID` is the story's own random UUID; it ties a story's sessions
/// together (a re-read is a second session of the same story). It says
/// nothing about the child by itself, but events of one device can be linked
/// through it: pseudonymous, not anonymous. FAZ 16 decides whether to send it
/// as is, rotate it per batch, or drop it.
///
/// Sending is FAZ 16's (with the parent's switch, `shareUsageData`). Until
/// then events wait in `ReadingEventQueue`. The keys below are a contract with
/// the server: `ReadingEventTests` pins them.
struct ReadingEvent: Codable, Equatable, Sendable {
    static let schemaVersion = 1

    struct ContentIDs: Codable, Equatable, Sendable {
        let setting: String
        let companion: String
        let discovery: String
    }

    var schemaVersion: Int = ReadingEvent.schemaVersion
    let storyID: String
    /// `StoryMode.rawValue`; nil for a story written before modes existed.
    let mode: String?
    let blueprintID: String
    let contentIDs: ContentIDs
    /// The companion's catalog type ("tavşan"): what kind of friend the story
    /// had, comparable across catalog versions where ids are not.
    let companionKind: String?
    /// `FamilyRelationKind.rawValue` when the story had a Masal ailem
    /// character. The kind only.
    let familyRelation: String?
    /// "5-6". A band, never an age.
    let ageBand: String?
    /// The furthest page reached in this session, from 0.
    let pageReached: Int
    let pageCount: Int
    /// The session reached the end of the story.
    let finished: Bool
    /// It reached the end, and the story had been finished before.
    let reread: Bool
    /// `yyyy-MM-dd` in the reader's time zone (`SeriesClock.day`).
    let day: String

    /// Nil for a story the offline engine did not write (old pipeline, the
    /// sample book): it has no ids worth learning from.
    init?(
        story: Story,
        pageReached: Int,
        finished: Bool,
        reread: Bool,
        companionKind: String?,
        at date: Date,
        in zone: TimeZone
    ) {
        guard let origin = story.origin else { return nil }
        storyID = story.id.uuidString
        mode = origin.mode?.rawValue
        blueprintID = origin.blueprintID
        contentIDs = ContentIDs(
            setting: origin.settingID, companion: origin.companionID, discovery: origin.discoveryID)
        self.companionKind = companionKind
        familyRelation = origin.familyRelation
        ageBand = origin.ageBand
        pageCount = story.pages.count
        self.pageReached = min(max(pageReached, 0), max(story.pages.count - 1, 0))
        self.finished = finished
        self.reread = reread
        day = SeriesClock.day(of: date, in: zone)
    }
}

extension ReadingEvent: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    // Nothing here is personal, but a log line has no business carrying a
    // story's id either: the shape is enough to debug with.
    var description: String { "ReadingEvent(\(mode ?? "-"), finished: \(finished), reread: \(reread))" }
    var debugDescription: String { description }
    var customMirror: Mirror {
        Mirror(self, children: ["mode": mode as Any, "finished": finished, "reread": reread])
    }
}
