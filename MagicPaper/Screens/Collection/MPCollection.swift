import Foundation

// Odam'ın sakin koleksiyonu (Faz 9, 11 Kasım 2026; `docs/VIZYON_PLANI.md`).
//
// Kurallar (CLAUDE.md ilke 7): yıldız yalnızca okuyarak kazanılır, parayla
// alınmaz; alınan hiçbir şey kaybolmaz ya da süresi dolmaz; rastgele paket yok,
// her şey fiyatıyla görünür; masal sonunda dükkân yok. Masalın çıkartması
// satın alınmaz: masal bitince kendiliğinden albüme girer (okumaya yakın ödül,
// Marinak ve Gambrell 2008). Yıldız yalnızca isteğe bağlı süs alır.

// MARK: - Çıkartma albümü

/// Biten her masalın albümdeki izi. Ayrı bir depo yok: biten masallardan ve
/// biten klasiklerden türetilir; masal silinse de yıldızı gitmez, çıkartması gider.
struct MPSticker: Identifiable, Equatable {
    let id: String
    let title: String
    let art: MPBookCover.Art
    let date: Date
}

enum MPStickerAlbum {

    /// Çocuğun bütün çıkartmaları, en yeni başta.
    @MainActor
    static func stickers(for profile: UserProfile?, stories: [Story],
                         classics: [UUID: ClassicProgressStore.Entry]? = nil,
                         catalog: ClassicsCatalog? = nil) -> [MPSticker] {
        let classics = classics ?? ClassicProgressStore.shared.entries
        let catalog = catalog ?? ClassicsLibrary.shared.catalog
        var out: [MPSticker] = stories
            .filter { $0.isFinished && $0.belongs(to: profile) }
            .map { MPSticker(id: $0.id.uuidString, title: $0.title,
                             art: LibraryShelfModel.coverArt($0), date: $0.lastReadAt ?? $0.createdAt) }
        for (id, entry) in classics {
            guard let finished = entry.finishedAt, let tale = catalog.tale(id) else { continue }
            out.append(MPSticker(id: id.uuidString, title: tale.title,
                                 art: .image(tale.cover, focus: tale.coverFocus), date: finished))
        }
        return out.sorted { $0.date > $1.date }
    }

    /// Ay ay gruplar: "Kasım 2026".
    static func byMonth(_ stickers: [MPSticker], calendar: Calendar = .current) -> [(title: String, stickers: [MPSticker])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "LLLL yyyy"
        var groups: [(key: DateComponents, title: String, stickers: [MPSticker])] = []
        for sticker in stickers {
            let key = calendar.dateComponents([.year, .month], from: sticker.date)
            if let i = groups.firstIndex(where: { $0.key == key }) {
                groups[i].stickers.append(sticker)
            } else {
                let title = formatter.string(from: sticker.date)
                groups.append((key, title.prefix(1).uppercased(with: Locale(identifier: "tr_TR")) + title.dropFirst(), [sticker]))
            }
        }
        return groups.map { ($0.title, $0.stickers) }
    }
}

// MARK: - Süsler

/// Yıldızla alınan süs. Bu turda kitaplık rafının rengi; kahraman dolabı
/// gerçek çizim gelince (`docs/VIZYON_PLANI.md`, Faz 9).
struct MPDecor: Identifiable, Equatable, Hashable {
    enum Kind: String { case shelf }
    let id: String
    let kind: Kind
    let title: String
    let tone: MPWorldTone
    /// Yıldız fiyatı (yaklaşık 2 yıldız/gün kazanılır).
    let price: Int

    /// Ücretsiz varsayılan raf.
    static let defaultShelf = MPDecor(id: "shelf_wood", kind: .shelf, title: "Ahşap", tone: .peach, price: 0)

    static let catalog: [MPDecor] = [
        defaultShelf,
        MPDecor(id: "shelf_lav", kind: .shelf, title: "Lavanta", tone: .lav, price: 8),
        MPDecor(id: "shelf_mint", kind: .shelf, title: "Nane", tone: .mint, price: 8),
        MPDecor(id: "shelf_sky", kind: .shelf, title: "Gökyüzü", tone: .sky, price: 8),
        MPDecor(id: "shelf_pink", kind: .shelf, title: "Pembe", tone: .pink, price: 8),
        MPDecor(id: "shelf_yellow", kind: .shelf, title: "Güneş", tone: .yellow, price: 8),
        MPDecor(id: "shelf_green", kind: .shelf, title: "Orman", tone: .green, price: 8)
    ]

    static func item(_ id: String) -> MPDecor? { catalog.first { $0.id == id } }

    /// 3-5 yaş için ebeveynin açtığı "kolay fiyatlar": yarı fiyat, yukarı yuvarlanır.
    func price(easy: Bool) -> Int { Self.easy(price, easy) }

    static func easy(_ price: Int, _ on: Bool) -> Int { on ? (price + 1) / 2 : price }
}

// MARK: - Yıldız cüzdanı

/// Çocuk başına harcama defteri. Yalnızca büyür (alınan eşya geri alınmaz,
/// kaybolmaz); iki cihazın defteri birleşince ikisinin alımları da kalır.
struct MPStarWallet: Codable, Equatable {
    struct Purchase: Codable, Equatable {
        let itemID: String
        let price: Int
        let date: Date
    }

    private(set) var purchases: [Purchase] = []
    /// Kullanılan süs, tür başına (`MPDecor.Kind.rawValue` → eşya kimliği).
    var equipped: [String: String] = [:]

    var spent: Int { purchases.reduce(0) { $0 + $1.price } }

    func owns(_ item: MPDecor) -> Bool {
        item.price == 0 || owns(itemID: item.id)
    }

    func owns(itemID: String) -> Bool { purchases.contains { $0.itemID == itemID } }

    func balance(earned: Int) -> Int { max(0, earned - spent) }

    enum BuyResult: Equatable { case bought, alreadyOwned, notEnough(missing: Int) }

    /// Yıldız eksiye düşmez: yetmiyorsa alım olmaz, kaç yıldız gerektiği söylenir.
    mutating func buy(_ item: MPDecor, earned: Int, easyPrices: Bool, now: Date = Date()) -> BuyResult {
        if owns(item) { return .alreadyOwned }
        return buy(itemIDs: [item.id], total: item.price(easy: easyPrices), earned: earned, now: now)
    }

    /// Birden çok eşya tek seferde (Dolap: şapka + kıyafet). Ya hepsi alınır ya
    /// hiçbiri; fiyat eşyalara bölünür ki defter doğru toplasın.
    mutating func buy(itemIDs: [String], total: Int, earned: Int, now: Date = Date()) -> BuyResult {
        let fresh = itemIDs.filter { !owns(itemID: $0) }
        guard !fresh.isEmpty else { return .alreadyOwned }
        let available = balance(earned: earned)
        guard available >= total else { return .notEnough(missing: total - available) }
        let share = total / fresh.count
        for (i, id) in fresh.enumerated() {
            let price = i == 0 ? total - share * (fresh.count - 1) : share
            purchases.append(Purchase(itemID: id, price: price, date: now))
        }
        return .bought
    }

    mutating func equip(_ item: MPDecor) {
        guard owns(item) else { return }
        equipped[item.kind.rawValue] = item.id
    }

    func equippedItem(_ kind: MPDecor.Kind) -> MPDecor {
        equipped[kind.rawValue].flatMap(MPDecor.item) ?? .defaultShelf
    }

    /// İki cihazın defteri: alımlar birleşir (aynı eşya bir kez), kullanılan
    /// süs bu cihazınki kalır.
    func merged(with other: MPStarWallet) -> MPStarWallet {
        var result = self
        for purchase in other.purchases where !result.purchases.contains(where: { $0.itemID == purchase.itemID }) {
            result.purchases.append(purchase)
        }
        result.purchases.sort { $0.date < $1.date }
        return result
    }
}

/// Cüzdanın cihazdaki yeri, çocuk başına.
struct MPStarWalletStore {
    var defaults: UserDefaults = .standard
    static let keyPrefix = "mp_starwallet_"

    func wallet(for profileID: UUID) -> MPStarWallet {
        guard let data = defaults.data(forKey: Self.keyPrefix + profileID.uuidString),
              let wallet = try? JSONDecoder().decode(MPStarWallet.self, from: data) else { return MPStarWallet() }
        return wallet
    }

    func save(_ wallet: MPStarWallet, for profileID: UUID) {
        guard let data = try? JSONEncoder().encode(wallet) else { return }
        defaults.set(data, forKey: Self.keyPrefix + profileID.uuidString)
    }
}
