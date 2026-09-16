import SwiftUI

/// Sayfanın geçtiği yer.
///
/// Dekorasyonun neye benzeyeceğini bu belirler: orman sayfası dal ve mantar
/// alır, deniz sayfası yosun ve dalga. Adlar `DecorationCategory` ile bilerek
/// örtüşüyor — ikisi farklı şeyler (biri sayfanın, öbürü varlığın niteliği)
/// ama aynı sözlüğü paylaşmaları eşlemeyi gereksiz kılıyor.
enum StoryEnvironment: String, CaseIterable, Codable, Identifiable {
    case forest
    case garden
    case ocean
    case sky
    case space
    case magic
    case bedtime
    case adventure
    /// Hiçbir sinyal yoksa. Yanlış dekorasyon vermektense hiç tema vermemek.
    case neutral

    var id: String { rawValue }

    var label: String {
        switch self {
        case .forest:    return "Orman"
        case .garden:    return "Bahçe"
        case .ocean:     return "Deniz"
        case .sky:       return "Gökyüzü"
        case .space:     return "Uzay"
        case .magic:     return "Büyü"
        case .bedtime:   return "Uyku"
        case .adventure: return "Macera"
        case .neutral:   return "Nötr"
        }
    }
}

extension StoryEnvironment {

    /// İki kademeli çıkarım; ikincisi birincisine düşer.
    ///
    /// **1. Sayfanın kendi sahnesi.** `imagePrompt`, motorun `visualScene`'ini
    /// taşıyor ve bugüne kadar hiçbir yerde okunmuyordu. İngilizce sahne
    /// yönergesi olduğu için ekranda gösterilemez ama *sınıflandırılabilir* —
    /// ve sayfa başına doğru sinyal veren tek şey bu.
    ///
    /// **2. Masalın dünyası.** `MP.World`. Kasıtlı olarak ikincil:
    /// `OfflineStoryMapper.theme(for:)` deniz/orman/uzay dışındaki her ayarı
    /// `.custom`'a düşürüyor ve `.custom` → `dinozor` oluyor. Yani motorun
    /// ürettiği masalların çoğunda bu kademe içerikle ilgisiz. Birincil sinyal
    /// yapılsaydı orman masalı pençe izi alırdı.
    static func resolve(scene: String, world: MP.World) -> StoryEnvironment {
        fromScene(scene) ?? fromWorld(world)
    }

    /// Sahne metnindeki anahtar kelimeleri sayar, en çok eşleşeni döner.
    ///
    /// Beraberlikte `allCases` sırası karar verir, böylece aynı metin her
    /// zaman aynı ortamı verir — dekorasyonun belirleyici olması buna bağlı.
    static func fromScene(_ scene: String) -> StoryEnvironment? {
        let text = scene.lowercased()
        guard !text.isEmpty else { return nil }

        var best: (env: StoryEnvironment, score: Int)?
        for env in allCases where env != .neutral {
            let score = env.keywords.reduce(0) { $0 + (text.contains($1) ? 1 : 0) }
            if score > 0, score > (best?.score ?? 0) { best = (env, score) }
        }
        return best?.env
    }

    static func fromWorld(_ world: MP.World) -> StoryEnvironment {
        switch world {
        case .orman, .ciftlik: return .forest
        case .deniz:           return .ocean
        case .uzay:            return .space
        case .kar:             return .bedtime
        case .peri, .krallik:  return .magic
        case .kahraman, .korsan: return .adventure
        default:               return .neutral
        }
    }

    /// Sahne yönergelerinde geçen kelimeler. İngilizce, çünkü `visualScene`
    /// İngilizce yazılıyor.
    var keywords: [String] {
        switch self {
        case .forest:
            return ["forest", "tree", "leaf", "leaves", "branch", "wood", "moss", "grass"]
        case .garden:
            return ["garden", "flower", "orchard", "petal", "bloom", "meadow"]
        case .ocean:
            return ["sea", "ocean", "water", "wave", "shore", "river", "boat", "fish", "shell"]
        case .sky:
            return ["sky", "cloud", "wind", "bird", "above"]
        case .space:
            return ["star", "planet", "constellation", "comet", "orbit"]
        case .magic:
            return ["glow", "glimmer", "shimmer", "faint light", "sparkle", "magic"]
        case .bedtime:
            return ["night", "dark", "moon", "sleep", "dream", "shadow"]
        case .adventure:
            return ["path", "bridge", "mountain", "hill", "climb", "journey", "edge"]
        case .neutral:
            return []
        }
    }
}
