import Foundation

/// Which story is Günün masalı. Deterministic: the same stories, day, age and
/// reading history always give the same story — on every device.
///
/// 1. Only stories whose day has come (`publishDate ≤ today`).
/// 2. Those for the child's age; if none fit, all of them — an empty Günlük
///    page is worse than a story a year off.
/// 3. Unread first. The story already chosen today counts as unread, so
///    reading it does not swap it for another one mid-day.
/// 4. The newest day first, then the id — a newly published story wins the
///    day it is published.
enum TodaysStoryPicker {
    static func pick(
        from stories: [FeedStory],
        today: String,
        age: Int?,
        read: Set<UUID>,
        pinned: UUID?
    ) -> FeedStory? {
        let published = Self.published(stories, today: today)
        let forAge = age.map { age in published.filter { $0.dailyStory(readOn: nil).matches(age: age) } } ?? published
        let pool = forAge.isEmpty ? published : forAge
        let unread = pool.filter { !read.contains($0.id) || $0.id == pinned }
        return (unread.isEmpty ? pool : unread).min(by: comesFirst)
    }

    /// Stories whose day has come, newest first; equal days keep the feed's order.
    static func published(_ stories: [FeedStory], today: String) -> [FeedStory] {
        let indexed: [(offset: Int, story: FeedStory)] = stories.enumerated()
            .map { (offset: $0.offset, story: $0.element) }
            .filter { $0.story.publishDate <= today }
        let sorted = indexed.sorted { a, b in
            if a.story.publishDate != b.story.publishDate { return a.story.publishDate > b.story.publishDate }
            return a.offset < b.offset
        }
        return sorted.map(\.story)
    }

    private static func comesFirst(_ a: FeedStory, _ b: FeedStory) -> Bool {
        if a.publishDate != b.publishDate { return a.publishDate > b.publishDate }
        return a.id.uuidString < b.id.uuidString
    }

    /// `yyyy-MM-dd` for `date` in the reader's own calendar day.
    static func day(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
