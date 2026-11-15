import Foundation

/// Yıldız puanı (karar 13 Ekim 2026; puan ve sabah kuralı 15 Kasım 2026,
/// `docs/ROZET_PLANI.md` 5b).
///
/// Puan, ömür boyu kazanılan bütün yıldızlardır ve hiç düşmez: harcama yalnızca
/// "cepteki yıldız"dan gider (`score - spent`). Ayrı bir depo yok, puan türetilir:
/// - bitirilen her farklı masal 1 yıldız (`MPBadgeLedger.finished`, hesapla
///   eşitleniyor, silinen masalın yıldızı gitmez; tekrar okuma yıldız vermez),
/// - sabah yıldızı: kural geçişine (`morningRuleSince`) kadar her sabah
///   kendiliğinden geldi, bu sabahlar korunur; geçişten sonra yalnızca masal
///   bitirilen günlerin sabahı ("okuma sabahı") gelir. Uygulamayı açmak
///   yıldız kazandırmaz.
enum MPStars {

    /// Cihazın sabah kuralına geçtiği an: bu sürümün ilk açılışı.
    static let ruleSinceKey = "mp_morningRuleSince"

    /// Geçiş anı; yoksa şimdi olarak bir kez yazılır.
    static func ruleSince(in defaults: UserDefaults = .standard, now: Date = Date()) -> Date {
        if let stored = defaults.object(forKey: ruleSinceKey) as? Date { return stored }
        defaults.set(now, forKey: ruleSinceKey)
        return now
    }

    /// Puan. `ruleSince` profilden önceyse profilin hiç kendiliğinden sabahı
    /// olmaz; değilse açılış gününden geçiş gününe (dahil) her sabah sayılır,
    /// sonrasında yalnızca okuma günleri.
    static func score(createdAt: Date, ruleSince: Date, readingDays: Set<String>, finished: Int,
                      now: Date = Date(), calendar: Calendar = .current) -> Int {
        let created = calendar.startOfDay(for: createdAt)
        let today = calendar.startOfDay(for: now)
        let lastPassive = min(calendar.startOfDay(for: ruleSince), today)
        var mornings = 0
        var firstReadingKey = MPBadgeDay.key(for: created, calendar: calendar)
        if lastPassive >= created {
            mornings = (calendar.dateComponents([.day], from: created, to: lastPassive).day ?? 0) + 1
            firstReadingKey = MPBadgeDay.key(for: lastPassive, calendar: calendar) + "~"   // geçiş gününden sonrası
        } else if today < created {
            // Saat profilden önceye alınmış: açılış sabahı yine sayılır.
            mornings = 1
        }
        let todayKey = MPBadgeDay.key(for: today, calendar: calendar)
        mornings += readingDays.filter { $0 >= firstReadingKey && $0 <= todayKey }.count
        return mornings + finished
    }

    /// Defterden puan. Defter henüz kurala geçmediyse (`morningRuleSince` yok)
    /// bugüne kadarki bütün sabahlar sayılır: güncelleme günü puan düşmez.
    static func score(createdAt: Date, ledger: MPBadgeLedger, now: Date = Date(),
                      calendar: Calendar = .current) -> Int {
        score(createdAt: createdAt, ruleSince: ledger.morningRuleSince ?? now,
              readingDays: ledger.readingDays, finished: ledger.finished.count, now: now, calendar: calendar)
    }

    /// Etkin çocuğun puanı. Görünüm gövdesinden çağrılır; tek yazdığı şey
    /// cihazın geçiş anıdır (bir kez). Defter henüz kurulmadıysa kitaplıktaki
    /// bitmiş masallar sayılır (`MPBadgeStore.ledger` defteri aynı kuralla kurar).
    @MainActor
    static func score(for profile: UserProfile, stories: [Story], now: Date = Date(),
                      defaults: UserDefaults = .standard) -> Int {
        if let ledger = MPBadgeStore(defaults: defaults).storedLedger(for: profile.id) {
            return score(createdAt: profile.createdAt,
                         ruleSince: ledger.morningRuleSince ?? ruleSince(in: defaults, now: now),
                         readingDays: ledger.readingDays, finished: ledger.finished.count, now: now)
        }
        let finished = stories.filter { $0.isFinished && $0.belongs(to: profile) }.count
        return score(createdAt: profile.createdAt, ruleSince: ruleSince(in: defaults, now: now),
                     readingDays: [], finished: finished, now: now)
    }
}
