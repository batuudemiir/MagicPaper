import Foundation
import OSLog

/// `print` reaches the shared device console verbatim. `Logger` redacts
/// interpolated values as `<private>` outside a debugger by default.
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "LibraryMigration")

/// Moves the library out of `UserDefaults` and onto disk, in the only order
/// that cannot lose a book: **write → verify → mark → wait → delete.**
///
/// The delete step is written here, in the same change as the write step, and
/// it is gated rather than absent. That ordering is not a style preference: the
/// app already shipped the other one twice and both are still visible in the
/// code it replaces —
///
/// * `migrateOldStoriesIfNeeded()` deleted a four-megabyte `stories` blob with
///   no backup at all, so a child's whole shelf could vanish on one launch;
/// * `stories.undecodable.*` kept unbounded copies that nothing ever read,
///   cleaned up, or surfaced — a backup step written without its delete step.
///
/// Nothing here throws out of `run()`. A migration that fails leaves the legacy
/// store exactly as it found it and records why; the app keeps working on the
/// old path. The one thing it must never do is half-move a library.
@MainActor
final class LibraryMigration {

    // MARK: - State

    enum Phase: String, Codable {
        /// Nothing verified yet. The legacy store is the only copy.
        case pending
        /// Every record was copied and read back intact. The legacy store is
        /// still authoritative; disk is a verified shadow kept in step.
        case verified
        /// The legacy keys are gone. Disk is the only copy.
        case legacyRetired
    }

    struct State: Codable, Equatable {
        var schemaVersion: Int = 1
        var phase: Phase = .pending
        var verifiedAt: Date?
        var retiredAt: Date?
        /// Why the last attempt did not reach `.verified`. Kept so a support
        /// question has an answer that is not "it just didn't".
        var lastFailure: String?
        /// Records that were on disk but unreadable at verification time.
        var quarantinedFiles: [String] = []
        /// Size of the oversized legacy blob already copied to quarantine, so
        /// the copy happens once rather than on every launch.
        var oversizedBlobBytes: Int?

        static let key = "mp_libraryMigration"
    }

    /// How long the legacy copy is kept after verification.
    ///
    /// Long enough that a parent who opens the app a few times in a fortnight
    /// proves the new path works before the old one goes. Shorter would be a
    /// guess dressed as a grace period.
    static let graceInterval: TimeInterval = 14 * 24 * 60 * 60

    /// How many quarantined blobs to keep.
    static let quarantineLimit = 3

    /// Whether disk is the read path yet.
    ///
    /// **False this wave, deliberately.** Two things must land before it can be
    /// true, and neither is this agent's file: Settings' "delete all data"
    /// (`SettingsView.clearAll`) has to erase the file store too, and the
    /// favourites/approval writers have to write through this store rather than
    /// straight to `UserDefaults`. Until then the legacy keys are the live copy
    /// and retiring them would delete the library rather than migrate it.
    /// See `docs/MagicPaper_Persistence_Migration.md` §6.
    static let readPathIsAuthoritative = false

    // MARK: - Dependencies

    private let defaults: UserDefaults
    private let store: LibraryFileStore
    private let now: () -> Date
    private let cutoverEnabled: Bool

    private(set) var state: State

    /// Fails only when the store's own directories cannot be created; the
    /// caller then keeps running on the legacy path.
    init(
        defaults: UserDefaults,
        store: LibraryFileStore,
        now: @escaping () -> Date = Date.init,
        cutoverEnabled: Bool = LibraryMigration.readPathIsAuthoritative
    ) {
        self.defaults = defaults
        self.store = store
        self.now = now
        self.cutoverEnabled = cutoverEnabled
        self.state = Self.readState(from: defaults) ?? State()
    }

    private static func readState(from defaults: UserDefaults) -> State? {
        guard let data = defaults.data(forKey: State.key) else { return nil }
        return try? JSONDecoder().decode(State.self, from: data)
    }

    /// The **mark** step. The only place `state` reaches disk.
    private func mark(_ mutate: (inout State) -> Void) {
        var next = state
        mutate(&next)
        guard let data = try? JSONEncoder().encode(next) else {
            logger.error("🛑 Göç durumu kodlanamadı; bir sonraki açılışta baştan denenecek.")
            return
        }
        defaults.set(data, forKey: State.key)
        // Small and written at a moment the process may not survive: the whole
        // safety argument rests on this marker being on disk before anything
        // reads it back.
        defaults.synchronize()
        state = next
    }

    // MARK: - Entry point

    /// Runs whatever step is due. Safe to call on every launch; idempotent.
    func run() {
        quarantineOversizedLegacyBlob()
        store.pruneQuarantine(keeping: Self.quarantineLimit)

        switch state.phase {
        case .legacyRetired:
            return
        case .verified:
            reconcile()
            retireLegacyIfDue()
        case .pending:
            copyVerifyAndMark()
        }
    }

    // MARK: - Step 0 — the unbacked delete this replaces

    /// The four-megabyte branch, made survivable.
    ///
    /// What it did (`SGM:939`): if `UserDefaults["stories"]` was over 4 MB it
    /// removed the key and set `stories = []`, on the theory that the blob was
    /// an old format with images embedded in it. That theory may even be right.
    /// It is still a child's entire library, and it was deleted without a copy,
    /// on a launch, with no way back — and it would have deleted precisely the
    /// data this migration exists to move.
    ///
    /// What it does now: **it does not delete anything.** An oversized entry is
    /// a performance problem; removing it unread is a data-loss problem, and
    /// the two are not worth trading. The blob is copied to quarantine, the
    /// copy is read back byte for byte, and the key stays where it is. The key
    /// goes away later, through the one path allowed to remove it —
    /// `retireLegacyIfDue()`, after the copy on disk has been verified.
    private func quarantineOversizedLegacyBlob() {
        guard let blob = defaults.data(forKey: LegacyKeys.stories) else { return }
        guard blob.count > Self.oversizedThreshold else { return }
        // One copy per blob, not one per launch.
        guard state.oversizedBlobBytes != blob.count else { return }

        let name = "stories.oversized.\(Int(now().timeIntervalSince1970)).json"
        do {
            let url = try store.quarantine(blob, named: name)
            guard try Data(contentsOf: url) == blob else {
                logger.error("🛑 Aşırı büyük masal yığınının kopyası eşleşmedi. Hiçbir şey silinmedi.")
                return
            }
            store.pruneQuarantine(keeping: Self.quarantineLimit)
            mark { $0.oversizedBlobBytes = blob.count }
            logger.debug("ℹ️ \(blob.count / 1024 / 1024) MB'lık masal yığını '\(name)' altına kopyalandı. Eski anahtar OLDUĞU GİBİ duruyor.")
        } catch {
            logger.error("🛑 Aşırı büyük masal yığını kopyalanamadı: \(String(describing: error)). Hiçbir şey silinmedi.")
        }
    }

    static let oversizedThreshold = 4_000_000

    // MARK: - Steps 1-3 — write, verify, mark

    private func copyVerifyAndMark() {
        let source = readLegacy()

        // A legacy blob that will not decode is not an empty library. Marking
        // the migration done over it would turn a recoverable problem into a
        // permanent one, so it stops here and says so.
        if let failure = source.failure {
            mark { $0.lastFailure = failure }
            logger.error("🛑 Göç durduruldu: \(failure)")
            return
        }

        // 1 — write. Unmarked on purpose: keyed by id and therefore repeatable,
        // so an interrupted run is simply resumed by the next one.
        do {
            for story in source.stories {
                try store.writeStory(story)
            }
            try store.writeFlagList(source.favorites, as: .favorites)
            try store.writeFlagList(source.approvals, as: .approvals)
        } catch {
            mark { $0.lastFailure = "Yazma: \(error)" }
            logger.error("🛑 Göç yazma adımında durdu: \(String(describing: error)). Eski veriye dokunulmadı.")
            return
        }

        // 2 — verify. Read back from disk and compare with the source, not with
        // what we believe we wrote.
        let verification = verify(against: source)
        guard verification.ok else {
            mark {
                $0.lastFailure = verification.reason
                $0.quarantinedFiles = verification.damagedFiles
            }
            logger.error("🛑 Göç doğrulanamadı: \(verification.reason ?? "?"). Eski veriye dokunulmadı.")
            return
        }

        // 3 — mark.
        mark {
            $0.phase = .verified
            $0.verifiedAt = now()
            $0.lastFailure = nil
            $0.quarantinedFiles = verification.damagedFiles
        }
        logger.debug("✅ Kütüphane göçü doğrulandı: \(source.stories.count) masal, \(source.favorites.count) favori, \(source.approvals.count) onay. Eski kopya \(Int(Self.graceInterval / 86400)) gün daha duruyor.")
    }

    private struct Verification {
        var ok: Bool
        var reason: String?
        var damagedFiles: [String] = []
    }

    private func verify(against source: LegacySnapshot) -> Verification {
        let onDisk = store.readAllStories()
        let damaged = onDisk.failures.map(\.description)

        if !onDisk.failures.isEmpty {
            return Verification(ok: false, reason: "Diskte çözümlenemeyen dosya var.", damagedFiles: damaged)
        }

        let expected = Set(source.stories.map(\.id))
        let actual = Set(onDisk.stories.map(\.id))
        guard expected.isSubset(of: actual) else {
            let missing = expected.subtracting(actual).count
            return Verification(ok: false, reason: "\(missing) masal diskte bulunamadı.")
        }

        // Identity is not enough. `Story: Equatable` compares ids only — by
        // design, for list diffing — so a story that lost its pages in the
        // round trip would still compare equal. The comparison has to be over
        // the bytes the record decodes to.
        let byID = Dictionary(uniqueKeysWithValues: onDisk.stories.map { ($0.id, $0) })
        // Same date strategy as both the legacy blob and the file store, so
        // the comparison cannot be made to pass by a lossy encoding applied
        // equally to both sides.
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        for story in source.stories {
            guard let restored = byID[story.id] else {
                return Verification(ok: false, reason: "'\(story.title)' diskte bulunamadı.")
            }
            guard let a = try? encoder.encode(story), let b = try? encoder.encode(restored), a == b else {
                return Verification(ok: false, reason: "'\(story.title)' diske eksik yazıldı.")
            }
        }

        do {
            guard try store.readFlagList(.favorites) == source.favorites else {
                return Verification(ok: false, reason: "Favoriler diske eksik yazıldı.")
            }
            guard try store.readFlagList(.approvals) == source.approvals else {
                return Verification(ok: false, reason: "Onaylar diske eksik yazıldı.")
            }
        } catch {
            return Verification(ok: false, reason: "Bayrak listeleri okunamadı: \(error)")
        }

        return Verification(ok: true, reason: nil, damagedFiles: damaged)
    }

    // MARK: - Step 4 — wait

    /// Makes disk match the legacy store, deletions included.
    ///
    /// During the grace window the legacy keys are still the live copy, so the
    /// shadow has to follow them in both directions. Copying additions but not
    /// removals is how a "delete all data" leaves a child's stories on disk
    /// after the parent was told they were gone — the reason this is a sync and
    /// not a top-up.
    @discardableResult
    func reconcile() -> Bool {
        guard state.phase == .verified else { return false }
        let source = readLegacy()
        guard source.failure == nil else { return false }
        return sync(to: source)
    }

    /// `reconcile()` for a caller that already holds the library in memory.
    ///
    /// `saveStories()` runs on every page turn. Re-reading and re-decoding the
    /// whole blob there would add a second full pass to a write that already
    /// encodes one — for a shelf the caller is holding in a property.
    @discardableResult
    func reconcile(stories: [Story]) -> Bool {
        guard state.phase == .verified else { return false }
        var source = LegacySnapshot()
        source.stories = stories
        source.favorites = Set(defaults.stringArray(forKey: LibraryFileStore.FlagList.favorites.legacyKey) ?? [])
        source.approvals = Set(defaults.stringArray(forKey: LibraryFileStore.FlagList.approvals.legacyKey) ?? [])
        return sync(to: source)
    }

    private func sync(to source: LegacySnapshot) -> Bool {
        do {
            let wanted = Set(source.stories.map(\.id))
            for id in store.storyIDsOnDisk().subtracting(wanted) {
                store.deleteStory(id: id)
            }
            for story in source.stories {
                try store.writeStory(story)
            }
            try store.writeFlagList(source.favorites, as: .favorites)
            try store.writeFlagList(source.approvals, as: .approvals)
            return true
        } catch {
            logger.error("🛑 Gölge kopya eşitlenemedi: \(String(describing: error))")
            return false
        }
    }

    // MARK: - Step 5 — delete

    /// Removes the legacy keys, once and only once it is safe to.
    ///
    /// Written in the same change as the write step even though it cannot fire
    /// yet. `cutoverEnabled` is the missing precondition, not a feature flag
    /// for taste: while reads still come from `UserDefaults`, deleting those
    /// keys deletes the library.
    @discardableResult
    func retireLegacyIfDue() -> Bool {
        guard cutoverEnabled else { return false }
        guard state.phase == .verified, let verifiedAt = state.verifiedAt else { return false }
        guard now().timeIntervalSince(verifiedAt) >= Self.graceInterval else { return false }

        // Last look before the point of no return: the shadow must still hold
        // everything the legacy store does.
        let source = readLegacy()
        guard source.failure == nil else { return false }
        guard verify(against: source).ok else {
            logger.error("🛑 Emeklilik iptal: doğrulama artık geçmiyor. Eski veri duruyor.")
            return false
        }

        for key in LegacyKeys.migrated {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
        mark {
            $0.phase = .legacyRetired
            $0.retiredAt = now()
        }
        logger.debug("✅ Eski UserDefaults kopyası emekliye ayrıldı. Kütüphane artık yalnızca diskte.")
        return true
    }

    // MARK: - Legacy reading

    enum LegacyKeys {
        static let stories = "stories"
        /// The keys this migration owns. `current_profile_id`, the onboarding
        /// flag and the UI preferences stay in `UserDefaults` — they are
        /// settings, not domain records. `user_profiles` is deliberately absent:
        /// it belongs to the character-system agent this wave (see the doc §5).
        static let migrated = [stories, LibraryFileStore.FlagList.favorites.legacyKey, LibraryFileStore.FlagList.approvals.legacyKey]
    }

    struct LegacySnapshot {
        var stories: [Story] = []
        var favorites: Set<String> = []
        var approvals: Set<String> = []
        /// Set when the source could not be read. Non-nil stops the migration.
        var failure: String?
    }

    func readLegacy() -> LegacySnapshot {
        var snapshot = LegacySnapshot()
        snapshot.favorites = Set(defaults.stringArray(forKey: LibraryFileStore.FlagList.favorites.legacyKey) ?? [])
        snapshot.approvals = Set(defaults.stringArray(forKey: LibraryFileStore.FlagList.approvals.legacyKey) ?? [])

        guard let data = defaults.data(forKey: LegacyKeys.stories) else {
            return snapshot // No stories yet: an empty library is a valid one.
        }
        let decoder = JSONDecoder()
        do {
            snapshot.stories = try decoder.decode([Story].self, from: data)
        } catch {
            snapshot.failure = "Eski masal yığını çözümlenemedi: \(error)"
        }
        return snapshot
    }
}

// MARK: - App wiring

/// The one instance the app uses.
///
/// A separate type so that everything above stays constructible against a
/// temporary directory and a scratch `UserDefaults`, which is what makes the
/// migration testable at all.
@MainActor
enum LibraryPersistence {
    private(set) static var store: LibraryFileStore?
    private(set) static var migration: LibraryMigration?

    /// Called once, from `StoryGenerationManager`'s initialiser, before the
    /// library is loaded.
    @discardableResult
    static func bootstrap() -> LibraryMigration? {
        if let migration { return migration }
        guard let root = LibraryFileStore.documentsRoot() else {
            logger.error("🛑 Documents dizinine erişilemedi; kütüphane eski yolda kalıyor.")
            return nil
        }
        do {
            let store = try LibraryFileStore(root: root)
            let migration = LibraryMigration(defaults: .standard, store: store)
            migration.run()
            self.store = store
            self.migration = migration
            return migration
        } catch {
            logger.error("🛑 Kütüphane deposu kurulamadı: \(String(describing: error)). Eski yol kullanılmaya devam ediyor.")
            return nil
        }
    }

    /// Keeps the shadow copy in step after a write to the legacy store.
    ///
    /// Takes the shelf the caller just wrote rather than re-reading it, and
    /// does nothing at all until the migration has verified.
    static func reconcileAfterWrite(stories: [Story]) {
        migration?.reconcile(stories: stories)
    }

    /// Everything this app keeps on disk about a family's library.
    ///
    /// Settings' "delete all data" must call this once it owns the seam; until
    /// then `reconcile()` carries erasures across. Kept here so the call site
    /// is one line when that lands.
    static func eraseAll() {
        do { try store?.eraseEverything() }
        catch { logger.error("🛑 Kütüphane dosyaları silinemedi: \(String(describing: error))") }
    }
}
