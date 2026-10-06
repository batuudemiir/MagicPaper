import Foundation

/// What one opening of the reader tells MagicPaper (FAZ 14).
///
/// The reader reports two things — the last page was reached, "Tekrar oku"
/// was pressed — and closes the session once. Closing writes the child's own
/// reading record (`StoryUsageStore`, which the engine learns from) and, when
/// the parent allows sharing, one anonymous `ReadingEvent` to the queue.
///
/// A session is recorded only if it was a reading (`MPReadingSession`): a
/// book opened and shut by accident teaches nothing. Going to the background
/// records nothing; the session ends when the reader does. If the app is
/// killed in the background, that session is lost — one data point, never a
/// wrong one.
@MainActor
final class ReadingSessionRecorder {

    private let story: Story
    private let usageStore: StoryUsageStore
    private let queue: ReadingEventQueue
    private let isSharing: @MainActor () -> Bool
    private let companionKind: @MainActor (String) -> String?
    private let now: () -> Date
    private let timeZone: () -> TimeZone

    private var completions = 0
    /// The first arrival at the end counts; after that only one that follows
    /// "Tekrar oku" does, so paging back and forth at the end is one reading.
    private var nextEndingCounts = true
    private var closed = false

    init(
        story: Story,
        usageStore: StoryUsageStore = StoryUsageStore(),
        queue: ReadingEventQueue = ReadingEventQueue(),
        isSharing: (() -> Bool)? = nil,
        // Varsayılanlar aktör dışında değerlendirildiği için canlı olanlar
        // init gövdesinde kurulur (`StoryReaderModel` ile aynı sebep).
        companionKind: ((String) -> String?)? = nil,
        now: @escaping () -> Date = Date.init,
        timeZone: @escaping () -> TimeZone = { .current }
    ) {
        self.story = story
        self.usageStore = usageStore
        self.queue = queue
        self.isSharing = isSharing ?? { MPSettingsStore.shared.shareUsageData }
        self.companionKind = companionKind ?? { OfflineStoryService.shared.companionKind(id: $0) }
        self.now = now
        self.timeZone = timeZone
    }

    func reachedEnding() {
        guard !closed, nextEndingCounts else { return }
        nextEndingCounts = false
        completions += 1
    }

    func readAgain() {
        nextEndingCounts = true
    }

    /// The reader closed, or today's reading time ran out. Once per session.
    func close(furthestPage: Int, session: MPReadingSession) {
        guard !closed else { return }
        closed = true
        guard let childID = story.childProfileID, story.origin != nil,
              session.isMeaningful || completions > 0 else { return }

        let before = usageStore.stats(of: story.id, for: childID)?.completions ?? 0
        usageStore.recordSession(
            storyID: story.id, childID: childID, completions: completions, furthestPage: furthestPage)

        guard isSharing(), let event = ReadingEvent(
            story: story,
            pageReached: furthestPage,
            finished: completions > 0,
            reread: completions > 1 || (completions > 0 && before > 0),
            companionKind: story.origin.flatMap { companionKind($0.companionID) },
            at: now(),
            in: timeZone()
        ) else { return }
        queue.append(event, for: childID)
    }
}
