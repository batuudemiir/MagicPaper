import SwiftUI
import AuthenticationServices

/// 05 · Giriş (`Giris`). Onboarding · **Giriş** (FAZ 16): Karşılama → Giriş → Ebeveyn onayı → Profil.
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
        ZStack {
            MPGlowBackground(style: .dawn)
            ScrollView(showsIndicators: false) {
                VStack(spacing: MPSpacing.xxl) {
                    VStack(spacing: MPSpacing.xl) {
                        Image("Brand/appIconLight")
                            .resizable().scaledToFit()
                            .frame(width: 128, height: 128)
                            .clipShape(RoundedRectangle(cornerRadius: MPRadius.hero, style: .continuous))
                            .mpShadow(.card)
                            .accessibilityHidden(true)
                        Image("Brand/wordmarkLight")
                            .resizable().scaledToFit()
                            .frame(maxWidth: 200)
                            .accessibilityLabel("MagicPaper")
                        VStack(spacing: MPSpacing.md) {
                            Text(AccountCopy.signInTitle)
                                .mpText(.largeTitle)
                                .foregroundStyle(MPColor.textPrimary)
                                .accessibilityAddTraits(.isHeader)
                            Text(AccountCopy.signInBody)
                                .mpText(.body)
                                .foregroundStyle(MPColor.textSecondary)
                        }
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, MPSpacing.xxxl)

                    if wasOffline {
                        MPOfflineNotice(showsMascot: false)
                    }

                    VStack(spacing: MPSpacing.md) {
                        AppleSignInButton(isBusy: working == .apple) { gateFor = .apple }
                            .frame(height: MPSize.buttonHeightAuth)
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(AccountCopy.continueWithApple)

                        // Ürün kararı: Apple + Google (tasarımdaki "E-posta ile
                        // devam et" yerine). Aynı dış çizgili görünüm.
                        if account.googleAvailable {
                            MPButton(title: AccountCopy.continueWithGoogle, systemImage: "g.circle",
                                     kind: .outline, size: .auth, fullWidth: true) {
                                gateFor = .google
                            }
                            .disabled(working != nil)
                        }

                        if FirebaseBackend.emulatorHost != nil {
                            MPButton(title: AccountCopy.emulatorSignIn, kind: .soft, size: .auth,
                                     fullWidth: true) {
                                Task { await signIn(.emulator) }
                            }
                            .disabled(working != nil)
                        }

                        if let message, !wasOffline {
                            Text(message)
                                .mpText(.footnote)
                                .foregroundStyle(MPColor.statusDanger)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.updatesFrequently)
                        }

                        Text(.init(AccountCopy.signInFootnote))
                            .mpText(.caption)
                            .foregroundStyle(MPColor.textSecondary)
                            .tint(MPColor.actionPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, MPSpacing.xs)
                    }

                    // A device that already has its children need not wait for
                    // a connection to read tonight's story.
                    if wasOffline && !profiles.profiles.isEmpty {
                        VStack(spacing: MPSpacing.xs) {
                            MPButton(title: AccountCopy.deferSignIn, kind: .ghost) {
                                account.deferredSignIn = true
                            }
                            Text(AccountCopy.deferFootnote)
                                .mpText(.caption)
                                .foregroundStyle(MPColor.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.bottom, MPSpacing.xxl)
            }
        }
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
            wasOffline = (error as? AccountError) == .offline
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
        button.cornerRadius = MPSize.buttonHeightAuth / 2
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
