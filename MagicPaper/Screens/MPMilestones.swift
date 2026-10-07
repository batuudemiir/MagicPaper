import Foundation
import StoryEngine

/// Sakin kilometre taşları (rozet), CLAUDE.md ilke 7 (karar 3 Ekim 2026).
///
/// - Yalnızca okuyarak kazanılır: sonuna kadar okunan farklı masallar. Süre,
///   uygulama kullanımı ya da üst üste gün sayılmaz.
/// - Kazanılan rozet kaybolmaz: masal silinse de defterde kalır.
/// - Kıyas, geri sayım, "az kaldı" yok: Benim köşem yalnızca kazanılanları
///   gösterir. Masal sonunda yeni kazanılan bir satırla söylenir; bildirim yok.
///
/// Liste FAZ 17 planının onaylı listesi (Batuhan, 7 Ekim 2026).
enum MPMilestone: String, CaseIterable, Identifiable, Codable {
    case firstStory
    case fiveStories
    case tenStories
    case twentyFiveStories
    case sevenBedtime
    case firstAdventure
    case firstLearning
    case firstSeriesCompleted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstStory:           return "İlk masal"
        case .fiveStories:          return "5 masal"
        case .tenStories:           return "10 masal"
        case .twentyFiveStories:    return "25 masal"
        case .sevenBedtime:         return "7 uyku masalı"
        case .firstAdventure:       return "İlk macera"
        case .firstLearning:        return "İlk öğrenelim masalı"
        case .firstSeriesCompleted: return "İlk seri tamamlandı"
        }
    }

    var icon: String {
        switch self {
        case .firstStory:           return "sparkles"
        case .fiveStories:          return "book"
        case .tenStories:           return "books.vertical"
        case .twentyFiveStories:    return "trophy"
        case .sevenBedtime:         return "moon"
        case .firstAdventure:       return "tent"
        case .firstLearning:        return "lightbulb"
        case .firstSeriesCompleted: return "pawprint"
        }
    }

    var tone: MPWorldTone {
        switch self {
        case .firstStory:           return .lav
        case .fiveStories:          return .sky
        case .tenStories:           return .green
        case .twentyFiveStories:    return .yellow
        case .sevenBedtime:         return .lav
        case .firstAdventure:       return .mint
        case .firstLearning:        return .yellow
        case .firstSeriesCompleted: return .peach
        }
    }

    func isMet(by ledger: MPBadgeLedger) -> Bool {
        switch self {
        case .firstStory:           return ledger.finished.count >= 1
        case .fiveStories:          return ledger.finished.count >= 5
        case .tenStories:           return ledger.finished.count >= 10
        case .twentyFiveStories:    return ledger.finished.count >= 25
        case .sevenBedtime:         return ledger.finishedBedtime.count >= 7
        case .firstAdventure:       return ledger.finishedAdventure.count >= 1
        case .firstLearning:        return ledger.finishedLearning.count >= 1
        case .firstSeriesCompleted: return ledger.completedSeries.count >= 1
        }
    }
}

/// Bir çocuğun rozet defteri: bitirilen farklı masallar ve kazanılan
/// rozetler. Yalnızca büyür; bu yüzden iki cihazın defteri birleşince hiçbir
/// rozet kaybolmaz (`merged`).
struct MPBadgeLedger: Codable, Equatable {
    var finished: Set<String> = []
    var finishedBedtime: Set<String> = []
    var finishedAdventure: Set<String> = []
    var finishedLearning: Set<String> = []
    var completedSeries: Set<String> = []
    /// Rozet → ilk kazanıldığı an.
    var earned: [String: Date] = [:]

    var earnedMilestones: [MPMilestone] {
        MPMilestone.allCases.filter { earned[$0.rawValue] != nil }
    }

    /// Bir masal sonuna kadar okundu. Aynı masal ikinci kez sayılmaz.
    /// Yeni kazanılan rozetleri döndürür.
    @discardableResult
    mutating func recordFinished(storyID: String, mode: StoryMode?, seriesCompletedID: String? = nil,
                                 at now: Date = Date()) -> [MPMilestone] {
        finished.insert(storyID)
        switch mode {
        case .bedtime:   finishedBedtime.insert(storyID)
        case .adventure: finishedAdventure.insert(storyID)
        case .learning:  finishedLearning.insert(storyID)
        case nil:        break
        }
        if let seriesCompletedID { completedSeries.insert(seriesCompletedID) }
        return award(at: now)
    }

    mutating func award(at now: Date = Date()) -> [MPMilestone] {
        let fresh = MPMilestone.allCases.filter { earned[$0.rawValue] == nil && $0.isMet(by: self) }
        for milestone in fresh { earned[milestone.rawValue] = now }
        return fresh
    }

    /// İki defterin birleşimi: her küme birleşir, her rozetin en erken tarihi kalır.
    func merged(with other: MPBadgeLedger) -> MPBadgeLedger {
        var out = self
        out.finished.formUnion(other.finished)
        out.finishedBedtime.formUnion(other.finishedBedtime)
        out.finishedAdventure.formUnion(other.finishedAdventure)
        out.finishedLearning.formUnion(other.finishedLearning)
        out.completedSeries.formUnion(other.completedSeries)
        out.earned.merge(other.earned) { min($0, $1) }
        return out
    }
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

    /// Defter; hiç yoksa kitaplıktaki bitmiş masallardan kurulur (FAZ 17
    /// öncesi okunanlar da sayılır).
    @MainActor
    func ledger(for profile: UserProfile, stories: [Story]) -> MPBadgeLedger {
        if let stored = storedLedger(for: profile.id) { return stored }
        var ledger = MPBadgeLedger()
        for story in stories where story.isFinished && story.belongs(to: profile) {
            ledger.recordFinished(storyID: story.id.uuidString, mode: story.mpMode)
        }
        save(ledger, for: profile.id)
        return ledger
    }

    /// Okuyucu masal sonuna varınca. Yeni kazanılan rozetleri döndürür.
    @MainActor
    func recordFinished(_ story: Story, profile: UserProfile, stories: [Story]) -> [MPMilestone] {
        var ledger = ledger(for: profile, stories: stories)
        let completedSeries = (story.origin?.seriesEpisode == SeriesCopy.episodeCount) ? story.origin?.seriesID : nil
        let fresh = ledger.recordFinished(storyID: story.id.uuidString, mode: story.mpMode,
                                          seriesCompletedID: completedSeries)
        save(ledger, for: profile.id)
        return fresh
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

/// Masal sonunda gösterilecek yeni rozetler (okuyucu yazar, kapanış yaprağı okur).
@MainActor
final class MPBadgeNews: ObservableObject {
    static let shared = MPBadgeNews()
    @Published var fresh: [MPMilestone] = []
    private init() {}
}
