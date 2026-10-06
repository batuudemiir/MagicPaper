import Foundation

/// The parent's account (FAZ 16). The child never signs in.
///
/// Only what the app needs to tell accounts apart: the Firebase user id and
/// how the parent signed in. No e-mail, no name — Sign in with Apple is asked
/// for neither, and what Google returns is not kept.
struct ParentAccount: Equatable, Sendable {
    let uid: String
    let provider: SignInProvider
}

enum SignInProvider: String, Sendable {
    case apple
    case google
    /// The local Firebase emulator's test account (DEBUG only).
    case emulator

    /// Firebase's provider id.
    init?(firebaseProviderID: String) {
        switch firebaseProviderID {
        case "apple.com": self = .apple
        case "google.com": self = .google
        default: return nil
        }
    }
}

enum AccountError: Error, Equatable {
    /// The parent closed the sign-in sheet. Not shown as an error.
    case cancelled
    case offline
    /// Google sign-in is not set up in this build (no client id).
    case googleUnavailable
    case failed
    /// Deleting needs a fresh sign-in, and it did not happen.
    case reauthenticationFailed
    /// There are changes on this device the account does not have yet.
    case unsentChanges
}

/// What the parent agreed to, and when (KVKK açık rıza).
///
/// The version names the text, not the app: a new text means a new consent.
/// The account keeps one record per version, written once.
struct ConsentRecord: Codable, Equatable, Sendable {
    let version: String
    let acceptedAt: Date
    /// Whether the parent left anonymous reading sharing on when agreeing.
    let shareUsageData: Bool
}

/// Where the app opens, from what is known about this device and account.
enum AppGate: Equatable {
    case intro
    case signIn
    case consent
    /// Signed in on a device with no children: the account's are on their way.
    case restoring
    case createProfile
    case selectProfile
    case app

    struct Inputs: Equatable {
        var onboardingDone: Bool
        var signedIn: Bool
        /// The parent chose to go on without signing in, offline, this launch.
        var deferredSignIn: Bool
        var consentCurrent: Bool
        /// One full pull from the account has finished (or was given up).
        var restoreSettled: Bool
        var hasProfiles: Bool
        var hasCurrentProfile: Bool
    }

    static func resolve(_ i: Inputs) -> AppGate {
        guard i.onboardingDone else { return .intro }
        if !i.signedIn {
            // Only a device that already has its children may wait for a
            // connection; a new one has nothing to open.
            guard i.deferredSignIn && i.hasProfiles else { return .signIn }
        } else {
            guard i.consentCurrent else { return .consent }
            if !i.hasProfiles && !i.restoreSettled { return .restoring }
        }
        guard i.hasProfiles else { return .createProfile }
        return i.hasCurrentProfile ? .app : .selectProfile
    }
}

/// The account's side of the sync, with the network behind it.
protocol FamilyRemote: Sendable {
    /// Records written since `highWater` (per collection), all of them when
    /// there is no mark.
    func pull(since highWater: [String: Date]) async throws -> [RemoteSyncRecord]
    func push(_ records: [RemoteSyncRecord]) async throws
    /// Every document of the family, consents included (account deletion).
    func deleteEverything() async throws
    func recordConsent(_ record: ConsentRecord) async throws
    func consent(version: String) async throws -> ConsentRecord?
}

/// Where anonymous reading events go. Nothing in it names the account.
protocol ReadingEventSink: Sendable {
    func send(_ events: [ReadingEventWire]) async throws
}
