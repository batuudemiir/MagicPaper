import AVFoundation
import SwiftUI

/// Mikrofondan tek bir sayfa kaydı (33 · Kendi sesin).
///
/// İzin yalnızca ebeveyn ilk kez "Kaydet"e basınca istenir. Kayıt sürerken
/// ses seviyesi dalga çubuklarını besler; bir sayfa en fazla
/// `maxSeconds` sürer, sonra kendiliğinden durur.
@MainActor
final class VoiceRecorder: NSObject, ObservableObject {
    enum State: Equatable { case idle, recording, denied, failed }

    static let maxSeconds: TimeInterval = 180
    /// Dalga çubuklarının sayısı.
    static let barCount = 24

    @Published private(set) var state: State = .idle
    /// 0...1, en yenisi sonda.
    @Published private(set) var levels: [CGFloat] = Array(repeating: 0, count: VoiceRecorder.barCount)

    private var recorder: AVAudioRecorder?
    private var meter: Timer?
    private var onSaved: (() -> Void)?

    func start(to url: URL, onSaved: @escaping () -> Void) async {
        guard await AVAudioApplication.requestRecordPermission() else {
            state = .denied
            return
        }
        MPSpeech.shared.stop()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
            try session.setActive(true)
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let next = try AVAudioRecorder(url: url, settings: settings)
            next.isMeteringEnabled = true
            guard next.record(forDuration: Self.maxSeconds) else { state = .failed; return }
            recorder = next
            self.onSaved = onSaved
            state = .recording
            startMeter()
        } catch {
            state = .failed
        }
    }

    func stop() {
        guard let recorder else { return }
        recorder.stop()
        self.recorder = nil
        meter?.invalidate()
        meter = nil
        levels = Array(repeating: 0, count: Self.barCount)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        state = .idle
        onSaved?()
        onSaved = nil
    }

    private func startMeter() {
        meter = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.sample() }
        }
    }

    private func sample() {
        guard let recorder else { return }
        if !recorder.isRecording { stop(); return }
        recorder.updateMeters()
        let db = recorder.averagePower(forChannel: 0)
        let level = CGFloat(max(0, min(1, (db + 50) / 50)))
        levels = Array(levels.dropFirst()) + [level]
    }
}
