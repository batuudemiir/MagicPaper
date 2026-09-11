import XCTest
@testable import StoryEngine

final class TextMetricsTests: XCTestCase {
    func testWordCountIgnoresPunctuation() {
        XCTAssertEqual(TextMetrics.wordCount("Hello, world! How are you?"), 5)
        XCTAssertEqual(TextMetrics.wordCount("   "), 0)
    }

    func testSentencesKeepTheirPunctuation() {
        let sentences = TextMetrics.sentences("One. Two! Three? Four")
        XCTAssertEqual(sentences, ["One.", "Two!", "Three?", "Four"])
    }

    func testDialogueAndItsAttributionStayOneSentence() {
        let sentences = TextMetrics.sentences(#""Stop!" said Deniz. Then it was quiet."#)
        XCTAssertEqual(sentences.count, 2)
        XCTAssertEqual(sentences[0], #""Stop!" said Deniz."#)
        XCTAssertEqual(sentences[1], "Then it was quiet.")
    }

    func testDialogueEndingASentenceStillSplits() {
        let sentences = TextMetrics.sentences(#"Deniz shouted, "Stop!" The wood went quiet."#)
        XCTAssertEqual(sentences.count, 2)
        XCTAssertEqual(sentences[1], "The wood went quiet.")
    }

    func testLongestSentenceIsMeasured() {
        XCTAssertEqual(TextMetrics.longestSentenceWordCount("Short. A rather longer sentence sits here."), 6)
    }

    func testNGramsAreLowercasedAndWindowed() {
        XCTAssertEqual(TextMetrics.nGrams("The Quick Brown Fox", size: 2), ["the quick", "quick brown", "brown fox"])
        XCTAssertTrue(TextMetrics.nGrams("Too short", size: 5).isEmpty)
    }
}

final class PageSegmenterTests: XCTestCase {
    private let segmenter = PageSegmenter()

    private func pages(_ budgets: [(min: Int, max: Int)]) -> [StoryPage] {
        budgets.enumerated().map { index, budget in
            StoryPage(
                id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index))!,
                index: index,
                outlineBeatID: UUID(uuidString: "DDDDDDDD-0000-0000-0000-000000000001")!,
                templateBeatID: "b",
                beatRole: .middle,
                sceneID: UUID(),
                layout: .imageTopTextBottom,
                layoutRuleID: "r",
                compositionRuleID: "c",
                typographyPresetID: "t",
                minimumWords: budget.min,
                maximumWords: budget.max
            )
        }
    }

    func testASinglePageTakesTheWholeSegment() {
        let text = "One sentence. Another sentence. A third one."
        XCTAssertEqual(segmenter.distribute(text: text, across: pages([(10, 20)])), [text])
    }

    func testSentencesAreNeverSplit() {
        let text = (0..<12).map { "Sentence number \($0) sits here quietly." }.joined(separator: " ")
        let result = segmenter.distribute(text: text, across: pages([(10, 20), (10, 20), (10, 20)]))

        for page in result {
            for sentence in TextMetrics.sentences(page) {
                XCTAssertTrue(sentence.hasSuffix("."), "A page ended mid-sentence: \(sentence)")
            }
        }
        XCTAssertEqual(
            TextMetrics.sentences(result.joined(separator: " ")).count,
            TextMetrics.sentences(text).count,
            "No sentence is lost or duplicated"
        )
    }

    func testPagesFillUpToTheirCeilingBeforeMovingOn() {
        let text = (0..<10).map { "Sentence \($0) has exactly six words." }.joined(separator: " ")
        let result = segmenter.distribute(text: text, across: pages([(6, 18), (6, 18), (6, 60)]))

        XCTAssertLessThanOrEqual(TextMetrics.wordCount(result[0]), 18)
        XCTAssertLessThanOrEqual(TextMetrics.wordCount(result[1]), 18)
        XCTAssertFalse(result[0].isEmpty)
        XCTAssertFalse(result[1].isEmpty)
    }

    func testOverflowLandsOnTheLastPageRatherThanBeingDropped() {
        let text = (0..<20).map { "Sentence \($0) has exactly six words." }.joined(separator: " ")
        let result = segmenter.distribute(text: text, across: pages([(6, 12), (6, 12)]))

        XCTAssertEqual(
            TextMetrics.sentences(result.joined(separator: " ")).count, 20,
            "A child's story must not lose paragraphs to fit a layout"
        )
        XCTAssertGreaterThan(TextMetrics.wordCount(result[1]), 12, "The overflow is visible, for the validator to flag")
    }

    func testAShortDraftLeavesLaterPagesEmpty() {
        let result = segmenter.distribute(text: "Just one sentence here.", across: pages([(20, 40), (20, 40)]))
        XCTAssertEqual(result[0], "Just one sentence here.")
        XCTAssertEqual(result[1], "")
    }

    func testEmptyTextProducesEmptyPages() {
        XCTAssertEqual(segmenter.distribute(text: "", across: pages([(5, 10), (5, 10)])), ["", ""])
    }

    func testSegmentationIsDeterministic() {
        let text = (0..<15).map { "Sentence \($0) sits quietly in the grass." }.joined(separator: " ")
        let a = segmenter.distribute(text: text, across: pages([(8, 16), (8, 16), (8, 40)]))
        let b = segmenter.distribute(text: text, across: pages([(8, 16), (8, 16), (8, 40)]))
        XCTAssertEqual(a, b)
    }

    func testSegmentingADraftFillsEveryPage() throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 7)
        let draft = NarrativeDraft(
            id: UUID(),
            voiceProfile: VoiceProfile(narratorRegister: "warm", sentenceRhythm: "short"),
            segments: planned.outline.beats.map {
                DraftSegment(id: UUID(), outlineBeatID: $0.id, text: ScriptedResponses.prose(words: 80, seed: $0.ordinal))
            },
            createdAt: StoryFixtures.referenceDate
        )

        let pages = segmenter.segment(draft: draft, pages: planned.pages)

        XCTAssertEqual(pages.count, 7)
        XCTAssertTrue(pages.allSatisfy(\.hasText))
        XCTAssertEqual(pages.map(\.index), Array(0..<7))
    }

    func testAMissingDraftSegmentLeavesThatPageEmptyRatherThanShiftingOthers() throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 5)
        let draft = NarrativeDraft(
            id: UUID(),
            voiceProfile: VoiceProfile(narratorRegister: "warm", sentenceRhythm: "short"),
            // The model skipped the third beat.
            segments: planned.outline.beats.filter { $0.ordinal != 2 }.map {
                DraftSegment(id: UUID(), outlineBeatID: $0.id, text: ScriptedResponses.prose(words: 60, seed: $0.ordinal))
            },
            createdAt: StoryFixtures.referenceDate
        )

        let pages = segmenter.segment(draft: draft, pages: planned.pages)

        XCTAssertFalse(pages[2].hasText, "The gap stays where it is, for validation to catch")
        XCTAssertTrue(pages[3].hasText, "Later pages keep their own text")
    }
}

final class DraftAlignmentTests: XCTestCase {
    func testSegmentsAreMatchedByBeatIndex() throws {
        let planned = try StoryFixtures.plannedStory(pageCount: 5)
        let drafter = NarrativeDrafter(
            aiService: StoryAIService(
                provider: FakeStoryAIProvider(),
                budget: GenerationBudgetManager(budget: .standard),
                policy: RetryPolicy(),
                clock: FixedClock()
            ),
            idGenerator: SequentialIDGenerator(startingAt: 3_000)
        )

        // Deliberately out of order: the model returned the last beat first.
        let response = NarrativeDrafter.DraftResponse(
            voiceProfile: nil,
            segments: [
                .init(beatIndex: 4, templateBeatID: nil, text: "Ending text."),
                .init(beatIndex: 0, templateBeatID: nil, text: "Opening text."),
                .init(beatIndex: 1, templateBeatID: nil, text: "Second text."),
                .init(beatIndex: 2, templateBeatID: nil, text: "Third text."),
                .init(beatIndex: 3, templateBeatID: nil, text: "Fourth text.")
            ]
        )

        let draft = drafter.buildDraft(from: response, outline: planned.outline, now: StoryFixtures.referenceDate)

        XCTAssertEqual(draft.segments.first?.text, "Opening text.")
        XCTAssertEqual(draft.segments.last?.text, "Ending text.")
    }

    func testAMissingVoiceProfileFallsBackRatherThanFailing() throws {
        // The shipped template's floor is five pages, so this is what a
        // three-page request actually becomes.
        let planned = try StoryFixtures.plannedStory(pageCount: 5)
        let drafter = NarrativeDrafter(
            aiService: StoryAIService(
                provider: FakeStoryAIProvider(),
                budget: GenerationBudgetManager(budget: .standard),
                policy: RetryPolicy(),
                clock: FixedClock()
            ),
            idGenerator: SequentialIDGenerator(startingAt: 4_000)
        )
        let response = NarrativeDrafter.DraftResponse(
            voiceProfile: nil,
            segments: [.init(beatIndex: 0, templateBeatID: nil, text: "Only one.")]
        )

        let draft = drafter.buildDraft(from: response, outline: planned.outline, now: StoryFixtures.referenceDate)
        XCTAssertFalse(draft.voiceProfile.narratorRegister.isEmpty)
        XCTAssertEqual(draft.segments.count, planned.outline.beats.count, "Every beat gets a segment, even an empty one")
    }
}

final class JSONExtractionTests: XCTestCase {
    func testPlainJSONIsReturnedAsIs() {
        XCTAssertEqual(StoryAIService.extractJSON(from: #"{"a":1}"#), #"{"a":1}"#)
    }

    func testFencedJSONIsUnwrapped() {
        let text = "Here you go:\n```json\n{\"a\":1}\n```\nHope that helps!"
        XCTAssertEqual(StoryAIService.extractJSON(from: text), #"{"a":1}"#)
    }

    func testUnlabelledFenceIsUnwrapped() {
        XCTAssertEqual(StoryAIService.extractJSON(from: "```\n{\"a\":1}\n```"), #"{"a":1}"#)
    }

    func testProseAroundJSONIsStripped() {
        XCTAssertEqual(StoryAIService.extractJSON(from: "Sure! {\"a\":1} Let me know."), #"{"a":1}"#)
    }

    func testArraysAreSupported() {
        XCTAssertEqual(StoryAIService.extractJSON(from: "result: [1,2,3]"), "[1,2,3]")
    }

    func testNoJSONYieldsEmpty() {
        XCTAssertEqual(StoryAIService.extractJSON(from: "I am afraid I cannot help with that."), "")
    }

    func testUnparseableResponseIsReportedAsMalformed() {
        struct Shape: Codable { let a: Int }
        XCTAssertThrowsError(try StoryAIService.decode(Shape.self, from: "not json at all", operation: .outline)) { error in
            guard case .malformedProviderResponse(let operation, _) = error as? StoryEngineError else {
                return XCTFail("Unexpected error \(error)")
            }
            XCTAssertEqual(operation, .outline)
        }
    }
}
