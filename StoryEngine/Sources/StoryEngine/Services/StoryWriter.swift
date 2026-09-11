import Foundation

// MARK: - Narrative drafting

/// Writes the whole story in one pass, before any page boundaries exist.
///
/// This is the deliberate rejection of per-page generation. A page written on
/// its own drifts: the narrator changes register, phrases repeat, the emotional
/// arc flattens because no single call ever saw the shape of the book. Writing
/// the draft whole and cutting it afterwards costs one large call instead of
/// N small ones, and it is the only way the pacing is decided by something that
/// can see the ending.
public struct NarrativeDrafter: Sendable {
    private let aiService: StoryAIService
    private let idGenerator: IDGenerator

    public init(aiService: StoryAIService, idGenerator: IDGenerator = RandomIDGenerator()) {
        self.aiService = aiService
        self.idGenerator = idGenerator
    }

    public struct Result: Sendable {
        public let draft: NarrativeDraft
        public let attempts: [StoryGenerationAttempt]
    }

    struct DraftResponse: Codable {
        struct Voice: Codable {
            let narratorRegister: String?
            let sentenceRhythm: String?
            let recurringMotifs: [String]?
            let characterVoices: [String: String]?
        }
        struct Segment: Codable {
            let beatIndex: Int?
            let templateBeatID: String?
            let text: String
        }
        let voiceProfile: Voice?
        let segments: [Segment]
    }

    public func draft(
        request: StoryRequest,
        template: ResolvedTemplate,
        outline: StoryOutline,
        characters: [StoryCharacter],
        pages: [StoryPage],
        storyID: UUID,
        now: Date
    ) async throws -> Result {
        let assembler = PromptAssembler(template: template.template)
        let budgets = wordBudgetBlock(outline: outline, pages: pages)

        let aiRequest = AICompletionRequest(
            operation: .narrativeDraft,
            modelTier: template.template.generationPolicy.draftModelTier,
            systemInstructions: assembler.systemInstructions(extra: [
                """
                Write the complete story in one pass so that voice, pacing and the \
                emotional arc are consistent from first page to last. Write each beat \
                as continuous prose; do not add headings, page numbers or labels.
                """
            ]),
            userInstructions: [
                assembler.settingsBlock(themeKey: request.themeKey, languageCode: request.languageCode, toneKey: request.toneKey),
                assembler.castBlock(characters),
                assembler.outlineBlock(outline),
                budgets,
                """
                Also describe the voice you wrote in, so later edits to a single page \
                can match it: the narrator's register, the sentence rhythm, any \
                recurring motifs, and how each character speaks.
                """
            ],
            responseSchemaDescription: Self.schemaDescription,
            languageCode: request.languageCode,
            temperature: 0.85,
            identity: IdempotencyKeyFactory.narrativeDraft(
                storyID: storyID, outline: outline, templateRef: template.ref
            )
        )

        let result = try await aiService.complete(
            aiRequest,
            stage: .draftNarrative,
            estimate: UsageEstimate(operation: .narrativeDraft, tokens: 16_000, costUSD: 0.12),
            decoding: DraftResponse.self
        )

        return Result(
            draft: buildDraft(from: result.value, outline: outline, now: now),
            attempts: result.attempts
        )
    }

    /// Tells the model how much room each beat has, so segmentation is a cut
    /// rather than a rescue.
    private func wordBudgetBlock(outline: StoryOutline, pages: [StoryPage]) -> String {
        let pagesByBeat = Dictionary(grouping: pages, by: \.outlineBeatID)
        let lines = outline.beats.sorted { $0.ordinal < $1.ordinal }.map { beat -> String in
            let beatPages = pagesByBeat[beat.id] ?? []
            let minimum = beatPages.reduce(0) { $0 + $1.minimumWords }
            let maximum = beatPages.reduce(0) { $0 + $1.maximumWords }
            return "\(beat.ordinal). \(minimum)–\(maximum) words"
        }
        return (["LENGTH — stay inside these per beat:"] + lines).joined(separator: "\n")
    }

    func buildDraft(from response: DraftResponse, outline: StoryOutline, now: Date) -> NarrativeDraft {
        let ordered = outline.beats.sorted { $0.ordinal < $1.ordinal }
        let byTemplateID = Dictionary(grouping: response.segments.filter { $0.templateBeatID != nil }, by: { $0.templateBeatID! })
        var templateCursor: [String: Int] = [:]

        let segments = ordered.enumerated().map { index, beat -> DraftSegment in
            // Index first, since that is what the model was asked for; the
            // template id is a fallback for models that reorder.
            var text = index < response.segments.count ? response.segments[index].text : ""
            if let answered = response.segments.first(where: { $0.beatIndex == beat.ordinal }) {
                text = answered.text
            } else if let candidates = byTemplateID[beat.templateBeatID] {
                let cursor = templateCursor[beat.templateBeatID, default: 0]
                if cursor < candidates.count {
                    text = candidates[cursor].text
                    templateCursor[beat.templateBeatID] = cursor + 1
                }
            }
            return DraftSegment(id: idGenerator.next(), outlineBeatID: beat.id, text: text.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let voice = response.voiceProfile
        return NarrativeDraft(
            id: idGenerator.next(),
            voiceProfile: VoiceProfile(
                narratorRegister: voice?.narratorRegister?.trimmed ?? "warm, close third person",
                sentenceRhythm: voice?.sentenceRhythm?.trimmed ?? "short sentences with occasional longer ones",
                recurringMotifs: voice?.recurringMotifs ?? [],
                characterVoices: voice?.characterVoices ?? [:]
            ),
            segments: segments,
            createdAt: now
        )
    }

    static let schemaDescription = """
    {
      "voiceProfile": {
        "narratorRegister": "string",
        "sentenceRhythm": "string",
        "recurringMotifs": ["string"],
        "characterVoices": { "CharacterName": "how they speak" }
      },
      "segments": [
        { "beatIndex": 0, "templateBeatID": "string", "text": "the prose for this beat" }
      ]
    }
    """
}

// MARK: - Segmentation

/// Cuts the draft into pages.
///
/// Deterministic and AI-free. It moves whole sentences, so a page can never end
/// mid-sentence, and it measures words with exactly the same counter the
/// validator uses later — otherwise a page could be segmented "in budget" and
/// then fail validation for being out of it.
public struct PageSegmenter: Sendable {
    public init() {}

    public func segment(draft: NarrativeDraft, pages: [StoryPage]) -> [StoryPage] {
        let pagesByBeat = Dictionary(grouping: pages, by: \.outlineBeatID)
        var updated: [UUID: String] = [:]

        for (beatID, beatPages) in pagesByBeat {
            let ordered = beatPages.sorted { $0.index < $1.index }
            let text = draft.segment(forBeat: beatID)?.text ?? ""
            let assigned = distribute(text: text, across: ordered)
            for (page, value) in zip(ordered, assigned) {
                updated[page.id] = value
            }
        }

        return pages.map { page in
            var copy = page
            copy.text = updated[page.id] ?? ""
            return copy
        }
    }

    /// Greedy fill by sentence, honouring each page's ceiling.
    ///
    /// Overflow lands on the last page rather than being dropped: losing a
    /// paragraph of a child's story to stay inside a layout is the wrong
    /// trade, and the validator will flag the long page.
    func distribute(text: String, across pages: [StoryPage]) -> [String] {
        guard !pages.isEmpty else { return [] }
        guard pages.count > 1 else { return [text.trimmingCharacters(in: .whitespacesAndNewlines)] }

        let sentences = TextMetrics.sentences(text)
        guard !sentences.isEmpty else { return Array(repeating: "", count: pages.count) }

        var result = Array(repeating: [String](), count: pages.count)
        var pageIndex = 0
        var wordsOnPage = 0

        for sentence in sentences {
            let words = TextMetrics.wordCount(sentence)
            let isLastPage = pageIndex == pages.count - 1
            let wouldOverflow = wordsOnPage + words > pages[pageIndex].maximumWords

            if wouldOverflow && !isLastPage && wordsOnPage >= pages[pageIndex].minimumWords {
                pageIndex += 1
                wordsOnPage = 0
            } else if wouldOverflow && !isLastPage && !result[pageIndex].isEmpty {
                // Under minimum but already overflowing: move on anyway rather
                // than pile everything onto one page.
                pageIndex += 1
                wordsOnPage = 0
            }

            result[pageIndex].append(sentence)
            wordsOnPage += words
        }

        return result.map { $0.joined(separator: " ") }
    }
}

// MARK: - Refinement

/// Polishes one page against the book's established voice.
///
/// Also the unit of single-page regeneration: because it is given the draft's
/// voice profile and the neighbouring pages, a page rewritten weeks later still
/// sounds like the book it belongs to.
public struct PageRefiner: Sendable {
    private let aiService: StoryAIService

    public init(aiService: StoryAIService) { self.aiService = aiService }

    public struct Result: Sendable {
        public let title: String
        public let text: String
        public let attempts: [StoryGenerationAttempt]
    }

    struct RefinementResponse: Codable {
        let title: String?
        let text: String
    }

    public func refine(
        page: StoryPage,
        story context: RefinementContext,
        instruction: String? = nil
    ) async throws -> Result {
        let assembler = PromptAssembler(template: context.template.template)
        let beat = context.outline.beat(id: page.outlineBeatID)

        var userInstructions = [
            assembler.settingsBlock(
                themeKey: context.themeKey,
                languageCode: context.languageCode,
                toneKey: context.toneKey
            ),
            assembler.castBlock(context.characters),
            assembler.voiceBlock(context.voiceProfile)
        ]

        if let beat {
            userInstructions.append("THIS PAGE covers: \(beat.summary) — \(beat.settingKey), \(beat.timeOfDayKey), \(beat.moodKey)")
        }
        if let previous = context.previousPageText {
            userInstructions.append("THE PAGE BEFORE ends:\n\(String(previous.suffix(400)))")
        }
        if let next = context.nextPageText {
            userInstructions.append("THE PAGE AFTER begins:\n\(String(next.prefix(400)))")
        }
        userInstructions.append("CURRENT TEXT:\n\(page.text)")
        userInstructions.append("LENGTH: \(page.minimumWords)–\(page.maximumWords) words.")
        if let instruction {
            userInstructions.append("THE PARENT ASKED FOR: \(instruction)")
        }
        userInstructions.append(
            "Rewrite this page only. It must flow from the page before and into the page after."
        )

        let aiRequest = AICompletionRequest(
            operation: .pageRefinement,
            modelTier: context.template.template.generationPolicy.refinementModelTier,
            systemInstructions: assembler.systemInstructions(extra: [
                "You are editing one page of an existing book. Match the established voice exactly."
            ]),
            userInstructions: userInstructions,
            responseSchemaDescription: #"{ "title": "short page title", "text": "the page text" }"#,
            languageCode: context.languageCode,
            temperature: 0.7,
            identity: IdempotencyKeyFactory.pageRefinement(
                storyID: context.storyID, page: page, instruction: instruction
            )
        )

        let result = try await aiService.complete(
            aiRequest,
            stage: .refinePages,
            estimate: UsageEstimate(operation: .pageRefinement, tokens: 2_500, costUSD: 0.01),
            decoding: RefinementResponse.self
        )

        return Result(
            title: result.value.title?.trimmed ?? page.title,
            text: result.value.text.trimmingCharacters(in: .whitespacesAndNewlines),
            attempts: result.attempts
        )
    }
}

/// What a refinement needs to know about the book around the page.
public struct RefinementContext: Sendable {
    public let storyID: UUID
    public let template: ResolvedTemplate
    public let outline: StoryOutline
    public let characters: [StoryCharacter]
    public let voiceProfile: VoiceProfile
    public let previousPageText: String?
    public let nextPageText: String?
    public let themeKey: String
    public let languageCode: String
    public let toneKey: String?

    public init(
        storyID: UUID,
        template: ResolvedTemplate,
        outline: StoryOutline,
        characters: [StoryCharacter],
        voiceProfile: VoiceProfile,
        previousPageText: String?,
        nextPageText: String?,
        themeKey: String,
        languageCode: String,
        toneKey: String?
    ) {
        self.storyID = storyID
        self.template = template
        self.outline = outline
        self.characters = characters
        self.voiceProfile = voiceProfile
        self.previousPageText = previousPageText
        self.nextPageText = nextPageText
        self.themeKey = themeKey
        self.languageCode = languageCode
        self.toneKey = toneKey
    }

    /// Builds the context for one page of a story.
    public static func make(
        for page: StoryPage,
        story: Story,
        request: StoryRequest,
        template: ResolvedTemplate
    ) throws -> RefinementContext {
        guard let outline = story.outline else {
            throw StoryEngineError.stageOutOfOrder(expected: .planStory, actual: .refinePages)
        }
        let ordered = story.pages.sorted { $0.index < $1.index }
        let position = ordered.firstIndex { $0.id == page.id }

        return RefinementContext(
            storyID: story.id,
            template: template,
            outline: outline,
            characters: story.characters,
            voiceProfile: story.draft?.voiceProfile
                ?? VoiceProfile(narratorRegister: "warm, close third person", sentenceRhythm: "short sentences"),
            previousPageText: position.flatMap { $0 > 0 ? ordered[$0 - 1].text : nil },
            nextPageText: position.flatMap { $0 + 1 < ordered.count ? ordered[$0 + 1].text : nil },
            themeKey: request.themeKey,
            languageCode: request.languageCode,
            toneKey: request.toneKey
        )
    }
}
