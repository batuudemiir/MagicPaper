import SwiftUI
import UIKit

/// Bir masal ailesinin illüstrasyon seti.
///
/// Referans uygulamaların görsel yoğunluğu masal başına üretilmiş resimden
/// değil, her ekranı dolduran küratörlü sanattan geliyor. Bu set o sanatın
/// tek kaynağı: bir kez üretilir, uygulamaya gömülür, masallara mod ya da
/// dünya üzerinden bağlanır. Uzaktan üretim yok — "önce düşük maliyet".
///
/// İçerik `art_kits.json`'da durur, kodda değil. Yeni bir set eklemek ya da
/// bir görseli değiştirmek Swift değişikliği gerektirmez.
///
/// Set bir `MP.World` değildir. Pilot set "gece", `StoryMode.bedtime`'a
/// bağlanır ve her dünyadaki uyku masalını kapsar; dünya enum'u kapak rengi
/// ve ikonu için kalır.
struct StoryArtKit: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    /// Bu seti alan niyetler (`StoryMode.rawValue`). Mod dünyadan önce gelir:
    /// ormandaki bir uyku masalı orman değil, gece gibi görünmeli.
    let modes: [String]
    /// Bu seti alan dünyalar (`MP.World.rawValue`).
    let worlds: [String]
    /// Görsel henüz gelmemişken çizilen, zaten onaylı süs varlıkları.
    let placeholderMotifs: [String]
    let slots: [Slot]

    struct Slot: Decodable, Equatable {
        let role: Role
        /// Varlık kataloğundaki ad (`ArtKit/...`).
        let asset: String
        /// Üretim oranı, `"3:4"` gibi. İllüstratör brifi için.
        let aspect: String
        /// Resmin sessiz bırakılması gereken bandı — kadraj kesirleri, sol üstten.
        let textSafe: Band?
        /// İllüstratöre ve AI varyasyonuna giden kısa tarif. Uygulama göstermez.
        let brief: String
    }

    enum Role: String, Decodable {
        case hero, cover, spot
    }

    struct Band: Decodable, Equatable {
        let x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat
    }

    func slots(_ role: Role) -> [Slot] { slots.filter { $0.role == role } }

    /// Bir rolün çizilecek sanatı. Varlık yoksa yer tutucu motiflere düşer,
    /// böylece görsel teslim edilmeden de ekran dolu ve dürüst kalır.
    ///
    /// `assetExists` testte değiştirilir; uygulamada varlık kataloğuna bakar.
    func art(for role: Role,
             assetExists: (String) -> Bool = StoryArtKit.bundleHasAsset) -> MPArt {
        if let slot = slots(role).first, assetExists(slot.asset) {
            return .image(slot.asset)
        }
        return .motifs(placeholderMotifs)
    }

    /// Teslim edilmemiş slotlar — illüstrasyon takibinin tek sorusu.
    func pendingSlots(assetExists: (String) -> Bool = StoryArtKit.bundleHasAsset) -> [Slot] {
        slots.filter { !assetExists($0.asset) }
    }

    static func bundleHasAsset(_ name: String) -> Bool {
        UIImage(named: name) != nil
    }
}

// MARK: - Katalog

struct StoryArtKitCatalog: Decodable {
    let schemaVersion: Int
    let kits: [StoryArtKit]

    /// Uygulamanın gömülü katalogu. Okunamazsa boş: sanat seti olmayan masal
    /// bugünkü kapağıyla görünür, sessizce yanlış bir sete düşmez.
    static let bundled: StoryArtKitCatalog = load(from: .main) ?? StoryArtKitCatalog(schemaVersion: 1, kits: [])

    static func load(from bundle: Bundle) -> StoryArtKitCatalog? {
        guard let url = bundle.url(forResource: "art_kits", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(StoryArtKitCatalog.self, from: data)
    }

    init(schemaVersion: Int, kits: [StoryArtKit]) {
        self.schemaVersion = schemaVersion
        self.kits = kits
    }

    /// Mod önce, dünya sonra. İkisi de eşleşmezse `nil`.
    func kit(modeID: String?, worldID: String?) -> StoryArtKit? {
        if let modeID, let kit = kits.first(where: { $0.modes.contains(modeID) }) { return kit }
        if let worldID, let kit = kits.first(where: { $0.worlds.contains(worldID) }) { return kit }
        return nil
    }
}

extension Story {
    /// Masalın sanat seti; masalın kaydedilmiş niyetinden ve dünyasından.
    var mpArtKit: StoryArtKit? { mpArtKit(in: .bundled) }

    func mpArtKit(in catalog: StoryArtKitCatalog) -> StoryArtKit? {
        catalog.kit(modeID: origin?.mode?.rawValue, worldID: origin?.worldID)
    }
}
