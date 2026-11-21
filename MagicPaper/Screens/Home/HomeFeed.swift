import Foundation

/// Ana sayfanın kararları (21 Kasım 2026, `docs/ANA_SAYFA_HAZIRLIK.md` A3, A4, C1).
///
/// Saf: girdiler ve saat verilir, ekranın göstereceği her şey döner. Servis
/// okumaz, diske yazmaz; bu yüzden testte saat ve takvim istenen ana kurulur.
/// Girdileri canlı servislerden toplayan ve değişince yenileyen katman
/// `HomeFeedStore`. "Bu akşam hangi masal" kuralının kendisi `MPTonight`'ta
/// kalır (widget ve Siri de onu okur); burada yalnızca ekrana çevrilir.
struct HomeFeed: Equatable {
    /// "Günaydın," … "İyi geceler,"; okul öncesi kademede görünüm göstermez.
    var greeting: String
    /// Bu akşamın kartı.
    var tonight: TonightState
    /// Uyku saati: başlık sahnesi geceye döner.
    var isNight: Bool
    /// Yıldız puanı (`MPStars`); başlığın sağındaki satır.
    var stars: Int
    /// Üst üste okunan gün.
    var streak: Int
    /// "Devam eden seri" bölümü görünür mü.
    var hasSeriesCard: Bool

    struct Inputs: Equatable {
        var tonight: MPTonight
        /// Bugün yeni masal yazılabilir mi (`MPAppState.canWriteNewStoryToday`).
        var canWriteNewStory: Bool
        var stars: Int
        var streak: Int
        var hasSeriesCard: Bool
    }

    static func make(_ inputs: Inputs, now: Date, calendar: Calendar = .current) -> HomeFeed {
        let tonight = state(for: inputs.tonight, canWrite: inputs.canWriteNewStory)
        var isNight = false
        if case .bedtime = tonight { isNight = true }
        return HomeFeed(greeting: greeting(at: now, calendar: calendar),
                        tonight: tonight,
                        isNight: isNight,
                        stars: inputs.stars,
                        streak: inputs.streak,
                        hasSeriesCard: inputs.hasSeriesCard)
    }

    /// `MPTonight` → kartın durumu.
    static func state(for tonight: MPTonight, canWrite: Bool) -> TonightState {
        switch tonight {
        case .bedtime(let bedtime):
            return .bedtime(time: bedtime.clockLabel)
        case .resume(let resume):
            return .resume(progress: resume.progress, title: resume.title,
                           meta: "Sayfa \(resume.page) / \(resume.pageCount)")
        case .unread(let daily):
            return .unread(title: daily.title, meta: "\(daily.minutes) dakika")
        case .readToday:
            return .readToday(canWrite: canWrite)
        }
    }

    // MARK: - Selam

    /// Selamın değiştiği saatler: 05, 11, 17, 22.
    static let greetingHours = [5, 11, 17, 22]

    /// Saate göre selam: akşam açılan bir masal uygulamasına "günaydın"
    /// demek, ürünün ne için var olduğunu bilmemek olurdu.
    static func greeting(at date: Date, calendar: Calendar = .current) -> String {
        switch calendar.component(.hour, from: date) {
        case 5..<11:  return "Günaydın,"
        case 11..<17: return "İyi günler,"
        case 17..<22: return "İyi akşamlar,"
        default:      return "İyi geceler,"
        }
    }

    // MARK: - Bir sonraki değişim

    /// Sayfanın kendiliğinden değişeceği ilk an: yatma saati, sabah 05.00 ve
    /// gece yarısı (`MPTonight.nextChange`, widget da bunu kullanır), selamın
    /// değiştiği saatler ve ücretsiz masal hakkının yeniden açıldığı an.
    /// Geçmişteki ya da şimdiki an sayılmaz.
    static func nextChange(after now: Date, bedtime: MPTonight.Bedtime?, writeOpensAt: Date?,
                           calendar: Calendar = .current) -> Date {
        var marks = [MPTonight.nextChange(after: now, bedtime: bedtime, calendar: calendar)]
        let startOfDay = calendar.startOfDay(for: now)
        for dayOffset in 0...1 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfDay) else { continue }
            for hour in greetingHours {
                if let mark = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) { marks.append(mark) }
            }
        }
        if let writeOpensAt { marks.append(writeOpensAt) }
        return marks.filter { $0 > now }.min() ?? now.addingTimeInterval(60 * 60)
    }
}
