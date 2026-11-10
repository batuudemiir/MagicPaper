import Foundation

/// Çocuğun kahramanının görünüşü (Faz 9, 12 Kasım 2026; Batuhan: "Duolingo tarzı
/// avatar ve avatar türleri"). Düz renkli, konturu olmayan, katmanlı bir büst.
///
/// İki tür var: çocuk (ten, saç) ve hayvan dostu (kedi, ayı, tavşan, tilki,
/// panda; kürk). Yüz, kıyafet, şapka ve gözlük ikisinde de ortak. Renkler indeks:
/// palet `MP.C.hero*`, sırası sabit. Kimlik parçaları (tür, ten, saç) ebeveyn
/// kapısıyla, kozmetikler (şapka, kıyafet, gözlük) çocuk tarafından değişir.
struct HeroLook: Codable, Equatable, Hashable {

    enum Kind: String, Codable, CaseIterable, Identifiable {
        case child, cat, bear, bunny, fox, panda
        var id: String { rawValue }
        var title: String {
            switch self {
            case .child: "Çocuk"
            case .cat: "Kedi"
            case .bear: "Ayı"
            case .bunny: "Tavşan"
            case .fox: "Tilki"
            case .panda: "Panda"
            }
        }
        var isAnimal: Bool { self != .child }
    }

    enum Hair: String, Codable, CaseIterable, Identifiable {
        case short, buzz, curly, long, bob, ponytail, buns, braids, afro, spiky, none
        var id: String { rawValue }
        var title: String {
            switch self {
            case .short: "Kısa"
            case .buzz: "Çok kısa"
            case .curly: "Kıvırcık"
            case .long: "Uzun"
            case .bob: "Küt"
            case .ponytail: "At kuyruğu"
            case .buns: "Topuz"
            case .braids: "Örgü"
            case .afro: "Afro"
            case .spiky: "Dikenli"
            case .none: "Saçsız"
            }
        }
    }

    enum Eyes: String, Codable, CaseIterable, Identifiable {
        case round, happy, big, wink, sleepy
        var id: String { rawValue }
        var title: String {
            switch self {
            case .round: "Yuvarlak"
            case .happy: "Gülen"
            case .big: "Kocaman"
            case .wink: "Göz kırpan"
            case .sleepy: "Uykulu"
            }
        }
    }

    enum Mouth: String, Codable, CaseIterable, Identifiable {
        case smile, grin, open, tongue, calm
        var id: String { rawValue }
        var title: String {
            switch self {
            case .smile: "Gülümseme"
            case .grin: "Kocaman gülüş"
            case .open: "Şaşkın"
            case .tongue: "Dil"
            case .calm: "Sakin"
            }
        }
    }

    enum Glasses: String, Codable, CaseIterable, Identifiable {
        case none, round, square, sun
        var id: String { rawValue }
        var title: String {
            switch self {
            case .none: "Yok"
            case .round: "Yuvarlak"
            case .square: "Köşeli"
            case .sun: "Güneş"
            }
        }
    }

    enum Headwear: String, Codable, CaseIterable, Identifiable {
        case none, beanie, cap, crown, hijab, flowers, wizard
        var id: String { rawValue }
        var title: String {
            switch self {
            case .none: "Yok"
            case .beanie: "Bere"
            case .cap: "Şapka"
            case .crown: "Taç"
            case .hijab: "Başörtüsü"
            case .flowers: "Çiçek tacı"
            case .wizard: "Büyücü şapkası"
            }
        }
        /// Başı saran örtü saçı gizler.
        var hidesHair: Bool { self == .hijab }
    }

    enum Top: String, Codable, CaseIterable, Identifiable {
        case tshirt, hoodie, collar, stripes, overalls, sweater
        var id: String { rawValue }
        var title: String {
            switch self {
            case .tshirt: "Tişört"
            case .hoodie: "Kapüşonlu"
            case .collar: "Yakalı"
            case .stripes: "Çizgili"
            case .overalls: "Tulum"
            case .sweater: "Kazak"
            }
        }
    }

    var kind: Kind = .child
    var skin: Int = 1
    var fur: Int = 0
    var hair: Hair = .short
    var hairColor: Int = 1
    var eyes: Eyes = .round
    var mouth: Mouth = .smile
    var freckles: Bool = false
    var glasses: Glasses = .none
    var headwear: Headwear = .none
    var headwearColor: Int = 6
    var top: Top = .tshirt
    var topColor: Int = 0

    static let standard = HeroLook()

    init(kind: Kind = .child, skin: Int = 1, fur: Int = 0, hair: Hair = .short, hairColor: Int = 1,
         eyes: Eyes = .round, mouth: Mouth = .smile, freckles: Bool = false, glasses: Glasses = .none,
         headwear: Headwear = .none, headwearColor: Int = 6, top: Top = .tshirt, topColor: Int = 0) {
        self.kind = kind; self.skin = skin; self.fur = fur; self.hair = hair; self.hairColor = hairColor
        self.eyes = eyes; self.mouth = mouth; self.freckles = freckles; self.glasses = glasses
        self.headwear = headwear; self.headwearColor = headwearColor; self.top = top; self.topColor = topColor
    }

    /// Eksik ya da tanınmayan alan varsayılana düşer: yeni bir parça eklenince
    /// eski kayıtlar okunmaya devam eder, kahraman kaybolmaz.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = HeroLook()
        kind = (try? c.decodeIfPresent(Kind.self, forKey: .kind)) ?? d.kind
        skin = (try? c.decodeIfPresent(Int.self, forKey: .skin)) ?? d.skin
        fur = (try? c.decodeIfPresent(Int.self, forKey: .fur)) ?? d.fur
        hair = (try? c.decodeIfPresent(Hair.self, forKey: .hair)) ?? d.hair
        hairColor = (try? c.decodeIfPresent(Int.self, forKey: .hairColor)) ?? d.hairColor
        eyes = (try? c.decodeIfPresent(Eyes.self, forKey: .eyes)) ?? d.eyes
        mouth = (try? c.decodeIfPresent(Mouth.self, forKey: .mouth)) ?? d.mouth
        freckles = (try? c.decodeIfPresent(Bool.self, forKey: .freckles)) ?? d.freckles
        glasses = (try? c.decodeIfPresent(Glasses.self, forKey: .glasses)) ?? d.glasses
        headwear = (try? c.decodeIfPresent(Headwear.self, forKey: .headwear)) ?? d.headwear
        headwearColor = (try? c.decodeIfPresent(Int.self, forKey: .headwearColor)) ?? d.headwearColor
        top = (try? c.decodeIfPresent(Top.self, forKey: .top)) ?? d.top
        topColor = (try? c.decodeIfPresent(Int.self, forKey: .topColor)) ?? d.topColor
    }

    /// Örnek kahramanlar: vitrin, önizleme, ilk açılış.
    static let samples: [HeroLook] = [
        HeroLook(skin: 1, hair: .short, hairColor: 1, eyes: .round, mouth: .smile, topColor: 0),
        HeroLook(skin: 2, hair: .ponytail, hairColor: 0, eyes: .happy, mouth: .grin, glasses: .round, top: .stripes, topColor: 4),
        HeroLook(skin: 4, hair: .curly, hairColor: 0, eyes: .big, mouth: .open, headwear: .beanie, headwearColor: 3, top: .hoodie, topColor: 2),
        HeroLook(skin: 5, hair: .braids, hairColor: 0, eyes: .round, mouth: .smile, top: .overalls, topColor: 7),
        HeroLook(skin: 0, hair: .bob, hairColor: 4, eyes: .wink, mouth: .tongue, freckles: true, top: .collar, topColor: 5),
        HeroLook(skin: 3, hair: .afro, hairColor: 1, eyes: .happy, mouth: .grin, headwear: .crown, top: .sweater, topColor: 1),
        HeroLook(skin: 2, hair: .long, hairColor: 2, eyes: .round, mouth: .calm, headwear: .hijab, headwearColor: 4, top: .tshirt, topColor: 6),
        HeroLook(skin: 1, hair: .buns, hairColor: 3, eyes: .big, mouth: .smile, headwear: .flowers, top: .collar, topColor: 2),
        HeroLook(kind: .cat, fur: 0, eyes: .round, mouth: .smile, top: .tshirt, topColor: 0),
        HeroLook(kind: .bear, fur: 2, eyes: .happy, mouth: .grin, headwear: .cap, headwearColor: 3, top: .hoodie, topColor: 1),
        HeroLook(kind: .bunny, fur: 3, eyes: .big, mouth: .tongue, glasses: .round, top: .overalls, topColor: 5),
        HeroLook(kind: .fox, fur: 0, eyes: .wink, mouth: .smile, headwear: .wizard, headwearColor: 6, top: .sweater, topColor: 7),
        HeroLook(kind: .panda, fur: 3, eyes: .round, mouth: .open, glasses: .sun, top: .stripes, topColor: 2)
    ]
}
