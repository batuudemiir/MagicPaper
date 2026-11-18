import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "LibraryShelf")

/// Where the library is read from and written to (E1).
///
/// One question, answered once per launch from the phase the migration left
/// behind: is the live copy `UserDefaults["stories"]` or the file store?
///
/// * Before cutover (`.pending`, `.verified`) nothing changes: the blob is
///   read and written exactly as it was, and the disk shadow follows it.
/// * After cutover (`.diskAuthoritative`, `.legacyRetired`) the shelf is the
///   story files. A save writes only the stories that changed and deletes
///   only the stories that left the shelf. The legacy blob is never written
///   again.
/// * After cutover but without a store (Documents unavailable this launch),
///   the frozen legacy copy is shown if there is one and nothing is saved.
///   The phase does not change.
///
/// Logs carry ids and file names only: never a title, a child's name or text.
@MainActor
final class LibraryShelf {

    enum Mode: Equatable {
        /// The legacy blob is the live copy; disk is its shadow.
        case legacy
        /// One file per story is the live copy.
        case disk
        /// Disk is the live copy but cannot be reached this launch.
        case readOnly
    }

    let mode: Mode

    private let defaults: UserDefaults
    private let migration: LibraryMigration?

    /// The ids on the shelf as last loaded or saved.
    ///
    /// A deletion is a known id that left the shelf. Never "a file the shelf
    /// does not list": that would include damaged and unreadable files, and
    /// deleting those is how a book is lost.
    private var knownIDs: Set<UUID> = []
    /// Files present but not readable this launch (a locked device). Their
    /// bytes are fine; they are neither written nor deleted until they read.
    private var unreadableIDs: Set<UUID> = []
    /// Damaged files that could not be set aside and still sit on the shelf's
    /// folder. Never written over, never deleted.
    private var stuckDamagedIDs: Set<UUID> = []
    private var hasUnreadableFiles = false
    private var favoritesReadFailed = false
    private var reportedReadOnlySave = false

    /// The story files the last save wrote. Empty before cutover.
    private(set) var lastWrittenStoryIDs: [UUID] = []

    private var protectedIDs: Set<UUID> { unreadableIDs.union(stuckDamagedIDs) }

    init(defaults: UserDefaults, migration: LibraryMigration?) {
        self.defaults = defaults
        self.migration = migration
        let phase = migration?.state.phase ?? LibraryMigration.storedState(in: defaults).phase
        if !phase.readsFromDisk {
            mode = .legacy
        } else if migration != nil {
            mode = .disk
        } else {
            mode = .readOnly
        }
    }

    // MARK: - Stories

    func load() -> [Story] {
        switch mode {
        case .legacy: return loadLegacy()
        case .disk: return loadDisk()
        case .readOnly: return loadFrozenLegacy()
        }
    }

    func save(_ stories: [Story]) {
        lastWrittenStoryIDs = []
        switch mode {
        case .legacy: saveLegacy(stories)
        case .disk: saveDisk(stories)
        case .readOnly: noteReadOnlySave()
        }
    }

    /// Forces a lazy write down, for the moment just before the process may
    /// die (reading progress). A file write is already on disk when it
    /// returns; only the legacy blob needs this.
    func flush() {
        if mode == .legacy { defaults.synchronize() }
    }

    /// Stories whose files could not be read at load and can be now.
    ///
    /// Called when protected data becomes available: a background launch on
    /// a locked device reads none of the `.completeUnlessOpen` files, and the
    /// same process later serves the unlocked app.
    func recoverUnreadable() -> [Story] {
        guard mode == .disk, hasUnreadableFiles, let store = migration?.store else { return [] }
        let result = store.readAllStories()
        absorb(result.failures)
        let recovered = result.stories.filter { !knownIDs.contains($0.id) }
        knownIDs.formUnion(recovered.map(\.id))
        return recovered
    }

    // MARK: - Legacy blob (unchanged from StoryGenerationManager)

    private func loadLegacy() -> [Story] {
        guard let data = defaults.data(forKey: LibraryMigration.LegacyKeys.stories) else { return [] }
        do {
            let stories = try JSONDecoder().decode([Story].self, from: data)
            logger.debug("✅ Loaded \(stories.count) stories from UserDefaults")
            return stories
        } catch {
            // Bu, uygulamadaki en pahalı sessiz arıza yoluydu.
            //
            // Çözümleme başarısız olunca `stories` boş kalıyor, hemen ardından
            // eski örnek masal kurulumu devreye giriyor ve ilk kayıtta
            // gerçek kütüphanenin üstüne yazıyordu. Ham veri artık tarihli bir
            // anahtara alınıyor; kurtarılabilir. Yedekler sınırlı
            // (`StoryGenerationManager.undecodableBackupLimit`).
            let backupKey = "\(StoryGenerationManager.undecodableBackupPrefix)\(Int(Date().timeIntervalSince1970))"
            defaults.set(data, forKey: backupKey)
            StoryGenerationManager.pruneUndecodableBackups(
                keeping: StoryGenerationManager.undecodableBackupLimit, in: defaults
            )
            assertionFailure("Masallar çözümlenemedi: \(error)")
            logger.error("🛑 Masallar ÇÖZÜMLENEMEDİ. Ham veri '\(backupKey)' altına alındı: \(String(describing: error))")
            return []
        }
    }

    private func saveLegacy(_ stories: [Story]) {
        do {
            let encoded = try JSONEncoder().encode(stories)
            let dataSize = encoded.count
            logger.debug("💾 Saving stories to UserDefaults: \(dataSize) bytes (\(dataSize / 1024) KB)")

            // Check if size is reasonable (< 1MB for UserDefaults)
            if dataSize > 1_000_000 {
                logger.warning("⚠️ WARNING: Stories data is large (\(dataSize / 1024 / 1024) MB). Consider cleanup.")
            }

            defaults.set(encoded, forKey: LibraryMigration.LegacyKeys.stories)
            // Keep the verified copy on disk in step with the write that just
            // happened, deletions included. Does nothing until the migration
            // has verified; never the source of a failure here, because this
            // store is still the authoritative one.
            migration?.reconcile(stories: stories)
        } catch {
            // Önceden `try?` idi: kodlama başarısız olduğunda hiçbir şey
            // yazılmıyor ve hiçbir şey söylenmiyordu.
            assertionFailure("Masallar kaydedilemedi: \(error)")
            logger.error("🛑 Masallar KAYDEDİLEMEDİ, bu oturumdaki değişiklikler kaybolacak: \(String(describing: error))")
        }
    }

    /// The frozen copy, shown when disk is the live copy but cannot be
    /// reached. Read only: no recovery backup is written, nothing is pruned.
    private func loadFrozenLegacy() -> [Story] {
        logger.error("🛑 Kütüphane deposu bu açılışta kurulamadı; raf donmuş yedekten gösteriliyor, kayıt yapılmayacak.")
        guard let data = defaults.data(forKey: LibraryMigration.LegacyKeys.stories) else { return [] }
        guard let stories = try? JSONDecoder().decode([Story].self, from: data) else {
            logger.error("🛑 Donmuş yedek çözümlenemedi; raf boş gösteriliyor.")
            return []
        }
        return stories
    }

    private func noteReadOnlySave() {
        guard !reportedReadOnlySave else { return }
        reportedReadOnlySave = true
        logger.error("🛑 Kütüphane deposu yok; bu oturumdaki değişiklikler kaydedilmiyor.")
    }

    // MARK: - Story files

    private func loadDisk() -> [Story] {
        guard let store = migration?.store else { return [] }
        let result = store.readAllStories()
        absorb(result.failures)
        knownIDs = Set(result.stories.map(\.id))
        logger.debug("✅ \(result.stories.count) masal diskten okundu.")
        return result.stories
    }

    /// Sorts the files that did not read into "locked, try later" and
    /// "damaged, set aside". Neither reaches the shelf; neither is lost.
    private func absorb(_ failures: [LibraryFileStore.Failure]) {
        var unreadable: Set<UUID> = []
        var anyUnreadable = false
        for failure in failures {
            guard case .unreadable(let url, _) = failure else { continue }
            anyUnreadable = true
            if let id = LibraryFileStore.storyID(of: url) { unreadable.insert(id) }
            logger.error("🛑 Masal dosyası şimdilik okunamadı, yerinde bırakıldı: \(url.lastPathComponent, privacy: .public)")
        }
        unreadableIDs = unreadable
        hasUnreadableFiles = anyUnreadable

        let damaged = failures.contains {
            if case .undecodable = $0 { return true }
            return false
        }
        guard damaged, let migration else { return }
        stuckDamagedIDs.formUnion(migration.setAsideDamagedStories(failures))
    }

    private func saveDisk(_ stories: [Story]) {
        guard let store = migration?.store else { return }
        let wanted = Set(stories.map(\.id))
        let protected = protectedIDs

        for id in knownIDs.subtracting(wanted).subtracting(protected) {
            store.deleteStory(id: id)
        }

        var written: [UUID] = []
        for story in stories where !protected.contains(story.id) {
            do {
                if try store.writeStory(story) { written.append(story.id) }
            } catch {
                logger.error("🛑 Masal dosyası yazılamadı: \(story.id.uuidString, privacy: .public)")
            }
        }
        knownIDs = wanted
        lastWrittenStoryIDs = written
    }

    // MARK: - Favourites

    /// Before cutover the legacy key, as `MPFavorites` always read it. After,
    /// `Flags/favorites.json`. A damaged or locked list falls back to the
    /// frozen legacy list for display and is not written over this session.
    func loadFavorites() -> Set<String> {
        let legacyKey = LibraryFileStore.FlagList.favorites.legacyKey
        guard mode == .disk, let store = migration?.store else {
            return Set(defaults.stringArray(forKey: legacyKey) ?? [])
        }
        do {
            let ids = try store.readFlagList(.favorites)
            favoritesReadFailed = false
            return ids ?? []
        } catch {
            favoritesReadFailed = true
            logger.error("🛑 Favori listesi okunamadı; bu oturumda üstüne yazılmayacak.")
            return Set(defaults.stringArray(forKey: legacyKey) ?? [])
        }
    }

    /// The list from disk when an earlier read failed and this one does not;
    /// `nil` when there is nothing new to take.
    func favoritesIfRecovered() -> Set<String>? {
        guard mode == .disk, favoritesReadFailed, let store = migration?.store else { return nil }
        do {
            let ids = try store.readFlagList(.favorites)
            favoritesReadFailed = false
            return ids ?? []
        } catch {
            return nil
        }
    }

    func saveFavorites(_ ids: Set<String>) {
        switch mode {
        case .legacy:
            defaults.set(Array(ids), forKey: LibraryFileStore.FlagList.favorites.legacyKey)
        case .disk:
            guard !favoritesReadFailed, let store = migration?.store else { return }
            do {
                try store.writeFlagList(ids, as: .favorites)
            } catch {
                logger.error("🛑 Favori listesi yazılamadı.")
            }
        case .readOnly:
            return
        }
    }
}
