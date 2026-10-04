import XCTest
@testable import MagicPaper

/// Profil silinince o çocuğun Masal ailem'i de gider (FAZ 11, kabul kriteri).
///
/// Gerçek `ProfileManager.deleteProfile` üzerinden: zincire eklenen satır
/// silinirse bu test kırmızıya döner. Profil listesi ve ilgili UserDefaults
/// değerleri test boyunca saklanıp sonunda geri yazılır.
@MainActor
final class FamilyCharacterDeletionTests: XCTestCase {

    private let profilesKey = "user_profiles"
    private let currentKey = "current_profile_id"

    func testDeletingAProfileErasesOnlyThatChildsCharacters() throws {
        let manager = ProfileManager.shared
        let savedProfiles = manager.profiles
        let savedCurrent = manager.currentProfile
        let savedData = UserDefaults.standard.data(forKey: profilesKey)
        let savedCurrentID = UserDefaults.standard.string(forKey: currentKey)
        let store = FamilyCharacterStore()

        let leaving = UserProfile(name: "Test Gider", age: 6, profileType: .child)
        let staying = UserProfile(name: "Test Kalır", age: 6, profileType: .child)
        defer {
            store.delete(for: leaving.id)
            store.delete(for: staying.id)
            manager.profiles = savedProfiles
            manager.currentProfile = savedCurrent
            UserDefaults.standard.set(savedData, forKey: profilesKey)
            UserDefaults.standard.set(savedCurrentID, forKey: currentKey)
        }

        manager.profiles = savedProfiles + [leaving, staying]
        try store.save(FamilyCharacter(childID: leaving.id, name: "Ela", relation: .sibling))
        try store.save(FamilyCharacter(childID: staying.id, name: "Can", relation: .friend))

        let result = manager.deleteProfile(leaving)
        if case .failure = result { return XCTFail("deleteProfile refused") }

        XCTAssertEqual(store.characters(for: leaving.id), [])
        XCTAssertEqual(store.characters(for: staying.id).map(\.name), ["Can"])
    }
}
