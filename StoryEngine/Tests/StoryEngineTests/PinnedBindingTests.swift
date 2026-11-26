import XCTest
@testable import StoryEngine

final class PinnedBindingTests: XCTestCase {
    func testPinnedBindingKeepsAllThreeIdentities() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let blueprint = try XCTUnwrap(catalog.blueprint("blueprint_threshold_crossing_001"))
        let intent = OfflineStoryIntent(childName: "Deniz", settingID: "setting_whispering_forest_001",
            companionID: "companion_hedgehog_pilot_001", discoveryID: "object_torn_map_001", seed: "pinned-source")
        let a = try OfflineContentBinder().bind(blueprint: blueprint, catalog: catalog, intent: intent)
        let b = try OfflineContentBinder().bind(blueprint: blueprint, catalog: catalog, intent: intent)
        XCTAssertEqual(a.setting.id, intent.settingID)
        XCTAssertEqual(a.companion.id, intent.companionID)
        XCTAssertEqual(a.discovery.id, intent.discoveryID)
        XCTAssertEqual(a.castRole, b.castRole)
    }

    func testRejectedPinnedCompanionIsExplainedInsteadOfSubstituted() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let blueprint = try XCTUnwrap(catalog.blueprint("blueprint_threshold_crossing_001"))
        let intent = OfflineStoryIntent(childName: "Deniz", settingID: "setting_whispering_forest_001",
            companionID: "companion_bear_001", discoveryID: "object_torn_map_001", seed: "pinned-source")
        XCTAssertThrowsError(try OfflineContentBinder().bind(blueprint: blueprint, catalog: catalog, intent: intent)) {
            guard case OfflineSelectionError.requestedContentRejected(let id, let reason) = $0 else {
                return XCTFail("Expected a rejected explicit choice")
            }
            XCTAssertEqual(id, intent.companionID)
            XCTAssertTrue(reason.contains("canCarry"))
        }
    }
}
