import XCTest
@testable import StoryEngine

/// Supply is per **cell**, not per beat.
///
/// Every declared filter partitions the pool, and they compose. `meet_companion`
/// declares sixteen variants; four cast roles times two length classes is eight
/// cells of one to four, and a story is bound to exactly one cell before a
/// single variant is eligible. A cell of one means every book of that binding
/// gets the same page — which was true on page 3 of a shipped blueprint while
/// the beat's headline count read sixteen.
///
/// This is the fourth appearance of one mistake. `afterBeat` was caught and
/// fixed, and the fix was named too narrowly — as being about `afterBeat` — so
/// `castRoles`, `discoveryTraits` and `lengthClass` went on dividing pools
/// unwatched. The generalisation is this file.
final class BoundPoolTests: XCTestCase {

    /// Below this a binding has no meaningful choice left.
    private let floor = 4

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    /// One legal binding, plus each part the companion could be playing in it.
    ///
    /// Legality is decided by the binder itself rather than re-derived here.
    /// Re-deriving it is exactly the drift this test exists to catch one layer
    /// down: a check that reimplements the rules it is checking will eventually
    /// disagree with them and report defects that are not there.
    private struct Cell {
        let blueprint: CatalogBlueprint
        let content: BoundContent
    }

    private func cells(in catalog: ContentCatalog) throws -> [Cell] {
        let binder = OfflineContentBinder()
        var found: [Cell] = []

        // Trait-less records are unselectable and say so; including them would
        // measure the unmigrated library rather than the live one.
        let settings = catalog.settings.filter { !$0.traits.isEmpty }
        let companions = catalog.companions.filter { !$0.traits.isEmpty }
        let objects = catalog.objects.filter { !$0.traits.isEmpty }

        for blueprint in catalog.blueprints where blueprint.isBeatAuthored && !blueprint.requires.isEmpty {
            for setting in settings {
                for companion in companions {
                    for discovery in objects {
                        let intent = OfflineStoryIntent(
                            childName: "Yeliz",
                            settingID: setting.id,
                            companionID: companion.id,
                            discoveryID: discovery.id,
                            seed: "cells")
                        // A rejection means this is not a legal binding, which
                        // is an answer and not a failure.
                        guard let bound = try? binder.bind(
                            blueprint: blueprint, catalog: catalog, intent: intent)
                        else { continue }

                        // The binder commits to one part; every part it *could*
                        // have committed to is a cell a real story can land in.
                        let roles = TraitMatch.castableRoles(
                            offered: companion.castRoles, casting: blueprint.requires.casting)
                        for role in roles.sorted(by: { $0.rawValue < $1.rawValue }) {
                            found.append(Cell(blueprint: blueprint, content: BoundContent(
                                setting: bound.setting, companion: bound.companion,
                                discovery: bound.discovery, castRole: role)))
                        }
                    }
                }
            }
        }
        return found
    }

    func testThereAreBindingsToCheck() throws {
        XCTAssertGreaterThan(try cells(in: catalog()).count, 20,
                             "No constrained binding was reachable; the sweep proves nothing.")
    }

    /// Every page of every legal binding has a pool, and a pool worth having.
    ///
    /// Measured through `OfflineStoryComposer.pool` — the composer's own
    /// narrowing, not a copy of it.
    func testEveryPageOfEveryLegalBindingHasRealChoice() throws {
        let catalog = try catalog()
        var thin: [String] = []
        var worst = Int.max

        for cell in try cells(in: catalog) {
            // The page walk comes from the composer, not from a copy of it. The
            // first version of this test rebuilt the walk and got `closing`
            // wrong — it answered "how did the story end" with "what came
            // immediately before", which on a page pairing `self_recognize`
            // with `warm_close` is a different beat. It reported an authoring
            // gap that did not exist.
            for step in try OfflineStoryComposer.plan(cell.blueprint) {
                let templates = OfflineStoryComposer.templates(
                    for: step.beat, in: catalog, blueprint: cell.blueprint)
                // A beat with no template at all is a different defect, and
                // `checkBeatCoverage` is where it is reported.
                guard !templates.isEmpty else { continue }

                var available = 0
                for template in templates {
                    let pool = try OfflineStoryComposer.pool(
                        from: template.variants, realizing: step.beat, wanting: step.wanted,
                        after: step.previous, closing: step.closing, state: step.state,
                        onPage: step.pageNumber, content: cell.content,
                        register: cell.blueprint.family?.beliefRegister,
                        conflict: cell.blueprint.family?.conflict)
                    available += pool.count
                }
                worst = min(worst, available)
                if available < floor {
                    thin.append(
                        "\(cell.blueprint.id.rawValue) p\(step.pageNumber) "
                        + "\(step.beat.rawValue) [\(cell.content.setting.id.rawValue)/"
                        + "\(cell.content.companion.id.rawValue) as "
                        + "\(cell.content.castRole?.rawValue ?? "-")/"
                        + "\(cell.content.discovery.id.rawValue)]: \(available)")
                }
            }
        }

        XCTAssertTrue(thin.isEmpty,
                      "Bound cells under \(floor) lines — every book of these bindings reads "
                      + "the same page:\n" + Set(thin).sorted().prefix(25).joined(separator: "\n"))
        XCTAssertLessThan(worst, Int.max, "Nothing was measured.")
    }

    /// The property the headline counts cannot express, stated directly: a
    /// beat's declared total says nothing about what any one story can choose
    /// from once the filters standing beside it have partitioned the pool.
    func testABeatsDeclaredTotalIsNotItsSupply() throws {
        let catalog = try catalog()
        let meet = catalog.templates.filter { $0.realizesBeat == .meetCompanion }
        let declared = meet.flatMap(\.variants).count
        XCTAssertGreaterThan(declared, 8, "Fixture too small to show partitioning.")

        var cellSizes: [String: Int] = [:]
        for variant in meet.flatMap(\.variants) {
            for role in variant.castRoles {
                let key = "\(role.rawValue)/\(variant.lengthClass?.rawValue ?? "any")"
                cellSizes[key, default: 0] += 1
            }
        }
        let smallest = try XCTUnwrap(cellSizes.values.min())
        XCTAssertLessThan(smallest, declared,
                          "If the smallest cell equals the total, nothing is partitioning "
                          + "and this test has stopped testing anything.")
        XCTAssertGreaterThanOrEqual(
            smallest, floor,
            "Smallest meet_companion cell is \(smallest) of \(declared) declared: "
            + "\(cellSizes.filter { $0.value < floor })")
    }
}
