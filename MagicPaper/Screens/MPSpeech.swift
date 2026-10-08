import AVFoundation
import SwiftUI

/// Sesli okuma motoru.
/// Tasarım "Sesli okuma"yı hem ayar hem okuyucu kontrolü olarak tanımlıyordu
/// ama arkasında ses yoktu; bu tip gerçek seslendirmeyi sağlar.
///
/// FAZ 18: sayfanın ailenin sesiyle kaydı varsa (`recording`) o çalınır,
/// yoksa masal anlatıcısı okur. Okuyucu ve Uyku modu farkı bilmez: aynı
/// `isSpeaking`/`isPaused`/`onFinished` sözleşmesi.
@MainActor
final class MPSpeech: NSObject, ObservableObject {
    static let shared = MPSpeech()

    @Published private(set) var isSpeaking = false
    @Published private(set) var isPaused = false

    private let synthesizer = AVSpeechSynthesizer()
    /// Ailenin sesi çalarken.
    private var player: AVAudioPlayer?
    /// Şu an okunan metin. Bir okuma durdurulup yenisi başladığında eskisinin
    /// "iptal" ya da "bitti" haberi geç gelir; yeni okumanın durumunu ezmesin,
    /// `onFinished`'i yanlış sayfa için çağırmasın diye karşılaştırılır.
    private var current: ObjectIdentifier?

    /// Bir metin sonuna kadar okununca (durdurulunca değil). Okuyucu sesli
    /// okurken sonraki sayfaya geçer, Uyku modu sonraki sayfayı okur.
    var onFinished: (() -> Void)?

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Sessize alma anahtarı açıkken de masal duyulsun diye oturum `playback`.
    private func activateSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio,
                                                            options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Ses oturumu açılamadı: \(error.localizedDescription)")
        }
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Cihazdaki en iyi Türkçe ses (FAZ 17): yüklüyse premium ya da
    /// geliştirilmiş ses, yoksa sistem varsayılanı.
    private func voice(for language: String) -> AVSpeechSynthesisVoice? {
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == language }
        if let best = candidates.max(by: { $0.quality.rawValue < $1.quality.rawValue }) { return best }
        return AVSpeechSynthesisVoice(language: language) ?? AVSpeechSynthesisVoice(language: "tr-TR")
    }

    func speak(_ text: String, language: String = "tr-TR", recording: URL? = nil) {
        if let recording, play(recording) { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        stop()
        activateSession()

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = voice(for: language)
        // Çocuğa okurken varsayılan hız fazla hızlı geliyor.
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * MPSettingsStore.shared.speechRate.multiplier
        utterance.pitchMultiplier = 1.05
        utterance.postUtteranceDelay = 0.2

        current = ObjectIdentifier(utterance)
        synthesizer.speak(utterance)
        isSpeaking = true
        isPaused = false
    }

    /// Ailenin sesiyle kaydedilmiş sayfa. Dosya açılmazsa anlatıcıya kalır.
    private func play(_ file: URL) -> Bool {
        stop()
        activateSession()
        guard let player = try? AVAudioPlayer(contentsOf: file) else { return false }
        player.delegate = self
        guard player.play() else { return false }
        self.player = player
        current = ObjectIdentifier(player)
        isSpeaking = true
        isPaused = false
        return true
    }

    func pause() {
        if let player, player.isPlaying {
            player.pause()
            isPaused = true
            return
        }
        guard synthesizer.isSpeaking, !synthesizer.isPaused else { return }
        synthesizer.pauseSpeaking(at: .word)
        isPaused = true
    }

    func resume() {
        if let player, isPaused {
            player.play()
            isPaused = false
            return
        }
        guard synthesizer.isPaused else { return }
        synthesizer.continueSpeaking()
        isPaused = false
    }

    func stop() {
        player?.stop()
        player = nil
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        current = nil
        isSpeaking = false
        isPaused = false
        deactivateSession()
    }

    /// Bir delege haberi şu anki okumaya mı ait (geç gelen haber değil mi).
    func isCurrent(_ utterance: ObjectIdentifier) -> Bool { current == utterance }

    /// Okuyucudaki tek butonun davranışı: çalıyorsa duraklat, duraklamışsa
    /// devam et, duruyorsa baştan oku.
    func toggle(_ text: String, language: String = "tr-TR", recording: URL? = nil) {
        if isSpeaking && !isPaused {
            pause()
        } else if isPaused {
            resume()
        } else {
            speak(text, language: language, recording: recording)
        }
    }
}

extension MPSpeech: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let finished = ObjectIdentifier(player)
        Task { @MainActor in
            guard self.isCurrent(finished) else { return }
            self.current = nil
            self.player = nil
            self.isSpeaking = false
            self.isPaused = false
            self.deactivateSession()
            self.onFinished?()
        }
    }
}

extension MPSpeech: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        let finished = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard self.isCurrent(finished) else { return }
            self.current = nil
            self.isSpeaking = false
            self.isPaused = false
            self.deactivateSession()
            self.onFinished?()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didCancel utterance: AVSpeechUtterance) {
        let cancelled = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard self.isCurrent(cancelled) else { return }
            self.current = nil
            self.isSpeaking = false
            self.isPaused = false
        }
    }
}
