import Foundation
import OSLog
import SwiftUI
import UIKit
import Combine
import StoryEngine

/// `print` reaches the shared device console verbatim. `Logger` redacts
/// interpolated values as `<private>` outside a debugger by default.
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "StoryGenerationManager")

/// Orchestrates the entire story creation workflow
/// Handles background story generation with status updates
@MainActor
class StoryGenerationManager: ObservableObject {
    
    static let shared = StoryGenerationManager(library: LibraryPersistence.shelf)

    // MARK: - Published Properties

    @Published var stories: [Story] = []
    @Published var isGenerating: Bool = false

    // MARK: - Private Properties

    private let fileManager = FileManagerService.shared

    /// Where the library lives: the legacy `UserDefaults` blob before the
    /// cutover, one file per story after it (E1, `LibraryShelf`). Built
    /// after the migration has run, so it reads the phase this launch ends in.
    private let library: LibraryShelf
    private var cancellables = Set<AnyCancellable>()

    /// Beş arkadaş pilotu (B4): yeni masalı eski motorun mu P56'nın mı yazacağı.
    private let runtime: StoryRuntimeRouter
    private let p56Writer: P56StoryWriter
    /// The last `createStory` routing decision, reason code only; nil when the
    /// request had no mode and the router was not asked.
    private(set) var lastRuntimeDecision: StoryRuntimeDecision?

    init(library: LibraryShelf, notifications: NotificationCenter = .default,
         runtime: StoryRuntimeRouter = .shared,
         p56Writer: P56StoryWriter = P56StoryWriter()) {
        self.library = library
        self.runtime = runtime
        self.p56Writer = p56Writer
        loadStories()
        auditStoriesMissingImageURLs()
        // A background launch on a locked device cannot read the story files
        // (`.completeUnlessOpen`); they join the shelf once the device unlocks.
        notifications.publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in self.recoverUnreadableStories() }
            }
            .store(in: &cancellables)
    }

    // MARK: - Persistence

    /// Every mutation of `stories` ends here. Before cutover this writes the
    /// whole blob as it always did; after, only the files that changed.
    private func saveStories() {
        library.save(stories)
    }

    private func loadStories() {
        stories = library.load()
    }

    /// Adds the stories whose files a locked device could not read at launch.
    /// Each goes where `applySyncedStory` would put it; nothing else moves.
    func recoverUnreadableStories() {
        for story in library.recoverUnreadable() where !stories.contains(where: { $0.id == story.id }) {
            let index = stories.firstIndex(where: { $0.createdAt < story.createdAt }) ?? stories.endIndex
            stories.insert(story, at: index)
        }
    }

    /// How many `stories.undecodable.*` blobs to keep.
    ///
    /// More than one because the same fault can strike twice before anyone
    /// looks, and the oldest copy is the one that predates the damage. Not
    /// unbounded, because these are whole libraries and they sit in
    /// `UserDefaults`.
    static let undecodableBackupLimit = 3

    static let undecodableBackupPrefix = "stories.undecodable."

    /// Keeps the newest `limit` recovery blobs and removes the rest.
    static func pruneUndecodableBackups(
        keeping limit: Int,
        in defaults: UserDefaults = .standard
    ) {
        let keys = defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(undecodableBackupPrefix) }
            // The suffix is a unix timestamp, so it sorts newest-first
            // numerically. String order would put "1000000000" after
            // "999999999" and drop the wrong one.
            .sorted { lhs, rhs in
                let l = Int(lhs.dropFirst(undecodableBackupPrefix.count)) ?? 0
                let r = Int(rhs.dropFirst(undecodableBackupPrefix.count)) ?? 0
                return l > r
            }
        for key in keys.dropFirst(max(0, limit)) {
            defaults.removeObject(forKey: key)
            logger.debug("🧹 Eski kurtarma yedeği kaldırıldı: \(key)")
        }
    }
    
    /// Reports stories written before `imageUrl` existed.
    ///
    /// This used to be the tail of `migrateOldStoriesIfNeeded()`. The head of
    /// that function deleted `UserDefaults["stories"]` outright whenever the
    /// blob passed four megabytes — no copy, no confirmation, on a launch —
    /// and set `stories = []` over a child's whole shelf. It has moved to
    /// `LibraryMigration`, which copies the blob to quarantine, reads the copy
    /// back, and then leaves the original alone. Nothing on the launch path
    /// removes user data any more.
    ///
    /// What remains here reads and reports. It never wrote anything.
    private func auditStoriesMissingImageURLs() {
        var needsSave = false
        for (_, story) in stories.enumerated() {
            for (pageIndex, page) in story.pages.enumerated() {
                // If page has no imageUrl but has imageFileName, try to load from file
                if page.imageUrl == nil && page.imageFileName != nil {
                    logger.warning("⚠️ Found page without imageUrl: Story \(story.id) Page \(pageIndex + 1)")
                    logger.debug("   This is an old story that needs migration")
                    needsSave = true
                }
            }
        }
        
        if needsSave {
            logger.warning("⚠️ Found \(self.stories.count) stories that may need imageUrl migration")
            logger.warning("⚠️ These stories will display placeholder images")
            logger.debug("💡 Solution: Delete old stories and create new ones, OR manually add imageUrls")
        }
    }
    
    // MARK: - Public Helpers
    
    func deleteStory(id: UUID) {
        // Delete images from file system
        fileManager.deleteStoryImages(storyId: id)
        // Kendi sesin (FAZ 18): masalla birlikte kayıtları da gider.
        VoiceRecordingStore.shared.deleteRecordings(for: id)
        
        // Remove from array
        stories.removeAll { $0.id == id }
        saveStories()
        
        logger.debug("✅ Story deleted: \(id)")
    }

    /// Deletes several stories with one save — used when a child's profile,
    /// and with it their shelf, is deleted.
    func deleteStories(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        for id in ids {
            fileManager.deleteStoryImages(storyId: id)
            VoiceRecordingStore.shared.deleteRecordings(for: id)
        }
        stories.removeAll { ids.contains($0.id) }
        saveStories()

        logger.debug("✅ \(ids.count) stories deleted")
    }
    
    // Kütüphaneye hikaye ekle (metin/günlük hikayeler için)
    func addStoryToLibrary(_ story: Story) {
        // Aynı ID'ye sahip hikaye varsa güncelle, yoksa ekle
        if let index = stories.firstIndex(where: { $0.id == story.id }) {
            stories[index] = story
        } else {
            stories.insert(story, at: 0)
        }
        saveStories()
        logger.debug("✅ Story added to library: \(story.id)")
    }
    
    /// İlk profil oluşturulduğunda eski örnek masallar yeni çocuğun adına
    /// uyarlanır (04-STATE-INTERACTIONS.md, akış 1). Yeni kurulum artık örnek
    /// masal kurmuyor (17 Kasım 2026); bu yalnızca önceki sürümün cihazda
    /// bıraktığı Zephyr ve Luna kopyaları için duruyor.
    func adoptSampleStories(childName: String, childProfileID: UUID? = nil) {
        guard !childName.isEmpty else { return }
        let samples = ["Zephyr", "Luna"]
        var changed = false
        for index in stories.indices where samples.contains(stories[index].childName) {
            let old = stories[index].childName
            stories[index].childName = childName
            stories[index].childProfileID = childProfileID
            stories[index].title = stories[index].title.replacingOccurrences(of: old, with: childName)
            for pageIndex in stories[index].pages.indices {
                stories[index].pages[pageIndex].text =
                    stories[index].pages[pageIndex].text.replacingOccurrences(of: old, with: childName)
            }
            changed = true
        }
        if changed {
            saveStories()
            logger.debug("✅ Örnek masallar profile uyarlandı")
        }
    }

    /// Okuma ilerlemesini yazar.
    ///
    /// **Anında diske indirilir.** Okuma ilerlemesi, kaybolması en olası
    /// veridir çünkü tam da uygulamanın kapanmasından hemen önce değişir:
    /// çocuk son sayfayı çevirir, ebeveyn uygulamadan çıkar. `UserDefaults`
    /// yazımı tembel; süreç o arada sonlandırılırsa değer hiç diske inmez ve
    /// "kaldığın yer" bir sonraki açılışta yok olur. Ana sayfanın birincil
    /// kartı buna bağlı olduğu için burada bekleyemeyiz.
    ///
    /// Maliyeti bilerek kabul ediliyor: `saveStories()` bütün kütüphaneyi
    /// yeniden kodluyor (~37 KB) ve bu her sayfa çevirmede oluyor. Doğru çözüm
    /// ilerlemeyi kendi küçük deposuna almak, ama o zaman aynı olgunun iki
    /// kaynağı olur — bu projede defalarca canımızı yakan şey. Tek kaynak
    /// kalsın, yazı da gerçekten insin.
    func updateLastReadPage(storyId: UUID, page: Int) {
        guard let index = stories.firstIndex(where: { $0.id == storyId }) else {
            // Sessizce dönüyordu. Okuyucuya kütüphanede olmayan bir masal
            // verildiğinde ilerleme hiçbir yere yazılmıyor, hiçbir şey de
            // söylenmiyordu — okuma çalışıyor, kayıt çalışmıyor, arada fark
            // yok gibi görünüyordu.
            assertionFailure("İlerleme yazılamadı: '\(storyId)' kütüphanede yok.")
            logger.error("🛑 İlerleme yazılamadı: '\(storyId)' kütüphanede yok.")
            return
        }

        guard stories[index].lastReadPage != page else { return }
        stories[index].lastReadPage = page
        stories[index].lastReadAt = Date()
        saveStories()
        // Tembel yazımı zorla indir. `synchronize()` kullanımdan kaldırıldı
        // sayılır ve çoğu yerde gereksizdir; burada gereklidir, çünkü bu değeri
        // yazan an ile sürecin öldüğü an arasında saniyeler olabiliyor.
        // Kesişimden sonra (E1) dosya yazımı zaten anında iner; `flush` yalnızca
        // eski yolda `synchronize()` çağırır.
        library.flush()

        logger.debug("📖 Updated reading progress for story \(storyId): page \(page)")
    }
    
    /// Masal açıldı — sayfa ilerlemese bile.
    ///
    /// `updateLastReadPage` yalnızca EN İLERİ sayfa değiştiğinde yazar, ki
    /// doğrusu budur: gereksiz yazma bütün `[Story]` dizisini yeniden JSON'a
    /// çevirmek demek. Ama o kural tek başına "en son hangi masalı okudu"
    /// sorusunu yanlış cevaplıyor: 3. sayfada bıraktığı masalı bu akşam açıp
    /// aynı sayfayı tekrar okuyan bir çocuk hiçbir iz bırakmıyor, ve ana sayfa
    /// başka bir masalı "kaldığın yer" diye gösteriyor.
    ///
    /// Açmak da okumaktır. Oturum başına bir yazma.
    func markOpened(storyId: UUID) {
        guard let index = stories.firstIndex(where: { $0.id == storyId }) else { return }
        stories[index].lastReadAt = Date()
        saveStories()
    }

    func getStory(id: UUID) -> Story? {
        return stories.first { $0.id == id }
    }
    
    
}

extension StoryGenerationManager {
    @MainActor
    /// Builds a story from the two choices the new creation flow collects, and
    /// saves it.
    ///
    /// Replaces `createOfflineTextStory`, which took a genre string, a theme
    /// string and hard-coded ids — `setting_forest_001` and
    /// `companion_fox_001` — so every choice the user made was discarded (B3).
    /// Here the choices are stable ids, the seed is kept so the story can be
    /// rebuilt (B5), and a failure is thrown rather than printed (B2).
    ///
    /// Returns the saved story. The caller opens it; nothing here navigates.
    ///
    /// `mode` is already resolved — a surprise has been turned into one of the
    /// three modes by `OfflineStoryService.resolveMode` — and `strategy` records
    /// how. Both nil builds a story the way it was built before modes existed.
    @discardableResult
    func createStory(
        for profile: UserProfile,
        mode: StoryMode? = nil,
        strategy: StorySelectionStrategy? = nil,
        storyIdeaID: String?,
        companionID: String?,
        subOption: String? = nil,
        seed: String? = nil,
        family: FamilyCharacter? = nil,
        occasion: OccasionRequest? = nil
    ) async throws -> Story {
        isGenerating = true
        defer { isGenerating = false }

        let service = OfflineStoryService.shared
        // E2: everything the story is written from, gathered in one place.
        let context = StoryContextBuilder().build(
            for: profile, library: stories, mode: mode, strategy: strategy,
            storyIdeaID: storyIdeaID, companionID: companionID,
            subOption: subOption, family: family, occasion: occasion)

        // Beş arkadaş pilotu (B4, K-B): P56 yalnız isteğin tamamını taşıyabildiğinde
        // yazar; taşıyamazsa ya da yazamazsa aynı bağlamla eski yol yazar.
        lastRuntimeDecision = nil
        if let mode {
            var decision = runtime.decide(StoryRuntimeRequest(
                age: profile.age, mode: mode, companionID: companionID, family: family,
                topicID: subOption, occasion: occasion?.kind.rawValue, safety: service.currentSafety))
            // Seçilen kart bir söz; P56 onu taşıyamaz.
            if case .p56 = decision.route, storyIdeaID != nil {
                decision = StoryRuntimeDecision(route: .legacy, reason: .unsupportedRequest)
            }
            if case .p56(let source) = decision.route {
                if let package = runtime.package(for: source) {
                    do {
                        let story = try p56Writer.write(context: context, mode: mode, strategy: strategy,
                                                        safety: service.currentSafety, package: package, seed: seed)
                        lastRuntimeDecision = decision
                        stories.insert(story, at: 0)
                        saveStories()
                        MPFunnel().record(.firstStory)
                        return story
                    } catch {
                        decision = StoryRuntimeDecision(route: decision.route, reason: .composeFailed)
                    }
                } else {
                    decision = StoryRuntimeDecision(route: .legacy, reason: .payloadUnavailable)
                }
            }
            lastRuntimeDecision = decision
            if let reason = decision.reason {
                logger.info("Story runtime: legacy (\(reason.rawValue, privacy: .public))")
            }
        }

        let composed = try service.compose(context, seed: seed)

        let mapped = OfflineStoryMapper.appStory(
            from: composed.story,
            childName: profile.name,
            childProfileID: profile.id,
            storyIdeaID: storyIdeaID,
            catalogVersion: composed.catalogVersion,
            contentSource: composed.contentSource,
            mode: mode,
            selectionStrategy: strategy,
            ageBand: service.servedBand(forAge: profile.age),
            subOption: subOption,
            familyCharacter: family,
            occasion: occasion
        )
        // Masal dünyası hatırlar: E3'ten beri motorun içinde. Hatırlama
        // cümlesi ilk sayfada zaten var, `origin.recalled` eşlemeden geliyor.
        let remembered = mapped
        // Görselli kitap (B2): kayıtlı bir kitap karakteri varsa ve bayrak
        // açıksa hazır sahneler eklenir; yoksa masal bugünkü gibi metin çıkar.
        let story = await IllustratedBookBinder.illustrateIfEnabled(
            remembered,
            composed: composed.story,
            profile: profile,
            mode: mode,
            ageBand: service.servedBand(forAge: profile.age),
            existing: stories
        )

        stories.insert(story, at: 0)
        saveStories()
        MPFunnel().record(.firstStory)
        return story
    }

    /// The modes of this child's most recent stories, newest first.
    ///
    /// What "Bana sürpriz yap" looks at so it does not repeat itself. Only
    /// stories that recorded a mode count; older ones say nothing.
    /// Delegates to `StoryContextBuilder`, the single source.
    func recentModes(for profile: UserProfile, limit: Int = StoryModeResolver.historyWindow) -> [StoryMode] {
        StoryContextBuilder.recentModes(of: stories, for: profile, limit: limit)
    }

    /// The titles of this child's newest stories, for the engine to avoid
    /// writing again (`TitleComposer`). Only titles: nothing else of the
    /// library reaches the engine for this. Delegates to `StoryContextBuilder`.
    static func recentTitles(
        of stories: [Story], for profile: UserProfile, limit: Int = titleMemory
    ) -> Set<String> {
        StoryContextBuilder.recentTitles(of: stories, for: profile, limit: limit)
    }

    /// How many recent titles are avoided. A blueprint has 4-6 title
    /// patterns; a longer memory would mark every one used and change nothing.
    static let titleMemory = 12

    /// What this child's most recent stories were made of, newest first
    /// (FAZ 12). The engine cools that content down, so the next story is
    /// less likely to repeat the last ones — for every child, interests or not.
    /// Stories without an origin (written before the offline engine) say
    /// nothing and are skipped. Delegates to `StoryContextBuilder`.
    func recentOrigins(for profile: UserProfile, limit: Int = SelectionScoring.historyWindow) -> [StoryOrigin] {
        StoryContextBuilder.recentOrigins(of: stories, for: profile, limit: limit)
    }

}

// MARK: - Account sync (FAZ 16)

extension StoryGenerationManager {
    /// A story another device wrote. Added when missing, never rewritten: a
    /// story's text does not change once written, and the copy already here
    /// keeps whatever this device knows about it (its cover file, its place).
    func applySyncedStory(_ story: Story) {
        guard !stories.contains(where: { $0.id == story.id }) else { return }
        let index = stories.firstIndex(where: { $0.createdAt < story.createdAt }) ?? stories.endIndex
        stories.insert(story, at: index)
        saveStories()
    }

    /// Where another device left a story. The later reading wins; a reading
    /// position never moves back because an older one arrived late.
    func applySyncedProgress(storyID: UUID, progress: StoryProgress) {
        guard let index = stories.firstIndex(where: { $0.id == storyID }) else { return }
        let local = stories[index].lastReadAt ?? .distantPast
        guard (progress.lastReadAt ?? .distantPast) > local else { return }
        stories[index].lastReadPage = progress.lastReadPage
        stories[index].lastReadAt = progress.lastReadAt
        saveStories()
    }

    /// After `LocalDataEraser`: an empty shelf, on disk and on screen. Before
    /// cutover the empty write also carries the erasure to the shadow copy;
    /// after it, the shelf deletes every file it knew of.
    func resetAfterErase() {
        stories = []
        saveStories()
    }
}
