import AVFoundation

/// Uygulamanın kısa sesleri (Faz 4). Tek çağrı yüzeyi, `MPHaptics` gibi.
///
/// Ses az ve anlamlı: masal sonu, kazanılan öğe, ciltlenen masal, sayfa ve Ragi'nin
/// selamı. Dosyalar `Tools/make_ragi_sounds.py` ile üretilir.
/// - Sessize alma anahtarına uyar (`ambient`) ve başka uygulamanın sesini kesmez.
/// - Uyku vaktinde ve masal okunurken çalmaz.
/// - Kullanıcı `MPSettingsStore.sounds` ile kapatır.
@MainActor
enum MPSound {

    enum Cue: String, CaseIterable {
        case ending = "mp_ending"
        case earned = "mp_earned"
        case ready = "mp_ready"
        case page = "mp_page"
        case ragi = "mp_ragi"
    }

    private static var players: [Cue: AVAudioPlayer] = [:]

    /// Saf karar: test edilir.
    nonisolated static func shouldPlay(enabled: Bool, bedtime: Bool, speaking: Bool) -> Bool {
        enabled && !bedtime && !speaking
    }

    static func play(_ cue: Cue) {
        let settings = MPSettingsStore.shared
        guard shouldPlay(enabled: settings.sounds,
                         bedtime: MPBedtime.isBedtime(settings: settings),
                         speaking: MPSpeech.shared.isSpeaking) else { return }
        // Masal sesi `playback` oturumunu kendi kurar; burası yalnızca okuma yokken gelir.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        guard let player = player(for: cue) else { return }
        player.currentTime = 0
        player.play()
    }

    private static func player(for cue: Cue) -> AVAudioPlayer? {
        if let cached = players[cue] { return cached }
        guard let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "m4a"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        players[cue] = player
        return player
    }
}
