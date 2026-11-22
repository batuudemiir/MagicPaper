import Foundation
import StoryEngine

/// A read mark from an older app must not silently strip source identity.
/// Metadata is inherited only when the source-dependent content still matches.
enum SeriesSourcePreservation {
    enum Failure: Error { case conflictingSource }

    static func merge(_ incoming: [StorySeries], preserving existing: [StorySeries]) throws -> [StorySeries] {
        try incoming.map { candidate in
            guard let old = existing.first(where: { $0.id == candidate.id }) else { return candidate }
            var result = candidate
            if let source = old.plan.contentSource {
                if let provided = candidate.plan.contentSource {
                    guard provided == source else { throw Failure.conflictingSource }
                } else {
                    guard candidate.childID == old.childID, candidate.firstStoryID == old.firstStoryID,
                          try samePlan(candidate.plan, old.plan),
                          candidate.episodes.count == old.episodes.count,
                          candidate.episodes.allSatisfy({ episode in
                              old.episodes.contains { sameContent(episode, $0) }
                          }) else { throw Failure.conflictingSource }
                    result.plan = candidate.plan.withContentSource(source)
                }
            }
            for index in result.episodes.indices {
                guard let previous = old.episodes.first(where: { $0.number == result.episodes[index].number }),
                      let source = previous.origin.contentSource else { continue }
                if let provided = result.episodes[index].origin.contentSource {
                    guard provided == source else { throw Failure.conflictingSource }
                } else {
                    guard sameContent(result.episodes[index], previous) else { throw Failure.conflictingSource }
                    result.episodes[index].origin.contentSource = source
                }
            }
            return result
        }
    }

    private static func samePlan(_ a: SeriesPlan, _ b: SeriesPlan) throws -> Bool {
        func value(_ plan: SeriesPlan) throws -> NSDictionary {
            var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(plan)) as? [String: Any] ?? [:]
            object.removeValue(forKey: "contentSource")
            return object as NSDictionary
        }
        return try value(a).isEqual(value(b))
    }

    private static func sameContent(_ a: SeriesEpisode, _ b: SeriesEpisode) -> Bool {
        var left = a.origin
        var right = b.origin
        left.contentSource = nil
        right.contentSource = nil
        return a.number == b.number && a.title == b.title && a.theme == b.theme
            && samePageContent(a.pages, b.pages) && left == right
    }

    private static func samePageContent(_ a: [StoryPage], _ b: [StoryPage]) -> Bool {
        // StoryPage.== intentionally compares IDs only; source inheritance
        // requires the text, provenance, reading metadata and art pins too.
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let left = try? encoder.encode(a), let right = try? encoder.encode(b) else { return false }
        return left == right
    }
}
