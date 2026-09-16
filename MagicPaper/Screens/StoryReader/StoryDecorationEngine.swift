import SwiftUI

/// Sayfanın dekorasyonunu belirleyen girdiler.
struct StoryDecorationContext: Hashable {
    let environment: StoryEnvironment
    let mood: StoryMood?
    let timeOfDay: StoryTimeOfDay
    let density: DecorationDensity
    /// Tohum: aynı sayfa her açılışta aynı görünsün diye.
    let seed: UInt64
    /// Metnin kapladığı alan (normalize). Bu dikdörtgene hiçbir süs girmez.
    let textSafeRect: CGRect
    /// Çizimin kapladığı alan (normalize). Varsa yüzleri ve önemli detayı korur.
    let illustrationSafeRect: CGRect?

    static func make(story: ReaderStory, page: ReaderPage,
                     density: DecorationDensity,
                     textSafeRect: CGRect,
                     illustrationSafeRect: CGRect?) -> StoryDecorationContext {
        StoryDecorationContext(
            environment: StoryEnvironment.resolve(scene: page.sceneHint, world: story.world),
            mood: nil,                       // motor henüz taşımıyor
            timeOfDay: .day,
            density: density,
            seed: StoryDecorationContext.seed(storyID: story.id, page: page.index),
            textSafeRect: textSafeRect,
            illustrationSafeRect: illustrationSafeRect
        )
    }

    /// Masal kimliği + sayfa numarası.
    ///
    /// Rastgele tohum kullanılsaydı aynı masalı ikinci kez açan çocuk farklı
    /// bir sayfa görürdü ve kitap olmaktan çıkardı. Sayfa numarasının tohuma
    /// girmesi ise sayfadan sayfaya farklı kompozisyon verir — §18'in istediği
    /// "her sayfanın kendi kişiliği" elle tasarlamadan buradan çıkar.
    static func seed(storyID: UUID, page: Int) -> UInt64 {
        var h = UInt64(bitPattern: Int64(storyID.hashValue))
        h ^= UInt64(truncatingIfNeeded: page &+ 1) &* 0x9E37_79B9_7F4A_7C15
        return h == 0 ? 0x12345678 : h
    }
}

/// Tek bir yerleştirilmiş süs.
struct StoryDecorationPlacement: Identifiable, Hashable {
    let id: String
    let assetID: String
    let zone: DecorationZone
    /// Sayfa genişliğine oranla motifin genişliği.
    let scale: CGFloat
    let rotation: Angle
    let opacity: Double
    /// Bölge çapasından küçük kayma — kompozisyonu tekdüzelikten çıkarır.
    let jitter: CGSize
}

/// Bağlamdan sayfaya: hangi süsler, hangi bölgede, ne ölçekte.
///
/// Akış §13'teki sırayla: semantik süzme → skorlama → çeşitlilik → güvenli
/// bölge → yoğunluk → yerleştirme. Hiçbir adımda `Double.random` yok;
/// belirleyici üreteç tohumdan besleniyor.
struct StoryDecorationEngine {

    /// Son sayfalarda kullanılan varlıklar — aynı mantar her sayfada çıkmasın.
    var recentlyUsed: [String] = []

    func plan(_ ctx: StoryDecorationContext) -> [StoryDecorationPlacement] {
        var rng = SeededGenerator(seed: ctx.seed)

        let candidates = score(ctx)
        guard !candidates.isEmpty else { return [] }

        let zones = availableZones(ctx)
        guard !zones.isEmpty else { return [] }

        let budget = ctx.density.range
        let target = Int.random(in: budget, using: &rng)

        var placements: [StoryDecorationPlacement] = []
        var usedZones: Set<DecorationZone> = []
        var usedTypes: [DecorationType: Int] = [:]
        var weight = 0.0
        let weightCap = Double(budget.upperBound) * 0.62

        for (asset, _) in candidates {
            guard placements.count < target, weight < weightCap else { break }

            // Aynı türden ikiden fazlası sayfayı tekdüze yapar.
            if usedTypes[asset.type, default: 0] >= 2 { continue }

            let open = zones.filter { !usedZones.contains($0) }
            guard let zone = pick(asset: asset, from: open, rng: &rng) else { continue }

            placements.append(place(asset, in: zone, ctx: ctx, rng: &rng))
            usedZones.insert(zone)
            usedTypes[asset.type, default: 0] += 1
            weight += asset.visualWeight
        }
        return placements
    }

    // MARK: - Süzme ve skorlama

    /// Uygun varlıklar, skorlarına göre sıralı.
    private func score(_ ctx: StoryDecorationContext) -> [(StoryDecorationAsset, Double)] {
        StoryDecorationCatalog.all.compactMap { asset in
            var s = 0.0

            // Ortam eşleşmesi zorunlu benzeri: eşleşmiyorsa neredeyse hiç şansı yok.
            if asset.environments.contains(ctx.environment) { s += 10 }
            else if asset.environments.isEmpty { s += 2 }
            else { return nil }

            if let mood = ctx.mood, asset.moods.contains(mood) { s += 3 }
            if ctx.timeOfDay == .night && asset.category == .bedtime { s += 2 }

            // Yakın zamanda kullanıldıysa geriye düşer, ama tamamen elenmez:
            // az varlıklı bir kategoride eleme, sayfayı bomboş bırakırdı.
            if let idx = recentlyUsed.firstIndex(of: asset.id) {
                s -= Double(recentlyUsed.count - idx) * 1.5
            }
            return (asset, s)
        }
        .sorted { $0.1 > $1.1 }
    }

    // MARK: - Güvenli bölgeler

    /// Metnin ve çizimin üstüne düşen bölgeler elenir (§15).
    private func availableZones(_ ctx: StoryDecorationContext) -> [DecorationZone] {
        DecorationZone.allCases.filter { zone in
            let probe = CGRect(x: zone.anchor.x - 0.13, y: zone.anchor.y - 0.10,
                               width: 0.26, height: 0.20)
            if probe.intersects(ctx.textSafeRect) { return false }
            if let illo = ctx.illustrationSafeRect, probe.intersects(illo) { return false }
            return true
        }
    }

    private func pick(asset: StoryDecorationAsset,
                      from zones: [DecorationZone],
                      rng: inout SeededGenerator) -> DecorationZone? {
        let preferred = zones.filter { asset.preferredZones.contains($0) }
        let pool = preferred.isEmpty ? zones.filter { fallbackFits(asset, $0) } : preferred
        guard !pool.isEmpty else { return nil }
        return pool[Int.random(in: 0..<pool.count, using: &rng)]
    }

    /// Tercih edilen bölge kalmadıysa: tür hâlâ mantıklı mı?
    /// Zemine ait bir çim kümesi gökyüzüne konmaz.
    private func fallbackFits(_ asset: StoryDecorationAsset, _ zone: DecorationZone) -> Bool {
        switch asset.type {
        case .ground, .background: return zone.isBottom
        case .sky:                 return zone.isTop
        default:                   return true
        }
    }

    // MARK: - Yerleştirme

    private func place(_ asset: StoryDecorationAsset,
                       in zone: DecorationZone,
                       ctx: StoryDecorationContext,
                       rng: inout SeededGenerator) -> StoryDecorationPlacement {
        // Ölçek: ağır motifler büyük, hafifler küçük — §19'un görsel hiyerarşisi.
        let base = 0.16 + asset.visualWeight * 0.20
        let scale = base * CGFloat.random(in: 0.88...1.12, using: &rng)

        // Dönüş küçük ve türle sınırlı: zemine oturan bir şey eğik durmaz.
        let span: ClosedRange<Double>
        switch asset.type {
        case .ground, .background: span = -2.5...2.5
        case .corner, .edge:       span = -6...6
        default:                   span = -9...9
        }
        let rotation = Angle.degrees(Double.random(in: span, using: &rng))

        // Opaklık: arka plan soluk, ön plan net (§21).
        let opacity: Double
        switch asset.type {
        case .background:        opacity = Double.random(in: 0.22...0.34, using: &rng)
        case .accent, .particle: opacity = Double.random(in: 0.30...0.46, using: &rng)
        case .sky, .floating:    opacity = Double.random(in: 0.42...0.62, using: &rng)
        default:                 opacity = Double.random(in: 0.52...0.74, using: &rng)
        }

        let jitter = CGSize(width: CGFloat.random(in: -0.035...0.035, using: &rng),
                            height: CGFloat.random(in: -0.030...0.030, using: &rng))

        return StoryDecorationPlacement(
            id: "\(asset.id)-\(zone.rawValue)",
            assetID: asset.id, zone: zone,
            scale: scale, rotation: rotation, opacity: opacity, jitter: jitter
        )
    }
}

/// Tohumdan beslenen belirleyici üreteç.
///
/// `SystemRandomNumberGenerator` kullanılsaydı aynı sayfa her açılışta farklı
/// dizilirdi. SplitMix64 — küçük, hızlı, tekrarlanabilir.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
