import XCTest
@testable import MagicPaper

/// `StoryDecorationContext.seed`: aynı masal, aynı sayfa → her açılışta aynı süs.
final class StoryDecorationSeedTests: XCTestCase {

    private let storyID = UUID(uuidString: "6F9619FF-8B86-D011-B42D-00C04FC964FF")!

    /// Sabitler bu süreçten bağımsız hesaplandı. `hashValue` süreç başına
    /// tohumlandığı için eski uygulama bu testi her çalıştırmada bozardı.
    func testSeedIsAFixedValueAcrossProcesses() {
        XCTAssertEqual(StoryDecorationContext.seed(storyID: storyID, page: 0), 0xd4fe_bfdc_820d_2205)
        XCTAssertEqual(StoryDecorationContext.seed(storyID: storyID, page: 1), 0x76a7_3517_03d3_a63a)
        XCTAssertEqual(StoryDecorationContext.seed(storyID: storyID, page: 2), 0x906f_ab49_8098_2a2f)
    }

    func testPagesOfTheSameStoryGetDifferentSeeds() {
        let seeds = Set((0..<12).map { StoryDecorationContext.seed(storyID: storyID, page: $0) })
        XCTAssertEqual(seeds.count, 12)
    }

    func testStoriesDifferingOnlyInTheirLastBytesGetDifferentSeeds() {
        let other = UUID(uuidString: "6F9619FF-8B86-D011-B42D-00C04FC96500")!
        XCTAssertNotEqual(StoryDecorationContext.seed(storyID: storyID, page: 0),
                          StoryDecorationContext.seed(storyID: other, page: 0))
    }
}
