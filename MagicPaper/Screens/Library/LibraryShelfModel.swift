// LibraryShelfModel.swift
// Kitaplığın içeriği: hangi kitap hangi rafta, hangi sırada, ne arayınca
// bulunur (karar 20 Ekim 2026). Görünümden ayrı ve saf: kitaplık ekranı bunu
// veri değişince bir kez kurar, kaydırırken yeniden hesaplamaz (ana sayfadaki
// 166 ms'lik donmanın dersi).
//
// İki tür kitap: çocuğun kendi masalları ve Günlük'ten açtığı klasikler.
// Tek zaman çizgisi (karar 21 Ekim 2026): son okunmaya göre yeniden eskiye,
// "Bugün · Dün · Bu hafta · Geçen hafta · Ekim…" bölümleriyle. Her kitap bir
// kez görünür; mod raf değil, süzgeç ve kapaktaki işarettir.

import Foundation

/// Kitaplıktaki tek kitap.
struct LibraryItem: Identifiable, Equatable {
    enum Kind: Equatable {
        case story
        case classic
    }

    let id: UUID
    let kind: Kind
    let title: String
    let mode: StoryMode?
    let minutes: Int
    /// 0…1; 0 açılmamış, 1 bitmiş.
    let progress: Double
    let isFavorite: Bool
    /// Seri bölümü: (kaçıncı, toplam).
    let episode: (number: Int, total: Int)?
    /// Son okunduğu ya da yazıldığı an; raflar en yeniden eskiye.
    let lastActivity: Date
    let art: MPBookCover.Art
    /// Aramada eşleşen sözcükler, katlanmış (başlık, çocuk, mod, dünya…).
    let searchText: String

    var isPartlyRead: Bool { progress > 0 && progress < 1 }

    /// Tek rozet yeri: yarım → bölüm → favori.
    var badge: MPBookCover.Badge? {
        if isPartlyRead { return .progress(progress) }
        if let episode { return .episode(episode.number, of: episode.total) }
        if isFavorite { return .favorite }
        return nil
    }

    /// Kapağın altındaki satır: kategori · süre.
    var meta: String {
        let category = kind == .classic ? "Klasik" : (mode?.shortTitle ?? "Masal")
        return "\(category) · \(minutes) dakika"
    }

    /// VoiceOver: rozetin anlamı.
    var accessibilityStatus: String? {
        switch badge {
        case .progress(let p): return "yarım, yüzde \(Int(p * 100)) okundu"
        case .episode(let n, let total): return "seri, \(n). bölüm, \(total) bölümden"
        case .favorite: return "favori"
        case nil: return progress >= 1 ? "okundu" : nil
        }
    }

    static func == (lhs: LibraryItem, rhs: LibraryItem) -> Bool {
        lhs.id == rhs.id && lhs.progress == rhs.progress && lhs.isFavorite == rhs.isFavorite
            && lhs.title == rhs.title && lhs.episode?.number == rhs.episode?.number
            && lhs.lastActivity == rhs.lastActivity && lhs.art == rhs.art
    }
}

/// Kitaplığın süzgeci: çipler ve rafların "Tümü" bağlantısı.
enum LibraryFilter: Hashable, Identifiable {
    case all
    case favorites
    case mode(StoryMode)
    case classics

    var id: String { title }

    var title: String {
        switch self {
        case .all: return "Tümü"
        case .favorites: return "Favoriler"
        case .mode(let mode): return mode.title
        case .classics: return "Klasikler"
        }
    }

    /// Çipteki kısa ad.
    var chipTitle: String {
        if case .mode(let mode) = self { return mode.shortTitle }
        return title
    }

    func admits(_ item: LibraryItem) -> Bool {
        switch self {
        case .all: return true
        case .favorites: return item.isFavorite
        case .mode(let mode): return item.kind == .story && item.mode == mode
        case .classics: return item.kind == .classic
        }
    }
}

/// Zaman çizgisinin bir bölümü: "Bugün", "Dün", "Bu hafta", "Ekim"…
struct LibrarySection: Identifiable, Equatable {
    let title: String
    let items: [LibraryItem]
    var id: String { title }
}

struct LibraryShelfModel: Equatable {
    /// En yeniden eskiye.
    let items: [LibraryItem]

    static let empty = LibraryShelfModel(items: [])

    init(items: [LibraryItem]) {
        self.items = items.sorted { $0.lastActivity > $1.lastActivity }
    }

    var isEmpty: Bool { items.isEmpty }
    var storyCount: Int { items.filter { $0.kind == .story }.count }
    var classicCount: Int { items.filter { $0.kind == .classic }.count }

    /// "Kaldığın yerden": en son açılan yarım kitap(lar).
    func continueItems(limit: Int = 1) -> [LibraryItem] {
        Array(items.filter(\.isPartlyRead).prefix(limit))
    }

    /// Çiplerde gösterilecek süzgeçler: içi dolu olanlar, sabit sırada.
    /// "Tümü" her zaman başta.
    var availableFilters: [LibraryFilter] {
        let candidates: [LibraryFilter] = [.favorites] + StoryMode.displayOrder.map { .mode($0) } + [.classics]
        return [.all] + candidates.filter { filter in items.contains(where: filter.admits) }
    }

    /// Süzgeç ve aramadan geçen kitaplar, zaman bölümlerine ayrılmış.
    /// Boş bölüm yok; sıra korunur (yeniden eskiye).
    func sections(for filter: LibraryFilter, query: String = "",
                  now: Date = Date(), calendar: Calendar = .current) -> [LibrarySection] {
        var result: [LibrarySection] = []
        for item in items(for: filter, query: query) {
            let title = Self.sectionTitle(for: item.lastActivity, now: now, calendar: calendar)
            if let last = result.last, last.title == title {
                result[result.count - 1] = LibrarySection(title: title, items: last.items + [item])
            } else {
                result.append(LibrarySection(title: title, items: [item]))
            }
        }
        return result
    }

    /// Bugün · Dün · Bu hafta · Geçen hafta · ay adı (başka yılsa yıl da).
    static func sectionTitle(for date: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDate(date, inSameDayAs: now) { return "Bugün" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) { return "Dün" }
        if let week = calendar.dateInterval(of: .weekOfYear, for: now) {
            if week.contains(date) { return "Bu hafta" }
            if let last = calendar.date(byAdding: .weekOfYear, value: -1, to: week.start),
               let lastWeek = calendar.dateInterval(of: .weekOfYear, for: last),
               lastWeek.contains(date) { return "Geçen hafta" }
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = calendar.isDate(date, equalTo: now, toGranularity: .year) ? "LLLL" : "LLLL yyyy"
        return formatter.string(from: date).capitalized(with: Locale(identifier: "tr_TR"))
    }

    /// Süzgeç ve arama birlikte; arama başlık, çocuk adı, mod ve dünya adında.
    func items(for filter: LibraryFilter, query: String = "") -> [LibraryItem] {
        let needle = Self.fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
        return items.filter { item in
            filter.admits(item) && (needle.isEmpty || item.searchText.contains(needle))
        }
    }

    /// Türkçe katlama: "İ"/"ı" doğru küçülsün.
    static func fold(_ text: String) -> String { MPText.foldedForSearch(text) }
}

// MARK: - Kurulum

extension LibraryShelfModel {
    /// Uygulamanın verilerinden kitaplık.
    ///
    /// - stories: onay kapısından geçmiş, bu çocuğun masalları.
    /// - classics: bu çocuğun açtığı Günlük klasikleri ve ilerlemesi.
    /// - art: kapak; testte mozaik üretmemek için değiştirilebilir.
    static func build(stories: [Story],
                      isFavorite: (UUID) -> Bool,
                      seriesTotal: (Story) -> Int? = { _ in nil },
                      classics: [(tale: ClassicTale, fraction: Double, openedAt: Date)] = [],
                      art: (Story) -> MPBookCover.Art = LibraryShelfModel.coverArt) -> LibraryShelfModel {
        var list: [LibraryItem] = stories.map { story in
            let mode = story.mpMode
            let words = [story.title, story.childName, mode?.title, mode?.shortTitle, story.mpWorld.name]
            let episode = story.origin?.seriesEpisode.map { number in
                (number: number, total: seriesTotal(story) ?? 5)
            }
            return LibraryItem(id: story.id, kind: .story, title: story.title, mode: mode,
                               minutes: story.mpReadingMinutes, progress: story.mpProgress,
                               isFavorite: isFavorite(story.id), episode: episode,
                               lastActivity: story.lastReadAt ?? story.createdAt,
                               art: art(story),
                               searchText: fold(words.compactMap { $0 }.joined(separator: " ")))
        }
        list += classics.map { entry in
            let tale = entry.tale
            return LibraryItem(id: tale.id, kind: .classic, title: tale.title, mode: nil,
                               minutes: tale.minutes, progress: entry.fraction,
                               isFavorite: isFavorite(tale.id), episode: nil,
                               lastActivity: entry.openedAt,
                               art: .image(tale.cover, focus: tale.coverFocus),
                               searchText: fold([tale.title, tale.byline, "Klasik", "Klasikler"].joined(separator: " ")))
        }
        return LibraryShelfModel(items: list)
    }

    /// Kendi masalının kapağı: teslim edilmiş set kapağı varsa o, yoksa
    /// başlık kapağı (mod tonunda kâğıt, ortada adı; 21 Ekim). Modu
    /// bilinmeyen eski masal gökyüzü tonunda, simgesiz.
    static func coverArt(_ story: Story) -> MPBookCover.Art {
        if let asset = story.mpKitCoverAsset ?? story.mpDefaultCoverAsset { return .image(asset) }
        let mode = story.mpMode
        return .title(story.title, tone: mode?.tone ?? .sky, modeSymbol: mode?.symbol,
                      worldSymbol: story.mpWorld.icon)
    }
}
