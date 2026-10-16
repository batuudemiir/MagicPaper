import SwiftUI

// MARK: - Renk yardımcısı

/// Paletin kurucusu. Ham `hex` değerleri YALNIZCA `MP.Palette` içinde
/// yazılır; bileşenler `MP.C` / `MP.Palette` token'larını kullanır.
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
///
/// **Bu dosya token'ların tek kaynağıdır.** Daha önce buradaki yorum bir
/// `tokens/*.css` kümesine işaret ediyordu; öyle bir klasör depoda yok ve
/// hiç olmadı. Renk, tipografi, boşluk, yarıçap, gölge ve hareket
/// değerleri artık yalnızca burada tanımlanır — dışarıda bir kopya veya
/// üretim adımı yoktur.
///
/// Değer eklerken: önce `Palette`'e ham rengi, sonra `C`'ye anlamını yaz.
/// Bileşenler `Palette`'i değil `C`'yi okur; `Palette`'i doğrudan okuyan
/// tek yer marka dışı aksanlardır (`World`, `ReadTheme`, `C.avatarAccents`,
/// `C.avatarParts`).
enum MP {

    // MARK: Temel palet

    enum Palette {
        // Mor — eylem rengi (karar: 3 Ekim 2026). 500, 600 ve 900 İrem'in
        // canvas'ından; 400, 50 ve 100 türetildi ve onaylandı. Kontrastlar
        // `docs/MagicPaper_Design_System.md`'de. Degrade yok.
        static let mor50      = Color(hex: 0xF2EDFA)
        static let mor100     = Color(hex: 0xDCD0F1)
        static let mor400     = Color(hex: 0x7653C2)
        static let mor500     = Color(hex: 0x6A47B8)
        static let mor600     = Color(hex: 0x5C3A8F)
        static let mor900     = Color(hex: 0x3A2458)
        /// Kâğıtta 3.74:1 — metin ve ikon için yetersiz. Yalnızca
        /// `C.focusRing` ve `C.brandTrack` okur.
        static let morLavanta = Color(hex: 0x8F6BD6)

        // Gül — eski birincil marka; artık dünya ve avatar aksanı
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
        // 25 ve 50, gece temasının metin mürekkepleridir: zemin koyu olduğu
        // için ramp burada ters çalışır, en açık ton en okunur olandır.
        static let gece25  = Color(hex: 0xE4E9F2)
        static let gece50  = Color(hex: 0xC6CFDD)
        static let gece100 = Color(hex: 0xD4DCEA)
        static let gece200 = Color(hex: 0x9BAAC6)
        static let gece300 = Color(hex: 0x5D719A)
        static let gece400 = Color(hex: 0x3A4E76)
        static let gece500 = Color(hex: 0x26385C)
        static let gece600 = Color(hex: 0x1B2A4A)
        static let gece700 = Color(hex: 0x121D34)
        static let gece800 = Color(hex: 0x0B1322)

        // Mürekkep — tüm metin
        static let murekkep900 = Color(hex: 0x2E1E3E)
        static let murekkep700 = Color(hex: 0x4A3640)
        static let murekkep500 = Color(hex: 0x6E5964)
        static let murekkep300 = Color(hex: 0x9B8892)

        // Kağıt — nötrler (sistemde soğuk gri yoktur)
        static let kagit0   = Color(hex: 0xFFFFFF)
        static let kagit50  = Color(hex: 0xFFFBF6)
        static let kagit100 = Color(hex: 0xFFF8EE)
        static let kagit200 = Color(hex: 0xF7EDE1)
        static let kagit300 = Color(hex: 0xEEDFCF)
        static let kagit400 = Color(hex: 0xDFCBB6)
        static let kagit500 = Color(hex: 0xC3AB93)

        // Sepya — yalnızca okuma temasının kağıdı ve mürekkebi.
        // Kağıt ailesinden ayrı durur: `kagit` arayüzün zeminidir, `sepya`
        // kitabın kendi kağıdıdır ve arayüzde kullanılmaz.
        static let sepya50  = Color(hex: 0xF7EFDE)
        static let sepya300 = Color(hex: 0xB49A78)
        static let sepya500 = Color(hex: 0x7A6248)
        static let sepya700 = Color(hex: 0x503A22)
        static let sepya900 = Color(hex: 0x3B2A18)

        // Dünya aksanları — gül/hardal/mercan/yeşim/gece'nin karşılamadığı
        // masal dünyaları. Tüketicileri: `MP.World.accent` ve ondan türeyen
        // kategori eşlemeleri. Marka rengi değillerdir, arayüzde tek
        // başlarına kullanılmazlar.
        static let deniz400 = Color(hex: 0x2A7A94)
        static let fosil400 = Color(hex: 0x7A6A3A)
        static let lila400  = Color(hex: 0xB265A8)
        static let kahve400 = Color(hex: 0x8A5A32)
        static let buz400   = Color(hex: 0x6E93B8)
        static let cimen400 = Color(hex: 0x8AA23C)
        static let metal400 = Color(hex: 0x5C6B7A)

        // Kitap karakteri (B2) — ten ve saç. Sıcak, boyanmış tonlar; arayüz
        // rengi değildir. Tek tüketicisi `C.avatarParts`. Yer tutucu değerler:
        // nihai liste Zehra'nın kararı (docs/B2_SCENE_LIBRARY_PLAN.md §9).
        static let tenAcik   = Color(hex: 0xF3D2B8)
        static let tenBugday = Color(hex: 0xD9A77C)
        static let tenEsmer  = Color(hex: 0xA86B45)
        static let tenKoyu   = Color(hex: 0x6B4029)
        static let sacSiyah  = Color(hex: 0x2E2426)
        static let sacKahve  = Color(hex: 0x5E3B26)
        static let sacKumral = Color(hex: 0x8A4B2A)
        static let sacSari   = Color(hex: 0xD9B26A)
        static let sacKizil  = Color(hex: 0xB5502E)
    }

    // MARK: Semantik renkler — bileşenlerde YALNIZCA bunları kullan

    /// Geçiş köprüsü (FAZ 17): semantik adlar Pastel Masal asset'lerine
    /// (`MPColor`) yönlenir. Taşınan ekranlar doğrudan `MPColor` okur.
    enum C {
        static let brand      = MPColor.actionPrimary
        static let brandHover = Palette.mor400
        static let brandPress = MPColor.brandPurple
        static let brandEdge  = MPColor.brandNight
        static let brandSoft  = MPColor.actionSoft
        /// `brandSoft` yüzeyin süs kenarı ve sönük veri çubuğu. Metin taşımaz.
        static let brandSoftEdge = MPColor.borderOutline
        /// `brandSoft` üstünde metin ve ikon (7.44:1).
        static let brandInk   = MPColor.brandPurple
        /// Tamamlanmış adım noktası. Metin dışı öğe (3.74:1 ≥ 3:1).
        static let brandTrack = MPColor.brandLavender
        static let textOnBrand = MPColor.textOnAction

        static let reward     = MPColor.brandStar
        static let rewardEdge = Palette.hardal600
        static let rewardSoft = MPColor.statusWarningSoft
        static let premiumInk = Palette.hardal700

        static let play     = MPColor.brandCoral
        static let playEdge = Palette.mercan600
        static let playSoft = MPColor.worldPeachSoft

        static let calm     = MPColor.statusSuccess
        static let calmEdge = Palette.yesim600
        static let calmSoft = MPColor.statusSuccessSoft

        static let textTitle = MPColor.textPrimary
        static let textBody  = MPColor.textPrimary
        static let textMuted = MPColor.textSecondary
        static let textFaint = MPColor.textTertiary
        static let textLink  = MPColor.actionPrimary

        static let surfaceApp     = MPColor.backgroundKid
        static let surfaceCard    = MPColor.backgroundSurface
        static let surfaceSunken  = MPColor.backgroundSunken
        static let surfaceRaised  = MPColor.backgroundSurface
        static let surfaceInverse = Palette.gece600

        static let borderHairline = MPColor.borderKid
        static let borderStrong   = MPColor.borderDashed
        static let edgeCard       = MPColor.borderKid
        static let edgeInverse    = Palette.gece800

        static let success = MPColor.statusSuccess
        static let warning = MPColor.statusWarning
        static let danger  = MPColor.statusDanger

        static let focusRing = Palette.morLavanta
        static let scrim     = Palette.murekkep900.opacity(0.44)

        /// Dairesel öğelerin sert alt kenarı — `mpEdge`'in yuvarlak karşılığı.
        /// Dikdörtgen kenarlar dolu renk kullanır; daire altında çalışan tek
        /// çözüm yarı saydam mürekkep olduğu için ayrı token.
        static let edgeCircle = Palette.murekkep900.opacity(0.18)

        /// Renkli zemin üstündeki kenar (toast gibi). `edgeCard` kağıt
        /// üstünde çalışır; renk üstünde aynı tonu vermediği için ayrı.
        static let edgeOnColor = Palette.murekkep900.opacity(0.22)

        /// Yarı saydam (`.ultraThinMaterial`) yüzeylerin kenarı.
        static let edgeGlass = Palette.murekkep900.opacity(0.12)

        /// İllüstrasyonun üstündeki metin — yalnızca `MP.Scrim.art` üstünde.
        /// Kontrastı `StoryArtKitTests` en kötü duruma (beyaz resim) karşı ölçer.
        static let textOnArt      = Palette.gece25
        static let textOnArtMuted = Palette.gece100
        /// Görseli henüz gelmemiş bir sanat setinin gece zemini.
        static let surfaceNight   = Palette.gece700

        /// Avatar madalyonunun renk kümesi.
        ///
        /// Sıra ve uzunluk sabittir: seçilen renk `UserDefaults`'ta *indeks*
        /// olarak saklanıyor (`mp_avatarColor_<uuid>`), bu yüzden araya renk
        /// eklemek kayıtlı profillerin rengini kaydırır. Yeni renk yalnızca
        /// sona eklenir.
        static let avatarAccents: [Color] = [
            Palette.gul400, Palette.hardal400, Palette.yesim400,
            Palette.mercan400, Palette.gece400, Palette.lila400
        ]

        /// Kitap karakterinin parça renkleri (B2), `avatar_kit.json`'daki
        /// `colorToken` adıyla. Kit hex yazmaz; adı buradan çözülür.
        /// `AvatarKitTests` kitteki her token'ın burada olduğunu denetler.
        static let avatarParts: [String: Color] = [
            "avatarSkinLight": Palette.tenAcik,
            "avatarSkinOlive": Palette.tenBugday,
            "avatarSkinBrown": Palette.tenEsmer,
            "avatarSkinDark":  Palette.tenKoyu,
            "avatarHairBlack":  Palette.sacSiyah,
            "avatarHairBrown":  Palette.sacKahve,
            "avatarHairAuburn": Palette.sacKumral,
            "avatarHairBlonde": Palette.sacSari,
            "avatarHairRed":    Palette.sacKizil,
            "avatarOutfitBlue":   Palette.deniz400,
            "avatarOutfitGreen":  Palette.yesim400,
            "avatarOutfitYellow": Palette.hardal300,
            "avatarOutfitOrange": Palette.mercan400,
            "avatarOutfitPurple": Palette.lila400,
            "avatarOutfitRed":    Palette.gul500,
        ]
        /// Yer tutucu avatarın yüz çizgisi ve gözlüğü.
        static let avatarInk = Palette.murekkep900
        /// Yer tutucu avatarın yüzü ve giysisi — ebeveynin seçmediği sabit
        /// parçalar. Hepsi mevcut paletten; yeni ham renk yok.
        static let avatarEyeWhite = Palette.kagit0
        static let avatarIris     = Palette.kahve400
        static let avatarCheek    = Palette.gul300
        static let avatarMouth    = Palette.gul800
        static let avatarTongue   = Palette.gul400
        static let avatarShade    = Palette.murekkep900.opacity(0.14)
        static let avatarHighlight = Palette.kagit0
        static let avatarPants    = Palette.gece300
        static let avatarShoe     = Palette.murekkep700
        static let avatarBag      = Palette.kahve400

        /// Yer tutucu yol arkadaşlarının (B2) renkleri. Gerçek çizim gelince
        /// kullanılmaz.
        static let companionFox         = Palette.mercan400
        static let companionFoxLight    = Palette.kagit50
        static let companionHedgehog    = Palette.kahve400
        static let companionHedgehogFace = Palette.hardal100
        static let companionRabbit      = Palette.kagit50
        static let companionRabbitInner = Palette.gul200
        static let companionOwl         = Palette.murekkep300
        static let companionOwlBelly    = Palette.kagit200
        static let companionBeak        = Palette.hardal400

        /// Yer tutucu sahne arka planlarının tonları (B2), `scene_library.json`
        /// → `placeholderArt.tone` adıyla. Düz renk; gradient yok.
        static let sceneTones: [String: SceneTone] = [
            "forest": SceneTone(sky: Palette.kagit50, far: Palette.yesim100, near: Palette.yesim300,
                                ground: Palette.yesim200, path: Palette.kagit300, accent: Palette.kahve400),
            "meadow": SceneTone(sky: Palette.hardal50, far: Palette.yesim100, near: Palette.cimen400,
                                ground: Palette.yesim100, path: Palette.kagit200, accent: Palette.gul300),
            "garden": SceneTone(sky: Palette.gece600, far: Palette.gece500, near: Palette.gece400,
                                ground: Palette.gece300, path: Palette.gece200, accent: Palette.hardal200),
        ]
    }

    /// Bir yer tutucu sahnenin renkleri: gökyüzü, uzak sıra, yakın sıra, zemin,
    /// patika ve küçük vurgular (gövde, ay, çiçek).
    struct SceneTone {
        let sky: Color
        let far: Color
        let near: Color
        let ground: Color
        let path: Color
        let accent: Color
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
            case .light: return MPColor.readerDayBackground
            case .sepia: return MPColor.readerSepiaBackground
            case .night: return MPColor.readerNightBackground
            }
        }
        var foreground: Color {
            switch self {
            case .light: return MPColor.readerDayText
            case .sepia: return MPColor.readerSepiaText
            case .night: return MPColor.readerNightText
            }
        }
        var body: Color {
            switch self {
            case .light: return MPColor.readerDayText
            case .sepia: return MPColor.readerSepiaText
            case .night: return MPColor.readerNightText
            }
        }
        var muted: Color {
            switch self {
            case .light: return MPColor.readerDaySecondary
            case .sepia: return MPColor.readerSepiaSecondary
            case .night: return MPColor.readerNightSecondary
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
            case .light: return MPColor.readerDayBackground
            case .sepia: return MPColor.readerSepiaBackground
            case .night: return MPColor.readerNightBackground
            }
        }

        /// Cilt payı — sayfanın iç kenarındaki ince gölge.
        /// Sistemdeki derinlik `mpEdge`'tir; bu onun kitaba özgü karşılığı.
        var spine: Color {
            switch self {
            case .light: return Palette.kagit500.opacity(0.22)
            case .sepia: return Palette.sepya300.opacity(0.22)
            case .night: return Palette.gece800.opacity(0.38)
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
            case .krallik:  return Palette.gul400
            case .uzay:     return Palette.gece400
            case .orman:    return Palette.yesim400
            case .kahraman: return Palette.hardal400
            case .deniz:    return Palette.deniz400
            case .dinozor:  return Palette.fosil400
            case .peri:     return Palette.lila400
            case .korsan:   return Palette.kahve400
            case .kar:      return Palette.buz400
            case .ciftlik:  return Palette.cimen400
            case .robot:    return Palette.metal400
            case .sirk:     return Palette.mercan400
            }
        }
        var isPremium: Bool {
            switch self {
            case .peri, .korsan, .kar, .ciftlik, .robot, .sirk: return true
            default: return false
            }
        }

        /// İçeriğin mekân etiketlerinden kapak dünyası.
        ///
        /// Etiketlerden türetilir çünkü etiketler içerikte yazılıdır; id listesi
        /// tutmak, her yeni mekânda güncellenmesi gereken ikinci bir kaynak
        /// olurdu. Tanınmayan etiket `nil` döner ve çağıran eski haritaya düşer
        /// — sessizce yanlış bir kapak vermektense bilinen davranışa dönmek.
        static func from(settingTags tags: [String]) -> World? {
            let set = Set(tags)
            if !set.isDisjoint(with: ["sea", "ocean", "water", "reef"])  { return .deniz }
            if !set.isDisjoint(with: ["mountain", "snow", "peak"])       { return .kar }
            if !set.isDisjoint(with: ["meadow", "festival"])             { return .sirk }
            if !set.isDisjoint(with: ["garden", "orchard", "farm"])      { return .ciftlik }
            if !set.isDisjoint(with: ["forest", "jungle", "woods"])      { return .orman }
            if !set.isDisjoint(with: ["space", "sky", "moon"])           { return .uzay }
            if !set.isDisjoint(with: ["castle", "kingdom"])              { return .krallik }
            return nil
        }
    }

    // MARK: Tipografi

    enum F {
        static let display = "Nunito"
        static let body    = "Nunito"

        // Display: Nunito black (FAZ 17, Baloo 2 kalktı)
        static func displayXL() -> Font { .custom(display, size: 40).weight(.black) }
        static func displayLG() -> Font { .custom(display, size: 32).weight(.black) }
        static func displayMD() -> Font { .custom(display, size: 26).weight(.black) }
        static func displaySM() -> Font { .custom(display, size: 21).weight(.black) }
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

        /// Glyph (SF Symbol / emoji) boyutu.
        ///
        /// Sistemdeki tek meşru `.system(...)` kullanımı budur: semboller
        /// sistem fontunun metriklerine bağlıdır, Nunito ile
        /// çizilemezler. Bu fonksiyonun amacı `.system`'i yasaklamak değil,
        /// sembol boyutlarının `MP.G` ölçeğinden gelmesini sağlamak.
        static func glyph(_ size: CGFloat, _ w: Font.Weight = .regular) -> Font {
            .system(size: size, weight: w)
        }
    }

    // MARK: Glyph ölçeği

    /// İkon ve emoji boyutları.
    ///
    /// Daha önce merkezi bir ikon ölçeği yoktu: 54 `MPIcon` çağrısı 17 ayrı
    /// boyut kullanıyor. Bu ölçek o boyutları emekliye ayırmak için var;
    /// mevcut çağrıların buraya taşınması görsel bir karar olduğu için
    /// ayrı bir turda yapılmalı (bkz. docs/MagicPaper_Design_System.md).
    enum G {
        static let xs: CGFloat = 12
        static let sm: CGFloat = 14
        static let md: CGFloat = 18
        static let lg: CGFloat = 22   // MPIcon varsayılanı
        static let xl: CGFloat = 26
        static let xxl: CGFloat = 34
        static let hero: CGFloat = 52
        static let display: CGFloat = 64
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
        /// Ortam hareketi: ana sayfa bulutlarının birkaç noktalık gidip gelişi.
        /// Bir tepki değil, bir dekor; yalnızca Reduce Motion kapalıyken başlar.
        static let ambient = Animation.easeInOut(duration: 14).repeatForever(autoreverses: true)
        /// Sahnedeki Ragi'nin nefes alışı: birkaç noktalık, yavaş, sürekli.
        static let idle = Animation.easeInOut(duration: 2.6).repeatForever(autoreverses: true)
        /// Masal atölyesi: bir cümlenin mürekkeple yazılma süresi, saniye
        /// (karar 16 Ekim 2026). Harf harf ilerler; bir eğri değil, bir tempo.
        static let inkDuration: Double = 2.8

        static let sink: CGFloat = 2
        static let scale: CGFloat = 0.96
        /// Yerinden kıpırdamayan basmanın sönme oranı (`MPPressStyle.highlight`).
        static let pressDim: Double = 0.62
    }

    // MARK: Gölgeler

    struct ShadowSpec {
        let color: Color, radius: CGFloat, x: CGFloat, y: CGFloat
    }

    enum Sh {
        static let soft    = ShadowSpec(color: Palette.murekkep900.opacity(0.05), radius: 3,  x: 0, y: 2)
        static let card    = ShadowSpec(color: Palette.murekkep900.opacity(0.06), radius: 7,  x: 0, y: 4)
        static let lifted  = ShadowSpec(color: Palette.murekkep900.opacity(0.10), radius: 13, x: 0, y: 10)
        static let sheet   = ShadowSpec(color: Palette.murekkep900.opacity(0.16), radius: 17, x: 0, y: -8)
        static let brand   = ShadowSpec(color: Palette.mor500.opacity(0.22),      radius: 9,  x: 0, y: 6)

        /// Tek başına duran görsel: logo, boş durum illüstrasyonu.
        /// Kart gölgesinden ayrıdır — kartın derinliği `mpEdge`'ten gelir,
        /// burada kenarı olmayan bir görseli zeminden ayırmak gerekir.
        static let art     = ShadowSpec(color: Palette.murekkep900.opacity(0.12), radius: 9,  x: 0, y: 8)

        /// Anahtar/topuz gibi küçük hareketli parçalar.
        static let knob    = ShadowSpec(color: Palette.murekkep900.opacity(0.20), radius: 1.5, x: 0, y: 1)
    }

    // MARK: Cam

    /// Liquid Glass (iOS 26+). Yalnızca içeriğin üstünde yüzen gezinme
    /// kontrollerinde: alt sekme çubuğu, `MPModeSwitch` (CLAUDE.md, Derinlik).
    /// Yüzey `mpGlassSurface(in:)` ile kurulur; bileşenler satır içi cam kurmaz.
    enum Glass {
        /// Yüzen gezinme kontrolü. Etkileşimli değil: dokununca cam esnemez,
        /// zıplamaz (karar: 15 Ekim 2026). Ton hafif; okunurluğu altındaki
        /// kaydırma kenarı efekti taşır
        /// (`mpFloatingBar`), cam kâğıda dönüşmez.
        @available(iOS 26.0, *)
        static var bar: SwiftUI.Glass { .regular.tint(C.surfaceCard.opacity(0.25)) }

        /// iOS 26 öncesi yüzeyin dolgusu (malzemenin üstünde) ve kenarı.
        static let fallbackFill = C.surfaceCard.opacity(0.72)
        static let fallbackEdge = C.edgeGlass
    }

    // MARK: Görsel üstü karartma

    /// İllüstrasyonun üstüne metin binen tek yer için karartma.
    ///
    /// Design law'daki gradient istisnası buna dayanır: arayüz yüzeyi değil,
    /// resmin içinde metni okunur kılan bir malzeme. Yalnızca `MPArtHero`
    /// kullanır. `peak` değiştirilirse `StoryArtKitTests`'teki kontrast testi
    /// yeniden koşmalı — `textOnArt` beyaz bir resim üstünde bile 4.5:1 kalmalı.
    ///
    /// Karartma kadrajın bir oranına değil metin bloğuna bağlıdır: metin
    /// Dynamic Type ile uzadıkça tam koyu bölge de uzar, metin hiçbir boyutta
    /// resmin açık kısmına taşmaz.
    enum Scrim {
        static let ink  = Palette.gece800
        static let peak: Double = 0.78
        /// Metnin üstünde karartmanın sıfırdan tam koyuya çıktığı mesafe.
        static let featherHeight: CGFloat = S.x10

        /// Metnin arkası — tam koyu.
        static var solid: Color { ink.opacity(peak) }
        /// Metnin üstündeki geçiş — yukarıdan aşağı saydamdan `solid`'e.
        static var feather: LinearGradient {
            LinearGradient(colors: [ink.opacity(0), solid], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Sistemin imzası: sert alt kenar

extension View {
    /// CSS'teki `border-bottom: Npx solid <edge>` karşılığı.
    /// Derinlik bu modifier'dan gelir — gölge ile taklit edilmemeli.
    func mpEdge(fill: Color, edge: Color, radius: CGFloat, width: CGFloat = MP.E.width) -> some View {
        // FAZ 17: Pastel Masal'da derinlik gölgeden gelir; `edge` artık çizilmez.
        // Taşınmamış ekranlar bu imzayı kullanmaya devam eder.
        self.background(
            RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill)
        )
        .mpShadow(.card)
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

/// Basma davranışı — sistemdeki tek kaynak.
///
/// İki his var:
/// - `sink`: öğe kendi alt kenarının üzerine çöker. 2px aşağı, 0.985 ölçek,
///   biraz koyulaşma. Kenarı (`mpEdge`) olan butonlar ve kartlar içindir.
/// - `highlight`: yerinden kıpırdamaz, yalnızca söner. Liste satırları,
///   sekmeler ve metin bağlantıları içindir. Bunlar hareket ettiğinde
///   satırlar birbirine çarpıyormuş gibi durur.
///
/// "Hareketi Azalt" açıkken `sink` da yerinden kıpırdamaz ve söner. Önceden
/// hiç tepki vermiyordu, yani basıldığını gösteren bir işaret kalmıyordu.
struct MPPressStyle: ButtonStyle {
    enum Feel { case sink, sinkFlat, highlight }

    var feel: Feel = .sink
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(_ feel: Feel = .sink) { self.feel = feel }

    /// Eski çağrı biçimi: `scales: false` ölçeksiz çökme.
    init(scales: Bool) { self.feel = scales ? .sink : .sinkFlat }

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let moves = feel != .highlight && !reduceMotion
        let held = pressed && moves
        let dims = pressed && !moves
        // Basınca kendi alt kenarına çöker (kısa eğri), bırakınca yaylanarak
        // geri gelir (tek spring): "dokundum" hissi yalnızca küçülmeden gelmez.
        return configuration.label
            .scaleEffect(held && feel == .sink ? MP.M.scale : 1)
            .offset(y: held ? MP.M.sink : 0)
            .brightness(held ? -0.03 : 0)
            .opacity(dims ? MP.M.pressDim : 1)
            .animation(pressed ? MP.M.press : MP.M.spring, value: pressed)
    }
}
