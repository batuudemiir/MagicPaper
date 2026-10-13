import Foundation
import FirebaseFirestore

/// Haftalık özet e-postası (FAZ 18): `families/{fid}/settings/weeklyEmail`.
///
/// Yalnızca kurucu açar; adres hesabın doğrulanmış e-postası (kurallar da
/// bunu zorlar). Varsayılan kapalı. Gönderim Cloud Functions'ta
/// (`firebase/functions`), Pazar 09:00; o hafta okuma yoksa gönderilmez.
protocol WeeklyEmailRemote: Sendable {
    func isEnabled(familyID: String) async throws -> Bool
    func set(enabled: Bool, email: String, timeZone: String, familyID: String) async throws
}

struct FirestoreWeeklyEmailRemote: WeeklyEmailRemote {
    private func document(_ familyID: String) -> DocumentReference {
        Firestore.firestore().collection("families").document(familyID).collection("settings").document("weeklyEmail")
    }

    func isEnabled(familyID: String) async throws -> Bool {
        let snapshot = try await document(familyID).getDocument(source: .server)
        return snapshot.data()?["enabled"] as? Bool ?? false
    }

    func set(enabled: Bool, email: String, timeZone: String, familyID: String) async throws {
        // Kapatınca adres de gider: kullanılmayan e-posta saklanmaz.
        guard enabled else {
            try await document(familyID).delete()
            return
        }
        try await document(familyID).setData([
            "enabled": enabled,
            "email": email,
            "timezone": timeZone,
            "updatedAt": FieldValue.serverTimestamp(),
        ])
    }
}

enum WeeklyEmailCopy {
    static let title = "Haftalık özet e-postası"

    static func subtitle(enabled: Bool, email: String?, isFounder: Bool) -> String {
        guard isFounder else { return "Ailenin kurucusu açabilir" }
        guard let email else { return "Hesabında doğrulanmış e-posta yok" }
        return enabled ? "Pazar sabahları · \(email)" : "Pazar sabahları, okunan masallar"
    }
}
