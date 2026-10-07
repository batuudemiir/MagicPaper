import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "FamilyLocalStore")

/// The device's side of the account sync (FAZ 16): what it holds, as records,
/// and how a server record is brought onto it.
///
/// The device stays the source the app reads (offline first). Sync never
/// reaches into a screen; it goes through the same stores the screens use.
@MainActor
protocol FamilyLocalStore: AnyObject {
    func records() async -> [LocalSyncRecord]
    func apply(_ records: [RemoteSyncRecord]) async
}

/// Posted by the family's stores after a local write, so the account sync
/// can follow without each screen knowing about it.
extension Notification.Name {
    static let mpFamilyDataChanged = Notification.Name("mpFamilyDataChanged")
}

enum SyncCoding {
    /// One encoding for every payload: sorted keys, so the same value is the
    /// same string on every device, and Foundation's default dates, which
    /// keep full precision (ISO-8601 rounds to the second, and a record that
    /// changed by rounding would sync forever).
    static func encode<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(value), as: UTF8.self)
    }

    static func decode<T: Decodable>(_ type: T.Type, from payload: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(payload.utf8))
    }
}

/// The starter books every new device makes for itself
/// (`StoryGenerationManager.createSampleStoriesIfNeeded`). Each device has its
/// own copies; syncing them would put two of each on every shelf.
enum SampleStoryRecognizer {
    static let firstPageTitles: Set<String> = ["Sihirli Başlangıç", "Yıldızlara Bakış"]

    static func isSample(_ story: Story) -> Bool {
        story.origin == nil && story.pages.count == 7
            && story.pages.first.map { firstPageTitles.contains($0.title) } == true
    }
}

/// What of the app's own records goes to the account, and how it comes back.
enum FamilyRecordMapping {
    /// A child as the server keeps it: the profile without its photo file
    /// name (a photo is never sent; the device that has one keeps showing
    /// it), and the avatar colour the parent picked, which lives beside the
    /// profile on the device (`mp_avatarColor_<UUID>`).
    struct SyncedChild: Codable {
        var profile: UserProfile
        /// The stored value (palette index + 1); nil when none was picked.
        var avatarColor: Int?
    }

    static func avatarColorKey(_ id: UUID) -> String { "mp_avatarColor_\(id.uuidString)" }

    static func payload(for profile: UserProfile, avatarColor: Int?) throws -> String {
        var sent = profile
        sent.imageFileName = nil
        return try SyncCoding.encode(SyncedChild(profile: sent, avatarColor: avatarColor))
    }

    /// A story as the server keeps it: written once, so without what changes
    /// as it is read, and without local file names.
    static func payload(for story: Story) throws -> String {
        var sent = story
        sent.lastReadPage = nil
        sent.lastReadAt = nil
        sent.currentProgress = nil
        sent.coverImageFileName = nil
        return try SyncCoding.encode(sent)
    }

    static func progress(of story: Story) -> StoryProgress? {
        guard story.lastReadPage != nil || story.lastReadAt != nil else { return nil }
        return StoryProgress(lastReadPage: story.lastReadPage, lastReadAt: story.lastReadAt)
    }

    /// Only finished books by a real child travel: a story being written, a
    /// failed one or a starter book does not.
    static func syncs(_ story: Story) -> Bool {
        story.status == .completed && !SampleStoryRecognizer.isSample(story)
    }
}

/// The live stores.
@MainActor
final class AppFamilyLocalStore: FamilyLocalStore {
    private let profiles: ProfileManager
    private let library: StoryGenerationManager
    private let avatars: AvatarStore
    private let family: FamilyCharacterStore
    private let series: StorySeriesStore

    init(
        profiles: ProfileManager = .shared,
        library: StoryGenerationManager = .shared,
        avatars: AvatarStore = .shared,
        family: FamilyCharacterStore = FamilyCharacterStore(),
        series: StorySeriesStore = StorySeriesStore()
    ) {
        self.profiles = profiles
        self.library = library
        self.avatars = avatars
        self.family = family
        self.series = series
    }

    func records() async -> [LocalSyncRecord] {
        var records: [LocalSyncRecord] = []
        for profile in profiles.profiles where profile.profileType == .child {
            let id = profile.id.uuidString
            let color = UserDefaults.standard.integer(forKey: FamilyRecordMapping.avatarColorKey(profile.id))
            if let payload = try? FamilyRecordMapping.payload(for: profile, avatarColor: color > 0 ? color : nil) {
                records.append(LocalSyncRecord(key: SyncKey(collection: .children, id: id), payload: payload))
            }
            if let avatar = await avatars.avatar(for: profile.id),
               let payload = try? SyncCoding.encode(avatar) {
                records.append(LocalSyncRecord(key: SyncKey(collection: .avatars, id: id), payload: payload))
            }
            let characters = family.characters(for: profile.id)
            if !characters.isEmpty, let payload = try? SyncCoding.encode(characters) {
                records.append(LocalSyncRecord(key: SyncKey(collection: .family, id: id), payload: payload))
            }
            let list = series.series(for: profile.id)
            if !list.isEmpty, let payload = try? SyncCoding.encode(list) {
                records.append(LocalSyncRecord(key: SyncKey(collection: .series, id: id), payload: payload))
            }
            if let ledger = MPBadgeStore().storedLedger(for: profile.id), !ledger.earned.isEmpty,
               let payload = try? SyncCoding.encode(ledger) {
                records.append(LocalSyncRecord(key: SyncKey(collection: .badges, id: id), payload: payload))
            }
        }
        for story in library.stories where FamilyRecordMapping.syncs(story) {
            let id = story.id.uuidString
            if let payload = try? FamilyRecordMapping.payload(for: story) {
                records.append(LocalSyncRecord(key: SyncKey(collection: .stories, id: id), payload: payload))
            }
            if let progress = FamilyRecordMapping.progress(of: story),
               let payload = try? SyncCoding.encode(progress) {
                records.append(LocalSyncRecord(
                    key: SyncKey(collection: .progress, id: id), payload: payload, changedAt: progress.lastReadAt))
            }
        }
        return records
    }

    func apply(_ records: [RemoteSyncRecord]) async {
        var failures = 0
        for record in records {
            do {
                try await apply(record)
            } catch {
                failures += 1
            }
        }
        if failures > 0 {
            // Counts only: a record's content is a child's.
            logger.error("🛑 Hesaptan gelen \(failures, privacy: .public) kayıt uygulanamadı")
        }
    }

    private func apply(_ record: RemoteSyncRecord) async throws {
        let key = record.key
        switch key.collection {
        case .children:
            guard let id = UUID(uuidString: key.id) else { return }
            if let payload = record.payload {
                let child = try SyncCoding.decode(FamilyRecordMapping.SyncedChild.self, from: payload)
                let colorKey = FamilyRecordMapping.avatarColorKey(id)
                if let color = child.avatarColor {
                    UserDefaults.standard.set(color, forKey: colorKey)
                } else {
                    UserDefaults.standard.removeObject(forKey: colorKey)
                }
                profiles.applySyncedProfile(child.profile)
            } else {
                profiles.removeSyncedProfile(id: id, library: library)
            }
        case .avatars:
            guard let id = UUID(uuidString: key.id) else { return }
            if let payload = record.payload {
                try await avatars.save(try SyncCoding.decode(AvatarSpec.self, from: payload), for: id)
            } else {
                await avatars.delete(for: id)
            }
        case .family:
            guard let id = UUID(uuidString: key.id) else { return }
            if let payload = record.payload {
                try family.replaceAll(try SyncCoding.decode([FamilyCharacter].self, from: payload), for: id)
            } else {
                family.delete(for: id)
            }
        case .series:
            guard let id = UUID(uuidString: key.id) else { return }
            if let payload = record.payload {
                try series.replaceAll(try SyncCoding.decode([StorySeries].self, from: payload), for: id)
            } else {
                series.delete(for: id)
            }
        case .badges:
            guard let id = UUID(uuidString: key.id) else { return }
            if let payload = record.payload {
                MPBadgeStore().merge(try SyncCoding.decode(MPBadgeLedger.self, from: payload), for: id)
            } else {
                MPBadgeStore().erase(for: id)
            }
        case .stories:
            guard let id = UUID(uuidString: key.id) else { return }
            if let payload = record.payload {
                library.applySyncedStory(try SyncCoding.decode(Story.self, from: payload))
            } else {
                library.deleteStories(ids: [id])
            }
        case .progress:
            guard let id = UUID(uuidString: key.id), let payload = record.payload else { return }
            library.applySyncedProgress(storyID: id, progress: try SyncCoding.decode(StoryProgress.self, from: payload))
        }
    }
}

/// The ledger on disk: `Documents/StoryEngine/Sync/ledger.json`.
struct SyncLedgerStore: Sendable {
    static let defaultSubdirectory = "Sync"
    private let subdirectory: String

    init(subdirectory: String = SyncLedgerStore.defaultSubdirectory) {
        self.subdirectory = subdirectory
    }

    private var url: URL? {
        StoryEngineStorage.directory(subdirectory)?.appendingPathComponent("ledger.json")
    }

    func load() -> SyncLedger {
        guard let url, let data = try? Data(contentsOf: url),
              let ledger = try? StoryEngineStorage.makeDecoder().decode(SyncLedger.self, from: data) else {
            // An unreadable ledger is an empty one: the next sync re-sends
            // and re-reads, and the rules make re-sending harmless.
            return SyncLedger()
        }
        return ledger
    }

    func save(_ ledger: SyncLedger) {
        guard let url else { return }
        do {
            try StoryEngineStorage.write(try StoryEngineStorage.makeEncoder().encode(ledger), to: url)
        } catch {
            logger.error("🛑 Eşitleme defteri yazılamadı")
        }
    }

    func erase() {
        guard let directory = StoryEngineStorage.directory(subdirectory) else { return }
        try? FileManager.default.removeItem(at: directory)
    }
}
