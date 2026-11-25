import Foundation

// Rozet kataloğu (rozet planı, karar 15 Kasım 2026; `docs/ROZET_PLANI.md`).
//
// CLAUDE.md ilke 7: rozet yalnızca okuyarak kazanılır, kaybolmaz; geri sayım,
// ilerleme çubuğu, "az kaldı", kıyas ve bildirim yok. Kilitli rozet yalnızca
// eylem cümlesi söyler ("Bir macera masalı okuyunca açılır"), kalan sayı söylemez.
//
// FAZ 17'nin sekiz rozetinin kimlikleri (`firstStory`, `fiveStories`, ...)
// aynen korunur: eski defterlerde kazanılmış rozet kaybolmaz.

/// Rozet ailesi. Kademeli ailelerde rozetler aynı yolun katlarıdır.
enum MPBadgeFamily: String, CaseIterable, Codable {
    case stories, bedtime, adventure, learning, readingDays, words
    case series, discovery, places, friends, family, secret

    var title: String {
        switch self {
        case .stories:     return "Masal yolu"
        case .bedtime:     return "Ay arkadaşı"
        case .adventure:   return "Yol açan"
        case .learning:    return "Meraklı"
        case .readingDays: return "Okuma günleri"
        case .words:       return "Kelime avcısı"
        case .series:      return "Seri"
        case .discovery:   return "Keşif"
        case .places:      return "Gezgin"
        case .friends:     return "Dostlar"
        case .family:      return "Ailemle"
        case .secret:      return "Gizli"
        }
    }

    /// Kademeli aile tek kartta en yüksek katıyla görünür (R3).
    var isTiered: Bool {
        switch self {
        case .series, .discovery, .family, .secret: return false
        default: return true
        }
    }
}

/// Bir rozetin defterden okuduğu sayı (`MPBadgeLedger.value(of:)`).
enum MPBadgeMetric: String, Codable {
    case finished, bedtime, adventure, learning, allModes
    case readingDays, words, wordCard
    case seriesSecond, seriesCompleted
    case classics, originals, surprise
    case places, companions, familyMembers, voiceStories
    case rereadDays, morning, fullWeekend, anniversary
}

struct MPBadge: Identifiable, Hashable {
    let id: String
    let family: MPBadgeFamily
    /// Aile içindeki sıra, 1'den başlar.
    let tier: Int
    let metric: MPBadgeMetric
    let threshold: Int
    let title: String
    let icon: String
    let tone: MPWorldTone
    /// Kilitliyken dokununca: yalnızca eylem, sayı yok (R0 kararı 2).
    let lockedHint: String

    var isSecret: Bool { family == .secret }

    /// Gizli rozet kazanılana kadar adını ve simgesini saklar.
    func displayTitle(unlocked: Bool) -> String { isSecret && !unlocked ? "Gizli rozet" : title }
    func displayIcon(unlocked: Bool) -> String { isSecret && !unlocked ? "questionmark" : icon }

    static func == (a: MPBadge, b: MPBadge) -> Bool { a.id == b.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// FAZ 17'nin sekiz rozeti: testler ve eski çağrılar adıyla okur.
extension MPBadge {
    static let firstStory = MPBadgeCatalog.badge("firstStory")!
    static let fiveStories = MPBadgeCatalog.badge("fiveStories")!
    static let tenStories = MPBadgeCatalog.badge("tenStories")!
    static let twentyFiveStories = MPBadgeCatalog.badge("twentyFiveStories")!
    static let sevenBedtime = MPBadgeCatalog.badge("sevenBedtime")!
    static let firstAdventure = MPBadgeCatalog.badge("firstAdventure")!
    static let firstLearning = MPBadgeCatalog.badge("firstLearning")!
    static let firstSeriesCompleted = MPBadgeCatalog.badge("firstSeriesCompleted")!
}

enum MPBadgeCatalog {

    /// Katalog sürümü. Defterin sürümü bundan küçükse rozetler sessizce
    /// yeniden hesaplanır (`MPBadgeStore.ledger`). 1: FAZ 17'nin 8 rozeti;
    /// 2: rozet planı, 69 rozet ve Yıldız katı (15 Kasım 2026).
    static let version = 2

    static let all: [MPBadge] = build()

    private static let index: [String: MPBadge] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func badge(_ id: String) -> MPBadge? { index[id] }

    static func badges(in family: MPBadgeFamily) -> [MPBadge] { all.filter { $0.family == family } }

    /// Rozetlerim ızgarası: önce kazanılanlar, sonra kilitliler; ikisi de
    /// katalog sırasıyla. Her zaman bütün rozetler.
    static func gridOrder(earned: Set<String>) -> [MPBadge] {
        all.filter { earned.contains($0.id) } + all.filter { !earned.contains($0.id) }
    }

    // MARK: - Liste (docs/ROZET_PLANI.md, 3. bölüm)

    private typealias Step = (id: String, threshold: Int, title: String)

    private static func tiered(_ family: MPBadgeFamily, _ metric: MPBadgeMetric, icon: String,
                               tone: MPWorldTone, first: String, later: String, _ steps: [Step]) -> [MPBadge] {
        steps.enumerated().map { i, step in
            MPBadge(id: step.id, family: family, tier: i + 1, metric: metric, threshold: step.threshold,
                    title: step.title, icon: icon, tone: tone, lockedHint: i == 0 ? first : later)
        }
    }

    private static func single(_ id: String, _ family: MPBadgeFamily, tier: Int, _ metric: MPBadgeMetric,
                               _ threshold: Int, _ title: String, icon: String, tone: MPWorldTone,
                               hint: String) -> MPBadge {
        MPBadge(id: id, family: family, tier: tier, metric: metric, threshold: threshold,
                title: title, icon: icon, tone: tone, lockedHint: hint)
    }

    private static func build() -> [MPBadge] {
        var out: [MPBadge] = []
        out += tiered(.stories, .finished, icon: "books.vertical", tone: .lav,
                      first: "Bir masalı sonuna kadar okuyunca açılır.",
                      later: "Masal okudukça açılır.", [
            ("firstStory", 1, "İlk masal"),
            ("threeStories", 3, "Üç masal"),
            ("fiveStories", 5, "5 masal"),
            ("tenStories", 10, "10 masal"),
            ("fifteenStories", 15, "15 masal"),
            ("twentyFiveStories", 25, "25 masal"),
            ("fiftyStories", 50, "50 masal"),
            ("seventyFiveStories", 75, "75 masal"),
            ("hundredStories", 100, "100 masal"),
            ("hundredFiftyStories", 150, "150 masal"),
            ("twoHundredStories", 200, "Masal ustası"),
        ])
        out += tiered(.bedtime, .bedtime, icon: "moon", tone: .sky,
                      first: "Bir uyku masalı okuyunca açılır.",
                      later: "Uyku masalları okudukça açılır.", [
            ("firstBedtime", 1, "İlk uyku masalı"),
            ("sevenBedtime", 7, "7 uyku masalı"),
            ("fifteenBedtime", 15, "15 uyku masalı"),
            ("thirtyBedtime", 30, "30 uyku masalı"),
            ("fiftyBedtime", 50, "50 uyku masalı"),
            ("hundredBedtime", 100, "100 uyku masalı"),
        ])
        out += tiered(.adventure, .adventure, icon: "tent", tone: .mint,
                      first: "Bir macera masalı okuyunca açılır.",
                      later: "Macera masalları okudukça açılır.", [
            ("firstAdventure", 1, "İlk macera"),
            ("fiveAdventures", 5, "5 macera"),
            ("tenAdventures", 10, "10 macera"),
            ("twentyAdventures", 20, "20 macera"),
            ("thirtyAdventures", 30, "30 macera"),
        ])
        out += tiered(.learning, .learning, icon: "lightbulb", tone: .yellow,
                      first: "Bir öğrenelim masalı okuyunca açılır.",
                      later: "Öğrenelim masalları okudukça açılır.", [
            ("firstLearning", 1, "İlk öğrenelim masalı"),
            ("fiveLearning", 5, "5 öğrenelim masalı"),
            ("tenLearning", 10, "10 öğrenelim masalı"),
            ("twentyLearning", 20, "20 öğrenelim masalı"),
            ("thirtyLearning", 30, "30 öğrenelim masalı"),
        ])
        out += tiered(.readingDays, .readingDays, icon: "calendar", tone: .peach,
                      first: "Masal okunan günler toplandıkça açılır.",
                      later: "Masal okunan günler toplandıkça açılır.", [
            ("readingDays3", 3, "3 gün okuduk"),
            ("readingDays7", 7, "7 gün okuduk"),
            ("readingDays14", 14, "14 gün okuduk"),
            ("readingDays30", 30, "30 gün okuduk"),
            ("readingDays50", 50, "50 gün okuduk"),
            ("readingDays75", 75, "75 gün okuduk"),
            ("readingDays100", 100, "100 gün okuduk"),
        ])
        out += tiered(.words, .words, icon: "character.book.closed", tone: .green,
                      first: "Masalda yeni bir kelime öğrenince açılır.",
                      later: "Yeni kelimeler öğrendikçe açılır.", [
            ("firstWord", 1, "İlk yeni kelime"),
            ("words10", 10, "10 kelime"),
            ("words25", 25, "25 kelime"),
            ("words50", 50, "50 kelime"),
            ("words100", 100, "100 kelime"),
            ("words200", 200, "200 kelime"),
        ])
        out += [
            single("firstSeriesEpisode", .series, tier: 1, .seriesSecond, 1, "İlk devam",
                   icon: "bookmark", tone: .peach, hint: "Bir serinin ikinci bölümünü okuyunca açılır."),
            single("firstSeriesCompleted", .series, tier: 2, .seriesCompleted, 1, "İlk seri tamamlandı",
                   icon: "pawprint", tone: .peach, hint: "Bir serinin beş bölümünü bitirince açılır."),
            single("threeSeries", .series, tier: 3, .seriesCompleted, 3, "3 seri",
                   icon: "pawprint", tone: .peach, hint: "Serileri bitirdikçe açılır."),
            single("fiveSeries", .series, tier: 4, .seriesCompleted, 5, "5 seri",
                   icon: "pawprint", tone: .peach, hint: "Serileri bitirdikçe açılır."),
        ]
        out += [
            single("allThreeModes", .discovery, tier: 1, .allModes, 3, "Üç kapı",
                   icon: "door.left.hand.open", tone: .lav,
                   hint: "Uyku, macera ve öğrenelim masallarından birer tane okuyunca açılır."),
            single("firstClassic", .discovery, tier: 2, .classics, 1, "İlk klasik",
                   icon: "book.closed", tone: .pink, hint: "Bir klasik masal okuyunca açılır."),
            single("fiveClassics", .discovery, tier: 3, .classics, 5, "5 klasik",
                   icon: "book.closed", tone: .pink, hint: "Klasik masallar okudukça açılır."),
            single("tenClassics", .discovery, tier: 4, .classics, 10, "10 klasik",
                   icon: "book.closed", tone: .pink, hint: "Klasik masallar okudukça açılır."),
            single("firstOriginal", .discovery, tier: 5, .originals, 1, "Bulut Durağı",
                   icon: "cloud", tone: .sky, hint: "Bir MagicPaper Original masalı okuyunca açılır."),
            single("fiveOriginals", .discovery, tier: 6, .originals, 5, "5 Original",
                   icon: "cloud", tone: .sky, hint: "Original masallar okudukça açılır."),
            single("surprise", .discovery, tier: 7, .surprise, 1, "Sürprizci",
                   icon: "gift", tone: .yellow, hint: "\"Bana sürpriz yap\" masalını okuyunca açılır."),
            single("wordCard", .discovery, tier: 8, .wordCard, 1, "Meraklı parmak",
                   icon: "hand.point.up", tone: .green, hint: "Masal okurken bir kelimeye dokununca açılır."),
        ]
        out += tiered(.places, .places, icon: "map", tone: .mint,
                      first: "Masallarda yeni yerlere gittikçe açılır.",
                      later: "Masallarda yeni yerlere gittikçe açılır.", [
            ("places3", 3, "3 yer"),
            ("places5", 5, "5 yer"),
            ("places10", 10, "10 yer"),
            ("places15", 15, "15 yer"),
        ])
        out += tiered(.friends, .companions, icon: "heart", tone: .pink,
                      first: "Masallarda yeni dostlarla tanıştıkça açılır.",
                      later: "Masallarda yeni dostlarla tanıştıkça açılır.", [
            ("friends3", 3, "3 dost"),
            ("friends5", 5, "5 dost"),
            ("friends10", 10, "10 dost"),
            ("friends20", 20, "20 dost"),
        ])
        out += [
            single("familyInStory", .family, tier: 1, .familyMembers, 1, "Ailem masalda",
                   icon: "house", tone: .peach, hint: "Masal ailen'den biri masala girince açılır."),
            single("bigFamily", .family, tier: 2, .familyMembers, 3, "Büyük aile",
                   icon: "house", tone: .peach, hint: "Ailenden başka kişiler de masallara girdikçe açılır."),
            single("hugeFamily", .family, tier: 3, .familyMembers, 5, "Kocaman aile",
                   icon: "house", tone: .peach, hint: "Ailenden başka kişiler de masallara girdikçe açılır."),
            single("familiarVoice", .family, tier: 4, .voiceStories, 1, "Tanıdık ses",
                   icon: "waveform", tone: .lav, hint: "Bir masalı ailenin sesiyle dinleyince açılır."),
            single("voiceLibrary", .family, tier: 5, .voiceStories, 5, "Sesli kitaplık",
                   icon: "waveform", tone: .lav, hint: "Ailenin sesiyle masallar dinledikçe açılır."),
        ]
        let secretHint = "Bu rozet bir sürpriz. Okudukça bulacaksın."
        out += [
            single("rereadThree", .secret, tier: 1, .rereadDays, 3, "Tekrar tekrar",
                   icon: "arrow.clockwise", tone: .lav, hint: secretHint),
            single("morningStory", .secret, tier: 2, .morning, 1, "Sabah masalı",
                   icon: "sunrise", tone: .yellow, hint: secretHint),
            single("weekendStory", .secret, tier: 3, .fullWeekend, 1, "Hafta sonu masalı",
                   icon: "sun.max", tone: .peach, hint: secretHint),
            single("anniversary", .secret, tier: 4, .anniversary, 1, "Masal yıldönümü",
                   icon: "birthday.cake", tone: .pink, hint: secretHint),
        ]
        return out
    }
}

// MARK: - Yıldız katı (profilin rozeti, plan 5b)

/// Yıldız puanı arttıkça profilin attığı kat. Puan ve kat asla düşmez;
/// kardeşler arasında yan yana gösterilmez.
struct MPStarLevel: Identifiable, Hashable {
    let id: String
    let tier: Int
    let threshold: Int
    let title: String

    /// Kilitliyken eşik de yazılmaz (26 Kasım 2026): çocuğa sayı hedefi
    /// gösterilmez; beklenen, sayıya bağlı ödül okuma isteğini dış ödüle
    /// kaydırabilir (Deci, Koestner, Ryan 1999).
    var lockedHint: String { "Masal okudukça açılır." }

    static let all: [MPStarLevel] = [
        (10, "Kıvılcım"), (25, "Yıldız tozu"), (50, "Parıltı"), (100, "Küçük yıldız"),
        (150, "Parlak yıldız"), (250, "Kayan yıldız"), (400, "Takımyıldız"), (600, "Ay ışığı"),
        (800, "Kuyruklu yıldız"), (1000, "Samanyolu"), (1500, "Gökada"), (2000, "Masal göğü"),
    ].enumerated().map { i, level in
        MPStarLevel(id: "starLevel\(i + 1)", tier: i + 1, threshold: level.0, title: level.1)
    }

    /// Bu puanla ulaşılmış en yüksek kat; 10 yıldızın altında `nil`.
    static func current(score: Int) -> MPStarLevel? { all.last { score >= $0.threshold } }
}
