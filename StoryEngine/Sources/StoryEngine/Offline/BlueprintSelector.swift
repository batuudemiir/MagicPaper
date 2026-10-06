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

        // A mode with no profile admits nothing: the parent asked for an
        // intent the catalog cannot serve, and quietly serving another one is
        // the substitution this engine exists to stop.
        let modeProfile = intent.mode.flatMap { catalog.modeProfile($0) }

        for blueprint in catalog.blueprints where blueprint.isBeatAuthored {
            var failures: [String] = []

            if let band = intent.ageBand, blueprint.ageRange != band {
                failures.append("written for \(blueprint.ageRange), not \(band)")
            }
            if let mode = intent.mode, !(modeProfile?.admits(blueprint) ?? false) {
                failures.append("family '\(blueprint.family?.rawValue ?? "none")' does not serve mode '\(mode.rawValue)'")
            }

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

            // A Masal ailem character narrows like everything else the parent
            // chose: a blueprint with no line for this relation at one of its
            // family moments is ruled out here, with the beat named, rather
            // than tried and silently swapped for the next one.
            if intent.family != nil, catalog.familyMoments.isEmpty {
                failures.append("the catalog declares no family moments")
            } else if let relation = intent.family?.relation,
               let gap = OfflineStoryComposer.familyGap(
                   in: blueprint, catalog: catalog, relation: relation) {
                failures.append("no '\(relation.rawValue)' line for '\(gap.rawValue)' in \(blueprint.ageRange)")
            }
            if intent.family?.relation == .animal, intent.family?.animalKind == nil {
                failures.append("an animal Masal ailem character needs a kind")
            }

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

        // Within each group, interests, recent history (FAZ 12) and what the
        // child's reading taught (FAZ 14) weigh the order. Equal weights — no interests, no history — are the seeded
        // rotation this always was.
        let wanted = Set(intent.interests)
        let recent = intent.recent.map(\.blueprintID)
        func weighted(_ items: [CatalogBlueprint]) -> [CatalogBlueprint] {
            SelectionScoring.ordered(
                items,
                weights: items.map { blueprint in
                    SelectionScoring.weight(
                        id: blueprint.id,
                        matchesInterest: hostsInterest(
                            blueprint, wanted: wanted, catalog: catalog, intent: intent, idea: idea),
                        recent: recent,
                        // What the child's reading taught (FAZ 14) and what
                        // every child's reading will (aggregate, 1 today).
                        usage: intent.usage.multiplier(family: blueprint.family)
                            * blueprint.aggregateWeight)
                },
                id: \.id, seed: intent.seed, salt: "blueprint")
        }
        return weighted(leaning) + weighted(rest)
    }

    /// Whether this blueprint can tell a story about something the child likes:
    /// it is tagged itself, or it can be built around a setting, companion or
    /// discovery that is. Asked of the binder, with the intent's own pins kept,
    /// so a blueprint is not preferred for content it could never be given.
    func hostsInterest(
        _ blueprint: CatalogBlueprint,
        wanted: Set<InterestTag>,
        catalog: ContentCatalog,
        intent: OfflineStoryIntent,
        idea: CatalogStoryIdea?
    ) -> Bool {
        guard !wanted.isEmpty else { return false }
        if blueprint.matches(wanted) { return true }
        let binder = OfflineContentBinder()
        func binds(_ probe: OfflineStoryIntent) -> Bool {
            (try? binder.bind(blueprint: blueprint, catalog: catalog, intent: probe, idea: idea)) != nil
        }
        if intent.settingID == nil, catalog.settings.contains(where: {
            $0.matches(wanted) && binds(intent.pinning(settingID: $0.id))
        }) { return true }
        if intent.companionID == nil, catalog.companions.contains(where: {
            $0.matches(wanted) && binds(intent.pinning(companionID: $0.id))
        }) { return true }
        if intent.discoveryID == nil, catalog.objects.contains(where: {
            $0.matches(wanted) && binds(intent.pinning(discoveryID: $0.id))
        }) { return true }
        return false
    }

    /// The blueprint this intent gets, or a typed failure naming every
    /// blueprint that was ruled out and why. There is no "pick any" branch.
    public func select(
        catalog: ContentCatalog,
        intent: OfflineStoryIntent
    ) throws -> CatalogBlueprint {
        try ranked(catalog: catalog, intent: intent)[0]
    }

    /// The modes a story can actually be built in for this band.
    ///
    /// A mode is offered, and a surprise may land on it, only if its profile
    /// admits at least one beat-authored blueprint written for the band. Nil
    /// band means any band.
    public func availableModes(catalog: ContentCatalog, ageBand: AgeBand?) -> [StoryMode] {
        StoryMode.allCases.filter { mode in
            guard let profile = catalog.modeProfile(mode) else { return false }
            return catalog.blueprints.contains { blueprint in
                blueprint.isBeatAuthored
                    && profile.admits(blueprint)
                    && (ageBand.map { blueprint.ageRange == $0 } ?? true)
            }
        }
    }

    /// Hangi mod hangi yaş bandında kurulabilir — ürünün tanıdığı her bant için.
    ///
    /// Bandın **kendi** blueprint'lerine bakar; içeriği olmayan bir bandın
    /// başka banttan sunulması (`AgeBandResolver.servedBand`) burada yok
    /// sayılır, çünkü soru "bu bant için ne yazıldı?". Boş liste o bant için
    /// hiç içerik yazılmadığı anlamına gelir.
    public func modeCoverage(catalog: ContentCatalog) -> [AgeBand: [StoryMode]] {
        Dictionary(uniqueKeysWithValues: AgeBandResolver.bands.map { band in
            (band, availableModes(catalog: catalog, ageBand: band))
        })
    }

    /// The Masal ailem relations a story can carry in this mode and band.
    ///
    /// A relation is offered when some blueprint the mode admits for the band
    /// has a line at every one of its family moments. The screen shows the
    /// rest as unavailable rather than letting a choice fail at "Başla".
    public func availableFamilyRelations(
        catalog: ContentCatalog,
        mode: StoryMode?,
        ageBand: AgeBand?
    ) -> [FamilyRelationKind] {
        // No moments means no line ever carries the character: offering it
        // would write a story that never mentions them.
        guard !catalog.familyMoments.isEmpty else { return [] }
        let profile = mode.flatMap { catalog.modeProfile($0) }
        let blueprints = catalog.blueprints.filter { blueprint in
            blueprint.isBeatAuthored
                && (mode == nil || (profile?.admits(blueprint) ?? false))
                && (ageBand.map { blueprint.ageRange == $0 } ?? true)
        }
        return FamilyRelationKind.allCases.filter { relation in
            blueprints.contains {
                OfflineStoryComposer.familyGap(in: $0, catalog: catalog, relation: relation) == nil
            }
        }
    }

    /// For every blueprint, the relations it cannot carry and the family moment
    /// that stops it. Empty arrays mean the blueprint carries every relation.
    /// The list FAZ 11 hands to the content pipeline.
    public func familyCoverage(catalog: ContentCatalog) -> [ContentID: [FamilyRelationKind: StoryBeat]] {
        var report: [ContentID: [FamilyRelationKind: StoryBeat]] = [:]
        for blueprint in catalog.blueprints where blueprint.isBeatAuthored {
            var gaps: [FamilyRelationKind: StoryBeat] = [:]
            for relation in FamilyRelationKind.allCases {
                if let gap = OfflineStoryComposer.familyGap(
                    in: blueprint, catalog: catalog, relation: relation) {
                    gaps[relation] = gap
                }
            }
            report[blueprint.id] = gaps
        }
        return report
    }

    /// The idea cards that belong under a mode, for a band.
    ///
    /// An idea belongs when one of the families it leans toward serves the
    /// mode. Ideas are optional personalization under a mode; an empty result
    /// means the flow skips straight past them.
    public func storyIdeas(catalog: ContentCatalog, mode: StoryMode, ageBand: AgeBand?) -> [CatalogStoryIdea] {
        guard let profile = catalog.modeProfile(mode) else { return [] }
        return catalog.storyIdeas.filter { idea in
            (ageBand.map { idea.ageRange == $0 } ?? true)
                && idea.preferredFamilies.contains(where: profile.families.contains)
        }
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

        // Bir arkadaş, onunla BÜTÜN bir hikâye kurulabiliyorsa teklif edilir.
        //
        // Eksenlere tek tek bakmak yetmiyordu ve iki ayrı kusur üretti. İlki:
        // yalnızca yeteneğe bakılıyor, kadro atlanıyordu — "yardıma ihtiyacı
        // olan birini bulalım" kartı, o rolü oynayamayan bir tilkiyi teklif
        // ediyordu. İkincisi daha ince: bir blueprint arkadaşı kabul edip,
        // fikrin istediği keşfi kabul etmeyebiliyor. Yunus "gizemli bir işaret"
        // kartında böyle çıkıyordu — onu kabul eden blueprint o keşfi
        // kabul etmiyordu, ve eksenleri ayrı ayrı denetleyen hiçbir kontrol
        // bunu göremez.
        //
        // Bu yüzden kural yeniden yazılmıyor, BİNDER'A SORULUYOR: bağlanabiliyor
        // mu? Reddi "teklif etme" demek. Kuralın ikinci bir kopyası olmadığı
        // için de bağlama kuralları değiştiğinde bu ekran kendiliğinden
        // doğru kalıyor.
        //
        // Çocuğun gördüğü her kart seçilebilir olmalı: seçildiğinde çalışmayan
        // bir kart, verdiği sözü sessizce başka bir hikâyeye çeviriyor.
        let binder = OfflineContentBinder()
        return catalog.companions.filter { companion in
            pool.contains { blueprint in
                let probe = OfflineStoryIntent(
                    childName: intent.childName,
                    storyIdeaID: intent.storyIdeaID,
                    companionID: companion.id,
                    seed: intent.seed,
                    mode: intent.mode,
                    ageBand: intent.ageBand,
                    subOption: intent.subOption,
                    family: intent.family,
                    interests: intent.interests,
                    recent: intent.recent,
                    usage: intent.usage
                )
                return (try? binder.bind(
                    blueprint: blueprint, catalog: catalog, intent: probe, idea: idea)) != nil
            }
        }
        .sorted { $0.id.rawValue < $1.id.rawValue }
    }
}
