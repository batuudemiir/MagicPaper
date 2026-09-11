import Foundation
import CharacterEngine
import EngineFoundation
import VisualSystem
@testable import StoryEngine

/// A `CharacterEngineContract` that hands back a fixed cast.
struct StubCharacterEngine: CharacterEngineContract {
    var cast: ResolvedCast
    var error: CharacterEngineError?

    func resolveCast(for binding: CastBinding) async throws -> ResolvedCast {
        if let error { throw error }
        return cast
    }
}

enum StoryFixtures {
    static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: - Characters

    /// Ids derived from the name rather than minted fresh.
    ///
    /// Character and version ids end up inside every image fingerprint via the
    /// constraint set's provenance, so random ids would make the deterministic
    /// pipeline produce different fingerprints on every run — which the golden
    /// fixtures would then flag as a behaviour change on every single run.
    static func deterministicUUID(_ seed: String, namespace: UInt8) -> UUID {
        var bytes = Array(StableHash.fingerprint([seed]).utf8.prefix(16)).map { UInt8($0) }
        while bytes.count < 16 { bytes.append(0) }
        bytes[0] = namespace
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    static func resolvedCharacter(
        name: String = "Deniz",
        role: CastRole = .protagonist,
        descriptors: [CharacterDescriptor] = [
            CharacterDescriptor(category: .hair, value: "curly black hair"),
            CharacterDescriptor(category: .eyes, value: "brown eyes")
        ],
        identitySeed: UInt64 = 7,
        doNotDepict: [String] = []
    ) -> ResolvedCharacter {
        let version = CharacterVersion(
            id: CharacterVersionID(deterministicUUID("\(name)-version-1", namespace: 0xCE)),
            versionNumber: 1,
            createdAt: referenceDate,
            identity: CharacterIdentity(
                ageYears: 6,
                pronouns: .theyThem,
                descriptors: descriptors,
                identitySeed: identitySeed,
                doNotDepict: doNotDepict
            ),
            styleProfile: CharacterStyleProfile(
                illustrationStyleID: "storybook_painted_v1",
                palettePresetID: "paper_warm"
            ),
            assetSet: CharacterAssetSet(
                masterReference: CharacterAsset(role: .master, locator: "deniz-master.jpg", createdAt: referenceDate),
                identitySeed: identitySeed,
                stylePresetID: "magic_paper_v1"
            ),
            provenance: .authoredByParent
        )
        return ResolvedCharacter(
            characterID: CharacterID(deterministicUUID(name, namespace: 0xCA)),
            displayName: name,
            role: role,
            version: version
        )
    }

    static func cast(_ protagonist: ResolvedCharacter? = nil, supporting: [ResolvedCharacter] = []) -> ResolvedCast {
        ResolvedCast(protagonist: protagonist ?? resolvedCharacter(), supporting: supporting)
    }

    static func storyCharacters(_ cast: ResolvedCast? = nil) -> [StoryCharacter] {
        (cast ?? Self.cast()).all.map(StoryCharacter.init(resolved:))
    }

    // MARK: - Requests

    static func request(
        templateID: String = "adventure_01",
        requirement: VersionRequirement = .latest,
        themeKey: String = "forest",
        languageCode: String = "en",
        ageYears: Int = 6,
        pageCount: Int = 7,
        budget: GenerationBudget = .standard,
        seedPolicy: SeedPolicy = .deterministic
    ) -> StoryRequest {
        StoryRequest(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!,
            cast: CastBinding(protagonist: CharacterID()),
            templateID: templateID,
            templateRequirement: requirement,
            themeKey: themeKey,
            languageCode: languageCode,
            ageYears: ageYears,
            requestedPageCount: pageCount,
            budget: budget,
            seedPolicy: seedPolicy,
            createdAt: referenceDate
        )
    }

    // MARK: - Templates

    static var adventureTemplate: StoryTemplate {
        guard let template = BuiltInTemplates.template(id: "adventure_01") else {
            fatalError("adventure_01 template is missing from package resources")
        }
        return template
    }

    static func resolvedTemplate(_ template: StoryTemplate? = nil) throws -> ResolvedTemplate {
        let template = template ?? adventureTemplate
        let style = try VisualStyleResolver().resolve(styleID: template.visualStyleID)
        return ResolvedTemplate(
            template: template,
            visualStyle: style,
            ref: TemplateRef(
                templateID: template.id,
                templateVersion: template.version,
                narrativeVersion: template.narrative.version,
                visualStyleID: style.preset.id,
                visualStylePins: style.versionPins,
                resolvedAt: referenceDate
            )
        )
    }

    /// A template built from parts, for tests that need a shape the shipped one
    /// does not have.
    static func template(
        id: String = "test_template",
        version: SemanticVersion = SemanticVersion(1, 0, 0),
        themeKeys: [String] = [],
        beats: [TemplateBeat]? = nil,
        sceneRules: SceneRules = SceneRules(maximumScenes: 8),
        generationPolicy: GenerationPolicy = GenerationPolicy(),
        pageRange: ClosedRange<Int> = 3...16,
        ageRange: ClosedRange<Int> = 3...12,
        languages: [String] = ["en", "tr"]
    ) -> StoryTemplate {
        StoryTemplate(
            id: id,
            version: version,
            displayName: "Test",
            themeKeys: themeKeys,
            narrative: NarrativeTemplate(
                version: SemanticVersion(1, 0, 0),
                beats: beats ?? defaultBeats,
                promptSlots: [NarrativeTemplate.appearanceLockdownSlot: "Never describe appearance."],
                toneKeys: ["warm"]
            ),
            visualStyleID: "magic_paper_v1",
            sceneRules: sceneRules,
            generationPolicy: generationPolicy,
            validationRules: ValidationRules(
                ageBands: [AgeBandRule(minimumAge: 3, maximumAge: 12, minimumWordsPerPage: 10, maximumWordsPerPage: 200, maximumSentenceWords: 30)]
            ),
            constraints: TemplateConstraints(
                supportedPageCounts: pageRange,
                supportedAgeRange: ageRange,
                supportedLanguageCodes: languages
            )
        )
    }

    static func beat(
        id: String,
        role: BeatRole,
        repeatable: Bool = false,
        setting: String = "home",
        timeOfDay: String = "day",
        mood: String = "calm",
        compositionRuleID: String? = nil
    ) -> TemplateBeat {
        TemplateBeat(
            id: id,
            role: role,
            title: id,
            instructions: ["do \(id)"],
            repeatable: repeatable,
            settingKey: setting,
            timeOfDayKey: timeOfDay,
            moodKey: mood,
            compositionRuleID: compositionRuleID
        )
    }

    static let defaultBeats: [TemplateBeat] = [
        beat(id: "open_a", role: .opening, setting: "home"),
        beat(id: "open_b", role: .opening, setting: "threshold"),
        beat(id: "mid_a", role: .middle, setting: "world"),
        beat(id: "mid_b", role: .middle, repeatable: true, setting: "journey"),
        beat(id: "close_a", role: .closing, setting: "world", timeOfDay: "dusk"),
        beat(id: "close_b", role: .closing, setting: "home", timeOfDay: "night")
    ]

    // MARK: - Outlines

    /// Builds an outline directly from a beat plan, the way `StoryPlanner`
    /// would if the model returned exactly what was asked for.
    static func outline(
        from plan: BeatPlan,
        title: String = "The Clearing",
        castNames: [String] = ["Deniz"],
        ids: IDGenerator = SequentialIDGenerator()
    ) -> StoryOutline {
        StoryOutline(
            title: title,
            logline: "A small adventure.",
            beats: plan.beats.map { planned in
                OutlineBeat(
                    id: ids.next(),
                    templateBeatID: planned.beat.id,
                    role: planned.beat.role,
                    ordinal: planned.ordinal,
                    summary: "\(planned.beat.title) happens.",
                    settingKey: planned.beat.settingKey,
                    timeOfDayKey: planned.beat.timeOfDayKey,
                    moodKey: planned.beat.moodKey,
                    castNames: castNames,
                    compositionRuleID: planned.beat.compositionRuleID
                )
            }
        )
    }

    /// A planned story: template, outline, scenes and pages, all deterministic.
    struct PlannedStory {
        let template: ResolvedTemplate
        let outline: StoryOutline
        let scenes: [StoryScene]
        let pages: [StoryPage]
        let characters: [StoryCharacter]

        init(
            template: ResolvedTemplate,
            outline: StoryOutline,
            scenes: [StoryScene],
            pages: [StoryPage],
            characters: [StoryCharacter]
        ) {
            self.template = template
            self.outline = outline
            self.scenes = scenes
            self.pages = pages
            self.characters = characters
        }
    }

    static func plannedStory(
        template: StoryTemplate? = nil,
        pageCount: Int = 7,
        characters: [StoryCharacter]? = nil,
        ids: IDGenerator = SequentialIDGenerator()
    ) throws -> PlannedStory {
        let resolved = try resolvedTemplate(template)
        let plan = try BeatPlanner().plan(template: resolved.template, requestedPageCount: pageCount)
        let cast = characters ?? storyCharacters()
        let outline = outline(from: plan, castNames: cast.displayNames, ids: ids)

        let scenePlanner = ScenePlanner(idGenerator: ids)
        let scenePlan = scenePlanner.planScenes(outline: outline, template: resolved.template)
        let pages = try PagePlanner(idGenerator: ids).planPages(
            outline: outline,
            template: resolved,
            sceneIDByBeatID: scenePlan.sceneIDByBeatID
        )
        let scenes = scenePlanner.linking(pages: pages, to: scenePlan.scenes)

        return PlannedStory(template: resolved, outline: outline, scenes: scenes, pages: pages, characters: cast)
    }
}

// MARK: - Whole stories

extension StoryFixtures {
    /// A story with cast, outline, draft, pages, scenes and ready illustrations
    /// — the state validation and regeneration operate on.
    static func completeStory(
        pageCount: Int = 7,
        wordsPerPage: Int = 80,
        template: StoryTemplate? = nil,
        characters: [StoryCharacter]? = nil,
        drawImages: Bool = true,
        ids: IDGenerator = SequentialIDGenerator(startingAt: 1_000)
    ) throws -> (story: Story, request: StoryRequest, template: ResolvedTemplate) {
        let planned = try plannedStory(template: template, pageCount: pageCount, characters: characters, ids: ids)
        let request = request(pageCount: pageCount)

        var scenes = try VisualPlanner(idGenerator: ids).planAssets(
            scenes: planned.scenes,
            pages: planned.pages,
            characters: planned.characters,
            template: planned.template,
            storyID: UUID(uuidString: "CCCCCCCC-0000-0000-0000-000000000001")!,
            seedPolicy: .deterministic
        )

        if drawImages {
            scenes = scenes.map { scene in
                var copy = scene
                copy.visualAssets = scene.visualAssets.map { asset in
                    var ready = asset
                    ready.state = .ready
                    ready.imageRef = ImageRef(locator: "image-\(asset.id.uuidString).png", createdAt: referenceDate)
                    return ready
                }
                return copy
            }
        }

        var pages = VisualPlanner().assigning(
            pages: planned.pages, to: scenes,
            policy: planned.template.template.sceneRules.visualPolicy
        )
        pages = pages.enumerated().map { index, page in
            var copy = page
            copy.title = "Page \(index + 1)"
            copy.text = ScriptedResponses.prose(words: wordsPerPage, seed: index)
            return copy
        }

        let draft = NarrativeDraft(
            id: ids.next(),
            voiceProfile: VoiceProfile(
                narratorRegister: "warm close third person",
                sentenceRhythm: "short sentences",
                recurringMotifs: ["lantern light"],
                characterVoices: ["Deniz": "curious and direct"]
            ),
            segments: planned.outline.beats.map { beat in
                DraftSegment(id: ids.next(), outlineBeatID: beat.id, text: ScriptedResponses.prose(words: wordsPerPage, seed: beat.ordinal))
            },
            createdAt: referenceDate
        )

        let story = Story(
            id: UUID(uuidString: "CCCCCCCC-0000-0000-0000-000000000001")!,
            requestID: request.id,
            templateRef: planned.template.ref,
            title: planned.outline.title,
            status: .validating,
            characters: planned.characters,
            outline: planned.outline,
            draft: draft,
            pages: pages,
            scenes: ScenePlanner().linking(pages: pages, to: scenes),
            createdAt: referenceDate
        )

        return (story, request, planned.template)
    }

    /// A validated, published story.
    static func publishedStory(pageCount: Int = 7) async throws -> (story: Story, request: StoryRequest, template: ResolvedTemplate) {
        let (story, request, template) = try completeStory(pageCount: pageCount)
        let clock = FixedClock()
        let result = await StoryValidator(clock: clock).validate(
            ValidationContext(story: story, template: template, request: request)
        )
        let validated = try story.applying([.setValidation(result)], at: clock.now())
        let published = try BookAssembler(clock: clock).publish(story: validated)
        return (published, request, template)
    }
}
