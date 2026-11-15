import Foundation
import StoryEngine

/// Bir masal sonunda yeni kazanılanlar: rozetler ve Yıldız katları.
struct MPBadgeAwards: Equatable {
    var badges: [MPBadge] = []
    var starLevels: [MPStarLevel] = []
    var isEmpty: Bool { badges.isEmpty && starLevels.isEmpty }
}

/// Çocuk başına rozet defterleri (`UserDefaults`, `mp_badges_<profil>`).
/// Hesapla senkronlanır (`SyncCollection.badges`); profil silme ve "Tüm
/// verileri sil" temizler.
struct MPBadgeStore {
    var defaults: UserDefaults = .standard

    static let keyPrefix = "mp_badges_"
    static func key(for profileID: UUID) -> String { keyPrefix + profileID.uuidString }

    func storedLedger(for profileID: UUID) -> MPBadgeLedger? {
        guard let data = defaults.data(forKey: Self.key(for: profileID)) else { return nil }
        return try? JSONDecoder().decode(MPBadgeLedger.self, from: data)
    }

    func save(_ ledger: MPBadgeLedger, for profileID: UUID) {
        guard let data = try? JSONEncoder().encode(ledger) else { return }
        defaults.set(data, forKey: Self.key(for: profileID))
    }

    /// Defter. Hiç yoksa kitaplıktaki bitmiş masallardan kurulur (FAZ 17
    /// öncesi okunanlar da sayılır). Katalog sürümü eskiyse (rozet planı
    /// öncesi defter) eksik bilgiler kitaplıktan doldurulur ve yeni
    /// eşiklere ulaşan rozetler ile katlar **sessizce** verilir: güncellemeden
    /// sonra arka arkaya kutlama patlamaz (`seen`).
    @MainActor
    func ledger(for profile: UserProfile, stories: [Story], now: Date = Date()) -> MPBadgeLedger {
        let stored = storedLedger(for: profile.id)
        if let stored, stored.catalogVersion >= MPBadgeCatalog.version { return stored }
        var ledger = stored ?? MPBadgeLedger()
        let mine = stories.filter { $0.belongs(to: profile) }
        for story in mine where story.isFinished || ledger.finished.contains(story.id.uuidString) {
            // Okunduğu gün bilinmiyor; son okunduğu gün en yakın tahmin.
            let day = story.lastReadAt ?? story.createdAt
            ledger.recordFinished(Self.facts(for: story), at: day)
        }
        ledger.morningRuleSince = ledger.morningRuleSince ?? MPStars.ruleSince(in: defaults, now: now)
        // `recordFinished` tarihleri geçmiş günlere yazdı; geriye dönük
        // rozetlerin tarihi bugün olur (FAZ 17 de böyle yapıyordu).
        let backfilled = ledger.earned.filter { stored?.earned[$0.key] == nil }.keys
        for id in backfilled { ledger.earned[id] = now }
        let fresh = ledger.award(at: now)
        let levels = ledger.awardStarLevels(score: MPStars.score(createdAt: profile.createdAt, ledger: ledger, now: now),
                                            at: now)
        ledger.seen.formUnion(backfilled)
        ledger.seen.formUnion(fresh.map(\.id))
        ledger.seen.formUnion(levels.map(\.id))
        ledger.catalogVersion = MPBadgeCatalog.version
        save(ledger, for: profile.id)
        return ledger
    }

    /// Okuyucu masal sonuna varınca. Yeni kazanılan rozetleri ve katları döndürür.
    @MainActor
    func recordFinished(_ story: Story, profile: UserProfile, stories: [Story],
                        now: Date = Date()) -> MPBadgeAwards {
        var ledger = ledger(for: profile, stories: stories, now: now)
        let before = ledger
        let badges = ledger.recordFinished(Self.facts(for: story), at: now)
        let levels = ledger.awardStarLevels(score: MPStars.score(createdAt: profile.createdAt, ledger: ledger, now: now),
                                            at: now)
        save(ledger, for: profile.id)
        // Defter değiştiyse hesap eşitlemesi de bilsin (diğer aile depoları
        // gibi); yoksa yeni rozet bir sonraki başka değişikliği beklerdi.
        if ledger != before {
            NotificationCenter.default.post(name: .mpFamilyDataChanged, object: nil)
        }
        return MPBadgeAwards(badges: badges, starLevels: levels)
    }

    /// Kutlanan rozet ve katlar bir daha kutlanmaz (R4 masal sonu anı yazar).
    func markSeen(_ ids: [String], for profileID: UUID) {
        guard var ledger = storedLedger(for: profileID) else { return }
        ledger.seen.formUnion(ids)
        save(ledger, for: profileID)
    }

    /// Masalın deftere yazılan bilgisi. R1: kimlik, mod, seri. Yer, dost,
    /// aile, ses, kelime, klasik ve Original R2'de buradan dolar.
    static func facts(for story: Story) -> MPFinishFacts {
        let episode = story.origin?.seriesEpisode
        let seriesID = story.origin?.seriesID
        return MPFinishFacts(storyID: story.id.uuidString, mode: story.mpMode,
                             seriesCompletedID: episode == SeriesCopy.episodeCount ? seriesID : nil,
                             seriesSecondID: episode == 2 ? seriesID : nil)
    }

    /// Hesaptan gelen defter: birleşir, kaybolmaz.
    func merge(_ remote: MPBadgeLedger, for profileID: UUID) {
        let merged = (storedLedger(for: profileID) ?? MPBadgeLedger()).merged(with: remote)
        save(merged, for: profileID)
    }

    func erase(for profileID: UUID) {
        defaults.removeObject(forKey: Self.key(for: profileID))
    }

    static func eraseAll(in defaults: UserDefaults = .standard) {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(keyPrefix) {
            defaults.removeObject(forKey: key)
        }
    }
}

/// Masal sonunda gösterilecek yeniler (okuyucu yazar, kapanış yaprağı okur).
@MainActor
final class MPBadgeNews: ObservableObject {
    static let shared = MPBadgeNews()
    @Published var fresh: [MPBadge] = []
    @Published var freshStarLevels: [MPStarLevel] = []
    private init() {}
}
