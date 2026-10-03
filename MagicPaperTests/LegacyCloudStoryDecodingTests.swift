import XCTest
@testable import MagicPaper

/// Bulut metin yolu kaldırıldı (Faz 9); onun ürettiği masallar kullanıcıların
/// kütüphanesinde duruyor. `origin` alanı yok, sayfalar uzak `imageUrl`
/// taşıyor, yarım kalmış olanlar `generatingImages` durumunda. Hepsi hâlâ
/// çözülmeli ve okuyucuya eşlenmeli.
@MainActor
final class LegacyCloudStoryDecodingTests: XCTestCase {

    private let completedID = UUID()
    private let halfDoneID = UUID()

    private func storyJSON(id: UUID, status: String, progress: String) -> String {
        """
        {"id":"\(id.uuidString)","title":"Ada ve Sihirli Orman","childName":"Ada",
         "theme":"jungle","language":"tr","status":"\(status)",
         "coverImageUrl":"https://example.invalid/cover.jpg",
         "coverImageFileName":"\(id.uuidString)_cover.jpg",
         "currentProgress":"\(progress)","createdAt":780000000.5,
         "pages":[
          {"id":"\(UUID().uuidString)","title":"","text":"Ada ormana girdi.\\n\\nYapraklar fısıldadı.",
           "imagePrompt":"a child in a forest","imageUrl":"\(id.uuidString)-page1.jpg"},
          {"id":"\(UUID().uuidString)","title":"","text":"Işık yolunu gösterdi.",
           "imagePrompt":"a glowing path"}
         ]}
        """
    }

    private var legacyArray: Data {
        let json = "[\(storyJSON(id: completedID, status: "completed", progress: "Tamamlandı!")),"
            + "\(storyJSON(id: halfDoneID, status: "generatingImages", progress: "Sayfa 1/2 çiziliyor..."))]"
        return Data(json.utf8)
    }

    private func assertLegacyShape(_ stories: [Story], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(stories.count, 2, file: file, line: line)
        XCTAssertEqual(stories.map(\.status), [.completed, .generatingImages], file: file, line: line)
        for story in stories {
            XCTAssertNil(story.origin, "Eski bulut masalında origin yok", file: file, line: line)
            XCTAssertEqual(story.coverImageUrl, "https://example.invalid/cover.jpg", file: file, line: line)
            XCTAssertEqual(story.pages.count, 2, file: file, line: line)
            XCTAssertNotNil(story.pages[0].imageUrl, file: file, line: line)
            XCTAssertNil(story.pages[0].imageFileName, file: file, line: line)
        }
    }

    /// `StoryGenerationManager.loadStories` ve `LibraryMigration.readLegacy`
    /// aynı çözücüyü kullanır: UserDefaults'taki `[Story]` yığını.
    func testLegacyBlobDecodesThroughTheLegacyMigrationPath() throws {
        let suite = "LegacyCloudStoryDecodingTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(legacyArray, forKey: "stories")

        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("LegacyCloudStoryDecodingTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let migration = LibraryMigration(defaults: defaults, store: try LibraryFileStore(root: root))

        let snapshot = migration.readLegacy()
        XCTAssertNil(snapshot.failure)
        assertLegacyShape(snapshot.stories)
    }

    func testLegacyBlobDecodesAsTheManagerDecodesIt() throws {
        assertLegacyShape(try JSONDecoder().decode([Story].self, from: legacyArray))
    }

    func testLegacyStoryFileDecodesThroughLibraryFileStore() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("LegacyCloudStoryDecodingTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try LibraryFileStore(root: root)

        let json = Data(storyJSON(id: halfDoneID, status: "generatingImages", progress: "Sayfa 1/2 çiziliyor...").utf8)
        try json.write(to: store.directory(.stories).appendingPathComponent("\(halfDoneID.uuidString).json"))

        let story = try XCTUnwrap(try store.readStory(id: halfDoneID))
        XCTAssertEqual(story.status, .generatingImages)
        XCTAssertNil(story.origin)
        XCTAssertEqual(story.pages[0].imageUrl, "\(halfDoneID.uuidString)-page1.jpg")
        XCTAssertEqual(store.readAllStories().stories.count, 1)
        XCTAssertTrue(store.readAllStories().failures.isEmpty)
    }

    func testLegacyStoriesMapForTheReader() throws {
        let stories = try JSONDecoder().decode([Story].self, from: legacyArray)
        let reader = ReaderFixtures.reader(stories[0])

        XCTAssertEqual(reader.pageCount, 2)
        let pages = reader.leaves.compactMap(\.page)
        XCTAssertEqual(pages.count, 2)
        XCTAssertEqual(pages[0].imageRef, "\(completedID.uuidString)-page1.jpg",
                       "Uzak imageUrl okuyucuya görsel referansı olarak gelir")
        XCTAssertEqual(pages[0].paragraphs, ["Ada ormana girdi.", "Yapraklar fısıldadı."])
        XCTAssertNil(pages[1].imageRef)
    }
}
