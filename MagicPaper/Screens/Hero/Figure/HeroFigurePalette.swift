import SwiftUI

/// Tam boy kahraman çiziminin boya paleti (`kahraman.js`'in renkleri, olduğu gibi).
///
/// Bu bir arayüz rengi değil, illüstrasyonun kendi boyası: kapak sanatının
/// paleti (`MagicPaperCoverColor`) gibi tasarım yasasının "renk yalnızca
/// `MP.Palette`" kuralının dışında, tek dosyada. Katalog renkleri (ten, göz,
/// saç) `hero_figure_catalog.json`'dan gelir.
struct HeroRGB: Equatable, Hashable {
    let r: Double
    let g: Double
    let b: Double

    init(_ hex: UInt32) {
        r = Double((hex >> 16) & 0xFF)
        g = Double((hex >> 8) & 0xFF)
        b = Double(hex & 0xFF)
    }

    init(r: Double, g: Double, b: Double) {
        self.r = r; self.g = g; self.b = b
    }

    /// "#F8DBCA"
    init?(string: String) {
        let text = string.hasPrefix("#") ? String(string.dropFirst()) : string
        guard text.count == 6, let value = UInt32(text, radix: 16) else { return nil }
        self.init(value)
    }

    /// `tint(color, target, weight)`: kanal kanal karışım, yuvarlanmış (JS ile aynı).
    func tint(_ target: HeroRGB, _ weight: Double) -> HeroRGB {
        HeroRGB(r: (r * (1 - weight) + target.r * weight).rounded(),
                g: (g * (1 - weight) + target.g * weight).rounded(),
                b: (b * (1 - weight) + target.b * weight).rounded())
    }

    var color: Color { Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: 1) }
}

enum HeroInk {
    // Gölge, dudak, kaş, yanak ve saç boyası hedefleri
    static let shadeTarget = HeroRGB(0x713F32)
    static let lipTarget = HeroRGB(0x722D36)
    static let browTarget = HeroRGB(0x442D31)
    static let skinLight = HeroRGB(0xFFF1D4)
    static let blush = HeroRGB(0xD66D72)
    static let dyeDeep = HeroRGB(0x221A23)
    static let dyeDark = HeroRGB(0x30202A)
    static let dyeLight = HeroRGB(0xEFE2CE)
    static let dyeBright = HeroRGB(0xFFF6DA)

    // Göz
    static let eyeWhite = HeroRGB(0xFFF7E9)
    static let pupil = HeroRGB(0x332931)
    static let eyeShine = HeroRGB(0xFFF9ED)
    static let teeth = HeroRGB(0xFFF6E9)

    // Çizilen giysiler
    static let foldInk = HeroRGB(0x513850)
    static let stripe = HeroRGB(0x679097)
    static let hood = HeroRGB(0x796294)
    static let pocket = HeroRGB(0x766092)
    static let placket = HeroRGB(0x473349)
    static let button = HeroRGB(0xF8E8BB)
    static let cuff = HeroRGB(0xF9EAC8)
    static let star = HeroRGB(0xEBC469)
    static let collar = HeroRGB(0xFAD4BD)
    static let hem = HeroRGB(0xEEAD8D)
    static let pleat = HeroRGB(0x4B3B54)
    static let seam = HeroRGB(0xF6E8DC)
    static let tops: [HeroRGB] = [HeroRGB(0xEFE2BC), HeroRGB(0x997BBD), HeroRGB(0xE6B650),
                                  HeroRGB(0x76A893), HeroRGB(0x574D83), HeroRGB(0xCF7E70)]
    static let bottoms: [HeroRGB] = [HeroRGB(0x967DA7), HeroRGB(0x779D91), HeroRGB(0x6A879D), HeroRGB(0xCA9C75)]

    // Aksesuar
    static let glasses: [HeroRGB] = [HeroRGB(0x775481), HeroRGB(0x447E82), HeroRGB(0xB88142),
                                     HeroRGB(0xAA5062), HeroRGB(0x34485E), HeroRGB(0x698268)]
    static let bags: [HeroRGB] = [HeroRGB(0xC59960), HeroRGB(0x819761), HeroRGB(0xC77179), HeroRGB(0x7394A0)]
    static let strap = HeroRGB(0x634F45)
    static let bagLight = HeroRGB(0xFFF2CD)
    static let clasp = HeroRGB(0xF4D68E)
    static let scarves: [HeroRGB] = [HeroRGB(0xA78AC0), HeroRGB(0xC1838E), HeroRGB(0x879D88), HeroRGB(0xDCC7AA)]
    static let scarfFold = HeroRGB(0x60495D)
    static let spaceSleeve = HeroRGB(0x51647F)
}
