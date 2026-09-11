import Foundation
@testable import CharacterEngine

enum CharacterFixtures {
    static let ownerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    static func asset(role: CharacterAssetRole = .master, locator: String = "https://example.test/master.jpg") -> CharacterAsset {
        CharacterAsset(role: role, locator: locator, createdAt: referenceDate)
    }

    static func identity(
        ageYears: Int = 6,
        descriptors: [CharacterDescriptor] = [
            CharacterDescriptor(category: .hair, value: "curly black hair"),
            CharacterDescriptor(category: .eyes, value: "brown eyes")
        ],
        doNotDepict: [String] = []
    ) -> CharacterIdentity {
        CharacterIdentity(
            ageYears: ageYears,
            pronouns: .theyThem,
            descriptors: descriptors,
            identitySeed: 42,
            doNotDepict: doNotDepict
        )
    }

    static let styleProfile = CharacterStyleProfile(
        illustrationStyleID: "storybook_painted_v1",
        palettePresetID: "forest_warm"
    )

    static func assetSet(master: CharacterAsset? = asset()) -> CharacterAssetSet {
        CharacterAssetSet(masterReference: master, identitySeed: 42, stylePresetID: "magic_paper_v1")
    }

    static func version(
        number: Int = 1,
        id: CharacterVersionID = CharacterVersionID(),
        identity: CharacterIdentity? = nil,
        assetSet: CharacterAssetSet? = nil
    ) -> CharacterVersion {
        CharacterVersion(
            id: id,
            versionNumber: number,
            createdAt: referenceDate.addingTimeInterval(TimeInterval(number)),
            identity: identity ?? Self.identity(),
            styleProfile: styleProfile,
            assetSet: assetSet ?? Self.assetSet(),
            provenance: .authoredByParent
        )
    }

    static func profile(
        id: CharacterID = CharacterID(),
        displayName: String = "Deniz",
        versions: [CharacterVersion]? = nil,
        activeVersionID: CharacterVersionID? = nil
    ) -> CharacterProfile {
        let resolvedVersions = versions ?? [version()]
        return CharacterProfile(
            id: id,
            ownerProfileID: ownerID,
            displayName: displayName,
            versions: resolvedVersions,
            activeVersionID: activeVersionID ?? resolvedVersions[0].id,
            createdAt: referenceDate
        )
    }
}
