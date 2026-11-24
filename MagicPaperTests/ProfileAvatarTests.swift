import XCTest
@testable import MagicPaper

/// Profil avatarı (23 Kasım 2026): katalog, görseller ve kayıt.
final class ProfileAvatarTests: XCTestCase {

    func testEveryAvatarHasItsPicture() {
        for avatar in ProfileAvatar.all {
            XCTAssertNotNil(UIImage(named: avatar.asset), "\(avatar.id) görseli yok")
        }
    }

    func testIdsAreUniqueAndEveryCharacterHasFaces() {
        let ids = ProfileAvatar.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        for character in ProfileAvatar.Character.allCases {
            XCTAssertFalse(ProfileAvatar.of(character).isEmpty, character.title)
        }
    }

    func testTheAvatarRoundTripsInsideTheHero() throws {
        let look = HeroLook(skin: 3, avatar: "tarcin-standing")
        let decoded = try JSONDecoder().decode(HeroLook.self, from: JSONEncoder().encode(look))
        XCTAssertEqual(decoded.avatar, "tarcin-standing")
        XCTAssertEqual(ProfileAvatar.named(decoded.avatar)?.character, .tarcin)
    }

    func testAnOldHeroHasNoAvatarAndAnUnknownOneIsIgnored() throws {
        let old = try JSONDecoder().decode(HeroLook.self, from: Data(#"{"kind":"child","skin":2}"#.utf8))
        XCTAssertNil(old.avatar)
        XCTAssertNil(ProfileAvatar.named("silinmis-avatar"))
        XCTAssertNil(ProfileAvatar.named(nil))
    }

    func testRagiIsTheMascotNeverTheChildsPicture() {
        XCTAssertTrue(ProfileAvatar.all.allSatisfy { !$0.id.hasPrefix("ragi-") })
        XCTAssertNil(ProfileAvatar.named("ragi-happy"))   // eski seçim boş resme düşer
    }
}
