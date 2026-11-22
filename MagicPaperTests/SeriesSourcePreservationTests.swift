import XCTest
import StoryEngine
@testable import MagicPaper

final class SeriesSourcePreservationTests: XCTestCase {
    private func series(source: ContentSourceMetadata?, id: UUID, seed: String = "stable") -> StorySeries {
        let plan = SeriesPlan(seed: seed, catalogVersion: "2.1.0", mode: .adventure,
            ageBand: AgeBand(lowerBound: 5, upperBound: 6),
            anchor: SeriesAnchor(settingID: "forest", companionID: "old-friend", keepsakeID: "map"),
            family: nil, episodes: [PlannedEpisode(number: 2, blueprintID: "continuation", discoveryID: "map", seed: seed + "-2")], contentSource: source)
        var page = StoryPage(title: "İkinci bölüm", text: "Saklanan özgün masal metni.", imagePrompt: "")
        page.art = StoryPageArt(role: "spot", altText: "Harita", sourceID: "historical-map",
            assetRevision: 7, assetDigest: String(repeating: "c", count: 64))
        page.provenance = StoryPageProvenance(parts: [
            .init(sourceKind: "beat_line", sourceID: "saved-line", sourceTextDigest: "saved-digest", contexts: ["series"])
        ])
        var origin = try! JSONDecoder().decode(StoryOrigin.self, from: Data(#"{"seed":"stable-2","blueprintID":"continuation","settingID":"forest","companionID":"old-friend","discoveryID":"map","fingerprint":"saved-fingerprint","catalogVersion":"2.1.0","modeID":"adventure","selectionStrategy":"direct","ageBand":"5-6"}"#.utf8))
        origin.contentSource = source
        origin.seriesID = id.uuidString
        origin.seriesEpisode = 2
        let episode = SeriesEpisode(number: 2, title: "Saklanan bölüm", theme: .fantasy, pages: [page],
            origin: origin, storyID: UUID(), unlockedAt: Date(timeIntervalSince1970: 0), read: nil)
        return StorySeries(id: id, childID: UUID(), childName: "Deniz", firstStoryID: UUID(),
            firstStoryTitle: "Sentetik", plan: plan, episodes: [episode],
            firstRead: SeriesReadMark(at: Date(timeIntervalSince1970: 0), day: "2026-11-22", timeZone: "Europe/Istanbul"),
            createdAt: Date(timeIntervalSince1970: 0))
    }

    func testOldClientMayNotDropKnownSourceOnSamePlan() throws {
        let source = ContentSourceMetadata(try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: "a", count: 64)))
        let old = series(source: source, id: UUID())
        var incoming = old
        incoming.plan = series(source: nil, id: old.id).plan
        incoming.episodes[0].origin.contentSource = nil
        incoming.episodes[0].read = SeriesReadMark(at: Date(timeIntervalSince1970: 100), day: "2026-11-23", timeZone: "Europe/Istanbul")
        let merged = try SeriesSourcePreservation.merge([incoming], preserving: [old])
        XCTAssertEqual(merged[0].plan.contentSource, source)
        XCTAssertEqual(merged[0].id, old.id)
        XCTAssertEqual(merged[0].episodes[0].origin.contentSource, source)
        XCTAssertEqual(merged[0].episodes[0].read, incoming.episodes[0].read)
        XCTAssertEqual(merged[0].episodes[0].pages[0].text, old.episodes[0].pages[0].text)
        XCTAssertEqual(merged[0].episodes[0].pages[0].art, old.episodes[0].pages[0].art)
        XCTAssertEqual(merged[0].episodes[0].pages[0].provenance, old.episodes[0].pages[0].provenance)
    }

    func testChangedPlanCannotInheritAnUnprovenSource() throws {
        let source = ContentSourceMetadata(try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: "a", count: 64)))
        let old = series(source: source, id: UUID())
        var incoming = old
        incoming.plan = series(source: nil, id: old.id, seed: "different").plan
        XCTAssertThrowsError(try SeriesSourcePreservation.merge([incoming], preserving: [old]))
    }

    func testConflictingExplicitReferenceIsRejected() throws {
        let a = ContentSourceMetadata(try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: "a", count: 64)))
        let b = ContentSourceMetadata(try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: "b", count: 64)))
        let old = series(source: a, id: UUID())
        var incoming = old
        incoming.plan = incoming.plan.withContentSource(b)
        XCTAssertThrowsError(try SeriesSourcePreservation.merge([incoming], preserving: [old]))
    }
    func testChangedEpisodeTextWithoutMetadataCannotInheritSource() throws {
        let source = ContentSourceMetadata(try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: "a", count: 64)))
        let old = series(source: source, id: UUID())
        var incoming = old
        incoming.plan = series(source: nil, id: old.id).plan
        incoming.episodes[0].origin.contentSource = nil
        incoming.episodes[0].pages[0].text = "Değiştirilmiş başka bir metin."
        XCTAssertEqual(incoming.episodes[0].pages[0].id, old.episodes[0].pages[0].id)
        XCTAssertThrowsError(try SeriesSourcePreservation.merge([incoming], preserving: [old]))
    }

    func testConflictingEpisodeReferenceIsRejectedEvenWithMatchingPlan() throws {
        let a = ContentSourceMetadata(try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: "a", count: 64)))
        let b = ContentSourceMetadata(try ContentSourceReference(catalogVersion: "2.1.0", payloadSHA256: String(repeating: "b", count: 64)))
        let old = series(source: a, id: UUID())
        var incoming = old
        incoming.episodes[0].origin.contentSource = b
        XCTAssertThrowsError(try SeriesSourcePreservation.merge([incoming], preserving: [old]))
    }

}
