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

    /// Every blueprint that can be satisfied by the catalog under this intent,
    /// plus a line for each that cannot and why.
    public func admissible(
        catalog: ContentCatalog,
        intent: OfflineStoryIntent
    ) -> (blueprints: [CatalogBlueprint], rejections: [String]) {
        var admitted: [CatalogBlueprint] = []
        var rejections: [String] = []

        for blueprint in catalog.blueprints where blueprint.isBeatAuthored {
            var failures: [String] = []

            func check<Record: Identifiable, Trait: Hashable & RawRepresentable>(
                _ records: [Record],
                pinned: ContentID?,
                axis: String,
                offered: KeyPath<Record, Set<Trait>>,
                required: Set<Trait>,
                forbidden: Set<Trait>
            ) where Record.ID == ContentID, Trait.RawValue == String {
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
                    failures.append("no \(axis) offers \(required.map(\.rawValue).sorted().joined(separator: ", "))")
                }
            }

            check(catalog.settings, pinned: intent.settingID, axis: "setting",
                  offered: \.traits, required: blueprint.requires.setting,
                  forbidden: blueprint.forbids.setting)
            check(catalog.companions, pinned: intent.companionID, axis: "companion",
                  offered: \.traits, required: blueprint.requires.companion,
                  forbidden: blueprint.forbids.companion)
            check(catalog.objects, pinned: intent.discoveryID, axis: "discovery",
                  offered: \.traits, required: blueprint.requires.discovery,
                  forbidden: blueprint.forbids.discovery)

            if failures.isEmpty {
                admitted.append(blueprint)
            } else {
                rejections.append("  \(blueprint.id.rawValue) (\(blueprint.family?.rawValue ?? "no family")): "
                                  + failures.joined(separator: "; "))
            }
        }

        return (admitted, rejections)
    }

    /// The blueprint this intent gets, or a typed failure naming every
    /// blueprint that was ruled out and why. There is no "pick any" branch.
    public func select(
        catalog: ContentCatalog,
        intent: OfflineStoryIntent
    ) throws -> CatalogBlueprint {
        let (candidates, rejections) = admissible(catalog: catalog, intent: intent)
        guard !candidates.isEmpty else {
            throw OfflineSelectionError.noBlueprintForChoices(reasons: rejections)
        }
        // Sorted before picking so the choice cannot depend on catalog order.
        let ordered = candidates.sorted { $0.id.rawValue < $1.id.rawValue }
        return DeterministicPicker.pick(from: ordered, seed: intent.seed, salt: "blueprint")
    }
}
