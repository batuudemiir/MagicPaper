import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "LocalDataEraser")

/// Removes a family's data from this device: "Tüm verileri sil", signing out
/// and deleting the account all end here (FAZ 16), so the three cannot drift
/// apart on what "everything" means.
///
/// Device preferences (reading size, haptics, reminder time) stay: they are
/// the device's, not the family's. Downloaded content (FAZ 15) stays too; it
/// holds nothing about anyone.
@MainActor
enum LocalDataEraser {
    /// The family's UserDefaults keys that are not per child.
    static let defaultsKeys = [
        "stories", "user_profiles", "current_profile_id",
        "mp_favoriteStoryIDs", "mp_readDays", "mp_readSeconds",
        "mp_approvedStoryIDs", MPWelcome.pendingKey,
    ]

    /// Engine folders under `Documents/StoryEngine` that hold a family's
    /// records and have no store of their own to erase them.
    static let engineFolders = ["Stories", "Jobs", "Requests", "Characters"]

    static func eraseFamilyData(keepingOnboarding: Bool, defaults: UserDefaults = .standard) {
        for key in defaultsKeys { defaults.removeObject(forKey: key) }
        // Reading ledgers are per child; their keys carry the profile id.
        MPStreak.eraseAllLedgers(in: defaults)
        MPBadgeStore.eraseAll(in: defaults)
        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix("mp_avatarColor_") || key.hasPrefix("read_history_") || key.hasPrefix(StoryGenerationManager.undecodableBackupPrefix) {
            defaults.removeObject(forKey: key)
        }
        AvatarStore.eraseAll()
        FamilyCharacterStore.eraseAll()
        StorySeriesStore.eraseAll()
        defaults.removeObject(forKey: SeriesClock.highWaterKey)
        StoryUsageStore.eraseAll()
        // Kendi sesin (FAZ 18): ebeveynin ses kayıtları.
        VoiceRecordingStore.shared.deleteAll()
        ReadingEventQueue.eraseAll()
        DailyStoryManager.shared.eraseReadingState()
        LibraryPersistence.eraseAll()
        for folder in engineFolders {
            if let url = StoryEngineStorage.directory(folder) { try? FileManager.default.removeItem(at: url) }
        }
        eraseDocumentsFiles()
        // The account's bookkeeping on this device.
        SyncLedgerStore().erase()
        ParentConsentStore(defaults: defaults).erase()

        // What the screens hold in memory goes with what was on disk; the
        // empty library write also clears the library's file copy.
        StoryGenerationManager.shared.resetAfterErase()
        ProfileManager.shared.resetAfterErase(keepingOnboarding: keepingOnboarding)
        logger.debug("Aile verisi cihazdan silindi")
    }

    /// Profile photos (`profile_<UUID>.jpg`) and the old pipeline's story
    /// images (`Documents/Stories`).
    private static func eraseDocumentsFiles() {
        let manager = FileManager.default
        guard let documents = manager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let names = (try? manager.contentsOfDirectory(atPath: documents.path)) ?? []
        for name in names where name.hasPrefix("profile_") && name.hasSuffix(".jpg") {
            try? manager.removeItem(at: documents.appendingPathComponent(name))
        }
        let images = documents.appendingPathComponent("Stories", isDirectory: true)
        for name in (try? manager.contentsOfDirectory(atPath: images.path)) ?? [] {
            try? manager.removeItem(at: images.appendingPathComponent(name))
        }
    }
}
