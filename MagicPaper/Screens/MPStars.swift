import Foundation

/// Yıldız sayacı (karar 13 Ekim 2026): "Her sabah 1 yıldız gelir. Her masal 1 yıldız."
///
/// Bu turda yıldız yalnızca kazanılır ve gösterilir; harcama, üst sınır ve
/// abonelik bağı sonraki planlarda. Bu yüzden ayrı bir depo yok, sayı
/// türetilir:
/// - sabahlar profilin oluşturulduğu günden bugüne (bugün dahil); uygulamayı
///   açmak yıldız kazandırmaz,
/// - masallar rozet defterindeki farklı bitmiş masallar (`MPBadgeLedger.finished`,
///   hesapla eşitleniyor, silinen masalın yıldızı gitmez).
enum MPStars {

    static func count(createdAt: Date, finished: Int, now: Date = Date(),
                      calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: createdAt)
        let today = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return max(days, 0) + 1 + finished
    }

    static func count(createdAt: Date, ledger: MPBadgeLedger, now: Date = Date(),
                      calendar: Calendar = .current) -> Int {
        count(createdAt: createdAt, finished: ledger.finished.count, now: now, calendar: calendar)
    }

    /// Etkin çocuğun yıldızları. Görünüm gövdesinden çağrılır, bu yüzden
    /// diske yazmaz: defter henüz kurulmadıysa kitaplıktaki bitmiş masallar sayılır
    /// (`MPBadgeStore.ledger` ilk masal sonunda defteri aynı kuralla kurar).
    @MainActor
    static func count(for profile: UserProfile, stories: [Story], now: Date = Date()) -> Int {
        let finished = MPBadgeStore().storedLedger(for: profile.id)?.finished.count
            ?? stories.filter { $0.isFinished && $0.belongs(to: profile) }.count
        return count(createdAt: profile.createdAt, finished: finished, now: now)
    }
}
