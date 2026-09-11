import Foundation
import EngineFoundation
import VisualSystem

/// What makes one moment of the story visually distinct from another.
///
/// Two pages with the same signature are looking at the same place, at the same
/// time, with the same people in it — so they can share a picture.
public struct SceneSignature: Codable, Sendable, Hashable {
    public let settingKey: String
    public let timeOfDayKey: String
    public let moodKey: String
    public let castNames: [String]

    public init(settingKey: String, timeOfDayKey: String, moodKey: String, castNames: [String]) {
        self.settingKey = settingKey
        self.timeOfDayKey = timeOfDayKey
        self.moodKey = moodKey
        self.castNames = castNames.sorted()
    }

    /// Compares only the parts the template says should start a new scene, so
    /// a mood shift can be made to matter — or not — per template.
    public func matches(_ other: SceneSignature, triggers: Set<SceneRules.SceneChangeTrigger>) -> Bool {
        if triggers.contains(.setting), settingKey != other.settingKey { return false }
        if triggers.contains(.timeOfDay), timeOfDayKey != other.timeOfDayKey { return false }
        if triggers.contains(.mood), moodKey != other.moodKey { return false }
        if triggers.contains(.cast), castNames != other.castNames { return false }
        return true
    }

    public var fingerprintComponents: [String] {
        ["setting:\(settingKey)", "time:\(timeOfDayKey)", "mood:\(moodKey)", "cast:\(castNames.joined(separator: "+"))"]
    }
}

/// Where a rendered image actually lives. Opaque to the engine.
public struct ImageRef: Codable, Sendable, Hashable {
    public let locator: String
    public let width: Int?
    public let height: Int?
    public let createdAt: Date

    public init(locator: String, width: Int? = nil, height: Int? = nil, createdAt: Date) {
        self.locator = locator
        self.width = width
        self.height = height
        self.createdAt = createdAt
    }
}

public enum VisualAssetState: String, Codable, Sendable, Hashable, CaseIterable {
    case notRequested
    case pending
    case ready
    case failed
}

/// One illustration of a scene.
///
/// A scene may own several: the same clearing at the same hour, but a wide
/// establishing shot on one page and a close-up on another. `fingerprint` is
/// what decides whether an asset needs drawing — if it still matches what a
/// `.ready` asset was drawn from, nothing is sent to the image provider.
public struct VisualAsset: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public let sceneID: UUID
    public let variant: VisualVariant
    public var fingerprint: String
    public var state: VisualAssetState
    public var imageRef: ImageRef?
    public var promptSnapshot: VisualConstraintSet?
    public var revision: Int
    public var failureMessage: String?
    /// What looking at the produced image concluded, if anything looked.
    ///
    /// Cleared whenever the asset is redrawn, because a record about the
    /// previous picture says nothing about the new one.
    public var validation: ImageValidationRecord?

    public init(
        id: UUID,
        sceneID: UUID,
        variant: VisualVariant = .default,
        fingerprint: String,
        state: VisualAssetState = .notRequested,
        imageRef: ImageRef? = nil,
        promptSnapshot: VisualConstraintSet? = nil,
        revision: Int = 0,
        failureMessage: String? = nil,
        validation: ImageValidationRecord? = nil
    ) {
        self.id = id
        self.sceneID = sceneID
        self.variant = variant
        self.fingerprint = fingerprint
        self.state = state
        self.imageRef = imageRef
        self.promptSnapshot = promptSnapshot
        self.revision = revision
        self.failureMessage = failureMessage
        self.validation = validation
    }

    public var isReady: Bool { state == .ready && imageRef != nil }

    /// The validation record, but only if it describes the current image.
    public var currentValidation: ImageValidationRecord? {
        guard let validation, validation.describes(self) else { return nil }
        return validation
    }

    /// Whether this asset needs to be sent to an image provider.
    ///
    /// The whole point of principle 7: a ready asset whose fingerprint still
    /// matches the constraints it would be drawn from costs nothing.
    public func needsGeneration(against currentFingerprint: String) -> Bool {
        guard isReady else { return true }
        return fingerprint != currentFingerprint
    }
}

/// A visual context that one or more pages share.
///
/// Deliberately not "an image". A scene is where and when the story is; how
/// many pictures that turns into is a policy decision, not a fact about the
/// data model.
public struct StoryScene: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public let index: Int
    public let signature: SceneSignature
    public let visualContext: SceneVisualContext
    public var pageIDs: [UUID]
    public var visualAssets: [VisualAsset]

    public init(
        id: UUID,
        index: Int,
        signature: SceneSignature,
        visualContext: SceneVisualContext,
        pageIDs: [UUID] = [],
        visualAssets: [VisualAsset] = []
    ) {
        self.id = id
        self.index = index
        self.signature = signature
        self.visualContext = visualContext
        self.pageIDs = pageIDs
        self.visualAssets = visualAssets
    }

    public func asset(id assetID: UUID) -> VisualAsset? { visualAssets.first { $0.id == assetID } }

    public func asset(matching variant: VisualVariant) -> VisualAsset? {
        visualAssets.first { $0.variant == variant }
    }

    public var readyAssets: [VisualAsset] { visualAssets.filter(\.isReady) }

    public mutating func upsert(_ asset: VisualAsset) {
        if let index = visualAssets.firstIndex(where: { $0.id == asset.id }) {
            visualAssets[index] = asset
        } else {
            visualAssets.append(asset)
        }
    }

    public func upserting(_ asset: VisualAsset) -> StoryScene {
        var copy = self
        copy.upsert(asset)
        return copy
    }

    /// Identity of the scene itself, independent of how it is drawn.
    public var fingerprint: String {
        StableHash.fingerprint(signature.fingerprintComponents)
    }
}
