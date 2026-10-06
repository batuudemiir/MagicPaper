import Foundation
import OSLog
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "FirebaseBackend")

/// Firebase set-up for the account (FAZ 16). Called once, right after
/// `FirebaseApp.configure()`.
///
/// No Firebase Analytics, no Crashlytics (Kids kategorisi; plan kararı).
/// Firestore keeps no disk cache: the device's own stores are the offline
/// copy, and a second copy of a child's stories in Firestore's cache would be
/// one more place to forget when the account is deleted.
enum FirebaseBackend {
    /// DEBUG only: `-MPFirebaseEmulator <host>` points Auth and Firestore at
    /// the local emulator (`firebase/` in the repository). Never in Release.
    static var emulatorHost: String? {
        #if DEBUG
        return UserDefaults.standard.string(forKey: "MPFirebaseEmulator").flatMap { $0.isEmpty ? nil : $0 }
        #else
        return nil
        #endif
    }

    static func configure() {
        let settings = FirestoreSettings()
        settings.cacheSettings = MemoryCacheSettings()
        if let host = emulatorHost {
            settings.host = "\(host):8080"
            settings.isSSLEnabled = false
            Auth.auth().useEmulator(withHost: host, port: 9099)
            logger.notice("Firebase emülatörü kullanılıyor")
        }
        Firestore.firestore().settings = settings
    }
}

/// `families/{uid}/{collection}/{id}`: one document per record.
///
/// Fields: `payload` (the record's JSON, absent for a deletion), `deleted`,
/// `updatedAt` (writer's clock, ms), `serverUpdatedAt` (server time, the pull
/// mark), `schemaVersion`. `firebase/firestore.rules` checks the same shape.
struct FirestoreFamilyRemote: FamilyRemote {
    static let schemaVersion = 1
    static let consentsCollection = "consents"
    let uid: String

    private var family: DocumentReference {
        Firestore.firestore().collection("families").document(uid)
    }

    func pull(since highWater: [String: Date]) async throws -> [RemoteSyncRecord] {
        var records: [RemoteSyncRecord] = []
        for collection in SyncCollection.allCases {
            var query: Query = family.collection(collection.rawValue)
            if let mark = highWater[collection.rawValue] {
                query = query.whereField("serverUpdatedAt", isGreaterThan: Timestamp(date: mark))
            }
            // From the server, never a cache: a sync that reads its own
            // cache believes it is up to date.
            let snapshot = try await query.getDocuments(source: .server)
            for document in snapshot.documents {
                let data = document.data()
                let deleted = data["deleted"] as? Bool ?? false
                records.append(RemoteSyncRecord(
                    key: SyncKey(collection: collection, id: document.documentID),
                    payload: deleted ? nil : data["payload"] as? String,
                    updatedAt: (data["updatedAt"] as? NSNumber)?.int64Value ?? 0,
                    serverUpdatedAt: (data["serverUpdatedAt"] as? Timestamp)?.dateValue()))
            }
        }
        return records
    }

    func push(_ records: [RemoteSyncRecord]) async throws {
        let db = Firestore.firestore()
        for chunk in stride(from: 0, to: records.count, by: 400).map({ Array(records[$0..<min($0 + 400, records.count)]) }) {
            let batch = db.batch()
            for record in chunk {
                var fields: [String: Any] = [
                    "deleted": record.deleted,
                    "updatedAt": NSNumber(value: record.updatedAt),
                    "serverUpdatedAt": FieldValue.serverTimestamp(),
                    "schemaVersion": Self.schemaVersion,
                ]
                // A deleted record keeps no content on the server: the
                // tombstone is only there so other devices delete theirs.
                if let payload = record.payload { fields["payload"] = payload }
                batch.setData(fields, forDocument: family.collection(record.key.collection.rawValue)
                    .document(record.key.id))
            }
            try await batch.commit()
        }
    }

    func deleteEverything() async throws {
        let db = Firestore.firestore()
        let names = SyncCollection.allCases.map(\.rawValue) + [Self.consentsCollection]
        for name in names {
            let snapshot = try await family.collection(name).getDocuments(source: .server)
            for chunk in stride(from: 0, to: snapshot.documents.count, by: 400)
                .map({ Array(snapshot.documents[$0..<min($0 + 400, snapshot.documents.count)]) }) {
                let batch = db.batch()
                chunk.forEach { batch.deleteDocument($0.reference) }
                try await batch.commit()
            }
        }
        try await family.delete()
    }

    func recordConsent(_ record: ConsentRecord) async throws {
        // `setData` on a version that exists is refused by the rules (a
        // consent is written once); the merge-free create is the point.
        try await family.collection(Self.consentsCollection).document(record.version).setData([
            "version": record.version,
            "acceptedAt": FieldValue.serverTimestamp(),
            "clientAcceptedAt": NSNumber(value: SyncPlanner.milliseconds(record.acceptedAt)),
            "shareUsageData": record.shareUsageData,
        ])
    }

    func consent(version: String) async throws -> ConsentRecord? {
        let document = try await family.collection(Self.consentsCollection).document(version)
            .getDocument(source: .server)
        guard document.exists, let data = document.data() else { return nil }
        let millis = (data["clientAcceptedAt"] as? NSNumber)?.doubleValue ?? 0
        return ConsentRecord(
            version: version,
            acceptedAt: (data["acceptedAt"] as? Timestamp)?.dateValue() ?? Date(timeIntervalSince1970: millis / 1000),
            shareUsageData: data["shareUsageData"] as? Bool ?? false)
    }
}

/// `readingEvents/{auto}`: create-only, no account id, no reads.
struct FirestoreReadingEventSink: ReadingEventSink {
    func send(_ events: [ReadingEventWire]) async throws {
        let db = Firestore.firestore()
        let batch = db.batch()
        for event in events {
            batch.setData(event.fields, forDocument: db.collection("readingEvents").document())
        }
        try await batch.commit()
    }
}
