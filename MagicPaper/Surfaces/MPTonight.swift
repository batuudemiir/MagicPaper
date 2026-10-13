import Foundation

/// "Bu akşamın masalı" (SCREENS.md 11): Ana sayfa kartı, widget ve Siri
/// aynı kuralı okur (FAZ 19).
///
/// Sıra: yatma saatiyse uyku; yarım masal varsa devam; bugün okunmadıysa
/// günün masalı; okunduysa "Bugün okudun".
enum MPTonight: Equatable, Sendable {
    case bedtime(Bedtime)
    case resume(Resume)
    case unread(Daily)
    case readToday

    struct Bedtime: Codable, Equatable, Sendable {
        let hour: Int
        let minute: Int

        /// "20.30"
        var clockLabel: String { MPTonight.clockLabel(hour: hour, minute: minute) }
    }

    struct Resume: Codable, Equatable, Sendable {
        let storyID: UUID
        let title: String
        /// 1'den başlayan, okunacak sayfa.
        let page: Int
        let pageCount: Int
        let progress: Double
    }

    struct Daily: Codable, Equatable, Sendable {
        let title: String
        let minutes: Int
    }

    struct Inputs: Equatable, Sendable {
        var bedtime: Bedtime?
        var resume: Resume?
        var readToday: Bool
        var daily: Daily?
    }

    static func resolve(_ inputs: Inputs, now: Date, calendar: Calendar = .current) -> MPTonight {
        if let bedtime = inputs.bedtime,
           isBedtime(hour: bedtime.hour, minute: bedtime.minute, now: now, calendar: calendar) {
            return .bedtime(bedtime)
        }
        if let resume = inputs.resume { return .resume(resume) }
        if !inputs.readToday, let daily = inputs.daily { return .unread(daily) }
        return .readToday
    }

    // MARK: - Yatma saati

    /// Uyku saati sabah 05.00'te biter.
    static let morningHour = 5

    static func isBedtime(hour: Int, minute: Int, now: Date, calendar: Calendar = .current) -> Bool {
        let c = calendar.dateComponents([.hour, .minute], from: now)
        let current = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        return current >= hour * 60 + minute || current < morningHour * 60
    }

    /// Kuralın değişebileceği bir sonraki an: yatma saati, sabah 05.00 ya da
    /// gece yarısı (gün dönünce "bugün okundu" sıfırlanır). Widget zaman
    /// çizelgesi bu anlarda yeni bir giriş açar.
    static func nextChange(after date: Date, bedtime: Bedtime?, calendar: Calendar = .current) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        var marks: [Date] = []
        for dayOffset in 0...1 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfDay) else { continue }
            marks.append(day)
            if let morning = calendar.date(bySettingHour: morningHour, minute: 0, second: 0, of: day) {
                marks.append(morning)
            }
            if let bedtime,
               let start = calendar.date(bySettingHour: bedtime.hour, minute: bedtime.minute, second: 0, of: day) {
                marks.append(start)
            }
        }
        return marks.filter { $0 > date }.min() ?? date.addingTimeInterval(6 * 60 * 60)
    }

    /// "20.30": Türkçe saat yazımı.
    static func clockLabel(hour: Int, minute: Int) -> String {
        String(format: "%02d.%02d", hour, minute)
    }
}
