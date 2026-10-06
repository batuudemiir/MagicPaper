import Foundation
import BackgroundTasks
import OSLog
import StoryEngine

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "RemoteContent")

/// Fetches the content feed and catalog packages (FAZ 15).
///
/// Runs at launch, when the app comes back to the foreground (at most every
/// half hour), and as a background app refresh. Each run: download the feed
/// and its signature → verify → keep it if it is newer → if it names a package
/// this device does not have, download it, check its digest, load it through
/// the engine and stage it for the next launch.
///
/// Requests carry nothing about the family: no query, no cookies, no
/// identifiers — the same two static files for everyone. Content is never
/// logged; versions and outcomes are.
@MainActor
final class RemoteContentService: ObservableObject {
    static let shared = RemoteContentService()

    static let backgroundTaskIdentifier = "com.magicpaper.content-refresh"
    /// Foreground runs closer together than this are skipped.
    static let minimumInterval: TimeInterval = 30 * 60
    /// How long iOS is asked to wait before the next background refresh.
    static let backgroundInterval: TimeInterval = 6 * 60 * 60

    static let maxFeedBytes = 2 * 1024 * 1024
    static let maxPackageBytes = 16 * 1024 * 1024

    /// The last verified feed. `nil` before the first one arrives.
    @Published private(set) var feed: ContentFeed?

    enum Outcome: Equatable {
        /// No key or address in this build.
        case disabled
        case skipped
        case unchanged
        case updated(feedVersion: Int)
        case failed
    }

    private let config: RemoteContentConfig?
    private let store: RemoteContentStore
    private let session: URLSession
    private let defaults: UserDefaults
    private let now: () -> Date
    private let bundledCatalog: @Sendable () -> ContentCatalogLoader.Result?
    private var lastAttempt: Date?
    private var running: Task<Outcome, Never>?

    /// Package digests that were downloaded and refused. Not fetched again
    /// until a feed names a different one.
    static let rejectedPackagesKey = "mp.remoteContent.rejectedPackages"

    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    init(
        config: RemoteContentConfig? = RemoteContentConfig.current(),
        store: RemoteContentStore = RemoteContentStore(),
        session: URLSession = RemoteContentService.makeSession(),
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init,
        bundledCatalog: @escaping @Sendable () -> ContentCatalogLoader.Result? = { try? ContentCatalogLoader().load() }
    ) {
        self.config = config
        self.store = store
        self.session = session
        self.defaults = defaults
        self.now = now
        self.bundledCatalog = bundledCatalog
        if let key = config?.key { feed = store.feed(key: key) }
    }

    nonisolated static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }

    private var foregroundInterval: TimeInterval {
        #if DEBUG
        // `-mp.debug.contentRefreshInterval 5`: try a republish in the simulator,
        // where background refresh does not run.
        let override = defaults.double(forKey: "mp.debug.contentRefreshInterval")
        if override > 0 { return override }
        #endif
        return Self.minimumInterval
    }

    // MARK: - Running

    /// The foreground entry point: skipped if a run happened recently.
    @discardableResult
    func refreshIfDue() async -> Outcome {
        if let lastAttempt, now().timeIntervalSince(lastAttempt) < foregroundInterval { return .skipped }
        return await refresh()
    }

    /// One run. Concurrent callers share it.
    @discardableResult
    func refresh() async -> Outcome {
        if let running { return await running.value }
        let task = Task { await self.run() }
        running = task
        let outcome = await task.value
        running = nil
        return outcome
    }

    /// The background task ran out of time: stop downloading.
    func cancelRunning() {
        running?.cancel()
    }

    private func run() async -> Outcome {
        guard let config else { return .disabled }
        lastAttempt = now()

        let fresh: ContentFeed
        let data: Data
        let signature: Data
        do {
            async let feedBytes = download(config.feedURL, limit: Self.maxFeedBytes)
            async let signatureBytes = download(config.signatureURL, limit: 4 * 1024)
            (data, signature) = try await (feedBytes, signatureBytes)
            fresh = try ContentFeed.verified(data, signature: signature, key: config.key)
        } catch {
            // Offline is the ordinary case for this; the stored feed serves.
            logger.notice("İçerik akışı alınamadı: \(Self.brief(error), privacy: .public)")
            return .failed
        }

        var outcome = Outcome.unchanged
        let stored = store.feed(key: config.key)
        if fresh.feedVersion > (stored?.feedVersion ?? Int.min) {
            do {
                try store.saveFeed(data, signature: signature)
                feed = fresh
                outcome = .updated(feedVersion: fresh.feedVersion)
                logger.info("İçerik akışı \(fresh.feedVersion, privacy: .public) alındı")
            } catch {
                logger.error("🛑 İçerik akışı yazılamadı")
                return .failed
            }
        } else if fresh.feedVersion < (stored?.feedVersion ?? Int.min) {
            logger.notice("Eski içerik akışı (\(fresh.feedVersion, privacy: .public)) geri çevrildi")
        }

        await syncPackage((feed ?? stored)?.catalogPackage, config: config)
        return outcome
    }

    /// Brings the staged package in line with what the feed names.
    private func syncPackage(_ reference: CatalogPackageRef?, config: RemoteContentConfig) async {
        guard let reference else {
            // The publisher took the package back: the bundle serves again.
            store.removeStaged()
            store.removeActive()
            return
        }
        if let staged = store.stagedPackage {
            if reference.matches(staged) { return }
            // Superseded before it was ever used.
            store.removeStaged()
        }
        if let active = store.activePackage, reference.matches(active) { return }
        var rejected = defaults.stringArray(forKey: Self.rejectedPackagesKey) ?? []
        let rejectionKey = Self.buildNumber + ":" + reference.sha256
        guard !rejected.contains(rejectionKey),
              reference.schemaVersion == ContentPackage.currentSchemaVersion else { return }

        let package: Data
        do {
            package = try await download(config.url(for: reference), limit: Self.maxPackageBytes)
        } catch {
            // Retried on the next run.
            logger.notice("İçerik paketi indirilemedi: \(Self.brief(error), privacy: .public)")
            return
        }

        let bundled = bundledCatalog
        let verdict: String? = await Task.detached(priority: .utility) {
            guard reference.matches(package) else { return "digest" }
            guard let loaded = try? ContentCatalogLoader().load(package: package) else { return "load" }
            guard let bundled = bundled() else { return "bundle" }
            let verdict = RemoteCatalogPolicy.evaluate(package: loaded, bundled: bundled)
            return verdict == .accept ? nil : String(describing: verdict)
        }.value

        if let verdict {
            logger.notice("İçerik paketi \(reference.version, privacy: .public) geri çevrildi: \(verdict, privacy: .public)")
            // A body that does not hash right may be a cache in the way, not
            // the package: tried again next run. A package this engine read
            // and refused stays refused — until an app update, which may read it.
            if verdict != "digest" {
                rejected = Array((rejected + [rejectionKey]).suffix(20))
                defaults.set(rejected, forKey: Self.rejectedPackagesKey)
            }
            return
        }
        do {
            try store.stage(package)
            logger.info("İçerik paketi \(reference.version, privacy: .public) bir sonraki açılışta kullanılacak")
        } catch {
            logger.error("🛑 İçerik paketi yazılamadı")
        }
    }

    /// A failure in a few words: the code, not the whole error with its URL.
    private static func brief(_ error: Error) -> String {
        if let rejection = error as? ContentFeed.Rejection { return "\(rejection)" }
        if let url = error as? URLError { return "URLError \(url.code.rawValue)" }
        return String(describing: type(of: error))
    }

    private func download(_ url: URL, limit: Int) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpShouldHandleCookies = false
        let (data, response) = try await LimitedDownload(limit: limit).run(request, configuration: session.configuration)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    // MARK: - Background refresh

    /// Must run before launch finishes (`AppDelegate`).
    nonisolated static func registerBackgroundRefresh() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return task.setTaskCompleted(success: false) }
            scheduleBackgroundRefresh()
            let completion = BackgroundCompletion(task)
            task.expirationHandler = {
                Task { @MainActor in RemoteContentService.shared.cancelRunning() }
                completion.finish(success: false)
            }
            Task { @MainActor in
                let outcome = await RemoteContentService.shared.refresh()
                completion.finish(success: outcome != .failed)
            }
        }
    }

    /// Asks iOS for the next background refresh. iOS decides when, if ever.
    nonisolated static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: backgroundInterval)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            logger.notice("Arka plan yenilemesi planlanamadı: \(String(describing: error), privacy: .public)")
        }
    }
}

/// Tells iOS a background task is over — once, whichever comes first: the
/// run finishing or the time running out.
private final class BackgroundCompletion: @unchecked Sendable {
    private let task: BGTask
    private let lock = NSLock()
    private var finished = false

    init(_ task: BGTask) { self.task = task }

    func finish(success: Bool) {
        lock.lock()
        defer { lock.unlock() }
        guard !finished else { return }
        finished = true
        task.setTaskCompleted(success: success)
    }
}

/// One download that stops the moment it passes `limit` — refused before it
/// fills memory, not after. Cancelling the calling task cancels the request.
private final class LimitedDownload: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private let limit: Int
    private let lock = NSLock()
    private var buffer = Data()
    private var response: URLResponse?
    private var continuation: CheckedContinuation<(Data, URLResponse), Error>?
    private var overflow = false

    init(limit: Int) { self.limit = limit }

    func run(_ request: URLRequest, configuration: URLSessionConfiguration) async throws -> (Data, URLResponse) {
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        let task = session.dataTask(with: request)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                lock.lock()
                self.continuation = continuation
                lock.unlock()
                task.resume()
            }
        } onCancel: {
            task.cancel()
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        lock.lock()
        self.response = response
        let tooLarge = response.expectedContentLength > Int64(limit)
        if tooLarge { overflow = true }
        lock.unlock()
        completionHandler(tooLarge ? .cancel : .allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        buffer.append(data)
        let tooLarge = buffer.count > limit
        if tooLarge { overflow = true }
        lock.unlock()
        if tooLarge { dataTask.cancel() }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        let continuation = self.continuation
        self.continuation = nil
        let result: Result<(Data, URLResponse), Error>
        if overflow {
            result = .failure(URLError(.dataLengthExceedsMaximum))
        } else if let error {
            result = .failure(error)
        } else if let response {
            result = .success((buffer, response))
        } else {
            result = .failure(URLError(.badServerResponse))
        }
        lock.unlock()
        continuation?.resume(with: result)
    }
}
