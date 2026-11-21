import Foundation
import StoryEngine

/// Adds bounded art once, using complete original engine provenance only.
enum WholeBookArtBinder {
    private struct Candidate {
        let index: Int
        let entry: WholeBookArtPolicy.Entry
        let rule: WholeBookArtPolicy.Rule
    }

    static func bind(_ story: Story, composed: ComposedStory,
                     policy: WholeBookArtPolicy? = .bundled) -> Story {
        guard let policy, let origin = story.origin,
              origin.seriesID == nil, origin.seriesEpisode == nil,
              origin.familyCharacterID == nil, origin.occasionID == nil,
              origin.catalogVersion == policy.catalogVersion,
              policy.blueprintIDs.contains(origin.blueprintID),
              origin.blueprintID == composed.blueprintID.rawValue,
              origin.settingID == composed.content.setting.id.rawValue,
              origin.companionID == composed.content.companion.id.rawValue,
              origin.discoveryID == composed.content.discovery.id.rawValue,
              composed.isClean, composed.pages.count == 8, story.pages.count == 8,
              composed.pages.map(\.pageNumber) == Array(1...8),
              composed.pages.enumerated().allSatisfy({ story.pages[$0.offset].text == $0.element.text })
        else { return story }
        return planned(story, candidates: candidates(story, composed: composed, policy: policy), policy: policy)
    }

    private static func candidates(_ story: Story, composed: ComposedStory,
                                   policy: WholeBookArtPolicy) -> [Candidate] {
        var result: [Candidate] = []
        for (index, page) in composed.pages.enumerated() {
            guard !hasImage(story.pages[index]), page.refrain == nil,
                  page.missingSlots.isEmpty, page.unrecognisedSuffixes.isEmpty else { continue }
            for rule in policy.rules {
                guard let entry = policy.assets.first(where: { $0.asset.assetID == rule.assetID }) else { continue }
                let isDiscovery = entry.subjectRole == "discovery"
                let subject = isDiscovery ? composed.content.discovery.id.rawValue : composed.content.companion.id.rawValue
                let fingerprint = isDiscovery
                    ? AuthoredSourceFingerprint.make(sources: [], discovery: composed.content.discovery)
                    : WholeBookArtPolicy.companionFingerprint(composed.content.companion)
                if policy.matches(rule, blueprintID: composed.blueprintID.rawValue, pageNumber: page.pageNumber,
                    role: page.role.rawValue, beats: page.beats.map(\.rawValue), parts: page.provenance,
                    variantIDs: page.variantIDs.map(\.rawValue), subjectID: subject, canonicalFingerprint: fingerprint) {
                    result.append(Candidate(index: index, entry: entry, rule: rule))
                }
            }
        }
        return result.sorted {
            if $0.rule.requiredStates.count != $1.rule.requiredStates.count {
                return $0.rule.requiredStates.count > $1.rule.requiredStates.count
            }
            if $0.index != $1.index { return $0.index < $1.index }
            return $0.entry.asset.assetID < $1.entry.asset.assetID
        }
    }

    private static func planned(_ story: Story, candidates: [Candidate], policy: WholeBookArtPolicy) -> Story {
        var result = story
        var count = story.pages.filter(hasImage).count
        var used = Set(story.pages.compactMap { $0.art?.assetDigest })
        let windows = [[0, 1], [3, 4, 5, 2], [6, 7]]
        for window in windows {
            guard count < 3, !window.contains(where: { hasImage(result.pages[$0]) }) else { continue }
            // Middle pages 4–6 have priority over page 3, after state specificity.
            let choices = candidates.filter { window.contains($0.index) && !used.contains($0.entry.asset.digest) }
                .sorted { left, right in
                    if left.rule.requiredStates.count != right.rule.requiredStates.count {
                        return left.rule.requiredStates.count > right.rule.requiredStates.count
                    }
                    let a = window.firstIndex(of: left.index)!, b = window.firstIndex(of: right.index)!
                    return a == b ? left.entry.asset.assetID < right.entry.asset.assetID : a < b
                }
            guard let choice = choices.first else { continue }
            result.pages[choice.index].art = art(entry: choice.entry, rule: choice.rule, policy: policy)
            used.insert(choice.entry.asset.digest)
            count += 1
        }
        return result
    }

    private static func hasImage(_ page: StoryPage) -> Bool {
        page.art != nil || page.scene != nil || page.imageFileName != nil || page.imageUrl != nil
    }

    static func art(entry: WholeBookArtPolicy.Entry, rule: WholeBookArtPolicy.Rule,
                    policy: WholeBookArtPolicy) -> StoryPageArt {
        let asset = entry.asset
        let proof = PageSourcePart.digest([policy.reviewID, Self.proof(rule), entry.canonicalFingerprint,
            entry.view, asset.assetID, asset.digest].joined(separator: "\u{1f}"))
        return StoryPageArt(role: "spot", altText: asset.altText, sourceID: asset.assetID,
            schemaVersion: 1, assetRevision: asset.revision, assetDigest: asset.digest,
            styleRevision: asset.styleRevision, bundledFileName: asset.fileName,
            subjectID: asset.subjectID, subjectState: asset.subjectState,
            variantIDs: rule.orderedParts.map(\.sourceID), authoredSourceFingerprint: proof,
            bindingPolicyVersion: 3, catalogVersion: policy.catalogVersion)
    }

    private static func proof(_ rule: WholeBookArtPolicy.Rule) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let parts = (try? encoder.encode(rule.orderedParts)) ?? Data()
        return [rule.blueprintID, String(rule.pageNumber), rule.role, rule.beats.joined(separator: ","),
            String(decoding: parts, as: UTF8.self)].joined(separator: "\u{1f}")
    }
}
