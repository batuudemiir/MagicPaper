import XCTest
@testable import StoryEngine

/// Story Creation V2, step 3: the child chooses an idea, not a configuration.
///
/// The product claim being tested is that a card is a **narrative promise, not a
/// preset** — the same idea must be able to become genuinely different stories —
/// while still keeping its promise. Those two pull against each other, and most
/// of what follows pins the line between them.
final class StoryIdeaTests: XCTestCase {

    private func library() throws -> ContentCatalog {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "pilot_library_v1", withExtension: "json"))
        return try JSONDecoder().decode(ContentCatalog.self, from: Data(contentsOf: url))
    }

    private func idea(_ id: String, in catalog: ContentCatalog) throws -> CatalogStoryIdea {
        try XCTUnwrap(catalog.storyIdeas.first { $0.id.rawValue == id }, id)
    }

    private func intent(idea: String?, companion: String? = nil, seed: String) -> OfflineStoryIntent {
        OfflineStoryIntent(
            childName: "Yeliz",
            storyIdeaID: idea.map { ContentID($0) },
            companionID: companion.map { ContentID($0) },
            seed: seed
        )
    }

    // MARK: - The catalog offers ideas

    func testTheLibraryOffersACuratedSet() throws {
        let ideas = try library().storyIdeas
        // §33: a small curated set, not a menu. Three plus Surprise.
        XCTAssertEqual(ideas.count, 3, ideas.map(\.id.rawValue).description)
        for idea in ideas {
            XCTAssertFalse(idea.display.isEmpty)
            XCTAssertFalse(idea.supportingText.isEmpty)
            XCTAssertTrue(idea.suits(age: 5))
            XCTAssertTrue(idea.suits(age: 6))
        }
        XCTAssertEqual(Set(ideas.map(\.id)).count, ideas.count, "Duplicate idea id.")
    }

    /// §14 and §28: the user-facing string must never be the identity.
    func testIdeasAreIdentifiedByStableIDsNotByTheirCopy() throws {
        for idea in try library().storyIdeas {
            XCTAssertTrue(idea.id.rawValue.hasPrefix("idea_"), idea.id.rawValue)
            XCTAssertEqual(idea.id.rawValue, idea.id.rawValue.lowercased())
            XCTAssertFalse(idea.id.rawValue.contains(" "))
            XCTAssertNotEqual(idea.id.rawValue, idea.display)
        }
    }

    /// The ideas must be loadable through the real loader, not only from the
    /// pilot file directly — otherwise the app cannot see them.
    func testIdeasSurviveTheMergedLoad() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        XCTAssertEqual(catalog.storyIdeas.count, 3)
    }

    // MARK: - A promise, not a preset

    /// The central product requirement (§6). If an idea could only ever produce
    /// one blueprint, the card would be a preset wearing a different name.
    func testEachIdeaCanBecomeMoreThanOneStory() throws {
        let catalog = try library()
        for idea in catalog.storyIdeas {
            let (candidates, rejections) = BlueprintSelector().admissible(
                catalog: catalog, intent: intent(idea: idea.id.rawValue, seed: "x"), idea: idea)
            XCTAssertGreaterThan(
                candidates.count, 1,
                "\(idea.id.rawValue) reaches only \(candidates.map(\.id.rawValue)); "
                + "rejected:\n\(rejections.joined(separator: "\n"))")
        }
    }

    func testTheSameIdeaProducesDifferentStoriesAcrossSeeds() throws {
        let catalog = try library()
        var prose: Set<String> = []
        var families: Set<NarrativeFamily> = []
        for seed in ["s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: intent(idea: "idea_follow_the_traces_001", seed: seed))
            prose.insert(story.pages.map(\.text).joined())
            if let family = story.family { families.insert(family) }
        }
        XCTAssertGreaterThan(prose.count, 1, "One card, one story — that is a preset.")
        XCTAssertGreaterThan(families.count, 1, "Only \(families.map(\.rawValue)) reachable.")
    }

    // MARK: - …but the promise is kept

    /// Affinity is a preference, and a preference that never wins is not one.
    func testAnIdeaResolvesToAFamilyItLeansTowardWhenOneIsAvailable() throws {
        let catalog = try library()
        for idea in catalog.storyIdeas {
            let preferred = Set(idea.preferredFamilies)
            XCTAssertFalse(preferred.isEmpty, "\(idea.id.rawValue) leans nowhere.")

            for seed in ["a", "b", "c", "d", "e", "f"] {
                let story = try OfflineStoryComposer().compose(
                    catalog: catalog, intent: intent(idea: idea.id.rawValue, seed: seed))
                let family = try XCTUnwrap(story.family)
                XCTAssertTrue(
                    preferred.contains(family),
                    "\(idea.id.rawValue) promised \(preferred.map(\.rawValue).sorted()) "
                    + "and delivered \(family.rawValue)")
            }
        }
    }

    /// An idea narrows what the engine may bind; it must never widen it. The
    /// "someone needs us" card cannot produce a story about a thing that implies
    /// no need.
    func testAnIdeaConstrainsTheContentThatGetsBound() throws {
        let catalog = try library()
        for seed in ["a", "b", "c", "d", "e", "f", "g", "h"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: intent(idea: "idea_someone_needs_us_001", seed: seed))
            XCTAssertTrue(story.content.discovery.traits.contains(.impliesNeed),
                          "bound \(story.content.discovery.id.rawValue)")
        }
    }

    func testTheSignalIdeaNeverBindsSomethingSilent() throws {
        let catalog = try library()
        for seed in ["a", "b", "c", "d", "e", "f", "g", "h"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: intent(idea: "idea_mysterious_signal_001", seed: seed))
            let traits = story.content.discovery.traits
            XCTAssertTrue(traits.contains(.isUnexplained), story.content.discovery.id.rawValue)
            XCTAssertTrue(traits.contains(.emitsSignal), story.content.discovery.id.rawValue)
        }
    }

    /// Combining must not let an idea talk a blueprint out of its own premise.
    func testAnIdeaCannotRelaxABlueprintsRequirements() throws {
        let catalog = try library()
        let threshold = try XCTUnwrap(catalog.blueprints.first { $0.family == .threshold })
        let idea = try idea("idea_follow_the_traces_001", in: catalog)

        let combined = threshold.requires.combined(with: idea.requires)
        XCTAssertTrue(combined.setting.allOf.contains(.hasThreshold),
                      "The blueprint's own requirement was dropped.")
        XCTAssertTrue(combined.discovery.allOf.isSuperset(of: threshold.requires.discovery.allOf))
        XCTAssertTrue(combined.discovery.allOf.contains(.impliesPresence),
                      "The idea's requirement was dropped.")
    }

    /// Two choice groups stay two choices. Pooling them would let a blueprint's
    /// alternative be answered by the idea's, which is not what either author
    /// wrote.
    func testCombiningKeepsChoiceGroupsSeparate() {
        let a = TraitRequirement<DiscoveryTrait>(anyOf: [[.emitsSignal, .isBeautiful]])
        let b = TraitRequirement<DiscoveryTrait>(anyOf: [[.impliesPresence, .impliesNeed]])
        let combined = a.combined(with: b)
        XCTAssertEqual(combined.anyOf.count, 2)
        XCTAssertTrue(combined.isSatisfied(by: [.emitsSignal, .impliesNeed]))
        XCTAssertFalse(combined.isSatisfied(by: [.emitsSignal, .isBeautiful]),
                       "The second choice went unanswered.")
    }

    func testCombiningUnionsExclusions() {
        let a = ContentExclusions(companion: [.canFly])
        let b = ContentExclusions(companion: [.canCarry], discovery: [.isFragile])
        let combined = a.combined(with: b)
        XCTAssertEqual(combined.companion, [.canFly, .canCarry])
        XCTAssertEqual(combined.discovery, [.isFragile])
    }

    // MARK: - Surprise (§15, §16)

    func testSurpriseAtStepOneStillProducesACoherentStory() throws {
        let catalog = try library()
        for seed in ["a", "b", "c", "d", "e"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog, intent: intent(idea: nil, seed: seed))
            XCTAssertEqual(story.pages.count, 8)
            XCTAssertTrue(story.isClean)
        }
    }

    /// §16 is explicit: choosing Surprise for the companion must not reset the
    /// narrative intent.
    func testSurpriseAtStepTwoKeepsTheChosenIdea() throws {
        let catalog = try library()
        for seed in ["a", "b", "c", "d", "e", "f"] {
            let pinned = try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: intent(idea: "idea_someone_needs_us_001",
                               companion: "companion_hedgehog_pilot_001", seed: seed))
            let surprised = try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: intent(idea: "idea_someone_needs_us_001", companion: nil, seed: seed))

            XCTAssertEqual(pinned.family, surprised.family,
                           "Surprising the companion changed the kind of story.")
            XCTAssertTrue(surprised.content.discovery.traits.contains(.impliesNeed))
        }
    }

    // MARK: - Companion candidates (§8, §9)

    func testCompanionCandidatesDependOnTheChosenIdea() throws {
        let catalog = try library()
        let selector = BlueprintSelector()

        var byIdea: [String: [String]] = [:]
        for idea in catalog.storyIdeas {
            let candidates = selector.companionCandidates(
                catalog: catalog,
                intent: intent(idea: idea.id.rawValue, seed: "x"),
                idea: idea
            ).map(\.id.rawValue)
            XCTAssertFalse(candidates.isEmpty, "\(idea.id.rawValue) offers nobody.")
            byIdea[idea.id.rawValue] = candidates
        }

        XCTAssertGreaterThan(Set(byIdea.values.map { $0.joined() }).count, 1,
                             "Every idea offered the same companions: \(byIdea)")
    }

    /// The reason a companion is a story role and not decoration: the blueprint
    /// that tells a misreading story forbids a companion who would simply say
    /// what it sees.
    func testACompanionThatWouldDissolveThePremiseIsNotOffered() throws {
        let catalog = try library()
        let idea = try idea("idea_follow_the_traces_001", in: catalog)
        let candidates = BlueprintSelector().companionCandidates(
            catalog: catalog,
            intent: intent(idea: idea.id.rawValue, seed: "x"),
            idea: idea
        )
        let rabbit = try XCTUnwrap(
            catalog.companions.first { $0.id.rawValue == "companion_rabbit_pilot_001" })
        XCTAssertTrue(rabbit.traits.contains(.isLiteralMinded))

        // The rabbit may still appear — Absence permits it — but the misreading
        // blueprint must not be what admits it.
        let misreading = try XCTUnwrap(catalog.blueprints.first { $0.family == .misreading })
        XCTAssertFalse(TraitMatch.admits(
            offered: rabbit.traits,
            required: misreading.requires.combined(with: idea.requires).companion,
            forbidden: misreading.forbids.combined(with: idea.forbids).companion))
        XCTAssertFalse(candidates.isEmpty)
    }

    // MARK: - Errors

    /// A named idea that is not in the catalog is an error, never a silent
    /// "surprise me" — the child chose something.
    func testAnUnknownIdeaIsReportedNotSubstituted() throws {
        let catalog = try library()
        XCTAssertThrowsError(
            try OfflineStoryComposer().compose(
                catalog: catalog, intent: intent(idea: "idea_does_not_exist", seed: "x"))
        ) { error in
            guard case OfflineSelectionError.storyIdeaNotFound(let id) = error else {
                return XCTFail("Wrong error: \(error)")
            }
            XCTAssertEqual(id.rawValue, "idea_does_not_exist")
        }
    }

    func testSameIntentWithAnIdeaStaysReproducible() throws {
        let catalog = try library()
        let first = try OfflineStoryComposer().compose(
            catalog: catalog, intent: intent(idea: "idea_mysterious_signal_001", seed: "fixed"))
        let second = try OfflineStoryComposer().compose(
            catalog: catalog, intent: intent(idea: "idea_mysterious_signal_001", seed: "fixed"))
        XCTAssertEqual(first.fingerprint, second.fingerprint)
        XCTAssertEqual(first.pages.map(\.text), second.pages.map(\.text))
    }
}
