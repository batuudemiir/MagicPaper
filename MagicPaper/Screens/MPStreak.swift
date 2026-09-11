import SwiftUI

/// Okuma serisi. Tasarımdaki "seri kartı" ve Günlük ekranındaki 7 günlük şerit
/// bu kayıttan beslenir. Prototipteki sabit değerlerin yerine gerçek okuma
/// günleri tutulur — okuyucu açıldığı gün işaretlenir.
@MainActor
final class MPStreak: ObservableObject {
    static let shared = MPStreak()

    private let key = "mp_readDays"
    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    @Published private(set) var readDays: Set<String>

    private init() {
        readDays = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    func markReadToday() {
        let today = Self.fmt.string(from: Date())
        guard !readDays.contains(today) else { return }
        readDays.insert(today)
        UserDefaults.standard.set(Array(readDays), forKey: key)
    }

    var readToday: Bool {
        readDays.contains(Self.fmt.string(from: Date()))
    }

    /// Kesintisiz gün sayısı. Bugün okunmadıysa dünden geriye sayar.
    var currentStreak: Int {
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        if !readDays.contains(Self.fmt.string(from: day)) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
            guard readDays.contains(Self.fmt.string(from: day)) else { return 0 }
        }
        var count = 0
        while readDays.contains(Self.fmt.string(from: day)) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    /// Pazartesi→Pazar, bu haftanın okunmuş günleri.
    var thisWeek: [Bool] {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Pazartesi
        let today = cal.startOfDay(for: Date())
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: today)?.start else {
            return Array(repeating: false, count: 7)
        }
        return (0..<7).map { offset in
            guard let d = cal.date(byAdding: .day, value: offset, to: weekStart) else { return false }
            return readDays.contains(Self.fmt.string(from: d))
        }
    }

    // MARK: - Okuma süresi
    //
    // Ebeveyn panelindeki "Bu hafta okuma" değeri eskiden okunan gün sayısından
    // uydurulmuştu. Artık okuyucu açık kaldığı süre gün gün biriktirilir.

    private let secondsKey = "mp_readSeconds"

    /// Gün ("yyyy-MM-dd") → o gün okunan saniye.
    private var readSeconds: [String: Double] {
        get { UserDefaults.standard.dictionary(forKey: secondsKey) as? [String: Double] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: secondsKey) }
    }

    /// Okuyucu kapanırken ya da arka plana giderken çağrılır.
    func addReadingTime(_ seconds: Double) {
        // Tek oturumda 2 saatten fazlası kayıt hatası sayılır (ekran açık unutulmuş).
        let clamped = min(max(seconds, 0), 2 * 60 * 60)
        guard clamped >= 1 else { return }
        let today = Self.fmt.string(from: Date())
        var map = readSeconds
        map[today, default: 0] += clamped
        readSeconds = map
        objectWillChange.send()
    }

    /// Bu hafta (Pzt→Paz) okunan toplam dakika.
    var minutesThisWeek: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let today = cal.startOfDay(for: Date())
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: today)?.start else { return 0 }
        let map = readSeconds
        let total = (0..<7).reduce(0.0) { sum, offset in
            guard let d = cal.date(byAdding: .day, value: offset, to: weekStart) else { return sum }
            return sum + (map[Self.fmt.string(from: d)] ?? 0)
        }
        return Int((total / 60).rounded())
    }

    static let weekdayLabels = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
}
