import Foundation
import EngineFoundation

/// What a scene looks like, independent of any one illustration of it.
public struct SceneVisualContext: Codable, Sendable, Hashable {
    public let settingKey: String
    public let timeOfDayKey: String
    public let moodKey: String
    /// Extra scene-specific description, drawn from the outline. Never contains
    /// character appearance — that comes from the cast, only.
    public let sceneClauses: [String]
    /// Overrides the style preset's default composition when the scene calls
    /// for something particular, e.g. an establishing shot.
    public let compositionRuleID: String?

    public init(
        settingKey: String,
        timeOfDayKey: String,
        moodKey: String,
        sceneClauses: [String] = [],
        compositionRuleID: String? = nil
    ) {
        self.settingKey = settingKey
        self.timeOfDayKey = timeOfDayKey
        self.moodKey = moodKey
        self.sceneClauses = sceneClauses
        self.compositionRuleID = compositionRuleID
    }
}

/// One particular way of illustrating a scene.
///
/// This is what makes a scene able to hold more than one image: same visual
/// context, different crop, camera, pose or emotional beat.
public struct VisualVariant: Codable, Sendable, Hashable {
    public let cameraDistance: CameraDistance?
    public let characterPoseKey: String?
    public let emotionalBeatKey: String?
    public let aspectRatio: AspectRatio?
    public let compositionRuleID: String?

    public init(
        cameraDistance: CameraDistance? = nil,
        characterPoseKey: String? = nil,
        emotionalBeatKey: String? = nil,
        aspectRatio: AspectRatio? = nil,
        compositionRuleID: String? = nil
    ) {
        self.cameraDistance = cameraDistance
        self.characterPoseKey = characterPoseKey
        self.emotionalBeatKey = emotionalBeatKey
        self.aspectRatio = aspectRatio
        self.compositionRuleID = compositionRuleID
    }

    /// The plain variant: whatever the scene and composition rule already say.
    public static let `default` = VisualVariant()

    /// Stable, order-independent identity for fingerprinting.
    public var fingerprintComponents: [String] {
        [
            "camera:\(cameraDistance?.rawValue ?? "-")",
            "pose:\(characterPoseKey ?? "-")",
            "beat:\(emotionalBeatKey ?? "-")",
            "aspect:\(aspectRatio?.rawValue ?? "-")",
            "composition:\(compositionRuleID ?? "-")"
        ]
    }
}

/// The complete, vendor-neutral instruction for one illustration.
///
/// This is the only thing an `ImageProvider` ever receives. There is no free
/// text path from the engine to an image model: every clause here came from a
/// design-system document or from the Character Engine.
public struct VisualConstraintSet: Codable, Sendable, Hashable {
    public let styleClauses: [String]
    public let compositionClauses: [String]
    public let paletteClauses: [String]
    public let sceneClauses: [String]
    /// Appearance clauses. Sourced exclusively from `CharacterIdentity`.
    public let identityClauses: [String]
    public let negativeClauses: [String]
    /// Reference images to condition on, most specific first.
    public let referenceLocators: [String]
    public let aspectRatio: AspectRatio
    public let seed: UInt64
    /// Version pins of every document that shaped this set.
    public let provenance: [String]

    public init(
        styleClauses: [String],
        compositionClauses: [String],
        paletteClauses: [String],
        sceneClauses: [String],
        identityClauses: [String],
        negativeClauses: [String],
        referenceLocators: [String],
        aspectRatio: AspectRatio,
        seed: UInt64,
        provenance: [String]
    ) {
        self.styleClauses = styleClauses
        self.compositionClauses = compositionClauses
        self.paletteClauses = paletteClauses
        self.sceneClauses = sceneClauses
        self.identityClauses = identityClauses
        self.negativeClauses = negativeClauses
        self.referenceLocators = referenceLocators
        self.aspectRatio = aspectRatio
        self.seed = seed
        self.provenance = provenance
    }

    /// Positive clauses, in a fixed order, as one string. Providers that want
    /// a single prompt use this; providers with structured inputs read the
    /// individual arrays instead.
    public var positivePrompt: String {
        (sceneClauses + identityClauses + compositionClauses + styleClauses + paletteClauses)
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    public var negativePrompt: String {
        negativeClauses.filter { !$0.isEmpty }.joined(separator: ", ")
    }

    /// Everything that determines whether two requests would produce the same
    /// picture. Seed is included: changing it is a deliberate reroll.
    public var fingerprint: String {
        StableHash.fingerprint(
            styleClauses + compositionClauses + paletteClauses + sceneClauses
                + identityClauses + negativeClauses + referenceLocators
                + [aspectRatio.rawValue, String(seed)] + provenance
        )
    }
}
