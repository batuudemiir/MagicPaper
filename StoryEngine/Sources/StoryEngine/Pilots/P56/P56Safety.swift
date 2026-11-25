import Foundation

/// Finite, exact-source safety review. This is separate from art and release approval.
struct P56SafetyReview: Decodable, Sendable {
    struct Catalog: Decodable, Sendable {
        struct Topic: Decodable, Sendable { let id: String }
        let safetyTopics: [Topic]
    }
    struct Title: Decodable, Sendable {
        let sourceText: String
        let sourceSHA256UTF8: String
        let topics: [String]
        let status: String
        let evidence: String
        let topicExclusionRationale: [String: String]
    }
    struct Book: Decodable, Sendable {
        let bookID: String
        let bookSHA256FileBytes: String
        let status: String
        let topics: [String]
        let emotions: [EmotionalState]
        let calmEligible: Bool
        let title: Title
        let pages: [Page]
    }
    struct Page: Decodable, Sendable {
        struct Evidence: Decodable, Sendable {
            let sourceID: String
            let pageNumber: Int
            let quote: String
            let topic: String?
        }
        let bookID: String
        let pageNumber: Int
        let sourceID: String
        let sourceSHA: String
        let sourceSHA256UTF8: String
        let topics: [String]
        let emotion: EmotionalState
        let status: String
        let evidence: [Evidence]
        let topicExclusionRationale: [String: String]
    }
    let schema: String
    let canonicalCatalog: Catalog
    let books: [Book]
    private static let vocabulary: Set<String> = ["darkness", "alone", "fear", "weather", "heights"]

    func validate(against sourceBooks: [P56Book]) throws {
        let topics = canonicalCatalog.safetyTopics.map(\.id)
        guard schema == "magicpaper.c3.content-safety-review.v1",
              Set(topics) == Self.vocabulary, topics.count == Self.vocabulary.count,
              books.count == sourceBooks.count, Set(books.map(\.bookID)).count == books.count,
              Set(books.map(\.bookID)) == Set(sourceBooks.map(\.id)) else {
            throw P56Error.integrity("safety-review-coverage")
        }
        for review in books {
            guard let source = sourceBooks.first(where: { $0.id == review.bookID }),
                  review.status == "reviewed", review.bookSHA256FileBytes == source.authoredBookSHA256,
                  review.pages.map(\.pageNumber) == Array(1...8),
                  Set(review.topics) == Set(review.pages.flatMap(\.topics) + review.title.topics),
                  Set(review.emotions) == Set(review.pages.map(\.emotion)),
                  review.calmEligible == !review.pages.contains(where: { ContentSafety.tenseEmotions.contains($0.emotion) }) else {
                throw P56Error.integrity("safety-book-review")
            }
            try validate(review.title, source: source)
            for page in review.pages { try validate(page, source: source) }
        }
    }

    private func validate(_ review: Title, source: P56Book) throws {
        let original = try JSONDecoder().decode(P56JSONValue.self, from: Data(source.authoredBookJSON.utf8))
        guard review.status == "reviewed", !review.sourceText.isEmpty,
              original["title"] == .string(review.sourceText), review.evidence == review.sourceText,
              P56Digest.sha256(Data(review.sourceText.utf8)) == review.sourceSHA256UTF8,
              Set(review.topics).count == review.topics.count,
              Set(review.topics).isSubset(of: Self.vocabulary),
              Set(review.topics).isDisjoint(with: Set(review.topicExclusionRationale.keys)),
              Set(review.topics).union(review.topicExclusionRationale.keys) == Self.vocabulary,
              review.topicExclusionRationale.values.allSatisfy({ !$0.isEmpty }) else {
            throw P56Error.integrity("safety-title-review")
        }
    }

    private func validate(_ review: Page, source: P56Book) throws {
        guard let page = source.pages.first(where: { $0.number == review.pageNumber }),
              review.bookID == source.id, review.status == "reviewed",
              review.sourceID == page.parentSourceID, review.sourceSHA == page.parentSHA256,
              review.sourceSHA256UTF8 == page.parentSHA256, review.emotion.intensity <= 2,
              Set(review.topics).count == review.topics.count,
              Set(review.topics).isSubset(of: Self.vocabulary),
              Set(review.topics).isDisjoint(with: Set(review.topicExclusionRationale.keys)),
              Set(review.topics).union(review.topicExclusionRationale.keys) == Self.vocabulary,
              review.topicExclusionRationale.values.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
              !review.evidence.isEmpty,
              review.topics.allSatisfy({ topic in review.evidence.contains { $0.topic == topic } }),
              review.evidence.contains(where: { $0.sourceID == page.parentSourceID }) else {
            throw P56Error.integrity("safety-page-review")
        }
        for evidence in review.evidence {
            guard let original = source.pages.first(where: { $0.parentSourceID == evidence.sourceID }),
                  original.number == evidence.pageNumber, TextMetrics.wordCount(evidence.quote) >= 2,
                  evidence.topic.map({ review.topics.contains($0) }) ?? true,
                  original.parentText.contains(evidence.quote) else {
                throw P56Error.integrity("safety-quote-source")
            }
        }
    }

    func admits(_ book: P56Book, safety: ContentSafety) -> Bool {
        guard let review = books.first(where: { $0.bookID == book.id }),
              safety.admits(topics: review.topics.map { SafetyTopic($0) }) else { return false }
        return safety.level != .calm || !review.pages.contains { ContentSafety.tenseEmotions.contains($0.emotion) }
    }

    /// Nil means avoid any tagged topic (ContentSafety.avoids), not a hidden list.
    /// New review vocabularies require a supported source/review revision.
    func understands(_ safety: ContentSafety) -> Bool {
        safety.avoided?.allSatisfy { Self.vocabulary.contains($0.rawValue) } ?? true
    }
}
