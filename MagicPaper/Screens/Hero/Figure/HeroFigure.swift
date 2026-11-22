import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "HeroFigure")

/// Tam boy insan kahraman (22 Kasım 2026, İrem; tasarım teslimi
/// "MagicPaper-Tam-Dolap-v2", `design-handoff/dolap/`).
///
/// On yedi bağımsız seçim yuvası: kimlik (ten, göz, saç, saç rengi, kaş, göz
/// biçimi, burun, yüz, ifade, yüz detayı), giysi (üst, alt, tek parça,
/// ayakkabı) ve aksesuar (başlık ya da örtü, gözlük, çanta). Değerler katalogdaki
/// kalıcı kimliklerdir (`hero_figure_catalog.json`), dizin değil. Cinsiyet yok:
/// her çocuk her parçayı seçer.
///
/// Kahramanın kaydı `HeroLook.figure`'da (çocuk başına, eşitlemeyle birlikte).
/// Hayvan kahramanlar eski büst çizimiyle sürer; insan ve hayvan kayıtları ayrı.
struct HeroFigure: Codable, Equatable, Hashable {

    /// Kaydın şema sürümü: katalog biçimi değişirse eski kayıt tanınır.
    static let schemaVersion = 2

    enum Slot: String, CaseIterable, Codable {
        case skin, eye, hair, dye, brow, eyeShape, nose, face, expression, detail
        case top, bottom, one, shoe, head, glasses, bag

        /// Başlangıç yüzünün değiştirdiği kimlik alanları (`secim.js identitySlots`).
        static let identity: [Slot] = [.skin, .eye, .brow, .nose, .eyeShape, .hair, .dye, .face, .expression, .detail]
        /// Kombinin değiştirdiği giysi alanları.
        static let outfit: [Slot] = [.top, .bottom, .shoe, .one]
    }

    private(set) var values: [Slot: String]
    var version: Int = HeroFigure.schemaVersion

    subscript(slot: Slot) -> String {
        get { values[slot] ?? HeroFigureCatalog.shared.defaultValue(for: slot) }
        set { values[slot] = newValue }
    }

    /// Bilinmeyen ya da eksik değer yalnızca kendi yuvasında varsayılana (ilk
    /// başlangıç yüzü) döner; geri kalan görünüm korunur (`normalizeLook`).
    init(values raw: [String: String], catalog: HeroFigureCatalog = .shared) {
        var values: [Slot: String] = [:]
        for slot in Slot.allCases {
            if let id = raw[slot.rawValue], catalog.contains(id, in: slot) {
                values[slot] = id
            } else {
                values[slot] = catalog.defaultValue(for: slot)
            }
        }
        self.values = values
    }

    /// Yeni kahraman: ilk başlangıç yüzü ("Kiraz bahçesi").
    static var starter: HeroFigure { HeroFigure(values: HeroFigureCatalog.shared.starters.first?.values ?? [:]) }

    var isHijab: Bool { self[.head].hasPrefix("scarf") }
    var isHat: Bool { self[.head].hasPrefix("hat") }
    var wearsOnePiece: Bool { self[.one] != "none" }

    // MARK: Kodlama: {"version": 2, "skin": "honey", …}

    private struct Key: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        var raw: [String: String] = [:]
        for key in c.allKeys where key.stringValue != "version" {
            if let value = try? c.decode(String.self, forKey: key) { raw[key.stringValue] = value }
        }
        self.init(values: raw)
        version = (try? c.decode(Int.self, forKey: Key(stringValue: "version"))) ?? Self.schemaVersion
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Key.self)
        try c.encode(version, forKey: Key(stringValue: "version"))
        for slot in Slot.allCases { try c.encode(self[slot], forKey: Key(stringValue: slot.rawValue)) }
    }

    static func == (a: HeroFigure, b: HeroFigure) -> Bool {
        Slot.allCases.allSatisfy { a[$0] == b[$0] }
    }

    func hash(into hasher: inout Hasher) {
        for slot in Slot.allCases { hasher.combine(self[slot]) }
    }
}

// MARK: - Seçim kuralları (`secim.js`)

extension HeroFigure {

    /// Dolabın bir seçimi: katalog yuvası, başlangıç yüzü ya da kombin.
    enum Choice: Equatable {
        case item(Slot, String)
        case starter(Int)
        case outfit(String)
    }

    /// Seçimin sonucu. Başlangıç yüzü yalnızca kimliği, kombin yalnızca giysiyi
    /// değiştirir; teni, saçı, yüzü, gözlüğü, başlığı ve çantayı korur. Üst ya da
    /// alt seçmek iki parçalı giyime döner; tek parçadayken ayakkabı tek
    /// parçayı korur. Başörtüsü takılıyken saç değişirse seçim saklanır.
    func selecting(_ choice: Choice, catalog: HeroFigureCatalog = .shared) -> HeroFigure {
        var result = self
        switch choice {
        case .starter(let index):
            guard catalog.starters.indices.contains(index) else { return self }
            let starter = HeroFigure(values: catalog.starters[index].values, catalog: catalog)
            for slot in Slot.identity { result[slot] = starter[slot] }
        case .outfit(let id):
            guard let outfit = catalog.outfits.first(where: { $0.id == id }) else { return self }
            for slot in Slot.outfit {
                if let value = outfit.parts[slot.rawValue], catalog.contains(value, in: slot) { result[slot] = value }
            }
        case .item(let slot, let id):
            guard catalog.contains(id, in: slot) else { return self }
            result[slot] = id
            if slot == .top || slot == .bottom { result[.one] = "none" }
        }
        return result
    }

    /// Bu seçim şu an giyili mi (dolaptaki tik).
    func isSelected(_ choice: Choice, catalog: HeroFigureCatalog = .shared) -> Bool {
        switch choice {
        case .starter(let index):
            guard catalog.starters.indices.contains(index) else { return false }
            let starter = HeroFigure(values: catalog.starters[index].values, catalog: catalog)
            return Slot.identity.allSatisfy { self[$0] == starter[$0] }
        case .outfit(let id):
            guard let outfit = catalog.outfits.first(where: { $0.id == id }) else { return false }
            return outfit.parts.allSatisfy { key, value in Slot(rawValue: key).map { self[$0] == value } ?? true }
        case .item(let slot, let id):
            if (slot == .top || slot == .bottom) && wearsOnePiece { return false }
            return self[slot] == id
        }
    }
}

// MARK: - Katalog

/// `hero_figure_catalog.json`: tasarım teslimindeki katalog, olduğu gibi.
struct HeroFigureCatalog {
    struct Option: Decodable, Hashable, Identifiable {
        let id: String
        let name: String
        let hex: String?
    }

    struct Outfit: Decodable, Hashable, Identifiable {
        let name: String
        let id: String
        let parts: [String: String]
    }

    struct Starter: Hashable {
        let name: String
        let values: [String: String]
    }

    let items: [HeroFigure.Slot: [Option]]
    let outfits: [Outfit]
    let starters: [Starter]

    static let shared: HeroFigureCatalog = load(from: .main)

    static let empty = HeroFigureCatalog(items: [:], outfits: [], starters: [])

    func options(_ slot: HeroFigure.Slot) -> [Option] { items[slot] ?? [] }

    func contains(_ id: String, in slot: HeroFigure.Slot) -> Bool {
        options(slot).contains { $0.id == id }
    }

    func option(_ id: String, in slot: HeroFigure.Slot) -> Option? {
        options(slot).first { $0.id == id }
    }

    /// İlk başlangıç yüzünün değeri; o da yoksa yuvanın ilk seçeneği.
    func defaultValue(for slot: HeroFigure.Slot) -> String {
        if let value = starters.first?.values[slot.rawValue], contains(value, in: slot) { return value }
        return options(slot).first?.id ?? "none"
    }

    // MARK: Yükleme

    private struct File: Decodable {
        let items: [String: [Option]]
        let outfits: [Outfit]
        let examples: [Example]
    }

    /// `["Kiraz bahçesi", {…}]`
    private struct Example: Decodable {
        let name: String
        let values: [String: String]
        init(from decoder: Decoder) throws {
            var c = try decoder.unkeyedContainer()
            name = try c.decode(String.self)
            values = try c.decode([String: String].self)
        }
    }

    init(items: [HeroFigure.Slot: [Option]], outfits: [Outfit], starters: [Starter]) {
        self.items = items
        self.outfits = outfits
        self.starters = starters
    }

    init(data: Data) throws {
        let file = try JSONDecoder().decode(File.self, from: data)
        var items: [HeroFigure.Slot: [Option]] = [:]
        for (key, options) in file.items {
            if let slot = HeroFigure.Slot(rawValue: key) { items[slot] = options }
        }
        self.init(items: items, outfits: file.outfits,
                  starters: file.examples.map { Starter(name: $0.name, values: $0.values) })
    }

    /// Okunamazsa boş katalog: dolap boş açılır, uygulama çalışır. Testler yakalar.
    static func load(from bundle: Bundle) -> HeroFigureCatalog {
        guard let url = bundle.url(forResource: "hero_figure_catalog", withExtension: "json") else {
            logger.error("hero_figure_catalog.json pakette yok")
            return .empty
        }
        do {
            return try HeroFigureCatalog(data: Data(contentsOf: url))
        } catch {
            logger.error("hero_figure_catalog.json okunamadı: \(String(describing: error), privacy: .public)")
            return .empty
        }
    }
}
