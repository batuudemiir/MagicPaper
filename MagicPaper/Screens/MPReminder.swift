import Foundation
import UserNotifications

/// Masal saati hatırlatması.
///
/// Ayarlar'daki anahtar "Her akşam 20.30" yazıyordu, varsayılan olarak açıktı
/// ve **hiçbir bildirim planlamıyordu**: `settings.reminder` hiçbir yerde
/// okunmuyordu. Bunun yanında uygulama, açılışta — daha tek bir masal bile
/// yokken — bildirim izni istiyordu. İkisi birlikte mümkün olan en kötü
/// birleşim: izni hiçbir şey vaat etmeden en kötü anda istemek, sonra izin
/// verilse bile hiçbir şey göndermemek.
///
/// İzin artık ebeveyn anahtarı açtığı anda isteniyor — yani istenen şeyin ne
/// işe yarayacağı ekranda yazarken.
///
/// Faz 14 (akıllı hatırlatma): her gün tekrarlayan tek bildirim yerine önümüzdeki
/// yedi akşam tek tek planlanır (`MPReminderPlan`). Masal okunan akşamın
/// bildirimi gitmez; bu akşamınki o akşamın masalını söyler. Yeni kurulumda
/// varsayılan kapalı. Plan her açılışta ve her okumadan sonra yenilenir.
@MainActor
enum MPReminder {

    /// Eski tek kimlik (her gün tekrarlayan bildirim). Yeni planda her akşamın
    /// kendi kimliği var (`identifier(for:)`); eskisi her planlamada silinir.
    static let identifier = "mp_story_reminder"

    enum Result: Equatable {
        case scheduled
        /// Ebeveyn iOS'a "hayır" dedi; anahtarın açık kalmaya hakkı yok.
        case denied
    }

    /// Hatırlatmayı kurar. Gerekirse izin ister.
    static func enable(hour: Int, minute: Int, childName: String?) async -> Result {
        guard await ensureAuthorised() else { return .denied }
        schedule(hour: hour, minute: minute, childName: childName)
        return .scheduled
    }

    /// Eşzamanlı siler: plan her zaman önümüzdeki günlerde olduğu için o
    /// günlerin kimlikleri bilinir. (Bekleyenleri sorup sonra silmek, hemen
    /// ardından eklenen yeni planı da silebilirdi.)
    static func disable(now: Date = Date(), calendar: Calendar = .current) {
        let start = calendar.startOfDay(for: now)
        let days = (-1...14).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier] + days.map { identifier(for: $0, calendar: calendar) })
    }

    /// Bu akşam masal okundu: bu akşamın bildirimi gitmez.
    static func readTonight(now: Date = Date()) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier(for: now)])
    }

    /// Bir akşamın bildirim kimliği: `mp_story_reminder_2026-11-11`.
    static func identifier(for date: Date, calendar: Calendar = .current) -> String {
        let d = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%@_%04d-%02d-%02d", identifier, d.year ?? 0, d.month ?? 0, d.day ?? 0)
    }

    /// Açılışta çağrılır.
    ///
    /// Bir bildirim planı iOS'ta kalıcıdır ama ebeveyn izni Sistem
    /// Ayarları'ndan geri alabilir. Uygulama açıldığında anahtarın hâlâ doğru
    /// olduğunu söylemek gerekiyor: izin gittiyse anahtar da kapanır.
    /// Dönen değer "anahtar açık kalabilir mi" sorusunun cevabıdır.
    static func resync(enabled: Bool, hour: Int, minute: Int, childName: String?) async -> Bool {
        guard enabled else {
            disable()
            return false
        }
        guard await isAuthorised() else {
            disable()
            return false
        }
        schedule(hour: hour, minute: minute, childName: childName)
        return true
    }

    /// İzin durumu — istemeden, yalnızca sorarak.
    static func isAuthorised() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    // MARK: -

    private static func ensureAuthorised() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])) ?? false
        default:
            // .denied — burada tekrar istemek bir şey yapmaz, iOS sormaz bile.
            return false
        }
    }

    private static func schedule(hour: Int, minute: Int, childName: String?) {
        disable()
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let now = Date()
        let evenings = MPReminderPlan.evenings(from: now, hour: hour, minute: minute,
                                               readToday: MPStreak.shared.readToday, calendar: calendar)
        let tonightTitle = tonightStoryTitle()
        for evening in evenings {
            let content = UNMutableNotificationContent()
            content.title = "Masal saati"
            let isTonight = calendar.isDate(evening, inSameDayAs: now)
            content.body = body(childName: childName, tonightTitle: isTonight ? tonightTitle : nil)
            content.sound = .default
            let when = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: evening)
            center.add(UNNotificationRequest(
                identifier: identifier(for: evening, calendar: calendar),
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: false)
            ))
        }
    }

    /// Bu akşamın masalı: yarım kalan masal, yoksa günün masalı.
    private static func tonightStoryTitle() -> String? {
        let source = MPTonightSource.current()
        return source.resumeStory?.title ?? source.daily?.title
    }

    /// Bildirimi okuyan ebeveyn; masalı dinleyen çocuk.
    ///
    /// Metin çocuğun adını taşır ama çocuğa seslenmez: kilit ekranındaki
    /// bildirimi açan el ebeveynin eli.
    static func body(childName: String?, tonightTitle: String? = nil) -> String {
        let name = childName?.trimmingCharacters(in: .whitespaces) ?? ""
        if let title = tonightTitle?.trimmingCharacters(in: .whitespaces), !title.isEmpty {
            return name.isEmpty ? "Bu akşamın masalı: \(title)." : "\(name) için bu akşamın masalı: \(title)."
        }
        guard !name.isEmpty else { return "Bu akşamın masalı için iyi bir zaman." }
        return "\(name) için bu akşamın masalı."
    }

    /// Ekranda gösterilecek saat — "20.30".
    static func clockLabel(hour: Int, minute: Int) -> String {
        MPTonight.clockLabel(hour: hour, minute: minute)
    }
}

/// Akıllı hatırlatmanın saf planı (Faz 14): hangi akşamlar.
enum MPReminderPlan {
    /// Önümüzdeki `count` akşam. Saati geçmiş ya da masalı okunmuş bu akşam
    /// atlanır; yerine bir sonraki gün eklenir, hep `count` akşam kalır.
    static func evenings(from now: Date, hour: Int, minute: Int, readToday: Bool,
                         count: Int = 7, calendar: Calendar = .current) -> [Date] {
        var result: [Date] = []
        var day = calendar.startOfDay(for: now)
        while result.count < count {
            if let evening = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) {
                let isToday = calendar.isDate(day, inSameDayAs: now)
                if evening > now && !(isToday && readToday) { result.append(evening) }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }
}
