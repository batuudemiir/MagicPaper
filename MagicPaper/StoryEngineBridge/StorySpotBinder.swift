import Foundation
import StoryEngine

/// Assigns a reviewed decision once, while both authored provenance and app pages exist.
enum StorySpotBinder {
    static func bind(_ story: Story, composed: ComposedStory, catalog: StorySpotCatalog?) -> Story {
        guard catalog != nil else { return story }
        let story = ReviewedDiscoveryArtBinder.bind(story, composed: composed)
        guard let catalog, let origin = story.origin,
              origin.blueprintID == composed.blueprintID.rawValue,
              origin.settingID == composed.content.setting.id.rawValue,
              origin.companionID == composed.content.companion.id.rawValue,
              origin.discoveryID == composed.content.discovery.id.rawValue,
              origin.familyCharacterID == nil, origin.occasionID == nil,
              !composed.pages.isEmpty, story.pages.count == composed.pages.count else { return story }
        let pages = composed.pages.sorted { $0.pageNumber < $1.pageNumber }
        guard pages.map(\.pageNumber) == Array(1...pages.count),
              pages.enumerated().allSatisfy({ story.pages[$0.offset].text == $0.element.text }),
              let first = pages.first, first.role.rawValue == "hook",
              first.beats.map(\.rawValue) == ["notice_anomaly"], first.refrain == nil,
              first.missingSlots.isEmpty, first.unrecognisedSuffixes.isEmpty,
              let fingerprint = first.authoredSourceFingerprint,
              story.pages[0].art == nil, story.pages[0].scene == nil,
              story.pages[0].imageFileName == nil, story.pages[0].imageUrl == nil else { return story }
        let matches = catalog.rules.filter {
            $0.catalogVersion == origin.catalogVersion && $0.blueprintID == origin.blueprintID
                && $0.pageNumber == first.pageNumber && $0.role == first.role.rawValue
                && $0.beats == first.beats.map(\.rawValue)
                && $0.variantIDs == first.variantIDs.map(\.rawValue)
                && $0.authoredSourceFingerprint == fingerprint
                && ($0.settingIDs.map { $0.contains(origin.settingID) } ?? true)
        }
        guard matches.count == 1, let rule = matches.first,
              let asset = catalog.assets.first(where: {
                  $0.assetID == rule.assetID && $0.revision == rule.assetRevision
                      && $0.subjectID == origin.discoveryID
              }) else { return story }
        var result = story
        result.pages[0].art = StoryPageArt(role: "spot", altText: asset.altText, sourceID: asset.assetID,
            schemaVersion: 1, assetRevision: asset.revision, assetDigest: asset.digest,
            styleRevision: asset.styleRevision, bundledFileName: asset.fileName,
            subjectID: asset.subjectID, subjectState: asset.subjectState, variantIDs: rule.variantIDs,
            authoredSourceFingerprint: fingerprint, bindingPolicyVersion: rule.bindingPolicyVersion,
            catalogVersion: rule.catalogVersion)
        return result
    }
}
