import XCTest
@testable import MagicPaper

/// Masal ailem deposu (FAZ 11): çocuk başına bir dosya, kayıplı okuma, üst sınır.
///
/// Her test kendi alt klasöründe çalışır ve onu siler; gerçek
/// `FamilyCharacters` klasörüne dokunmaz.
final class FamilyCharacterStoreTests: XCTestCase {

    private var subdirectory = ""
    private var store: FamilyCharacterStore { FamilyCharacterStore(subdirectory: subdirectory) }

    override func setUp() {
        super.setUp()
        subdirectory = "FamilyCharactersTest-\(UUID().uuidString)"
    }

    override func tearDown() {
        store.eraseAll()
        super.tearDown()
    }

    private func character(_ name: String, child: UUID, relation: FamilyRelation = .sibling,
                           at offset: TimeInterval = 0) -> FamilyCharacter {
        FamilyCharacter(childID: child, name: name, relation: relation,
                        createdAt: Date(timeIntervalSince1970: 1_800_000_000 + offset))
    }

    func testASavedCharacterComesBack() throws {
        let child = UUID()
        let ela = character("Ela", child: child)
        try store.save(ela)
        XCTAssertEqual(store.characters(for: child), [ela])
    }

    func testCharactersComeBackInTheOrderTheyWereAdded() throws {
        let child = UUID()
        let second = character("Deniz", child: child, at: 20)
        let first = character("Ela", child: child, at: 10)
        try store.save(second)
        try store.save(first)
        XCTAssertEqual(store.characters(for: child).map(\.name), ["Ela", "Deniz"])
    }

    func testSavingTheSameIDReplacesInsteadOfAdding() throws {
        let child = UUID()
        var ela = character("Ela", child: child)
        try store.save(ela)
        ela.name = "Elif"
        ela.relation = .friend
        try store.save(ela)
        XCTAssertEqual(store.characters(for: child), [ela])
    }

    func testChildrenDoNotSeeEachOthersCharacters() throws {
        let yeliz = UUID(), demir = UUID()
        try store.save(character("Ela", child: yeliz))
        try store.save(character("Pamuk", child: demir, relation: .animal(kindID: "family_animal_cat")))
        XCTAssertEqual(store.characters(for: yeliz).map(\.name), ["Ela"])
        XCTAssertEqual(store.characters(for: demir).map(\.name), ["Pamuk"])
    }

    func testTheNinthCharacterIsRefused() throws {
        let child = UUID()
        for index in 0..<FamilyCharacter.maxPerChild {
            try store.save(character("Ad\(index)", child: child, at: TimeInterval(index)))
        }
        XCTAssertThrowsError(try store.save(character("Fazla", child: child))) { error in
            XCTAssertEqual(error as? FamilyCharacterStore.Failure, .limitReached)
        }
        XCTAssertEqual(store.characters(for: child).count, FamilyCharacter.maxPerChild)
    }

    func testDeletingOneLeavesTheRest() throws {
        let child = UUID()
        let ela = character("Ela", child: child)
        let deniz = character("Deniz", child: child, at: 1)
        try store.save(ela)
        try store.save(deniz)
        try store.delete(id: ela.id, childID: child)
        XCTAssertEqual(store.characters(for: child), [deniz])
    }

    func testDeletingAChildsCharactersLeavesTheirSiblings() throws {
        let yeliz = UUID(), demir = UUID()
        try store.save(character("Ela", child: yeliz))
        try store.save(character("Can", child: demir))
        store.delete(for: yeliz)
        XCTAssertEqual(store.characters(for: yeliz), [])
        XCTAssertEqual(store.characters(for: demir).map(\.name), ["Can"])
    }

    func testEraseAllRemovesEveryChild() throws {
        let yeliz = UUID(), demir = UUID()
        try store.save(character("Ela", child: yeliz))
        try store.save(character("Can", child: demir))
        store.eraseAll()
        XCTAssertEqual(store.characters(for: yeliz), [])
        XCTAssertEqual(store.characters(for: demir), [])
    }

    /// A record written by a newer version (a relation this build does not
    /// know) is skipped; the rest of the child's list survives.
    func testAnUnknownRecordDoesNotTakeTheFileWithIt() throws {
        let child = UUID()
        let ela = character("Ela", child: child)
        try store.save(ela)
        let url = try XCTUnwrap(StoryEngineStorage.directory(subdirectory))
            .appendingPathComponent("\(child.uuidString).json")
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        var list = try XCTUnwrap(json["characters"] as? [[String: Any]])
        var future = list[0]
        future["id"] = UUID().uuidString
        future["relation"] = "grandparent"
        list.append(future)
        json["characters"] = list
        try JSONSerialization.data(withJSONObject: json).write(to: url)

        XCTAssertEqual(store.characters(for: child), [ela])
    }

    func testAnUnreadableFileReadsAsEmptyNotACrash() throws {
        let child = UUID()
        let url = try XCTUnwrap(StoryEngineStorage.directory(subdirectory))
            .appendingPathComponent("\(child.uuidString).json")
        try Data("not json".utf8).write(to: url)
        XCTAssertEqual(store.characters(for: child), [])
    }
}
