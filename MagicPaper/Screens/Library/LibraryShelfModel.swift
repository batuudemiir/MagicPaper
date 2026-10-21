// LibraryShelfModel.swift
// Kitaplığın içeriği: hangi kitap hangi rafta, hangi sırada, ne arayınca
// bulunur (karar 20 Ekim 2026). Görünümden ayrı ve saf: kitaplık ekranı bunu
// veri değişince bir kez kurar, kaydırırken yeniden hesaplamaz (ana sayfadaki
// 166 ms'lik donmanın dersi).
//
// İki tür kitap: çocuğun kendi masalları ve Günlük'ten açtığı klasikler.
// Tek, başlıksız dizi (karar 21 Ekim 2026; Apple Books, Kindle, Audible
// gibi): varsayılan son okunan önde, istenirse yeni yazılan ya da ada göre.
// Her kitap bir kez görünür; ne zaman okunduğu kapağın altında yazar
// ("Dün · 4 dk"). Mod raf değil, süzgeç ve kapaktaki işarettir.

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
    /// Son okunduğu ya da yazıldığı an; varsayılan sıra en yeniden eskiye.
    let lastActivity: Date
    /// Yazıldığı (klasikte ilk açıldığı) an: "Yeni yazılan" sırası.
    let writtenAt: Date
    /// Son okunmanın göreli adı: "Bugün", "Dün", "3 gün önce", "12 Ekim".
    let when: String
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

    /// Kapağın altındaki satır: ne zaman · süre. Mod kapağın renginden ve
    /// simgesinden belli; klasikte "Klasik" yazar.
    var meta: String {
        kind == .classic ? "Klasik · \(when)" : "\(when) · \(minutes) dk"
    }

    /// VoiceOver: kapakta renkle ve simgeyle verilen tür yazıyla da söylenir.
    var kindLabel: String {
        if kind == .classic { return "klasik masal" }
        return mode.map { "\($0.title) masalı" } ?? "masal"
    }

    /// VoiceOver: tür ve rozetin anlamı.
    var accessibilityStatus: String? {
        let status: String?
        switch badge {
        case .progress(let p): status = "yarım, yüzde \(Int(p * 100)) okundu"
        case .episode(let n, let total): status = "seri, \(n). bölüm, \(total) bölümden"
        case .favorite: status = "favori"
        case nil: status = progress >= 1 ? "okundu" : nil
        }
        return [kindLabel, status].compactMap { $0 }.joined(separator: ", ")
    }

    static func == (lhs: LibraryItem, rhs: LibraryItem) -> Bool {
        lhs.id == rhs.id && lhs.progress == rhs.progress && lhs.isFavorite == rhs.isFavorite
            && lhs.title == rhs.title && lhs.episode?.number == rhs.episode?.number
            && lhs.lastActivity == rhs.lastActivity && lhs.art == rhs.art && lhs.when == rhs.when
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

/// Kitaplığın sırası (Apple Books ve Audible'daki gibi küçük bir menü).
enum LibrarySort: String, CaseIterable, Identifiable {
    case recent, newest, title

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recent: return "Son okunan"
        case .newest: return "Yeni yazılan"
        case .title: return "Ada göre"
        }
    }
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

    /// Göreli gün adı: Bugün · Dün · "3 gün önce" · "12 Ekim" (başka yılsa yılıyla).
    static func relativeLabel(for date: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDate(date, inSameDayAs: now) { return "Bugün" }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date),
                                           to: calendar.startOfDay(for: now)).day ?? 0
        if days == 1 { return "Dün" }
        if days > 1, days < 7 { return "\(days) gün önce" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = calendar.isDate(date, equalTo: now, toGranularity: .year) ? "d MMMM" : "d MMMM yyyy"
        return formatter.string(from: date)
    }

    /// Süzgeç, arama ve sıra birlikte; arama başlık, çocuk adı, mod ve dünya adında.
    func items(for filter: LibraryFilter, query: String = "", sort: LibrarySort = .recent) -> [LibraryItem] {
        let needle = Self.fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
        let list = items.filter { item in
            filter.admits(item) && (needle.isEmpty || item.searchText.contains(needle))
        }
        switch sort {
        case .recent: return list
        case .newest: return list.sorted { $0.writtenAt > $1.writtenAt }
        case .title:
            let tr = Locale(identifier: "tr_TR")
            return list.sorted { $0.title.compare($1.title, locale: tr) == .orderedAscending }
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
                      art: (Story) -> MPBookCover.Art = LibraryShelfModel.coverArt,
                      now: Date = Date(), calendar: Calendar = .current) -> LibraryShelfModel {
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
                               writtenAt: story.createdAt,
                               when: relativeLabel(for: story.lastReadAt ?? story.createdAt, now: now, calendar: calendar),
                               art: art(story),
                               searchText: fold(words.compactMap { $0 }.joined(separator: " ")))
        }
        list += classics.map { entry in
            let tale = entry.tale
            return LibraryItem(id: tale.id, kind: .classic, title: tale.title, mode: nil,
                               minutes: tale.minutes, progress: entry.fraction,
                               isFavorite: isFavorite(tale.id), episode: nil,
                               lastActivity: entry.openedAt,
                               writtenAt: entry.openedAt,
                               when: relativeLabel(for: entry.openedAt, now: now, calendar: calendar),
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
