import Foundation
import StoryEngine

/// Runs only while a new exact-source V4 story is mapped. Saved art is never
/// selected again when reading, decoding, or using an older source archive.
enum P56StoryArtBinder {
    private struct Candidate {
        let index: Int
        let asset: P56StoryArtPolicy.Asset
        let rule: P56StoryArtPolicy.Rule
    }

    static func bind(_ story: Story, composed: P56ComposedStory,
                     policy: P56StoryArtPolicy? = .bundled) -> Story {
        guard let policy, policy.isValid, let book = policy.books.first(where: { $0.bookID == composed.bookID }),
              validSource(composed, policy: policy, book: book),
              validStored(story, composed: composed) else { return story }
        let candidates = policy.rules.compactMap { rule -> Candidate? in
            guard rule.bookID == book.bookID,
                  let asset = policy.assets.first(where: { $0.assetID == rule.assetID }) else { return nil }
            return Candidate(index: rule.pageNumber - 1, asset: asset, rule: rule)
        }.sorted {
            $0.rule.priority == $1.rule.priority
                ? ($0.index == $1.index ? $0.asset.assetID < $1.asset.assetID : $0.index < $1.index)
                : $0.rule.priority > $1.rule.priority
        }
        return planned(story, composed: composed, candidates: candidates, policy: policy)
    }

    private static func validSource(_ composed: P56ComposedStory, policy: P56StoryArtPolicy,
                                    book: P56StoryArtPolicy.Book) -> Bool {
        let source = composed.sourceReference
        guard source.schemaVersion == 1, source.packageVersion == policy.packageVersion,
              source.payloadSHA256 == policy.payloadSHA256, source.engineBehaviorID == policy.engineBehaviorID,
              [5, 6].contains(composed.age), composed.companion.id == book.companionID,
              composed.structureID == book.structureID, composed.mode.rawValue == book.mode,
              composed.worldID == book.worldID, composed.discoveryID == book.discoveryID,
              composed.pages.map(\.number) == Array(1...8) else { return false }
        return zip(composed.pages, book.pages).allSatisfy { page, expected in
            let trace = page.provenance
            return page.number == expected.number && page.beat.rawValue == expected.beat
                && page.settingID == expected.settingID && trace.order == 0
                && trace.templateID == expected.templateID && trace.templateSHA256 == expected.templateSHA256
                && trace.parentSourceID == expected.parentSourceID && trace.parentSHA256 == expected.parentSHA256
                && trace.parentPointer == expected.parentPointer
                && page.text == (try? P56Personalization.render(expected.templateText, name: composed.childName))
                && trace.renderedSHA256 == P56StoryArtPolicy.digest(Data(page.text.utf8))
        }
    }

    private static func validStored(_ story: Story, composed: P56ComposedStory) -> Bool {
        guard let origin = story.origin, story.childName == composed.childName,
              story.pages.count == 8, origin.contentSource?.p56Reference == composed.sourceReference,
              origin.p56BookID == composed.bookID, origin.catalogVersion == composed.sourceReference.packageVersion,
              origin.companionID == composed.companion.id, origin.blueprintID == composed.structureID,
              origin.discoveryID == composed.discoveryID, origin.modeID == composed.mode.rawValue,
              origin.settingID == composed.pages.first?.settingID,
              origin.fingerprint == P56StoryMapper.fingerprint(ofRenderedDigests: composed.pages.map(\.provenance.renderedSHA256)),
              origin.ageBand == AgeBandResolver.band(forAge: composed.age).description,
              origin.seed == String(composed.seed), origin.familyCharacterID == nil, origin.familyRelation == nil,
              origin.occasionID == nil, origin.seriesID == nil, origin.seriesEpisode == nil else { return false }
        return zip(story.pages, composed.pages).allSatisfy { stored, page in
            guard let provenance = stored.provenance, provenance.isComplete,
                  provenance.parts.isEmpty, provenance.partCount == 0,
                  let trace = provenance.p56 else { return false }
            return stored.text == page.text && trace.packageVersion == composed.sourceReference.packageVersion
                && trace.templateID == page.provenance.templateID
                && trace.templateSHA256 == page.provenance.templateSHA256
                && trace.parentSourceID == page.provenance.parentSourceID
                && trace.parentSHA256 == page.provenance.parentSHA256
                && trace.parentPointer == page.provenance.parentPointer
                && trace.renderedSHA256 == page.provenance.renderedSHA256 && trace.order == 0
        }
    }

    private static func planned(_ story: Story, composed: P56ComposedStory,
                                candidates: [Candidate], policy: P56StoryArtPolicy) -> Story {
        var result = story
        var count = story.pages.filter(hasImage).count
        var used = Set(story.pages.compactMap { $0.art?.assetDigest })
        for window in [[0, 1], [2, 3, 4, 5], [6, 7]] {
            guard count < 3, !window.contains(where: { hasImage(result.pages[$0]) }) else { continue }
            guard let candidate = candidates.first(where: {
                window.contains($0.index) && !hasImage(result.pages[$0.index]) && !used.contains($0.asset.digest)
            }) else { continue }
            let page = composed.pages[candidate.index]
            result.pages[candidate.index].art = art(candidate.asset, page: page, policy: policy)
            used.insert(candidate.asset.digest)
            count += 1
        }
        return result
    }

    private static func hasImage(_ page: StoryPage) -> Bool {
        page.art != nil || page.scene != nil || page.imageFileName != nil || page.imageUrl != nil
    }

    private static func art(_ asset: P56StoryArtPolicy.Asset, page: P56ComposedPage,
                            policy: P56StoryArtPolicy) -> StoryPageArt {
        let trace = page.provenance
        let proof = P56StoryArtPolicy.digest(Data([policy.reviewID, policy.payloadSHA256,
            trace.templateID, trace.templateSHA256, trace.parentSourceID, trace.parentSHA256,
            trace.parentPointer, trace.renderedSHA256, asset.assetID, asset.digest].joined(separator: "\u{1f}").utf8))
        return StoryPageArt(role: "spot", altText: asset.altText, sourceID: asset.assetID,
            schemaVersion: 1, assetRevision: asset.revision, assetDigest: asset.digest,
            styleRevision: asset.styleRevision, bundledFileName: asset.fileName,
            subjectID: asset.subjectID, subjectState: asset.subjectState,
            variantIDs: [trace.templateID], authoredSourceFingerprint: proof,
            bindingPolicyVersion: 4, catalogVersion: policy.packageVersion)
    }
}
