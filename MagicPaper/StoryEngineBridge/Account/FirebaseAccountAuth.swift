import Foundation
import AuthenticationServices
import CryptoKit
import UIKit
import OSLog
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "AccountAuth")

/// Signing the parent in and out, behind a seam the tests can replace.
@MainActor
protocol AccountAuth: AnyObject {
    var current: ParentAccount? { get }
    /// Whether this build can offer Google (client id and URL scheme set).
    var googleAvailable: Bool { get }
    func signIn(with provider: SignInProvider) async throws -> ParentAccount
    /// A fresh sign-in with the same provider, which deleting the account
    /// requires; for Apple it also revokes the app's Apple token (Apple's
    /// account-deletion rule).
    func reauthenticateForDeletion() async throws
    func deleteUser() async throws
    func signOut() throws
    /// The account's e-mail, only when the provider verified it (FAZ 18,
    /// Haftalık özet). Kept by Firebase Auth, not by the app.
    var verifiedEmail: String? { get }
}

extension AccountAuth {
    var verifiedEmail: String? { nil }
}

/// Firebase Auth with Sign in with Apple and Google.
@MainActor
final class FirebaseAccountAuth: AccountAuth {
    private var appleFlow: AppleSignInFlow?

    var verifiedEmail: String? {
        guard let user = Auth.auth().currentUser, user.isEmailVerified, let email = user.email, !email.isEmpty else { return nil }
        return email
    }

    var current: ParentAccount? {
        guard let user = Auth.auth().currentUser else { return nil }
        if FirebaseBackend.emulatorHost != nil, UserDefaults.standard.bool(forKey: Self.emulatorFlagKey) {
            return ParentAccount(uid: user.uid, provider: .emulator)
        }
        let provider = user.providerData.lazy.compactMap { SignInProvider(firebaseProviderID: $0.providerID) }.first
        return ParentAccount(uid: user.uid, provider: provider ?? .apple)
    }

    var googleAvailable: Bool { Self.googleClientID != nil }

    /// The OAuth client id from `GoogleService-Info.plist`, when its reversed
    /// form is also registered as a URL scheme. Without the scheme
    /// GoogleSignIn raises an exception instead of an error, so the button
    /// is not offered at all.
    static var googleClientID: String? {
        guard let clientID = FirebaseApp.app()?.options.clientID, !clientID.isEmpty else { return nil }
        let reversed = clientID.split(separator: ".").reversed().joined(separator: ".")
        let types = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] ?? []
        let schemes = types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        return schemes.contains(reversed) ? clientID : nil
    }

    func signIn(with provider: SignInProvider) async throws -> ParentAccount {
        let credential: AuthCredential
        switch provider {
        case .apple:
            let result = try await runAppleFlow()
            credential = result.credential
        case .google:
            credential = try await googleCredential()
        case .emulator:
            credential = try emulatorCredential()
        }
        do {
            let result = try await Auth.auth().signIn(with: credential)
            if provider == .emulator { UserDefaults.standard.set(true, forKey: Self.emulatorFlagKey) }
            return ParentAccount(uid: result.user.uid, provider: provider)
        } catch {
            throw Self.map(error)
        }
    }

    func reauthenticateForDeletion() async throws {
        guard let user = Auth.auth().currentUser, let account = current else { throw AccountError.failed }
        do {
            switch account.provider {
            case .apple:
                let result = try await runAppleFlow()
                try await user.reauthenticate(with: result.credential)
                if let code = result.authorizationCode {
                    try await Auth.auth().revokeToken(withAuthorizationCode: code)
                }
            case .google:
                try await user.reauthenticate(with: try await googleCredential())
            case .emulator:
                return
            }
        } catch AccountError.cancelled {
            throw AccountError.cancelled
        } catch {
            logger.notice("Yeniden giriş yapılamadı")
            throw AccountError.reauthenticationFailed
        }
    }

    func deleteUser() async throws {
        guard let user = Auth.auth().currentUser else { return }
        do { try await user.delete() } catch { throw Self.map(error) }
    }

    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        UserDefaults.standard.removeObject(forKey: Self.emulatorFlagKey)
        do { try Auth.auth().signOut() } catch { throw AccountError.failed }
    }

    // MARK: - Apple

    private func runAppleFlow() async throws -> AppleSignInFlow.Result {
        let flow = AppleSignInFlow()
        appleFlow = flow
        defer { appleFlow = nil }
        return try await flow.run()
    }

    // MARK: - Google

    private func googleCredential() async throws -> AuthCredential {
        guard let clientID = Self.googleClientID else { throw AccountError.googleUnavailable }
        guard let presenter = Self.topViewController() else { throw AccountError.failed }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = result.user.idToken?.tokenString else { throw AccountError.failed }
            return GoogleAuthProvider.credential(withIDToken: idToken,
                                                 accessToken: result.user.accessToken.tokenString)
        } catch let error as NSError where error.domain == kGIDSignInErrorDomain
                    && error.code == GIDSignInError.canceled.rawValue {
            throw AccountError.cancelled
        } catch let error as AccountError {
            throw error
        } catch {
            throw Self.map(error)
        }
    }

    // MARK: - Emulator (DEBUG)

    static let emulatorFlagKey = "mp_emulatorAccount"

    /// The Auth emulator accepts an unsigned Google id token written as
    /// JSON. Only ever built when the app points at the emulator.
    private func emulatorCredential() throws -> AuthCredential {
        #if DEBUG
        guard FirebaseBackend.emulatorHost != nil else { throw AccountError.failed }
        let sub = UserDefaults.standard.string(forKey: "MPEmulatorAccount") ?? "test-parent"
        let token = #"{"sub":"\#(sub)","email":"\#(sub)@example.test","email_verified":true}"#
        return GoogleAuthProvider.credential(withIDToken: token, accessToken: "")
        #else
        throw AccountError.failed
        #endif
    }

    // MARK: - Helpers

    static func map(_ error: Error) -> AccountError {
        if let error = error as? AccountError { return error }
        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain, let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .networkError: return .offline
            case .requiresRecentLogin: return .reauthenticationFailed
            default: return .failed
            }
        }
        if nsError.domain == NSURLErrorDomain { return .offline }
        return .failed
    }

    static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first
        var top = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

/// One Sign in with Apple request, nonce included. Asks for neither name nor
/// e-mail: the account needs neither.
@MainActor
final class AppleSignInFlow: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    struct Result {
        let credential: AuthCredential
        let authorizationCode: String?
    }

    private var continuation: CheckedContinuation<Result, Error>?
    private var rawNonce = ""

    func run() async throws -> Result {
        rawNonce = Self.randomNonce()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        // E-posta yalnızca Haftalık özet için (FAZ 18, karar: giriş hesabının
        // e-postası). Apple onu yalnızca ilk girişte verir; daha önce girmiş
        // hesaplarda olmayabilir. Ad istenmez.
        request.requestedScopes = [.email]
        request.nonce = Self.sha256(rawNonce)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        FirebaseAccountAuth.topViewController()?.view.window ?? ASPresentationAnchor()
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let apple = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = apple.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            finish(.failure(AccountError.failed))
            return
        }
        let credential = OAuthProvider.appleCredential(withIDToken: token, rawNonce: rawNonce, fullName: nil)
        let code = apple.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
        finish(.success(Result(credential: credential, authorizationCode: code)))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let code = (error as? ASAuthorizationError)?.code
        finish(.failure(code == .canceled ? AccountError.cancelled : AccountError.failed))
    }

    private func finish(_ result: Swift.Result<Result, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }

    static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var generator = SystemRandomNumberGenerator()
        return String((0..<length).map { _ in charset[Int.random(in: 0..<charset.count, using: &generator)] })
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
