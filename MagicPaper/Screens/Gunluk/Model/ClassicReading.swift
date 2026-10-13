import Foundation

/// Bir Günlük masalını mevcut okuyucuya (`StoryReaderView`) veren köprü.
///
/// Okuyucu `Story` okur; Günlük masalı için geçici bir `Story` kurulur.
/// Kaydedilmez: çocuğun Kitaplık'ına girmez. `origin` boş, çünkü motor
/// yazmadı — okuma olayları (`ReadingEvent`) ve motorun öğrenme defteri
/// onu kendiliğinden dışarıda bırakır. Okuma serisi ise her okumayı sayar.
enum ClassicReading {

    static func story(
        for tale: ClassicTale,
        narration: ClassicNarration,
        childID: UUID?,
        childName: String,
        savedPage: Int?
    ) -> Story {
        let pages = tale.text(narration).pages.map {
            StoryPage(title: "", text: $0, imagePrompt: "")
        }
        var story = Story(
            id: tale.id, title: tale.title, childName: childName, childProfileID: childID,
            theme: .fantasy, language: .turkish, status: .completed, pages: pages)
        story.lastReadPage = savedPage
        return story
    }

    /// Günlük akışın kendi masalları (FAZ 15): tek parça metin, paragraf
    /// gruplarıyla sayfalara bölünür.
    static func story(for daily: DailyStory, childID: UUID?, childName: String, savedPage: Int?) -> Story {
        var story = Story(
            id: daily.id, title: daily.title, childName: childName, childProfileID: childID,
            theme: .fantasy, language: .turkish, status: .completed,
            pages: pages(of: daily.content).map { StoryPage(title: "", text: $0, imagePrompt: "") })
        story.lastReadPage = savedPage
        return story
    }

    /// Paragrafları en fazla `perPage` tanesi bir sayfaya gelecek biçimde
    /// gruplar. Tek paragraflı metin tek sayfa olur.
    static func pages(of text: String, perPage: Int = 2) -> [String] {
        let paragraphs = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .split(whereSeparator: \.isEmpty)
            .map { $0.joined(separator: " ") }
        guard !paragraphs.isEmpty else { return [text] }
        return stride(from: 0, to: paragraphs.count, by: perPage).map {
            paragraphs[$0..<min($0 + perPage, paragraphs.count)].joined(separator: "\n\n")
        }
    }
}
