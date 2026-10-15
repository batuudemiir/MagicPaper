import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "ClassicsCatalog")

/// Günlük'ün içeriği ve bütün sorguları. Saf bir değer: tarih, okuma geçmişi
/// ve yaş dışarıdan verilir, böylece her kural düz bir birim testiyle
/// doğrulanır.
struct ClassicsCatalog: Equatable {

    let file: ClassicsCatalogFile

    init(file: ClassicsCatalogFile) {
        self.file = file
    }

    static let empty = ClassicsCatalog(file: ClassicsCatalogFile(
        version: 1, tales: [], series: [],
        weeklyPicks: ClassicWeeklyPicks(weekOf: "2026-01-01", ids: []), originals: []))

    // MARK: - Yükleme

    /// Pakete gömülü katalog. Okunamazsa boş katalog: Günlük boş görünür,
    /// uygulama çalışmaya devam eder. Testler bunu yakalar.
    static let bundled: ClassicsCatalog = load(from: .main)

    static func load(from bundle: Bundle) -> ClassicsCatalog {
        guard let url = bundle.url(forResource: "classics_catalog", withExtension: "json") else {
            logger.error("classics_catalog.json pakette yok")
            return .empty
        }
        do {
            let data = try Data(contentsOf: url)
            return ClassicsCatalog(file: try JSONDecoder().decode(ClassicsCatalogFile.self, from: data))
        } catch {
            logger.error("classics_catalog.json okunamadı: \(String(describing: error), privacy: .public)")
            return .empty
        }
    }

    /// Okuyucunun kapak yaprağı için: bu id bir Günlük masalıysa kapağı.
    static func coverAsset(for id: UUID) -> String? {
        bundled.tale(id)?.cover ?? bundled.originalCover(feedID: id)?.cover
    }

    static func contains(_ id: UUID) -> Bool {
        bundled.tale(id) != nil || bundled.originalCover(feedID: id) != nil
    }

    // MARK: - Arama

    var tales: [ClassicTale] { file.tales }
    var series: [ClassicSeries] { file.series }

    /// Serilere ait olmayan masallar.
    var standaloneTales: [ClassicTale] { file.tales.filter { !$0.isEpisode } }

    func tale(_ id: UUID) -> ClassicTale? { file.tales.first { $0.id == id } }
    func series(_ id: UUID) -> ClassicSeries? { file.series.first { $0.id == id } }
    func originalCover(feedID: UUID) -> ClassicOriginalCover? { file.originals.first { $0.feedID == feedID } }

    func episodes(of seriesID: UUID) -> [ClassicTale] {
        file.tales.filter { $0.seriesID == seriesID }.sorted { ($0.episode ?? 0) < ($1.episode ?? 0) }
    }

    func item(_ id: UUID) -> ClassicItem? {
        if let s = series(id) { return .series(s, episodeCount: episodes(of: s.id).count) }
        if let t = tale(id) { return .tale(t) }
        return nil
    }

    /// Tek masallar ve seriler, katalogdaki sırayla.
    var allItems: [ClassicItem] {
        standaloneTales.map(ClassicItem.tale)
            + file.series.map { .series($0, episodeCount: episodes(of: $0.id).count) }
    }

    /// Bir rafın öğeleri. `age` verilirse yalnızca o yaşa uyanlar.
    func items(in shelf: ClassicShelf?, age: Int? = nil) -> [ClassicItem] {
        let onShelf: [ClassicItem]
        switch shelf {
        case nil:
            onShelf = allItems
        case .seriler:
            onShelf = file.series.map { .series($0, episodeCount: episodes(of: $0.id).count) }
        case .besDakika:
            onShelf = standaloneTales.filter { $0.minutes <= 5 }.map(ClassicItem.tale)
        case .sesli:
            onShelf = []
        case let written?:
            onShelf = standaloneTales.filter { $0.shelves.contains(written) }.map(ClassicItem.tale)
                + file.series.filter { $0.shelves.contains(written) }
                    .map { .series($0, episodeCount: episodes(of: $0.id).count) }
        }
        // Boyalı kapaklar önde, çizimi bekleyenler (`pendingCovers`) sonda;
        // kendi içlerinde katalog sırası korunur.
        let pending = Set(file.pendingCovers)
        let ordered = onShelf.filter { !pending.contains($0.cover) } + onShelf.filter { pending.contains($0.cover) }
        guard let age else { return ordered }
        return ordered.filter { $0.fits(age: age) }
    }

    /// Haftanın seçkisi, editörün sırasıyla. Yaşa göre süzülmez: numaralar
    /// bir listedir, delik bırakmamalı.
    var weeklyPicks: [ClassicItem] {
        file.weeklyPicks.ids.compactMap(item)
    }

    /// Detaydaki "Benzerleri": aynı kökenden olanlar önce, sonra raf
    /// paylaşanlar. Masalın kendisi ve kendi serisi hariç.
    func similar(to tale: ClassicTale, limit: Int = 8) -> [ClassicItem] {
        let others = allItems.filter { $0.id != tale.id && $0.id != tale.seriesID }
        func score(_ item: ClassicItem) -> Int {
            switch item {
            case .tale(let t):
                return (t.origin == tale.origin ? 2 : 0) + (Set(t.shelves).isDisjoint(with: tale.shelves) ? 0 : 1)
            case .series(let s, _):
                return Set(s.shelves).isDisjoint(with: tale.shelves) ? 0 : 1
            }
        }
        let ranked = others.enumerated()
            .map { (offset: $0.offset, item: $0.element, score: score($0.element)) }
            .filter { $0.score > 0 }
            .sorted { $0.score != $1.score ? $0.score > $1.score : $0.offset < $1.offset }
        return Array(ranked.prefix(limit).map(\.item))
    }

    /// Başlıkta arama: büyük/küçük harf ve Türkçe aksan duyarsız.
    func search(_ query: String) -> [ClassicItem] {
        let needle = Self.fold(query)
        guard !needle.isEmpty else { return allItems }
        let episodeHits = Set(file.tales.filter { $0.isEpisode && Self.fold($0.title).contains(needle) }
            .compactMap(\.seriesID))
        return allItems.filter { Self.fold($0.title).contains(needle) || episodeHits.contains($0.id) }
    }

    static func fold(_ text: String) -> String {
        text.lowercased(with: Locale(identifier: "tr_TR"))
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Günün masalı

    /// Günün masalı: tek masallardan, deterministik.
    ///
    /// 0. Kapağı çizilmiş olanlar (`pendingCovers` dışı).
    /// 1. Çocuğun yaşına uyanlar; hiçbiri uymazsa hepsi.
    /// 2. Okunmamışlar önce. Bugün zaten seçilmiş olan (`pinned`) okunmuş
    ///    sayılmaz, gün ortasında okununca başka masala geçilmesin.
    /// 3. Havuz id'ye göre sıralanır, gün sırası havuzun boyuna bölünür:
    ///    aynı gün, aynı geçmiş, aynı masal — her cihazda.
    func todaysTale(day: String, age: Int?, read: Set<UUID>, pinned: UUID?) -> ClassicTale? {
        // Editörün seçimi her şeyin önünde: yaş ve okuma geçmişi onu değiştirmez.
        if let id = file.featuredID, let featured = tale(id), !featured.isEpisode { return featured }
        if let pinned, let tale = tale(pinned), !tale.isEpisode, !file.pendingCovers.contains(tale.cover),
           age.map(tale.fits(age:)) ?? true { return tale }
        // Günün masalı boyalı kapakla gelir: kapağı bekleyenler yalnızca başka
        // masal kalmadıysa seçilir.
        let pending = Set(file.pendingCovers)
        let illustrated = standaloneTales.filter { !pending.contains($0.cover) }
        let all = illustrated.isEmpty ? standaloneTales : illustrated
        let forAge = age.map { age in all.filter { $0.fits(age: age) } } ?? all
        let pool = forAge.isEmpty ? all : forAge
        let unread = pool.filter { !read.contains($0.id) }
        let candidates = (unread.isEmpty ? pool : unread).sorted { $0.id.uuidString < $1.id.uuidString }
        guard !candidates.isEmpty else { return nil }
        return candidates[Self.dayOrdinal(day) % candidates.count]
    }

    /// `yyyy-MM-dd` → 1970'ten bu yana gün. Okunamazsa 0.
    static func dayOrdinal(_ day: String) -> Int {
        let parts = day.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return 0 }
        var components = DateComponents()
        components.year = parts[0]; components.month = parts[1]; components.day = parts[2]
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        guard let date = calendar.date(from: components) else { return 0 }
        return max(Int(date.timeIntervalSince1970 / 86_400), 0)
    }
}

// MARK: - Başlık vitrini

/// Günlük'ün en üstündeki kaydırılan vitrinin bir slaytı.
struct ClassicHeaderSlide: Identifiable, Equatable {
    enum Kind: Equatable { case resume, today, bedtime, weekly }
    let kind: Kind
    let tale: ClassicTale
    var id: String { "\(kind)-\(tale.id)" }

    var eyebrow: String {
        switch kind {
        case .resume: return "Kaldığın yerden"
        case .today: return "Günün masalı"
        case .bedtime: return "Uyku vakti"
        case .weekly: return "Bu haftanın seçkisi"
        }
    }
}

extension ClassicsCatalog {
    /// Vitrinin slaytları, sırayla:
    /// 1. yarım kalan masal (en son açılan),
    /// 2. günün masalı,
    /// 3. uyku saatindeyse bir uyku masalı,
    /// 4. kalan yerler haftanın seçkisinden.
    /// Yalnızca boyalı kapağı olan tek masallar; aynı masal iki kez gelmez.
    func headerSlides(today: ClassicTale?, inProgress: [UUID], isBedtime: Bool, limit: Int = 5) -> [ClassicHeaderSlide] {
        let pending = Set(file.pendingCovers)
        var used = Set<UUID>()
        var slides: [ClassicHeaderSlide] = []
        func add(_ tale: ClassicTale?, _ kind: ClassicHeaderSlide.Kind) {
            guard let tale, slides.count < limit, !tale.isEpisode, !pending.contains(tale.cover),
                  !used.contains(tale.id) else { return }
            used.insert(tale.id)
            slides.append(ClassicHeaderSlide(kind: kind, tale: tale))
        }
        add(inProgress.lazy.compactMap(tale).first { !$0.isEpisode }, .resume)
        add(today, .today)
        if isBedtime { add(items(in: .uyku).compactMap { if case .tale(let t) = $0, !pending.contains(t.cover) { return t } else { return nil } }.first, .bedtime) }
        for item in weeklyPicks { if case .tale(let t) = item { add(t, .weekly) } }
        return slides
    }
}

// MARK: - Doğrulama

extension ClassicsCatalog {

    struct Issue: Equatable, CustomStringConvertible {
        let subject: String
        let problem: String
        var description: String { "\(subject): \(problem)" }
    }

    /// Kataloğun yayınlanabilir olup olmadığı. Boş liste = sorun yok.
    /// `assetExists` testte `UIImage(named:)`; burada UIKit'e bağlanmıyoruz.
    func validate(assetExists rawAssetExists: (String) -> Bool) -> [Issue] {
        var issues: [Issue] = []
        let pending = Set(file.pendingCovers)
        func assetExists(_ name: String) -> Bool { pending.contains(name) || rawAssetExists(name) }
        for name in pending where rawAssetExists(name) {
            issues.append(Issue(subject: name, problem: "kapak geldi, pendingCovers'tan çıkar"))
        }
        func flag(_ subject: String, _ problem: String) { issues.append(Issue(subject: subject, problem: problem)) }

        let ids = file.tales.map(\.id) + file.series.map(\.id)
        if Set(ids).count != ids.count { flag("katalog", "aynı id iki kez kullanılmış") }
        let slugs = file.tales.map(\.slug) + file.series.map(\.slug)
        if Set(slugs).count != slugs.count { flag("katalog", "aynı slug iki kez kullanılmış") }

        for tale in file.tales {
            let s = tale.slug
            if tale.title.isEmpty { flag(s, "başlık boş") }
            if tale.summary.isEmpty { flag(s, "özet boş") }
            if tale.byline.isEmpty { flag(s, "meta boş") }
            if tale.attribution.isEmpty { flag(s, "metin kaynağı boş") }
            if tale.coverCredit.isEmpty { flag(s, "görsel kaynağı boş") }
            if !(3...12).contains(tale.ageMin) || !(3...12).contains(tale.ageMax) || tale.ageMin > tale.ageMax {
                flag(s, "yaş aralığı geçersiz")
            }
            if tale.minutes <= 0 { flag(s, "süre geçersiz") }
            if !assetExists(tale.cover) { flag(s, "kapak yok: \(tale.cover)") }
            if !(0...1).contains(tale.coverFocus.x) || !(0...1).contains(tale.coverFocus.y) { flag(s, "odak 0…1 dışında") }
            if tale.soft.pages.isEmpty || tale.soft.pages.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                flag(s, "yumuşak anlatımda boş sayfa")
            }
            if let classic = tale.classic,
               classic.pages.isEmpty || classic.pages.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                flag(s, "klasik anlatımda boş sayfa")
            }
            if tale.shelves.contains(where: \.isDerived) { flag(s, "türetilen raf elle yazılmış") }
            if tale.isEpisode {
                if tale.episode == nil { flag(s, "bölüm numarası yok") }
                if let sid = tale.seriesID, series(sid) == nil { flag(s, "serisi katalogda yok") }
            } else if tale.shelves.isEmpty {
                flag(s, "hiçbir rafta değil")
            }
        }

        for series in file.series {
            let s = series.slug
            if series.title.isEmpty || series.summary.isEmpty { flag(s, "başlık ya da özet boş") }
            if series.attribution.isEmpty || series.coverCredit.isEmpty { flag(s, "kaynak bilgisi boş") }
            if !assetExists(series.cover) { flag(s, "kapak yok: \(series.cover)") }
            let numbers = episodes(of: series.id).compactMap(\.episode)
            if numbers.isEmpty {
                flag(s, "bölümü yok")
            } else if numbers != Array(1...numbers.count) {
                flag(s, "bölümler 1'den ardışık değil")
            }
            if series.shelves.contains(where: \.isDerived) { flag(s, "türetilen raf elle yazılmış") }
        }

        if let id = file.featuredID, tale(id) == nil { flag("öne çıkan", "katalogda olmayan masal") }
        for id in file.weeklyPicks.ids where item(id) == nil {
            flag("haftanın seçkisi", "katalogda olmayan id: \(id)")
        }
        if Set(file.weeklyPicks.ids).count != file.weeklyPicks.ids.count {
            flag("haftanın seçkisi", "aynı masal iki kez")
        }

        for original in file.originals {
            if !assetExists(original.cover) { flag(original.cover, "orijinal masal kapağı yok") }
            if original.coverCredit.isEmpty { flag(original.cover, "görsel kaynağı boş") }
        }
        return issues
    }
}
