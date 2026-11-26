import Foundation

/// Schema 2 with one immutable voice-v4 corpus; historical validators remain unchanged.
enum P56V4PackageLoader {
    private typealias Payload = P56V2PackageLoader.Payload
    private typealias Corpus = P56V2PackageLoader.Corpus
    private struct EvidenceDocument: Decodable { let records: [P56CausalEvidence] }
    private static let corpusIDs: Set<String> = ["five-friends-56-voice-v4"]

    static func load(payload: Data, expectedSHA256: String) throws -> P56Package {
        let raw = try JSONDecoder().decode(Payload.self, from: payload)
        guard raw.schemaVersion == 2, raw.packageVersion == "five-friends-56-runtime-v4",
              raw.engineBehaviorID == "offline-p56-v1", !raw.productionEnabled, !raw.artApproved,
              raw.worldID == "pilot56_world_whispering_forest_v1" else {
            throw P56Error.integrity("v4-schema-behavior-or-release")
        }
        try P56PackageLoader.validateProfiles(raw.companions)
        try validateCoverage(raw)
        guard raw.corpora.count == 1, Set(raw.corpora.map(\.id)) == corpusIDs else {
            throw P56Error.integrity("v4-corpora")
        }
        let corpus = raw.corpora[0]
        let parents = try sources(corpus)
        try validateEvidence(corpus, books: raw.books)
        var templates: Set<String> = []
        for book in raw.books {
            try P56PackageLoader.validateBook(book, sources: parents, templateIDs: &templates, corpusID: corpus.id)
            try validateAuthoredLineage(book, raw: raw, corpusID: corpus.id)
        }
        guard let review = raw.safetyReview else { throw P56Error.integrity("v4-safety-review-required") }
        try review.validate(against: raw.books)
        return P56Package(sourceReference: P56SourceReference(packageVersion: raw.packageVersion,
            payloadSHA256: expectedSHA256), books: raw.books, structures: raw.structures,
            companions: raw.companions, settings: raw.settings, worldID: raw.worldID, safetyReview: raw.safetyReview)
    }

    private static func sources(_ corpus: Corpus) throws -> [P56PackageLoader.ParentSource] {
        let bytes = Data(corpus.sourcesJSON.utf8)
        guard P56Digest.sha256(bytes) == corpus.sourcesSHA256 else {
            throw P56Error.integrity("v4-corpus-source-bytes")
        }
        let sources = try JSONDecoder().decode(P56PackageLoader.SourceDocument.self, from: bytes).sources
        guard Set(sources.map(\.id)).count == sources.count,
              sources.allSatisfy({ P56Digest.sha256(Data($0.text.utf8)) == $0.sha256UTF8 }) else {
            throw P56Error.integrity("v4-corpus-parent-digest")
        }
        return sources
    }

    private static func validateEvidence(_ corpus: Corpus, books: [P56Book]) throws {
        let bytes = Data(corpus.causalEvidenceJSON.utf8)
        guard P56Digest.sha256(bytes) == corpus.causalEvidenceSHA256 else {
            throw P56Error.integrity("v4-causal-snapshot")
        }
        let records = try JSONDecoder().decode(EvidenceDocument.self, from: bytes).records
        guard records.count == books.count * 8 else { throw P56Error.integrity("v4-causal-count") }
        for book in books {
            for page in book.pages {
                guard records.filter({ $0.bookID == book.id && $0.pageNumber == page.number }) == [page.causalEvidence] else {
                    throw P56Error.integrity("v4-causal-lineage")
                }
            }
        }
    }

    private static func validateAuthoredLineage(_ book: P56Book, raw: Payload, corpusID: String) throws {
        guard let lineage = raw.bookLineages.first(where: { $0.bookID == book.id }) else {
            throw P56Error.integrity("v4-book-lineage")
        }
        let original = try JSONDecoder().decode(P56JSONValue.self, from: Data(book.authoredBookJSON.utf8))
        let expectedCorpus = "five-friends-56-voice-v4"
        guard corpusID == expectedCorpus,
              lineage.baseBookID == (original["baseBookID"]?.stringValue ?? book.id),
              (lineage.eventID != "event01" || lineage.baseBookID == book.id),
              (lineage.eventID == "event01" || lineage.baseBookID != book.id),
              lineage.eventID == (original["variantID"]?.stringValue ?? "event01"),
              original["context"]?["worldID"] == .string(book.worldID),
              original["context"]?["discoveryID"] == .string(book.discoveryID),
              original["mechanismKey"] == .string(book.mechanism),
              try P56Personalization.template(fromSyntheticText: original["title"]?.stringValue ?? "") == book.titleTemplate,
              let pages = original["pages"]?.arrayValue else { throw P56Error.integrity("v4-authored-lineage") }
        for (page, source) in zip(book.pages, pages) {
            let parts = source["provenance"]?["parts"]?.arrayValue
            guard parts?.count == 1, parts?.first?["sourceID"] == .string(page.parentSourceID),
                  parts?.first?["sourceTextDigest"] == .string(page.parentSHA256),
                  parts?.first?["sourcePointer"] == .string("sources.json#/sources/\(page.parentSourceIndex)") else {
                throw P56Error.integrity("v4-authored-parent-pointer")
            }
        }
    }

    private static func validateCoverage(_ raw: Payload) throws {
        guard raw.books.count == 90, Set(raw.books.map(\.id)).count == 90,
              raw.bookLineages.count == 90, Set(raw.bookLineages.map(\.bookID)) == Set(raw.books.map(\.id)),
              raw.structures.count == 9, Set(raw.structures.map(\.planLabel)).count == 9 else {
            throw P56Error.integrity("v4-book-or-lineage-count")
        }
        for structure in raw.structures {
            guard structure.pageMoves == P56StructureValidator.sequences[structure.planLabel],
                  Set(structure.allowedCompanionIDs) == P56PackageLoader.allowed[structure.planLabel] else {
                throw P56Error.integrity("v4-structure-allowlist")
            }
        }
        var pairs: [String: Set<String>] = [:], cells: [String: Int] = [:]
        for book in raw.books {
            guard let structure = raw.structures.first(where: { $0.planLabel == book.structureID }),
                  structure.mode == book.mode, structure.mechanismKey == book.mechanism,
                  structure.allowedCompanionIDs.contains(book.companionID),
                  let lineage = raw.bookLineages.first(where: { $0.bookID == book.id }),
                  corpusIDs.contains(lineage.corpusID),
                  let base = raw.books.first(where: { $0.id == lineage.baseBookID }),
                  base.structureID == book.structureID, base.companionID == book.companionID,
                  let baseLineage = raw.bookLineages.first(where: { $0.bookID == base.id }),
                  baseLineage.eventID == "event01", baseLineage.baseBookID == base.id,
                  baseLineage.corpusID == "five-friends-56-voice-v4" else { throw P56Error.integrity("v4-book-allowlist") }
            let pair = book.structureID + "/" + book.companionID
            guard pairs[pair, default: []].insert(lineage.eventID).inserted else {
                throw P56Error.integrity("v4-duplicate-event")
            }
            cells[book.mode.rawValue + "/" + book.companionID, default: 0] += 1
        }
        guard pairs.count == 30, pairs.values.allSatisfy({ $0 == ["event01", "event02", "event03"] }),
              cells.count == 15, cells.values.allSatisfy({ $0 == 6 }) else { throw P56Error.integrity("v4-event-coverage") }
    }
}
