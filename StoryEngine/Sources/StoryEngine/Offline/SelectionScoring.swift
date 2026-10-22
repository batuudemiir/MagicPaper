import Foundation
import EngineFoundation

/// How interests and recent history weigh a choice (FAZ 12).
///
/// Weight, never filter. A record the child's interests match is more likely
/// to be picked; a record the child just had is less likely. Neither removes
/// anything from the pool, so the engine's coherence rules — what a blueprint
/// requires, what lives where — are exactly what they were, and an interest
/// the catalog cannot serve changes nothing.
///
/// Interests alone would collapse every story onto one topic: the best match
/// would win every time. Cooldown is what stops that, and it applies to every
/// child, with or without interests (karar, 4 Ekim 2026): the same forest three
/// nights running is a defect whatever the child likes.
///
/// With no interests and no history every weight is equal, and ordering falls
/// back to the seeded rotation the engine used before FAZ 12 — so every intent
/// built without them produces the same book, byte for byte.
public enum SelectionScoring {
    /// A match multiplies weight by `1 + interestBoost`.
    public static let interestBoost = 2.0
    /// How many recent stories cool content down.
    public static let cooldownWindow = 4
    /// What the most recent story's content keeps of its weight. Older stories
    /// cool less, linearly, until the window ends.
    public static let cooldownFloor = 0.1

    /// The weight of one record for this intent.
    ///
    /// `recent` is this axis's ids, newest first, one per earlier story (nil
    /// where that story had none). `cooldown` is the record's own authored
    /// `SelectionWeights.cooldown`: 1 is the default, 0 never cools.
    /// `usage` is what the child's own reading taught (FAZ 14,
    /// `UsageProfile`) times any aggregate weight the catalog carries; exactly
    /// 1 when there is nothing to learn from, which keeps the seeded rotation.
    public static func weight(
        id: ContentID,
        matchesInterest: Bool,
        cooldown: Double = 1.0,
        recent: [ContentID?],
        usage: Double = 1.0
    ) -> Double {
        var weight = usage
        if matchesInterest { weight *= 1 + interestBoost }
        weight *= cooled(storiesAgo: recent.prefix(cooldownWindow).firstIndex(of: id),
                         cooldown: cooldown)
        return weight
    }

    /// Soğuma eğrisi: kaç masal önce kullanıldığına göre ağırlığın ne kadarı
    /// kalır. `nil` pencerede hiç geçmedi demek, ve hiçbir şey kaybetmez.
    ///
    /// Tek yerde durması şart, çünkü iki ekseni besliyor: içerik kayıtları
    /// (eksen başına tek kimlik) ve proza satırları (masal başına onlarca).
    /// Eğriyi iki kez yazmak, birini ayarlayıp öbürünü unutmanın en kolay yolu.
    static func cooled(storiesAgo index: Int?, cooldown: Double) -> Double {
        guard let index else { return 1 }
        let full = (1 - cooldownFloor) * Double(cooldownWindow - index) / Double(cooldownWindow)
        // Never to zero: cooled is less likely, not impossible, so a pool of
        // one stays a pool of one rather than an error.
        return 1 - min(full * max(0, cooldown), 0.95)
    }

    /// Bir proza satırının ağırlığı: çocuğun son masallarında geçtiyse soğur
    /// (D2, 22 Ekim 2026).
    ///
    /// Buraya kadar soğuma yalnızca mekân, arkadaş ve nesne eksenlerinde
    /// çalışıyordu; cümlenin kendisinde hiçbir hafıza yoktu. Ölçüm bunun
    /// bedelini gösterdi: aynı çocuğun elli masalında tekrar eden cümle oranı
    /// öğrenelim 5-6'da %52, macerada %57, uyku öncesinde %85. Havuz A turunda
    /// iki katına çıktığında bu oran neredeyse hiç kıpırdamadı, çünkü mekân
    /// değişse de sayfanın cümlesi aynı yerden seçiliyordu.
    ///
    /// `recent` masal başına bir küme, en yenisi önce: içerik eksenlerinin
    /// aksine bir masalın onlarca satırı var, bu yüzden geçmiş kimlik değil
    /// küme listesi. Eğri aynı (`cooled`), yani "üç masal önce geçti" iki
    /// eksende aynı şeyi ifade ediyor.
    ///
    /// Süzgeç değil ağırlık: üç varyantlı bir beat'te satırı elemek masalı
    /// kurulamaz hâle getirirdi. Soğuyan satır daha az olası, imkânsız değil.
    public static func variantWeight(id: ContentID, recent: [Set<ContentID>]) -> Double {
        let index = recent.prefix(cooldownWindow).firstIndex { $0.contains(id) }
        return cooled(storiesAgo: index, cooldown: 1)
    }

    /// `items` best first, deterministically.
    ///
    /// Equal weights keep the pre-FAZ 12 order: a rotation starting at the
    /// seeded index. Unequal weights use a seeded weighted shuffle
    /// (Efraimidis–Spirakis: each item draws `u` from the seed and its own id,
    /// and items sort by `u^(1/w)`), so a heavier item is more likely to come
    /// first but never certain to. Keyed on ids, not positions, so the order
    /// cannot depend on how the catalog happens to be laid out beyond the
    /// rotation that already did.
    public static func ordered<T>(
        _ items: [T],
        weights: [Double],
        id: (T) -> ContentID,
        seed: String,
        salt: String
    ) -> [T] {
        precondition(items.count == weights.count)
        guard items.count > 1 else { return items }

        if Set(weights).count == 1 {
            let start = DeterministicPicker.index(count: items.count, seed: seed, salt: salt)
            return Array(items[start...] + items[..<start])
        }

        let keyed = zip(items, weights).map { item, weight -> (T, Double, String) in
            let raw = id(item).rawValue
            let hash = mixed(StableHash.hash([seed, salt, "weighted", raw]))
            // (0, 1], never 0: log(0) would make every draw equal.
            let u = (Double(hash >> 11) + 1) / Double(UInt64(1) << 53)
            return (item, log(u) / max(weight, .leastNonzeroMagnitude), raw)
        }
        return keyed
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.2 < $1.2 }
            .map(\.0)
    }

    /// SplitMix64's finaliser. FNV-1a, which `StableHash` is, barely moves the
    /// high bits when two ids differ only in their last byte, and the draw is
    /// read from the high bits: unmixed, "a" led a four-item list 199 times in
    /// 200 at a weight that should give it half.
    static func mixed(_ value: UInt64) -> UInt64 {
        var z = value &+ 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// A record selection can weigh: interest words plus its authored weights.
protocol WeighedContent: InterestTagged {
    var weights: SelectionWeights { get }
}

extension CatalogSetting: WeighedContent {}
extension CatalogCompanion: WeighedContent {}
extension CatalogObject: WeighedContent {}
