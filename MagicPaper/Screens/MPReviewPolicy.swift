import UIKit

/// Değerlendirme isteği (Faz 14): yalnızca ebeveyn alanında, Özet açılınca.
///
/// Kurallar: en az üç biten masal (değer görülmüş olsun), son istekten bu yana
/// 60 gün, son çökmeden bu yana bir gün. Çocuk alanında asla; okurken asla.
/// Sistem zaten yılda üç kezle sınırlar; bu sınır bizim sakin olma kararımız.
enum MPReviewPolicy {
    static let minimumFinished = 3
    static let spacingDays = 60
    static let crashQuietDays = 1

    private static let lastAskedKey = "mp_review_lastAsked"
    private static let lastCrashKey = "mp_review_lastCrash"
    private static let runningKey = "mp_review_sessionRunning"

    /// Saf karar: test edilir.
    static func shouldAsk(finished: Int, lastAsked: Date?, lastCrash: Date?, now: Date,
                          calendar: Calendar = .current) -> Bool {
        guard finished >= minimumFinished else { return false }
        if let lastAsked, let days = calendar.dateComponents([.day], from: lastAsked, to: now).day,
           days < spacingDays { return false }
        if let lastCrash, let days = calendar.dateComponents([.day], from: lastCrash, to: now).day,
           days < crashQuietDays { return false }
        return true
    }

    @MainActor
    static func shouldAskNow(finished: Int, defaults: UserDefaults = .standard, now: Date = Date()) -> Bool {
        shouldAsk(finished: finished,
                  lastAsked: defaults.object(forKey: lastAskedKey) as? Date,
                  lastCrash: defaults.object(forKey: lastCrashKey) as? Date,
                  now: now)
    }

    @MainActor
    static func recordAsked(defaults: UserDefaults = .standard, now: Date = Date()) {
        defaults.set(now, forKey: lastAskedKey)
    }

    /// Açılışta bir kez. Önceki oturum ön plandayken bitmediyse (çökme ya da
    /// zorla kapanma) o an "son çökme" sayılır. Arka plana geçince işaret
    /// kalkar: uygulama değiştiricisinden kapatmak çökme sayılmaz.
    @MainActor
    static func markLaunch(defaults: UserDefaults = .standard, now: Date = Date()) {
        if defaults.bool(forKey: runningKey) { defaults.set(now, forKey: lastCrashKey) }
        defaults.set(true, forKey: runningKey)
        let center = NotificationCenter.default
        center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
            defaults.set(false, forKey: runningKey)
        }
        center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
            defaults.set(true, forKey: runningKey)
        }
    }
}
