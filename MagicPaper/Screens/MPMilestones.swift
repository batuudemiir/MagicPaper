import Foundation

/// Sakin kilometre taşları (rozet), CLAUDE.md ilke 7 (karar 3 Ekim 2026).
///
/// - Yalnızca okuyarak kazanılır: sonuna kadar okunan masal ve birlikte
///   okunan günler. Uygulamada geçen süre sayılmaz.
/// - Kazanılan rozet kaybolmaz: okuma serisi bozulsa da "3 gün üst üste"
///   kalır. Bu yüzden kazanılanlar çocuk başına saklanır, her seferinde
///   yeniden hesaplanmaz.
/// - Kıyas yok, geri sayım yok, bildirim yok. Masal sonunda ve Benim köşem'de.
///
/// Teslimdeki "Uzay kaşifi" (uzay içeriği yok) ve "30 gün seri" (her gün
/// gelme baskısı) yerine "Macera kaşifi" ve "25 masal" var.
enum MPMilestone: String, CaseIterable, Identifiable {
    case firstStory
    case threeDays
    case adventurer
    case tenStories
    case sevenBedtime
    case twentyFiveStories

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstStory:        return "İlk masal"
        case .threeDays:         return "3 gün üst üste"
        case .adventurer:        return "Macera kaşifi"
        case .tenStories:        return "10 masal"
        case .sevenBedtime:      return "7 uyku masalı"
        case .twentyFiveStories: return "25 masal"
        }
    }

    var icon: String {
        switch self {
        case .firstStory:        return "sparkles"
        case .threeDays:         return "flame"
        case .adventurer:        return "tent"
        case .tenStories:        return "book"
        case .sevenBedtime:      return "moon"
        case .twentyFiveStories: return "trophy"
        }
    }

    var tone: MPWorldTone {
        switch self {
        case .firstStory:        return .lav
        case .threeDays:         return .peach
        case .adventurer:        return .sky
        case .tenStories:        return .green
        case .sevenBedtime:      return .lav
        case .twentyFiveStories: return .yellow
        }
    }

    /// Okunanlar.
    struct Reading: Equatable {
        var finishedStories: Int
        var finishedBedtime: Int
        var finishedAdventure: Int
        var daysInARow: Int
    }

    func isMet(by r: Reading) -> Bool {
        switch self {
        case .firstStory:        return r.finishedStories >= 1
        case .threeDays:         return r.daysInARow >= 3
        case .adventurer:        return r.finishedAdventure >= 3
        case .tenStories:        return r.finishedStories >= 10
        case .sevenBedtime:      return r.finishedBedtime >= 7
        case .twentyFiveStories: return r.finishedStories >= 25
        }
    }
}

/// Çocuk başına kazanılmış rozetler. Yalnızca eklenir; profil silinince ya
/// da "Tüm verileri sil" ile silinir.
struct MPBadgeStore {
    var defaults: UserDefaults = .standard

    static func key(for profileID: UUID) -> String { "mp_badges_\(profileID.uuidString)" }

    func earned(for profileID: UUID) -> Set<MPMilestone> {
        Set((defaults.stringArray(forKey: Self.key(for: profileID)) ?? []).compactMap(MPMilestone.init(rawValue:)))
    }

    /// Bugünkü okumayla yeni kazanılanları ekler ve yalnızca yeni olanları döndürür.
    @discardableResult
    func update(for profileID: UUID, reading: MPMilestone.Reading) -> [MPMilestone] {
        let had = earned(for: profileID)
        let now = MPMilestone.allCases.filter { had.contains($0) || $0.isMet(by: reading) }
        let fresh = now.filter { !had.contains($0) }
        if !fresh.isEmpty {
            defaults.set(now.map(\.rawValue), forKey: Self.key(for: profileID))
        }
        return fresh
    }

    func erase(for profileID: UUID) {
        defaults.removeObject(forKey: Self.key(for: profileID))
    }

    static func eraseAll(in defaults: UserDefaults = .standard) {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("mp_badges_") {
            defaults.removeObject(forKey: key)
        }
    }

    /// Kitaplık ve okuma serisinden bu çocuğun okumaları.
    @MainActor
    static func reading(stories: [Story], profile: UserProfile?, daysInARow: Int) -> MPMilestone.Reading {
        let finished = stories.filter { $0.isFinished && $0.belongs(to: profile) }
        return MPMilestone.Reading(
            finishedStories: finished.count,
            finishedBedtime: finished.filter { $0.mpMode == .bedtime }.count,
            finishedAdventure: finished.filter { $0.mpMode == .adventure }.count,
            daysInARow: daysInARow)
    }
}
