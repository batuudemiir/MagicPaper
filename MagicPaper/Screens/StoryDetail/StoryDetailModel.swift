import SwiftUI

/// Masal detayının ve ana sayfa rafının okuduğu türetilmiş alanlar.
///
/// Görünümün içinde hesaplanmaz: aynı süre ve aynı alıntı rafta, detayda ve
/// ileride sesli okumada aynı olmalı, ve hepsi test edilebilmeli.
extension Story {

    /// Masalın yazıldığı niyet. Mod öncesi masallarda `nil`.
    var mpMode: StoryMode? {
        origin?.modeID.flatMap(StoryMode.init(rawValue:))
    }

    /// Sesli okuma süresi, dakika.
    ///
    /// Çocuğa sesli okunan bir masal dakikada yaklaşık 90 kelime ilerler —
    /// yetişkinin sessiz okumasının yarısından az, çünkü duraklar, sesler ve
    /// "bu ne?" soruları okumanın parçası. En az bir dakika.
    var mpReadingMinutes: Int {
        let words = pages.reduce(0) { total, page in
            total + page.text.split(whereSeparator: \.isWhitespace).count
        }
        return max(1, Int((Double(words) / Self.readAloudWordsPerMinute).rounded()))
    }

    static let readAloudWordsPerMinute: Double = 90

    /// Detay ekranında masalın ilk cümleleri — kapağı açmadan bir tadım.
    ///
    /// Cümle sınırında kesilir, kelimenin ortasında değil. Diyalog satırları
    /// (tırnakla başlayan) alıntıya girmez: bağlamı olmadan okunan bir
    /// "Bu da ne?" masalın başı gibi değil, bir hata gibi durur.
    var mpExcerpt: String? {
        guard let first = pages.first?.text else { return nil }
        let paragraphs = first
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !Self.opensWithQuote($0) }
        guard let lead = paragraphs.first else { return nil }

        var excerpt = ""
        lead.enumerateSubstrings(in: lead.startIndex..., options: .bySentences) { sentence, _, _, stop in
            guard let sentence else { return }
            if !excerpt.isEmpty && excerpt.count + sentence.count > Self.excerptLimit {
                stop = true
                return
            }
            excerpt += sentence
        }
        let trimmed = excerpt.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static let excerptLimit = 180

    private static func opensWithQuote(_ s: String) -> Bool {
        guard let c = s.first else { return false }
        return "\"“”«‘'—–-".contains(c)
    }

    /// Detayın sahnesi: setin teslim edilmiş hero'su varsa o.
    /// Yoksa `nil` — detay masalın kendi mozaik kapağını büyütür.
    func mpHeroArt(assetExists: (String) -> Bool = StoryArtKit.bundleHasAsset) -> MPArt? {
        guard let kit = mpArtKit,
              case .image(let name) = kit.art(for: .hero, assetExists: assetExists) else { return nil }
        return .image(name)
    }

    /// Raf kartının kapak görseli: setin teslim edilmiş kapağı varsa o.
    var mpKitCoverAsset: String? {
        guard let kit = mpArtKit,
              case .image(let name) = kit.art(for: .cover) else { return nil }
        return name
    }
}

/// Ana sayfa rafının mod süzgeci.
enum MPShelfFilter: Hashable {
    case all
    case mode(StoryMode)

    var title: String {
        switch self {
        case .all:            return "Hepsi"
        case .mode(let mode): return mode.title
        }
    }

    var symbol: String? {
        switch self {
        case .all:            return nil
        case .mode(let mode): return mode.symbol
        }
    }

    func admits(_ story: Story) -> Bool {
        switch self {
        case .all:            return true
        case .mode(let mode): return story.mpMode == mode
        }
    }

    /// Rafta gösterilecek süzgeçler.
    ///
    /// Yalnızca rafta gerçekten bulunan modlar, sabit sırayla. Tek bir mod
    /// varsa hiç süzgeç yok: "Hepsi" ile o mod aynı listeyi verir ve iki
    /// düğmenin aynı şeyi yapması bir seçim değildir.
    static func available(in stories: [Story]) -> [MPShelfFilter] {
        let present = Set(stories.compactMap(\.mpMode))
        let modes = StoryMode.allCases.filter(present.contains)
        guard modes.count > 1 else { return [] }
        return [.all] + modes.map(MPShelfFilter.mode)
    }
}
