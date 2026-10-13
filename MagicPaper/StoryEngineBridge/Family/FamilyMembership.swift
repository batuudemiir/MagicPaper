import Foundation

// MARK: - Aile üyeliği (FAZ 18)
//
// Aile `families/{familyID}`: `familyID` kurucu ebeveynin uid'i. Kurucu
// ailenin tek yöneticisidir. Davetle katılan yetişkinler ya ebeveyn (masal
// yazar, okur, ses kaydeder, paylaşır) ya da sadece okuma rolündedir.
// Kurallar: `firebase/firestore.rules`, testleri `firebase/tests/family.test.mjs`.

enum FamilyRole: String, Codable, CaseIterable, Sendable {
    /// Ailenin kurucusu. Tek yönetici; devredilmez (bu sürümde).
    case admin
    case parent
    case reader

    var title: String {
        switch self {
        case .admin:  return "Yönetici"
        case .parent: return "Ebeveyn"
        case .reader: return "Sadece okuma"
        }
    }

    /// Satırdaki "Yönetici · abonelik, onaylar, güvenlik" açıklaması.
    var summary: String {
        switch self {
        case .admin:  return "abonelik, onaylar, güvenlik"
        case .parent: return "masallar, okuma ve ses kaydı"
        case .reader: return "paylaşılan masallar"
        }
    }

    /// Aile kayıtlarını yazabilir mi (masal, profil, ilerleme, ses).
    var canWrite: Bool { self != .reader }

    /// Davetle verilebilen roller.
    static let invitable: [FamilyRole] = [.parent, .reader]
}

/// Bu cihazdaki hesabın hangi ailede, hangi rolde olduğu.
struct FamilyMembership: Codable, Equatable, Sendable {
    let familyID: String
    let role: FamilyRole

    /// Hesap kendi ailesinin kurucusu.
    static func founder(_ uid: String) -> FamilyMembership { FamilyMembership(familyID: uid, role: .admin) }

    var isFounder: Bool { role == .admin }
}

/// Ailedeki bir yetişkin.
struct FamilyMember: Identifiable, Equatable, Sendable {
    let uid: String
    let displayName: String
    let role: FamilyRole
    var id: String { uid }
}

/// Kurucunun yazdığı davet. Kod tek kullanımlık, 7 gün geçerli.
struct FamilyInvite: Identifiable, Equatable, Sendable {
    let code: String
    let familyID: String
    let role: FamilyRole
    let inviterName: String
    let expiresAt: Date
    var id: String { code }

    func isValid(at now: Date = Date()) -> Bool { expiresAt > now }
}

enum FamilyInviteCode {
    /// Karışmayan harf ve rakamlar: I, O, 0, 1 yok (kurallardaki desenle aynı).
    static let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
    static let length = 8
    static let lifetime: TimeInterval = 7 * 86_400

    static func make<G: RandomNumberGenerator>(using generator: inout G) -> String {
        String((0..<length).map { _ in alphabet.randomElement(using: &generator)! })
    }

    static func make() -> String {
        var generator = SystemRandomNumberGenerator()
        return make(using: &generator)
    }

    /// Ebeveynin yazdığını kod biçimine getirir: boşluk ve tire atılır,
    /// küçük harf büyür. Geçersizse nil.
    static func normalize(_ text: String) -> String? {
        let cleaned = text.uppercased(with: Locale(identifier: "en_US_POSIX"))
            .filter { !$0.isWhitespace && $0 != "-" }
        guard cleaned.count == length, cleaned.allSatisfy({ alphabet.contains($0) }) else { return nil }
        return cleaned
    }

    /// `magicpaper://invite/ABCD2345` ya da `https://…/i/ABCD2345`.
    static func from(url: URL) -> String? {
        let parts = url.pathComponents.filter { $0 != "/" }
        if url.scheme == "magicpaper", url.host == "invite", let code = parts.first { return normalize(code) }
        if parts.count == 2, parts[0] == "i" { return normalize(parts[1]) }
        return nil
    }

    static func link(_ code: String) -> URL {
        URL(string: "https://magicpaper-393a7.web.app/i/\(code)")!
    }

    /// Paylaşım sayfasına giden metin.
    static func message(code: String, inviterName: String) -> String {
        "\(inviterName) seni MagicPaper'da ailesine davet etti. Uygulamada Ayarlar > Aile üyeleri > Davet kodum var bölümüne bu kodu yaz: \(code)\n\(link(code).absoluteString)"
    }
}

/// Ailenin üyelik tarafı, sunucu arkada.
protocol FamilyDirectory: Sendable {
    /// Hesabın katıldığı aile; nil ise hesap kendi ailesinin kurucusudur.
    func membership(for uid: String) async throws -> FamilyMembership?
    func members(of familyID: String) async throws -> [FamilyMember]
    /// Kurucunun kendi satırı (görünen adıyla); yoksa yazar.
    func ensureFounder(familyID: String, displayName: String) async throws
    func createInvite(familyID: String, role: FamilyRole, inviterName: String, now: Date) async throws -> FamilyInvite
    func invites(of familyID: String) async throws -> [FamilyInvite]
    func invite(code: String) async throws -> FamilyInvite?
    func deleteInvite(code: String) async throws
    /// Daveti tüketerek katılır (tek yazım).
    func accept(_ invite: FamilyInvite, uid: String, displayName: String) async throws
    func setRole(_ role: FamilyRole, for uid: String, in familyID: String) async throws
    /// Kurucu çıkarır ya da üye kendisi ayrılır.
    func remove(uid: String, from familyID: String) async throws
    /// Kurucunun hesabı silinirken: üyeler, üyelikleri ve davetler.
    func dissolve(familyID: String) async throws
}

/// Üyelik bilgisi olmayan derlemeler ve testler için: herkes kendi ailesinin kurucusu.
struct SoloFamilyDirectory: FamilyDirectory {
    func membership(for uid: String) async throws -> FamilyMembership? { nil }
    func members(of familyID: String) async throws -> [FamilyMember] { [] }
    func ensureFounder(familyID: String, displayName: String) async throws {}
    func createInvite(familyID: String, role: FamilyRole, inviterName: String, now: Date) async throws -> FamilyInvite {
        throw AccountError.failed
    }
    func invites(of familyID: String) async throws -> [FamilyInvite] { [] }
    func invite(code: String) async throws -> FamilyInvite? { nil }
    func deleteInvite(code: String) async throws {}
    func accept(_ invite: FamilyInvite, uid: String, displayName: String) async throws { throw AccountError.failed }
    func setRole(_ role: FamilyRole, for uid: String, in familyID: String) async throws {}
    func remove(uid: String, from familyID: String) async throws {}
    func dissolve(familyID: String) async throws {}
}

/// Üyeliğin cihazdaki kopyası: çevrimdışı açılışta doğru aileyi eşitlemek için.
struct FamilyMembershipCache {
    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    private func key(_ uid: String) -> String { "mp_family_membership_\(uid)" }

    func load(for uid: String) -> FamilyMembership? {
        guard let data = defaults.data(forKey: key(uid)) else { return nil }
        return try? JSONDecoder().decode(FamilyMembership.self, from: data)
    }

    func save(_ membership: FamilyMembership, for uid: String) {
        defaults.set(try? JSONEncoder().encode(membership), forKey: key(uid))
    }

    func clear(for uid: String) { defaults.removeObject(forKey: key(uid)) }
}
