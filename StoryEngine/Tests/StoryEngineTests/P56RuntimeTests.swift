import XCTest
@testable import StoryEngine

final class P56RuntimeTests: XCTestCase {
    private var directory: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Content/Pilots/five-friends-56-runtime-v1")
    }

    private func package() throws -> P56Package {
        let data = try Data(contentsOf: directory.appendingPathComponent("payload.json"))
        let manifest = try JSONDecoder().decode(P56RuntimeManifest.self,
            from: Data(contentsOf: directory.appendingPathComponent("manifest.json")))
        return try P56PackageLoader.load(payload: data, expectedSHA256: manifest.payloadSHA256)
    }

    func testSHA256KnownVectors() {
        XCTAssertEqual(P56Digest.sha256(Data()), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        XCTAssertEqual(P56Digest.sha256(Data("abc".utf8)), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    func testAllThirtyPairsHaveDeterministicCompleteTraces() throws {
        let catalog = try package()
        XCTAssertEqual(catalog.books.count, 30)
        var cells: [String: Set<String>] = [:]
        for book in catalog.books {
            let request = P56Request(childID: "test-child", name: "İrem", age: 6, seed: 42,
                mode: book.mode, companionID: book.companionID, forcedStructure: book.structureID)
            let composer = P56StoryComposer(package: catalog)
            let first = try composer.compose(request)
            XCTAssertEqual(first, try composer.compose(request))
            XCTAssertEqual(first.pages.count, 8)
            XCTAssertFalse(first.pages.contains { $0.text.contains("Deniz") || $0.text.contains("{{") })
            XCTAssertEqual(first.pages.map(\.number), Array(1...8))
            XCTAssertTrue(first.pages.allSatisfy { $0.provenance.renderedSHA256 == P56Digest.sha256(Data($0.text.utf8)) })
            XCTAssertTrue(first.pages.allSatisfy { !$0.artApproved })
            cells[book.mode.rawValue + book.companionID, default: []].insert(book.structureID)
        }
        XCTAssertEqual(cells.count, 15)
        XCTAssertTrue(cells.values.allSatisfy { $0.count == 2 })
    }

    func testUnsupportedContextPreservesReason() throws {
        let composer = P56StoryComposer(package: try package())
        for context in ["family", "guest", "recall", "occasion", "series", "topic", "unknown"] {
            XCTAssertThrowsError(try composer.compose(P56Request(childID: "x", name: "İrem", age: 5,
                seed: 1, contexts: [context]))) { error in
                XCTAssertEqual(error as? P56Error, .unsupported(context))
            }
        }
        XCTAssertThrowsError(try composer.compose(P56Request(childID: "x", name: "İrem", age: 7, seed: 1)))
    }

    func testPayloadTamperRejected() throws {
        let data = try Data(contentsOf: directory.appendingPathComponent("payload.json"))
        XCTAssertThrowsError(try P56PackageLoader.load(payload: data + Data([32]),
            expectedSHA256: P56Digest.sha256(data)))
    }

    func testSevenTurkishNamesAndCaseForms() throws {
        for name in ["İrem", "Işıl", "Ece", "Öykü", "Çağrı", "Ali", "Yağmur"] {
            let text = try P56Personalization.render("{{child.name}} {{child.name}}'in {{child.name}}'e", name: name)
            XCTAssertTrue(text.hasPrefix(name + " "))
            XCTAssertFalse(text.contains("{{"))
            XCTAssertEqual(text, name + " " + TurkishGrammar.inflect(TurkishNoun(name, isProperNoun: true), into: .genitive)
                + " " + TurkishGrammar.inflect(TurkishNoun(name, isProperNoun: true), into: .dative))
        }
    }

    private func changedPayload(_ change: (inout [String: Any]) -> Void) throws -> Data {
        let original = try Data(contentsOf: directory.appendingPathComponent("payload.json"))
        var value = try XCTUnwrap(JSONSerialization.jsonObject(with: original) as? [String: Any])
        change(&value)
        return try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
    }

    private func assertInvalid(_ change: (inout [String: Any]) -> Void,
                               file: StaticString = #filePath, line: UInt = #line) throws {
        let data = try changedPayload(change)
        XCTAssertThrowsError(try P56PackageLoader.load(payload: data, expectedSHA256: P56Digest.sha256(data)),
            file: file, line: line)
    }

    func testMalformedProfilesSchemaAndDuplicateIDsFailClosed() throws {
        try assertInvalid { $0["engineBehaviorID"] = "offline-legacy-v1" }
        try assertInvalid { $0["schemaVersion"] = 2 }
        try assertInvalid { $0["productionEnabled"] = true }
        try assertInvalid {
            var books = $0["books"] as! [[String: Any]]
            books[1]["id"] = books[0]["id"]; $0["books"] = books
        }
        try assertInvalid {
            var profiles = $0["companions"] as! [[String: Any]]
            profiles[0]["anatomy"] = "invented hands"; $0["companions"] = profiles
        }
        try assertInvalid {
            var structures = $0["structures"] as! [[String: Any]]
            structures[0]["allowedCompanionIDs"] = ["companion_city_cat_001"]; $0["structures"] = structures
        }
    }

    func testMutatedSourceParentPointerAndActorsFailClosed() throws {
        for key in ["templateText", "templateSHA256", "parentSHA256", "parentPointer", "parentSourceID"] {
            try assertInvalid {
                var books = $0["books"] as! [[String: Any]]
                var pages = books[0]["pages"] as! [[String: Any]]
                pages[0][key] = "tampered"; books[0]["pages"] = pages; $0["books"] = books
            }
        }
        try assertInvalid {
            var books = $0["books"] as! [[String: Any]]
            let index = books.firstIndex { $0["structureID"] as? String == "U3" }!
            var pages = books[index]["pages"] as! [[String: Any]]
            pages[3]["actorIDs"] = [books[index]["companionID"] as! String]
            books[index]["pages"] = pages; $0["books"] = books
        }
    }

    func testWaitingSupportDoesNotInventAnObservation() throws {
        let catalog = try package()
        for book in catalog.books.filter({ $0.structureID == "L3" }) {
            let traces = try P56StructureValidator.compile(book)
            XCTAssertEqual(traces[2].events.map(\.establishes), [.waitingSupportOffered])
            XCTAssertFalse(traces[2].events.map(\.establishes).contains(.supportingObservation))
            XCTAssertTrue(traces[5].events[0].requires.contains(.firstObservation))
            XCTAssertTrue(traces[5].events[0].requires.contains(.decisiveObservation))
        }
    }

    func testMissingObservationFakeCareAndEarlyRetrievalFailClosed() throws {
        for badBeat in ["comfort_need", "object_recovered", "child_infers"] {
            try assertInvalid {
                var books = $0["books"] as! [[String: Any]]
                let index = books.firstIndex { $0["structureID"] as? String == "U3" }!
                var pages = books[index]["pages"] as! [[String: Any]]
                pages[1]["beat"] = badBeat; books[index]["pages"] = pages; $0["books"] = books
            }
        }
        try assertInvalid {
            var books = $0["books"] as! [[String: Any]]
            let index = books.firstIndex { $0["structureID"] as? String == "L1" }!
            var pages = books[index]["pages"] as! [[String: Any]]
            pages.remove(at: 4); books[index]["pages"] = pages; $0["books"] = books
        }
    }

    func testMemoryStaysRememberedAndClosedEyesAreNotSleep() throws {
        let catalog = try package()
        let composer = P56StoryComposer(package: catalog)
        for book in catalog.books.filter({ $0.structureID == "U3" }) {
            let story = try composer.compose(P56Request(childID: "actual-child", name: "Işıl", age: 5, seed: 0,
                mode: book.mode, companionID: book.companionID, forcedStructure: "U3"))
            XCTAssertFalse(story.pages.last!.transition.after.actualSleep)
            for page in story.pages.dropFirst().dropLast() {
                let memory = page.semantics["subjects"]!.arrayValue!.filter {
                    $0["subjectID"] == .string(book.discoveryID)
                }
                XCTAssertTrue(memory.allSatisfy { $0["presence"] == .string("remembered") })
            }
        }
        try assertInvalid {
            var books = $0["books"] as! [[String: Any]]
            let index = books.firstIndex { $0["structureID"] as? String == "U3" }!
            var pages = books[index]["pages"] as! [[String: Any]]
            var semantics = pages[1]["semantics"] as! [String: Any]
            var subjects = semantics["subjects"] as! [[String: Any]]
            let memoryIndex = subjects.firstIndex { $0["presence"] as? String == "remembered" }!
            subjects[memoryIndex]["presence"] = "present"; semantics["subjects"] = subjects
            pages[1]["semantics"] = semantics; books[index]["pages"] = pages; $0["books"] = books
        }
    }

    func testAllUnsupportedContextsAndSafetyArePreserved() throws {
        let composer = P56StoryComposer(package: try package())
        XCTAssertThrowsError(try composer.compose(P56Request(childID: "x", name: "İrem", age: 5, seed: 1,
            contexts: ["family", "recall", "series"]))) {
            XCTAssertEqual($0 as? P56Error, .unsupportedContexts(["family", "recall", "series"]))
        }
        XCTAssertThrowsError(try composer.compose(P56Request(childID: "x", name: "İrem", age: 5,
            seed: 1, contentSafety: .mostProtective))) {
            XCTAssertEqual($0 as? P56Error, .unsupported("content-safety-not-reviewed"))
        }
    }

    func testBedtimeEndingRejectsQuestionTomorrowAndOpenHook() throws {
        for ending in ["Gözlerini kapattı. Acaba?", "Yarın ne olacaktı.", "Birden bir ses duyuldu."] {
            XCTAssertThrowsError(try P56StoryComposer.validateEnding(ending, mode: .bedtime))
        }
        XCTAssertNoThrow(try P56StoryComposer.validateEnding("Akşam burada sakince bitmişti.", mode: .bedtime))
    }

    func testUnsupportedRequestAggregatesContextAgeSafetyAndSelection() throws {
        let composer = P56StoryComposer(package: try package())
        XCTAssertThrowsError(try composer.compose(P56Request(childID: "x", name: "İrem", age: 7, seed: 1,
            companionID: "outside", contexts: ["family", "series"], contentSafety: .mostProtective))) {
            XCTAssertEqual($0 as? P56Error, .unsupportedContexts(["age", "companion", "content-safety-not-reviewed",
                "family", "selection-outside-pilot", "series"]))
        }
    }

    func testCausalActionQuoteActorAndLineageCannotBeSwapped() throws {
        for key in ["actorID", "quote", "quoteSHA256", "parentSourceID", "attributionSourceID"] {
            try assertInvalid {
                var books = $0["books"] as! [[String: Any]]
                var pages = books[0]["pages"] as! [[String: Any]]
                var evidence = pages[0]["causalEvidence"] as! [String: Any]
                evidence[key] = "tampered"; pages[0]["causalEvidence"] = evidence
                books[0]["pages"] = pages; $0["books"] = books
            }
        }
    }

    func testFirstAttempt1500Report() throws {
        let catalog = try package()
        let report = P56Sampler.run(package: catalog, count: 1500)
        if let path = ProcessInfo.processInfo.environment["P56_REPORT_DIRECTORY"] {
            let directory = URL(fileURLWithPath: path)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(report).write(to: directory.appendingPathComponent("sampling.json"))
            let composer = P56StoryComposer(package: catalog)
            let drafts = try catalog.books.map { book in
                try composer.compose(P56Request(childID: "p56-sampler", name: "İrem", age: 6, seed: 42,
                    mode: book.mode, companionID: book.companionID, forcedStructure: book.structureID))
            }
            try encoder.encode(drafts).write(to: directory.appendingPathComponent("forced-books.json"))
        }
        XCTAssertEqual(report.attempts, 1500)
        XCTAssertEqual(report.failures, 0, "\(report.failureReasons)")
        XCTAssertEqual(report.successes + report.failures, report.attempts)
        XCTAssertEqual(report.bookCounts.count, 30)
        if let path = ProcessInfo.processInfo.environment["P56_REPORT_PATH"] {
            try JSONEncoder().encode(report).write(to: URL(fileURLWithPath: path))
        }
    }
}
