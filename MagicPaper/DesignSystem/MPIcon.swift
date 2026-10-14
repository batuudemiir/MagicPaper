import SwiftUI

/// Tasarımın ikon sistemi Lucide'dir (2px kontur, geometrik, yuvarlak uç).
/// 50 SVG `Assets.xcassets/Icons/` altında template image olarak duruyor;
/// bu görünüm onları çizer ve bulunamazsa SF Symbol karşılığına düşer.
///
/// SF Symbols bazı glyph'lerde görsel olarak sapıyordu (Lucide `castle` yerine
/// `building.columns` bir banka binası, `rocket` yerine `airplane.departure`
/// bir uçak çiziyordu) — 05-SWIFTUI-MAPPING.md bu durumda SVG'lerin
/// kullanılabileceğini söylüyor.
struct MPIcon: View {
    let name: String
    var size: CGFloat = MP.G.lg
    var weight: Font.Weight = .regular
    /// Lucide eşlemesini atlar, doğrudan SF Symbol çizer. Dolu/boş varyantı
    /// ve sembol animasyonu gereken yerler için (alt sekme çubuğu): Lucide
    /// ikonlarının dolu hâli yok, karışık set de aynı çubukta tutarsız durur.
    var symbolOnly: Bool = false

    init(_ name: String, size: CGFloat = MP.G.lg, weight: Font.Weight = .regular,
         symbolOnly: Bool = false) {
        self.name = name
        self.size = size
        self.weight = weight
        self.symbolOnly = symbolOnly
    }

    var body: some View {
        if symbolOnly {
            Image(systemName: name)
                .font(MP.F.glyph(size, weight))
        } else {
            mapped
        }
    }

    @ViewBuilder
    private var mapped: some View {
        // Doğrudan Lucide adı da olur ("castle", "rocket"): SF karşılığı
        // olmayan dünya simgeleri için (design-handoff/docs/ICONS.md "custom").
        if let lucide = MPIconMap.lucideName(for: name) ?? (UIImage(named: "Icons/\(name)") != nil ? name : nil),
           UIImage(named: "Icons/\(lucide)") != nil {
            Image("Icons/\(lucide)")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: name)
                .font(MP.F.glyph(size, weight))
        }
    }
}

/// SF Symbol adı → Lucide dosya adı. 05-SWIFTUI-MAPPING.md'deki tablonun tersi.
enum MPIconMap {
    private static let table: [String: String] = [
        "arrow.left": "arrow-left",
        "arrow.right": "arrow-right",
        "bell": "bell",
        "bookmark": "book-marked",
        "book": "book-open",
        "cpu": "bot",
        "calendar": "calendar-days",
        "building.columns": "castle",
        "checkmark": "check",
        "chevron.down": "chevron-down",
        "chevron.left": "chevron-left",
        "chevron.right": "chevron-right",
        "clock": "clock",
        "crown.fill": "crown",
        "arrow.down.circle": "download",
        "eye.slash": "eye-off",
        "fish": "fish",
        "flame.fill": "flame",
        "heart": "heart",
        "heart.fill": "heart",
        "house": "house",
        "lock.fill": "lock",
        "moon": "moon",
        "pause.fill": "pause",
        "play.fill": "play",
        "pencil": "pencil",
        "plus": "plus",
        "printer": "printer",
        "airplane.departure": "rocket",
        "magnifyingglass": "search",
        "gearshape": "settings",
        "square.and.arrow.up": "share-2",
        "shield": "shield",
        "sailboat": "ship",
        "snowflake": "snowflake",
        "sparkles": "sparkles",
        "star.fill": "star",
        "sun.max": "sun",
        "tent": "tent",
        "leaf": "tractor",
        "trash": "trash-2",
        "tree": "trees",
        "trophy.fill": "trophy",
        "textformat.size": "type",
        "person.crop.circle": "user-round",
        "person.2.circle": "users-round",
        "speaker.wave.2": "volume-2",
        "wand.and.stars": "wand-sparkles",
        "xmark": "x",
        "bolt.fill": "zap",
        // Pastel Masal teslimindeki SF adları (ICONS.md)
        "lock": "lock",
        "star": "star",
        "crown": "crown",
        "flame": "flame",
        "wand.and.sparkles": "wand-sparkles",
        "bolt": "zap",
        "book.closed": "book-marked",
        "person": "user-round",
        "person.2": "users-round",
        "trophy": "trophy",
        "trash.fill": "trash-2",
        "gearshape.fill": "settings"
    ]

    static func lucideName(for sfSymbol: String) -> String? { table[sfSymbol] }
}
