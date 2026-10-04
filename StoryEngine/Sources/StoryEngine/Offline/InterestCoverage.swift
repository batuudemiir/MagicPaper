import Foundation

// MARK: - Interest coverage (FAZ 12)

extension BlueprintSelector {
    /// Which interest words each band can actually serve.
    ///
    /// A word *reaches* a band when a blueprint written for that band can build
    /// a whole story with content carrying the word — the blueprint itself, or
    /// a setting, companion or object pinned into it. The binder is asked, not a
    /// copy of its rules: matching traits one axis at a time misses habitat,
    /// which is why the coral sea reaches nothing in 3-4 although water is not
    /// forbidden there (the one 3-4 shape needs someone to look after, and no
    /// one who can be looked after lives in the sea).
    ///
    /// Bands with no blueprint of their own map to an empty set.
    public func interestCoverage(catalog: ContentCatalog) -> [AgeBand: Set<InterestTag>] {
        let binder = OfflineContentBinder()
        var coverage: [AgeBand: Set<InterestTag>] = [:]

        for band in AgeBandResolver.bands {
            var reached = Set<InterestTag>()
            for blueprint in catalog.blueprints where blueprint.isBeatAuthored && blueprint.ageRange == band {
                func binds(
                    settingID: ContentID? = nil,
                    companionID: ContentID? = nil,
                    discoveryID: ContentID? = nil
                ) -> Bool {
                    let probe = OfflineStoryIntent(
                        childName: "", settingID: settingID, companionID: companionID,
                        discoveryID: discoveryID, seed: "interest-coverage", ageBand: band)
                    return (try? binder.bind(blueprint: blueprint, catalog: catalog, intent: probe)) != nil
                }
                func adds(_ record: some InterestTagged) -> Bool {
                    !record.interests.isEmpty && !reached.isSuperset(of: record.interests)
                }

                if adds(blueprint), binds() { reached.formUnion(blueprint.interests) }
                for setting in catalog.settings where adds(setting) && binds(settingID: setting.id) {
                    reached.formUnion(setting.interests)
                }
                for companion in catalog.companions where adds(companion) && binds(companionID: companion.id) {
                    reached.formUnion(companion.interests)
                }
                for object in catalog.objects where adds(object) && binds(discoveryID: object.id) {
                    reached.formUnion(object.interests)
                }
            }
            coverage[band] = reached
        }
        return coverage
    }

    /// The interests a parent is offered: those that reach **every** band the
    /// catalog has content for, in vocabulary order (karar, 4 Ekim 2026).
    ///
    /// One list for every child rather than one per band, so a child growing
    /// into the next band never sees a chip disappear. A word that reaches only
    /// some bands stays in the vocabulary and on any profile that saved it, is
    /// not shown or used until it reaches every band, and is reported to the
    /// content pipeline.
    public func availableInterests(catalog: ContentCatalog) -> [CatalogInterest] {
        let bands = AgeBandResolver.bands.filter { band in
            catalog.blueprints.contains { $0.isBeatAuthored && $0.ageRange == band }
        }
        guard !bands.isEmpty else { return [] }
        let coverage = interestCoverage(catalog: catalog)
        var seen = Set<InterestTag>()
        return catalog.interests.filter { interest in
            guard seen.insert(interest.id).inserted else { return false }
            return bands.allSatisfy { coverage[$0]?.contains(interest.id) ?? false }
        }
    }
}
