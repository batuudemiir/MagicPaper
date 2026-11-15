import Foundation

/// Tek kahraman kimliği (E4, 16 Kasım 2026; CLAUDE.md ilke 5).
///
/// Çocuğun görünüşünün tek kaynağı `HeroLook`. Görselli kitabın parça seçimi
/// (`AvatarSpec`) artık ondan türetilir; ayrıca düzenlenmez. Eşleme tablosu
/// burada ve yalnızca burada.
///
/// | HeroLook | AvatarSpec |
/// |---|---|
/// | ten 0, 1 | `skin_light` |
/// | ten 2 | `skin_olive` |
/// | ten 3, 4 | `skin_brown` |
/// | ten 5 | `skin_dark` |
/// | saç kısa, çok kısa, dikenli, saçsız | `hair_short` |
/// | saç kıvırcık, afro | `hair_curly` |
/// | saç uzun, küt | `hair_shoulder` |
/// | saç at kuyruğu, topuz | `hair_ponytail` |
/// | saç örgü | `hair_braided` |
/// | saç rengi 0 siyah, 1 kahve, 2 kumral, 3 sarı, 4 kızıl, 5 açık sarı | `haircolor_black`, `_brown`, `_auburn`, `_blonde`, `_red`, `_blonde` |
/// | saç rengi 6 mor, 7 mavi | kitte yok: grubun varsayılanı |
/// | üst rengi 0 mavi, 1 yeşil, 2 hardal, 3 mercan, 4 lila, 5 gül, 6 marka moru, 7 mavi | `outfit_blue`, `_green`, `_yellow`, `_orange`, `_purple`, `_red`, `_purple`, `_blue` |
/// | gözlük yuvarlak, köşeli | `acc_glasses` |
/// | bere (gözlük yoksa) | `acc_beanie` |
/// | güneş gözlüğü, öbür başlıklar | aksesuar yok |
///
/// Kitte karşılığı olmayan değer grubun varsayılanına düşer
/// (`AvatarKit.resolved`). Üstün biçimi (tişört, kazak…) taşınmaz: kitte tek
/// biçim var.
///
/// Kitap yazılmayan iki durum, `nil`: hayvan kahraman (sahneye hayvan
/// çizilmez) ve başörtüsü (kitte başörtüsü parçası yok; başörtülü bir çocuğu
/// başörtüsüz çizmek kimliği yanlış çizmek olur). Masal bugünkü gibi metin.
enum HeroBookCharacter {

    static let skinTones: [String] = [
        "skin_light", "skin_light", "skin_olive", "skin_brown", "skin_brown", "skin_dark"
    ]
    static let hairColors: [String?] = [
        "haircolor_black", "haircolor_brown", "haircolor_auburn", "haircolor_blonde",
        "haircolor_red", "haircolor_blonde", nil, nil
    ]
    static let outfits: [String] = [
        "outfit_blue", "outfit_green", "outfit_yellow", "outfit_orange",
        "outfit_purple", "outfit_red", "outfit_purple", "outfit_blue"
    ]

    static func hairStyle(_ hair: HeroLook.Hair) -> String {
        switch hair {
        case .short, .buzz, .spiky, .none: return "hair_short"
        case .curly, .afro: return "hair_curly"
        case .long, .bob: return "hair_shoulder"
        case .ponytail, .buns: return "hair_ponytail"
        case .braids: return "hair_braided"
        }
    }

    static func accessory(_ look: HeroLook) -> String? {
        if look.glasses == .round || look.glasses == .square { return "acc_glasses" }
        if look.headwear == .beanie { return "acc_beanie" }
        return nil
    }

    /// The book character this hero is drawn as, or nil when it is not drawn.
    /// With a kit, the result is resolved against it (unknown parts become the
    /// group's default).
    static func spec(for look: HeroLook, kit: AvatarKit?) -> AvatarSpec? {
        guard look.kind == .child, look.headwear != .hijab else { return nil }
        let raw = AvatarSpec(
            skinTone: pick(skinTones, look.skin) ?? "",
            hairStyle: hairStyle(look.hair),
            hairColor: pick(hairColors, look.hairColor).flatMap { $0 } ?? "",
            outfit: pick(outfits, look.topColor) ?? "",
            accessory: accessory(look))
        return kit?.resolved(raw) ?? raw
    }

    private static func pick<T>(_ table: [T], _ index: Int) -> T? {
        table.indices.contains(index) ? table[index] : nil
    }

    // MARK: - Reverse (one-time migration)

    static let reverseSkin: [String: Int] = ["skin_light": 1, "skin_olive": 2, "skin_brown": 4, "skin_dark": 5]
    static let reverseHair: [String: HeroLook.Hair] = [
        "hair_short": .short, "hair_curly": .curly, "hair_shoulder": .long,
        "hair_ponytail": .ponytail, "hair_braided": .braids
    ]
    static let reverseHairColor: [String: Int] = [
        "haircolor_black": 0, "haircolor_brown": 1, "haircolor_auburn": 2,
        "haircolor_blonde": 3, "haircolor_red": 4
    ]
    static let reverseOutfit: [String: Int] = [
        "outfit_blue": 0, "outfit_green": 1, "outfit_yellow": 2,
        "outfit_orange": 3, "outfit_purple": 4, "outfit_red": 5
    ]

    /// The hero a parent's saved book character describes. Only identity and
    /// the free parts: a beanie costs stars and is not handed out by a
    /// migration, a backpack has no hero part.
    static func look(from spec: AvatarSpec, kit: AvatarKit?) -> HeroLook {
        let r = kit?.resolved(spec) ?? spec
        let standard = HeroLook.standard
        var look = HeroLook()
        look.skin = reverseSkin[r.skinTone] ?? standard.skin
        look.hair = reverseHair[r.hairStyle] ?? standard.hair
        look.hairColor = reverseHairColor[r.hairColor] ?? standard.hairColor
        look.topColor = reverseOutfit[r.outfit] ?? standard.topColor
        if r.accessory == "acc_glasses" { look.glasses = .round }
        return look
    }
}

/// Where the illustrated book reads the child's character from.
///
/// The hero first. A child with a hero record but no drawable character (an
/// animal, a hijab) gets a text book: the old `AvatarSpec` is not used to
/// draw someone the child no longer is. Only an install that never made a
/// hero falls back to the saved book character.
@MainActor
struct BookCharacterSource {
    var heroes: HeroLookStore = HeroLookStore()
    var avatars: AvatarStore = AvatarStore()
    var kit: AvatarKit? = .bundled

    func avatar(for profileID: UUID) async -> AvatarSpec? {
        if let look = heroes.look(for: profileID) {
            return HeroBookCharacter.spec(for: look, kit: kit)
        }
        return await avatars.avatar(for: profileID)
    }
}

/// The one-time move of a parent's saved book character into the hero.
///
/// Only when the profile has an `AvatarSpec` and no `HeroLook`: an existing
/// hero is never written over. The migrated hero is marked, so the account
/// sync lets any hero the child made on another device win over it
/// (`HeroLookStore.isUnchangedSinceMigration`).
@MainActor
struct HeroIdentityMigration {
    var heroes: HeroLookStore = HeroLookStore()
    var avatars: AvatarStore = AvatarStore()
    var kit: AvatarKit? = .bundled

    /// Returns whether a hero was made.
    @discardableResult
    func migrateIfNeeded(profileID: UUID) async -> Bool {
        guard heroes.look(for: profileID) == nil,
              let spec = await avatars.avatar(for: profileID) else { return false }
        // Read again after the await: something may have saved a hero meanwhile.
        guard heroes.look(for: profileID) == nil else { return false }
        let look = HeroBookCharacter.look(from: spec, kit: kit)
        heroes.save(look, for: profileID)
        heroes.markMigrated(look, for: profileID)
        return true
    }

    func run(profileIDs: [UUID]) async {
        for id in profileIDs { await migrateIfNeeded(profileID: id) }
    }
}
