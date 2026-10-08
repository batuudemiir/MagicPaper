import Foundation
import FirebaseFirestore

/// `memberships/{uid}`, `families/{fid}/members/{uid}`, `invites/{code}` (FAZ 18).
/// Biçim ve yetkiler `firebase/firestore.rules`'ta.
struct FirestoreFamilyDirectory: FamilyDirectory {
    private var db: Firestore { Firestore.firestore() }

    private func members(_ familyID: String) -> CollectionReference {
        db.collection("families").document(familyID).collection("members")
    }

    func membership(for uid: String) async throws -> FamilyMembership? {
        let link = try await db.collection("memberships").document(uid).getDocument(source: .server)
        guard link.exists, let familyID = link.data()?["familyID"] as? String else { return nil }
        let row = try await members(familyID).document(uid).getDocument(source: .server)
        guard let raw = row.data()?["role"] as? String, let role = FamilyRole(rawValue: raw) else {
            // Kurucu çıkardıysa üyelik bağı kalmış olabilir: artık üye değil.
            return nil
        }
        return FamilyMembership(familyID: familyID, role: role)
    }

    func members(of familyID: String) async throws -> [FamilyMember] {
        let snapshot = try await members(familyID).getDocuments(source: .server)
        return snapshot.documents.compactMap { document in
            let data = document.data()
            guard let raw = data["role"] as? String, let role = FamilyRole(rawValue: raw) else { return nil }
            return FamilyMember(uid: document.documentID,
                                displayName: data["displayName"] as? String ?? "",
                                role: role)
        }
    }

    func ensureFounder(familyID: String, displayName: String) async throws {
        let row = members(familyID).document(familyID)
        if try await row.getDocument(source: .server).exists {
            try await row.updateData(["displayName": displayName])
        } else {
            try await row.setData(["role": FamilyRole.admin.rawValue, "displayName": displayName,
                                   "joinedAt": FieldValue.serverTimestamp()])
        }
    }

    func createInvite(familyID: String, role: FamilyRole, inviterName: String, now: Date) async throws -> FamilyInvite {
        let invite = FamilyInvite(code: FamilyInviteCode.make(), familyID: familyID, role: role,
                                  inviterName: inviterName, expiresAt: now.addingTimeInterval(FamilyInviteCode.lifetime))
        try await db.collection("invites").document(invite.code).setData([
            "familyID": familyID,
            "role": role.rawValue,
            "inviterName": inviterName,
            "expiresAt": Timestamp(date: invite.expiresAt),
            "createdAt": FieldValue.serverTimestamp(),
        ])
        return invite
    }

    func invites(of familyID: String) async throws -> [FamilyInvite] {
        let snapshot = try await db.collection("invites").whereField("familyID", isEqualTo: familyID)
            .getDocuments(source: .server)
        return snapshot.documents.compactMap { Self.invite(code: $0.documentID, data: $0.data()) }
    }

    func invite(code: String) async throws -> FamilyInvite? {
        let document = try await db.collection("invites").document(code).getDocument(source: .server)
        guard let data = document.data() else { return nil }
        return Self.invite(code: code, data: data)
    }

    func deleteInvite(code: String) async throws {
        try await db.collection("invites").document(code).delete()
    }

    func accept(_ invite: FamilyInvite, uid: String, displayName: String) async throws {
        let batch = db.batch()
        batch.setData(["role": invite.role.rawValue, "displayName": displayName,
                       "joinedAt": FieldValue.serverTimestamp(), "invite": invite.code],
                      forDocument: members(invite.familyID).document(uid))
        batch.setData(["familyID": invite.familyID, "joinedAt": FieldValue.serverTimestamp()],
                      forDocument: db.collection("memberships").document(uid))
        batch.deleteDocument(db.collection("invites").document(invite.code))
        try await batch.commit()
    }

    func setRole(_ role: FamilyRole, for uid: String, in familyID: String) async throws {
        try await members(familyID).document(uid).updateData(["role": role.rawValue])
    }

    func remove(uid: String, from familyID: String) async throws {
        // Önce üye satırı: üyelik bağı kalsa bile hiçbir şeye erişmez.
        try await members(familyID).document(uid).delete()
        try await db.collection("memberships").document(uid).delete()
        try? await db.collection("families").document(familyID).collection("voiceConsents").document(uid).delete()
    }

    func dissolve(familyID: String) async throws {
        for member in try await members(of: familyID) where member.uid != familyID {
            try await db.collection("memberships").document(member.uid).delete()
            try await members(familyID).document(member.uid).delete()
        }
        try? await members(familyID).document(familyID).delete()
        for invite in try await invites(of: familyID) {
            try await deleteInvite(code: invite.code)
        }
    }

    private static func invite(code: String, data: [String: Any]) -> FamilyInvite? {
        guard let familyID = data["familyID"] as? String,
              let raw = data["role"] as? String, let role = FamilyRole(rawValue: raw),
              let expires = (data["expiresAt"] as? Timestamp)?.dateValue() else { return nil }
        return FamilyInvite(code: code, familyID: familyID, role: role,
                            inviterName: data["inviterName"] as? String ?? "", expiresAt: expires)
    }
}
