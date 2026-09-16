import SwiftUI

// MARK: - Renk yardımcısı

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Tema

/// MagicPaper tasarım sistemi token'ları.
/// Kaynak: tokens/*.css — değerler birebir aktarılmıştır.
enum MP {

    // MARK: Temel palet

    enum Palette {
        // Gül — birincil marka
        static let gul50  = Color(hex: 0xFDF0F4)
        static let gul100 = Color(hex: 0xF9D9E3)
        static let gul200 = Color(hex: 0xF0AEC3)
        static let gul300 = Color(hex: 0xE37E9E)
        static let gul400 = Color(hex: 0xD25C81)
        static let gul500 = Color(hex: 0xC1436B)
        static let gul600 = Color(hex: 0xA8355A)
        static let gul700 = Color(hex: 0x872844)
        static let gul800 = Color(hex: 0x5E1B2F)
        static let gul900 = Color(hex: 0x3B111E)

        // Hardal — sıcaklık, ödül
        static let hardal50  = Color(hex: 0xFDF6E7)
        static let hardal100 = Color(hex: 0xF9E8BF)
        static let hardal200 = Color(hex: 0xF2D183)
        static let hardal300 = Color(hex: 0xEABA4C)
        static let hardal400 = Color(hex: 0xE0A32E)
        static let hardal500 = Color(hex: 0xC98A1C)
        static let hardal600 = Color(hex: 0xA46E12)
        static let hardal700 = Color(hex: 0x754E0C)

        // Mercan — enerji, uyarı
        static let mercan50  = Color(hex: 0xFDF1EC)
        static let mercan100 = Color(hex: 0xF9DACE)
        static let mercan200 = Color(hex: 0xF2B49B)
        static let mercan300 = Color(hex: 0xEC8D69)
        static let mercan400 = Color(hex: 0xE4572E)
        static let mercan500 = Color(hex: 0xC74522)
        static let mercan600 = Color(hex: 0x9E3319)
        static let mercan700 = Color(hex: 0x6E2211)

        // Yeşim — sakinlik, başarı
        static let yesim50  = Color(hex: 0xEAF4F1)
        static let yesim100 = Color(hex: 0xC9E4DC)
        static let yesim200 = Color(hex: 0x94CBBC)
        static let yesim300 = Color(hex: 0x5CAF9B)
        static let yesim400 = Color(hex: 0x2E7D6B)
        static let yesim500 = Color(hex: 0x26685A)
        static let yesim600 = Color(hex: 0x1D5147)
        static let yesim700 = Color(hex: 0x133731)

        // Gece — okuma modu, derinlik
        static let gece100 = Color(hex: 0xD4DCEA)
        static let gece200 = Color(hex: 0x9BAAC6)
        static let gece300 = Color(hex: 0x5D719A)
        static let gece400 = Color(hex: 0x3A4E76)
        static let gece500 = Color(hex: 0x26385C)
        static let gece600 = Color(hex: 0x1B2A4A)
        static let gece700 = Color(hex: 0x121D34)
        static let gece800 = Color(hex: 0x0B1322)

        // Mürekkep — tüm metin
        static let murekkep900 = Color(hex: 0x2B1D24)
        static let murekkep700 = Color(hex: 0x4A3640)
        static let murekkep500 = Color(hex: 0x6E5964)
        static let murekkep300 = Color(hex: 0x9B8892)

        // Kağıt — nötrler (sistemde soğuk gri yoktur)
        static let kagit0   = Color(hex: 0xFFFFFF)
        static let kagit50  = Color(hex: 0xFFFBF6)
        static let kagit100 = Color(hex: 0xFDF6EE)
        static let kagit200 = Color(hex: 0xF7EDE1)
        static let kagit300 = Color(hex: 0xEEDFCF)
        static let kagit400 = Color(hex: 0xDFCBB6)
        static let kagit500 = Color(hex: 0xC3AB93)
    }

    // MARK: Semantik renkler — bileşenlerde YALNIZCA bunları kullan

    enum C {
        static let brand      = Palette.gul500
        static let brandHover = Palette.gul400
        static let brandPress = Palette.gul600
        static let brandEdge  = Palette.gul700
        static let brandSoft  = Palette.gul50
        static let textOnBrand = Palette.kagit0

        static let reward     = Palette.hardal400
        static let rewardEdge = Palette.hardal600
        static let rewardSoft = Palette.hardal50
        static let premiumInk = Palette.hardal700

        static let play     = Palette.mercan400
        static let playEdge = Palette.mercan600
        static let playSoft = Palette.mercan50

        static let calm     = Palette.yesim400
        static let calmEdge = Palette.yesim600
        static let calmSoft = Palette.yesim50

        static let textTitle = Palette.murekkep900
        static let textBody  = Palette.murekkep700
        static let textMuted = Palette.murekkep500
        static let textFaint = Palette.murekkep300
        static let textLink  = Palette.gul600

        static let surfaceApp     = Palette.kagit100
        static let surfaceCard    = Palette.kagit0
        static let surfaceSunken  = Palette.kagit200
        static let surfaceRaised  = Palette.kagit50
        static let surfaceInverse = Palette.gece600

        static let borderHairline = Palette.kagit300
        static let borderStrong   = Palette.kagit400
        static let edgeCard       = Palette.kagit400
        static let edgeInverse    = Palette.gece800

        static let success = Palette.yesim400
        static let warning = Palette.hardal400
        static let danger  = Palette.mercan500

        static let focusRing = Palette.gul300
        static let scrim     = Color(hex: 0x2B1D24, alpha: 0.44)
    }

    // MARK: Okuma temaları — uygulamadaki tek tema anahtarı

    enum ReadTheme: String, CaseIterable, Identifiable {
        case light, sepia, night
        public var id: String { rawValue }

        var label: String {
            switch self {
            case .light: return "Gündüz"
            case .sepia: return "Sepya"
            case .night: return "Gece"
            }
        }
        var background: Color {
            switch self {
            case .light: return Palette.kagit0
            case .sepia: return Color(hex: 0xF7EFDE)
            case .night: return Palette.gece700
            }
        }
        var foreground: Color {
            switch self {
            case .light: return Palette.murekkep900
            case .sepia: return Color(hex: 0x3B2A18)
            case .night: return Color(hex: 0xE4E9F2)
            }
        }
        var body: Color {
            switch self {
            case .light: return Palette.murekkep700
            case .sepia: return Color(hex: 0x503A22)
            case .night: return Color(hex: 0xC6CFDD)
            }
        }
        var muted: Color {
            switch self {
            case .light: return Palette.murekkep500
            case .sepia: return Color(hex: 0x7A6248)
            case .night: return Palette.gece200
            }
        }

        /// Kitap sayfasının kendi yüzeyi.
        ///
        /// `background` ile aynı değil ve olmamalı: `background` gündüz modunda
        /// saf beyazdır (`kagit0`), beyaz ise kağıt değildir. Okuyucu bunu
        /// kullanır, `MPStoryPDF`'in bastığı kağıt rengiyle aynı tonu
        /// (`kagit100`) tutar. Ayrı bir property olmasının sebebi
        /// `DailyStoryReaderView`'ın `background`'ı okumaya devam etmesi.
        var paper: Color {
            switch self {
            case .light: return Palette.kagit100
            case .sepia: return Color(hex: 0xF7EFDE)
            case .night: return Palette.gece700
            }
        }

        /// Cilt payı — sayfanın iç kenarındaki ince gölge.
        /// Sistemdeki derinlik `mpEdge`'tir; bu onun kitaba özgü karşılığı.
        var spine: Color {
            switch self {
            case .light: return Color(hex: 0xC3AB93, alpha: 0.22)
            case .sepia: return Color(hex: 0xB49A78, alpha: 0.22)
            case .night: return Color(hex: 0x0B1322, alpha: 0.38)
            }
        }
    }

    // MARK: Masal dünyası aksanları

    enum World: String, CaseIterable, Identifiable {
        case krallik, uzay, orman, kahraman, deniz, dinozor
        case peri, korsan, kar, ciftlik, robot, sirk

        public var id: String { rawValue }

        var name: String {
            switch self {
            case .krallik:  return "Sihirli Krallık"
            case .uzay:     return "Uzay Macerası"
            case .orman:    return "Orman Macerası"
            case .kahraman: return "Süper Kahraman"
            case .deniz:    return "Deniz Altı"
            case .dinozor:  return "Dinozorlar"
            case .peri:     return "Peri Masalı"
            case .korsan:   return "Korsanlar"
            case .kar:      return "Kar Diyarı"
            case .ciftlik:  return "Çiftlik"
            case .robot:    return "Robotlar"
            case .sirk:     return "Sirk"
            }
        }
        /// SF Symbol karşılıkları — 05-SWIFTUI-MAPPING.md ile aynı liste.
        var symbol: String {
            switch self {
            case .krallik:  return "building.columns"
            case .uzay:     return "airplane.departure"
            case .orman:    return "tree"
            case .kahraman: return "bolt.fill"
            case .deniz:    return "fish"
            case .dinozor:  return "pawprint"
            case .peri:     return "sparkles"
            case .korsan:   return "sailboat"
            case .kar:      return "snowflake"
            case .ciftlik:  return "leaf"
            case .robot:    return "cpu"
            case .sirk:     return "tent"
            }
        }
        var accent: Color {
            switch self {
            case .krallik:  return Color(hex: 0xD25C81)
            case .uzay:     return Color(hex: 0x3A4E76)
            case .orman:    return Color(hex: 0x2E7D6B)
            case .kahraman: return Color(hex: 0xE0A32E)
            case .deniz:    return Color(hex: 0x2A7A94)
            case .dinozor:  return Color(hex: 0x7A6A3A)
            case .peri:     return Color(hex: 0xB265A8)
            case .korsan:   return Color(hex: 0x8A5A32)
            case .kar:      return Color(hex: 0x6E93B8)
            case .ciftlik:  return Color(hex: 0x8AA23C)
            case .robot:    return Color(hex: 0x5C6B7A)
            case .sirk:     return Color(hex: 0xE4572E)
            }
        }
        var isPremium: Bool {
            switch self {
            case .peri, .korsan, .kar, .ciftlik, .robot, .sirk: return true
            default: return false
            }
        }
    }

    // MARK: Tipografi

    enum F {
        static let display = "Baloo 2"
        static let body    = "Nunito"

        // Display — Baloo 2, weight 700, tracking -0.01em
        static func displayXL() -> Font { .custom(display, size: 40).weight(.bold) }
        static func displayLG() -> Font { .custom(display, size: 32).weight(.bold) }
        static func displayMD() -> Font { .custom(display, size: 26).weight(.bold) }
        static func displaySM() -> Font { .custom(display, size: 21).weight(.bold) }
        /// StatCard / PlanCard fiyatı gibi ağır (800) display kullanımları
        static func displayHeavy(_ size: CGFloat) -> Font { .custom(display, size: size).weight(.heavy) }

        // Body — Nunito
        static func bodyLG(_ w: Font.Weight = .regular) -> Font { .custom(body, size: 18).weight(w) }
        static func bodyMD(_ w: Font.Weight = .regular) -> Font { .custom(body, size: 16).weight(w) }
        static func bodySM(_ w: Font.Weight = .regular) -> Font { .custom(body, size: 14).weight(w) }
        static func labelMD(_ w: Font.Weight = .bold) -> Font { .custom(body, size: 15).weight(w) }
        static func labelSM(_ w: Font.Weight = .bold) -> Font { .custom(body, size: 13).weight(w) }
        static func caption(_ w: Font.Weight = .bold) -> Font { .custom(body, size: 12).weight(w) }

        /// Masal metni. Satır yüksekliği 1.72 → lineSpacing = size * 0.72
        static func read(_ size: CGFloat) -> Font { .custom(body, size: size).weight(.semibold) }
    }

    /// Display metinlerde tracking -0.01em karşılığı.
    static func tightTracking(_ size: CGFloat) -> CGFloat { -0.01 * size }

    /// Okuma boyutu ayarı
    enum ReadSize: String, CaseIterable, Identifiable {
        case kucuk = "Küçük", normal = "Normal", buyuk = "Büyük", cokBuyuk = "Çok büyük"
        public var id: String { rawValue }
        var points: CGFloat {
            switch self {
            case .kucuk: return 17
            case .normal: return 19
            case .buyuk: return 22
            case .cokBuyuk: return 26
            }
        }
        /// line-height 1.72
        var lineSpacing: CGFloat { points * 0.72 }
    }

    // MARK: Boşluk

    enum S {
        static let x1: CGFloat = 4
        static let x2: CGFloat = 8
        static let x3: CGFloat = 12
        static let x4: CGFloat = 16
        static let x5: CGFloat = 20
        static let x6: CGFloat = 24
        static let x7: CGFloat = 32
        static let x8: CGFloat = 40
        static let x9: CGFloat = 48
        static let x10: CGFloat = 64

        static let screenGutter: CGFloat = 20
        static let sectionGap: CGFloat = 28
        static let stackGap: CGFloat = 12
        static let tapMin: CGFloat = 48
        static let tabBarHeight: CGFloat = 76
        static let navBarHeight: CGFloat = 56
    }

    // MARK: Köşe yarıçapı

    enum R {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 22
        static let xl: CGFloat = 28
        static let xxl: CGFloat = 34
        static let pill: CGFloat = 999

        static let card: CGFloat = 22
        static let button: CGFloat = 20
        static let tile: CGFloat = 22
        static let sheet: CGFloat = 32
        static let input: CGFloat = 16
    }

    // MARK: Derinlik — sert alt kenar, bulanıklık değil

    enum E {
        static let width: CGFloat = 3
        static let widthLG: CGFloat = 4
    }

    // MARK: Hareket

    enum M {
        static let easeOut = Animation.timingCurve(0.2, 0.8, 0.3, 1, duration: 0.18)
        static let press   = Animation.timingCurve(0.2, 0.8, 0.3, 1, duration: 0.11)
        static let base    = Animation.timingCurve(0.2, 0.8, 0.3, 1, duration: 0.26)
        static let slow    = Animation.timingCurve(0.2, 0.8, 0.3, 1, duration: 0.42)
        static let page    = Animation.timingCurve(0.2, 0.8, 0.3, 1, duration: 0.52)
        static let spring  = Animation.spring(response: 0.32, dampingFraction: 0.62)

        static let sink: CGFloat = 2
        static let scale: CGFloat = 0.985
    }

    // MARK: Gölgeler

    struct ShadowSpec {
        let color: Color, radius: CGFloat, x: CGFloat, y: CGFloat
    }

    enum Sh {
        static let soft    = ShadowSpec(color: Color(hex: 0x2B1D24, alpha: 0.05), radius: 3,  x: 0, y: 2)
        static let card    = ShadowSpec(color: Color(hex: 0x2B1D24, alpha: 0.06), radius: 7,  x: 0, y: 4)
        static let lifted  = ShadowSpec(color: Color(hex: 0x2B1D24, alpha: 0.10), radius: 13, x: 0, y: 10)
        static let sheet   = ShadowSpec(color: Color(hex: 0x2B1D24, alpha: 0.16), radius: 17, x: 0, y: -8)
        static let brand   = ShadowSpec(color: Color(hex: 0xC1436B, alpha: 0.22), radius: 9,  x: 0, y: 6)
    }
}

// MARK: - Sistemin imzası: sert alt kenar

extension View {
    /// CSS'teki `border-bottom: Npx solid <edge>` karşılığı.
    /// Derinlik bu modifier'dan gelir — gölge ile taklit edilmemeli.
    func mpEdge(fill: Color, edge: Color, radius: CGFloat, width: CGFloat = MP.E.width) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(edge)
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(fill)
                        .padding(.bottom, width)
                )
        )
    }

    func mpShadow(_ s: MP.ShadowSpec) -> some View {
        self.shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
    }

    /// Display metinlerin varsayılan sıkı harf aralığı.
    func mpTightTracking(_ size: CGFloat) -> some View {
        self.tracking(MP.tightTracking(size))
    }
}

// MARK: - Basma davranışı (tüm sistemde aynı)

/// Öğe kendi alt kenarının üzerine çöker: 2px aşağı, 0.985 ölçek, %95 parlaklık.
struct MPPressStyle: ButtonStyle {
    var scales: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let held = configuration.isPressed && !reduceMotion
        return configuration.label
            .offset(y: held ? MP.M.sink : 0)
            .scaleEffect(held && scales ? MP.M.scale : 1)
            .brightness(held && scales ? -0.02 : 0)
            .animation(MP.M.press, value: configuration.isPressed)
    }
}
