import Foundation
import EngineFoundation

/// Identifier of a content record, e.g. `setting_forest_001`.
///
/// A distinct type rather than `String` because the whole compatibility system is
/// references between records; a bare string invites passing a tag where an id
/// belongs, which is precisely how the current catalog ended up with companions
/// pointing at settings that do not exist.
public struct ContentID: Hashable, Codable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }
    public var description: String { rawValue }

    public init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// A tag used for compatibility matching, e.g. `forest`, `night`, `water`.
///
/// Deliberately *not* a `ContentID`. Tags describe a record; ids name one. The
/// catalog links companions to settings by tag, and conflating the two is what
/// makes `compatibleSettings: ["ocean"]` look valid when no setting is tagged
/// `ocean`.
public struct ContentTag: Hashable, Codable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(_ rawValue: String) { self.rawValue = rawValue.lowercased() }
    public init(stringLiteral value: String) { self.init(value) }
    public var description: String { rawValue }

    public init(from decoder: Decoder) throws {
        self.init(try decoder.singleValueContainer().decode(String.self))
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// An inclusive age band, written `"5-6"` in the catalog.
public struct AgeBand: Hashable, Codable, Sendable, CustomStringConvertible {
    public let lowerBound: Int
    public let upperBound: Int

    public init(lowerBound: Int, upperBound: Int) {
        self.lowerBound = min(lowerBound, upperBound)
        self.upperBound = max(lowerBound, upperBound)
    }

    public init?(_ text: String) {
        let parts = text.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2, let low = Int(parts[0]), let high = Int(parts[1]) else { return nil }
        self.init(lowerBound: low, upperBound: high)
    }

    public var description: String { "\(lowerBound)-\(upperBound)" }
    public func contains(_ age: Int) -> Bool { (lowerBound...upperBound).contains(age) }

    // MARK: - Okuma parametreleri
    //
    // Bu değerler `docs/AGE_BANDING.md`'den geliyor ve orada kaynaklarıyla
    // birlikte duruyor. Buraya kadar taşınmalarının sebebi şu: `AgeBand` bugüne
    // kadar yalnızca "5-6" metnini taşıyordu, yani bir bandın NE DEMEK olduğunu
    // hiçbir yer bilmiyordu. Bir sonraki bant yazıldığında kelime bütçesinin,
    // cümle sınırının ve sayfa sayısının nereden geleceği belirsizdi — ve
    // belirsiz olduğu için de muhtemelen 5-6'nınkiler kopyalanacaktı.

    /// Bir sayfanın kelime bandı.
    ///
    /// Resimli kitap (3-7) üst sınırı sektörde ~600 kelime. Sekiz sayfalık bir
    /// masalda bu sayfa başına ~75; bugünkü 18-38 bandı bunun altında ve
    /// bilerek öyle: metin SESLİ okunuyor, ve sesli okumada sayfada geçen süre
    /// sayfadaki kelime kadar önemli.
    public var pageBudget: (lower: Int, upper: Int) {
        switch lowerBound {
        case ..<5:  return (10, 24)   // 3-4: kısa, tek olaylı sayfalar
        case 5...7: return (18, 38)   // bugünkü korpusun yazıldığı bant
        case 8...10: return (30, 60)
        default:    return (45, 90)
        }
    }

    /// Bir cümlenin en fazla kaç kelime olabileceği.
    ///
    /// **MLU tavan değil tabandır.** Gelişim literatürünün en çok alıntılanan
    /// ölçüsü olan ortalama sözce uzunluğu 5-6 yaş için ~5 kelime, ama o,
    /// çocuğun ÜRETTİĞİdir. Anlama üretmeyi belirgin biçimde önden götürür:
    /// masalı dinleyen çocuk, kendi kuramayacağı cümleleri rahatça takip eder.
    /// MLU'yu tavan sanıp cümleleri beşe indirmek metni uygun değil TATSIZ
    /// yapar — bu literatürdeki en kolay hata ve buraya bu yüzden yazıldı.
    public var maxSentenceWords: Int {
        switch lowerBound {
        case ..<5:  return 10
        case 5...7: return 14
        case 8...10: return 20
        default:    return 26
        }
    }

    /// Kaç sayfa.
    public var pageCount: Int {
        switch lowerBound {
        case ..<5:  return 6
        case 5...7: return 8
        case 8...10: return 10
        default:    return 12
        }
    }

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let parsed = AgeBand(raw) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "'\(raw)' is not an age band like \"5-6\"")
            )
        }
        self = parsed
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

/// What a page is *for*. Closed, because every page must have a narrative
/// purpose — eight pages that are variations of one paragraph is the failure
/// this prevents.
///
/// The first eight are the MVP arc and the only ones blueprints currently use.
/// `celebration` and `bedtimeTransition` exist because the shipped catalog has
/// templates for them; the integrity check reports them as unreachable rather
/// than silently dropping real authored content.
public enum PageRole: String, Codable, Sendable, Hashable, CaseIterable {
    case hook
    case discovery
    case companion
    case problem
    case attempt
    case challenge
    case resolution
    case emotionalEnding = "emotional_ending"
    case celebration
    case bedtimeTransition = "bedtime_transition"

    /// The eight-beat arc a V2 MVP blueprint is expected to declare.
    public static let mvpArc: [PageRole] = [
        .hook, .discovery, .companion, .problem, .attempt, .challenge, .resolution, .emotionalEnding
    ]
}

/// How strongly a record resists being reused soon, and how much it is worth
/// preferring when it has not been seen lately. Consumed by novelty scoring in a
/// later step; carried here so the catalog is the single place weights live.
public struct SelectionWeights: Codable, Sendable, Hashable {
    public let cooldown: Double
    public let novelty: Double

    public init(cooldown: Double = 1.0, novelty: Double = 1.0) {
        self.cooldown = cooldown
        self.novelty = novelty
    }

    public static let neutral = SelectionWeights()

    private enum CodingKeys: String, CodingKey { case cooldownWeight, noveltyWeight }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cooldown = try container.decodeIfPresent(Double.self, forKey: .cooldownWeight) ?? 1.0
        novelty = try container.decodeIfPresent(Double.self, forKey: .noveltyWeight) ?? 1.0
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cooldown, forKey: .cooldownWeight)
        try container.encode(novelty, forKey: .noveltyWeight)
    }
}
