import Foundation
import CharacterEngine
import EngineFoundation
@testable import VisualSystem

enum VisualFixtures {
    static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    static func character(
        name: String = "Deniz",
        role: CastRole = .protagonist,
        descriptors: [CharacterDescriptor] = [
            CharacterDescriptor(category: .hair, value: "curly black hair"),
            CharacterDescriptor(category: .eyes, value: "brown eyes")
        ],
        doNotDepict: [String] = [],
        negativeTraits: [String] = [],
        renderingNotes: [String] = [],
        assetSet: CharacterAssetSet? = nil
    ) -> ResolvedCharacter {
        let version = CharacterVersion(
            versionNumber: 1,
            createdAt: referenceDate,
            identity: CharacterIdentity(
                ageYears: 6,
                pronouns: .theyThem,
                descriptors: descriptors,
                identitySeed: 7,
                doNotDepict: doNotDepict
            ),
            styleProfile: CharacterStyleProfile(
                illustrationStyleID: "storybook_painted_v1",
                palettePresetID: "paper_warm",
                renderingNotes: renderingNotes,
                negativeTraits: negativeTraits
            ),
            assetSet: assetSet ?? CharacterAssetSet(
                masterReference: CharacterAsset(role: .master, locator: "master.jpg", createdAt: referenceDate),
                identitySeed: 7,
                stylePresetID: "magic_paper_v1"
            ),
            provenance: .authoredByParent
        )
        return ResolvedCharacter(characterID: CharacterID(), displayName: name, role: role, version: version)
    }

    static let sceneContext = SceneVisualContext(
        settingKey: "forest clearing",
        timeOfDayKey: "late afternoon",
        moodKey: "curious",
        sceneClauses: ["a mossy stone circle"]
    )

    static func resolvedStyle() throws -> ResolvedVisualStyle {
        try VisualStyleResolver().resolve(styleID: "magic_paper_v1")
    }
}
