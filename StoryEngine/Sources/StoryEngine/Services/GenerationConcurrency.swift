import Foundation

/// How much work the engine may have in flight at once.
///
/// The arithmetic this prevents is unglamorous but real: ten stories, ten pages
/// each, one illustration per page is a hundred simultaneous image requests —
/// enough to exhaust a rate limit, a budget, or a device's memory in one go.
/// Defaults are deliberately conservative; a caller who knows better can raise
/// them.
public struct GenerationConcurrencyPolicy: Codable, Sendable, Hashable {
    public let maxConcurrentStories: Int
    public let maxConcurrentAIRequests: Int
    public let maxConcurrentImageRequests: Int

    public init(
        maxConcurrentStories: Int = 2,
        maxConcurrentAIRequests: Int = 3,
        maxConcurrentImageRequests: Int = 2
    ) {
        self.maxConcurrentStories = max(1, maxConcurrentStories)
        self.maxConcurrentAIRequests = max(1, maxConcurrentAIRequests)
        self.maxConcurrentImageRequests = max(1, maxConcurrentImageRequests)
    }

    /// What a phone should do: one book at a time, a couple of calls in flight.
    public static let conservative = GenerationConcurrencyPolicy()

    /// One thing at a time. Used by tests that assert on ordering.
    public static let serial = GenerationConcurrencyPolicy(
        maxConcurrentStories: 1, maxConcurrentAIRequests: 1, maxConcurrentImageRequests: 1
    )
}

/// Which pool a piece of work draws from.
public enum ConcurrencyLane: String, Sendable, Hashable, CaseIterable {
    case story
    case aiRequest
    case imageRequest
}

/// A counting limiter with FIFO waiting.
///
/// FIFO matters: without it a long-running book can be starved indefinitely by
/// newer work that keeps arriving, which is the failure people actually notice.
/// Capacity is released in a `defer`, so it comes back on success, on failure
/// and on cancellation alike — a limiter that leaks a slot on the error path is
/// worse than no limiter, because it fails closed and quietly.
public actor GenerationConcurrencyLimiter {
    private let policy: GenerationConcurrencyPolicy
    private var active: [ConcurrencyLane: Int] = [:]
    private var waiting: [ConcurrencyLane: [(id: UUID, continuation: CheckedContinuation<Void, Error>)]] = [:]
    /// High-water marks, so a test can assert a limit was never exceeded.
    public private(set) var peak: [ConcurrencyLane: Int] = [:]

    public init(policy: GenerationConcurrencyPolicy = .conservative) {
        self.policy = policy
    }

    public func activeCount(_ lane: ConcurrencyLane) -> Int { active[lane] ?? 0 }
    public func peakCount(_ lane: ConcurrencyLane) -> Int { peak[lane] ?? 0 }
    public func waitingCount(_ lane: ConcurrencyLane) -> Int { waiting[lane]?.count ?? 0 }

    public func limit(for lane: ConcurrencyLane) -> Int {
        switch lane {
        case .story: return policy.maxConcurrentStories
        case .aiRequest: return policy.maxConcurrentAIRequests
        case .imageRequest: return policy.maxConcurrentImageRequests
        }
    }

    /// Runs `work` with a slot held, releasing it however `work` ends.
    public func withSlot<Value: Sendable>(_ lane: ConcurrencyLane, _ work: @Sendable () async throws -> Value) async throws -> Value {
        try await acquire(lane)
        defer { release(lane) }
        return try await work()
    }

    /// Waits for capacity. Throws if cancelled while queued, so a cancelled
    /// story does not sit holding a place in the queue.
    public func acquire(_ lane: ConcurrencyLane) async throws {
        try Task.checkCancellation()

        if activeCount(lane) < limit(for: lane) {
            occupy(lane)
            return
        }

        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                waiting[lane, default: []].append((id: id, continuation: continuation))
            }
        } onCancel: {
            Task { await self.cancelWaiter(id: id, lane: lane) }
        }
    }

    /// Hands the slot to the longest-waiting caller, or back to the pool.
    public func release(_ lane: ConcurrencyLane) {
        guard var queue = waiting[lane], !queue.isEmpty else {
            active[lane] = max(0, activeCount(lane) - 1)
            return
        }
        let next = queue.removeFirst()
        waiting[lane] = queue
        // The slot passes straight across, so the count never dips and lets a
        // third caller slip in ahead of the queue.
        next.continuation.resume()
    }

    private func occupy(_ lane: ConcurrencyLane) {
        let count = activeCount(lane) + 1
        active[lane] = count
        peak[lane] = max(peak[lane] ?? 0, count)
    }

    private func cancelWaiter(id: UUID, lane: ConcurrencyLane) {
        guard var queue = waiting[lane], let index = queue.firstIndex(where: { $0.id == id }) else { return }
        let waiter = queue.remove(at: index)
        waiting[lane] = queue
        waiter.continuation.resume(throwing: CancellationError())
    }

    public func resetPeaks() { peak.removeAll() }
}
