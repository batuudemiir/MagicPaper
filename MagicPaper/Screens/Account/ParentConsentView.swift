import SwiftUI

/// 06 · Ebeveyn onayı (`EbeveynOnayi`). Onboarding · **Ebeveyn onayı** (FAZ 16 §2): the KVKK consent, versioned.
///
/// The whole text is on the screen, not behind a link: leaving the app is a
/// parent-gated door in a Kids app, and the parent should not need it to
/// know what they agree to. The reading-sharing switch is shown here, on, so
/// the default the product chose is a default the parent saw.
struct ParentConsentView: View {
    @ObservedObject private var account = AccountService.shared
    @State private var shareUsage = true
    @State private var agreed = false
    @State private var saving = false
    @State private var showFullText = false
    @State private var showJoin = false

    /// 06 · Ebeveyn onayı: neyi neden tuttuğumuzun üç satırlık özeti. Tam
    /// metin "Aydınlatma metni"nde, uygulamanın içinde (dışarı link yok).
    private let summary: [(icon: String, tone: MPWorldTone, title: String, body: String)] = [
        // Tasarımda "Sadece ad ve yaş aralığı"; sevdiği şeyler ve Masal ailem
        // de saklandığı için başlık doğru olanı söylüyor (İrem'e not).
        ("person", .green, "Ad, yaş ve sevdiği şeyler", "Fotoğraf, konum ya da ses kaydı istemiyoruz."),
        ("eye.slash", .pink, "Reklam ve takip yok", "Uygulamada reklam ve üçüncü taraf takip aracı yok."),
        ("trash", .sky, "İstediğin an silebilirsin", "Ayarlar'dan tüm verileri tek dokunuşla silersin.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            MPTopBar(title: "Ebeveyn onayı") { EmptyView() }
                .padding(.horizontal, MPSpacing.screenH)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MPSpacing.xl) {
                    HStack(spacing: MPSpacing.lg) {
                        MascotImage(mascot: .calm, width: 80)
                            .accessibilityHidden(true)
                        Text("Çocuğunun verileri güvende")
                            .mpText(.largeTitle)
                            .foregroundStyle(MPColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                    }
                    Text("Masal yazabilmek için çok az şey bilmemiz gerekiyor. Neyi neden tuttuğumuz aşağıda.")
                        .mpText(.body)
                        .foregroundStyle(MPColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    MPCard(padding: MPSpacing.lg) {
                        VStack(alignment: .leading, spacing: MPSpacing.lg) {
                            ForEach(summary, id: \.title) { row in
                                HStack(alignment: .top, spacing: MPSpacing.md) {
                                    MPIconTile(systemImage: row.icon, tone: row.tone, size: 44)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                                        Text(row.title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                                        Text(row.body).mpText(.callout).fontWeight(.regular)
                                            .foregroundStyle(MPColor.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        MPCheckbox(isOn: $agreed, label: ParentConsentText.agreement)
                        Button("Aydınlatma metni") { showFullText = true }
                            .mpText(.callout)
                            .foregroundStyle(MPColor.actionPrimary)
                            .underline()
                            .padding(.leading, (MPSpacing.xxxl + MPSpacing.xs))
                            .frame(minHeight: MPSize.minTouchParent)
                    }

                    // Okuma bilgisi paylaşımı: ürünün seçtiği varsayılan,
                    // ebeveynin gördüğü bir varsayılan olsun diye burada (FAZ 16).
                    MPCard(padding: MPSpacing.lg) {
                        Toggle(isOn: $shareUsage) {
                            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                                Text(AccountCopy.usageRowTitle).mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                                Text(AccountCopy.usageRowBody).mpText(.footnote).fontWeight(.regular)
                                    .foregroundStyle(MPColor.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .toggleStyle(MPSwitchStyle())
                    }
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.vertical, MPSpacing.lg)
            }

            MPButton(title: AccountCopy.agreeLabel, fullWidth: true, isLoading: saving) {
                saving = true
                Task {
                    await account.acceptConsent(shareUsageData: shareUsage)
                    saving = false
                }
            }
            .disabled(!agreed)
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.top, MPSpacing.md)
            .padding(.bottom, FamilyFeatureAccess.isEnabled(.familyMembers) ? 0 : MPSpacing.md)

            // Davetle gelen yetişkin (FAZ 18) kendi ailesini kurmadan katılır;
            // onay ailenin kurucusunun onayıdır.
            if FamilyFeatureAccess.isEnabled(.familyMembers) {
                MPButton(title: "Bir aileye davet edildim", kind: .ghost) { showJoin = true }
                    .padding(.bottom, MPSpacing.sm)
            }
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .sheet(isPresented: $showFullText) { ConsentFullTextSheet() }
        .sheet(isPresented: $showJoin, onDismiss: { account.pendingInviteCode = nil }) {
            JoinFamilySheet(initialCode: account.pendingInviteCode, onJoined: { showJoin = false })
        }
        .onAppear { if account.pendingInviteCode != nil { showJoin = true } }
    }
}

/// "Aydınlatma metni": onay metninin tamamı, sürümüyle.
private struct ConsentFullTextSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            MPTopBar(title: "Aydınlatma metni") {
                MPCircleButton(systemImage: "xmark", accessibilityLabel: "Kapat") { dismiss() }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.md)
            ScrollView {
                VStack(alignment: .leading, spacing: MPSpacing.lg) {
                    Text(ParentConsentText.lead)
                        .mpText(.body).foregroundStyle(MPColor.textSecondary)
                    ForEach(ParentConsentText.sections) { section in
                        VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                            Text(section.title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                                .accessibilityAddTraits(.isHeader)
                            Text(section.body).mpText(.body).foregroundStyle(MPColor.textPrimary)
                        }
                    }
                    Text(AccountCopy.versionLine(ParentConsentText.version))
                        .mpText(.caption).foregroundStyle(MPColor.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(MPSpacing.xl)
            }
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationCornerRadius(MPRadius.sheet)
    }
}

/// Signed in on a device without children: the account's are on their way.
/// Bağlantı yoksa 44 · İnternet yok durumu (düşünceli Ragi, "Tekrar dene").
struct AccountRestoreView: View {
    @ObservedObject private var account = AccountService.shared
    @State private var failed = false

    var body: some View {
        Group {
            if failed {
                MPStateView(mascot: .thinking, tone: .sky,
                            title: AccountCopy.restoreFailedTitle,
                            message: AccountCopy.restoreFailedBody) {
                    MPButton(title: AccountCopy.retry, systemImage: "arrow.counterclockwise", fullWidth: true) {
                        failed = false
                        Task { await attempt() }
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    MPButton(title: AccountCopy.startFresh, kind: .ghost) {
                        account.sync.settleRestoreWithoutPull()
                    }
                }
            } else {
                VStack(spacing: MPSpacing.lg) {
                    MascotImage(mascot: .reading, width: 160).accessibilityHidden(true)
                    ProgressView().controlSize(.large).tint(MPColor.actionPrimary)
                        .accessibilityHidden(true)
                    Text(AccountCopy.restoringTitle).mpText(.title2).foregroundStyle(MPColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(AccountCopy.restoringBody).mpText(.body).foregroundStyle(MPColor.textSecondary)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, MPSpacing.xl)
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .task { await attempt() }
    }

    private func attempt() async {
        let ok = await account.sync.syncNow()
        if !ok && !account.sync.restored { failed = true }
    }
}

/// A moment's wait with nothing to decide: looking up whether the parent
/// already agreed on another device.
struct AccountWaitView: View {
    var body: some View {
        ProgressView()
            .controlSize(.large)
            .tint(MPColor.actionPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MPColor.backgroundKid.ignoresSafeArea())
            .accessibilityLabel("Yükleniyor")
    }
}
