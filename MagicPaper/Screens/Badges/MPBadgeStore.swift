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
        // Masallar'ın klasikleri ve Original'leri kitaplıkta durmaz; FAZ 17'den
        // beri defterin `finished` kümesinde dururlar.
        for id in ledger.finished {
            guard let uuid = UUID(uuidString: id) else { continue }
            switch Self.tellingKind(of: uuid) {
            case .original: ledger.originals.insert(id)
            case .classic:  ledger.classics.insert(id)
            case nil:       break
            }
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
                        heardFamilyVoice: Bool = false, now: Date = Date()) -> MPBadgeAwards {
        var ledger = ledger(for: profile, stories: stories, now: now)
        let before = ledger
        let badges = ledger.recordFinished(Self.facts(for: story, heardFamilyVoice: heardFamilyVoice), at: now)
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

    /// Masalın deftere yazılan bilgisi (rozet planı R2). Hepsi masalın kendi
    /// kaydından okunur, kimlikle; ad ya da metin deftere girmez.
    /// - yer, dost, Masal ailem: `StoryOrigin` (motor masalı)
    /// - sürpriz: "Bana sürpriz yap" ile yazıldı (`selectionStrategy`)
    /// - kelimeler: sayfalardaki öğretilen kelimeler; masal sonuna kadar okundu
    /// - klasik ve Original: Masallar'ın okuyucudan geçen masalları
    /// - ailenin sesi: okuyucu bu masalda ailenin kaydını gerçekten çaldı
    @MainActor
    static func facts(for story: Story, heardFamilyVoice: Bool = false) -> MPFinishFacts {
        let id = story.id.uuidString
        let origin = story.origin
        let episode = origin?.seriesEpisode
        let seriesID = origin?.seriesID
        var facts = MPFinishFacts(storyID: id, mode: story.mpMode,
                                  seriesCompletedID: episode == SeriesCopy.episodeCount ? seriesID : nil,
                                  seriesSecondID: episode == 2 ? seriesID : nil)
        switch tellingKind(of: story.id) {
        case .original: facts.originalID = id
        case .classic:  facts.classicID = id
        case nil:       break
        }
        facts.isSurprise = origin?.selectionStrategy == StorySelectionStrategy.surprise.rawValue
        facts.placeID = origin.map(\.settingID).flatMap(nonEmpty)
        facts.companionIDs = origin.map(\.companionID).flatMap(nonEmpty).map { [$0] } ?? []
        facts.familyMemberIDs = origin?.familyCharacterID.flatMap(nonEmpty).map { [$0] } ?? []
        facts.heardFamilyVoice = heardFamilyVoice
        facts.newWords = Array(Set(story.pages.flatMap { $0.words ?? [] }.map(\.id)))
        return facts
    }

    private enum TellingKind { case classic, original }

    /// Masallar'ın masalı mı (klasik ya da MagicPaper Original), motorun mu?
    @MainActor
    private static func tellingKind(of id: UUID) -> TellingKind? {
        guard ClassicsCatalog.contains(id) else { return nil }
        let catalog = ClassicsCatalog.bundled
        if catalog.originalCover(feedID: id) != nil || OriginalIndex.cover(for: id) != nil
            || catalog.tale(id)?.origin == .orijinal {
            return .original
        }
        return .classic
    }

    private static func nonEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty || trimmed == "none" ? nil : trimmed
    }

    /// Masal okunurken kelime kartı açıldı ("Meraklı parmak"). Rozet burada
    /// verilmez: masal sonunda verilir ve orada kutlanır.
    func markWordCardOpened(for profileID: UUID) {
        // Defter yoksa boş kurulur (sürüm 0): ilk `ledger(for:)` onu yine kitaplıktan doldurur.
        var ledger = storedLedger(for: profileID) ?? MPBadgeLedger()
        guard !ledger.wordCardOpened else { return }
        ledger.wordCardOpened = true
        save(ledger, for: profileID)
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
