import XCTest
import StoryEngine
@testable import MagicPaper

/// An observational baseline, not an art authorization or a coverage guarantee.
final class WholeBookArtCoverageTests: XCTestCase {
    private let blueprintIDs = [
        "blueprint_threshold_crossing_001", "bp_threshold_joining_002",
        "blueprint_absence_looking_001", "bp_absence_retracing_002",
        "bp_threshold_together_003", "bp_absence_asking_003"
    ]

    @MainActor
    func testFixedSixBlueprintWholeBookBaseline() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        XCTAssertEqual(Set(blueprintIDs).count, 6)
        var attempts: [Attempt] = []
        for id in blueprintIDs {
            let blueprint = try XCTUnwrap(catalog.blueprints.first { $0.id.rawValue == id })
            XCTAssertEqual(blueprint.ageRange.description, "5-6")
            for index in 0..<100 {
                let seed = String(format: "whole-book-art-v1-%03d", index)
                var phase = "composition"
                do {
                    let composed = try OfflineStoryComposer().compose(blueprint: blueprint,
                        catalog: catalog, intent: OfflineStoryIntent(childName: "Deniz", seed: seed,
                            mode: .adventure, ageBand: AgeBand(lowerBound: 5, upperBound: 6)))
                    phase = "mapper_save_roundtrip"
                    attempts.append(try record(composed, catalogVersion: catalog.version))
                } catch {
                    attempts.append(Attempt(blueprintID: id, seed: seed,
                        error: String(describing: error), errorPhase: phase, settingID: nil, companionID: nil,
                        discoveryID: nil, fingerprint: nil, isClean: nil, pages: []))
                }
            }
        }
        XCTAssertEqual(attempts.count, 600)
        XCTAssertEqual(Set(attempts.map(\.blueprintID)), Set(blueprintIDs))
        for id in blueprintIDs {
            XCTAssertEqual(attempts.filter { $0.blueprintID == id }.count, 100)
            XCTAssertEqual(Set(attempts.filter { $0.blueprintID == id }.map(\.seed)).count, 100)
        }
        let report = Report(catalogVersion: catalog.version, blueprintIDs: blueprintIDs, attempts: attempts)
        XCTAssertEqual(report.summary.successes + report.summary.errors, 600)
        XCTAssertEqual(report.summary.pages, report.summary.pinnedPages + report.summary.unpinnedPages)
        XCTAssertEqual(report.summary.pages, report.summary.opening + report.summary.middle + report.summary.closing)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(report)
        XCTAssertEqual(data, try encoder.encode(report))
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
        attachment.name = "whole-book-art-v1.json"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func record(_ composed: ComposedStory, catalogVersion: String) throws -> Attempt {
        let story = OfflineStoryMapper.appStory(from: composed, childName: "Deniz",
            childProfileID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            storyIdeaID: nil, catalogVersion: catalogVersion, mode: .adventure,
            ageBand: AgeBand(lowerBound: 5, upperBound: 6))
        let ordered = composed.pages.sorted { $0.pageNumber < $1.pageNumber }
        guard ordered.map(\.pageNumber) == Array(1...8), story.pages.count == ordered.count else {
            throw BaselineError.invalidMappedPageLayout
        }
        XCTAssertEqual(story.pages.map(\.text), ordered.map(\.text))
        let saved = try JSONDecoder().decode(MagicPaper.Story.self, from: JSONEncoder().encode(story))
        XCTAssertEqual(saved.pages.map(\.text), ordered.map(\.text))
        XCTAssertEqual(saved.pages.map(\.art), story.pages.map(\.art))
        XCTAssertEqual(saved.pages.map(\.provenance), story.pages.map(\.provenance))
        let pages = ordered.enumerated().map { index, page in
            Page(page: page, position: page.pageNumber <= 2 ? "opening" :
                (page.pageNumber >= 7 ? "closing" : "middle"), art: story.pages[index].art)
        }
        return Attempt(blueprintID: composed.blueprintID.rawValue, seed: composed.seed,
            error: nil, errorPhase: nil, settingID: composed.content.setting.id.rawValue,
            companionID: composed.content.companion.id.rawValue,
            discoveryID: composed.content.discovery.id.rawValue,
            fingerprint: composed.fingerprint, isClean: composed.isClean, pages: pages)
    }

    private enum BaselineError: Error {
        case invalidMappedPageLayout
    }

    private struct Attempt: Encodable {
        let blueprintID: String
        let seed: String
        let error: String?
        let errorPhase: String?
        let settingID: String?
        let companionID: String?
        let discoveryID: String?
        let fingerprint: String?
        let isClean: Bool?
        let pages: [Page]
    }

    private struct Page: Encodable {
        let pageNumber: Int
        let position: String
        let role: String
        let beats: [String]
        let text: String
        let variantIDs: [String]
        let provenance: [PageSourcePart]
        let missingSlots: [String]
        let unrecognisedSuffixes: [String]
        let art: StoryPageArt?
        let absenceReasons: [String]
        let candidacyEvidence: [Evidence]

        init(page: ComposedPage, position: String, art: StoryPageArt?) {
            pageNumber = page.pageNumber
            self.position = position
            role = page.role.rawValue
            beats = page.beats.map(\.rawValue)
            text = page.text
            variantIDs = page.variantIDs.map(\.rawValue)
            provenance = page.provenance
            missingSlots = page.missingSlots
            unrecognisedSuffixes = page.unrecognisedSuffixes
            self.art = art
            candidacyEvidence = page.provenance.flatMap { part in
                (part.visual ?? []).map { Evidence(sourceID: part.sourceID,
                    review: part.visualReview?.rawValue, visual: $0) }
            }
            var reasons: [String] = []
            if art == nil { reasons.append("mapper_produced_no_pin; policy_rejection_reason_not_exposed") }
            if page.provenance.isEmpty { reasons.append("no_provenance") }
            if page.provenance.contains(where: { $0.visual == nil }) { reasons.append("unannotated_source") }
            if candidacyEvidence.isEmpty { reasons.append("no_declared_visual_mentions") }
            if !candidacyEvidence.contains(where: { $0.visual.presence == .present }) {
                reasons.append("no_declared_present_subject")
            }
            absenceReasons = reasons
        }
    }

    private struct Evidence: Encodable {
        let sourceID: String
        let review: String?
        let visual: ResolvedVisual
        let status = "annotation_only_not_an_approved_art_match"
    }

    private struct Summary: Encodable {
        let successes: Int
        let uncleanSuccesses: Int
        let errors: Int
        let pages: Int
        let pinnedPages: Int
        let unpinnedPages: Int
        let opening: Int
        let middle: Int
        let closing: Int
        let pinnedByPosition: [String: Int]
        let storiesByPinnedPageCount: [String: Int]
        let presentEvidencePages: Int

        init(attempts: [Attempt]) {
            let successful = attempts.filter { $0.error == nil }
            let allPages = successful.flatMap(\.pages)
            successes = successful.count
            uncleanSuccesses = successful.filter { $0.isClean == false }.count
            errors = attempts.count - successful.count
            pages = allPages.count
            pinnedPages = allPages.filter { $0.art != nil }.count
            unpinnedPages = pages - pinnedPages
            opening = allPages.filter { $0.position == "opening" }.count
            middle = allPages.filter { $0.position == "middle" }.count
            closing = allPages.filter { $0.position == "closing" }.count
            pinnedByPosition = Dictionary(grouping: allPages.filter { $0.art != nil }, by: \.position).mapValues(\.count)
            storiesByPinnedPageCount = Dictionary(grouping: successful,
                by: { String($0.pages.filter { $0.art != nil }.count) }).mapValues(\.count)
            presentEvidencePages = allPages.filter { page in
                page.candidacyEvidence.contains { $0.visual.presence == .present }
            }.count
        }
    }

    private struct Report: Encodable {
        let schemaVersion = 1
        let experiment = "whole-book-art-v1"
        let interpretation = "Explicit blueprint-stratified sample, not production frequency. Fixed seeds; default catalog cast; annotations are evidence only, never approved matches. Errors remain in denominator. No coverage target asserted."
        let catalogVersion: String
        let blueprintIDs: [String]
        let attempts: [Attempt]
        let summary: Summary

        init(catalogVersion: String, blueprintIDs: [String], attempts: [Attempt]) {
            self.catalogVersion = catalogVersion
            self.blueprintIDs = blueprintIDs
            self.attempts = attempts
            summary = Summary(attempts: attempts)
        }
    }
}
