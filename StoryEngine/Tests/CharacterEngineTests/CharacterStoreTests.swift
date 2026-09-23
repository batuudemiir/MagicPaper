import XCTest
@testable import CharacterEngine

/// The `CharacterStore` lifecycle: create, persist, reload, update, delete.
///
/// `InMemoryCharacterStore` is the reference implementation of the protocol,
/// so these are the rules every real store has to satisfy too. The app is
/// about to grow a second one (`FileCharacterStore`, on disk under
/// `Documents/StoryEngine/Characters`), and this is the contract it must meet.
final class CharacterStoreTests: XCTestCase {

    // MARK: - Create and reload

    func testSavedProfileReloads() async throws {
        let store = InMemoryCharacterStore()
        let profile = CharacterFixtures.profile()

        try await store.save(profile)
        let reloaded = try await store.profile(id: profile.id)

        XCTAssertEqual(reloaded, profile)
    }

    func testUnknownProfileIsNilRatherThanAnError() async throws {
        let store = InMemoryCharacterStore()
        let missing = try await store.profile(id: CharacterID())
        XCTAssertNil(missing)
    }

    func testSeededProfilesAreReadable() async throws {
        let profile = CharacterFixtures.profile()
        let store = InMemoryCharacterStore([profile])
        let loaded = try await store.profile(id: profile.id)
        XCTAssertEqual(loaded, profile)
    }

    // MARK: - Update

    /// Saving under an existing id replaces, it does not duplicate.
    func testSavingAgainReplacesInPlace() async throws {
        let store = InMemoryCharacterStore()
        let profile = CharacterFixtures.profile()
        try await store.save(profile)

        let second = CharacterFixtures.version(number: 2)
        try await store.save(profile.appending(second))

        let reloaded = try await XCTUnwrapAsync(await store.profile(id: profile.id))
        XCTAssertEqual(reloaded.versions.count, 2)
        XCTAssertEqual(reloaded.activeVersionID, second.id)
        let owned = try await store.allProfiles(ownedBy: CharacterFixtures.ownerID)
        XCTAssertEqual(owned.count, 1)
    }

    /// An update appends. The snapshot a book was drawn against stays readable,
    /// which is the whole reason versions are append-only.
    func testUpdateKeepsEarlierVersionsResolvable() async throws {
        let store = InMemoryCharacterStore()
        let original = CharacterFixtures.profile()
        let originalVersionID = try XCTUnwrap(original.activeVersion?.id)
        try await store.save(original)

        try await store.save(original.appending(CharacterFixtures.version(number: 2)))

        let reloaded = try await XCTUnwrapAsync(await store.profile(id: original.id))
        XCTAssertNotNil(reloaded.version(id: originalVersionID))
    }

    // MARK: - Delete

    func testDeleteRemovesTheProfile() async throws {
        let store = InMemoryCharacterStore()
        let profile = CharacterFixtures.profile()
        try await store.save(profile)

        try await store.delete(id: profile.id)

        let gone = try await store.profile(id: profile.id)
        XCTAssertNil(gone)
    }

    /// The protocol says so explicitly: deleting something already gone must
    /// succeed. A delete that throws on a second attempt turns a retried
    /// "remove this child" into an error the parent cannot resolve.
    func testDeletingTwiceSucceeds() async throws {
        let store = InMemoryCharacterStore()
        let profile = CharacterFixtures.profile()
        try await store.save(profile)

        try await store.delete(id: profile.id)
        try await store.delete(id: profile.id)
        try await store.delete(id: CharacterID())
    }

    func testDeleteLeavesOtherProfilesAlone() async throws {
        let store = InMemoryCharacterStore()
        let kept = CharacterFixtures.profile(displayName: "Deniz")
        let removed = CharacterFixtures.profile(displayName: "Ada")
        try await store.save(kept)
        try await store.save(removed)

        try await store.delete(id: removed.id)

        let remaining = try await store.allProfiles(ownedBy: CharacterFixtures.ownerID)
        XCTAssertEqual(remaining.map(\.displayName), ["Deniz"])
    }

    // MARK: - Ownership

    /// Characters are listed per family profile. A second family on the same
    /// device must not see the first one's children.
    func testProfilesAreScopedToTheirOwner() async throws {
        let store = InMemoryCharacterStore()
        let mine = CharacterFixtures.profile()
        let theirVersion = CharacterFixtures.version()
        let theirs = CharacterProfile(
            ownerProfileID: UUID(),
            displayName: "Başkasının çocuğu",
            versions: [theirVersion],
            activeVersionID: theirVersion.id,
            createdAt: CharacterFixtures.referenceDate
        )
        try await store.save(mine)
        try await store.save(theirs)

        let owned = try await store.allProfiles(ownedBy: CharacterFixtures.ownerID)
        XCTAssertEqual(owned.map(\.id), [mine.id])
    }

    func testProfilesAreOrderedByCreation() async throws {
        let store = InMemoryCharacterStore()
        let olderVersion = CharacterFixtures.version()
        let older = CharacterProfile(
            ownerProfileID: CharacterFixtures.ownerID,
            displayName: "Önce",
            versions: [olderVersion],
            activeVersionID: olderVersion.id,
            createdAt: CharacterFixtures.referenceDate
        )
        let newerVersion = CharacterFixtures.version()
        let newer = CharacterProfile(
            ownerProfileID: CharacterFixtures.ownerID,
            displayName: "Sonra",
            versions: [newerVersion],
            activeVersionID: newerVersion.id,
            createdAt: CharacterFixtures.referenceDate.addingTimeInterval(60)
        )

        try await store.save(newer)
        try await store.save(older)

        let owned = try await store.allProfiles(ownedBy: CharacterFixtures.ownerID)
        XCTAssertEqual(owned.map(\.displayName), ["Önce", "Sonra"])
    }
}

/// `XCTUnwrap` cannot take an `await` expression inside an autoclosure.
func XCTUnwrapAsync<T>(_ value: T?, file: StaticString = #filePath, line: UInt = #line) throws -> T {
    try XCTUnwrap(value, file: file, line: line)
}
