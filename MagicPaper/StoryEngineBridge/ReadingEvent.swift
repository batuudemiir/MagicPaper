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
/// together on the device (a re-read is a second session of the same story).
/// It **never leaves the device** (karar: 6 Ekim 2026): events of one device
/// could be linked through it, and the server's table — finished and re-read
/// per blueprint — does not need it; `reread` is already decided here.
/// What is sent is `ReadingEventWire`.
///
/// Sent by `ReadingEventUploader` (FAZ 16) when the parent's switch
/// (`shareUsageData`) is on and the parent has seen the consent text. Until
/// then events wait in `ReadingEventQueue`. The keys of `ReadingEventWire` are
/// a contract with the server and its rules: `ReadingEventTests` pins them.
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

/// A reading event as it leaves the device: the event without `storyID`.
struct ReadingEventWire: Codable, Equatable, Sendable {
    let schemaVersion: Int
    let mode: String?
    let blueprintID: String
    let contentIDs: ReadingEvent.ContentIDs
    let companionKind: String?
    let familyRelation: String?
    let ageBand: String?
    let pageReached: Int
    let pageCount: Int
    let finished: Bool
    let reread: Bool
    let day: String

    init(_ event: ReadingEvent) {
        schemaVersion = event.schemaVersion
        mode = event.mode
        blueprintID = event.blueprintID
        contentIDs = event.contentIDs
        companionKind = event.companionKind
        familyRelation = event.familyRelation
        ageBand = event.ageBand
        pageReached = event.pageReached
        pageCount = event.pageCount
        finished = event.finished
        reread = event.reread
        day = event.day
    }

    /// The document as Firestore takes it. Absent optionals are left out,
    /// never written as null.
    var fields: [String: Any] {
        var fields: [String: Any] = [
            "schemaVersion": schemaVersion,
            "blueprintID": blueprintID,
            "contentIDs": ["setting": contentIDs.setting,
                           "companion": contentIDs.companion,
                           "discovery": contentIDs.discovery],
            "pageReached": pageReached,
            "pageCount": pageCount,
            "finished": finished,
            "reread": reread,
            "day": day,
        ]
        if let mode { fields["mode"] = mode }
        if let companionKind { fields["companionKind"] = companionKind }
        if let familyRelation { fields["familyRelation"] = familyRelation }
        if let ageBand { fields["ageBand"] = ageBand }
        return fields
    }
}
