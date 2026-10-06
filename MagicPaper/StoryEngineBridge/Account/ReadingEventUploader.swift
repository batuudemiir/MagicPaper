import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "ReadingEventUploader")

/// Sends the anonymous reading events (FAZ 14 → FAZ 16).
///
/// Three conditions, all of them: the parent's switch is on, the parent has
/// agreed to the current consent text on this account (which says what is
/// shared), and there is an account to send through. The events carry no
/// account id (`ReadingEventWire`); the account only proves a real app sent
/// them.
struct ReadingEventUploader {
    static let batchSize = 100

    let queue: ReadingEventQueue
    let sink: ReadingEventSink

    init(queue: ReadingEventQueue = ReadingEventQueue(), sink: ReadingEventSink) {
        self.queue = queue
        self.sink = sink
    }

    struct Conditions: Equatable {
        var sharingOn: Bool
        var consentGiven: Bool
        var signedIn: Bool

        var allowSending: Bool { sharingOn && consentGiven && signedIn }
    }

    /// Sends what waits, a batch at a time. Returns how many were sent.
    @discardableResult
    func flush(when conditions: Conditions) async -> Int {
        guard conditions.allowSending else { return 0 }
        var sent = 0
        // Bounded: never more batches than the queue could hold.
        for _ in 0..<(ReadingEventQueue.capacity / Self.batchSize + 1) {
            let batch = Array(queue.outbound().prefix(Self.batchSize))
            guard !batch.isEmpty else { break }
            do {
                try await sink.send(batch.map(ReadingEventWire.init))
            } catch {
                logger.notice("Okuma bilgisi gönderilemedi; sırada bekliyor")
                break
            }
            queue.removeSent(batch)
            sent += batch.count
        }
        if sent > 0 {
            logger.debug("Okuma bilgisi gönderildi: \(sent, privacy: .public)")
        }
        return sent
    }
}
