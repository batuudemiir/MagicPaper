import Foundation
import StoryEngine

/// Evaluates actual composed provenance before saved-page tolerant decoding can lose parts.
enum ReviewedDiscoveryArtBinder {
    static func bind(_ story: Story, composed: ComposedStory,
                     policy: ReviewedDiscoveryArtPolicy? = .bundled) -> Story {
        guard let policy, let origin = story.origin,
              origin.seriesID == nil, origin.seriesEpisode == nil,
              origin.catalogVersion == policy.catalogVersion,
              origin.blueprintID == composed.blueprintID.rawValue,
              origin.settingID == composed.content.setting.id.rawValue,
              origin.companionID == composed.content.companion.id.rawValue,
              origin.discoveryID == composed.content.discovery.id.rawValue,
              origin.familyCharacterID == nil, origin.occasionID == nil,
              !composed.pages.isEmpty, story.pages.count == composed.pages.count else { return story }
        let pages = composed.pages.sorted { $0.pageNumber < $1.pageNumber }
        guard pages.map(\.pageNumber) == Array(1...pages.count),
              pages.enumerated().allSatisfy({ story.pages[$0.offset].text == $0.element.text }) else { return story }
        var result = story
        for (index, page) in pages.enumerated() {
            guard page.beats == [.noticeAnomaly], page.refrain == nil,
                  page.missingSlots.isEmpty, page.unrecognisedSuffixes.isEmpty,
                  result.pages[index].art == nil, result.pages[index].scene == nil,
                  result.pages[index].imageFileName == nil, result.pages[index].imageUrl == nil,
                  let authorization = policy.authorization(parts: page.provenance, variantIDs: page.variantIDs.map(\.rawValue),
                    discovery: composed.content.discovery) else { continue }
            let asset = authorization.asset
            result.pages[index].art = StoryPageArt(role: "spot", altText: asset.altText, sourceID: asset.assetID,
                schemaVersion: 1, assetRevision: asset.revision, assetDigest: asset.digest,
                styleRevision: asset.styleRevision, bundledFileName: asset.fileName,
                subjectID: asset.subjectID, subjectState: asset.subjectState, variantIDs: page.variantIDs.map(\.rawValue),
                authoredSourceFingerprint: authorization.proof, bindingPolicyVersion: policy.bindingPolicyVersion,
                catalogVersion: policy.catalogVersion)
        }
        return result
    }
}
