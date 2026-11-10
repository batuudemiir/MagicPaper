import Foundation

/// Dolap'ın kuralları (Faz 9). Kimlik parçaları (tür, ten, kürk, saç, yüz)
/// hep ücretsiz ve ebeveyn kapısıyla kaydedilir. Kozmetikler (şapka, kıyafet,
/// güneş gözlüğü) çocuğundur; bir kısmı yıldızla açılır. Başörtüsü, gözlük ve
/// sade kıyafetler kimliğin parçası sayılır: hep ücretsiz.
enum HeroShop {

    struct Item: Equatable {
        let id: String
        let title: String
        let price: Int
    }

    static func price(_ headwear: HeroLook.Headwear) -> Int {
        switch headwear {
        case .none, .hijab: 0
        case .beanie, .cap: 6
        case .flowers: 8
        case .crown, .wizard: 14
        }
    }

    static func price(_ top: HeroLook.Top) -> Int {
        switch top {
        case .tshirt, .collar: 0
        case .sweater, .stripes: 6
        case .hoodie: 8
        case .overalls: 10
        }
    }

    static func price(_ glasses: HeroLook.Glasses) -> Int {
        glasses == .sun ? 6 : 0
    }

    /// Görünüşteki ücretli kozmetikler.
    static func paidItems(in look: HeroLook) -> [Item] {
        var items: [Item] = []
        if price(look.headwear) > 0 {
            items.append(Item(id: "hero.headwear.\(look.headwear.rawValue)", title: look.headwear.title, price: price(look.headwear)))
        }
        if price(look.top) > 0 {
            items.append(Item(id: "hero.top.\(look.top.rawValue)", title: look.top.title, price: price(look.top)))
        }
        if price(look.glasses) > 0 {
            items.append(Item(id: "hero.glasses.\(look.glasses.rawValue)", title: "Güneş gözlüğü", price: price(look.glasses)))
        }
        return items
    }

    /// Henüz alınmamış ücretli kozmetikler ve toplam fiyatı.
    static func unpaid(in look: HeroLook, wallet: MPStarWallet, easyPrices: Bool) -> (items: [Item], total: Int) {
        let items = paidItems(in: look).filter { !wallet.owns(itemID: $0.id) }
        let total = items.reduce(0) { $0 + MPDecor.easy($1.price, easyPrices) }
        return (items, total)
    }

    /// Kimlik değişti mi: kayıt ebeveyn kapısından geçer.
    static func identityChanged(from old: HeroLook, to new: HeroLook) -> Bool {
        old.kind != new.kind || old.skin != new.skin || old.fur != new.fur || old.hair != new.hair
            || old.hairColor != new.hairColor || old.eyes != new.eyes || old.mouth != new.mouth
            || old.freckles != new.freckles
    }
}

/// Kahramanın cihazdaki yeri, çocuk başına. Hesap eşitlemesi sonraki adım.
struct HeroLookStore {
    var defaults: UserDefaults = .standard
    static let keyPrefix = "mp_herolook_"

    func look(for profileID: UUID) -> HeroLook? {
        guard let data = defaults.data(forKey: Self.keyPrefix + profileID.uuidString) else { return nil }
        return try? JSONDecoder().decode(HeroLook.self, from: data)
    }

    func save(_ look: HeroLook, for profileID: UUID) {
        guard let data = try? JSONEncoder().encode(look) else { return }
        defaults.set(data, forKey: Self.keyPrefix + profileID.uuidString)
        NotificationCenter.default.post(name: .mpHeroLookChanged, object: profileID)
    }
}

extension Notification.Name {
    static let mpHeroLookChanged = Notification.Name("mpHeroLookChanged")
}
