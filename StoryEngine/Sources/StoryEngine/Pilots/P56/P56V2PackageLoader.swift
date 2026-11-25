import Foundation

struct P56PayloadHeader: Decodable { let schemaVersion: Int }

/// Payload schema 2 preserves the two immutable authoring corpora independently.
enum P56V2PackageLoader {
    struct Corpus: Decodable {
        let id: String
        let sourcesJSON: String
        let sourcesSHA256: String
        let causalEvidenceJSON: String
        let causalEvidenceSHA256: String
    }
    struct Lineage: Decodable {
        let bookID: String
        let corpusID: String
        let eventID: String
        let baseBookID: String
    }
    struct Payload: Decodable {
        let schemaVersion: Int
        let packageVersion: String
        let engineBehaviorID: String
        let productionEnabled: Bool
        let artApproved: Bool
        let companions: [P56CompanionProfile]
        let settings: P56JSONValue
        let worldID: String
        let structures: [P56Structure]
        let books: [P56Book]
        let corpora: [Corpus]
        let bookLineages: [Lineage]
        let safetyReview: P56SafetyReview?
    }
    private struct EvidenceDocument: Decodable { let records: [P56CausalEvidence] }
    private static let corpusIDs: Set<String> = ["five-friends-56-v1", "five-friends-56-expansion-v1"]

    static func load(payload: Data, expectedSHA256: String) throws -> P56Package {
        let raw = try JSONDecoder().decode(Payload.self, from: payload)
        guard raw.schemaVersion == 2, raw.packageVersion == "five-friends-56-runtime-v2",
              raw.engineBehaviorID == "offline-p56-v1", !raw.productionEnabled, !raw.artApproved,
              raw.worldID == "pilot56_world_whispering_forest_v1" else {
            throw P56Error.integrity("v2-schema-behavior-or-release")
        }
        try P56PackageLoader.validateProfiles(raw.companions)
        try validateCoverage(raw)
        guard raw.corpora.count == 2, Set(raw.corpora.map(\.id)) == corpusIDs else {
            throw P56Error.integrity("v2-corpora")
        }
        var templates: Set<String> = [], parents: Set<String> = []
        for corpus in raw.corpora {
            let sources = try sources(corpus)
            guard sources.allSatisfy({ parents.insert($0.id).inserted }) else {
                throw P56Error.integrity("v2-cross-corpus-parent-id")
            }
            let ids = Set(raw.bookLineages.filter { $0.corpusID == corpus.id }.map(\.bookID))
            let books = raw.books.filter { ids.contains($0.id) }
            try validateEvidence(corpus, books: books)
            for book in books {
                try P56PackageLoader.validateBook(book, sources: sources, templateIDs: &templates, corpusID: corpus.id)
                try validateAuthoredLineage(book, raw: raw, corpusID: corpus.id)
            }
        }
        try raw.safetyReview?.validate(against: raw.books)
        return P56Package(sourceReference: P56SourceReference(packageVersion: raw.packageVersion,
            payloadSHA256: expectedSHA256), books: raw.books, structures: raw.structures,
            companions: raw.companions, settings: raw.settings, worldID: raw.worldID, safetyReview: raw.safetyReview)
    }

    private static func sources(_ corpus: Corpus) throws -> [P56PackageLoader.ParentSource] {
        let bytes = Data(corpus.sourcesJSON.utf8)
        guard P56Digest.sha256(bytes) == corpus.sourcesSHA256 else {
            throw P56Error.integrity("v2-corpus-source-bytes")
        }
        let sources = try JSONDecoder().decode(P56PackageLoader.SourceDocument.self, from: bytes).sources
        guard Set(sources.map(\.id)).count == sources.count,
              sources.allSatisfy({ P56Digest.sha256(Data($0.text.utf8)) == $0.sha256UTF8 }) else {
            throw P56Error.integrity("v2-corpus-parent-digest")
        }
        return sources
    }

    private static func validateEvidence(_ corpus: Corpus, books: [P56Book]) throws {
        let bytes = Data(corpus.causalEvidenceJSON.utf8)
        guard P56Digest.sha256(bytes) == corpus.causalEvidenceSHA256 else {
            throw P56Error.integrity("v2-causal-snapshot")
        }
        let records = try JSONDecoder().decode(EvidenceDocument.self, from: bytes).records
        guard records.count == books.count * 8 else { throw P56Error.integrity("v2-causal-count") }
        for book in books {
            for page in book.pages {
                guard records.filter({ $0.bookID == book.id && $0.pageNumber == page.number }) == [page.causalEvidence] else {
                    throw P56Error.integrity("v2-causal-lineage")
                }
            }
        }
    }

    private static func validateAuthoredLineage(_ book: P56Book, raw: Payload, corpusID: String) throws {
        guard let lineage = raw.bookLineages.first(where: { $0.bookID == book.id }) else {
            throw P56Error.integrity("v2-book-lineage")
        }
        let original = try JSONDecoder().decode(P56JSONValue.self, from: Data(book.authoredBookJSON.utf8))
        let expectedCorpus = lineage.eventID == "event01" ? "five-friends-56-v1" : "five-friends-56-expansion-v1"
        guard corpusID == expectedCorpus,
              lineage.baseBookID == (original["baseBookID"]?.stringValue ?? book.id),
              lineage.eventID == (original["variantID"]?.stringValue ?? "event01"),
              original["context"]?["worldID"] == .string(book.worldID),
              original["context"]?["discoveryID"] == .string(book.discoveryID),
              original["mechanismKey"] == .string(book.mechanism),
              try P56Personalization.template(fromSyntheticText: original["title"]?.stringValue ?? "") == book.titleTemplate,
              let pages = original["pages"]?.arrayValue else { throw P56Error.integrity("v2-authored-lineage") }
        for (page, source) in zip(book.pages, pages) {
            let parts = source["provenance"]?["parts"]?.arrayValue
            guard parts?.count == 1, parts?.first?["sourceID"] == .string(page.parentSourceID),
                  parts?.first?["sourceTextDigest"] == .string(page.parentSHA256),
                  parts?.first?["sourcePointer"] == .string("sources.json#/sources/\(page.parentSourceIndex)") else {
                throw P56Error.integrity("v2-authored-parent-pointer")
            }
        }
    }

    private static func validateCoverage(_ raw: Payload) throws {
        guard raw.books.count == 90, Set(raw.books.map(\.id)).count == 90,
              raw.bookLineages.count == 90, Set(raw.bookLineages.map(\.bookID)) == Set(raw.books.map(\.id)),
              raw.structures.count == 9, Set(raw.structures.map(\.planLabel)).count == 9 else {
            throw P56Error.integrity("v2-book-or-lineage-count")
        }
        for structure in raw.structures {
            guard structure.pageMoves == P56StructureValidator.sequences[structure.planLabel],
                  Set(structure.allowedCompanionIDs) == P56PackageLoader.allowed[structure.planLabel] else {
                throw P56Error.integrity("v2-structure-allowlist")
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
                  baseLineage.corpusID == "five-friends-56-v1" else { throw P56Error.integrity("v2-book-allowlist") }
            let pair = book.structureID + "/" + book.companionID
            guard pairs[pair, default: []].insert(lineage.eventID).inserted else {
                throw P56Error.integrity("v2-duplicate-event")
            }
            cells[book.mode.rawValue + "/" + book.companionID, default: 0] += 1
        }
        guard pairs.count == 30, pairs.values.allSatisfy({ $0 == ["event01", "event02", "event03"] }),
              cells.count == 15, cells.values.allSatisfy({ $0 == 6 }) else { throw P56Error.integrity("v2-event-coverage") }
    }
}
