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

/// Dekorasyonun sayfadaki **rolü** — nereye, nasıl oturduğu.
///
/// Kategori "ne olduğunu", tür "nasıl davrandığını" söyler. İkisi ayrı çünkü
/// bir yaprak kümesi hem ormanda hem bahçede olabilir, ama her iki durumda da
/// aynı şekilde yerleşir: havada, serbest.
enum DecorationType: String, CaseIterable, Codable, Identifiable {
    /// Köşeden giren, sayfayı çerçeveleyen parça.
    case corner
    /// Yere oturan: çim, mantar, taş.
    case ground
    /// Kenardan giren: sarmaşık, deniz yosunu.
    case edge
    /// Havada duran: yaprak, kelebek, tüy.
    case floating
    /// Üstte duran: bulut, ay, kuşlar.
    case sky
    /// Küçük vurgu: dalga izi, küçük süs.
    case accent
    /// Arkada duran, soluk: tepe silueti.
    case background
    /// Parçacık — şimdilik onaylı varlığı yok.
    case particle

    var id: String { rawValue }

    var label: String {
        switch self {
        case .corner:     return "Köşe"
        case .ground:     return "Zemin"
        case .edge:       return "Kenar"
        case .floating:   return "Serbest"
        case .sky:        return "Gök"
        case .accent:     return "Vurgu"
        case .background: return "Arka"
        case .particle:   return "Parçacık"
        }
    }
}

/// Sayfadaki yerleşim bölgeleri.
///
/// Serbest koordinat yerine adlandırılmış bölge kullanılıyor: rastgele x/y
/// dağıtmak §13'ün "AI çöplüğü" dediği şeyi üretir. Bölge, bir motifin
/// *nereye ait olduğunu* söyler; içindeki küçük kayma kompozisyonu canlı tutar.
enum DecorationZone: String, CaseIterable, Codable, Identifiable {
    case topLeading, topCenter, topTrailing
    case leadingEdge, trailingEdge
    case bottomLeading, bottomCenter, bottomTrailing

    var id: String { rawValue }

    /// Bölgenin sayfadaki normalize çapası (0…1).
    var anchor: UnitPoint {
        switch self {
        // Üst bant kontrollerin altından başlar. Önce 0.07–0.10 denendi ve
        // süs kapat düğmesiyle aynı hizaya düştü: sayfaya ait bir motif,
        // arayüz öğesiyle çakışınca ikisi de yanlış okunuyor.
        case .topLeading:     return UnitPoint(x: 0.10, y: 0.17)
        case .topCenter:      return UnitPoint(x: 0.50, y: 0.14)
        case .topTrailing:    return UnitPoint(x: 0.89, y: 0.18)
        case .leadingEdge:    return UnitPoint(x: 0.05, y: 0.46)
        case .trailingEdge:   return UnitPoint(x: 0.95, y: 0.52)
        case .bottomLeading:  return UnitPoint(x: 0.13, y: 0.91)
        case .bottomCenter:   return UnitPoint(x: 0.50, y: 0.95)
        case .bottomTrailing: return UnitPoint(x: 0.87, y: 0.90)
        }
    }

    /// Motifin bölgeye göre hangi kenarından hizalanacağı.
    ///
    /// Kenar ve köşe parçaları sayfa dışına taşarak devam ediyormuş gibi
    /// durmalı (§16): çapa, motifin *dışına* düşer.
    var bleed: CGSize {
        switch self {
        case .topLeading:     return CGSize(width: -0.22, height: -0.28)
        case .topCenter:      return CGSize(width:  0.00, height: -0.34)
        case .topTrailing:    return CGSize(width:  0.22, height: -0.28)
        case .leadingEdge:    return CGSize(width: -0.34, height:  0.00)
        case .trailingEdge:   return CGSize(width:  0.34, height:  0.00)
        case .bottomLeading:  return CGSize(width: -0.18, height:  0.26)
        case .bottomCenter:   return CGSize(width:  0.00, height:  0.30)
        case .bottomTrailing: return CGSize(width:  0.18, height:  0.26)
        }
    }

    var isTop: Bool { self == .topLeading || self == .topCenter || self == .topTrailing }
    var isBottom: Bool { self == .bottomLeading || self == .bottomCenter || self == .bottomTrailing }
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
