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

/// "Çıkış yap" onayı: ebeveyn alanında alttan açılan sakin bir kart.
struct AccountSignOutSheet: View {
    @ObservedObject private var account = AccountService.shared
    var onClose: () -> Void
    @State private var working = false
    @State private var message: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            MPColor.textPrimary.opacity(0.35).ignoresSafeArea()
                .onTapGesture { if !working { onClose() } }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MPSpacing.lg) {
                Text(AccountCopy.signOut).mpText(.title3).foregroundStyle(MPColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(AccountCopy.signOutBody).mpText(.body).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let message {
                    Text(message).mpText(.footnote).foregroundStyle(MPColor.statusDanger)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VStack(spacing: MPSpacing.xs) {
                    MPButton(title: AccountCopy.signOut, kind: .danger, fullWidth: true, isLoading: working) {
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
                    MPButton(title: "Vazgeç", kind: .ghost, action: onClose).disabled(working)
                }
            }
            .padding(MPSpacing.xl)
            .padding(.bottom, MPSpacing.lg)
            .background(MPColor.backgroundParent, in: UnevenRoundedRectangle(topLeadingRadius: MPRadius.sheet, topTrailingRadius: MPRadius.sheet))
            // VoiceOver arkadaki ekrana kaçmaz; iki parmakla "Z" kapatır.
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
            .accessibilityAction(.escape) { if !working { onClose() } }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

/// 39 · Hesabı sil (`HesapSil`), FAZ 16 §4, Apple 5.1.1(v): neyin silineceği,
/// önce PDF indirme yolu, "SİL" yazarak onay ve silmenin ilerleyişi.
/// Tasarımdaki ses kaydı ve paylaşım bağlantısı satırları yalnızca o
/// özellikler açıkken görünür (FAZ 18).
struct AccountDeletionSheet: View {
    @ObservedObject private var account = AccountService.shared
    @ObservedObject private var profiles = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    var onClose: () -> Void
    @State private var step: AccountService.DeletionStep?
    @State private var message: String?
    @State private var typed = ""
    @State private var exportFile: MPExportFile?
    @State private var isExporting = false

    private static let confirmWord = "SİL"
    private var confirmed: Bool {
        typed.trimmingCharacters(in: .whitespaces).uppercased(with: Locale(identifier: "tr_TR")) == Self.confirmWord
    }

    private var lines: [String] {
        var out = ["\(profiles.profiles.count) çocuk profili ve kahramanları",
                   "\(storyManager.stories.count) masal, seriler ve okuma ilerlemesi"]
        if FamilyFeatureAccess.isEnabled(.voiceRecording) { out.append("Kendi sesinle yaptığın kayıtlar") }
        if FamilyFeatureAccess.isEnabled(.shareLink) { out.append("Paylaşım bağlantıları") }
        return out
    }

    var body: some View {
        VStack(spacing: 0) {
            ParentHeader(title: AccountCopy.deleteAccount, onBack: step == nil ? onClose : nil)
                .padding(.horizontal, MPSpacing.screenH)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MPSpacing.xl) {
                    MPIcon("trash", size: 30, weight: .semibold)
                        .foregroundStyle(MPColor.statusDanger)
                        .frame(width: 64, height: 64)
                        .background(MPColor.statusDangerSoft, in: RoundedRectangle(cornerRadius: MPRadius.tile, style: .continuous))
                        .accessibilityHidden(true)
                    Text("Her şey kalıcı olarak silinecek").mpText(.title1).foregroundStyle(MPColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    MPCard(area: .parent, padding: MPSpacing.lg) {
                        VStack(alignment: .leading, spacing: MPSpacing.md) {
                            ForEach(lines, id: \.self) { line in
                                HStack(spacing: MPSpacing.md) {
                                    MPIcon("xmark", size: 14, weight: .bold)
                                        .foregroundStyle(MPColor.statusDanger)
                                        .accessibilityHidden(true)
                                    Text(line).mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                                }
                            }
                        }
                    }

                    Text("Aboneliğin App Store üzerinden ayrıca iptal edilmeli. Silmeden önce masalları PDF olarak indirebilirsin.")
                        .mpText(.footnote).fontWeight(.regular)
                        .foregroundStyle(MPColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !storyManager.stories.isEmpty {
                        Button(isExporting ? "PDF hazırlanıyor" : "Önce masalları indir", action: exportBook)
                            .mpText(.bodyStrong)
                            .foregroundStyle(MPColor.actionPrimary)
                            .disabled(isExporting || step != nil)
                            .frame(minHeight: MPSize.minTouchParent)
                    }

                    MPTextField(label: "Onaylamak için \(Self.confirmWord) yaz", placeholder: Self.confirmWord,
                                text: $typed, isError: confirmed)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .disabled(step != nil)

                    Text(AccountCopy.deleteAccountBody)
                        .mpText(.caption).fontWeight(.regular)
                        .foregroundStyle(MPColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let step {
                        HStack(spacing: MPSpacing.sm) {
                            ProgressView().tint(MPColor.actionPrimary).accessibilityHidden(true)
                            Text(AccountCopy.deletionStep(step)).mpText(.callout).foregroundStyle(MPColor.textPrimary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    if let message {
                        Text(message).mpText(.footnote).foregroundStyle(MPColor.statusDanger)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.vertical, MPSpacing.lg)
            }

            VStack(spacing: MPSpacing.xs) {
                MPButton(title: AccountCopy.deleteConfirm, kind: .danger, fullWidth: true, isLoading: step != nil) {
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
                .disabled(!confirmed)
                MPButton(title: "Vazgeç", kind: .ghost, action: onClose).disabled(step != nil)
            }
            .padding(.horizontal, MPSpacing.xl)
            .padding(.vertical, MPSpacing.md)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
        .sheet(item: $exportFile) { file in ShareSheet(items: [file.url]) }
    }

    private func exportBook() {
        guard !isExporting else { return }
        isExporting = true
        let snapshot = storyManager.stories
        Task.detached(priority: .userInitiated) {
            let url = await MPStoryPDF.makePDF(stories: snapshot, fileName: "magicpaper-masallar.pdf")
            await MainActor.run {
                isExporting = false
                if let url { exportFile = MPExportFile(url: url) }
            }
        }
    }
}
