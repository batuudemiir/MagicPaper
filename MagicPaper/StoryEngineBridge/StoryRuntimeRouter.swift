import Foundation
import OSLog
import StoryEngine

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "StoryRuntimeRouter")

/// Which engine writes a new story (B3, beş arkadaş B hattı; karar K-A, K-B, K-C).
///
/// P56 writes only when the pilot flag is on and P56 supports the whole
/// request; everything else goes to the legacy engine exactly as today, with a
/// fixed reason code. The reason never carries child data.
///
/// This decides for **new** stories only. A saved P56 story is never rewritten
/// by the legacy engine: its source stays `.unsupported` for the historical
/// catalog (C4).
enum StoryRuntimeRoute: Equatable {
    case legacy
    case p56(P56SourceReference)
}

enum StoryRuntimeReason: String, Equatable {
    case flagOff, unsupportedAge, unsupportedRequest, payloadUnavailable, composeFailed
}

struct StoryRuntimeDecision: Equatable {
    let route: StoryRuntimeRoute
    let reason: StoryRuntimeReason?
}

/// What the router needs to know about a request. No child name or id.
struct StoryRuntimeRequest {
    let age: Int
    let mode: StoryMode
    let companionID: String?
    let family: FamilyCharacter?
    let topicID: String?
    let occasion: String?
    /// The profile's real policy (`UserProfile.effectiveSafety`), never dropped.
    let safety: ContentSafety?
}

enum StoryRuntimeFlags {
    /// Internal pilot only (K-C), never in Release. Debug builds have it on by
    /// default so the phone opened from the home screen shows the five friends
    /// (Batuhan, 26 Kasım 2026); `-mpFiveFriendsPilot NO` turns it off. Under
    /// unit tests the default stays off, so tests see today's flow unless
    /// they ask for the pilot.
    static var fiveFriendsPilot: Bool {
        #if DEBUG
        resolve(debug: true,
                launchValue: UserDefaults.standard.object(forKey: "mpFiveFriendsPilot") as? Bool,
                underTests: ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil)
        #else
        false
        #endif
    }

    /// The decision without the process: an explicit launch value wins in
    /// Debug; otherwise on, except under tests. Release is always off.
    static func resolve(debug: Bool, launchValue: Bool?, underTests: Bool) -> Bool {
        guard debug else { return false }
        return launchValue ?? !underTests
    }
}

/// The verified payload as the loader read it: the decoded package for
/// decisions and the exact bytes for the archive, so the archive never reads
/// or decodes the 12 MB a second time.
struct P56VerifiedSource {
    let reference: P56SourceReference
    let package: P56Package
    let payload: Data
}

/// Thread-safe: the lock guards only the load state (idle, loading, ready);
/// the payload is read and decoded outside it, so nobody waits on the lock
/// while 12 MB is decoded.
final class StoryRuntimeRouter: @unchecked Sendable {
    /// One router for the app, so the payload is read once for the selection
    /// screen (B5) and the writer (B4). Created at launch (the story library
    /// asks for it), and with the pilot flag on it starts reading the payload
    /// in the background right away.
    static let shared: StoryRuntimeRouter = {
        let router = StoryRuntimeRouter()
        router.prewarm()
        return router
    }()

    /// Whether the verified payload also reached the snapshot archive. Kept
    /// apart from the decision: a failed archive never makes a source "known".
    enum ArchiveOutcome: String, Equatable { case archived, failed }

    private typealias Loaded = Result<(P56SourceReference, P56Package), Error>

    /// The only thing the lock protects (kod düzeltmeleri, 26 Kasım 2026:
    /// kilit yükleme boyunca tutuluyordu, ana iş parçacığı 2-3 sn bekliyordu).
    /// A failed read is `.ready(.failure)`.
    private enum LoadState {
        case idle
        case loading
        case ready(Loaded)
    }

    private let isEnabled: Bool
    private let loadSource: () throws -> P56VerifiedSource
    private let archive: ((P56VerifiedSource) throws -> Void)?
    private let lock = NSLock()
    private var state: LoadState = .idle
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var archiveResult: ArchiveOutcome?

    init(isEnabled: Bool = StoryRuntimeFlags.fiveFriendsPilot,
         loadSource: @escaping () throws -> P56VerifiedSource = StoryRuntimeRouter.bundledSource,
         archive: ((P56VerifiedSource) throws -> Void)? = StoryRuntimeRouter.archiveBundled) {
        self.isEnabled = isEnabled
        self.loadSource = loadSource
        self.archive = archive
    }

    /// Nil until the archive write after a successful load has finished.
    var archiveOutcome: ArchiveOutcome? {
        lock.lock(); defer { lock.unlock() }
        return archiveResult
    }

    /// True once a decision can be made without waiting: the flag is off, or
    /// the payload has been read (or failed to read).
    var isReady: Bool {
        guard isEnabled else { return true }
        return readyResult() != nil
    }

    /// The decision for a new story. Waits, without blocking the caller's
    /// thread, for a payload read that is still running.
    func decide(_ request: StoryRuntimeRequest) async -> StoryRuntimeDecision {
        guard isEnabled else { return Self.flagOff }
        await waitUntilReady()
        guard let loaded = readyResult() else {
            return StoryRuntimeDecision(route: .legacy, reason: .payloadUnavailable)
        }
        return decision(request, loaded: loaded)
    }

    /// The decision if it can be made now; nil while the payload is still
    /// being read (the selection screen shows the five meanwhile and asks
    /// again). Starts the read if nothing has started it yet.
    func decideIfReady(_ request: StoryRuntimeRequest) -> StoryRuntimeDecision? {
        guard isEnabled else { return Self.flagOff }
        guard let loaded = readyResult() else { prewarm(); return nil }
        return decision(request, loaded: loaded)
    }

    /// Reads and verifies the payload off the main thread (B7 bulgusu: ilk
    /// kararda 3,3 MB ana iş parçacığında okunuyordu). With the flag off
    /// nothing is read; a call while a read is running or done does nothing.
    func prewarm() {
        guard isEnabled else { return }
        lock.lock()
        guard case .idle = state else { lock.unlock(); return }
        state = .loading
        lock.unlock()
        DispatchQueue.global(qos: .userInitiated).async { [self] in finishLoading() }
    }

    /// Returns once `isReady`; starts the read if needed.
    func waitUntilReady() async {
        guard isEnabled else { return }
        prewarm()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            lock.lock()
            if case .ready = state {
                lock.unlock()
                continuation.resume()
            } else {
                waiters.append(continuation)
                lock.unlock()
            }
        }
    }

    /// The package behind a `.p56` decision, for the writer (B4). Never waits:
    /// a `.p56` decision exists only after the payload is ready.
    func package(for reference: P56SourceReference) -> P56Package? {
        guard case .success(let (cachedReference, package)) = readyResult(), cachedReference == reference else {
            return nil
        }
        return package
    }

    /// An anonymous request for the support check: no child data, the real
    /// safety policy, and the request's contexts as P56 names them.
    static func p56Request(for request: StoryRuntimeRequest) -> P56Request {
        var contexts: [String] = []
        if request.family != nil { contexts.append("family") }
        if request.topicID != nil { contexts.append("topic") }
        if request.occasion != nil { contexts.append("occasion") }
        return P56Request(childID: "support-check", name: "Deniz", age: request.age, seed: 0,
                          mode: P56Mode(rawValue: request.mode.rawValue), companionID: request.companionID,
                          contexts: contexts, contentSafety: request.safety)
    }

    static func bundledSource() throws -> P56VerifiedSource {
        try P56BundledSource().loadVerified()
    }

    /// Archives the bytes the loader already verified and decoded: a hash
    /// check and a write, no second read or decode.
    static func archiveBundled(_ source: P56VerifiedSource) throws {
        try P56SnapshotStore(root: P56BundledSource.defaultStoreDirectory)
            .save(data: source.payload, reference: source.reference)
    }

    // MARK: - Private

    private static let flagOff = StoryRuntimeDecision(route: .legacy, reason: .flagOff)

    private func decision(_ request: StoryRuntimeRequest, loaded: Loaded) -> StoryRuntimeDecision {
        guard case .success(let (reference, package)) = loaded else {
            return StoryRuntimeDecision(route: .legacy, reason: .payloadUnavailable)
        }
        let reasons = P56Support.unsupportedReasons(for: Self.p56Request(for: request), package: package)
        if reasons.isEmpty { return StoryRuntimeDecision(route: .p56(reference), reason: nil) }
        return StoryRuntimeDecision(route: .legacy, reason: reasons == ["age"] ? .unsupportedAge : .unsupportedRequest)
    }

    private func readyResult() -> Loaded? {
        lock.lock(); defer { lock.unlock() }
        if case .ready(let loaded) = state { return loaded }
        return nil
    }

    /// Runs once, on a background queue; the read and decode hold no lock.
    private func finishLoading() {
        let verified = Result { try loadSource() }
        lock.lock()
        state = .ready(verified.map { ($0.reference, $0.package) })
        let resumed = waiters
        waiters = []
        lock.unlock()
        resumed.forEach { $0.resume() }

        // Arşiv karardan bağımsız, aynı arka plan işinde; sonucu ayrı tutulur.
        // Doğrulanmış baytlar arşive doğrudan gider, ikinci kez okunmaz.
        guard case .success(let source) = verified, let archive else { return }
        let outcome: ArchiveOutcome = (try? archive(source)) != nil ? .archived : .failed
        lock.lock(); archiveResult = outcome; lock.unlock()
        if outcome == .failed { logger.info("P56 archive: \(outcome.rawValue, privacy: .public)") }
    }
}
