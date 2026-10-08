import AVFoundation
import Foundation
import FirebaseFirestore

/// Bir sayfanın sesini kaydeder (FAZ 18, 33 · Kendi sesin).
///
/// AAC, tek kanal, 22 kHz: insan sesi için yeter, dakikası ~300 KB.
/// Kayıt geçici dosyaya yazılır; ebeveyn "Kaydet" deyince
/// `VoiceRecordingStore` yerine taşır.
@MainActor
final class MPVoiceRecorder: NSObject, ObservableObject {
    enum State: Equatable { case idle, recording, recorded(seconds: Double), playing }

    @Published private(set) var state: State = .idle
    /// 0...1, dalga çizimi için (yalnızca kayıt sürerken).
    @Published private(set) var level: Double = 0
    @Published private(set) var elapsed: Double = 0

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var meter: Timer?
    private(set) var file: URL?

    static let settings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 22_050,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        AVEncoderBitRateKey: 48_000,
    ]

    /// Mikrofon izni: sorulmadıysa sorar.
    static func requestPermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return true
        case .denied: return false
        default: return await AVAudioApplication.requestRecordPermission()
        }
    }

    static var permissionDenied: Bool { AVAudioApplication.shared.recordPermission == .denied }

    func start() throws {
        stopPlayback()
        MPSpeech.shared.stop()
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
        try session.setActive(true)
        discard()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("mp-voice-\(UUID().uuidString).m4a")
        let recorder = try AVAudioRecorder(url: url, settings: Self.settings)
        recorder.isMeteringEnabled = true
        guard recorder.record(forDuration: VoiceRecordingStore.maxPageSeconds) else { throw AccountError.failed }
        self.recorder = recorder
        file = url
        state = .recording
        elapsed = 0
        meter = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        guard let recorder else { return }
        if !recorder.isRecording { stop(); return }
        recorder.updateMeters()
        // -50 dB sessizlik, 0 dB tavan.
        let power = Double(recorder.averagePower(forChannel: 0))
        level = max(0, min(1, (power + 50) / 50))
        elapsed = recorder.currentTime
    }

    func stop() {
        meter?.invalidate()
        meter = nil
        guard let recorder else { return }
        let seconds = recorder.currentTime
        recorder.stop()
        self.recorder = nil
        level = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        state = seconds > 0.5 ? .recorded(seconds: seconds) : .idle
        if case .idle = state { discard() }
    }

    func play() {
        guard let file, case .recorded = state else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        player = try? AVAudioPlayer(contentsOf: file)
        player?.delegate = self
        if player?.play() == true { state = .playing }
    }

    func stopPlayback() {
        guard let player else { return }
        player.stop()
        self.player = nil
        if let duration = file.flatMap({ try? AVAudioPlayer(contentsOf: $0).duration }) {
            state = .recorded(seconds: duration)
        }
    }

    /// Kaydedilmeyen kaydı atar.
    func discard() {
        if let file { try? FileManager.default.removeItem(at: file) }
        file = nil
        state = .idle
        elapsed = 0
    }

    /// Kaydedilen dosya ve süresi; sahipliği çağırana geçer.
    func take() -> (url: URL, seconds: Double)? {
        guard let file else { return nil }
        let seconds: Double
        switch state {
        case .recorded(let s): seconds = s
        case .playing: stopPlayback(); seconds = (try? AVAudioPlayer(contentsOf: file).duration) ?? 0
        default: return nil
        }
        self.file = nil
        state = .idle
        return (file, seconds)
    }
}

extension MPVoiceRecorder: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let duration = player.duration
        Task { @MainActor in
            self.player = nil
            self.state = .recorded(seconds: duration)
        }
    }
}

// MARK: - Ses kaydı rızası

/// Ses kaydı ayrı bir açık rıza ister (KVKK): kaydeden her yetişkin, ilk
/// kaydından önce bir kez (`families/{fid}/voiceConsents/{uid}`). Geri
/// çekmek bütün kayıtları siler.
enum VoiceConsent {
    static let version = "voice-2026-10"

    static let text = """
    Sesimi bu masalları çocuğuma okumak için kaydediyorum. Kayıtlar yalnızca bu aile hesabında, \
    ailenin yetişkinlerinin ve çocuklarının dinleyebileceği şekilde saklanır; ben sesli bir paylaşım \
    bağlantısı oluşturmadıkça başka hiçbir yerde açılmaz. Sesim reklam, analiz ya da yapay zekâ \
    eğitimi için kullanılmaz. Kayıtları Ayarlar > Kendi sesin bölümünden istediğim an silebilirim; \
    rızamı geri çekmek bütün kayıtlarımı siler.
    """

    private static func key(_ uid: String) -> String { "mp_voiceConsent_\(uid)" }

    static func isGiven(uid: String, defaults: UserDefaults = .standard) -> Bool {
        defaults.string(forKey: key(uid)) == version
    }

    /// Önce sunucuya yazar; yazılmadıysa kayıt başlamaz.
    @MainActor
    static func give(familyID: String, uid: String, defaults: UserDefaults = .standard) async throws {
        let ref = Firestore.firestore().collection("families").document(familyID)
            .collection("voiceConsents").document(uid)
        if try await !ref.getDocument(source: .server).exists {
            try await ref.setData([
                "version": version,
                "acceptedAt": FieldValue.serverTimestamp(),
                "clientAcceptedAt": NSNumber(value: SyncPlanner.milliseconds(Date())),
            ])
        }
        defaults.set(version, forKey: key(uid))
    }

    @MainActor
    static func withdraw(familyID: String, uid: String, defaults: UserDefaults = .standard) async throws {
        try await Firestore.firestore().collection("families").document(familyID)
            .collection("voiceConsents").document(uid).delete()
        defaults.removeObject(forKey: key(uid))
    }
}
