import Foundation
import CharacterEngine
import EngineFoundation

/// Everything needed to compile one illustration instruction.
public struct VisualCompilationInput: Sendable {
    public let style: ResolvedVisualStyle
    public let sceneContext: SceneVisualContext
    public let variant: VisualVariant
    public let cast: [ResolvedCharacter]
    public let seed: UInt64
    /// Which reference image to lean on for the protagonist.
    public let preferredAssetRole: CharacterAssetRole
    public let expression: CharacterExpression?

    public init(
        style: ResolvedVisualStyle,
        sceneContext: SceneVisualContext,
        variant: VisualVariant = .default,
        cast: [ResolvedCharacter],
        seed: UInt64,
        preferredAssetRole: CharacterAssetRole = .master,
        expression: CharacterExpression? = nil
    ) {
        self.style = style
        self.sceneContext = sceneContext
        self.variant = variant
        self.cast = cast
        self.seed = seed
        self.preferredAssetRole = preferredAssetRole
        self.expression = expression
    }
}

/// Turns design-system documents plus a resolved cast into a
/// `VisualConstraintSet`.
///
/// Pure and deterministic — same input, byte-identical output — because scene
/// fingerprints are derived from what it produces. If this function ever became
/// order-dependent, every story would think its images were stale.
///
/// The rule that matters most: appearance clauses are read from
/// `CharacterIdentity.descriptors` and from nowhere else. There is no parameter
/// through which a caller can describe how a child looks.
public struct PromptConstraintCompiler: Sendable {
    public init() {}

    public func compile(_ input: VisualCompilationInput) throws -> VisualConstraintSet {
        let composition = try resolveComposition(for: input)

        let styleClauses = input.style.illustrationStyle.mediumClauses
            + input.style.illustrationStyle.lightingClauses
            + input.style.illustrationStyle.renderingConstraints

        var compositionClauses = composition.clauses
        if let pose = input.variant.characterPoseKey, !pose.isEmpty {
            compositionClauses.append("character pose: \(pose)")
        }
        if let beat = input.variant.emotionalBeatKey, !beat.isEmpty {
            compositionClauses.append("emotional tone: \(beat)")
        }

        var sceneClauses = [
            "setting: \(input.sceneContext.settingKey)",
            "time of day: \(input.sceneContext.timeOfDayKey)",
            "mood: \(input.sceneContext.moodKey)"
        ]
        sceneClauses.append(contentsOf: input.sceneContext.sceneClauses)

        let identityClauses = compileIdentityClauses(for: input.cast)
        let negativeClauses = compileNegativeClauses(for: input)
        let referenceLocators = compileReferenceLocators(for: input)

        let aspectRatio = input.variant.aspectRatio ?? composition.aspectRatio

        var provenance = input.style.versionPins
        provenance.append("composition:\(composition.id)@\(composition.version)")
        provenance.append(contentsOf: input.cast
            .map { "character:\($0.characterID)@\($0.versionID)" }
            .sorted())

        return VisualConstraintSet(
            styleClauses: styleClauses,
            compositionClauses: compositionClauses,
            paletteClauses: input.style.palette.paletteClauses,
            sceneClauses: sceneClauses,
            identityClauses: identityClauses,
            negativeClauses: negativeClauses,
            referenceLocators: referenceLocators,
            aspectRatio: aspectRatio,
            seed: input.seed,
            provenance: provenance
        )
    }

    // MARK: - Pieces

    private func resolveComposition(for input: VisualCompilationInput) throws -> ImageCompositionRule {
        // Most specific wins: the variant asked for it, then the scene, then
        // the preset's default.
        let requestedID = input.variant.compositionRuleID
            ?? input.sceneContext.compositionRuleID
            ?? input.style.preset.defaultCompositionRuleID

        guard var rule = input.style.compositionRule(id: requestedID) else {
            throw VisualSystemError.compositionRuleNotFound(requestedID)
        }

        // A variant may override camera distance without redefining a rule.
        if let camera = input.variant.cameraDistance, camera != rule.cameraDistance {
            rule = ImageCompositionRule(
                id: rule.id,
                version: rule.version,
                displayName: rule.displayName,
                subjectAnchor: rule.subjectAnchor,
                textSafeArea: rule.textSafeArea,
                cameraDistance: camera,
                aspectRatio: rule.aspectRatio,
                headroomRules: rule.headroomRules
            )
        }
        return rule
    }

    /// The single source of appearance language.
    ///
    /// Descriptors are emitted in a fixed category order and sorted inside each
    /// category, so two identical identities always compile to the same string.
    private func compileIdentityClauses(for cast: [ResolvedCharacter]) -> [String] {
        let ordered = cast.sorted { lhs, rhs in
            (roleRank(lhs.role), lhs.displayName) < (roleRank(rhs.role), rhs.displayName)
        }

        return ordered.flatMap { character -> [String] in
            var clauses: [String] = ["\(character.displayName), age \(character.identity.ageYears)"]
            for category in DescriptorCategory.allCases {
                let values = character.identity
                    .descriptors(in: category)
                    .map(\.value)
                    .sorted()
                guard !values.isEmpty else { continue }
                clauses.append("\(character.displayName) \(category.clausePrefix) \(values.joined(separator: ", "))")
            }
            clauses.append(contentsOf: character.styleProfile.renderingNotes)
            return clauses
        }
    }

    private func compileNegativeClauses(for input: VisualCompilationInput) -> [String] {
        var negatives = input.style.illustrationStyle.forbiddenClauses
        negatives.append(contentsOf: input.style.preset.globalNegativeClauses)
        for character in input.cast {
            negatives.append(contentsOf: character.styleProfile.negativeTraits)
            negatives.append(contentsOf: character.identity.doNotDepict)
        }
        // Stable and duplicate-free: this feeds the fingerprint.
        var seen: Set<String> = []
        return negatives.filter { seen.insert(DescriptorNormalization.normalize($0)).inserted }
    }

    private func compileReferenceLocators(for input: VisualCompilationInput) -> [String] {
        let ordered = input.cast.sorted { lhs, rhs in
            (roleRank(lhs.role), lhs.displayName) < (roleRank(rhs.role), rhs.displayName)
        }
        var locators: [String] = []
        var seen: Set<String> = []
        for character in ordered {
            let chain = character.assetSet.referenceChain(
                preferring: input.preferredAssetRole,
                expression: input.expression
            )
            for asset in chain where seen.insert(asset.locator).inserted {
                locators.append(asset.locator)
            }
        }
        return locators
    }

    private func roleRank(_ role: CastRole) -> Int {
        switch role {
        case .protagonist: return 0
        case .companion: return 1
        case .supporting: return 2
        }
    }
}

private extension DescriptorCategory {
    /// Wording that reads naturally in a prompt clause.
    var clausePrefix: String {
        switch self {
        case .hair: return "has"
        case .eyes: return "has"
        case .skinTone: return "has"
        case .build: return "has a"
        case .height: return "is"
        case .distinguishingFeature: return "has"
        case .clothingDefault: return "wears"
        case .accessory: return "carries"
        }
    }
}
