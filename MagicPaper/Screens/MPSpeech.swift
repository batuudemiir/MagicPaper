import AVFoundation
import SwiftUI

/// Sesli okuma motoru.
/// Tasarım "Sesli okuma"yı hem ayar hem okuyucu kontrolü olarak tanımlıyordu
/// ama arkasında ses yoktu; bu tip gerçek seslendirmeyi sağlar.
@MainActor
final class MPSpeech: NSObject, ObservableObject {
    static let shared = MPSpeech()

    @Published private(set) var isSpeaking = false
    @Published private(set) var isPaused = false

    private let synthesizer = AVSpeechSynthesizer()

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

    func speak(_ text: String, language: String = "tr-TR") {
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

        synthesizer.speak(utterance)
        isSpeaking = true
        isPaused = false
    }

    func pause() {
        guard synthesizer.isSpeaking, !synthesizer.isPaused else { return }
        synthesizer.pauseSpeaking(at: .word)
        isPaused = true
    }

    func resume() {
        guard synthesizer.isPaused else { return }
        synthesizer.continueSpeaking()
        isPaused = false
    }

    func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        isPaused = false
        deactivateSession()
    }

    /// Okuyucudaki tek butonun davranışı: çalıyorsa duraklat, duraklamışsa
    /// devam et, duruyorsa baştan oku.
    func toggle(_ text: String, language: String = "tr-TR") {
        if isSpeaking && !isPaused {
            pause()
        } else if isPaused {
            resume()
        } else {
            speak(text, language: language)
        }
    }
}

extension MPSpeech: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
            self.deactivateSession()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
        }
    }
}
