import Foundation

/// Bir çocuğun art arda okuduğu masallarda tekrarın ölçüsü (A0, 20 Kasım 2026;
/// `docs/ANLATI_PLANI.md`).
///
/// Uygulamanın yaptığını taklit eder: her masalda motora son masalların
/// kökeni ve satırları (`historyWindow` kadar) ve son 12 başlık verilir;
/// bozuk taslakta yeni seed denenir. Ölçülen: olay örgüsünün ilk tekrarı,
/// satırlarının yarısı daha önce okunmuş ilk masal, pencerelere göre daha önce
/// okunmuş satır oranı, birebir aynı masal ve farklı kurgu sayısı.
///
/// Sayılar okuma *sırasına* aittir; havuzun kapasitesi değil, çocuğun
/// gerçekten hissedeceği tekrar.
public struct ReadingSequenceReport: Sendable, Hashable {
    public let band: AgeBand
    public let modes: [StoryMode]
    public let children: Int
    public let stories: Int
    /// Çocuk başına: aynı mod + olay örgüsünün ilk kez tekrar ettiği masal (1'den).
    /// Tekrar olmadıysa `stories + 1`.
    public let firstPlotRepeat: [Int]
    /// Çocuk başına: satırlarının yarısı daha önce okunmuş ilk masal.
    public let firstHalfFamiliar: [Int]
    /// Masal sırasına göre daha önce okunmuş satır oranı, çocukların ortalaması.
    public let familiarShare: [Double]
    public let exactDuplicates: Int
    /// Çocuk başına farklı kurgu (olay örgüsü + mekân + arkadaş + keşif), ortalama.
    public let distinctSetups: Double
    public let failures: Int

    /// `range` (0'dan) aralığındaki masalların ortalama tanıdık satır oranı.
    public func familiar(_ range: Range<Int>) -> Double {
        let slice = familiarShare[range.clamped(to: 0..<familiarShare.count)]
        return slice.isEmpty ? 0 : slice.reduce(0, +) / Double(slice.count)
    }

    public static func measure(
        catalog: ContentCatalog,
        band: AgeBand,
        modes: [StoryMode] = [.bedtime, .learning, .adventure],
        children: Int = 3,
        stories: Int = 100,
        historyWindow: Int = SelectionScoring.lineCooldownWindow,
        composer: OfflineStoryComposer = OfflineStoryComposer()
    ) -> ReadingSequenceReport {
        let byID = Dictionary(catalog.blueprints.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        var share = [Double](repeating: 0, count: stories)
        var repeats: [Int] = [], halves: [Int] = []
        var duplicates = 0, setups = 0, failures = 0
        for child in 0..<children {
            var history: [RecentContent] = []
            var titles: [String] = []
            var plots = Set<String>(), seenSetups = Set<String>(), prints = Set<String>()
            var lines = Set<ContentID>()
            var repeatAt = 0, halfAt = 0
            for index in 0..<stories {
                let mode = modes[index % modes.count]
                var story: ComposedStory?
                for attempt in 0..<3 {
                    let intent = OfflineStoryIntent(
                        childName: "Yeliz", seed: "seq-c\(child)-s\(index)-a\(attempt)",
                        mode: mode, ageBand: band, recent: history, recentTitles: Set(titles))
                    if let s = try? composer.compose(catalog: catalog, intent: intent), s.isClean {
                        story = s; break
                    }
                }
                guard let s = story else { failures += 1; continue }
                let plot = "\(mode.rawValue):" + (byID[s.blueprintID]?.mechanismKey ?? s.blueprintID.rawValue)
                if plots.contains(plot), repeatAt == 0 { repeatAt = index + 1 }
                plots.insert(plot)
                seenSetups.insert("\(s.blueprintID)|\(s.content.setting.id)|\(s.content.companion.id)|\(s.content.discovery.id)")
                if !prints.insert(s.fingerprint).inserted { duplicates += 1 }
                let used = s.pages.flatMap(\.variantIDs)
                let old = used.filter(lines.contains).count
                let part = used.isEmpty ? 0 : Double(old) / Double(used.count)
                share[index] += part
                if part >= 0.5, halfAt == 0 { halfAt = index + 1 }
                lines.formUnion(used)
                history.insert(RecentContent(
                    blueprintID: s.blueprintID, settingID: s.content.setting.id,
                    companionID: s.content.companion.id, discoveryID: s.content.discovery.id,
                    variantIDs: Set(used)), at: 0)
                history = Array(history.prefix(historyWindow))
                titles.insert(s.title, at: 0)
                titles = Array(titles.prefix(12))
            }
            repeats.append(repeatAt == 0 ? stories + 1 : repeatAt)
            halves.append(halfAt == 0 ? stories + 1 : halfAt)
            setups += seenSetups.count
        }
        return ReadingSequenceReport(
            band: band, modes: modes, children: children, stories: stories,
            firstPlotRepeat: repeats, firstHalfFamiliar: halves,
            familiarShare: share.map { $0 / Double(children) },
            exactDuplicates: duplicates,
            distinctSetups: Double(setups) / Double(children), failures: failures)
    }
}
