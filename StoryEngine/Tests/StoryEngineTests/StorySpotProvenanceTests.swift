import XCTest
@testable import StoryEngine

final class StorySpotProvenanceTests: XCTestCase {
    func testAuthoredTextAndSubjectSemanticsArePinned() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let object = try XCTUnwrap(catalog.objects.first)
        let source = AuthoredSourceFingerprint.Source(templateID: "template", variantID: "variant", text: "raw source")
        let original = AuthoredSourceFingerprint.make(sources: [source], discovery: object)
        XCTAssertEqual(original, AuthoredSourceFingerprint.make(sources: [source], discovery: object))
        XCTAssertNotEqual(original, AuthoredSourceFingerprint.make(sources: [.init(templateID: "template", variantID: "variant", text: "changed")], discovery: object))
        let encoded = try JSONEncoder().encode(object)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json["name"] = object.name + " changed"
        let changed = try JSONDecoder().decode(CatalogObject.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNotEqual(original, AuthoredSourceFingerprint.make(sources: [source], discovery: changed))
        json["name"] = object.name
        json["traits"] = object.traits.isEmpty ? ["isVisible"] : []
        let changedTraits = try JSONDecoder().decode(CatalogObject.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNotEqual(original, AuthoredSourceFingerprint.make(sources: [source], discovery: changedTraits))
    }

    func testRealCompositionPinsSourcesAndRecallClearsPin() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let intent = OfflineStoryIntent(childName: "Yeliz", seed: "spot-provenance")
        let first = try OfflineStoryComposer().compose(catalog: catalog, intent: intent)
        let second = try OfflineStoryComposer().compose(catalog: catalog, intent: intent)
        XCTAssertEqual(first.pages.map(\.authoredSourceFingerprint), second.pages.map(\.authoredSourceFingerprint))
        let page = try XCTUnwrap(first.pages.first)
        XCTAssertNotNil(page.authoredSourceFingerprint)
        XCTAssertNil(page.appendingRecall(id: ContentID("recall"), text: "Hatırladı.").authoredSourceFingerprint)
    }
}
