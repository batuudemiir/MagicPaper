import Foundation
import Combine
import Network
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "FamilySync")

/// Keeps the device and the parent's account in step (FAZ 16 §3).
///
/// Offline first: the app always reads and writes the device; this follows
/// behind. A sync is pull → plan → apply → push, as one step, never two at
/// once. It runs when the account signs in, when the app comes forward, and a
/// moment after a local change.
@MainActor
final class FamilySyncService: ObservableObject {
    enum Status: Equatable {
        case idle
        case syncing
        case synced(Date)
        /// No connection; changes wait on the device.
        case offline
        case failed
    }

    @Published private(set) var status: Status = .idle
    /// Changes this device has that the account does not.
    @Published private(set) var hasUnsentChanges = false
    /// One full pull has finished for the signed-in account.
    @Published private(set) var restored = false

    private let local: FamilyLocalStore
    private let ledgerStore: SyncLedgerStore
    private let clock: () -> Date
    private var remote: FamilyRemote?
    private var uid: String?
    private var running: Task<Bool, Never>?
    private var runID = 0
    private var scheduled: Task<Void, Never>?
    private var applying = false
    private var observers: Set<AnyCancellable> = []
    private let reachability = Reachability()
    /// Runs after every successful sync (reading events go then).
    var afterSync: (() async -> Void)?

    init(
        local: FamilyLocalStore,
        ledgerStore: SyncLedgerStore = SyncLedgerStore(),
        clock: @escaping () -> Date = Date.init
    ) {
        self.local = local
        self.ledgerStore = ledgerStore
        self.clock = clock
    }

    /// Starts syncing `uid`. A ledger kept for another account is dropped:
    /// its marks say nothing about this one.
    func start(uid: String, remote: FamilyRemote) {
        self.uid = uid
        self.remote = remote
        var ledger = ledgerStore.load()
        if ledger.ownerUID != uid {
            ledger = SyncLedger(ownerUID: uid)
            ledgerStore.save(ledger)
        }
        restored = ledger.restored
        hasUnsentChanges = ledger.hasUnsentChanges
        observeLocalChanges()
        reachability.onChange = { [weak self] online in
            Task { @MainActor in
                guard let self else { return }
                if online { self.schedule(after: 1) } else if self.status != .syncing { self.status = .offline }
            }
        }
        reachability.start()
        schedule(after: 0)
    }

    func stop() {
        scheduled?.cancel()
        running?.cancel()
        running = nil
        observers.removeAll()
        reachability.stop()
        uid = nil
        remote = nil
        restored = false
        hasUnsentChanges = false
        status = .idle
    }

    /// Gives up waiting for the first pull (offline, new device): the parent
    /// can start a profile; the account's children arrive when it connects.
    func settleRestoreWithoutPull() {
        restored = true
    }

    func schedule(after seconds: Double = 2) {
        guard uid != nil else { return }
        scheduled?.cancel()
        scheduled = Task { [weak self] in
            if seconds > 0 {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            await self?.syncNow()
        }
    }

    /// One sync that starts now. One already running is waited for first:
    /// it may have read the device before the change the caller cares about.
    @discardableResult
    func syncNow() async -> Bool {
        while let running { _ = await running.value }
        runID += 1
        let id = runID
        let task = Task { () -> Bool in
            let result = await self.performSync()
            // Cleared by the run itself, so a waiter never sees a finished run.
            if self.runID == id { self.running = nil }
            return result
        }
        running = task
        return await task.value
    }

    private func performSync() async -> Bool {
        guard let uid, let remote else { return false }
        let records = await local.records()
        var ledger = SyncPlanner.notePending(local: records, in: ledgerStore.load(), now: clock())
        ledger.ownerUID = uid
        ledgerStore.save(ledger)
        hasUnsentChanges = ledger.hasUnsentChanges

        guard reachability.isOnline else {
            status = .offline
            return false
        }
        status = .syncing
        do {
            let pulled = try await remote.pull(since: ledger.highWater)
            guard self.uid == uid else { return false }
            let plan = SyncPlanner.plan(local: records, remote: pulled, ledger: ledger, now: clock())
            if !plan.apply.isEmpty {
                applying = true
                await local.apply(plan.apply)
                applying = false
            }
            if !plan.push.isEmpty {
                try await remote.push(plan.push)
            }
            guard self.uid == uid else { return false }
            var settled = plan.ledger
            for (key, entry) in settled.entries where entry.pendingDigest != nil {
                if entry.pendingDigest == SyncPlanner.pendingMarker(entry.digest) {
                    settled.entries[key]?.pendingDigest = nil
                    settled.entries[key]?.pendingSince = nil
                }
            }
            settled.restored = true
            ledgerStore.save(settled)
            restored = true
            hasUnsentChanges = settled.hasUnsentChanges
            status = .synced(clock())
            logger.debug("Eşitleme: \(plan.apply.count, privacy: .public) geldi, \(plan.push.count, privacy: .public) gitti")
            await afterSync?()
            return true
        } catch {
            applying = false
            status = reachability.isOnline ? .failed : .offline
            logger.notice("Eşitleme tamamlanamadı; değişiklikler cihazda bekliyor")
            return false
        }
    }

    private func observeLocalChanges() {
        observers.removeAll()
        let changed = { [weak self] in
            guard let self, !self.applying else { return }
            self.schedule()
        }
        StoryGenerationManager.shared.$stories.dropFirst().sink { _ in changed() }.store(in: &observers)
        ProfileManager.shared.$profiles.dropFirst().sink { _ in changed() }.store(in: &observers)
        // Posted on the main actor by the stores, so `applying` is still
        // set when a write made by `apply` arrives here.
        NotificationCenter.default.publisher(for: .mpFamilyDataChanged)
            .sink { _ in changed() }
            .store(in: &observers)
    }
}

/// Whether a network path exists. A sync that cannot reach the server says
/// "offline" at once instead of waiting on a timeout.
final class Reachability: @unchecked Sendable {
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "mp.reachability")
    private let lock = NSLock()
    private var online = true
    private var started = false
    var onChange: ((Bool) -> Void)?

    var isOnline: Bool {
        lock.lock(); defer { lock.unlock() }
        return online
    }

    func start() {
        guard !started else { return }
        started = true
        // A cancelled monitor cannot be restarted; each start makes its own.
        let monitor = NWPathMonitor()
        self.monitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let now = path.status == .satisfied
            self.lock.lock()
            let changed = now != self.online
            self.online = now
            self.lock.unlock()
            if changed { self.onChange?(now) }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        guard started else { return }
        started = false
        monitor?.cancel()
        monitor = nil
    }
}
