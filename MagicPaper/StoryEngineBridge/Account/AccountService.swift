import Foundation
import Combine
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "Account")

/// The parent's account on this device (FAZ 16): who is signed in, whether
/// they have agreed to the current consent text, and the sync that follows.
///
/// Screens read this and call it; none of them talks to Firebase.
@MainActor
final class AccountService: ObservableObject {
    static let shared = AccountService.live()

    @Published private(set) var account: ParentAccount?
    /// The consent for the current text on this account, if given.
    @Published private(set) var consent: ConsentRecord?
    /// Looking up whether the parent agreed already (on another device).
    @Published private(set) var checkingConsent = false
    /// The parent chose to open the app offline without signing in, this
    /// launch only (a device that already has its children).
    @Published var deferredSignIn = false

    let sync: FamilySyncService
    private let auth: AccountAuth
    private let consentStore: ParentConsentStore
    private let makeRemote: (String) -> FamilyRemote
    private let eventSink: ReadingEventSink
    private let eventQueue: ReadingEventQueue
    private let shareUsageData: () -> Bool
    private let setShareUsageData: (Bool) -> Void
    private let eraseLocal: (_ keepingOnboarding: Bool) -> Void
    private var forward: AnyCancellable?

    init(
        auth: AccountAuth,
        sync: FamilySyncService,
        consentStore: ParentConsentStore = ParentConsentStore(),
        makeRemote: @escaping (String) -> FamilyRemote,
        eventSink: ReadingEventSink,
        eventQueue: ReadingEventQueue = ReadingEventQueue(),
        shareUsageData: @escaping () -> Bool,
        setShareUsageData: @escaping (Bool) -> Void,
        eraseLocal: @escaping (_ keepingOnboarding: Bool) -> Void
    ) {
        self.auth = auth
        self.sync = sync
        self.consentStore = consentStore
        self.makeRemote = makeRemote
        self.eventSink = eventSink
        self.eventQueue = eventQueue
        self.shareUsageData = shareUsageData
        self.setShareUsageData = setShareUsageData
        self.eraseLocal = eraseLocal
        // Screens observe this object; the sync's state is part of it.
        forward = sync.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
        sync.afterSync = { [weak self] in await self?.afterSync() }
    }

    static func live() -> AccountService {
        AccountService(
            auth: FirebaseAccountAuth(),
            sync: FamilySyncService(local: AppFamilyLocalStore()),
            makeRemote: { FirestoreFamilyRemote(uid: $0) },
            eventSink: FirestoreReadingEventSink(),
            shareUsageData: { MPSettingsStore.shared.shareUsageData },
            setShareUsageData: { MPSettingsStore.shared.shareUsageData = $0 },
            eraseLocal: { LocalDataEraser.eraseFamilyData(keepingOnboarding: $0) })
    }

    var googleAvailable: Bool { auth.googleAvailable }

    // MARK: - Launch

    /// Picks up a session kept from an earlier launch.
    func bootstrap() {
        guard let current = auth.current else { return }
        account = current
        consent = consentStore.current(for: current.uid)
        if consent != nil {
            sync.start(uid: current.uid, remote: makeRemote(current.uid))
        } else {
            Task { await lookUpConsent(for: current.uid) }
        }
    }

    // MARK: - Sign in

    func signIn(with provider: SignInProvider) async throws {
        let signedIn = try await auth.signIn(with: provider)
        account = signedIn
        deferredSignIn = false
        consent = consentStore.current(for: signedIn.uid)
        logger.debug("Ebeveyn giriş yaptı (\(signedIn.provider.rawValue, privacy: .public))")
        if consent != nil {
            sync.start(uid: signedIn.uid, remote: makeRemote(signedIn.uid))
        } else {
            await lookUpConsent(for: signedIn.uid)
        }
    }

    /// The parent may have agreed on another device: then this one does
    /// not ask again.
    private func lookUpConsent(for uid: String) async {
        checkingConsent = true
        defer { checkingConsent = false }
        guard let found = try? await makeRemote(uid).consent(version: ParentConsentText.version),
              account?.uid == uid else { return }
        adopt(found, for: uid, recordedRemotely: true)
    }

    // MARK: - Consent

    /// The parent agreed on this device.
    func acceptConsent(shareUsageData share: Bool, now: Date = Date()) async {
        guard let account else { return }
        setShareUsageData(share)
        let record = ConsentRecord(version: ParentConsentText.version, acceptedAt: now, shareUsageData: share)
        adopt(record, for: account.uid, recordedRemotely: false)
        await recordPendingConsent()
    }

    /// Makes `record` this device's consent and starts the sync.
    ///
    /// The first time this device learns of a consent, reading events that
    /// waited from before are dropped (karar: 6 Ekim 2026): only reading done
    /// after the parent read the text is ever sent.
    private func adopt(_ record: ConsentRecord, for uid: String, recordedRemotely: Bool) {
        if !consentStore.hasAny { eventQueue.eraseAll() }
        consentStore.save(record, for: uid, recordedRemotely: recordedRemotely)
        consent = record
        sync.start(uid: uid, remote: makeRemote(uid))
    }

    private func recordPendingConsent() async {
        guard let uid = account?.uid, let pending = consentStore.pendingRemote(for: uid) else { return }
        let remote = makeRemote(uid)
        do {
            try await remote.recordConsent(pending)
            consentStore.markRecorded(for: uid)
        } catch {
            // Written once: if this version is already on the account (agreed
            // on another device), the create is refused and that is fine.
            if (try? await remote.consent(version: pending.version)) != nil {
                consentStore.markRecorded(for: uid)
            }
        }
    }

    private func afterSync() async {
        await recordPendingConsent()
        let conditions = ReadingEventUploader.Conditions(
            sharingOn: shareUsageData(), consentGiven: consent != nil, signedIn: account != nil)
        await ReadingEventUploader(queue: eventQueue, sink: eventSink).flush(when: conditions)
    }

    // MARK: - Sign out

    /// Signs out and removes the family's data from this device; the
    /// account keeps it. Refused while the device has changes the account
    /// does not, so signing out never loses a story.
    func signOut() async throws {
        // Always one more sync: it is what notices a change made a moment ago,
        // and a change it cannot send keeps the parent signed in.
        _ = await sync.syncNow()
        guard !sync.hasUnsentChanges else { throw AccountError.unsentChanges }
        sync.stop()
        try auth.signOut()
        account = nil
        consent = nil
        eraseLocal(true)
        logger.debug("Ebeveyn çıkış yaptı")
    }

    // MARK: - Delete

    enum DeletionStep: Equatable {
        case reauthenticating, deletingData, deletingAccount, erasingDevice
    }

    /// Deletes the account: a fresh sign-in, then every document of the
    /// family, then the sign-in itself, then this device's copy (FAZ 16 §4).
    ///
    /// Anonymous reading events are not deleted: nothing ties them to the
    /// account, which is the point of them.
    func deleteAccount(progress: @escaping (DeletionStep) -> Void = { _ in }) async throws {
        guard let account else { throw AccountError.failed }
        progress(.reauthenticating)
        try await auth.reauthenticateForDeletion()
        sync.stop()
        do {
            progress(.deletingData)
            try await makeRemote(account.uid).deleteEverything()
            progress(.deletingAccount)
            try await auth.deleteUser()
        } catch {
            // Nothing local was touched: the parent can try again.
            sync.start(uid: account.uid, remote: makeRemote(account.uid))
            throw FirebaseAccountAuth.map(error)
        }
        progress(.erasingDevice)
        self.account = nil
        consent = nil
        deferredSignIn = false
        eraseLocal(false)
        logger.debug("Hesap silindi")
    }
}
