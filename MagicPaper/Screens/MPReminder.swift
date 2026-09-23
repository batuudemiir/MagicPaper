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
@MainActor
enum MPReminder {

    /// Tek bir kimlik: her planlama öncekinin yerine geçer, birikmez.
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

    static func disable() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
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
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Masal saati"
        content.body = body(childName: childName)
        content.sound = .default

        var when = DateComponents()
        when.hour = hour
        when.minute = minute

        center.add(UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        ))
    }

    /// Bildirimi okuyan ebeveyn; masalı dinleyen çocuk.
    ///
    /// Metin çocuğun adını taşır ama çocuğa seslenmez: kilit ekranındaki
    /// bildirimi açan el ebeveynin eli.
    static func body(childName: String?) -> String {
        guard let name = childName?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
            return "Bu akşamın masalı için iyi bir zaman."
        }
        return "\(name) için bu akşamın masalı."
    }

    /// Ekranda gösterilecek saat — "20.30".
    static func clockLabel(hour: Int, minute: Int) -> String {
        String(format: "%02d.%02d", hour, minute)
    }
}
