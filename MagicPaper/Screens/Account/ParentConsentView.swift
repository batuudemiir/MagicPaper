import SwiftUI

/// Onboarding · **Ebeveyn onayı** (FAZ 16 §2): the KVKK consent, versioned.
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

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MP.S.x6) {
                    VStack(alignment: .leading, spacing: MP.S.x3) {
                        Text(ParentConsentText.title)
                            .font(MP.F.displayLG())
                            .mpTightTracking(32)
                            .foregroundStyle(MP.C.textTitle)
                            .accessibilityAddTraits(.isHeader)
                        Text(ParentConsentText.lead)
                            .font(MP.F.bodyLG())
                            .foregroundStyle(MP.C.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, MP.S.x7)

                    LegacyMPCard(padding: MP.S.x5) {
                        VStack(alignment: .leading, spacing: MP.S.x5) {
                            ForEach(ParentConsentText.sections) { section in
                                VStack(alignment: .leading, spacing: MP.S.x1) {
                                    Text(section.title)
                                        .font(MP.F.bodyMD(.bold))
                                        .foregroundStyle(MP.C.textTitle)
                                        .accessibilityAddTraits(.isHeader)
                                    Text(section.body)
                                        .font(MP.F.bodyMD())
                                        .foregroundStyle(MP.C.textBody)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    LegacyMPCard(padding: 0) {
                        VStack(spacing: 0) {
                            LegacyMPListRow(symbol: "eye.slash", title: AccountCopy.usageRowTitle,
                                      description: AccountCopy.usageRowBody) {
                                MPSwitch(isOn: $shareUsage, label: AccountCopy.usageRowTitle)
                            }
                            LegacyMPRowDivider()
                            LegacyMPListRow(symbol: "checkmark.shield", title: AccountCopy.agreeLabel,
                                      description: ParentConsentText.agreement) {
                                MPSwitch(isOn: $agreed, label: ParentConsentText.agreement)
                            }
                        }
                    }

                    Text(AccountCopy.versionLine(ParentConsentText.version))
                        .font(MP.F.caption(.regular))
                        .foregroundStyle(MP.C.textMuted)
                }
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.bottom, MP.S.x6)
            }

            LegacyMPButton(title: AccountCopy.agreeButton, size: .lg, iconAfter: "arrow.right",
                     fullWidth: true, isDisabled: !agreed || saving) {
                saving = true
                Task {
                    await account.acceptConsent(shareUsageData: shareUsage)
                    saving = false
                }
            }
            .padding(.horizontal, MP.S.screenGutter)
            .padding(.vertical, MP.S.x3)
        }
        .mpScreenBackground()
    }
}

/// Signed in on a device without children: the account's are on their way.
struct AccountRestoreView: View {
    @ObservedObject private var account = AccountService.shared
    @State private var failed = false

    var body: some View {
        VStack(spacing: MP.S.x6) {
            Spacer(minLength: 0)
            if failed {
                MPIcon("wifi.slash", size: MP.G.xxl, weight: .semibold)
                    .foregroundStyle(MP.C.textMuted)
                    .accessibilityHidden(true)
            } else {
                ProgressView()
                    .controlSize(.large)
                    .tint(MP.C.brand)
                    .accessibilityHidden(true)
            }
            VStack(spacing: MP.S.x2) {
                Text(failed ? AccountCopy.restoreFailedTitle : AccountCopy.restoringTitle)
                    .font(MP.F.displayMD())
                    .foregroundStyle(MP.C.textTitle)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(failed ? AccountCopy.restoreFailedBody : AccountCopy.restoringBody)
                    .font(MP.F.bodyMD())
                    .foregroundStyle(MP.C.textMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if failed {
                VStack(spacing: MP.S.x2) {
                    LegacyMPButton(title: AccountCopy.retry, size: .md, fullWidth: true) {
                        failed = false
                        Task { await attempt() }
                    }
                    LegacyMPButton(title: AccountCopy.startFresh, variant: .ghost, size: .md) {
                        account.sync.settleRestoreWithoutPull()
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, MP.S.screenGutter)
        .mpScreenBackground()
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
            .tint(MP.C.brand)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .mpScreenBackground()
            .accessibilityLabel("Yükleniyor")
    }
}
