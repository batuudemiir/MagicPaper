import Foundation

/// Tam boy kahramandan eski büst alanlarına yansıma (22 Kasım 2026).
///
/// Çocuğun görünüşünün tek kaynağı yine `HeroLook` (CLAUDE.md ilke 5). Tam boy
/// kahraman kaydedilince eski alanlar da yaklaşık karşılıklarıyla yazılır:
/// görselli kitabın parça seçimi (`HeroBookCharacter`) ve henüz tam boy bilmeyen
/// her yer aynı çocuğu görsün. Eşleme tablosu burada ve yalnızca burada.
///
/// | Tam boy | Eski alan |
/// |---|---|
/// | ten porselen · açık şeftali · kum, bal · amber · fındık, kakao · ceviz, toprak, koyu kahve | ten 0 · 1 · 2 · 3 · 4 · 5 |
/// | saç kısa dalga, küt kahkül, çift örgü, kıvırcık topuz, uzun dalga, yüksek topuz, kısacık, saçsız | kısa, küt, örgü, topuz, uzun, topuz, çok kısa, saçsız |
/// | saç rengi siyah · kestane, koyu kahve · küllü kumral · bal · bakır · gümüş · mürdüm | 0 · 1 · 2 · 3 · 4 · 5 · 6 |
/// | başörtüsü | başörtüsü (kitap yazılmaz, `HeroBookCharacter`) |
/// | gözlük turkuaz köşeli, yeşil altıgen · diğerleri | köşeli · yuvarlak |
/// | üst ya da tek parçanın ana rengi | üst rengi (kitaptaki kıyafet rengi) |
///
/// Şapka, çanta ve ayakkabı yansıtılmaz: eski büstte ücretli kozmetiktir ve
/// hayvana geçen çocuğa ödenmemiş bir eşya bırakmamalıdır.
extension HeroLook {
    func wearing(_ figure: HeroFigure) -> HeroLook {
        var look = self
        look.kind = .child
        look.figure = figure
        look.skin = HeroFigureLegacy.skin[figure[.skin]] ?? look.skin
        look.hair = HeroFigureLegacy.hair[figure[.hair]] ?? look.hair
        look.hairColor = HeroFigureLegacy.hairColor[figure[.dye]] ?? look.hairColor
        if figure.isHijab {
            look.headwear = .hijab
            look.headwearColor = HeroFigureLegacy.scarfColor[figure[.head]] ?? look.headwearColor
        } else if look.headwear == .hijab {
            look.headwear = .none
        }
        switch figure[.glasses] {
        case "none": look.glasses = .none
        case "glass-2", "glass-6": look.glasses = .square
        default: look.glasses = .round
        }
        let garment = figure.wearsOnePiece ? figure[.one] : figure[.top]
        look.topColor = HeroFigureLegacy.clothColor[garment] ?? look.topColor
        return look
    }
}

enum HeroFigureLegacy {
    static let skin: [String: Int] = [
        "pearl": 0, "apricot": 1, "sand": 2, "honey": 2, "amber": 3,
        "hazel": 4, "cocoa": 4, "walnut": 5, "earth": 5, "espresso": 5
    ]
    static let hair: [String: HeroLook.Hair] = [
        "hair-1": .short, "hair-2": .bob, "hair-3": .braids, "hair-4": .buns,
        "hair-5": .long, "hair-6": .buns, "crop": .buzz, "bald": .none
    ]
    static let hairColor: [String: Int] = [
        "black": 0, "chestnut": 1, "darkbrown": 1, "ash": 2, "honey": 3,
        "copper": 4, "silver": 5, "violet": 6
    ]
    /// `MP.C.heroCloth`: 0 mavi, 1 yeşil, 2 hardal, 3 mercan, 4 lila, 5 gül, 6 mor, 7 mavi.
    static let scarfColor: [String: Int] = ["scarf-1": 4, "scarf-2": 5, "scarf-3": 1, "scarf-4": 2]
    static let clothColor: [String: Int] = [
        "top-1": 3, "top-2": 1, "top-3": 4, "top-4": 0, "top-5": 3, "top-6": 5,
        "top-7": 0, "top-8": 4, "top-9": 2, "top-10": 1, "top-11": 6, "top-12": 3,
        "one-1": 5, "one-2": 0, "one-3": 6, "one-4": 2, "one-5": 1, "one-6": 7
    ]
}
