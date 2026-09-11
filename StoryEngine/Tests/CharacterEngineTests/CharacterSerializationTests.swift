import XCTest
@testable import CharacterEngine

final class CharacterSerializationTests: XCTestCase {
    private func roundTrip<T: Codable & Equatable>(_ value: T, file: StaticString = #filePath, line: UInt = #line) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(T.self, from: encoder.encode(value))
        XCTAssertEqual(decoded, value, file: file, line: line)
    }

    func testProfileRoundTrips() throws {
        try roundTrip(CharacterFixtures.profile())
    }

    func testProfileWithFullAssetSetRoundTrips() throws {
        let assetSet = CharacterAssetSet(
            masterReference: CharacterFixtures.asset(role: .master),
            fullBodyReference: CharacterFixtures.asset(role: .fullBody, locator: "body.jpg"),
            faceReference: CharacterFixtures.asset(role: .face, locator: "face.jpg"),
            expressionReferences: [
                .happy: CharacterFixtures.asset(role: .expression, locator: "happy.jpg"),
                .sleepy: CharacterFixtures.asset(role: .expression, locator: "sleepy.jpg")
            ],
            identitySeed: 99,
            stylePresetID: "magic_paper_v1"
        )
        try roundTrip(CharacterFixtures.profile(versions: [CharacterFixtures.version(assetSet: assetSet)]))
    }

    func testIdentifiersEncodeAsBareStrings() throws {
        let data = try JSONEncoder().encode(["id": CharacterID(UUID(uuidString: "22222222-2222-2222-2222-222222222222")!)])
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, #"{"id":"22222222-2222-2222-2222-222222222222"}"#)
    }

    func testLexiconRoundTrips() throws {
        let lexicon = DescriptorLexicon(languageCode: "en", phrases: [.hair: ["red hair"], .eyes: ["green eyes"]])
        let data = try JSONEncoder().encode(lexicon)
        let decoded = try JSONDecoder().decode(DescriptorLexicon.self, from: data)
        XCTAssertEqual(decoded.phrases, lexicon.phrases)
        XCTAssertEqual(decoded.languageCode, "en")
    }

    func testSchemaVersionIsPersisted() throws {
        let data = try JSONEncoder().encode(CharacterFixtures.profile())
        let object = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["schemaVersion"] as? Int, CharacterProfile.currentSchemaVersion)
    }
}
