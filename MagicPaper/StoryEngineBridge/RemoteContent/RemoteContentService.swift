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

    // MARK: - Running

    /// The foreground entry point: skipped if a run happened recently.
    @discardableResult
    func refreshIfDue() async -> Outcome {
        if let lastAttempt, now().timeIntervalSince(lastAttempt) < Self.minimumInterval { return .skipped }
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
            logger.notice("İçerik akışı alınamadı: \(String(describing: error), privacy: .public)")
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
        guard !rejected.contains(reference.sha256),
              reference.schemaVersion == ContentPackage.currentSchemaVersion else { return }

        let package: Data
        do {
            package = try await download(config.url(for: reference), limit: Self.maxPackageBytes)
        } catch {
            // Retried on the next run.
            logger.notice("İçerik paketi indirilemedi: \(String(describing: error), privacy: .public)")
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
            rejected = Array((rejected + [reference.sha256]).suffix(20))
            defaults.set(rejected, forKey: Self.rejectedPackagesKey)
            return
        }
        do {
            try store.stage(package)
            logger.info("İçerik paketi \(reference.version, privacy: .public) bir sonraki açılışta kullanılacak")
        } catch {
            logger.error("🛑 İçerik paketi yazılamadı")
        }
    }

    private func download(_ url: URL, limit: Int) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpShouldHandleCookies = false
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        guard data.count <= limit else { throw URLError(.dataLengthExceedsMaximum) }
        return data
    }

    // MARK: - Background refresh

    /// Must run before launch finishes (`AppDelegate`).
    nonisolated static func registerBackgroundRefresh() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return task.setTaskCompleted(success: false) }
            scheduleBackgroundRefresh()
            let work = Task { @MainActor in
                let outcome = await RemoteContentService.shared.refresh()
                task.setTaskCompleted(success: outcome != .failed)
            }
            task.expirationHandler = { work.cancel() }
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
