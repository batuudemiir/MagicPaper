import Foundation
import FirebaseFirestore
import FirebaseStorage

/// `shares/{token}` (açık), `families/{fid}/shares/{token}` (ailenin listesi),
/// `shares/{token}/{story}/{page}.m4a` (sesli paylaşımın kopyaları).
/// Biçim ve yetkiler `firebase/firestore.rules` ve `firebase/storage.rules`'ta.
struct FirebaseShareRemote: ShareRemote {
    private var db: Firestore { Firestore.firestore() }

    func create(token: String, document: ShareDocument, recipient: String?, audioFiles: [String: URL], createdBy: String) async throws {
        var fields = document.fields
        fields["expiresAt"] = Timestamp(date: document.expiresAt)
        fields["createdAt"] = FieldValue.serverTimestamp()
        // Önce açık belge: Storage kuralı ses kopyasına izni ona bakarak verir.
        try await db.collection("shares").document(token).setData(fields)
        var copied: [String] = []
        do {
            for key in document.audioKeys {
                guard let file = audioFiles[key] else { continue }
                let metadata = StorageMetadata()
                metadata.contentType = "audio/mp4"
                _ = try await Storage.storage().reference(withPath: "shares/\(token)/\(key).m4a")
                    .putFileAsync(from: file, metadata: metadata)
                copied.append(key)
            }
            var meta: [String: Any] = [
                "storyCount": document.stories.count,
                "voice": document.voice,
                "audio": copied,
                "expiresAt": Timestamp(date: document.expiresAt),
                "createdAt": FieldValue.serverTimestamp(),
                "createdBy": createdBy,
            ]
            if let recipient, !recipient.isEmpty { meta["recipient"] = String(recipient.prefix(40)) }
            try await db.collection("families").document(document.familyID).collection("shares").document(token).setData(meta)
        } catch {
            // Yarım kalan bağlantı açık kalmasın.
            for key in copied { try? await Storage.storage().reference(withPath: "shares/\(token)/\(key).m4a").delete() }
            try? await db.collection("shares").document(token).delete()
            throw error
        }
    }

    func list(familyID: String) async throws -> [ShareRecord] {
        let snapshot = try await db.collection("families").document(familyID).collection("shares")
            .getDocuments(source: .server)
        return snapshot.documents.compactMap { document in
            let data = document.data()
            guard let expires = (data["expiresAt"] as? Timestamp)?.dateValue() else { return nil }
            return ShareRecord(token: document.documentID,
                               recipient: data["recipient"] as? String,
                               storyCount: data["storyCount"] as? Int ?? 0,
                               voice: data["voice"] as? Bool ?? false,
                               expiresAt: expires,
                               audio: data["audio"] as? [String] ?? [])
        }
        .sorted { $0.expiresAt > $1.expiresAt }
    }

    func revoke(_ record: ShareRecord, familyID: String) async throws {
        for key in record.audio {
            try? await Storage.storage().reference(withPath: "shares/\(record.token)/\(key).m4a").delete()
        }
        try await db.collection("shares").document(record.token).delete()
        try await db.collection("families").document(familyID).collection("shares").document(record.token).delete()
    }
}
