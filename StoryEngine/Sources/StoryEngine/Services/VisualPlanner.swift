import Foundation
import EngineFoundation
import CharacterEngine
import VisualSystem

/// Decides which illustrations a book needs, and what each one is made of.
///
/// Two jobs, both deterministic:
///
/// 1. Choose the variants a scene should be drawn in. Under
///    `singleAssetPerScene` that is one; under `assetPerVariant` it is one per
///    distinct shot the pages in that scene want.
/// 2. Compile each variant into a `VisualConstraintSet` and fingerprint it, so
///    the generation service can tell what genuinely needs drawing.
public struct VisualPlanner: Sendable {
    private let compiler: PromptConstraintCompiler
    private let idGenerator: IDGenerator

    public init(compiler: PromptConstraintCompiler = PromptConstraintCompiler(), idGenerator: IDGenerator = RandomIDGenerator()) {
        self.compiler = compiler
        self.idGenerator = idGenerator
    }

    /// Plans assets for every scene, preserving any that are already drawn and
    /// still current.
    public func planAssets(
        scenes: [StoryScene],
        pages: [StoryPage],
        characters: [StoryCharacter],
        template: ResolvedTemplate,
        storyID: UUID,
        seedPolicy: SeedPolicy
    ) throws -> [StoryScene] {
        try scenes.map { scene in
            try planAssets(
                for: scene,
                pages: pages,
                characters: characters,
                template: template,
                storyID: storyID,
                seedPolicy: seedPolicy
            )
        }
    }

    public func planAssets(
        for scene: StoryScene,
        pages: [StoryPage],
        characters: [StoryCharacter],
        template: ResolvedTemplate,
        storyID: UUID,
        seedPolicy: SeedPolicy
    ) throws -> StoryScene {
        let scenePages = pages.filter { $0.sceneID == scene.id && $0.requiresImage }
        guard !scenePages.isEmpty else {
            // A scene of text-only pages needs no picture at all.
            var copy = scene
            copy.visualAssets = []
            return copy
        }

        let variants = plannedVariants(for: scene, pages: scenePages, policy: template.template.sceneRules.visualPolicy)
        var copy = scene
        var assets: [VisualAsset] = []

        for variant in variants {
            let existing = scene.asset(matching: variant)
            let revision = existing?.revision ?? 0
            let constraints = try compileConstraints(
                scene: scene,
                variant: variant,
                characters: characters,
                template: template,
                storyID: storyID,
                seedPolicy: seedPolicy,
                revision: revision
            )

            if var asset = existing {
                // Keep a ready image if nothing about it changed.
                if asset.isReady && asset.fingerprint == constraints.fingerprint {
                    asset.promptSnapshot = constraints
                    assets.append(asset)
                    continue
                }
                asset.fingerprint = constraints.fingerprint
                asset.promptSnapshot = constraints
                asset.state = .notRequested
                asset.imageRef = nil
                asset.failureMessage = nil
                // The old verdict was about the old picture.
                asset.validation = nil
                assets.append(asset)
            } else {
                assets.append(
                    VisualAsset(
                        id: idGenerator.next(),
                        sceneID: scene.id,
                        variant: variant,
                        fingerprint: constraints.fingerprint,
                        state: .notRequested,
                        promptSnapshot: constraints
                    )
                )
            }
        }

        copy.visualAssets = assets
        return copy
    }

    /// Points each page at the asset it should show.
    public func assigning(pages: [StoryPage], to scenes: [StoryScene], policy: SceneVisualPolicy) -> [StoryPage] {
        let scenesByID = Dictionary(uniqueKeysWithValues: scenes.map { ($0.id, $0) })
        return pages.map { page in
            var copy = page
            guard page.requiresImage, let scene = scenesByID[page.sceneID] else {
                copy.visualAssetID = nil
                return copy
            }
            let variant = variant(for: page, policy: policy)
            copy.visualAssetID = (scene.asset(matching: variant) ?? scene.visualAssets.first)?.id
            return copy
        }
    }

    /// Recompiles one asset's constraints, optionally forcing a different seed.
    public func recompile(
        asset: VisualAsset,
        scene: StoryScene,
        characters: [StoryCharacter],
        template: ResolvedTemplate,
        storyID: UUID,
        seedPolicy: SeedPolicy,
        forceNewSeed: Bool
    ) throws -> VisualAsset {
        let revision = forceNewSeed ? asset.revision + 1 : asset.revision
        let constraints = try compileConstraints(
            scene: scene,
            variant: asset.variant,
            characters: characters,
            template: template,
            storyID: storyID,
            seedPolicy: seedPolicy,
            revision: revision
        )
        var copy = asset
        copy.revision = revision
        copy.fingerprint = constraints.fingerprint
        copy.promptSnapshot = constraints
        return copy
    }

    // MARK: - Variants

    private func plannedVariants(for scene: StoryScene, pages: [StoryPage], policy: SceneVisualPolicy) -> [VisualVariant] {
        switch policy {
        case .singleAssetPerScene:
            // One picture for the whole scene: the first page's shot wins, so
            // the choice is stable rather than whichever page sorted last.
            guard let first = pages.min(by: { $0.index < $1.index }) else { return [.default] }
            return [variant(for: first, policy: policy)]

        case .assetPerVariant:
            var seen: Set<VisualVariant> = []
            var ordered: [VisualVariant] = []
            for page in pages.sorted(by: { $0.index < $1.index }) {
                let value = variant(for: page, policy: policy)
                if seen.insert(value).inserted { ordered.append(value) }
            }
            return ordered
        }
    }

    private func variant(for page: StoryPage, policy: SceneVisualPolicy) -> VisualVariant {
        switch policy {
        case .singleAssetPerScene:
            // Under a single-asset policy every page in the scene must resolve
            // to the same variant, or pages would point at assets that do not
            // exist. The scene's own composition is what they all share.
            return VisualVariant()
        case .assetPerVariant:
            return VisualVariant(compositionRuleID: page.compositionRuleID)
        }
    }

    // MARK: - Constraints

    private func compileConstraints(
        scene: StoryScene,
        variant: VisualVariant,
        characters: [StoryCharacter],
        template: ResolvedTemplate,
        storyID: UUID,
        seedPolicy: SeedPolicy,
        revision: Int
    ) throws -> VisualConstraintSet {
        let seed = Self.seed(
            storyID: storyID,
            scene: scene,
            variant: variant,
            characters: characters,
            seedPolicy: seedPolicy,
            revision: revision
        )
        do {
            return try compiler.compile(
                VisualCompilationInput(
                    style: template.visualStyle,
                    sceneContext: scene.visualContext,
                    variant: variant,
                    cast: characters.resolved,
                    seed: seed,
                    preferredAssetRole: .master
                )
            )
        } catch let error as VisualSystemError {
            throw StoryEngineError.visual(error)
        }
    }

    /// Deterministic seed.
    ///
    /// Derived rather than random so that regenerating a page without asking
    /// for a reroll produces the same picture, and asking for one (which bumps
    /// `revision`) reliably produces a different one.
    static func seed(
        storyID: UUID,
        scene: StoryScene,
        variant: VisualVariant,
        characters: [StoryCharacter],
        seedPolicy: SeedPolicy,
        revision: Int
    ) -> UInt64 {
        var components = [
            "story:\(storyID.uuidString)",
            "scene:\(scene.id.uuidString)",
            "revision:\(revision)",
            "salt:\(seedPolicy.salt)"
        ]
        components.append(contentsOf: variant.fingerprintComponents)
        components.append(contentsOf: characters.map { "identity:\($0.identity.identitySeed)" }.sorted())
        return StableHash.hash(components)
    }
}
