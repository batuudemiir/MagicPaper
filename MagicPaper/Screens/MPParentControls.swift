import Foundation

// MARK: - Günlük okuma bütçesi

/// "Ekran süresi limiti" anahtarının arkasındaki kural.
///
/// Anahtar Ayarlar'da bir yıl boyunca **açık** durdu ve hiçbir yerde
/// okunmuyordu: hiçbir kod `settings.screenLimit` kelimesini görmüyordu. Bir
/// ebeveyne "günde 30 dakika" yazıp hiçbir şey saymamak, kapalı bir anahtar
/// göstermekten kötüdür — kapalı anahtar yanlış bir şey vaat etmez.
///
/// Kural burada, ekranın içinde değil, çünkü doğrulanması gereken şey bir
/// görünüm değil bir aritmetik: "bugün ne kadar okundu, ne kadar kaldı".
struct MPReadingBudget: Equatable {

    /// Ebeveyn limiti açtı mı.
    var isEnabled: Bool
    /// Günlük bütçe, dakika.
    var dailyLimitMinutes: Int
    /// Bugün, bu oturumdan **önce** okunmuş süre.
    var secondsBeforeSession: Double

    /// Seçilebilen bütçeler. "Günde 30 dakika" sabit bir metindi; bir
    /// ebeveynin 15 ya da 60 demek istemesi için hiçbir yol yoktu.
    static let choices = [15, 30, 45, 60]

    /// Bütçeden kalan süre — limit kapalıysa `nil`.
    ///
    /// `nil`, "çok büyük bir sayı" değil: ölçülecek bir şey olmadığı anlamına
    /// gelir. Limit kapalıyken `.greatestFiniteMagnitude` döndürmek, çağıran
    /// her yerin o sayıyı bir süre sanma ihtimalini açık bırakırdı.
    func remainingSeconds(sessionSeconds: Double) -> Double? {
        guard isEnabled, dailyLimitMinutes > 0 else { return nil }
        let budget = Double(dailyLimitMinutes) * 60
        let spent = max(0, secondsBeforeSession) + max(0, sessionSeconds)
        return max(0, budget - spent)
    }

    /// Bugünün payı bitti mi.
    func isExhausted(sessionSeconds: Double) -> Bool {
        guard let remaining = remainingSeconds(sessionSeconds: sessionSeconds) else { return false }
        return remaining <= 0
    }

    /// Ebeveyn paneli için: bugün okunan dakika / bütçe.
    var minutesUsedToday: Int { Int((max(0, secondsBeforeSession) / 60).rounded()) }
}

// MARK: - Onay kapısı

/// "Masalları onaylamadan gösterme" anahtarının arkasındaki kural.
///
/// Onay kuyruğu Ebeveyn panelinde vardı ve çalışıyordu — ama onaylanmamış
/// masal hiçbir yerden gizlenmiyordu. Çocuk masalı kütüphaneden açıp okuyor,
/// ebeveyn de günler sonra paneldeki kuyruktan "onaylıyordu". Kuyruk gerçek,
/// kapı hayalîydi.
enum MPStoryGate {

    /// Çocuğun görmeye hakkı olan masallar.
    ///
    /// Önce okunabilirlik: okunacak metni olmayan, takılı kalmış eski masal
    /// onay ayarından bağımsız olarak hiçbir yerde görünmez. Sonra onay kapısı:
    /// metni olan takılı masal, tamamlanmış gibi davranır (onaylanmadıkça
    /// gizlenir) — ebeveynin onay kuyruğunda da aynı masallar görünür.
    static func visible(
        _ stories: [Story],
        approvalRequired: Bool,
        isApproved: (UUID) -> Bool
    ) -> [Story] {
        let readable = stories.filter(\.isReadable)
        guard approvalRequired else { return readable }
        return readable.filter { isApproved($0.id) }
    }

    /// Okunabilir ama onay bekleyen masallar: çocuğa "onay bekliyor" denir,
    /// masal kaybolmuş gibi görünmez. Onay kapalıyken hiçbiri.
    static func pending(
        _ stories: [Story],
        approvalRequired: Bool,
        isApproved: (UUID) -> Bool
    ) -> [Story] {
        guard approvalRequired else { return [] }
        return stories.filter { $0.isReadable && !isApproved($0.id) }
    }
}

// MARK: - Uyku saati

/// "Uyku saati" anahtarının arkasındaki kural (31 · Güvenlik).
///
/// Saat geldiyse Ana sayfa uyku kartını gösterir ve Yarat yalnızca Uyku
/// öncesi modunu sunar. Gece yarısından sabah 5'e kadar da uyku saati
/// sayılır: 20.30'da başlayan gece 00.10'da bitmiş olmaz.
enum MPBedtime {
    static let morningHour = MPTonight.morningHour

    /// Kural `MPTonight`'ta: widget da aynı saati okur (FAZ 19).
    static func isBedtime(enabled: Bool, hour: Int, minute: Int, now: Date = Date(),
                          calendar: Calendar = .current) -> Bool {
        enabled && MPTonight.isBedtime(hour: hour, minute: minute, now: now, calendar: calendar)
    }

    @MainActor
    static func isBedtime(settings: MPSettingsStore, now: Date = Date()) -> Bool {
        isBedtime(enabled: settings.bedtime, hour: settings.bedtimeHour,
                  minute: settings.bedtimeMinute, now: now)
    }
}

// MARK: - Ebeveyn kapısı

/// 28 · Ebeveyn kapısı'nın kuralı: çarpma sorusu, üç yanlışta 30 saniye
/// bekleme. Çocuk tahminle geçemesin, ebeveyn yorulmasın.
struct MPGateQuiz: Equatable {
    static let maxMisses = 3
    static let lockout: TimeInterval = 30

    private(set) var a: Int
    private(set) var b: Int
    private(set) var misses = 0
    private(set) var lockedUntil: Date?

    init(a: Int = Int.random(in: 3...9), b: Int = Int.random(in: 3...9)) {
        self.a = a
        self.b = b
    }

    var question: String { "\(a) × \(b) = ?" }

    func isLocked(at now: Date = Date()) -> Bool {
        guard let lockedUntil else { return false }
        return now < lockedUntil
    }

    func secondsLeft(at now: Date = Date()) -> Int {
        guard let lockedUntil else { return 0 }
        return max(0, Int(lockedUntil.timeIntervalSince(now).rounded(.up)))
    }

    enum Result: Equatable { case correct, wrong, locked }

    /// Yanlışta yeni soru gelir; üçüncü yanlış kapıyı 30 saniye kilitler.
    mutating func answer(_ value: Int?, at now: Date = Date(),
                         next: () -> (Int, Int) = { (Int.random(in: 3...9), Int.random(in: 3...9)) }) -> Result {
        if isLocked(at: now) { return .locked }
        if lockedUntil != nil { lockedUntil = nil; misses = 0 }
        if value == a * b { return .correct }
        misses += 1
        (a, b) = next()
        if misses >= Self.maxMisses {
            lockedUntil = now.addingTimeInterval(Self.lockout)
            return .locked
        }
        return .wrong
    }
}
