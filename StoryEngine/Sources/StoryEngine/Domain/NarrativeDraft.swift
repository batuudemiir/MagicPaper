import Foundation

/// The book's voice, captured once and reused everywhere.
///
/// This exists because pages are not written independently. When a single page
/// is later regenerated, it is re-written against this profile, so a fixed page
/// cannot drift into a different narrator than the rest of the book.
public struct VoiceProfile: Codable, Sendable, Hashable {
    public let narratorRegister: String
    public let sentenceRhythm: String
    public let recurringMotifs: [String]
    /// Speech traits per character display name.
    public let characterVoices: [String: String]

    public init(
        narratorRegister: String,
        sentenceRhythm: String,
        recurringMotifs: [String] = [],
        characterVoices: [String: String] = [:]
    ) {
        self.narratorRegister = narratorRegister
        self.sentenceRhythm = sentenceRhythm
        self.recurringMotifs = recurringMotifs
        self.characterVoices = characterVoices
    }
}

/// One beat's worth of continuous prose from the full draft.
public struct DraftSegment: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public let outlineBeatID: UUID
    public let text: String

    public init(id: UUID, outlineBeatID: UUID, text: String) {
        self.id = id
        self.outlineBeatID = outlineBeatID
        self.text = text
    }

    public var wordCount: Int { TextMetrics.wordCount(text) }
}

/// The whole story as continuous prose, written in one pass.
///
/// Written before pages are filled, so pacing, voice and the emotional arc are
/// decided for the book as a whole rather than page by page.
public struct NarrativeDraft: Codable, Sendable, Hashable {
    public let id: UUID
    public let voiceProfile: VoiceProfile
    public let segments: [DraftSegment]
    public let createdAt: Date

    public init(id: UUID, voiceProfile: VoiceProfile, segments: [DraftSegment], createdAt: Date) {
        self.id = id
        self.voiceProfile = voiceProfile
        self.segments = segments
        self.createdAt = createdAt
    }

    public func segment(forBeat beatID: UUID) -> DraftSegment? {
        segments.first { $0.outlineBeatID == beatID }
    }

    public var fullText: String { segments.map(\.text).joined(separator: "\n\n") }
    public var wordCount: Int { segments.reduce(0) { $0 + $1.wordCount } }
}
