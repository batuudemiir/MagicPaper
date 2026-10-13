import ActivityKit
import AppIntents
import Foundation

/// 26 · Uyku modunun Live Activity'si (FAZ 19, karar 13 Ekim 2026).
///
/// Uyku modu açıkken kilit ekranında ve Dynamic Island'da: ay, "Uyku modu",
/// kalan süre ve Durdur. Masalın adı yazmaz: kilit ekranı herkese açık ve
/// başlıkta çoğu zaman çocuğun adı geçiyor.
struct MPSleepActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Okuma sürerken uyku modunun kapanacağı an.
        var endsAt: Date
        /// Duraklatıldıysa kalan süre (saniye); sayaç durur.
        var pausedRemaining: TimeInterval?
        /// Masal bitti, ekran kararıyor.
        var finished: Bool = false

        var isPaused: Bool { pausedRemaining != nil }
    }
}

/// Live Activity'deki "Durdur": uyku modunu kapatır.
///
/// `LiveActivityIntent` uygulamanın sürecinde çalışır; uzantıda yalnızca
/// düğmeyi çizmek için derlenir. Uygulama açılışta `MPSleepRemote.stop`'u
/// kurar.
struct StopSleepModeIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Uyku modunu kapat"
    static let isDiscoverable = false

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        MPSleepRemote.stop?()
        return .result()
    }
}

/// Live Activity'den gelen komutun uygulamadaki karşılığı.
enum MPSleepRemote {
    @MainActor static var stop: (() -> Void)?
}
