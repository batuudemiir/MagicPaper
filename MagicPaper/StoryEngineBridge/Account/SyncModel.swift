import Foundation
import CryptoKit

/// What the family's account holds on the server (FAZ 16), one kind per
/// Firestore subcollection under `families/{uid}`.
///
/// Each document carries one record of an existing app model as a JSON
/// string (`payload`). The models are not mapped field by field: they already
/// decode older and newer versions of themselves, and a second schema on the
/// server would be a second source of truth to keep in step.
enum SyncCollection: String, CaseIterable, Codable, Sendable {
    /// `UserProfile`, keyed by profile id. No photo, no photo file name.
    case children
    /// `AvatarSpec`, keyed by profile id.
    case avatars
    /// The child's Masal ailem (`[FamilyCharacter]`), keyed by profile id.
    case family
    /// `Story` without reading progress, keyed by story id. Written once:
    /// a story's text never changes after it is written.
    case stories
    /// Where a story was left (`StoryProgress`), keyed by story id.
    case progress
    /// The child's series (`[StorySeries]`), keyed by profile id.
    case series

    /// How two devices that both changed a record are reconciled.
    var policy: SyncConflictPolicy {
        switch self {
        case .stories: return .presenceOnly
        default: return .lastWriterWins
        }
    }

    /// Children first: everything else hangs off a child.
    static let applyOrder: [SyncCollection] = [.children, .avatars, .family, .series, .stories, .progress]
}

enum SyncConflictPolicy: Sendable {
    /// The newer write wins, whole record.
    case lastWriterWins
    /// Only whether the record exists is synced. Its content is never
    /// rewritten — the story text rule.
    case presenceOnly
}

struct SyncKey: Hashable, Codable, Sendable, CustomStringConvertible {
    let collection: SyncCollection
    let id: String

    var description: String { "\(collection.rawValue)/\(id)" }
}

/// One record as this device holds it.
struct LocalSyncRecord: Equatable, Sendable {
    let key: SyncKey
    let payload: String
    /// When the record itself says it changed, if it knows (reading progress
    /// does). Nil: the planner uses when it first saw the change.
    var changedAt: Date? = nil
}

/// One record as the server holds it.
struct RemoteSyncRecord: Equatable, Sendable {
    let key: SyncKey
    /// Nil for a deletion.
    let payload: String?
    /// The writer's clock, milliseconds. Last-writer-wins compares these.
    let updatedAt: Int64
    /// The server's clock at the write; the pull high-water mark.
    let serverUpdatedAt: Date?

    var deleted: Bool { payload == nil }
}

/// The reading position of one story, synced apart from the story so the
/// story document can stay write-once.
struct StoryProgress: Codable, Equatable, Sendable {
    var lastReadPage: Int?
    var lastReadAt: Date?
}

enum SyncDigest {
    static func of(_ payload: String) -> String {
        SHA256.hash(data: Data(payload.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// What a presence-only record's digest is: the same for every device
    /// that has it, whatever its local copy looks like.
    static let present = "present"
}

/// What this device last agreed with the server, per record.
///
/// Without it a missing local record cannot be told apart from one never
/// synced (delete it remotely, or upload nothing?), and a changed one cannot be
/// told apart from one changed elsewhere.
struct SyncLedger: Codable, Equatable, Sendable {
    struct Entry: Codable, Equatable, Sendable {
        /// Digest of the last agreed payload; nil when the agreed state is
        /// "deleted".
        var digest: String?
        var updatedAt: Int64
        /// A local change seen but not yet sent, and since when. A change
        /// that keeps changing keeps its first time.
        var pendingDigest: String?
        var pendingSince: Date?
    }

    var schemaVersion = 1
    /// The account this ledger belongs to. A ledger of another account is
    /// never used.
    var ownerUID: String?
    var entries: [String: Entry] = [:]
    /// Per collection, the newest `serverUpdatedAt` pulled.
    var highWater: [String: Date] = [:]
    /// Whether one full pull has finished for `ownerUID`.
    var restored = false

    subscript(key: SyncKey) -> Entry? {
        get { entries[key.description] }
        set { entries[key.description] = newValue }
    }

    var hasUnsentChanges: Bool { entries.values.contains { $0.pendingDigest != nil } }
}

/// What one sync does, decided without touching disk or network.
struct SyncPlan: Equatable, Sendable {
    /// Records to write to the server (`payload` nil = delete).
    var push: [RemoteSyncRecord] = []
    /// Server records to bring onto this device.
    var apply: [RemoteSyncRecord] = []
    /// The ledger after the plan has been carried out.
    var ledger: SyncLedger
}

/// Last writer wins, deletions travel as tombstones, a story is never
/// rewritten (FAZ 16 §3).
enum SyncPlanner {
    static func plan(
        local: [LocalSyncRecord],
        remote: [RemoteSyncRecord],
        ledger: SyncLedger,
        now: Date
    ) -> SyncPlan {
        var ledger = ledger
        var plan = SyncPlan(ledger: ledger)
        let localByKey = Dictionary(local.map { ($0.key, $0) }, uniquingKeysWith: { first, _ in first })
        let remoteByKey = Dictionary(remote.map { ($0.key, $0) }, uniquingKeysWith: { a, b in
            a.updatedAt >= b.updatedAt ? a : b
        })
        var keys = Set(localByKey.keys).union(remoteByKey.keys)
        for (raw, entry) in ledger.entries where entry.digest != nil {
            if let key = Self.key(raw) { keys.insert(key) }
        }

        let nowMS = milliseconds(now)

        for key in keys.sorted(by: { $0.description < $1.description }) {
            let policy = key.collection.policy
            let localRecord = localByKey[key]
            let remoteRecord = remoteByKey[key]
            var entry = ledger[key]

            let localDigest = localRecord.map { digest(of: $0.payload, policy) }
            let remoteDigest = remoteRecord?.payload.map { digest(of: $0, policy) }

            // A key the ledger has never seen and the device does not hold is
            // only a remote record; a key the ledger agreed was deleted and
            // the device does not hold has not changed.
            let localChanged: Bool = {
                guard let entry else { return localRecord != nil }
                return localDigest != entry.digest
            }()
            let remoteChanged: Bool = {
                guard remoteRecord != nil else { return false }
                guard let entry else { return true }
                return remoteDigest != entry.digest
            }()

            /// When this device's version came to be: the record's own time,
            /// or when the change was first seen, or now.
            func localChangeTime() -> Date {
                localRecord?.changedAt
                    ?? (entry?.pendingDigest == pendingMarker(localDigest) ? entry?.pendingSince : nil)
                    ?? now
            }

            func pushLocal() {
                let changedMS = min(milliseconds(localChangeTime()), nowMS)
                let stamp = max(changedMS, (entry?.updatedAt ?? 0) + 1)
                plan.push.append(RemoteSyncRecord(
                    key: key, payload: localRecord?.payload, updatedAt: stamp, serverUpdatedAt: nil))
                entry = SyncLedger.Entry(digest: localDigest, updatedAt: plan.push.last!.updatedAt)
            }

            func applyRemote(_ record: RemoteSyncRecord) {
                // A deletion of something this device never had needs no work.
                if !(record.deleted && localRecord == nil) {
                    plan.apply.append(record)
                }
                entry = SyncLedger.Entry(digest: remoteDigest, updatedAt: record.updatedAt)
            }

            switch (localChanged, remoteChanged) {
            case (false, false):
                if let remoteRecord, var agreed = entry {
                    agreed.updatedAt = max(agreed.updatedAt, remoteRecord.updatedAt)
                    entry = agreed
                }
            case (true, false):
                if policy == .presenceOnly, localRecord != nil, remoteRecord != nil, remoteDigest != nil {
                    // Already on the server; nothing to rewrite.
                    entry = SyncLedger.Entry(digest: remoteDigest, updatedAt: remoteRecord!.updatedAt)
                } else {
                    pushLocal()
                }
            case (false, true):
                applyRemote(remoteRecord!)
            case (true, true):
                let remoteRecord = remoteRecord!
                if localDigest == remoteDigest {
                    entry = SyncLedger.Entry(digest: remoteDigest, updatedAt: remoteRecord.updatedAt)
                } else if policy == .presenceOnly && localRecord != nil && !remoteRecord.deleted {
                    // Both have the story: the text is the text.
                    entry = SyncLedger.Entry(digest: remoteDigest, updatedAt: remoteRecord.updatedAt)
                } else {
                    if remoteRecord.updatedAt > milliseconds(localChangeTime()) {
                        applyRemote(remoteRecord)
                    } else {
                        pushLocal()
                    }
                }
            }

            ledger[key] = entry
        }

        for record in remote {
            guard let stamp = record.serverUpdatedAt else { continue }
            let name = record.key.collection.rawValue
            if ledger.highWater[name].map({ stamp > $0 }) ?? true {
                ledger.highWater[name] = stamp
            }
        }

        plan.ledger = ledger
        plan.apply.sort { lhs, rhs in
            let l = SyncCollection.applyOrder.firstIndex(of: lhs.key.collection) ?? 0
            let r = SyncCollection.applyOrder.firstIndex(of: rhs.key.collection) ?? 0
            return l == r ? lhs.key.id < rhs.key.id : l < r
        }
        return plan
    }

    /// Marks local changes seen now, so a change that waits (offline) keeps
    /// the time it was made rather than the time it was finally sent.
    static func notePending(local: [LocalSyncRecord], in ledger: SyncLedger, now: Date) -> SyncLedger {
        var ledger = ledger
        let localByKey = Dictionary(local.map { ($0.key, $0) }, uniquingKeysWith: { first, _ in first })
        var keys = Set(localByKey.keys)
        for (raw, entry) in ledger.entries where entry.digest != nil {
            if let key = Self.key(raw) { keys.insert(key) }
        }
        for key in keys {
            let localDigest = localByKey[key].map { digest(of: $0.payload, key.collection.policy) }
            var entry = ledger[key] ?? SyncLedger.Entry(digest: nil, updatedAt: 0)
            if ledger[key] == nil && localDigest == nil { continue }
            if localDigest == entry.digest {
                entry.pendingDigest = nil
                entry.pendingSince = nil
            } else if entry.pendingDigest != pendingMarker(localDigest) || entry.pendingSince == nil {
                entry.pendingDigest = pendingMarker(localDigest)
                entry.pendingSince = now
            }
            ledger[key] = entry
        }
        return ledger
    }

    /// A pending local deletion has no digest; it is marked as such.
    static func pendingMarker(_ localDigest: String?) -> String { localDigest ?? "deleted" }

    static func milliseconds(_ date: Date) -> Int64 { Int64((date.timeIntervalSince1970 * 1000).rounded()) }

    static func digest(of payload: String, _ policy: SyncConflictPolicy) -> String {
        policy == .presenceOnly ? SyncDigest.present : SyncDigest.of(payload)
    }

    static func key(_ raw: String) -> SyncKey? {
        guard let slash = raw.firstIndex(of: "/"),
              let collection = SyncCollection(rawValue: String(raw[..<slash])) else { return nil }
        return SyncKey(collection: collection, id: String(raw[raw.index(after: slash)...]))
    }
}
