import SwiftUI

/// Dekorasyonun hangi dünyaya ait olduğu.
enum DecorationCategory: String, CaseIterable, Codable, Identifiable {
    case forest, garden, ocean, sky, magic, bedtime, adventure, space
    var id: String { rawValue }

    var label: String {
        switch self {
        case .forest:    return "Orman"
        case .garden:    return "Bahçe"
        case .ocean:     return "Deniz"
        case .sky:       return "Gökyüzü"
        case .magic:     return "Büyü"
        case .bedtime:   return "Uyku"
        case .adventure: return "Macera"
        case .space:     return "Uzay"
        }
    }
}

/// Dekorasyonun sayfadaki yapısal rolü (Motif)
enum MotifZone: String, CaseIterable, Codable, Identifiable {
    /// Büyük, sayfayı alttan çerçeveleyen kümeler (çimen, kayalar)
    case foregroundBottom
    /// Üst köşelerden uzanan dallar, sarmaşıklar
    case atmosphericTop
    /// Tek taraflı, büyük çevresel asimetri sağlayan küme
    case asymmetricalFrame
    /// Serbest süzülen çok hafif partiküller (baloncuk, yıldız)
    case backgroundParticles

    var id: String { rawValue }
    var label: String { rawValue }
}

/// Sayfanın bütünsel kompozisyon yapısı.
enum StorybookComposition: String, CaseIterable, Identifiable {
    /// Orman gibi yerlerde: Alt taraf çimen/mantar, üst köşe dal.
    case groundedForest
    /// Deniz gibi yerlerde: Yana doğru akan sualtı elementleri, yukarıda boşluk.
    case horizontalFlow
    /// Uyku/Gökyüzü: Alt taraf boş (yazıya ayrılmış), üst köşeler yıldız/bulut.
    case atmosphericVoid
    /// Macera: Asimetrik ve ağır bir köşe çerçevesi (kayalık/büyük ağaç).
    case asymmetricalAdventure
    
    var id: String { rawValue }
    
    /// Bu kompozisyonun gerektirdiği motif bölgeleri ve ağırlıkları.
    var requiredZones: [MotifZone] {
        switch self {
        case .groundedForest: return [.foregroundBottom, .atmosphericTop]
        case .horizontalFlow: return [.foregroundBottom, .backgroundParticles]
        case .atmosphericVoid: return [.atmosphericTop, .backgroundParticles]
        case .asymmetricalAdventure: return [.asymmetricalFrame, .atmosphericTop]
        }
    }
}

/// Sayfanın duygusu. Motor bugün bunu taşımıyor; §12 için ayrılmış alan.
enum StoryMood: String, CaseIterable, Codable, Identifiable {
    case calm, happy, magical, mysterious, adventurous, dreamy
    var id: String { rawValue }
}

/// Günün vakti. Motor bugün taşımıyor; gece/gündüz ayrımı için ayrıldı.
enum StoryTimeOfDay: String, CaseIterable, Codable {
    case day, evening, night
}

/// Sayfada kaç süs olacağı.
///
/// §14: varsayılan 4–7. Sessiz sayfa 2–4, büyülü sayfa 6–10. Boşluk kusur
/// değil; sayfa nefes almalı.
enum DecorationDensity: String, CaseIterable, Codable {
    case sparse, normal, rich

    var range: ClosedRange<Int> {
        switch self {
        case .sparse: return 2...4
        case .normal: return 4...7
        case .rich:   return 6...10
        }
    }

    /// Sayfanın kendi yoğunluğu — §18'in "her sayfanın kişiliği".
    ///
    /// Her sayfaya aynı yoğunluğu vermek kitabı tekdüze yapar. Burada üç kural
    /// var ve üçü de kompozisyon kararı:
    ///
    /// - **Açılış sayfası sakin.** Okumaya başlanan yer kalabalık olmamalı.
    /// - **Son sayfa sakin.** Masalın kapanışı nefes ister.
    /// - **Büyülü sayfa zengin.** Süslemenin hakkını vereceği tek yer.
    ///
    /// Aradaki sayfalar tohuma göre dönüşümlü: ardışık iki sayfa aynı
    /// yoğunlukta olmaz, böylece çevirdikçe ritim hissediliyor.
    static func forPage(index: Int, pageCount: Int,
                        environment: StoryEnvironment,
                        seed: UInt64) -> DecorationDensity {
        if index == 0 { return .sparse }
        if pageCount > 1 && index == pageCount - 1 { return .sparse }
        if environment == .magic { return .rich }
        return (index &+ Int(truncatingIfNeeded: seed)) % 2 == 0 ? .normal : .sparse
    }

    /// Yazı boyutu büyüdükçe seyrelir; metin her zaman kazanır (§39).
    func reduced(for size: DynamicTypeSize) -> DecorationDensity {
        guard size.isAccessibilitySize else { return self }
        switch self {
        case .rich:   return .normal
        case .normal: return .sparse
        case .sparse: return .sparse
        }
    }
}
