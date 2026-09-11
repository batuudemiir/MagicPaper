import Foundation
import CharacterEngine

/// Deleting the things the engine created.
///
/// Children's personal data is the point of this product, so where it goes when
/// someone asks for it to be gone has to be an explicit contract rather than
/// whatever the storage layer happens to do.
public protocol StoryDataLifecycle: Sendable {
    func deleteStory(_ storyID: UUID) async throws
    func deleteCharacter(_ characterID: CharacterID) async throws
    func deleteGenerationJob(_ jobID: UUID) async throws
}

/// Removing a file the engine caused to exist.
///
/// The engine never touches bytes — it holds locators. This is the port through
/// which a host app deletes what a locator points at: a file in Documents, an
/// object in cloud storage, a cache entry.
public protocol AssetDeleting: Sendable {
    /// Deletes the asset a locator refers to. Deleting something already gone
    /// must succeed, so that a retried deletion converges rather than fails.
    func deleteAsset(locator: String) async throws
}

/// What a deletion actually removed.
///
/// The three categories are distinct on purpose. A record can be gone from the
/// engine while its pixels are still sitting in cloud storage, and a report that
/// blurred them together would let that go unnoticed.
public struct DeletionReport: Sendable, Hashable {
    /// Engine records removed: stories, jobs, requests, character profiles.
    public private(set) var logicalRecords: [String] = []
    /// Locators the engine asked the host to delete.
    public private(set) var deletedAssetLocators: [String] = []
    /// Locators the engine knows about but does not own — a parent's uploaded
    /// photo lives in the app's storage, and removing a character must not
    /// silently delete the family's own picture.
    public private(set) var externalAssetLocators: [String] = []
    /// Deletions the host reported as failed. Recorded rather than thrown, so
    /// one unreachable file cannot leave the rest of a deletion half-done.
    public private(set) var failedAssetLocators: [String] = []
    /// True when there was nothing to delete.
    public private(set) var wasAlreadyAbsent = false

    public init() {}

    mutating func recordRecord(_ description: String) { logicalRecords.append(description) }
    mutating func recordDeletedAsset(_ locator: String) { deletedAssetLocators.append(locator) }
    mutating func recordExternalAsset(_ locator: String) { externalAssetLocators.append(locator) }
    mutating func recordFailedAsset(_ locator: String) { failedAssetLocators.append(locator) }
    mutating func markAlreadyAbsent() { wasAlreadyAbsent = true }

    public var isEmpty: Bool {
        logicalRecords.isEmpty && deletedAssetLocators.isEmpty && failedAssetLocators.isEmpty
    }
}

/// The engine's own implementation of the deletion contract.
///
/// Idempotent throughout: deleting something that is already gone reports that
/// and succeeds. A deletion that threw halfway would leave a child's data in a
/// state nobody can reason about, which is the opposite of what this is for.
public struct StoryDataLifecycleService: StoryDataLifecycle {
    private let storyRepository: StoryRepository
    private let jobStore: JobStore
    private let characterStore: CharacterStore?
    private let assetDeleter: AssetDeleting?

    public init(
        storyRepository: StoryRepository,
        jobStore: JobStore,
        characterStore: CharacterStore? = nil,
        assetDeleter: AssetDeleting? = nil
    ) {
        self.storyRepository = storyRepository
        self.jobStore = jobStore
        self.characterStore = characterStore
        self.assetDeleter = assetDeleter
    }

    // MARK: - Stories

    public func deleteStory(_ storyID: UUID) async throws {
        _ = try await deleteStoryReporting(storyID)
    }

    /// Deletes a story and says what went with it.
    @discardableResult
    public func deleteStoryReporting(_ storyID: UUID) async throws -> DeletionReport {
        var report = DeletionReport()

        guard let story = try await storyRepository.story(id: storyID) else {
            report.markAlreadyAbsent()
            return report
        }

        // Illustrations the engine caused to be created, including the ones
        // from failed attempts and superseded regenerations — those are exactly
        // the files that would otherwise be orphaned with nothing pointing at
        // them.
        for scene in story.scenes {
            for asset in scene.visualAssets {
                guard let locator = asset.imageRef?.locator else { continue }
                await delete(locator: locator, into: &report)
            }
        }

        // Reference photos belong to the family's profile, not to this story.
        for character in story.characters {
            for reference in character.assetSet.referenceChain(preferring: .master) {
                report.recordExternalAsset(reference.locator)
            }
        }

        try await storyRepository.delete(id: storyID)
        report.recordRecord("story:\(storyID.uuidString)")

        // The job and request that produced it go too, or a resumable
        // checkpoint would try to rebuild a story the user deleted.
        for job in try await jobStore.resumableJobs() where job.storyID == storyID {
            try await jobStore.delete(jobID: job.id)
            report.recordRecord("job:\(job.id.uuidString)")
        }
        try await jobStore.deleteRequest(id: story.requestID)
        report.recordRecord("request:\(story.requestID.uuidString)")

        return report
    }

    // MARK: - Characters

    public func deleteCharacter(_ characterID: CharacterID) async throws {
        _ = try await deleteCharacterReporting(characterID)
    }

    /// Removes a character so no future generation can resolve it.
    ///
    /// Stories already generated keep their embedded copy of the identity they
    /// were drawn with — deleting the character must not corrupt books a child
    /// already owns. Deleting those is `deleteStory`'s job.
    @discardableResult
    public func deleteCharacterReporting(_ characterID: CharacterID) async throws -> DeletionReport {
        var report = DeletionReport()
        guard let characterStore else { return report }

        guard let profile = try await characterStore.profile(id: characterID) else {
            report.markAlreadyAbsent()
            return report
        }

        // Every reference image across every version, not just the active one.
        var seen: Set<String> = []
        for version in profile.versions {
            let assets = [
                version.assetSet.masterReference,
                version.assetSet.fullBodyReference,
                version.assetSet.faceReference
            ].compactMap { $0 } + version.assetSet.expressionReferences.values

            for asset in assets where seen.insert(asset.locator).inserted {
                await delete(locator: asset.locator, into: &report)
            }
        }

        try await characterStore.delete(id: characterID)
        report.recordRecord("character:\(characterID)")
        return report
    }

    // MARK: - Jobs

    public func deleteGenerationJob(_ jobID: UUID) async throws {
        _ = try await deleteGenerationJobReporting(jobID)
    }

    /// Removes a job and its checkpoint, leaving the story it produced intact.
    @discardableResult
    public func deleteGenerationJobReporting(_ jobID: UUID) async throws -> DeletionReport {
        var report = DeletionReport()
        guard try await jobStore.job(id: jobID) != nil else {
            report.markAlreadyAbsent()
            return report
        }
        try await jobStore.delete(jobID: jobID)
        report.recordRecord("job:\(jobID.uuidString)")
        return report
    }

    private func delete(locator: String, into report: inout DeletionReport) async {
        guard let assetDeleter else {
            // Nothing can remove it, so say so rather than implying it is gone.
            report.recordExternalAsset(locator)
            return
        }
        do {
            try await assetDeleter.deleteAsset(locator: locator)
            report.recordDeletedAsset(locator)
        } catch {
            report.recordFailedAsset(locator)
        }
    }
}
