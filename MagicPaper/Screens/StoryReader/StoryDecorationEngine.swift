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
    ///
    /// Kimlik, UUID'nin 16 baytı üzerinde FNV-1a ile özetlenir. `hashValue`
    /// süreç başına tohumlandığı için her açılışta başka bir sayı verirdi;
    /// sabit aritmetik açılıştan açılışa, cihazdan cihaza aynı sonucu verir.
    static func seed(storyID: UUID, page: Int) -> UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        withUnsafeBytes(of: storyID.uuid) { bytes in
            for byte in bytes {
                h ^= UInt64(byte)
                h = h &* 0x0000_0100_0000_01b3
            }
        }
        h ^= UInt64(truncatingIfNeeded: page &+ 1) &* 0x9E37_79B9_7F4A_7C15
        return h == 0 ? 0x12345678 : h
    }
}

struct StoryDecorationPlacement: Identifiable, Hashable {
    let id: String
    let assetID: String
    let zone: MotifZone
    let scale: CGFloat
    let rotation: Angle
    let opacity: Double
    let alignment: Alignment
    let offset: CGSize

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: StoryDecorationPlacement, rhs: StoryDecorationPlacement) -> Bool {
        lhs.id == rhs.id
    }
}

struct StoryDecorationEngine {
    func plan(_ ctx: StoryDecorationContext) -> [StoryDecorationPlacement] {
        var rng = SeededGenerator(seed: ctx.seed)
        
        let composition = selectComposition(for: ctx.environment, rng: &rng)
        var placements: [StoryDecorationPlacement] = []
        
        for zone in composition.requiredZones {
            if let asset = pickAsset(for: zone, ctx: ctx, rng: &rng) {
                placements.append(place(asset, in: zone, rng: &rng))
            }
        }
        
        return placements
    }
    
    private func selectComposition(for env: StoryEnvironment, rng: inout SeededGenerator) -> StorybookComposition {
        switch env {
        case .forest, .garden, .magic: return .groundedForest
        case .ocean: return .horizontalFlow
        case .sky, .space, .bedtime: return .atmosphericVoid
        case .adventure, .neutral: return .asymmetricalAdventure
        }
    }
    
    private func pickAsset(for zone: MotifZone, ctx: StoryDecorationContext, rng: inout SeededGenerator) -> StoryDecorationAsset? {
        let candidates = StoryDecorationCatalog.all.filter {
            $0.motifZone == zone &&
            ($0.environments.contains(ctx.environment) || $0.environments.isEmpty)
        }
        guard !candidates.isEmpty else { return nil }
        return candidates.randomElement(using: &rng)
    }
    
    private func place(_ asset: StoryDecorationAsset, in zone: MotifZone, rng: inout SeededGenerator) -> StoryDecorationPlacement {
        let scale = 0.8 + CGFloat.random(in: 0...0.4, using: &rng)
        
        let alignment: Alignment
        var offset = CGSize.zero
        var rotation = Angle.zero
        let opacity = 0.85
        
        switch zone {
        case .foregroundBottom:
            alignment = .bottom
            offset = CGSize(width: 0, height: 20)
        case .atmosphericTop:
            let isLeft = Bool.random(using: &rng)
            alignment = isLeft ? .topLeading : .topTrailing
            offset = CGSize(width: isLeft ? -20 : 20, height: -20)
            rotation = .degrees(Double.random(in: -10...10, using: &rng))
        case .asymmetricalFrame:
            alignment = .bottomLeading
            offset = CGSize(width: -30, height: 20)
        case .backgroundParticles:
            alignment = .center
            offset = CGSize(width: CGFloat.random(in: -100...100, using: &rng),
                            height: CGFloat.random(in: -200...0, using: &rng))
        }
        
        return StoryDecorationPlacement(
            id: "\(asset.id)-\(zone.rawValue)",
            assetID: asset.id,
            zone: zone,
            scale: scale,
            rotation: rotation,
            opacity: opacity,
            alignment: alignment,
            offset: offset
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
