import Foundation
import SwiftUI

// MARK: - Günlük: ücretsiz masallar (FAZ 20)
//
// Kamu malı klasikler, Anadolu masalları ve MagicPaper'ın kendi masalları.
// Motorun yazdığı masallardan ayrı bir defter: kimse için kişiselleştirilmez,
// çocuğun Kitaplık'ına kaydedilmez, her çocuk için aynı metni okur.
// Kaynak tek dosya: `classics_catalog.json` (pakette).

/// Masalın nereden geldiği. Kapak ve detayın alt satırındaki kaynak bilgisi
/// bundan değil, masalın kendi `attribution` ve `coverCredit` alanlarından
/// okunur; bu yalnızca süzme ve "Benzerleri" için.
enum ClassicOrigin: String, Codable, CaseIterable {
    case grimm, perrault, andersen, aesop, anadolu, dogu, modern, orijinal
}

/// Günlük'ün rafları ve Kategoriler listesi, tasarımdaki sırayla.
enum ClassicShelf: String, Codable, CaseIterable, Identifiable {
    case klasikler, anadolu, fabllar, seriler, uyku, besDakika, hayvanlar, sesli

    var id: String { rawValue }

    /// Kategoriler listesindeki ve raf ekranının başlığı.
    var title: String {
        switch self {
        case .klasikler: return "Dünya klasikleri"
        case .anadolu:   return "Anadolu'dan"
        case .fabllar:   return "Fabllar"
        case .seriler:   return "Seriler"
        case .uyku:      return "Uyku vakti"
        case .besDakika: return "5 dakikalık"
        case .hayvanlar: return "Hayvanlar"
        case .sesli:     return "Sesli"
        }
    }

    /// Günlük'teki kısa çip adı.
    var chipTitle: String {
        switch self {
        case .klasikler: return "Klasikler"
        case .anadolu:   return "Anadolu"
        case .uyku:      return "Uyku"
        default:         return title
        }
    }

    /// Raf ekranındaki alt başlık.
    var subtitle: String {
        switch self {
        case .klasikler: return "Yüz yıldır okunan masallar"
        case .anadolu:   return "Ninelerimizin anlattığı masallar"
        case .fabllar:   return "Hayvanların dilinden kısa dersler"
        case .seriler:   return "Bölüm bölüm okunan masallar"
        case .uyku:      return "Kısa, sakin, ışıklar kısılırken"
        case .besDakika: return "Beş dakikada biten masallar"
        case .hayvanlar: return "Konuşan tavşanlar, akıllı tilkiler"
        case .sesli:     return "Sesli okunan masallar"
        }
    }

    /// Bu raflar kataloğa yazılmaz; masalın başka alanlarından çıkarılır.
    /// "Seriler" seri olmaktan, "5 dakikalık" süreden. "Sesli" için henüz
    /// seslendirilmiş masal yok, bu yüzden hep boş ve gizli.
    var isDerived: Bool { self == .seriler || self == .besDakika || self == .sesli }
}

/// Kapağın odak noktası, CSS `object-position` gibi: 0…1.
struct ClassicFocus: Codable, Equatable {
    var x: Double
    var y: Double

    static let center = ClassicFocus(x: 0.5, y: 0.5)
    var unitPoint: UnitPoint { UnitPoint(x: x, y: y) }
}

/// Anlatım: Yumuşak her masalda var, Klasik yalnızca korkutucu sahnesi
/// olan masallarda (tasarım: "ANLATIM" segmenti).
enum ClassicNarration: String, Codable, CaseIterable {
    case soft, classic

    var title: String { self == .soft ? "Yumuşak" : "Klasik" }
}

/// Bir anlatımın sayfaları. Her öğe bir sayfa; paragraflar boş satırla ayrılır.
struct ClassicText: Codable, Equatable {
    var pages: [String]
}

struct ClassicTale: Codable, Identifiable, Equatable {
    let id: UUID
    /// Dosya ve asset adlarında kullanılan kısa ad (`rapunzel`).
    let slug: String
    let title: String
    let origin: ClassicOrigin
    /// Meta satırının ilk parçası: "Grimm", "Anadolu", "Fıkra", "M. Williams".
    let byline: String
    let ageMin: Int
    let ageMax: Int
    /// Yumuşak anlatımın okuma süresi, dakika.
    let minutes: Int
    let summary: String
    /// Yazılan raflar (türetilen raflar burada olmaz).
    let shelves: [ClassicShelf]
    /// Asset catalog'daki kapak adı.
    let cover: String
    let coverFocus: ClassicFocus
    /// Metnin kaynağı: "Grimm Kardeşler, 1812."
    let attribution: String
    /// Görselin kaynağı: "Görsel: Johnny Gruelle, 1914. Kamu malı."
    let coverCredit: String
    let soft: ClassicText
    let classic: ClassicText?
    /// Seri bölümüyse serisi ve sırası (1'den başlar).
    let seriesID: UUID?
    let episode: Int?

    var isEpisode: Bool { seriesID != nil }

    func text(_ narration: ClassicNarration) -> ClassicText {
        narration == .classic ? (classic ?? soft) : soft
    }

    /// "5-7 yaş" — tasarımdaki biçim.
    var ageLabel: String { "\(ageMin)-\(ageMax) yaş" }

    /// "Grimm · 9 dk"
    var shortMeta: String { "\(byline) · \(minutes) dk" }

    /// "Grimm · 9 dk · 5-7 yaş"
    var fullMeta: String { "\(shortMeta) · \(ageLabel)" }

    func fits(age: Int) -> Bool { (ageMin...ageMax).contains(age) }

    /// Detay ekranının en altındaki satır.
    var creditLine: String { "\(attribution) \(coverCredit) MagicPaper uyarlaması." }
}

struct ClassicSeries: Codable, Identifiable, Equatable {
    let id: UUID
    let slug: String
    let title: String
    let byline: String
    let ageMin: Int
    let ageMax: Int
    let summary: String
    let shelves: [ClassicShelf]
    let cover: String
    let coverFocus: ClassicFocus
    let attribution: String
    let coverCredit: String
    /// Listenin başlığı: "1. Kitap".
    let bookTitle: String
    /// Rafta "6 masal", "12 fıkra", "4 bölüm" gibi.
    let unitName: String

    var ageLabel: String { "\(ageMin)-\(ageMax) yaş" }
    func fits(age: Int) -> Bool { (ageMin...ageMax).contains(age) }
    var creditLine: String { "\(attribution) \(coverCredit)" }
}

/// Haftanın seçkisi: editörün sırası, okuma sayısı değil.
struct ClassicWeeklyPicks: Codable, Equatable {
    /// `yyyy-MM-dd`, haftanın ilk günü.
    let weekOf: String
    /// Masal ya da seri id'leri, sırayla.
    let ids: [UUID]
}

/// Mevcut günlük akış masallarının (FAZ 15) Günlük'teki kapağı.
/// Metin akıştan gelir; burada yalnızca kapak ve raf.
struct ClassicOriginalCover: Codable, Equatable {
    let feedID: UUID
    let cover: String
    let coverFocus: ClassicFocus
    let coverCredit: String
    let shelves: [ClassicShelf]
}

/// `classics_catalog.json`
struct ClassicsCatalogFile: Codable, Equatable {
    let version: Int
    let tales: [ClassicTale]
    let series: [ClassicSeries]
    let weeklyPicks: ClassicWeeklyPicks
    let originals: [ClassicOriginalCover]
    /// Henüz çizimi olmayan kapak adları: ekranda düz renkli yedek kapak.
    /// Asset eklenince buradan çıkarılır (`Content/Classics/COVER_SOURCES.md`).
    var pendingCovers: [String] = []
    /// Editörün öne çıkardığı masal: varsa Günün masalı odur (İrem'in
    /// tasarımında Rapunzel). Yoksa günlük sıra işler.
    var featuredID: UUID? = nil

    enum CodingKeys: String, CodingKey { case version, tales, series, weeklyPicks, originals, pendingCovers, featuredID }

    init(version: Int, tales: [ClassicTale], series: [ClassicSeries], weeklyPicks: ClassicWeeklyPicks,
         originals: [ClassicOriginalCover], pendingCovers: [String] = [], featuredID: UUID? = nil) {
        self.version = version
        self.tales = tales
        self.series = series
        self.weeklyPicks = weeklyPicks
        self.originals = originals
        self.pendingCovers = pendingCovers
        self.featuredID = featuredID
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decode(Int.self, forKey: .version)
        tales = try c.decode([ClassicTale].self, forKey: .tales)
        series = try c.decode([ClassicSeries].self, forKey: .series)
        weeklyPicks = try c.decode(ClassicWeeklyPicks.self, forKey: .weeklyPicks)
        originals = try c.decodeIfPresent([ClassicOriginalCover].self, forKey: .originals) ?? []
        pendingCovers = try c.decodeIfPresent([String].self, forKey: .pendingCovers) ?? []
        featuredID = try c.decodeIfPresent(UUID.self, forKey: .featuredID)
    }
}

// MARK: - Ekranların gösterdiği öğe

/// Bir rafta yan yana duran şey: tek masal ya da bir seri.
enum ClassicItem: Identifiable, Equatable {
    case tale(ClassicTale)
    case series(ClassicSeries, episodeCount: Int)

    var id: UUID {
        switch self {
        case .tale(let t): return t.id
        case .series(let s, _): return s.id
        }
    }

    var title: String {
        switch self {
        case .tale(let t): return t.title
        case .series(let s, _): return s.title
        }
    }

    var cover: String {
        switch self {
        case .tale(let t): return t.cover
        case .series(let s, _): return s.cover
        }
    }

    var coverFocus: ClassicFocus {
        switch self {
        case .tale(let t): return t.coverFocus
        case .series(let s, _): return s.coverFocus
        }
    }

    /// Kapağın altındaki ikinci satır: "Grimm · 12 dk", "Anadolu · 6 masal".
    var meta: String {
        switch self {
        case .tale(let t): return t.shortMeta
        case .series(let s, let n): return "\(s.byline) · \(n) \(s.unitName)"
        }
    }

    var ageMin: Int {
        switch self {
        case .tale(let t): return t.ageMin
        case .series(let s, _): return s.ageMin
        }
    }

    var ageMax: Int {
        switch self {
        case .tale(let t): return t.ageMax
        case .series(let s, _): return s.ageMax
        }
    }

    func fits(age: Int) -> Bool { (ageMin...ageMax).contains(age) }
}
