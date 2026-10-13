import ActivityKit
import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "SleepMode")

/// Uyku modunun sesi ve saati (26, FAZ 19).
///
/// Önceden görünümün içindeydi; telefon kilitlenince de masal okunmaya,
/// saat işlemeye ve Live Activity güncel kalmaya devam etsin diye ayrıldı.
/// Geçen süre saniye saymakla değil duvar saatiyle tutulur: uygulama arka
/// planda ya da askıdayken geçen süre de sayılır.
@MainActor
final class MPSleepPlayback: ObservableObject {
    let session: MPSleepSession

    @Published private(set) var page = 0
    @Published private(set) var isPlaying = true
    @Published private(set) var finished = false
    /// Kararma ve kapanma bunu okur; `tick()` günceller.
    @Published private(set) var elapsed: TimeInterval = 0
    @Published var timer = MPSleepTimer() {
        didSet { if timer != oldValue { publishActivity() } }
    }

    /// Uyku modu kapanınca (süre doldu, masal bitti, Durdur).
    var onClose: (() -> Void)?

    private let speech: MPSleepSpeaking
    private let activity: MPSleepActivityHosting
    private let now: () -> Date
    /// Bu oynatmadan önce birikmiş süre ve oynatmanın başladığı an.
    private var playedBefore: TimeInterval = 0
    private var playingSince: Date?
    private var closed = false

    init(session: MPSleepSession,
         speech: MPSleepSpeaking? = nil,
         activity: MPSleepActivityHosting? = nil,
         now: @escaping () -> Date = Date.init) {
        self.session = session
        self.speech = speech ?? MPSpeech.shared
        self.activity = activity ?? MPSleepActivity.shared
        self.now = now
    }

    // MARK: - Yaşam döngüsü

    func start() {
        speech.onFinished = { [weak self] in self?.advance() }
        MPSleepRemote.stop = { [weak self] in self?.close() }
        playingSince = now()
        activity.start(state: activityState)
        readCurrentPage()
    }

    /// Görünüm kaybolunca: ses ve Live Activity kapanır.
    func stop() {
        speech.onFinished = nil
        speech.stop()
        MPSleepRemote.stop = nil
        activity.end()
    }

    func close() {
        guard !closed else { return }
        closed = true
        stop()
        onClose?()
    }

    /// Saniyede bir: süre dolduysa kapanır.
    func tick() {
        elapsed = playedBefore + (playingSince.map { now().timeIntervalSince($0) } ?? 0)
        if timer.isOver(after: elapsed) { close() }
    }

    func togglePlay() {
        isPlaying.toggle()
        if isPlaying {
            playingSince = now()
            if speech.isPaused { speech.resume() } else { readCurrentPage() }
        } else {
            tick()
            playedBefore = elapsed
            playingSince = nil
            speech.pause()
        }
        publishActivity()
    }

    // MARK: - Sayfalar

    private func readCurrentPage() {
        guard session.pages.indices.contains(page) else {
            finished = true
            publishActivity()
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                self?.close()
            }
            return
        }
        speech.speak(session.pages[page],
                     recording: session.storyID.flatMap { MPNarration.recording($0, page: session.pageIndexes[page]) })
    }

    private func advance() {
        guard isPlaying, !closed else { return }
        page += 1
        readCurrentPage()
    }

    // MARK: - Live Activity

    var activityState: MPSleepActivityAttributes.ContentState {
        let remaining = max(0, timer.duration - elapsedNow)
        return .init(endsAt: now().addingTimeInterval(remaining),
                     pausedRemaining: isPlaying ? nil : remaining,
                     finished: finished)
    }

    private var elapsedNow: TimeInterval {
        playedBefore + (playingSince.map { now().timeIntervalSince($0) } ?? 0)
    }

    private func publishActivity() {
        guard !closed else { return }
        activity.update(state: activityState)
    }
}

// MARK: - Ses

/// Uyku modunun sesten istediği (`MPSpeech`); testler sahte bir ses verir.
@MainActor
protocol MPSleepSpeaking: AnyObject {
    var isPaused: Bool { get }
    var onFinished: (() -> Void)? { get set }
    func speak(_ text: String, language: String, recording: URL?)
    func pause()
    func resume()
    func stop()
}

extension MPSleepSpeaking {
    func speak(_ text: String, recording: URL?) { speak(text, language: "tr-TR", recording: recording) }
}

extension MPSpeech: MPSleepSpeaking {}

// MARK: - Live Activity

@MainActor
protocol MPSleepActivityHosting: AnyObject {
    func start(state: MPSleepActivityAttributes.ContentState)
    func update(state: MPSleepActivityAttributes.ContentState)
    func end()
}

/// Uyku modunun Live Activity'si. Kullanıcı Live Activity'leri kapattıysa
/// hiçbir şey yapmaz; uyku modu yine çalışır.
@MainActor
final class MPSleepActivity: MPSleepActivityHosting {
    static let shared = MPSleepActivity()

    private var current: Activity<MPSleepActivityAttributes>?

    func start(state: MPSleepActivityAttributes.ContentState) {
        end()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            current = try Activity.request(attributes: MPSleepActivityAttributes(),
                                           content: content(state), pushType: nil)
        } catch {
            logger.notice("Uyku modu Live Activity açılamadı: \(error.localizedDescription, privacy: .public)")
        }
    }

    func update(state: MPSleepActivityAttributes.ContentState) {
        guard let current else { return }
        Task { await current.update(content(state)) }
    }

    func end() {
        guard let current else { return }
        self.current = nil
        Task { await current.end(nil, dismissalPolicy: .immediate) }
    }

    /// Önceki bir çalışmadan kalmış (uygulama kapatılmış) uyku modu
    /// etkinlikleri: açılışta ve aile verisi silinince kapanır.
    static func endAll() {
        for activity in Activity<MPSleepActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    /// Süre dolduktan sonra kilit ekranında eski bir sayaç kalmasın.
    private func content(_ state: MPSleepActivityAttributes.ContentState)
        -> ActivityContent<MPSleepActivityAttributes.ContentState> {
        ActivityContent(state: state, staleDate: state.isPaused ? nil : state.endsAt)
    }
}
