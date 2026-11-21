import Foundation
import StoryEngine

/// Everything a new story is written from (E2, `docs/EVREN_PLANI.md`).
///
/// Collected in one place instead of line by line inside
/// `StoryGenerationManager.createStory`: the parent's choices, the child's
/// profile, and what the library says about this child (recent content,
/// reading outcomes, recent titles, the stories a recall line may point to).
/// Nothing here is stored; the context is built, composed from, and dropped.
///
/// `childStories` compares by id only, because `Story: Equatable` does.
struct StoryContext: Equatable {
    var childName: String
    var childProfileID: UUID
    var age: Int
    var mode: StoryMode?
    var strategy: StorySelectionStrategy?
    var storyIdeaID: String?
    var companionID: String?
    var subOption: String?
    var family: FamilyCharacter?
    var interests: [String]
    /// This child's story origins, newest first, at most
    /// `SelectionScoring.historyWindow` (A1: satır penceresi içerikten uzun olabilir); stories without one are skipped.
    var recent: [StoryOrigin]
    var usage: [StoryUsage]
    /// This child's newest titles, at most `StoryGenerationManager.titleMemory`.
    var recentTitles: Set<String>
    /// This child's stories, in library order.
    var childStories: [Story]
    /// What the engine may recall (E3): companions and places from this
    /// child's finished standalone stories, as ids and counts. Nil when there
    /// is nothing to recall or one of the two newest stories already recalled.
    var recall: RecallHistory? = nil
    /// The special day this story is written for (E6), nil for every other.
    var occasion: OccasionRequest? = nil
}

/// A context never prints what it holds: `"\(context)"` in a log line would
/// otherwise carry the child's name, interests, titles and story text.
/// Counts and catalog ids only, as `UserProfile` does.
extension StoryContext: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    var description: String {
        "StoryContext(mode: \(mode?.rawValue ?? "-"), idea: \(storyIdeaID ?? "-"), "
            + "companion: \(companionID ?? "-"), family: \(family == nil ? 0 : 1), "
            + "interests: \(interests.count), recent: \(recent.count), usage: \(usage.count), "
            + "titles: \(recentTitles.count), stories: \(childStories.count), "
            + "recall: \(recall == nil ? 0 : 1), occasion: \(occasion?.kind.rawValue ?? "-"))"
    }
    var debugDescription: String { description }
    var customMirror: Mirror {
        Mirror(self, children: [
            "recent": recent.count, "usage": usage.count,
            "titles": recentTitles.count, "stories": childStories.count,
        ])
    }
}

/// Builds a `StoryContext` from the parent's choices, the profile and the
/// whole library. The single source for "this child's recent stories":
/// `StoryGenerationManager.recentOrigins`, `recentTitles` and `recentModes`
/// delegate here.
///
/// `@MainActor` only because `StoryGenerationManager.titleMemory`, the window
/// it reads rather than copies, lives on a main-actor class.
@MainActor
struct StoryContextBuilder {
    var usageStore: StoryUsageStore

    init(usageStore: StoryUsageStore = StoryUsageStore()) {
        self.usageStore = usageStore
    }

    func build(
        for profile: UserProfile,
        library: [Story],
        mode: StoryMode?,
        strategy: StorySelectionStrategy?,
        storyIdeaID: String?,
        companionID: String?,
        subOption: String?,
        family: FamilyCharacter?,
        occasion: OccasionRequest? = nil
    ) -> StoryContext {
        let own = Self.stories(of: profile, in: library)
        return StoryContext(
            childName: profile.name,
            childProfileID: profile.id,
            age: profile.age,
            mode: mode,
            strategy: strategy,
            storyIdeaID: storyIdeaID,
            companionID: companionID,
            subOption: subOption,
            family: family,
            interests: profile.interests,
            recent: Self.recentOrigins(of: library, for: profile),
            usage: usageStore.usage(of: own, for: profile.id),
            recentTitles: Self.recentTitles(of: library, for: profile),
            childStories: own,
            recall: Self.recallHistory(of: own),
            occasion: occasion
        )
    }

    /// How many of the child's newest stories are looked at for an earlier
    /// recall. One in either keeps this story without one: at most one recall
    /// in three stories, so the memory stays a surprise and not a formula.
    static let recallSpacing = 2

    /// What the engine may recall from this child's stories (E3), or nil.
    ///
    /// Counted from finished standalone stories only, as `StoryMemory` did
    /// (Faz 10): an unfinished story was not lived through, a series episode
    /// carries its own continuity, and a story without an origin says nothing.
    /// "First met" is the earliest by when it was read.
    static func recallHistory(of childStories: [Story]) -> RecallHistory? {
        let newest = childStories.sorted { $0.createdAt > $1.createdAt }.prefix(recallSpacing)
        guard !newest.contains(where: { $0.origin?.recalled == true }) else { return nil }

        let earlier = childStories
            .filter { $0.isFinished && $0.origin != nil && $0.origin?.seriesEpisode == nil }
            .sorted { ($0.lastReadAt ?? $0.createdAt) < ($1.lastReadAt ?? $1.createdAt) }
        var companions: [ContentID: RecallHistory.Companion] = [:]
        var visited: Set<ContentID> = []
        for origin in earlier.compactMap(\.origin) {
            let companion = ContentID(origin.companionID)
            let setting = ContentID(origin.settingID)
            let count = (companions[companion]?.storyCount ?? 0) + 1
            let first = companions[companion]?.firstSettingID ?? setting
            companions[companion] = .init(storyCount: count, firstSettingID: first)
            visited.insert(setting)
        }
        let history = RecallHistory(companions: companions, visitedSettings: visited)
        return history.isEmpty ? nil : history
    }

    /// The child's stories, in library order: by profile id, and by name for
    /// stories written before the id existed (`Story.belongs(to:)`).
    static func stories(of profile: UserProfile, in library: [Story]) -> [Story] {
        library.filter { $0.belongs(to: profile) }
    }

    private static func newestFirst(of library: [Story], for profile: UserProfile) -> [Story] {
        stories(of: profile, in: library).sorted { $0.createdAt > $1.createdAt }
    }

    /// What this child's most recent stories were made of, newest first
    /// (FAZ 12). Stories without an origin say nothing and are skipped.
    static func recentOrigins(
        of library: [Story], for profile: UserProfile, limit: Int = SelectionScoring.historyWindow
    ) -> [StoryOrigin] {
        Array(newestFirst(of: library, for: profile).compactMap(\.origin).prefix(limit))
    }

    /// The titles of this child's newest stories, for the engine to avoid
    /// writing again (`TitleComposer`). Only titles.
    static func recentTitles(
        of library: [Story], for profile: UserProfile, limit: Int = StoryGenerationManager.titleMemory
    ) -> Set<String> {
        Set(newestFirst(of: library, for: profile).prefix(limit).map(\.title))
    }

    /// The modes of this child's most recent stories, newest first, for
    /// "Bana sürpriz yap". Only stories that recorded a mode count.
    static func recentModes(
        of library: [Story], for profile: UserProfile, limit: Int = StoryModeResolver.historyWindow
    ) -> [StoryMode] {
        Array(newestFirst(of: library, for: profile).compactMap { $0.origin?.mode }.prefix(limit))
    }
}
