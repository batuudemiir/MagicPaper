import Foundation
import StoryEngine

/// Bir masal sonunun rozet defterine yazılan bilgisi. Okuyucu masal sonuna
/// varınca `MPBadgeStore.facts(for:)` kurar; alanların çoğu R2'de dolar.
struct MPFinishFacts: Equatable {
    var storyID: String
    var mode: StoryMode?
    /// Serinin 5. bölümü bittiyse serinin kimliği.
    var seriesCompletedID: String? = nil
    /// Serinin 2. bölümü bittiyse serinin kimliği ("İlk devam").
    var seriesSecondID: String? = nil
    var classicID: String? = nil
    var originalID: String? = nil
    var isSurprise = false
    var placeID: String? = nil
    var companionIDs: [String] = []
    var familyMemberIDs: [String] = []
    /// Masal ailenin kaydettiği sesle dinlendi.
    var heardFamilyVoice = false
    var newWords: [String] = []
}

/// Bir çocuğun rozet defteri. Yalnızca büyür; bu yüzden iki cihazın defteri
/// birleşince hiçbir rozet ve hiçbir yıldız kaybolmaz (`merged`).
///
/// Kodlama elle yazılır: yeni alanlar eski defterde yoktur ve sentezlenmiş
/// `Decodable` eksik anahtarda hata verir; o zaman eski defter okunamaz ve
/// rozet tarihleri kaybolurdu (rozet planı, 5. bölüm).
struct MPBadgeLedger: Equatable {
    // FAZ 17
    var finished: Set<String> = []
    var finishedBedtime: Set<String> = []
    var finishedAdventure: Set<String> = []
    var finishedLearning: Set<String> = []
    var completedSeries: Set<String> = []
    /// Rozet → ilk kazanıldığı an.
    var earned: [String: Date] = [:]

    // Rozet planı (15 Kasım 2026)
    /// Masal bitirilen yerel günler (`MPBadgeDay.key`).
    var readingDays: Set<String> = []
    /// Masal → sonuna kadar okunduğu günler ("Tekrar tekrar").
    var finishDays: [String: Set<String>] = [:]
    /// Sabah (05.00-12.00) bitirilen masallar. Gece yarısından sonrası sabah
    /// sayılmaz: geç saatte okumak ödüllendirilmez (rozet planı 3).
    var morningStories: Set<String> = []
    var firstFinishedAt: Date?
    var seriesSecond: Set<String> = []
    var classics: Set<String> = []
    var originals: Set<String> = []
    var surpriseStories: Set<String> = []
    var places: Set<String> = []
    var companions: Set<String> = []
    var familyMembers: Set<String> = []
    var voiceStories: Set<String> = []
    var words: Set<String> = []
    var wordCardOpened = false
    /// Yıldız katı → ilk ulaşıldığı an.
    var starLevels: [String: Date] = [:]
    /// Kutlanmış ya da sessizce verilmiş rozet ve katlar: bir daha kutlanmaz.
    var seen: Set<String> = []
    /// Sabah yıldızının "okuma sabahı" kuralına geçtiği an (plan 5b, karar 11).
    /// Bu güne kadarki sabahlar okunmasa da sayılır; puan düşmez.
    var morningRuleSince: Date?
    /// Defterin hesaplandığı katalog sürümü (`MPBadgeCatalog.version`).
    var catalogVersion = 0

    init() {}

    var earnedBadges: [MPBadge] { MPBadgeCatalog.all.filter { earned[$0.id] != nil } }
    var earnedIDs: Set<String> { Set(earned.keys) }

    // MARK: - Yazma

    /// Bir masal sonuna kadar okundu. Aynı masal ikinci kez sayılmaz; aynı
    /// günde ikinci kez bitmesi de "Tekrar tekrar"a sayılmaz. Yeni kazanılan
    /// rozetleri döndürür.
    @discardableResult
    mutating func recordFinished(_ facts: MPFinishFacts, at now: Date = Date(),
                                 calendar: Calendar = .current) -> [MPBadge] {
        let id = facts.storyID
        let day = MPBadgeDay.key(for: now, calendar: calendar)
        finished.insert(id)
        switch facts.mode {
        case .bedtime:   finishedBedtime.insert(id)
        case .adventure: finishedAdventure.insert(id)
        case .learning:  finishedLearning.insert(id)
        case nil:        break
        }
        readingDays.insert(day)
        finishDays[id, default: []].insert(day)
        if (5..<12).contains(calendar.component(.hour, from: now)) { morningStories.insert(id) }
        firstFinishedAt = min(firstFinishedAt ?? now, now)
        if let s = facts.seriesCompletedID { completedSeries.insert(s) }
        if let s = facts.seriesSecondID { seriesSecond.insert(s) }
        if let c = facts.classicID { classics.insert(c) }
        if let o = facts.originalID { originals.insert(o) }
        if facts.isSurprise { surpriseStories.insert(id) }
        if let p = facts.placeID { places.insert(p) }
        companions.formUnion(facts.companionIDs)
        familyMembers.formUnion(facts.familyMemberIDs)
        if facts.heardFamilyVoice { voiceStories.insert(id) }
        words.formUnion(facts.newWords)
        return award(at: now, calendar: calendar)
    }

    /// FAZ 17'nin çağrısı: yalnızca masal kimliği, mod ve tamamlanan seri.
    @discardableResult
    mutating func recordFinished(storyID: String, mode: StoryMode?, seriesCompletedID: String? = nil,
                                 at now: Date = Date(), calendar: Calendar = .current) -> [MPBadge] {
        recordFinished(MPFinishFacts(storyID: storyID, mode: mode, seriesCompletedID: seriesCompletedID),
                       at: now, calendar: calendar)
    }

    /// Masal okunurken bir kelime kartı açıldı ("Meraklı parmak").
    @discardableResult
    mutating func recordWordCardOpened(at now: Date = Date()) -> [MPBadge] {
        wordCardOpened = true
        return award(at: now)
    }

    /// Eşiği geçmiş ama henüz kazanılmamış rozetleri verir.
    mutating func award(at now: Date = Date(), calendar: Calendar = .current) -> [MPBadge] {
        let fresh = MPBadgeCatalog.all.filter {
            earned[$0.id] == nil && value(of: $0.metric, calendar: calendar) >= $0.threshold
        }
        for badge in fresh { earned[badge.id] = now }
        return fresh
    }

    /// Puanın ulaştığı ama henüz işlenmemiş Yıldız katlarını verir.
    @discardableResult
    mutating func awardStarLevels(score: Int, at now: Date = Date()) -> [MPStarLevel] {
        let fresh = MPStarLevel.all.filter { starLevels[$0.id] == nil && score >= $0.threshold }
        for level in fresh { starLevels[level.id] = now }
        return fresh
    }

    // MARK: - Ölçüler

    func value(of metric: MPBadgeMetric, calendar: Calendar = .current) -> Int {
        switch metric {
        case .finished:        return finished.count
        case .bedtime:         return finishedBedtime.count
        case .adventure:       return finishedAdventure.count
        case .learning:        return finishedLearning.count
        case .allModes:        return [finishedBedtime, finishedAdventure, finishedLearning].filter { !$0.isEmpty }.count
        case .readingDays:     return readingDays.count
        case .words:           return words.count
        case .wordCard:        return wordCardOpened ? 1 : 0
        case .seriesSecond:    return seriesSecond.count
        case .seriesCompleted: return completedSeries.count
        case .classics:        return classics.count
        case .originals:       return originals.count
        case .surprise:        return surpriseStories.count
        case .places:          return places.count
        case .companions:      return companions.count
        case .familyMembers:   return familyMembers.count
        case .voiceStories:    return voiceStories.count
        case .rereadDays:      return finishDays.values.map(\.count).max() ?? 0
        case .morning:         return morningStories.count
        case .fullWeekend:     return MPBadgeDay.hasFullWeekend(readingDays, calendar: calendar) ? 1 : 0
        case .anniversary:     return hasAnniversary(calendar: calendar) ? 1 : 0
        }
    }

    /// İlk masaldan en az bir yıl sonra bir masal okundu.
    private func hasAnniversary(calendar: Calendar) -> Bool {
        guard let first = firstFinishedAt,
              let target = calendar.date(byAdding: .year, value: 1, to: calendar.startOfDay(for: first)) else { return false }
        let key = MPBadgeDay.key(for: target, calendar: calendar)
        return readingDays.contains { $0 >= key }
    }

    // MARK: - Birleşme

    /// İki defterin birleşimi: her küme birleşir, her rozetin ve katın en erken
    /// tarihi kalır. Sabah kuralının geçiş anı en geç olanıdır: böylece
    /// birleşme hiçbir cihazda puanı düşürmez.
    func merged(with other: MPBadgeLedger) -> MPBadgeLedger {
        var out = self
        out.finished.formUnion(other.finished)
        out.finishedBedtime.formUnion(other.finishedBedtime)
        out.finishedAdventure.formUnion(other.finishedAdventure)
        out.finishedLearning.formUnion(other.finishedLearning)
        out.completedSeries.formUnion(other.completedSeries)
        out.earned.merge(other.earned) { min($0, $1) }
        out.readingDays.formUnion(other.readingDays)
        out.finishDays.merge(other.finishDays) { $0.union($1) }
        out.morningStories.formUnion(other.morningStories)
        out.firstFinishedAt = [firstFinishedAt, other.firstFinishedAt].compactMap { $0 }.min()
        out.seriesSecond.formUnion(other.seriesSecond)
        out.classics.formUnion(other.classics)
        out.originals.formUnion(other.originals)
        out.surpriseStories.formUnion(other.surpriseStories)
        out.places.formUnion(other.places)
        out.companions.formUnion(other.companions)
        out.familyMembers.formUnion(other.familyMembers)
        out.voiceStories.formUnion(other.voiceStories)
        out.words.formUnion(other.words)
        out.wordCardOpened = wordCardOpened || other.wordCardOpened
        out.starLevels.merge(other.starLevels) { min($0, $1) }
        out.seen.formUnion(other.seen)
        out.morningRuleSince = [morningRuleSince, other.morningRuleSince].compactMap { $0 }.max()
        out.catalogVersion = max(catalogVersion, other.catalogVersion)
        return out
    }
}

extension MPBadgeLedger: Codable {
    private enum CodingKeys: String, CodingKey {
        case finished, finishedBedtime, finishedAdventure, finishedLearning, completedSeries, earned
        case readingDays, finishDays, morningStories, firstFinishedAt, seriesSecond, classics, originals
        case surpriseStories, places, companions, familyMembers, voiceStories, words, wordCardOpened
        case starLevels, seen, morningRuleSince, catalogVersion
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func set(_ key: CodingKeys) throws -> Set<String> { try c.decodeIfPresent(Set<String>.self, forKey: key) ?? [] }
        finished = try set(.finished)
        finishedBedtime = try set(.finishedBedtime)
        finishedAdventure = try set(.finishedAdventure)
        finishedLearning = try set(.finishedLearning)
        completedSeries = try set(.completedSeries)
        earned = try c.decodeIfPresent([String: Date].self, forKey: .earned) ?? [:]
        readingDays = try set(.readingDays)
        finishDays = try c.decodeIfPresent([String: Set<String>].self, forKey: .finishDays) ?? [:]
        morningStories = try set(.morningStories)
        firstFinishedAt = try c.decodeIfPresent(Date.self, forKey: .firstFinishedAt)
        seriesSecond = try set(.seriesSecond)
        classics = try set(.classics)
        originals = try set(.originals)
        surpriseStories = try set(.surpriseStories)
        places = try set(.places)
        companions = try set(.companions)
        familyMembers = try set(.familyMembers)
        voiceStories = try set(.voiceStories)
        words = try set(.words)
        wordCardOpened = try c.decodeIfPresent(Bool.self, forKey: .wordCardOpened) ?? false
        starLevels = try c.decodeIfPresent([String: Date].self, forKey: .starLevels) ?? [:]
        seen = try set(.seen)
        morningRuleSince = try c.decodeIfPresent(Date.self, forKey: .morningRuleSince)
        catalogVersion = try c.decodeIfPresent(Int.self, forKey: .catalogVersion) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(finished, forKey: .finished)
        try c.encode(finishedBedtime, forKey: .finishedBedtime)
        try c.encode(finishedAdventure, forKey: .finishedAdventure)
        try c.encode(finishedLearning, forKey: .finishedLearning)
        try c.encode(completedSeries, forKey: .completedSeries)
        try c.encode(earned, forKey: .earned)
        try c.encode(readingDays, forKey: .readingDays)
        try c.encode(finishDays, forKey: .finishDays)
        try c.encode(morningStories, forKey: .morningStories)
        try c.encodeIfPresent(firstFinishedAt, forKey: .firstFinishedAt)
        try c.encode(seriesSecond, forKey: .seriesSecond)
        try c.encode(classics, forKey: .classics)
        try c.encode(originals, forKey: .originals)
        try c.encode(surpriseStories, forKey: .surpriseStories)
        try c.encode(places, forKey: .places)
        try c.encode(companions, forKey: .companions)
        try c.encode(familyMembers, forKey: .familyMembers)
        try c.encode(voiceStories, forKey: .voiceStories)
        try c.encode(words, forKey: .words)
        try c.encode(wordCardOpened, forKey: .wordCardOpened)
        try c.encode(starLevels, forKey: .starLevels)
        try c.encode(seen, forKey: .seen)
        try c.encodeIfPresent(morningRuleSince, forKey: .morningRuleSince)
        try c.encode(catalogVersion, forKey: .catalogVersion)
    }
}

/// Yerel takvim günü anahtarı: "2026-11-15". Sözlük sırası tarih sırasıdır.
enum MPBadgeDay {
    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func date(for key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    /// Aynı hafta sonu cumartesi ve pazar ikisinde de masal bitti.
    static func hasFullWeekend(_ days: Set<String>, calendar: Calendar = .current) -> Bool {
        days.contains { key in
            guard let date = date(for: key, calendar: calendar),
                  calendar.component(.weekday, from: date) == 7,   // cumartesi
                  let sunday = calendar.date(byAdding: .day, value: 1, to: date) else { return false }
            return days.contains(Self.key(for: sunday, calendar: calendar))
        }
    }
}
