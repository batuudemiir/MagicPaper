import Foundation

/// One beat of the arc, filled in for this particular story.
public struct OutlineBeat: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    /// Which `TemplateBeat` this came from. A repeatable middle beat can appear
    /// more than once, so this is not unique across the outline.
    public let templateBeatID: String
    public let role: BeatRole
    public let ordinal: Int
    public let summary: String
    public let settingKey: String
    public let timeOfDayKey: String
    public let moodKey: String
    /// Display names of the characters present. Identity itself stays in the cast.
    public let castNames: [String]
    public let compositionRuleID: String?

    public init(
        id: UUID,
        templateBeatID: String,
        role: BeatRole,
        ordinal: Int,
        summary: String,
        settingKey: String,
        timeOfDayKey: String,
        moodKey: String,
        castNames: [String],
        compositionRuleID: String? = nil
    ) {
        self.id = id
        self.templateBeatID = templateBeatID
        self.role = role
        self.ordinal = ordinal
        self.summary = summary
        self.settingKey = settingKey
        self.timeOfDayKey = timeOfDayKey
        self.moodKey = moodKey
        self.castNames = castNames
        self.compositionRuleID = compositionRuleID
    }
}

/// The shape of the story before a word of prose exists.
public struct StoryOutline: Codable, Sendable, Hashable {
    public let title: String
    public let logline: String
    public let beats: [OutlineBeat]

    public init(title: String, logline: String, beats: [OutlineBeat]) {
        self.title = title
        self.logline = logline
        self.beats = beats
    }

    public func beat(id: UUID) -> OutlineBeat? { beats.first { $0.id == id } }
}
