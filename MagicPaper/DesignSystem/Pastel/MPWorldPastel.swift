import SwiftUI

/// Masal dünyalarının Pastel Masal karşılığı: kart zemini (`tone.soft`),
/// simge rengi (`tone.deep`) ve Lucide simgesi. Değerler teslimdeki
/// 19 · Yarat 1 ve 11 · Ana sayfa ekranlarından.
extension MP.World {
    var tone: MPWorldTone {
        switch self {
        case .krallik:  return .pink
        case .uzay:     return .sky
        case .orman:    return .green
        case .kahraman: return .yellow
        case .deniz:    return .mint
        case .dinozor:  return .peach
        case .peri:     return .lav
        case .korsan:   return .sky
        case .kar:      return .gray
        case .ciftlik:  return .green
        case .robot:    return .gray
        case .sirk:     return .pink
        }
    }

    /// `MPIcon` adı: Lucide dosyası varsa o çizilir.
    var icon: String {
        switch self {
        case .krallik:  return "castle"
        case .uzay:     return "rocket"
        case .orman:    return "tree"
        case .kahraman: return "bolt"
        case .deniz:    return "fish"
        case .dinozor:  return "bone"
        case .peri:     return "sparkles"
        case .korsan:   return "sailboat"
        case .kar:      return "snowflake"
        case .ciftlik:  return "tractor"
        case .robot:    return "bot"
        case .sirk:     return "tent"
        }
    }
}
