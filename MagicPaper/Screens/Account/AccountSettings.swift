import SwiftUI

/// Ayarlar · Hesap satırları (FAZ 16): who is signed in, the sync, sign out.
struct AccountStatusRows: View {
    @ObservedObject private var account = AccountService.shared
    var onSignOut: () -> Void

    var body: some View {
        if let signedIn = account.account {
            Button { Task { await account.sync.syncNow() } } label: {
                MPListRow(systemImage: "person", tone: .lav,
                          title: AccountCopy.signedIn(with: signedIn.provider), subtitle: syncLine) {
                    if account.sync.status == .syncing {
                        ProgressView().tint(MPColor.actionPrimary).accessibilityHidden(true)
                    }
                }
            }
            .buttonStyle(MPPressStyle(.highlight))
            .accessibilityElement(children: .combine)
            .accessibilityHint("Eşitlemek için dokun")
            MPRowDivider(area: .parent)
            ParentRowButton(systemImage: "rectangle.portrait.and.arrow.right", tone: .gray,
                            title: AccountCopy.signOut, action: onSignOut)
        } else {
            ParentRowButton(systemImage: "person", tone: .yellow, title: AccountCopy.notSignedIn,
                            subtitle: AccountCopy.deferFootnote, action: { account.deferredSignIn = false })
        }
    }

    private var syncLine: String {
        switch account.sync.status {
        case .idle: return AccountCopy.syncIdle
        case .syncing: return AccountCopy.syncing
        case .offline: return AccountCopy.syncOffline
        case .failed: return AccountCopy.syncFailed
        case .synced(let date):
            return AccountCopy.synced(at: date.formatted(.dateTime.hour().minute()))
        }
    }
}

/// "Çıkış yap" onayı.
struct AccountSignOutSheet: View {
    @ObservedObject private var account = AccountService.shared
    var onClose: () -> Void
    @State private var working = false
    @State private var message: String?

    var body: some View {
        MPSheet(title: AccountCopy.signOut, onClose: working ? nil : onClose) {
            VStack(alignment: .leading, spacing: MP.S.x3) {
                Text(AccountCopy.signOutBody)
                    .font(MP.F.bodyMD())
                    .foregroundStyle(MP.C.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                if let message {
                    Text(message)
                        .font(MP.F.bodySM(.semibold))
                        .foregroundStyle(MP.C.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } footer: {
            VStack(spacing: MP.S.x2) {
                LegacyMPButton(title: AccountCopy.signOut, tone: .play, size: .lg, fullWidth: true,
                         isDisabled: working) {
                    working = true
                    message = nil
                    Task {
                        do {
                            try await account.signOut()
                        } catch {
                            message = AccountCopy.message(for: error)
                        }
                        working = false
                    }
                }
                LegacyMPButton(title: "Vazgeç", variant: .ghost, size: .sm, isDisabled: working, action: onClose)
            }
        }
    }
}

/// "Hesabı sil" onayı ve ilerleyişi (FAZ 16 §4, Apple 5.1.1(v)).
struct AccountDeletionSheet: View {
    @ObservedObject private var account = AccountService.shared
    var onClose: () -> Void
    @State private var step: AccountService.DeletionStep?
    @State private var message: String?

    var body: some View {
        MPSheet(title: AccountCopy.deleteAccount, onClose: step == nil ? onClose : nil) {
            VStack(alignment: .leading, spacing: MP.S.x3) {
                Text(AccountCopy.deleteAccountBody)
                    .font(MP.F.bodyMD())
                    .foregroundStyle(MP.C.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                if let step {
                    HStack(spacing: MP.S.x2) {
                        ProgressView().tint(MP.C.brand).accessibilityHidden(true)
                        Text(AccountCopy.deletionStep(step))
                            .font(MP.F.bodySM(.semibold))
                            .foregroundStyle(MP.C.textBody)
                    }
                    .accessibilityElement(children: .combine)
                }
                if let message {
                    Text(message)
                        .font(MP.F.bodySM(.semibold))
                        .foregroundStyle(MP.C.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } footer: {
            VStack(spacing: MP.S.x2) {
                LegacyMPButton(title: AccountCopy.deleteConfirm, tone: .play, size: .lg, fullWidth: true,
                         isDisabled: step != nil) {
                    message = nil
                    Task {
                        do {
                            try await account.deleteAccount { step = $0 }
                        } catch {
                            step = nil
                            if (error as? AccountError) != .cancelled {
                                message = AccountCopy.deleteFailed
                            }
                        }
                    }
                }
                LegacyMPButton(title: "Vazgeç", variant: .ghost, size: .sm, isDisabled: step != nil, action: onClose)
            }
        }
    }
}
