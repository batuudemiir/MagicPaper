import Foundation

/// "Okuma yolculuğum" ekranının kararları (23 Kasım 2026, İrem; referans:
/// alışkanlık uygulamasının tracker ekranı, `design-preview/app/yolculuk.js`).
///
/// Kurallar (AGENTS.md ilke 7): seri sakin dille ("birlikte okudunuz"); okunmayan
/// gün başarısızlık değil boş daire; "zayıf", "az kaldı", geri sayım ya da
/// karşılaştırma yok. Yıldız katı asla düşmez; bir sonraki kata ilerleme
/// gösterilmez. Saf: servis okumaz, testte gün ve saat verilir.
struct ReadingJourney: Equatable {
    struct Day: Equatable {
        /// "Pzt"
        let label: String
        /// Ayın günü, gelecek günlerde gösterilir.
        let dayOfMonth: Int
        let read: Bool
        let isToday: Bool
        let isFuture: Bool
        let minutes: Int
    }

    let days: [Day]
    let streak: Int
    let stars: Int
    let level: MPStarLevel?
    /// Bu haftanın kelimelerinden en çok üçü; `wordCount` haftanın tamamı.
    let words: [String]
    let wordCount: Int
    let lastBadge: MPBadge?

    static let dayLabels = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]

    var readDaysThisWeek: Int { days.filter(\.read).count }
    var minutesThisWeek: Int { days.reduce(0) { $0 + $1.minutes } }

    /// Kartın büyük satırı.
    var headline: String { streak > 0 ? "\(streak) gün üst üste" : "Okuma yolculuğun" }

    /// Altındaki sakin cümle: seri varsa birlikte okumayı söyler, yoksa davet eder.
    var message: String {
        streak > 0 ? "Birlikte okudunuz. Okuma yolculuğunuz devam ediyor."
                   : "Bugün bir masalla yolculuğa başlayalım."
    }

    /// Haftanın özeti: okunan gün sayısı, yoksa davet.
    var weekSummary: String {
        readDaysThisWeek > 0 ? "Bu hafta \(readDaysThisWeek) gün birlikte okudunuz"
                             : "Bu hafta ilk masalı birlikte okuyalım"
    }

    static func make(week: [(date: Date, read: Bool)], minutes: [Int], streak: Int, stars: Int,
                     words: [String], wordCount: Int, lastBadge: MPBadge?,
                     now: Date, calendar: Calendar = .current) -> ReadingJourney {
        let today = calendar.startOfDay(for: now)
        let days = week.enumerated().map { index, entry in
            let day = calendar.startOfDay(for: entry.date)
            return Day(label: dayLabels.indices.contains(index) ? dayLabels[index] : "",
                       dayOfMonth: calendar.component(.day, from: entry.date),
                       read: entry.read,
                       isToday: day == today,
                       isFuture: day > today,
                       minutes: minutes.indices.contains(index) ? max(0, minutes[index]) : 0)
        }
        return ReadingJourney(days: days, streak: streak, stars: stars,
                              level: MPStarLevel.current(score: stars),
                              words: Array(words.prefix(3)), wordCount: wordCount, lastBadge: lastBadge)
    }
}

extension ReadingJourney {
    /// Açık çocuğun canlı verisiyle: okuma günleri ve dakikalar (`MPStreak`),
    /// yıldız (`MPStars`), bu haftanın kelimeleri (`MPVocabulary`), en son
    /// kazanılan rozet (rozet defteri).
    @MainActor
    static func live(for profile: UserProfile, now: Date = Date()) -> ReadingJourney {
        let streak = MPStreak.shared
        let stories = StoryGenerationManager.shared.stories
        let mine = stories.filter { $0.belongs(to: profile) }
        let words = MPVocabulary.collectedThisWeek(MPVocabulary.collectedWords(in: mine), now: now)
        let ledger = MPBadgeStore().ledger(for: profile, stories: stories)
        let lastBadge = ledger.earned.max { $0.value < $1.value }.flatMap { MPBadgeCatalog.badge($0.key) }
        return make(week: streak.daysThisWeek, minutes: streak.minutesThisWeekByDay,
                    streak: streak.currentStreak, stars: MPStars.score(for: profile, stories: stories),
                    words: words.map(\.word.term), wordCount: words.count, lastBadge: lastBadge, now: now)
    }
}
