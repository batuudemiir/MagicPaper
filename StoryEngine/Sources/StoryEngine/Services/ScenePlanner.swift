import Foundation
import EngineFoundation
import VisualSystem

/// Scenes plus the beat-to-scene mapping the page planner needs.
public struct ScenePlan: Sendable {
    public let scenes: [StoryScene]
    public let sceneIDByBeatID: [UUID: UUID]

    public init(scenes: [StoryScene], sceneIDByBeatID: [UUID: UUID]) {
        self.scenes = scenes
        self.sceneIDByBeatID = sceneIDByBeatID
    }
}

/// Groups the outline's beats into visual contexts.
///
/// Consecutive beats that are in the same place, at the same time, with the
/// same people, are one scene — and one scene is one picture that several pages
/// share. That is the whole cost story: an 11-page book set mostly in one
/// clearing should not buy eleven illustrations of that clearing.
///
/// Which fields count as "the same" is the template's call, via
/// `SceneRules.changeTriggers`, so a template that wants a fresh picture every
/// time the mood shifts can say so.
public struct ScenePlanner: Sendable {
    private let idGenerator: IDGenerator

    public init(idGenerator: IDGenerator = RandomIDGenerator()) {
        self.idGenerator = idGenerator
    }

    public func planScenes(outline: StoryOutline, template: StoryTemplate) -> ScenePlan {
        let beats = outline.beats.sorted { $0.ordinal < $1.ordinal }
        guard !beats.isEmpty else { return ScenePlan(scenes: [], sceneIDByBeatID: [:]) }

        let rules = template.sceneRules
        var scenes: [StoryScene] = []
        var mapping: [UUID: UUID] = [:]
        var currentSignature: SceneSignature?
        var currentID: UUID?

        for beat in beats {
            let signature = SceneSignature(
                settingKey: beat.settingKey,
                timeOfDayKey: beat.timeOfDayKey,
                moodKey: beat.moodKey,
                castNames: beat.castNames
            )

            // Only consecutive beats merge. A story that returns to the kitchen
            // at the end gets a fresh scene, because the pages in between are
            // not part of that visual moment.
            let continuesCurrentScene = currentSignature?.matches(signature, triggers: rules.changeTriggers) == true
            let atSceneCeiling = scenes.count >= rules.maximumScenes

            if continuesCurrentScene || (atSceneCeiling && currentID != nil) {
                mapping[beat.id] = currentID
                continue
            }

            let sceneID = idGenerator.next()
            scenes.append(
                StoryScene(
                    id: sceneID,
                    index: scenes.count,
                    signature: signature,
                    visualContext: SceneVisualContext(
                        settingKey: beat.settingKey,
                        timeOfDayKey: beat.timeOfDayKey,
                        moodKey: beat.moodKey,
                        sceneClauses: [],
                        compositionRuleID: beat.compositionRuleID
                    )
                )
            )
            mapping[beat.id] = sceneID
            currentSignature = signature
            currentID = sceneID
        }

        return ScenePlan(scenes: scenes, sceneIDByBeatID: mapping)
    }

    /// Fills each scene's `pageIDs` once pages exist.
    public func linking(pages: [StoryPage], to scenes: [StoryScene]) -> [StoryScene] {
        var pagesByScene: [UUID: [UUID]] = [:]
        for page in pages.sorted(by: { $0.index < $1.index }) {
            pagesByScene[page.sceneID, default: []].append(page.id)
        }
        return scenes.map { scene in
            var copy = scene
            copy.pageIDs = pagesByScene[scene.id] ?? []
            return copy
        }
    }
}
