import Foundation

/// Ana sayfa zilinin "Yenilikler" listesi (26 Kasım 2026, Batuhan: zil yalnızca
/// Profil'e geçiyordu, çalışmıyor gibi duruyordu).
///
/// Saf: girdiler verilir, liste döner; görülen kimlikler `HomeNewsSeen`'de.
/// Uygulama içinde kalır, push yok, geri sayım yok, "kaçırma" dili yok
/// (CLAUDE.md §7). Yalnızca çocuğun gerçekten yeni olan şeyleri: kazanılan
/// rozet, günü gelen seri bölümü, haftanın yeni seçkisi, yeni Original masal.
struct HomeNews: Equatable {

    enum Action: Equatable {
        case badges
        case series
        case masallar
        case tale(UUID)
    }

    struct Item: Identifiable, Equatable {
        /// Görüldü defterinin anahtarı: aynı yenilik ikinci kez nokta yakmaz.
        let id: String
        let systemImage: String
        let tone: MPWorldTone
        let title: String
        let subtitle: String
        let action: Action
    }

    struct Inputs: Equatable {
        /// `MPBadgeNews.homeNote`: masal sonunda kazanılan rozet ya da kat.
        var badgeNote: String? = nil
        /// Günü gelmiş, okunmamış seri bölümü.
        var seriesReady: (episode: Int, title: String, storyID: UUID)? = nil
        /// Haftanın seçkisi: haftası ve ilk masalın adı.
        var weeklyPick: (weekOf: String, firstTitle: String)? = nil
        /// Son yedi günde yayımlanan Original masallar, en yeni önce.
        var newOriginals: [(id: UUID, title: String)] = []

        static func == (l: Inputs, r: Inputs) -> Bool {
            l.badgeNote == r.badgeNote
                && l.seriesReady?.storyID == r.seriesReady?.storyID
                && l.weeklyPick?.weekOf == r.weeklyPick?.weekOf
                && l.newOriginals.map(\.id) == r.newOriginals.map(\.id)
        }
    }

    let items: [Item]

    var isEmpty: Bool { items.isEmpty }

    static func make(_ inputs: Inputs) -> HomeNews {
        var items: [Item] = []
        if let note = inputs.badgeNote {
            items.append(Item(id: "badge-\(note)", systemImage: "rosette", tone: .yellow,
                              title: "Yeni rozet", subtitle: note, action: .badges))
        }
        if let ready = inputs.seriesReady {
            items.append(Item(id: "series-\(ready.storyID.uuidString)", systemImage: "pawprint", tone: .peach,
                              title: SeriesCopy.readyTitle(ready.episode), subtitle: ready.title, action: .series))
        }
        for original in inputs.newOriginals.prefix(2) {
            items.append(Item(id: "original-\(original.id.uuidString)", systemImage: "sparkles", tone: .lav,
                              title: "Yeni masal", subtitle: original.title, action: .tale(original.id)))
        }
        if let pick = inputs.weeklyPick {
            items.append(Item(id: "weekly-\(pick.weekOf)", systemImage: "books.vertical", tone: .mint,
                              title: "Bu haftanın seçkisi", subtitle: "\(pick.firstTitle) ve diğerleri Masallar'da",
                              action: .masallar))
        }
        return HomeNews(items: items)
    }

    /// Zilin noktası: listede görülmemiş bir yenilik var mı.
    func hasUnseen(seen: Set<String>) -> Bool {
        items.contains { !seen.contains($0.id) }
    }
}

/// Görülen yenilikler, çocuk başına. Liste açılınca hepsi görülmüş sayılır.
enum HomeNewsSeen {
    private static func key(_ childID: UUID?) -> String {
        "mp_homeNewsSeen_\(childID?.uuidString ?? "none")"
    }

    static func ids(for childID: UUID?, defaults: UserDefaults = .standard) -> Set<String> {
        Set(defaults.stringArray(forKey: key(childID)) ?? [])
    }

    static func markSeen(_ news: HomeNews, for childID: UUID?, defaults: UserDefaults = .standard) {
        // Yalnızca şu an listede olanlar tutulur: defter büyümez.
        defaults.set(news.items.map(\.id), forKey: key(childID))
    }
}

extension HomeNews {
    /// Canlı servislerden toplanır; kural `make`'te.
    @MainActor
    static func live(childID: UUID?, now: Date = Date(), calendar: Calendar = .current) -> HomeNews {
        var inputs = Inputs()
        inputs.badgeNote = MPBadgeNews.shared.homeNote(for: childID)
        if let childID, case .ready(let storyID, let episode, let title)? = SeriesManager.shared.cardState(for: childID) {
            inputs.seriesReady = (episode, title, storyID)
        }
        let library = ClassicsLibrary.shared
        if let first = library.weeklyPicks.first {
            inputs.weeklyPick = (library.catalog.file.weeklyPicks.weekOf, first.title)
        }
        let today = TodaysStoryPicker.day(now, calendar: calendar)
        let weekAgo = TodaysStoryPicker.day(calendar.date(byAdding: .day, value: -7, to: now) ?? now, calendar: calendar)
        let visible = Set(library.originalTales.map(\.id))
        inputs.newOriginals = RemoteContentService.shared.originals
            .filter { $0.publishDate > weekAgo && $0.publishDate <= today && visible.contains($0.id) }
            .sorted { $0.publishDate > $1.publishDate }
            .map { (id: $0.id, title: $0.title) }
        return make(inputs)
    }
}
