import Foundation

/// Only explicit bytes are accepted. This never searches bundles or changes the production catalog.
public enum P56PackageLoader {
    public static func load(payload: Data, expectedSHA256: String) throws -> P56Package {
        guard expectedSHA256.count == 64, P56Digest.sha256(payload) == expectedSHA256 else {
            throw P56Error.integrity("payload-sha256")
        }
        let header = try JSONDecoder().decode(P56PayloadHeader.self, from: payload)
        if header.schemaVersion == 2 {
            return try P56V2PackageLoader.load(payload: payload, expectedSHA256: expectedSHA256)
        }
        let raw = try JSONDecoder().decode(P56Payload.self, from: payload)
        guard raw.schemaVersion == 1, raw.packageVersion == "five-friends-56-runtime-v1",
              raw.engineBehaviorID == "offline-p56-v1", !raw.productionEnabled, !raw.artApproved,
              raw.worldID == "pilot56_world_whispering_forest_v1" else {
            throw P56Error.integrity("schema-behavior-or-release")
        }
        try validateProfiles(raw.companions)
        try validateStructureCoverage(raw)
        let sources = try originalSources(raw)
        try validateCausalEvidenceSnapshot(raw)
        var templateIDs: Set<String> = []
        for book in raw.books {
            try validateBook(book, sources: sources, templateIDs: &templateIDs)
        }
        return P56Package(sourceReference: P56SourceReference(payloadSHA256: expectedSHA256),
            books: raw.books, structures: raw.structures, companions: raw.companions,
            settings: raw.settings, worldID: raw.worldID)
    }

    struct ParentSource: Decodable {
        let id: String
        let text: String
        let sha256UTF8: String
    }
    struct SourceDocument: Decodable { let sources: [ParentSource] }
    private static func originalSources(_ raw: P56Payload) throws -> [ParentSource] {
        let data = Data(raw.authoredSourcesJSON.utf8)
        guard P56Digest.sha256(data) == raw.authoredSourcePayloadSHA256 else {
            throw P56Error.integrity("authored-source-payload")
        }
        let sources = try JSONDecoder().decode(SourceDocument.self, from: data).sources
        guard Set(sources.map(\.id)).count == sources.count else { throw P56Error.integrity("duplicate-parent-id") }
        for source in sources {
            guard P56Digest.sha256(Data(source.text.utf8)) == source.sha256UTF8 else {
                throw P56Error.integrity("parent-source-sha256")
            }
        }
        return sources
    }

    private struct CausalDocument: Decodable { let records: [P56CausalEvidence] }
    private static func validateCausalEvidenceSnapshot(_ raw: P56Payload) throws {
        let data = Data(raw.causalEvidenceJSON.utf8)
        guard P56Digest.sha256(data) == raw.causalEvidenceSHA256 else { throw P56Error.integrity("causal-evidence-snapshot") }
        let records = try JSONDecoder().decode(CausalDocument.self, from: data).records
        guard records.count == 240 else { throw P56Error.integrity("causal-evidence-count") }
        var seen: Set<String> = []
        for book in raw.books {
            for page in book.pages {
                let key = book.id + "/" + String(page.number)
                guard seen.insert(key).inserted,
                      records.filter({ $0.bookID == book.id && $0.pageNumber == page.number }) == [page.causalEvidence] else {
                    throw P56Error.integrity("causal-evidence-lineage")
                }
            }
        }
    }

    static func validateBook(_ book: P56Book, sources: [ParentSource], templateIDs: inout Set<String>, corpusID: String? = nil) throws {
        try validateAuthoredBook(book)
        let traces = try P56StructureValidator.compile(book)
        guard traces.count == 8, book.worldID == "pilot56_world_whispering_forest_v1" else {
            throw P56Error.integrity("book-world")
        }
        for page in book.pages {
            guard templateIDs.insert(page.templateID).inserted,
                  sources.indices.contains(page.parentSourceIndex) else { throw P56Error.integrity("template-id-or-source-index") }
            let parent = sources[page.parentSourceIndex]
            guard parent.id == page.parentSourceID, parent.text == page.parentText,
                  parent.sha256UTF8 == page.parentSHA256,
                  page.parentPointer == (corpusID.map { $0 + "/" } ?? "") + "sources.json#/sources/\(page.parentSourceIndex)",
                  page.templateID == "p56_runtime_" + parent.id,
                  P56Digest.sha256(Data(page.templateText.utf8)) == page.templateSHA256,
                  try P56Personalization.template(fromSyntheticText: parent.text) == page.templateText else {
                throw P56Error.integrity("template-parent-lineage")
            }
            let setting = book.mode == .bedtime ? "pilot56_setting_forest_edge_room_v1" : "setting_whispering_forest_001"
            guard page.settingID == setting, (0...3).contains(page.intensity) else { throw P56Error.integrity("setting-or-intensity") }
        }
        if book.mode == .bedtime {
            let curve = book.pages.map(\.intensity)
            guard curve.allSatisfy({ (0...1).contains($0) }), Array(curve.suffix(3)) == [0, 0, 0],
                  zip(curve.dropFirst(), curve.dropFirst(2)).allSatisfy({ pair in pair.0 >= pair.1 }) else {
                throw P56Error.invalidStructure("bedtime-intensity-curve")
            }
        }
    }

    static func validateAuthoredBook(_ book: P56Book) throws {
        let data = Data(book.authoredBookJSON.utf8)
        guard P56Digest.sha256(data) == book.authoredBookSHA256 else { throw P56Error.integrity("authored-book-bytes") }
        let original = try JSONDecoder().decode(P56JSONValue.self, from: data)
        guard original["id"] == .string(book.id), original["planLabel"] == .string(book.structureID),
              original["context"]?["mode"] == .string(book.mode.rawValue),
              original["context"]?["companionID"] == .string(book.companionID),
              let pages = original["pages"]?.arrayValue, pages.count == book.pages.count else {
            throw P56Error.integrity("authored-book-identity")
        }
        for (page, source) in zip(book.pages, pages) {
            guard source["text"] == .string(page.parentText), source["semantics"] == page.semantics,
                  source["artHandoff"] == page.artHandoff, source["role"] == .string(page.beat.rawValue),
                  source["editorialIntensity"] == .number(Double(page.intensity)),
                  source["context"]?["settingID"] == .string(page.settingID) else {
                throw P56Error.integrity("authored-page-metadata")
            }
        }
    }

    private static func validateStructureCoverage(_ raw: P56Payload) throws {
        guard raw.books.count == 30, raw.structures.count == 9,
              Set(raw.books.map(\.id)).count == 30,
              Set(raw.structures.map(\.planLabel)).count == 9 else { throw P56Error.integrity("duplicate-or-count") }
        let ids = Set(canonicalProfiles.keys)
        var cells: [String: Set<String>] = [:]
        for structure in raw.structures {
            guard structure.pageMoves == P56StructureValidator.sequences[structure.planLabel],
                  Set(structure.allowedCompanionIDs) == allowed[structure.planLabel] else {
                throw P56Error.integrity("structure-allowlist")
            }
        }
        for book in raw.books {
            guard ids.contains(book.companionID), let structure = raw.structures.first(where: { $0.planLabel == book.structureID }),
                  structure.mode == book.mode, structure.mechanismKey == book.mechanism,
                  structure.allowedCompanionIDs.contains(book.companionID) else {
                throw P56Error.integrity("book-allowlist")
            }
            let key = book.mode.rawValue + book.companionID
            guard cells[key, default: []].insert(book.structureID).inserted else { throw P56Error.integrity("duplicate-pair") }
        }
        guard cells.count == 15, cells.values.allSatisfy({ $0.count == 2 }) else { throw P56Error.integrity("cell-coverage") }
    }

    static func validateProfiles(_ profiles: [P56CompanionProfile]) throws {
        guard profiles.count == 5, Set(profiles.map(\.id)).count == 5 else { throw P56Error.integrity("companion-count") }
        for profile in profiles {
            guard let expected = canonicalProfiles[profile.id], !profile.legacyRecordMutated,
                  [profile.name, profile.personality, profile.anatomy] == expected else {
                throw P56Error.integrity("canonical-companion-profile")
            }
        }
    }

    static let allowed: [String: Set<String>] = [
        "U1": ["companion_fox_pilot_001", "companion_owl_pilot_001", "companion_bear_001"],
        "U2": ["companion_hedgehog_pilot_001", "companion_city_cat_001", "companion_bear_001"],
        "U3": ["companion_fox_pilot_001", "companion_hedgehog_pilot_001", "companion_owl_pilot_001", "companion_city_cat_001"],
        "L1": ["companion_fox_pilot_001", "companion_owl_pilot_001", "companion_city_cat_001"],
        "L2": ["companion_hedgehog_pilot_001", "companion_owl_pilot_001", "companion_bear_001"],
        "L3": ["companion_fox_pilot_001", "companion_hedgehog_pilot_001", "companion_city_cat_001", "companion_bear_001"],
        "A1": ["companion_fox_pilot_001", "companion_hedgehog_pilot_001", "companion_city_cat_001"],
        "A2": ["companion_fox_pilot_001", "companion_owl_pilot_001", "companion_bear_001"],
        "A3": ["companion_hedgehog_pilot_001", "companion_owl_pilot_001", "companion_city_cat_001", "companion_bear_001"]]

    private static let canonicalProfiles: [String: [String]] = [
        "companion_fox_pilot_001": ["Tarçın", "Sakin eşlik; acele ettirmez; çocuğun kararını bekler.", "Dört ayak; doğal tilki ölçeği."],
        "companion_hedgehog_pilot_001": ["Kestane", "Küçük adımlarla cesaretlenir; her sahnede kaygılı değildir.", "Dört kısa ayak; dikenler korunur."],
        "companion_owl_pilot_001": ["Yıldız", "Az konuşur; dikkatle gözler; cevabı çocuğa bırakır.", "Kanatlar; tünekte dengeli ayaklar; dört ayaklı gibi kıvrılmaz."],
        "companion_city_cat_001": ["Simit", "Şehirden bugün ziyarete gelmiştir; meraklı; yavaşlamayı dener.", "Kıvrık simit kuyruğu; dört ayak. Ormanın eski sakini değildir."],
        "companion_bear_001": ["Böğürtlen", "Sakin ve güçlü; çocuğun fikrini dinler; güç cevap yerine geçmez.", "Büyük beden; geniş zemin; küçük pervaz/yatak yok."]
    ]
}
