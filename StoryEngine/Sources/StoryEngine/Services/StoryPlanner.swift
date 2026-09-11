import Foundation

/// Turns a request into an outline: one LLM call, filling in the template's
/// beat skeleton with this story's specifics.
///
/// What the model may decide: the title, the logline, and each beat's summary,
/// setting, time and mood. What it may not: how many beats there are, what
/// order they come in, or which template beat each one is — those are the
/// deterministic beat plan, and the model's answer is aligned onto them rather
/// than trusted to reproduce them.
public struct StoryPlanner: Sendable {
    private let aiService: StoryAIService
    private let beatPlanner: BeatPlanner
    private let idGenerator: IDGenerator

    public init(aiService: StoryAIService, beatPlanner: BeatPlanner = BeatPlanner(), idGenerator: IDGenerator = RandomIDGenerator()) {
        self.aiService = aiService
        self.beatPlanner = beatPlanner
        self.idGenerator = idGenerator
    }

    public struct Result: Sendable {
        public let outline: StoryOutline
        public let beatPlan: BeatPlan
        public let attempts: [StoryGenerationAttempt]
    }

    struct OutlineResponse: Codable {
        struct Beat: Codable {
            let templateBeatID: String?
            let summary: String?
            let settingKey: String?
            let timeOfDayKey: String?
            let moodKey: String?
            let castNames: [String]?
        }
        let title: String
        let logline: String?
        let beats: [Beat]
    }

    public func planOutline(
        request: StoryRequest,
        template: ResolvedTemplate,
        characters: [StoryCharacter],
        storyID: UUID
    ) async throws -> Result {
        let plan = try beatPlanner.plan(template: template.template, requestedPageCount: request.requestedPageCount)
        let assembler = PromptAssembler(template: template.template)

        let aiRequest = AICompletionRequest(
            operation: .outline,
            modelTier: template.template.generationPolicy.outlineModelTier,
            systemInstructions: assembler.systemInstructions(extra: [
                "You are planning a picture book. Return the plan only — no prose from the story itself."
            ]),
            userInstructions: [
                assembler.settingsBlock(themeKey: request.themeKey, languageCode: request.languageCode, toneKey: request.toneKey),
                assembler.castBlock(characters),
                assembler.beatBlock(plan),
                """
                Fill in every beat. Keep `templateBeatID` exactly as given. \
                `settingKey`, `timeOfDayKey` and `moodKey` are short lowercase keys \
                (for example "forest clearing", "dusk", "hopeful"); reuse the same key \
                when consecutive beats happen in the same place, because that is what \
                lets them share an illustration.
                """
            ],
            responseSchemaDescription: Self.schemaDescription,
            languageCode: request.languageCode,
            temperature: 0.7,
            identity: IdempotencyKeyFactory.outline(
                storyID: storyID, templateRef: template.ref, requestID: request.id
            )
        )

        let result = try await aiService.complete(
            aiRequest,
            stage: .planStory,
            estimate: UsageEstimate(operation: .outline, tokens: 4_000, costUSD: 0.02),
            decoding: OutlineResponse.self
        )

        return Result(
            outline: buildOutline(from: result.value, plan: plan, characters: characters),
            beatPlan: plan,
            attempts: result.attempts
        )
    }

    /// Aligns the model's beats onto the planned ones by position.
    ///
    /// Models drop beats, merge them, and rename ids. Position is the one thing
    /// that survives, so the plan stays authoritative and anything missing
    /// falls back to the template's own defaults.
    func buildOutline(from response: OutlineResponse, plan: BeatPlan, characters: [StoryCharacter]) -> StoryOutline {
        let names = characters.displayNames
        let beats = plan.beats.enumerated().map { index, planned -> OutlineBeat in
            let answered = index < response.beats.count ? response.beats[index] : nil
            return OutlineBeat(
                id: idGenerator.next(),
                templateBeatID: planned.beat.id,
                role: planned.beat.role,
                ordinal: planned.ordinal,
                summary: answered?.summary?.trimmed ?? planned.beat.title,
                settingKey: answered?.settingKey?.trimmed ?? planned.beat.settingKey,
                timeOfDayKey: answered?.timeOfDayKey?.trimmed ?? planned.beat.timeOfDayKey,
                moodKey: answered?.moodKey?.trimmed ?? planned.beat.moodKey,
                castNames: answered?.castNames?.filter { names.contains($0) } ?? names,
                compositionRuleID: planned.beat.compositionRuleID
            )
        }

        return StoryOutline(
            title: response.title.trimmed ?? "Untitled",
            logline: response.logline?.trimmed ?? "",
            beats: beats
        )
    }

    static let schemaDescription = """
    {
      "title": "string",
      "logline": "string",
      "beats": [
        {
          "templateBeatID": "string, copied from the beat list",
          "summary": "string, one or two sentences describing what happens",
          "settingKey": "short lowercase key",
          "timeOfDayKey": "short lowercase key",
          "moodKey": "short lowercase key",
          "castNames": ["names of characters present"]
        }
      ]
    }
    """
}

extension String {
    /// Trimmed, or nil when there was nothing but whitespace.
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
