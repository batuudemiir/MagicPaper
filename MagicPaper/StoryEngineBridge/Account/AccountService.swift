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
    /// Which family this account syncs, and in what role (FAZ 18). Nil until
    /// signed in; an account that joined no family founds its own.
    @Published private(set) var membership: FamilyMembership?
    /// A family invite opened from a link, waiting for the parent to sign in
    /// and accept it (FAZ 18).
    @Published var pendingInviteCode: String?

    let sync: FamilySyncService
    private let auth: AccountAuth
    private let consentStore: ParentConsentStore
    private let makeRemote: (String) -> FamilyRemote
    private let eventSink: ReadingEventSink
    private let eventQueue: ReadingEventQueue
    private let shareUsageData: () -> Bool
    private let setShareUsageData: (Bool) -> Void
    private let eraseLocal: (_ keepingOnboarding: Bool) -> Void
    let directory: FamilyDirectory
    private let membershipCache: FamilyMembershipCache
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
        eraseLocal: @escaping (_ keepingOnboarding: Bool) -> Void,
        directory: FamilyDirectory = SoloFamilyDirectory(),
        membershipCache: FamilyMembershipCache = FamilyMembershipCache()
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
        self.directory = directory
        self.membershipCache = membershipCache
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
            eraseLocal: { LocalDataEraser.eraseFamilyData(keepingOnboarding: $0) },
            directory: FirestoreFamilyDirectory())
    }

    var googleAvailable: Bool { auth.googleAvailable }

    // MARK: - Family (FAZ 18)

    /// The family this account reads and writes: its founder's uid.
    var familyID: String? { membership?.familyID ?? account?.uid }

    var role: FamilyRole? { account == nil ? nil : (membership?.role ?? .admin) }

    /// Whether this account may change the family's records. True when no
    /// one is signed in: the device is then the family's only copy.
    var canWriteFamily: Bool { role?.canWrite ?? true }

    var isFounder: Bool { role == .admin }

    private func startSync() {
        guard let familyID else { return }
        sync.start(uid: familyID, remote: makeRemote(familyID), readOnly: role == .reader)
    }

    /// Asks the server which family this account belongs to. Offline, the
    /// device's copy stands. Restarts the sync when the answer changed (the
    /// founder removed this account, or changed its role).
    @discardableResult
    func refreshMembership() async -> FamilyMembership? {
        guard let uid = account?.uid else { return nil }
        let found: FamilyMembership
        do {
            found = try await directory.membership(for: uid) ?? .founder(uid)
        } catch {
            return membership
        }
        guard account?.uid == uid else { return membership }
        let changed = found != membership
        let familyChanged = found.familyID != membership?.familyID
        membership = found
        if changed && consent != nil && familyChanged {
            // Another family's data is on this device (removed from a family,
            // or joined one on another device): it goes.
            sync.stop()
            consent = nil
            eraseLocal(true)
            membershipCache.save(found, for: uid)
            await lookUpConsent(for: uid)
        } else {
            membershipCache.save(found, for: uid)
            if changed && consent != nil { startSync() }
        }
        return found
    }

    /// Joins the family `invite` belongs to (FAZ 18). The account's own
    /// family, if it has one, is deleted first: an account belongs to one
    /// family. The caller has told the parent so.
    func joinFamily(_ invite: FamilyInvite, displayName: String) async throws {
        guard let account else { throw AccountError.failed }
        guard invite.isValid() else { throw AccountError.failed }
        if isFounder {
            try await directory.dissolve(familyID: account.uid)
            try await makeRemote(account.uid).deleteEverything()
        }
        try await directory.accept(invite, uid: account.uid, displayName: displayName)
        sync.stop()
        consent = nil
        eraseLocal(true)
        let joined = FamilyMembership(familyID: invite.familyID, role: invite.role)
        membership = joined
        membershipCache.save(joined, for: account.uid)
        pendingInviteCode = nil
        await lookUpConsent(for: account.uid)
        logger.debug("Aileye katıldı (\(invite.role.rawValue, privacy: .public))")
    }

    /// Leaves the family this account joined; the device's copy of it goes.
    /// The account then founds its own, empty family.
    func leaveFamily() async throws {
        guard let account, let membership, !membership.isFounder else { throw AccountError.failed }
        try await directory.remove(uid: account.uid, from: membership.familyID)
        sync.stop()
        consent = nil
        eraseLocal(true)
        self.membership = .founder(account.uid)
        membershipCache.save(.founder(account.uid), for: account.uid)
        await lookUpConsent(for: account.uid)
    }

    // MARK: - Launch

    /// Picks up a session kept from an earlier launch.
    func bootstrap() {
        guard let current = auth.current else { return }
        account = current
        membership = membershipCache.load(for: current.uid) ?? .founder(current.uid)
        consent = consentStore.current(for: current.uid)
        if consent != nil {
            startSync()
            Task { await refreshMembership() }
        } else {
            Task {
                await refreshMembership()
                await lookUpConsent(for: current.uid)
            }
        }
    }

    // MARK: - Sign in

    func signIn(with provider: SignInProvider) async throws {
        let signedIn = try await auth.signIn(with: provider)
        account = signedIn
        deferredSignIn = false
        membership = membershipCache.load(for: signedIn.uid) ?? .founder(signedIn.uid)
        await refreshMembership()
        consent = consentStore.current(for: signedIn.uid)
        logger.debug("Ebeveyn giriş yaptı (\(signedIn.provider.rawValue, privacy: .public))")
        if consent != nil {
            startSync()
        } else {
            await lookUpConsent(for: signedIn.uid)
        }
    }

    /// The parent may have agreed on another device: then this one does
    /// not ask again. A member of a family the founder agreed for is not
    /// asked either (FAZ 18): the consent is the family's.
    private func lookUpConsent(for uid: String) async {
        checkingConsent = true
        defer { checkingConsent = false }
        guard let familyID,
              let found = try? await makeRemote(familyID).consent(version: ParentConsentText.version),
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
        startSync()
    }

    private func recordPendingConsent() async {
        // Only the founder records the family's consent (the rules agree).
        guard isFounder, let uid = account?.uid, let pending = consentStore.pendingRemote(for: uid) else { return }
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
        membership = nil
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
    ///
    /// FAZ 18: the founder's deletion takes the whole family with it (its
    /// members lose access first); a member's deletion only takes the
    /// member out, the family's data stays the family's.
    func deleteAccount(progress: @escaping (DeletionStep) -> Void = { _ in }) async throws {
        guard let account else { throw AccountError.failed }
        let membership = self.membership ?? .founder(account.uid)
        progress(.reauthenticating)
        try await auth.reauthenticateForDeletion()
        sync.stop()
        do {
            progress(.deletingData)
            if membership.isFounder {
                try await directory.dissolve(familyID: account.uid)
                try await makeRemote(account.uid).deleteEverything()
            } else {
                try await directory.remove(uid: account.uid, from: membership.familyID)
            }
            progress(.deletingAccount)
            try await auth.deleteUser()
        } catch {
            // Nothing local was touched: the parent can try again.
            startSync()
            throw FirebaseAccountAuth.map(error)
        }
        progress(.erasingDevice)
        membershipCache.clear(for: account.uid)
        self.account = nil
        self.membership = nil
        consent = nil
        deferredSignIn = false
        eraseLocal(false)
        logger.debug("Hesap silindi")
    }
}
