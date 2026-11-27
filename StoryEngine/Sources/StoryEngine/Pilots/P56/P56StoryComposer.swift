import Foundation

public struct P56Request: Sendable {
    public let childID: String
    public let name: String
    public let age: Int
    public let seed: UInt64
    public let mode: P56Mode?
    public let companionID: String?
    public let forcedStructure: String?
    public let contexts: [String]
    /// Opaque reference to the caller's canonical CharacterEngine identity; never a new appearance.
    public let characterIdentityReference: String?
    public let contentSafety: ContentSafety?
    /// Books this child has already been given, most recent first (kitap
    /// kimlikleri, metin değil). Selection skips them while an unread book is
    /// left in the cell; when every candidate has been read it takes the one
    /// read longest ago. Never a support condition: the request is still
    /// supported with every book read.
    public let recentBookIDs: [String]
    public init(childID: String, name: String, age: Int, seed: UInt64, mode: P56Mode? = nil,
                companionID: String? = nil, forcedStructure: String? = nil, contexts: [String] = [],
                characterIdentityReference: String? = nil, contentSafety: ContentSafety? = nil,
                recentBookIDs: [String] = []) {
        self.childID = childID; self.name = name; self.age = age; self.seed = seed
        self.mode = mode; self.companionID = companionID; self.forcedStructure = forcedStructure
        self.contexts = contexts; self.characterIdentityReference = characterIdentityReference
        self.contentSafety = contentSafety
        self.recentBookIDs = recentBookIDs
    }
}

public struct P56PageProvenance: Codable, Hashable, Sendable {
    public let templateID: String
    public let templateSHA256: String
    public let parentSourceID: String
    public let parentSHA256: String
    public let parentPointer: String
    public let renderedSHA256: String
    public let order: Int
}

public struct P56ComposedPage: Codable, Hashable, Sendable {
    public let number: Int
    public let text: String
    public let beat: P56Beat
    public let settingID: String
    public let semantics: P56JSONValue
    public let authoredSemantics: P56JSONValue
    public let artHandoff: P56JSONValue
    public let authoredArtHandoff: P56JSONValue
    public let artApproved: Bool
    public let provenance: P56PageProvenance
    public let transition: P56Transition
}

public struct P56ComposedStory: Codable, Hashable, Sendable {
    public let sourceReference: P56SourceReference
    public let bookID: String
    public let structureID: String
    public let mechanism: String
    public let title: String
    public let mode: P56Mode
    public let age: Int
    public let seed: UInt64
    public let childID: String
    public let childName: String
    public let characterIdentityReference: String?
    public let companion: P56CompanionProfile
    public let worldID: String
    public let discoveryID: String
    public let pages: [P56ComposedPage]
}

public struct P56StoryComposer: Sendable {
    public let package: P56Package
    public init(package: P56Package) { self.package = package }

    public func compose(_ request: P56Request) throws -> P56ComposedStory {
        try validateRequest(request)
        let candidates = P56Support.candidates(for: request, package: package)
        guard !candidates.isEmpty else { throw P56Error.unsupported("selection-outside-pilot") }
        // One deterministic draw, no retry or fallback after a validation failure.
        let pool = P56Selection.unread(candidates, recent: request.recentBookIDs)
        let book = pool[Int(P56Selection.mix(request.seed) % UInt64(pool.count))]
        return try composeFixture(book: book, request: request)
    }

    /// Exact authored-book fixture for internal quality audits; never a selection retry.
    func composeFixture(book: P56Book, request: P56Request) throws -> P56ComposedStory {
        try validateRequest(request)
        guard P56Support.candidates(for: request, package: package).contains(book) else {
            throw P56Error.integrity("fixture-book-not-in-supported-source")
        }
        let traces = try P56StructureValidator.compile(book)
        let pages = try zip(book.pages, traces).map { try composePage($0, transition: $1, mode: book.mode, request: request) }
        guard let companion = package.companions.first(where: { $0.id == book.companionID }) else {
            throw P56Error.integrity("missing-companion")
        }
        return P56ComposedStory(sourceReference: package.sourceReference, bookID: book.id,
            structureID: book.structureID, mechanism: book.mechanism,
            title: try P56Personalization.render(book.titleTemplate, name: request.name), mode: book.mode,
            age: request.age, seed: request.seed, childID: request.childID, childName: request.name,
            characterIdentityReference: request.characterIdentityReference, companion: companion,
            worldID: book.worldID, discoveryID: book.discoveryID, pages: pages)
    }

    private func validateRequest(_ request: P56Request) throws {
        let ordered = P56Support.unsupportedReasons(for: request, package: package)
        if ordered.count == 1 { throw P56Error.unsupported(ordered[0]) }
        if !ordered.isEmpty { throw P56Error.unsupportedContexts(ordered) }
    }

    static func validateEnding(_ text: String, mode: P56Mode) throws {
        guard mode != .bedtime || CalmEnding.isCalm(text) else { throw P56Error.invalidStructure("bedtime-open-ending") }
    }

    private func composePage(_ page: P56TemplatePage, transition: P56Transition, mode: P56Mode,
                             request: P56Request) throws -> P56ComposedPage {
        let text = try P56Personalization.render(page.templateText, name: request.name)
        if page.number == 8 { try Self.validateEnding(text, mode: mode) }
        let band = AgeBandResolver.mvp
        let words = TextMetrics.wordCount(text)
        guard words >= band.pageBudget.lower, words <= band.pageBudget.upper,
              TextMetrics.longestSentenceWordCount(text) <= band.maxSentenceWords else {
            throw P56Error.ageBudget(page: page.number)
        }
        let provenance = P56PageProvenance(templateID: page.templateID, templateSHA256: page.templateSHA256,
            parentSourceID: page.parentSourceID, parentSHA256: page.parentSHA256,
            parentPointer: page.parentPointer, renderedSHA256: P56Digest.sha256(Data(text.utf8)), order: 0)
        return P56ComposedPage(number: page.number, text: text, beat: page.beat, settingID: page.settingID,
            semantics: try personalize(page.semantics, request: request, renderedText: text),
            authoredSemantics: page.semantics,
            artHandoff: try personalize(page.artHandoff, request: request, renderedText: text),
            authoredArtHandoff: page.artHandoff, artApproved: false,
            provenance: provenance, transition: try personalizeTransition(transition, request: request))
    }

    private func personalizeTransition(_ trace: P56Transition, request: P56Request) throws -> P56Transition {
        func actors(_ values: [String]) -> [String] { values.map { $0 == "child" ? request.childID : $0 } }
        let events = try trace.events.map { event in
            P56CausalEvent(establishes: event.establishes, requires: event.requires, actorIDs: actors(event.actorIDs),
                evidenceSourceID: event.evidenceSourceID,
                evidenceText: try P56Personalization.render(
                    P56Personalization.template(fromSyntheticText: event.evidenceText), name: request.name),
                evidence: try personalizeEvidence(event.evidence, request: request), authoredEvidence: event.authoredEvidence)
        }
        return P56Transition(beat: trace.beat, before: trace.before, after: trace.after,
            actorIDs: actors(trace.actorIDs), evidenceSourceID: trace.evidenceSourceID,
            evidenceSHA256: trace.evidenceSHA256, events: events)
    }

    private func personalizeEvidence(_ evidence: P56CausalEvidence, request: P56Request) throws -> P56CausalEvidence {
        let quote = try P56Personalization.render(
            P56Personalization.template(fromSyntheticText: evidence.quote), name: request.name)
        return P56CausalEvidence(bookID: evidence.bookID, pageNumber: evidence.pageNumber,
            actorID: evidence.actorID == "child" ? request.childID : evidence.actorID, quote: quote,
            quoteSHA256: P56Digest.sha256(Data(quote.utf8)),
            attributionQuote: evidence.actorID == "child" ? request.name : evidence.attributionQuote,
            attributionSourceID: evidence.attributionSourceID, parentSourceID: evidence.parentSourceID, kind: evidence.kind)
    }

    private func personalize(_ value: P56JSONValue, request: P56Request,
                             renderedText: String) throws -> P56JSONValue {
        switch value {
        case .string("pilot56_synthetic_child_deniz"): return .string(request.childID)
        case .string(let text):
            guard text.contains("Deniz") else { return value }
            return .string(try P56Personalization.render(
                P56Personalization.template(fromSyntheticText: text), name: request.name))
        case .array(let values):
            return .array(try values.map { try personalize($0, request: request, renderedText: renderedText) })
        case .object(let values):
            let transformed = try values.mapValues { try personalize($0, request: request, renderedText: renderedText) }
            return .object(transformed.merging(values["evidenceText"] == nil ? [:] :
                ["evidenceText": .string(renderedText)]) { _, new in new })
        default: return value
        }
    }

}

enum P56Selection {
    /// The candidates the child has not been given yet; when none is left,
    /// only the one read longest ago (the last of them in `recent`). Order is
    /// kept, so the seeded draw stays deterministic.
    static func unread(_ candidates: [P56Book], recent: [String]) -> [P56Book] {
        guard !recent.isEmpty else { return candidates }
        let read = Set(recent)
        let fresh = candidates.filter { !read.contains($0.id) }
        if !fresh.isEmpty { return fresh }
        let age = Dictionary(recent.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        let oldest = candidates.max { (age[$0.id] ?? .max) < (age[$1.id] ?? .max) }
        return oldest.map { [$0] } ?? candidates
    }

    static func mix(_ seed: UInt64) -> UInt64 {
        var z = seed &+ 0x9e3779b97f4a7c15
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
