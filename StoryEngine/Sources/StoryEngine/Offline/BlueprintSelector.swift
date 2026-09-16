import Foundation

/// Chooses which story *shape* the child's three choices get.
///
/// This is the inverse of `OfflineContentBinder`, and the direction that
/// carries the architecture's central claim: the discovery the child picks is
/// not decoration, it is the most informative input the engine has. Footprints
/// imply a presence, so they can recruit an absence or a misreading; they cannot
/// recruit a threshold. Modelled as a bare object that information is lost, and
/// blueprint selection falls back to "any of the twelve" — which is how twelve
/// blueprints produced one story.
public struct BlueprintSelector: Sendable {
    public init() {}

    /// The idea this intent is working from, if any.
    ///
    /// A named idea that is not in the catalog is an error, never a silent
    /// "surprise me": the child chose something, and quietly giving them a
    /// different story is exactly the substitution this engine exists to stop.
    public func storyIdea(
        catalog: ContentCatalog,
        intent: OfflineStoryIntent
    ) throws -> CatalogStoryIdea? {
        guard let id = intent.storyIdeaID else { return nil }
        guard let idea = catalog.storyIdeas.first(where: { $0.id == id }) else {
            throw OfflineSelectionError.storyIdeaNotFound(id: id)
        }
        return idea
    }

    /// Every blueprint that can be satisfied by the catalog under this intent,
    /// plus a line for each that cannot and why.
    public func admissible(
        catalog: ContentCatalog,
        intent: OfflineStoryIntent,
        idea: CatalogStoryIdea? = nil
    ) -> (blueprints: [CatalogBlueprint], rejections: [String]) {
        var admitted: [CatalogBlueprint] = []
        var rejections: [String] = []

        for blueprint in catalog.blueprints where blueprint.isBeatAuthored {
            var failures: [String] = []

            // The idea narrows; it never relaxes. Combining rather than
            // replacing is what keeps a blueprint's own premise intact — an
            // idea about following traces cannot talk a Threshold blueprint out
            // of needing a threshold.
            let requires = idea.map { blueprint.requires.combined(with: $0.requires) } ?? blueprint.requires
            let forbids = idea.map { blueprint.forbids.combined(with: $0.forbids) } ?? blueprint.forbids

            func check<Record: Identifiable, Trait>(
                _ records: [Record],
                pinned: ContentID?,
                axis: String,
                offered: KeyPath<Record, Set<Trait>>,
                required: TraitRequirement<Trait>,
                forbidden: Set<Trait>
            ) where Record.ID == ContentID {
                // A pinned choice must itself fit; otherwise any record may.
                let pool = pinned.map { id in records.filter { $0.id == id } } ?? records
                let fits = pool.contains {
                    TraitMatch.admits(offered: $0[keyPath: offered],
                                      required: required, forbidden: forbidden)
                }
                guard !fits else { return }
                if let pinned, let record = records.first(where: { $0.id == pinned }) {
                    let why = TraitMatch.rejection(offered: record[keyPath: offered],
                                                   required: required, forbidden: forbidden)
                    failures.append("\(axis) '\(pinned.rawValue)' \(why ?? "does not fit")")
                } else if pinned != nil {
                    failures.append("\(axis) '\(pinned!.rawValue)' is not in the catalog")
                } else {
                    failures.append("no \(axis) offers \(required.unmet(in: []).joined(separator: "; "))")
                }
            }

            check(catalog.settings, pinned: intent.settingID, axis: "setting",
                  offered: \.traits, required: requires.setting,
                  forbidden: forbids.setting)
            check(catalog.companions, pinned: intent.companionID, axis: "companion",
                  offered: \.traits, required: requires.companion,
                  forbidden: forbids.companion)
            check(catalog.objects, pinned: intent.discoveryID, axis: "discovery",
                  offered: \.traits, required: requires.discovery,
                  forbidden: forbids.discovery)

            if failures.isEmpty {
                admitted.append(blueprint)
            } else {
                rejections.append("  \(blueprint.id.rawValue) (\(blueprint.family?.rawValue ?? "no family")): "
                                  + failures.joined(separator: "; "))
            }
        }

        return (admitted, rejections)
    }

    /// Every blueprint this intent could get, best first.
    ///
    /// A list rather than a single answer, because admissibility is judged one
    /// axis at a time and the axes are not independent. A blueprint can admit
    /// the companion the child picked *and* admit some setting, while admitting
    /// no setting the companion could plausibly be in: the dolphin fits on
    /// capability, the sea fits on traits, and the blueprint needs a threshold
    /// the sea does not have. Nothing checking one axis at a time can see that.
    ///
    /// So the caller walks this list until one blueprint binds, the same
    /// backtracking the binder already does over settings and for the same
    /// reason. The child chose a companion; the engine's job is to find a shape
    /// that works with it, not to pick a shape first and then report that the
    /// choice was impossible.
    public func ranked(
        catalog: ContentCatalog,
        intent: OfflineStoryIntent
    ) throws -> [CatalogBlueprint] {
        let idea = try storyIdea(catalog: catalog, intent: intent)
        let (candidates, rejections) = admissible(catalog: catalog, intent: intent, idea: idea)
        guard !candidates.isEmpty else {
            throw OfflineSelectionError.noBlueprintForChoices(reasons: rejections)
        }

        // Sorted before picking so the choice cannot depend on catalog order.
        let ordered = candidates.sorted { $0.id.rawValue < $1.id.rawValue }

        // Affinity, applied as preference rather than as a filter (§12). A card
        // that always resolved to one blueprint would be a preset; a card that
        // ignored its own promise would be a lie. So: the families the idea
        // leans toward come first, and the rest stay available behind them
        // rather than being discarded — the fallback is now an ordering, which
        // is what lets an unbuildable preference give way without silence.
        let preferred = Set(idea?.preferredFamilies ?? [])
        let leaning = ordered.filter { $0.family.map(preferred.contains) ?? false }
        let rest = ordered.filter { !($0.family.map(preferred.contains) ?? false) }

        func rotated(_ items: [CatalogBlueprint]) -> [CatalogBlueprint] {
            guard !items.isEmpty else { return [] }
            let start = DeterministicPicker.index(
                count: items.count, seed: intent.seed, salt: "blueprint")
            return Array(items[start...] + items[..<start])
        }
        return rotated(leaning) + rotated(rest)
    }

    /// The blueprint this intent gets, or a typed failure naming every
    /// blueprint that was ruled out and why. There is no "pick any" branch.
    public func select(
        catalog: ContentCatalog,
        intent: OfflineStoryIntent
    ) throws -> CatalogBlueprint {
        try ranked(catalog: catalog, intent: intent)[0]
    }

    /// The companions worth offering for this intent, best first.
    ///
    /// Step 2 of the flow asks "who should come with us?", and the answer has to
    /// depend on step 1 — otherwise the companion is decoration. A companion is
    /// offered when at least one admissible blueprint would accept it, which is
    /// why a literal-minded rabbit never appears for a story about misreading
    /// the evidence: the blueprint that tells that story forbids it.
    public func companionCandidates(
        catalog: ContentCatalog,
        intent: OfflineStoryIntent,
        idea: CatalogStoryIdea?
    ) -> [CatalogCompanion] {
        let (candidates, _) = admissible(catalog: catalog, intent: intent, idea: idea)
        guard !candidates.isEmpty else { return [] }

        let preferred = Set(idea?.preferredFamilies ?? [])
        let leaning = candidates.filter { $0.family.map(preferred.contains) ?? false }
        let pool = leaning.isEmpty ? candidates : leaning

        return catalog.companions.filter { companion in
            pool.contains { blueprint in
                let requires = idea.map { blueprint.requires.combined(with: $0.requires) } ?? blueprint.requires
                let forbids = idea.map { blueprint.forbids.combined(with: $0.forbids) } ?? blueprint.forbids
                return TraitMatch.admits(
                    offered: companion.traits,
                    required: requires.companion,
                    forbidden: forbids.companion
                )
            }
        }
        .sorted { $0.id.rawValue < $1.id.rawValue }
    }
}
