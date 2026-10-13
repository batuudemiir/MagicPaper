import SwiftUI
import WidgetKit

/// 40 · Widget'lar ve 41 · Kilit ekranı (FAZ 19).
///
/// Veri yalnızca uygulamanın App Group'a yazdığı kayıttan gelir
/// (`MPSurfaceSnapshot`); uzantı kitaplığa, profile ya da ağa erişmez.
@main
struct MagicPaperWidgets: WidgetBundle {
    var body: some Widget {
        TonightWidget()
        WeekWidget()
        SeriesWidget()
        LockWidget()
        SleepLiveActivity()
    }
}

// MARK: - Zaman çizelgesi

struct SurfaceEntry: TimelineEntry {
    let date: Date
    let snapshot: MPSurfaceSnapshot
}

/// Bütün widget'ların ortak zaman çizelgesi.
///
/// Kayıt uygulama açılıp kapandıkça yenilenir; arada kuralın kendiliğinden
/// değiştiği anlar (yatma saati, sabah, gece yarısı, serinin yeni bölümünün
/// açılacağı gün) için girişler önceden açılır.
struct SurfaceProvider: TimelineProvider {
    var store = MPSurfaceStore()

    func placeholder(in context: Context) -> SurfaceEntry {
        SurfaceEntry(date: Date(), snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (SurfaceEntry) -> Void) {
        completion(SurfaceEntry(date: Date(), snapshot: context.isPreview ? .preview : store.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SurfaceEntry>) -> Void) {
        let snapshot = store.load()
        let dates = Self.entryDates(for: snapshot, from: Date())
        completion(Timeline(entries: dates.map { SurfaceEntry(date: $0, snapshot: snapshot) },
                            policy: .atEnd))
    }

    /// Şimdi, kuralın sonraki altı değişim anı ve serinin açılış anı.
    static func entryDates(for snapshot: MPSurfaceSnapshot, from now: Date,
                           calendar: Calendar = .current) -> [Date] {
        var dates = [now]
        var cursor = now
        for _ in 0..<6 {
            cursor = MPTonight.nextChange(after: cursor, bedtime: snapshot.bedtime, calendar: calendar)
            dates.append(cursor)
        }
        if let opens = snapshot.series?.opensAt, opens > now, opens < cursor { dates.append(opens) }
        return Array(Set(dates)).sorted()
    }
}

// MARK: - Önizleme verisi

extension MPSurfaceSnapshot {
    /// Widget galerisinde gösterilen örnek: gerçek bir çocuğun verisi değil.
    static var preview: MPSurfaceSnapshot {
        let today = Date()
        let week = MPReadingWeek.weekCalendar(.current)
        let start = week.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let days = (0..<3).compactMap { week.date(byAdding: .day, value: $0, to: start) }
            // Bugün okunmamış: galeri "Bu akşamın masalı"nı göstersin.
            .filter { $0 < week.startOfDay(for: today) }
            .map { MPReadingWeek.dayKey($0) }
        return MPSurfaceSnapshot(
            hasChild: true,
            bedtime: nil,
            resume: nil,
            daily: .init(title: "Kayıp Yıldız Gemisi", minutes: 6),
            readDays: days,
            series: .init(title: "Gökkuşağı köprüsü", episode: 4, isReady: true, opensAt: nil,
                          read: 3, total: 5))
    }
}
