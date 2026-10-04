import XCTest
@testable import MagicPaper

/// Masal ailem kaydı ve masalın kökeni, geriye dönük (FAZ 11).
///
/// Kaydedilmiş masallar açılmaya devam etmeli: FAZ 11'den önce yazılmış bir
/// `StoryOrigin`'de aile alanları yok ve `nil` olarak çözülmeli.
final class FamilyCharacterDecodingTests: XCTestCase {

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func testAnAnimalKeepsItsKind() throws {
        let pet = FamilyCharacter(childID: UUID(), name: "Boncuk", relation: .animal(kindID: "family_animal_dog"))
        let data = try encoder.encode(pet)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"relation\":\"animal\""), json)
        XCTAssertTrue(json.contains("\"animalKind\":\"family_animal_dog\""), json)
        XCTAssertEqual(try decoder.decode(FamilyCharacter.self, from: data), pet)
    }

    func testEveryRelationRoundTrips() throws {
        for relation in [FamilyRelation.sibling, .friend, .imaginary, .animal(kindID: "family_animal_cat")] {
            let character = FamilyCharacter(childID: UUID(), name: "Ela", relation: relation)
            XCTAssertEqual(try decoder.decode(FamilyCharacter.self, from: encoder.encode(character)), character)
        }
    }

    func testAnUnknownRelationIsRefused() {
        let json = """
        {"id":"\(UUID().uuidString)","childID":"\(UUID().uuidString)","name":"Ela",
         "relation":"grandparent","createdAt":"2026-10-04T10:00:00Z"}
        """
        XCTAssertThrowsError(try decoder.decode(FamilyCharacter.self, from: Data(json.utf8)))
    }

    func testARecordWithoutASchemaVersionReadsAsVersionOne() throws {
        let json = """
        {"id":"\(UUID().uuidString)","childID":"\(UUID().uuidString)","name":"Ela",
         "relation":"sibling","createdAt":"2026-10-04T10:00:00Z"}
        """
        XCTAssertEqual(try decoder.decode(FamilyCharacter.self, from: Data(json.utf8)).schemaVersion, 1)
    }

    /// An origin exactly as FAZ 10 wrote it.
    func testAnOriginWrittenBeforeFaz11StillOpens() throws {
        let json = """
        {"seed":"s","blueprintID":"bp","settingID":"st","companionID":"c","discoveryID":"d",
         "fingerprint":"f","catalogVersion":"2.0.0","modeID":"bedtime","selectionStrategy":"direct",
         "ageBand":"5-6"}
        """
        let origin = try JSONDecoder().decode(StoryOrigin.self, from: Data(json.utf8))
        XCTAssertNil(origin.familyCharacterID)
        XCTAssertNil(origin.familyRelation)
        XCTAssertEqual(origin.mode, .bedtime)
    }

    func testANewOriginKeepsTheCharacterIDAndRelationButNotTheName() throws {
        var origin = StoryOrigin(seed: "s", blueprintID: "bp", settingID: "st", companionID: "c",
                                 discoveryID: "d", fingerprint: "f", catalogVersion: "2.0.0")
        let id = UUID().uuidString
        origin.familyCharacterID = id
        origin.familyRelation = "animal"
        let data = try JSONEncoder().encode(origin)
        let back = try JSONDecoder().decode(StoryOrigin.self, from: data)
        XCTAssertEqual(back.familyCharacterID, id)
        XCTAssertEqual(back.familyRelation, "animal")
    }
}
