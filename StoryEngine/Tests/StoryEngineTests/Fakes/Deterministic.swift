import Foundation
@testable import StoryEngine

/// A clock the test drives. Backoff sleeps are recorded, not slept, so retry
/// tests assert on the schedule instead of waiting for it.
final class FixedClock: Clock, @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date
    private(set) var sleeps: [TimeInterval] = []
    /// Seconds the clock advances on every `now()`, so successive timestamps differ.
    var autoAdvance: TimeInterval

    init(start: Date = Date(timeIntervalSince1970: 1_700_000_000), autoAdvance: TimeInterval = 0) {
        self.current = start
        self.autoAdvance = autoAdvance
    }

    func now() -> Date {
        lock.lock()
        defer { lock.unlock() }
        let value = current
        current = current.addingTimeInterval(autoAdvance)
        return value
    }

    func sleep(for duration: TimeInterval) async throws {
        try Task.checkCancellation()
        lock.lock()
        sleeps.append(duration)
        current = current.addingTimeInterval(duration)
        lock.unlock()
    }

    func advance(by interval: TimeInterval) {
        lock.lock()
        current = current.addingTimeInterval(interval)
        lock.unlock()
    }
}

/// UUIDs that are readable in failure output and identical between runs.
final class SequentialIDGenerator: IDGenerator, @unchecked Sendable {
    private let lock = NSLock()
    private var counter: Int
    private let prefix: String

    init(startingAt start: Int = 1, prefix: String = "00000000-0000-0000-0000") {
        self.counter = start
        self.prefix = prefix
    }

    func next() -> UUID {
        lock.lock()
        defer { lock.unlock() }
        let value = counter
        counter += 1
        return UUID(uuidString: String(format: "%@-%012d", prefix, value))!
    }
}
