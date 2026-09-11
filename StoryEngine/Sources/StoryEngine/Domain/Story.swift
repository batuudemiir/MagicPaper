import Foundation
import EngineFoundation
import VisualSystem

public enum StoryStatus: String, Codable, Sendable, Hashable, CaseIterable {
    case planning
    case writing
    case illustrating
    case validating
    case ready
    case failed
}

/// Draft, or frozen.
public enum PublicationState: Codable, Sendable, Hashable {
    case draft
    case published(at: Date, contentHash: String)

    public var isPublished: Bool { if case .published = self { return true } else { return false } }
    public var publishedAt: Date? { if case .published(let date, _) = self { return date } else { return nil } }
    public var contentHash: String? { if case .published(_, let hash) = self { return hash } else { return nil } }
}

/// Why a change is being made.
///
/// The distinction exists so that "published" can mean something. A published
/// story rejects ordinary generation writes; it accepts only changes a person
/// explicitly asked for.
public enum MutationOrigin: String, Codable, Sendable, Hashable {
    case generation
    case explicitRegeneration
}

/// The changes a story will accept.
public enum StoryChange: Sendable {
    case setTitle(String)
    case setStatus(StoryStatus)
    case setCast([StoryCharacter])
    case setOutline(StoryOutline)
    case setDraft(NarrativeDraft)
    case setPages([StoryPage])
    case setScenes([StoryScene])
    case replacePageText(pageID: UUID, title: String?, text: String)
    case upsertVisualAsset(sceneID: UUID, asset: VisualAsset)
    case assignVisualAsset(pageID: UUID, assetID: UUID?)
    case recordUsage(AIUsage)
    case setValidation(StoryValidationResult)
    case setProvenance(GenerationProvenance)
    case publish(at: Date)

    /// Whether this change is one a person can ask for after publication.
    var isRegenerationShaped: Bool {
        switch self {
        case .replacePageText, .upsertVisualAsset, .assignVisualAsset,
             .recordUsage, .setValidation, .setProvenance, .setStatus:
            return true
        case .setTitle, .setCast, .setOutline, .setDraft, .setPages, .setScenes, .publish:
            return false
        }
    }
}

public struct StoryMutation: Sendable {
    public let change: StoryChange
    public let origin: MutationOrigin

    public init(_ change: StoryChange, origin: MutationOrigin = .generation) {
        self.change = change
        self.origin = origin
    }
}

/// A book.
///
/// Every write goes through `applying(_:)`. That is the only place publication
/// immutability is enforced, so there is exactly one rule to read and one place
/// for it to be wrong.
public struct Story: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public let requestID: UUID
    public let templateRef: TemplateRef
    public private(set) var title: String
    public private(set) var status: StoryStatus
    public private(set) var characters: [StoryCharacter]
    public private(set) var outline: StoryOutline?
    public private(set) var draft: NarrativeDraft?
    public private(set) var pages: [StoryPage]
    public private(set) var scenes: [StoryScene]
    public private(set) var validation: StoryValidationResult?
    public private(set) var publication: PublicationState
    public private(set) var usage: UsageLedger
    /// How this book was produced. Written at assembly and refreshed by any
    /// explicit regeneration, so it always describes the current contents.
    public private(set) var provenance: GenerationProvenance?
    public let createdAt: Date
    public private(set) var updatedAt: Date
    public let schemaVersion: Int

    public static let currentSchemaVersion = 1

    public init(
        id: UUID,
        requestID: UUID,
        templateRef: TemplateRef,
        title: String = "",
        status: StoryStatus = .planning,
        characters: [StoryCharacter] = [],
        outline: StoryOutline? = nil,
        draft: NarrativeDraft? = nil,
        pages: [StoryPage] = [],
        scenes: [StoryScene] = [],
        validation: StoryValidationResult? = nil,
        publication: PublicationState = .draft,
        usage: UsageLedger = UsageLedger(),
        provenance: GenerationProvenance? = nil,
        createdAt: Date,
        updatedAt: Date? = nil,
        schemaVersion: Int = Story.currentSchemaVersion
    ) {
        self.id = id
        self.requestID = requestID
        self.templateRef = templateRef
        self.title = title
        self.status = status
        self.characters = characters
        self.outline = outline
        self.draft = draft
        self.pages = pages
        self.scenes = scenes
        self.validation = validation
        self.publication = publication
        self.usage = usage
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.schemaVersion = schemaVersion
    }

    // MARK: - Lookups

    public func page(id pageID: UUID) -> StoryPage? { pages.first { $0.id == pageID } }
    public func scene(id sceneID: UUID) -> StoryScene? { scenes.first { $0.id == sceneID } }

    public func scene(forPage pageID: UUID) -> StoryScene? {
        guard let page = page(id: pageID) else { return nil }
        return scene(id: page.sceneID)
    }

    public func visualAsset(id assetID: UUID) -> VisualAsset? {
        scenes.compactMap { $0.asset(id: assetID) }.first
    }

    public func visualAsset(forPage pageID: UUID) -> VisualAsset? {
        guard let assetID = page(id: pageID)?.visualAssetID else { return nil }
        return visualAsset(id: assetID)
    }

    /// Pages that would be affected by redrawing one asset. Callers surface
    /// this so "regenerate this page's picture" can say what else it changes.
    public func pages(sharing assetID: UUID) -> [StoryPage] {
        pages.filter { $0.visualAssetID == assetID }
    }

    public var protagonist: StoryCharacter? { characters.protagonist }

    /// Stable digest of everything a reader would see. Stamped at publication.
    public var contentHash: String {
        var components: [String] = [title]
        for page in pages.sorted(by: { $0.index < $1.index }) {
            components.append("page:\(page.index):\(page.text):\(page.visualAssetID?.uuidString ?? "-")")
        }
        for scene in scenes.sorted(by: { $0.index < $1.index }) {
            for asset in scene.visualAssets.sorted(by: { $0.id.uuidString < $1.id.uuidString }) {
                components.append("asset:\(asset.id):\(asset.fingerprint):\(asset.imageRef?.locator ?? "-")")
            }
        }
        components.append(contentsOf: characters.map(\.versionPin).sorted())
        return StableHash.fingerprint(components)
    }

    // MARK: - Mutation

    /// The single gate. Every write in the engine comes through here.
    public func applying(_ mutation: StoryMutation, at date: Date) throws -> Story {
        if publication.isPublished {
            guard mutation.origin == .explicitRegeneration, mutation.change.isRegenerationShaped else {
                throw StoryEngineError.storyIsPublished(id)
            }
        }

        var copy = self
        copy.updatedAt = date

        switch mutation.change {
        case .setTitle(let value):
            copy.title = value

        case .setStatus(let value):
            copy.status = value

        case .setCast(let value):
            copy.characters = value

        case .setOutline(let value):
            copy.outline = value

        case .setDraft(let value):
            copy.draft = value

        case .setPages(let value):
            copy.pages = value.sorted { $0.index < $1.index }

        case .setScenes(let value):
            copy.scenes = value.sorted { $0.index < $1.index }

        case .replacePageText(let pageID, let newTitle, let text):
            guard let index = copy.pages.firstIndex(where: { $0.id == pageID }) else {
                throw StoryEngineError.pageNotFound(pageID)
            }
            copy.pages[index].text = text
            if let newTitle { copy.pages[index].title = newTitle }
            copy.pages[index].textRevision += 1

        case .upsertVisualAsset(let sceneID, let asset):
            guard let index = copy.scenes.firstIndex(where: { $0.id == sceneID }) else {
                throw StoryEngineError.sceneNotFound(sceneID)
            }
            copy.scenes[index].upsert(asset)

        case .assignVisualAsset(let pageID, let assetID):
            guard let index = copy.pages.firstIndex(where: { $0.id == pageID }) else {
                throw StoryEngineError.pageNotFound(pageID)
            }
            if let assetID, copy.visualAsset(id: assetID) == nil {
                throw StoryEngineError.visualAssetNotFound(assetID)
            }
            copy.pages[index].visualAssetID = assetID

        case .recordUsage(let usage):
            copy.usage = copy.usage.recording(usage)

        case .setValidation(let result):
            copy.validation = result

        case .setProvenance(let value):
            copy.provenance = value

        case .publish(let publishedAt):
            guard let validation = copy.validation, validation.isValid else {
                throw StoryEngineError.validationFailed(
                    (copy.validation?.errors ?? []).map(\.code)
                )
            }
            copy.status = .ready
            copy.publication = .published(at: publishedAt, contentHash: copy.contentHash)
        }

        return copy
    }

    /// Convenience for applying several changes with one origin.
    public func applying(_ changes: [StoryChange], origin: MutationOrigin = .generation, at date: Date) throws -> Story {
        try changes.reduce(self) { story, change in
            try story.applying(StoryMutation(change, origin: origin), at: date)
        }
    }
}
