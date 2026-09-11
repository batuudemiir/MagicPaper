import XCTest
@testable import CharacterEngine

final class CharacterResolverTests: XCTestCase {
    func testResolvesCastAndPinsVersion() async throws {
        let profile = CharacterFixtures.profile()
        let resolver = CharacterResolver(store: InMemoryCharacterStore([profile]))

        let cast = try await resolver.resolveCast(for: CastBinding(protagonist: profile.id))

        XCTAssertEqual(cast.protagonist.characterID, profile.id)
        XCTAssertEqual(cast.protagonist.versionID, profile.activeVersionID)
        XCTAssertEqual(cast.protagonist.displayName, "Deniz")
        XCTAssertEqual(cast.protagonist.role, .protagonist)
        XCTAssertTrue(cast.supporting.isEmpty)
        XCTAssertEqual(cast.all.count, 1)
    }

    func testResolvesSupportingCharacters() async throws {
        let hero = CharacterFixtures.profile(displayName: "Deniz")
        let friend = CharacterFixtures.profile(displayName: "Pamuk")
        let resolver = CharacterResolver(store: InMemoryCharacterStore([hero, friend]))

        let binding = CastBinding(members: [
            .init(characterID: hero.id, role: .protagonist),
            .init(characterID: friend.id, role: .companion)
        ])
        let cast = try await resolver.resolveCast(for: binding)

        XCTAssertEqual(cast.supporting.map(\.displayName), ["Pamuk"])
        XCTAssertEqual(cast.character(id: friend.id)?.role, .companion)
    }

    func testMissingProfileThrows() async {
        let resolver = CharacterResolver(store: InMemoryCharacterStore())
        let ghost = CharacterID()

        do {
            _ = try await resolver.resolveCast(for: CastBinding(protagonist: ghost))
            XCTFail("Expected profileNotFound")
        } catch {
            XCTAssertEqual(error as? CharacterEngineError, .profileNotFound(ghost))
        }
    }

    func testEmptyCastThrows() async {
        let resolver = CharacterResolver(store: InMemoryCharacterStore())
        do {
            _ = try await resolver.resolveCast(for: CastBinding(members: []))
            XCTFail("Expected emptyCast")
        } catch {
            XCTAssertEqual(error as? CharacterEngineError, .emptyCast)
        }
    }

    func testTwoProtagonistsThrow() async {
        let a = CharacterFixtures.profile(displayName: "Deniz")
        let b = CharacterFixtures.profile(displayName: "Ada")
        let resolver = CharacterResolver(store: InMemoryCharacterStore([a, b]))
        let binding = CastBinding(members: [
            .init(characterID: a.id, role: .protagonist),
            .init(characterID: b.id, role: .protagonist)
        ])

        do {
            _ = try await resolver.resolveCast(for: binding)
            XCTFail("Expected duplicateCastRole")
        } catch {
            XCTAssertEqual(error as? CharacterEngineError, .duplicateCastRole("protagonist"))
        }
    }
}
