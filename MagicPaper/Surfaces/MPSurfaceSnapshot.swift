import Foundation

/// iOS yüzeylerinin (widget, kilit ekranı) okuduğu tek veri (FAZ 19).
///
/// Uygulama yazar, widget uzantısı okur; ikisi App Group üzerinden aynı
/// küçük kaydı paylaşır. Kitaplığın, profilin ya da seri dosyalarının
/// kendisi uzantıya açılmaz: widget yalnızca ekranda göstereceği kadarını
/// görür. Çocuğun adı ayrı bir alan olarak tutulmaz; masal başlığında
/// geçiyorsa yalnızca ana ekran widget'ında görünür, kilit ekranında hiç.
///
/// Kural ("bu akşam hangi masal?") burada değil, `MPTonight`'ta: widget saat
/// ilerledikçe aynı kaydı farklı anlarda yeniden çözer.
struct MPSurfaceSnapshot: Codable, Equatable, Sendable {
    static let currentVersion = 1

    var version: Int = Self.currentVersion
    /// Uygulamada seçili bir çocuk var mı. Yoksa widget'lar boş durumunu çizer.
    var hasChild: Bool
    /// Yatma saati (Ebeveyn > Ayarlar), açıksa.
    var bedtime: MPTonight.Bedtime?
    /// Çocuğun yarım bıraktığı masal (`MPContinueReading`).
    var resume: MPTonight.Resume?
    /// Günün masalı (FAZ 15).
    var daily: MPTonight.Daily?
    /// Okunan günler, `yyyy-MM-dd`, son iki hafta (`MPStreak`).
    var readDays: [String]
    /// Çocuğun açık serisi (FAZ 13).
    var series: Series?

    struct Series: Codable, Equatable, Sendable {
        /// Serinin ilk masalının adı.
        let title: String
        /// Sıradaki bölüm (2-5).
        let episode: Int
        /// Bölüm açıldı, kitaplıkta bekliyor.
        let isReady: Bool
        /// Bölüm henüz açılmadıysa açılacağı an: bir önceki bölümün okunduğu
        /// günün ertesi. Önceki bölüm okunmadıysa nil.
        let opensAt: Date?
        /// Okunan ve toplam bölüm, ilk masal dahil.
        let read: Int
        let total: Int

        /// `date` anında bölüm hazır mı: açılma günü geldiyse uygulama onu
        /// ilk açılışta kitaplığa koyar, widget şimdiden "hazır" der.
        func isReady(at date: Date) -> Bool {
            isReady || (opensAt.map { date >= $0 } ?? false)
        }
    }

    static let empty = MPSurfaceSnapshot(hasChild: false, bedtime: nil, resume: nil, daily: nil,
                                         readDays: [], series: nil)

    /// O anki "bu akşamın masalı".
    func tonight(at date: Date, calendar: Calendar = .current) -> MPTonight {
        MPTonight.resolve(.init(bedtime: bedtime, resume: resume,
                                readToday: MPReadingWeek.contains(readDays, date, calendar: calendar),
                                daily: daily),
                          now: date, calendar: calendar)
    }

    /// Pazartesi'den Pazar'a, `date`'in haftasında okunan günler.
    func week(at date: Date, calendar: Calendar = .current) -> [Bool] {
        MPReadingWeek.days(readDays, weekOf: date, calendar: calendar)
    }
}

// MARK: - Depo

/// Anlık görüntünün App Group'taki yeri.
///
/// Uygulama ve uzantı aynı `UserDefaults` takımını okur. Grup hesabı
/// imzalanmamış bir derlemede yoksa (test, imzasız simülatör) yazma sessizce
/// standart depoya düşmez: uzantı onu göremez, uygulamanın kendi verisiyle
/// de karışmasın.
struct MPSurfaceStore: Sendable {
    static let appGroup = "group.com.batu.magicpaper.v1"
    static let key = "mp_surfaceSnapshot"

    /// Widget türleri; uygulama zaman çizelgelerini bunlarla yeniler.
    enum Kind {
        static let tonight = "MPTonightWidget"
        static let week = "MPWeekWidget"
        static let series = "MPSeriesWidget"
        static let lock = "MPLockWidget"
    }

    private let suite: String?

    init(suite: String? = MPSurfaceStore.appGroup) {
        self.suite = suite
    }

    private var defaults: UserDefaults? { suite.flatMap(UserDefaults.init(suiteName:)) }

    func load() -> MPSurfaceSnapshot {
        guard let data = defaults?.data(forKey: Self.key),
              let snapshot = try? JSONDecoder().decode(MPSurfaceSnapshot.self, from: data),
              snapshot.version == MPSurfaceSnapshot.currentVersion
        else { return .empty }
        return snapshot
    }

    /// Kayıt değiştiyse yazar ve `true` döner: widget zaman çizelgeleri
    /// yalnızca o zaman yenilenir (iOS yenileme bütçesi sınırlı).
    @discardableResult
    func save(_ snapshot: MPSurfaceSnapshot) -> Bool {
        guard let defaults, load() != snapshot,
              let data = try? JSONEncoder().encode(snapshot) else { return false }
        defaults.set(data, forKey: Self.key)
        return true
    }

    func erase() {
        defaults?.removeObject(forKey: Self.key)
    }
}

// MARK: - Haftanın okuma günleri

/// `MPStreak`'in hafta kuralı, uzantının da okuyabileceği hâliyle: Pazartesi
/// başlangıçlı Gregoryen hafta, gün anahtarı cihazın saat diliminde
/// `yyyy-MM-dd`.
enum MPReadingWeek {
    /// Widget'a taşınan geçmiş: bu hafta ve bir önceki.
    static let retainedDays = 14

    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func contains(_ days: [String], _ date: Date, calendar: Calendar = .current) -> Bool {
        days.contains(dayKey(date, calendar: calendar))
    }

    static func weekCalendar(_ calendar: Calendar) -> Calendar {
        var week = Calendar(identifier: .gregorian)
        week.firstWeekday = 2
        week.timeZone = calendar.timeZone
        return week
    }

    static func days(_ days: [String], weekOf date: Date, calendar: Calendar = .current) -> [Bool] {
        let week = weekCalendar(calendar)
        let read = Set(days)
        guard let start = week.dateInterval(of: .weekOfYear, for: week.startOfDay(for: date))?.start else {
            return Array(repeating: false, count: 7)
        }
        return (0..<7).map { offset in
            guard let day = week.date(byAdding: .day, value: offset, to: start) else { return false }
            // Anahtar `MPStreak` gibi cihazın takvimiyle yazılır.
            return read.contains(dayKey(day, calendar: calendar))
        }
    }

    /// Son `retainedDays` günün okunanları.
    static func recent(_ days: Set<String>, now: Date, calendar: Calendar = .current) -> [String] {
        (0..<retainedDays).compactMap { back -> String? in
            guard let day = calendar.date(byAdding: .day, value: -back, to: now) else { return nil }
            let key = dayKey(day, calendar: calendar)
            return days.contains(key) ? key : nil
        }
    }
}
