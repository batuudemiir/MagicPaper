import Foundation
import EngineFoundation
import VisualSystem

// MARK: - Narrative

/// Where a beat sits in the arc. Openings and closings are fixed; middles are
/// what stretch when a parent asks for a longer book.
public enum BeatRole: String, Codable, Sendable, CaseIterable, Hashable {
    case opening
    case middle
    case closing
}

/// One story beat, as data.
///
/// This is the piece that used to be a hard-coded Swift array of prompt
/// strings. Moving it into a template is what lets a new kind of story ship
/// without touching the engine.
public struct TemplateBeat: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let role: BeatRole
    public let title: String
    public let instructions: [String]
    /// Middle beats with this set may be used more than once to fill a longer book.
    public let repeatable: Bool
    /// Hints the scene planner uses to decide whether the picture changes.
    public let settingKey: String
    public let timeOfDayKey: String
    public let moodKey: String
    /// Optional composition override for this beat, e.g. an establishing shot.
    public let compositionRuleID: String?

    public init(
        id: String,
        role: BeatRole,
        title: String,
        instructions: [String],
        repeatable: Bool = false,
        settingKey: String,
        timeOfDayKey: String,
        moodKey: String,
        compositionRuleID: String? = nil
    ) {
        self.id = id
        self.role = role
        self.title = title
        self.instructions = instructions
        self.repeatable = repeatable
        self.settingKey = settingKey
        self.timeOfDayKey = timeOfDayKey
        self.moodKey = moodKey
        self.compositionRuleID = compositionRuleID
    }

    // Templates are hand-written. Anything with a sensible default is optional
    // in the file, so an author writes only what makes this beat different.
    private enum CodingKeys: String, CodingKey {
        case id, role, title, instructions, repeatable, settingKey, timeOfDayKey, moodKey, compositionRuleID
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        role = try container.decode(BeatRole.self, forKey: .role)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? id
        instructions = try container.decodeIfPresent([String].self, forKey: .instructions) ?? []
        repeatable = try container.decodeIfPresent(Bool.self, forKey: .repeatable) ?? false
        settingKey = try container.decode(String.self, forKey: .settingKey)
        timeOfDayKey = try container.decodeIfPresent(String.self, forKey: .timeOfDayKey) ?? "unspecified"
        moodKey = try container.decodeIfPresent(String.self, forKey: .moodKey) ?? "unspecified"
        compositionRuleID = try container.decodeIfPresent(String.self, forKey: .compositionRuleID)
    }
}

/// The narrative half of a template: arc, voice, and the prompt fragments the
/// AI services assemble from.
public struct NarrativeTemplate: Codable, Sendable, Hashable {
    public let version: SemanticVersion
    public let beats: [TemplateBeat]
    /// Named instruction fragments. `appearanceLockdownSlot` must be present:
    /// it is what tells the model not to describe how the child looks.
    public let promptSlots: [String: String]
    public let toneKeys: [String]

    public static let appearanceLockdownSlot = "appearance_lockdown"

    public init(version: SemanticVersion, beats: [TemplateBeat], promptSlots: [String: String] = [:], toneKeys: [String] = []) {
        self.version = version
        self.beats = beats
        self.promptSlots = promptSlots
        self.toneKeys = toneKeys
    }

    private enum CodingKeys: String, CodingKey { case version, beats, promptSlots, toneKeys }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(SemanticVersion.self, forKey: .version)
        beats = try container.decodeIfPresent([TemplateBeat].self, forKey: .beats) ?? []
        promptSlots = try container.decodeIfPresent([String: String].self, forKey: .promptSlots) ?? [:]
        toneKeys = try container.decodeIfPresent([String].self, forKey: .toneKeys) ?? []
    }

    public func beats(role: BeatRole) -> [TemplateBeat] { beats.filter { $0.role == role } }
    public var repeatableMiddleBeats: [TemplateBeat] { beats(role: .middle).filter(\.repeatable) }
    public func beat(id: String) -> TemplateBeat? { beats.first { $0.id == id } }
    public func promptSlot(_ name: String) -> String? { promptSlots[name] }
}

// MARK: - Scene rules

/// How many images a scene is allowed to own.
///
/// V1 ships `singleAssetPerScene`. The alternative exists so that wanting a
/// second camera angle inside one scene later is a policy change, not a data
/// migration.
public enum SceneVisualPolicy: String, Codable, Sendable, Hashable, CaseIterable {
    case singleAssetPerScene
    case assetPerVariant
}

/// What counts as a new scene, and how many a book may have.
public struct SceneRules: Codable, Sendable, Hashable {
    public let maximumScenes: Int
    public let visualPolicy: SceneVisualPolicy
    /// Which parts of a beat, when they change, start a new scene.
    public let changeTriggers: Set<SceneChangeTrigger>

    public enum SceneChangeTrigger: String, Codable, Sendable, Hashable, CaseIterable {
        case setting
        case timeOfDay
        case mood
        case cast
    }

    public init(
        maximumScenes: Int,
        visualPolicy: SceneVisualPolicy = .singleAssetPerScene,
        changeTriggers: Set<SceneChangeTrigger> = [.setting, .timeOfDay, .cast]
    ) {
        self.maximumScenes = maximumScenes
        self.visualPolicy = visualPolicy
        self.changeTriggers = changeTriggers
    }

    private enum CodingKeys: String, CodingKey { case maximumScenes, visualPolicy, changeTriggers }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        maximumScenes = try container.decode(Int.self, forKey: .maximumScenes)
        visualPolicy = try container.decodeIfPresent(SceneVisualPolicy.self, forKey: .visualPolicy) ?? .singleAssetPerScene
        changeTriggers = try container.decodeIfPresent(Set<SceneChangeTrigger>.self, forKey: .changeTriggers)
            ?? [.setting, .timeOfDay, .cast]
    }
}

// MARK: - Generation policy

/// Which model tier to ask for. Adapters map these onto real model names, so
/// the engine never mentions a vendor's model.
public enum ModelTier: String, Codable, Sendable, Hashable, CaseIterable {
    case fast
    case balanced
    case quality
}

/// How generation should behave: retries, refinement, and what the engine is
/// allowed to spend extra calls on.
public struct GenerationPolicy: Codable, Sendable, Hashable {
    public let maximumAttemptsPerStage: Int
    public let initialBackoff: TimeInterval
    public let backoffMultiplier: Double
    public let maximumBackoff: TimeInterval
    /// Whether pages get an individual polish pass after segmentation.
    public let pageRefinementEnabled: Bool
    /// Whether the LLM-assisted validators run at all.
    public let semanticValidationEnabled: Bool
    /// Semantic findings block publication instead of warning.
    public let semanticIssuesAreBlocking: Bool
    /// Whether, and how strictly, the produced images are looked at.
    public let imageValidationMode: ImageValidationMode
    public let outlineModelTier: ModelTier
    public let draftModelTier: ModelTier
    public let refinementModelTier: ModelTier
    public let validationModelTier: ModelTier
    public let defaultBudget: GenerationBudget

    public init(
        maximumAttemptsPerStage: Int = 3,
        initialBackoff: TimeInterval = 0.5,
        backoffMultiplier: Double = 2.0,
        maximumBackoff: TimeInterval = 8.0,
        pageRefinementEnabled: Bool = true,
        semanticValidationEnabled: Bool = true,
        semanticIssuesAreBlocking: Bool = false,
        imageValidationMode: ImageValidationMode = .advisory,
        outlineModelTier: ModelTier = .balanced,
        draftModelTier: ModelTier = .quality,
        refinementModelTier: ModelTier = .fast,
        validationModelTier: ModelTier = .fast,
        defaultBudget: GenerationBudget = .standard
    ) {
        self.maximumAttemptsPerStage = maximumAttemptsPerStage
        self.initialBackoff = initialBackoff
        self.backoffMultiplier = backoffMultiplier
        self.maximumBackoff = maximumBackoff
        self.pageRefinementEnabled = pageRefinementEnabled
        self.semanticValidationEnabled = semanticValidationEnabled
        self.semanticIssuesAreBlocking = semanticIssuesAreBlocking
        self.imageValidationMode = imageValidationMode
        self.outlineModelTier = outlineModelTier
        self.draftModelTier = draftModelTier
        self.refinementModelTier = refinementModelTier
        self.validationModelTier = validationModelTier
        self.defaultBudget = defaultBudget
    }

    private enum CodingKeys: String, CodingKey {
        case maximumAttemptsPerStage, initialBackoff, backoffMultiplier, maximumBackoff
        case pageRefinementEnabled, semanticValidationEnabled, semanticIssuesAreBlocking, imageValidationMode
        case outlineModelTier, draftModelTier, refinementModelTier, validationModelTier, defaultBudget
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = GenerationPolicy()
        maximumAttemptsPerStage = try container.decodeIfPresent(Int.self, forKey: .maximumAttemptsPerStage) ?? fallback.maximumAttemptsPerStage
        initialBackoff = try container.decodeIfPresent(TimeInterval.self, forKey: .initialBackoff) ?? fallback.initialBackoff
        backoffMultiplier = try container.decodeIfPresent(Double.self, forKey: .backoffMultiplier) ?? fallback.backoffMultiplier
        maximumBackoff = try container.decodeIfPresent(TimeInterval.self, forKey: .maximumBackoff) ?? fallback.maximumBackoff
        pageRefinementEnabled = try container.decodeIfPresent(Bool.self, forKey: .pageRefinementEnabled) ?? fallback.pageRefinementEnabled
        semanticValidationEnabled = try container.decodeIfPresent(Bool.self, forKey: .semanticValidationEnabled) ?? fallback.semanticValidationEnabled
        semanticIssuesAreBlocking = try container.decodeIfPresent(Bool.self, forKey: .semanticIssuesAreBlocking) ?? fallback.semanticIssuesAreBlocking
        imageValidationMode = try container.decodeIfPresent(ImageValidationMode.self, forKey: .imageValidationMode) ?? fallback.imageValidationMode
        outlineModelTier = try container.decodeIfPresent(ModelTier.self, forKey: .outlineModelTier) ?? fallback.outlineModelTier
        draftModelTier = try container.decodeIfPresent(ModelTier.self, forKey: .draftModelTier) ?? fallback.draftModelTier
        refinementModelTier = try container.decodeIfPresent(ModelTier.self, forKey: .refinementModelTier) ?? fallback.refinementModelTier
        validationModelTier = try container.decodeIfPresent(ModelTier.self, forKey: .validationModelTier) ?? fallback.validationModelTier
        defaultBudget = try container.decodeIfPresent(GenerationBudget.self, forKey: .defaultBudget) ?? fallback.defaultBudget
    }
}

// MARK: - Validation rules

/// Word bounds for one age band.
public struct AgeBandRule: Codable, Sendable, Hashable {
    public let minimumAge: Int
    public let maximumAge: Int
    public let minimumWordsPerPage: Int
    public let maximumWordsPerPage: Int
    public let maximumSentenceWords: Int

    public init(minimumAge: Int, maximumAge: Int, minimumWordsPerPage: Int, maximumWordsPerPage: Int, maximumSentenceWords: Int) {
        self.minimumAge = minimumAge
        self.maximumAge = maximumAge
        self.minimumWordsPerPage = minimumWordsPerPage
        self.maximumWordsPerPage = maximumWordsPerPage
        self.maximumSentenceWords = maximumSentenceWords
    }

    public func covers(age: Int) -> Bool { (minimumAge...maximumAge).contains(age) }
}

/// Which validators run, and how strict they are.
public struct ValidationRules: Codable, Sendable, Hashable {
    public let ageBands: [AgeBandRule]
    public let bannedPhrases: [String]
    /// Repeated n-grams longer than this across pages are flagged.
    public let repetitionNGramSize: Int
    public let maximumRepeatedNGrams: Int
    public let maximumSharedSentenceOpeners: Int
    public let requireProtagonistMentionPerPage: Bool
    public let enabledValidators: [String]

    public init(
        ageBands: [AgeBandRule],
        bannedPhrases: [String] = [],
        repetitionNGramSize: Int = 5,
        maximumRepeatedNGrams: Int = 0,
        maximumSharedSentenceOpeners: Int = 2,
        requireProtagonistMentionPerPage: Bool = true,
        enabledValidators: [String] = ValidatorID.allDeterministic
    ) {
        self.ageBands = ageBands
        self.bannedPhrases = bannedPhrases
        self.repetitionNGramSize = repetitionNGramSize
        self.maximumRepeatedNGrams = maximumRepeatedNGrams
        self.maximumSharedSentenceOpeners = maximumSharedSentenceOpeners
        self.requireProtagonistMentionPerPage = requireProtagonistMentionPerPage
        self.enabledValidators = enabledValidators
    }

    private enum CodingKeys: String, CodingKey {
        case ageBands, bannedPhrases, repetitionNGramSize, maximumRepeatedNGrams
        case maximumSharedSentenceOpeners, requireProtagonistMentionPerPage, enabledValidators
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ageBands = try container.decodeIfPresent([AgeBandRule].self, forKey: .ageBands) ?? []
        bannedPhrases = try container.decodeIfPresent([String].self, forKey: .bannedPhrases) ?? []
        repetitionNGramSize = try container.decodeIfPresent(Int.self, forKey: .repetitionNGramSize) ?? 5
        maximumRepeatedNGrams = try container.decodeIfPresent(Int.self, forKey: .maximumRepeatedNGrams) ?? 0
        maximumSharedSentenceOpeners = try container.decodeIfPresent(Int.self, forKey: .maximumSharedSentenceOpeners) ?? 2
        requireProtagonistMentionPerPage = try container.decodeIfPresent(Bool.self, forKey: .requireProtagonistMentionPerPage) ?? true
        enabledValidators = try container.decodeIfPresent([String].self, forKey: .enabledValidators) ?? ValidatorID.allDeterministic
    }

    public func ageBand(for age: Int) -> AgeBandRule? { ageBands.first { $0.covers(age: age) } }
}

/// Stable validator names, so a template can switch one off by id.
public enum ValidatorID {
    public static let structural = "structural"
    public static let repetition = "repetition"
    public static let characterConsistency = "character_consistency"
    public static let ageAppropriateness = "age_appropriateness"
    public static let visualSafety = "visual_safety"
    public static let generatedImage = "generated_image"
    public static let inputSafety = "input_safety"
    public static let narrativeConsistency = "narrative_consistency"
    public static let sceneTextAlignment = "scene_text_alignment"

    public static let allDeterministic = [structural, repetition, characterConsistency, ageAppropriateness, visualSafety, generatedImage]
    public static let allSemantic = [narrativeConsistency, sceneTextAlignment]
    public static let all = allDeterministic + allSemantic
}

// MARK: - Constraints

public struct TemplateConstraints: Codable, Sendable, Hashable {
    public let supportedPageCounts: ClosedRange<Int>
    public let supportedAgeRange: ClosedRange<Int>
    public let supportedLanguageCodes: [String]

    public init(supportedPageCounts: ClosedRange<Int>, supportedAgeRange: ClosedRange<Int>, supportedLanguageCodes: [String]) {
        self.supportedPageCounts = supportedPageCounts
        self.supportedAgeRange = supportedAgeRange
        self.supportedLanguageCodes = supportedLanguageCodes
    }

    private enum CodingKeys: String, CodingKey {
        case minimumPages, maximumPages, minimumAge, maximumAge, supportedLanguageCodes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let minimumPages = try container.decode(Int.self, forKey: .minimumPages)
        let maximumPages = try container.decode(Int.self, forKey: .maximumPages)
        let minimumAge = try container.decode(Int.self, forKey: .minimumAge)
        let maximumAge = try container.decode(Int.self, forKey: .maximumAge)
        guard minimumPages <= maximumPages, minimumAge <= maximumAge else {
            throw DecodingError.dataCorruptedError(
                forKey: .minimumPages, in: container,
                debugDescription: "Template constraint ranges are inverted"
            )
        }
        supportedPageCounts = minimumPages...maximumPages
        supportedAgeRange = minimumAge...maximumAge
        supportedLanguageCodes = try container.decode([String].self, forKey: .supportedLanguageCodes)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(supportedPageCounts.lowerBound, forKey: .minimumPages)
        try container.encode(supportedPageCounts.upperBound, forKey: .maximumPages)
        try container.encode(supportedAgeRange.lowerBound, forKey: .minimumAge)
        try container.encode(supportedAgeRange.upperBound, forKey: .maximumAge)
        try container.encode(supportedLanguageCodes, forKey: .supportedLanguageCodes)
    }
}

// MARK: - Template

/// Narrative + layout + visual style + scene rules + generation policy +
/// validation, as one versioned document.
///
/// A template is the only place a "kind of story" is defined. The engine holds
/// no theme names, no beat prose and no word-count constants: adding a new
/// theme is a JSON file.
public struct StoryTemplate: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let version: SemanticVersion
    public let schemaVersion: Int
    public let displayName: String
    /// Free-form keys this template can dress a story in, e.g. "space",
    /// "jungle". Matched against `StoryRequest.themeKey`; the engine never
    /// interprets them.
    public let themeKeys: [String]
    public let narrative: NarrativeTemplate
    /// Visual style preset id, resolved through `VisualSystem`.
    public let visualStyleID: String
    public let visualStyleRequirement: VersionRequirement
    public let sceneRules: SceneRules
    public let generationPolicy: GenerationPolicy
    public let validationRules: ValidationRules
    public let childSafety: ChildSafetyPolicy
    public let constraints: TemplateConstraints

    public static let currentSchemaVersion = 1

    public init(
        id: String,
        version: SemanticVersion,
        schemaVersion: Int = StoryTemplate.currentSchemaVersion,
        displayName: String,
        themeKeys: [String],
        narrative: NarrativeTemplate,
        visualStyleID: String,
        visualStyleRequirement: VersionRequirement = .latest,
        sceneRules: SceneRules,
        generationPolicy: GenerationPolicy = GenerationPolicy(),
        validationRules: ValidationRules,
        childSafety: ChildSafetyPolicy = .strict,
        constraints: TemplateConstraints
    ) {
        self.id = id
        self.version = version
        self.schemaVersion = schemaVersion
        self.displayName = displayName
        self.themeKeys = themeKeys
        self.narrative = narrative
        self.visualStyleID = visualStyleID
        self.visualStyleRequirement = visualStyleRequirement
        self.sceneRules = sceneRules
        self.generationPolicy = generationPolicy
        self.validationRules = validationRules
        self.childSafety = childSafety
        self.constraints = constraints
    }

    private enum CodingKeys: String, CodingKey {
        case id, version, schemaVersion, displayName, themeKeys, narrative
        case visualStyleID, visualStyleRequirement, sceneRules, generationPolicy, validationRules, childSafety, constraints
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        version = try container.decode(SemanticVersion.self, forKey: .version)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? StoryTemplate.currentSchemaVersion
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? id
        themeKeys = try container.decodeIfPresent([String].self, forKey: .themeKeys) ?? []
        narrative = try container.decode(NarrativeTemplate.self, forKey: .narrative)
        visualStyleID = try container.decode(String.self, forKey: .visualStyleID)
        visualStyleRequirement = try container.decodeIfPresent(VersionRequirement.self, forKey: .visualStyleRequirement) ?? .latest
        sceneRules = try container.decode(SceneRules.self, forKey: .sceneRules)
        generationPolicy = try container.decodeIfPresent(GenerationPolicy.self, forKey: .generationPolicy) ?? GenerationPolicy()
        validationRules = try container.decode(ValidationRules.self, forKey: .validationRules)
        // Defaults to strict: a template that forgets to mention safety gets
        // the safest behaviour, not the most permissive.
        childSafety = try container.decodeIfPresent(ChildSafetyPolicy.self, forKey: .childSafety) ?? .strict
        constraints = try container.decode(TemplateConstraints.self, forKey: .constraints)
    }

    public func supports(themeKey: String) -> Bool {
        themeKeys.isEmpty || themeKeys.contains(themeKey)
    }
}

/// A template resolved for one story, with every version pinned.
///
/// Stored on the `Story` so a book can be reconstructed exactly as generated,
/// however far the templates have moved on since.
public struct TemplateRef: Codable, Sendable, Hashable {
    public let templateID: String
    public let templateVersion: SemanticVersion
    public let narrativeVersion: SemanticVersion
    public let visualStyleID: String
    public let visualStylePins: [String]
    public let resolvedAt: Date

    public init(
        templateID: String,
        templateVersion: SemanticVersion,
        narrativeVersion: SemanticVersion,
        visualStyleID: String,
        visualStylePins: [String],
        resolvedAt: Date
    ) {
        self.templateID = templateID
        self.templateVersion = templateVersion
        self.narrativeVersion = narrativeVersion
        self.visualStyleID = visualStyleID
        self.visualStylePins = visualStylePins
        self.resolvedAt = resolvedAt
    }
}

/// A template plus the visual style it points at, both resolved.
public struct ResolvedTemplate: Sendable {
    public let template: StoryTemplate
    public let visualStyle: ResolvedVisualStyle
    public let ref: TemplateRef

    public init(template: StoryTemplate, visualStyle: ResolvedVisualStyle, ref: TemplateRef) {
        self.template = template
        self.visualStyle = visualStyle
        self.ref = ref
    }
}
