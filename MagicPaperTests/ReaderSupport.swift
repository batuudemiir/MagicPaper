import Foundation
@testable import MagicPaper

/// Okuyucu testleri için masal kurma yardımcıları.
///
/// Tek yerde, çünkü üç test dosyası da aynı şekle ihtiyaç duyuyor ve her birinde
/// ayrı ayrı kurmak üç farklı "tipik masal" tanımı üretirdi.
enum ReaderFixtures {

    /// `count` sayfalık metin masalı — ürünün bugün ürettiği şey.
    static func textStory(pages count: Int, title: String = "Yeliz ve Küçük Işık") -> Story {
        Story(
            title: title,
            childName: "Yeliz",
            childProfileID: UUID(),
            theme: .jungle,
            language: .turkish,
            status: .completed,
            pages: (0..<count).map { index in
                StoryPage(
                    title: "",
                    text: "Bu \(index + 1). sayfanın metni.\n\n“Bu da ne?” diye fısıldadı.",
                    imagePrompt: "child pausing mid-step at the edge of the place"
                )
            }
        )
    }

    /// Her sayfası çizilmiş masal.
    static func illustratedStory(pages count: Int) -> Story {
        Story(
            title: "Çizimli Masal",
            childName: "Yeliz",
            childProfileID: UUID(),
            theme: .space,
            language: .turkish,
            status: .completed,
            pages: (0..<count).map { index in
                StoryPage(
                    title: "",
                    text: "Sayfa \(index + 1).",
                    imagePrompt: "a scene",
                    imageFileName: "page-\(index).jpg",
                    imageUrl: "page-\(index).jpg"
                )
            }
        )
    }

    /// Bazı sayfası çizilmiş, bazısı değil.
    static func mixedStory() -> Story {
        Story(
            title: "Karışık",
            childName: "Yeliz",
            theme: .custom,
            language: .turkish,
            status: .completed,
            pages: [
                StoryPage(title: "", text: "Görselli.", imagePrompt: "x", imageFileName: "a.jpg"),
                StoryPage(title: "", text: "Görselsiz.", imagePrompt: "y"),
                StoryPage(title: "", text: "Boş dosya adı.", imagePrompt: "z", imageFileName: "")
            ]
        )
    }

    static func reader(_ story: Story) -> ReaderStory { ReaderStory(from: story) }
}

/// Diske hiç dokunmayan ilerleme deposu.
@MainActor
final class SpyProgressStore: ReaderProgressStore {
    private(set) var writes: [(storyID: UUID, page: Int)] = []

    func saveProgress(storyID: UUID, page: Int) {
        writes.append((storyID, page))
    }

    var lastWrittenPage: Int? { writes.last?.page }
    var writeCount: Int { writes.count }
}
