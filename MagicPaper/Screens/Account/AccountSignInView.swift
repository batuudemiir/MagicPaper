import SwiftUI
import AuthenticationServices

/// Onboarding · **Giriş** (FAZ 16): Karşılama → Giriş → Ebeveyn onayı → Profil.
///
/// Both buttons sit behind the parental gate: signing in opens Apple's or
/// Google's own sheet, which in a Kids app is a parent-only door.
struct AccountSignInView: View {
    @ObservedObject private var account = AccountService.shared
    @ObservedObject private var profiles = ProfileManager.shared
    @State private var gateFor: SignInProvider?
    @State private var working: SignInProvider?
    @State private var message: String?
    @State private var wasOffline = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MP.S.x7) {
                VStack(spacing: MP.S.x5) {
                    MPIcon("person.crop.circle.badge.checkmark", size: MP.G.hero, weight: .semibold)
                        .foregroundStyle(MP.C.brand)
                        .frame(width: 108, height: 108)
                        .background(
                            RoundedRectangle(cornerRadius: MP.R.xxl, style: .continuous)
                                .fill(MP.C.brandSoft))
                        .accessibilityHidden(true)

                    VStack(spacing: MP.S.x3) {
                        Text(AccountCopy.signInTitle)
                            .font(MP.F.displayLG())
                            .mpTightTracking(32)
                            .foregroundStyle(MP.C.textTitle)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        Text(AccountCopy.signInBody)
                            .font(MP.F.bodyLG())
                            .foregroundStyle(MP.C.textMuted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, MP.S.x10)

                VStack(spacing: MP.S.x3) {
                    AppleSignInButton(isBusy: working == .apple) { gateFor = .apple }
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(AccountCopy.continueWithApple)

                    if account.googleAvailable {
                        MPButton(title: AccountCopy.continueWithGoogle, variant: .outline, size: .md,
                                 icon: "g.circle", fullWidth: true, isDisabled: working != nil) {
                            gateFor = .google
                        }
                        .accessibilityLabel(AccountCopy.continueWithGoogle)
                    }

                    if FirebaseBackend.emulatorHost != nil {
                        MPButton(title: AccountCopy.emulatorSignIn, variant: .soft, size: .md,
                                 fullWidth: true, isDisabled: working != nil) {
                            Task { await signIn(.emulator) }
                        }
                    }

                    if let message {
                        Text(message)
                            .font(MP.F.bodySM(.semibold))
                            .foregroundStyle(MP.C.danger)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.updatesFrequently)
                    }

                    Text(AccountCopy.signInFootnote)
                        .font(MP.F.caption(.regular))
                        .foregroundStyle(MP.C.textMuted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // A device that already has its children need not wait for
                // a connection to read tonight's story.
                if wasOffline && !profiles.profiles.isEmpty {
                    VStack(spacing: MP.S.x2) {
                        MPButton(title: AccountCopy.deferSignIn, variant: .ghost, size: .md) {
                            account.deferredSignIn = true
                        }
                        Text(AccountCopy.deferFootnote)
                            .font(MP.F.caption(.regular))
                            .foregroundStyle(MP.C.textMuted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, MP.S.screenGutter)
            .padding(.bottom, MP.S.x7)
        }
        .mpScreenBackground()
        .fullScreenCover(item: $gateFor) { provider in
            ParentalGateView(onSuccess: {
                gateFor = nil
                // The gate's cover must be gone before Apple's or Google's
                // sheet can be presented.
                Task {
                    try? await Task.sleep(nanoseconds: 450_000_000)
                    await signIn(provider)
                }
            }, onCancel: { gateFor = nil })
        }
    }

    private func signIn(_ provider: SignInProvider) async {
        guard working == nil else { return }
        working = provider
        message = nil
        defer { working = nil }
        do {
            try await account.signIn(with: provider)
        } catch {
            message = AccountCopy.message(for: error)
            if (error as? AccountError) == .offline { wasOffline = true }
        }
    }
}

extension SignInProvider: Identifiable {
    var id: String { rawValue }
}

/// Apple's own button (HIG requires it), driving our sign-in flow.
private struct AppleSignInButton: UIViewRepresentable {
    var isBusy: Bool
    var action: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: .continue, authorizationButtonStyle: .black)
        button.cornerRadius = MP.R.button
        button.addTarget(context.coordinator, action: #selector(Coordinator.tap), for: .touchUpInside)
        return button
    }

    func updateUIView(_ button: ASAuthorizationAppleIDButton, context: Context) {
        context.coordinator.action = action
        button.isEnabled = !isBusy
        button.alpha = isBusy ? 0.6 : 1
    }

    final class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func tap() { action() }
    }
}
