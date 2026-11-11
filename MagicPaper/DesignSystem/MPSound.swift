import AVFoundation

/// Uygulamanın kısa sesleri (Faz 4). Tek çağrı yüzeyi, `MPHaptics` gibi.
///
/// Ses az ve anlamlı: masal sonu, kazanılan öğe, ciltlenen masal, sayfa ve Ragi'nin
/// selamı. Dosyalar `Tools/make_ragi_sounds.py` ile üretilir.
/// - Sessize alma anahtarına uyar (`ambient`) ve başka uygulamanın sesini kesmez.
/// - Uyku vaktinde ve masal okunurken çalmaz.
/// - Kullanıcı `MPSettingsStore.sounds` ile kapatır.
///
/// Perde-anlam haritası (Faz 13, sabit; `docs/RAGI.md`): bütün notalar tek
/// dizide (Sol majör pentatonik, G5-G6). Yukarı giden nota "tamamlandı" ya da
/// "kazanıldı" demek; aşağı inen nota hiç yok, çünkü hiçbir şey kaybedilmez.
/// Ragi'nin sesi notasız bir cıvıltı (620-1120 Hz), kâğıt notasız bir hışırtı.
/// Yeni bir ses bu haritaya uymuyorsa eklenmez.
///
/// Konum: hafif stereo. Sayfa sağdan sola çevrilir, sesi biraz solda; kazanılan
/// öğe sağ alttaki Odam sekmesine uçar, sesi biraz sağda.
@MainActor
enum MPSound {

    enum Cue: String, CaseIterable {
        case ending = "mp_ending"
        case earned = "mp_earned"
        case ready = "mp_ready"
        case page = "mp_page"
        case ragi = "mp_ragi"

        /// -1 sol, 1 sağ. Hafif tutulur: kulaklıkta bile yön değil, his.
        var pan: Float {
            switch self {
            case .page: -0.15
            case .earned: 0.2
            case .ending, .ready, .ragi: 0
            }
        }
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
        player.pan = cue.pan
        player.prepareToPlay()
        players[cue] = player
        return player
    }
}
