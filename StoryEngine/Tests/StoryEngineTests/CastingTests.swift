import XCTest
@testable import StoryEngine

/// D2 — what a character *is* versus what it is *doing*.
///
/// The conflation these tests exist to prevent was real on both sides of the
/// merge: one blueprint required `isSmallAndVulnerable` and another forbade it,
/// both with sound reasons, because the trait was answering two questions at
/// once. A hedgehog is small in every story and is the one who needs help in
/// only some of them.
final class CastingTests: XCTestCase {

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    private func blueprint(_ id: String) throws -> CatalogBlueprint {
        let catalog = try catalog()
        return try XCTUnwrap(catalog.blueprints.first { $0.id == ContentID(id) })
    }

    // MARK: - The vocabulary is actually split

    /// The point of the delta, stated as a property: no name appears in both
    /// vocabularies, and nothing in the capability list is a part.
    func testNoCapabilityIsAPart() {
        let capabilities = Set(CompanionTrait.allCases.map(\.rawValue))
        let parts = Set(CompanionRole.allCases.map(\.rawValue))
        XCTAssertTrue(capabilities.isDisjoint(with: parts))
        for retired in ["canHesitate", "canReassure", "isSmallAndVulnerable"] {
            XCTAssertNil(CompanionTrait(rawValue: retired),
                         "'\(retired)' conflated a fact with a part and must not come back.")
        }
    }

    /// `isSmall` and `needsCare` are the two halves of the trait that had to be
    /// split, and the content has to *exercise* the split or it bought nothing.
    ///
    /// This is a check on the catalog, not on the types. Two enums that are
    /// perfectly correlated in every record are one enum wearing two names: the
    /// first migration here passed every other test while leaving smallness and
    /// needing care in exact lockstep, which would have carried the old
    /// conflation forward under a new spelling.
    func testSmallnessAndNeedingCareAreIndependentInTheContent() throws {
        let companions = try catalog().companions.filter { !$0.traits.isEmpty }
        XCTAssertTrue(companions.contains { $0.traits.contains(.isSmall) },
                      "Nothing is small; the capability axis is untested.")
        XCTAssertTrue(
            companions.contains { !$0.traits.contains(.isSmall) && $0.castRoles.contains(.needsCare) },
            "Only small companions can need care, so the two axes still move together.")
    }

    // MARK: - Casting selects, and says why when it does not

    /// F3, as a regression test. The threshold blueprint used to require
    /// `canReassure`, which excluded the companion who is frightened too and
    /// goes anyway — the better children's-book choice, and the one its own
    /// worked example had used.
    func testAFrightenedCompanionCanCarryACrossingStory() throws {
        let blueprint = try blueprint("blueprint_threshold_crossing_001")
        XCTAssertNil(TraitMatch.castingRejection(
            offered: [.hesitant, .needsCare], casting: blueprint.requires.casting))
    }

    func testAnUncastableCompanionIsRejectedWithItsReason() throws {
        let blueprint = try blueprint("blueprint_appeal_together_001")
        XCTAssertEqual(
            TraitMatch.castingRejection(offered: [.guide, .reassuring],
                                        casting: blueprint.requires.casting),
            "cannot be cast as needsCare")
    }

    /// Unmigrated content is unavailable to casting rather than admitted by a
    /// requirement that happens to ask nothing — the §8.4 rule, applied to the
    /// new axis.
    func testAPartlessCompanionCannotBeCast() {
        XCTAssertEqual(TraitMatch.castingRejection(offered: [], casting: [.guide]),
                       "declares no castable role")
        XCTAssertEqual(TraitMatch.castingRejection(offered: [], casting: []),
                       "declares no castable role",
                       "A blueprint that casts nothing still cannot use a record that plays nothing.")
    }

    // MARK: - One part per story

    /// A companion eligible for three parts plays exactly one, and every page
    /// agrees about which. Choosing per page would let the same character
    /// arrive trembling and later speak steadily — not a range, two characters.
    func testTheCastIsResolvedOncePerStoryAndEveryPageObeysIt() throws {
        let catalog = try catalog()
        let byID = Dictionary(
            uniqueKeysWithValues: catalog.templates.flatMap(\.variants).map { ($0.id, $0) })

        for seed in ["a", "b", "c", "d", "e", "f", "g", "h"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog, intent: OfflineStoryIntent(childName: "Yeliz", seed: seed))
            let role = try XCTUnwrap(story.content.castRole,
                                     "seed \(seed): a selectable companion must be cast in something.")
            XCTAssertTrue(story.content.companion.castRoles.contains(role),
                          "seed \(seed): cast as a part this companion cannot play.")
            for page in story.pages {
                for variant in page.variantIDs.compactMap({ byID[$0] }) where !variant.castRoles.isEmpty {
                    XCTAssertTrue(
                        variant.castRoles.contains(role),
                        "seed \(seed) p\(page.pageNumber): \(variant.id.rawValue) is written for "
                        + "\(variant.castRoles.map(\.rawValue).sorted()), story cast \(role.rawValue).")
                }
            }
        }
    }

    func testTheSameIntentAlwaysCastsTheSamePart() throws {
        let catalog = try catalog()
        let intent = OfflineStoryIntent(childName: "Yeliz", seed: "repeat")
        let first = try OfflineStoryComposer().compose(catalog: catalog, intent: intent)
        for _ in 0..<5 {
            let again = try OfflineStoryComposer().compose(catalog: catalog, intent: intent)
            XCTAssertEqual(first.content.castRole, again.content.castRole)
            XCTAssertEqual(first.fingerprint, again.fingerprint)
        }
    }

    // MARK: - The part does not degrade

    /// The distinction that makes `chooseVariant` worth reading: content the
    /// line assumes is relaxed under pool pressure, the part is not.
    ///
    /// A line written for a guide, handed to the companion who needs care, does
    /// not read as a slightly-off line — it describes a different character
    /// than the rest of the book does. So the composer raises an authoring gap
    /// instead of quietly picking one.
    func testAMissingLineForTheCastPartIsReportedRatherThanSubstituted() throws {
        let guideOnly = try JSONDecoder().decode(CatalogVariant.self, from: Data("""
        {"id":"v_guide_only","text":"{{companion.name}} yolu biliyordu.",
         "castRoles":["guide"]}
        """.utf8))
        let catalog = try catalog()
        let content = BoundContent(
            setting: try XCTUnwrap(catalog.settings.first { !$0.traits.isEmpty }),
            companion: try XCTUnwrap(catalog.companions.first {
                $0.castRoles.contains(.needsCare)
            }),
            discovery: try XCTUnwrap(catalog.objects.first { !$0.traits.isEmpty }),
            castRole: .needsCare)

        XCTAssertThrowsError(
            try OfflineStoryComposer.chooseVariant(
                from: [guideOnly], realizing: .meetCompanion, wanting: .solo, after: nil,
                onPage: 3, content: content, register: nil, seed: "s", salt: "t")
        ) { error in
            guard case OfflineSelectionError.noVariantForRole(let role, let beat, let page) = error else {
                return XCTFail("Expected an authoring gap, got \(error)")
            }
            XCTAssertEqual(role, .needsCare)
            XCTAssertEqual(beat, .meetCompanion)
            XCTAssertEqual(page, 3)
        }
    }

    /// The other half of the rule: a line that names no part still fits anyone,
    /// which is what keeps the twenty-odd unmigrated beat files usable.
    func testALineThatNamesNoPartFitsWhoeverIsCast() throws {
        let neutral = try JSONDecoder().decode(CatalogVariant.self, from: Data("""
        {"id":"v_neutral","text":"{{child.name}} durdu."}
        """.utf8))
        for role in CompanionRole.allCases {
            XCTAssertTrue(neutral.suits(role: role))
        }
        XCTAssertTrue(neutral.suits(role: nil))
    }

    // MARK: - Capability gating on lines

    /// The workaround this replaces was to delete flight from the prose so
    /// every line would be safe for every companion — which keeps the corpus
    /// usable at the cost of its best sentences.
    func testALineMayAssumeACapabilityAndIsOfferedOnlyToCompanionsThatHaveIt() throws {
        let gliding = try JSONDecoder().decode(CatalogVariant.self, from: Data("""
        {"id":"v_glide","text":"{{companion.name}} süzülerek indi.",
         "capabilityRequire":["canFly"]}
        """.utf8))
        let catalog = try catalog()
        let setting = try XCTUnwrap(catalog.settings.first { !$0.traits.isEmpty })
        let discovery = try XCTUnwrap(catalog.objects.first { !$0.traits.isEmpty })
        let flier = try XCTUnwrap(catalog.companions.first { $0.traits.contains(.canFly) })
        let walker = try XCTUnwrap(catalog.companions.first { !$0.traits.contains(.canFly) })

        XCTAssertTrue(gliding.fits(setting: setting, discovery: discovery, companion: flier))
        XCTAssertFalse(gliding.fits(setting: setting, discovery: discovery, companion: walker))
    }

    // MARK: - Register

    /// A belief voiced as a maybe leaves page 6 something to do; a misreading
    /// has to be held with certainty before it can be overturned. The two are
    /// not stylistic variants of each other, so the family decides.
    func testTheFamilyDecidesHowFirmlyABeliefIsVoiced() {
        XCTAssertEqual(NarrativeFamily.misreading.beliefRegister, .certain)
        for family in NarrativeFamily.allCases where family != .misreading {
            XCTAssertEqual(family.beliefRegister, .tentative,
                           "\(family.rawValue) resolves by \(family.resolution), not revelation.")
        }
    }

    func testAMisreadingStoryNeverVoicesItsBeliefTentatively() throws {
        let catalog = try catalog()
        let byID = Dictionary(
            uniqueKeysWithValues: catalog.templates.flatMap(\.variants).map { ($0.id, $0) })
        var checked = 0

        for seed in ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog, intent: OfflineStoryIntent(childName: "Yeliz", seed: seed))
            guard let wanted = story.family?.beliefRegister else { continue }
            for page in story.pages {
                for variant in page.variantIDs.compactMap({ byID[$0] }) {
                    guard let register = variant.register else { continue }
                    checked += 1
                    XCTAssertEqual(register, wanted,
                                   "seed \(seed) p\(page.pageNumber): \(variant.id.rawValue) is "
                                   + "\(register.rawValue) in a \(story.family!.rawValue) story.")
                }
            }
        }
        XCTAssertGreaterThan(checked, 0, "No variant declares a register; the axis is untested.")
    }

    // MARK: - Integrity

    func testACompanionWithCapabilitiesButNoPartIsReported() throws {
        let orphan = try JSONDecoder().decode(CatalogCompanion.self, from: Data("""
        {"id":"companion_orphan_001","name":"Kuytu","type":"porsuk",
         "tags":["forest"],"traits":["isSmall"]}
        """.utf8))
        let shipped = try catalog()
        let report = CatalogIntegrityChecker().check(ContentCatalog(
            version: shipped.version,
            settings: shipped.settings,
            companions: shipped.companions + [orphan],
            objects: shipped.objects,
            events: shipped.events,
            challenges: shipped.challenges,
            endings: shipped.endings,
            templates: shipped.templates,
            blueprints: shipped.blueprints,
            storyIdeas: shipped.storyIdeas))
        XCTAssertEqual(
            report.issues(withCode: "companion_without_cast_role").map(\.recordID),
            [ContentID("companion_orphan_001")])
    }

    /// The shipped catalog must not itself be mid-migration on this axis: every
    /// companion that selection can reach declares a part.
    func testEverySelectableCompanionInTheShippedCatalogIsCastable() throws {
        let report = CatalogIntegrityChecker().check(try catalog())
        XCTAssertEqual(report.issues(withCode: "companion_without_cast_role"), [])
        XCTAssertEqual(report.issues(withCode: "uncastable_blueprint"), [])
    }
}

/// D3 — the axes added after the compatibility review, and the one removed.
final class SettingAxisTests: XCTestCase {

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    /// `hasDistance` was held by twelve of sixteen settings. A requirement that
    /// three-quarters of the library satisfies is not a requirement, and it was
    /// one blueprint's *only* setting rule — so that rule meant "any setting"
    /// while reading as though it were selective.
    func testTheTraitThatFilteredNothingIsGone() {
        XCTAssertNil(SettingTrait(rawValue: "hasDistance"))
    }

    /// A boundary and what kind of boundary are two statements about one fact,
    /// so they drift. Both directions are silent: a place with a threshold and
    /// no kind cannot be written about, and a place with a kind and no threshold
    /// is never offered to the blueprints that would want it.
    func testEveryThresholdDeclaresWhatKindItIs() throws {
        let report = CatalogIntegrityChecker().check(try catalog())
        XCTAssertEqual(report.issues(withCode: "threshold_without_kind"), [])
        XCTAssertEqual(report.issues(withCode: "kind_without_threshold"), [])
    }

    func testABlueprintAsksForTheKindOfCrossingItsProseCanDescribe() {
        XCTAssertEqual(
            TraitMatch.thresholdRejection(offered: [.opening], wanted: [.span]),
            "offers no span threshold")
        XCTAssertNil(TraitMatch.thresholdRejection(offered: [.opening], wanted: [.opening, .span]))
        XCTAssertNil(TraitMatch.thresholdRejection(offered: [], wanted: []),
                     "A blueprint that is not about crossing must not care.")
    }

    /// A flickering light beside water is perfectly plausible and completely
    /// uninteresting, because the water already explains it. Habitat cannot
    /// catch that — it asks whether the thing could be here, and the answer is
    /// yes. A discovery the setting explains is not a discovery, and the first
    /// four pages are then about nothing.
    func testADiscoveryTheSettingExplainsIsNeverBound() throws {
        let catalog = try catalog()
        for seed in ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog, intent: OfflineStoryIntent(childName: "Yeliz", seed: seed))
            XCTAssertTrue(
                story.content.discovery.explainedBy.isDisjoint(with: story.content.setting.traits),
                "seed \(seed): \(story.content.discovery.id.rawValue) in "
                + "\(story.content.setting.id.rawValue), which accounts for it.")
        }
    }

    func testAskingForAnExplainedDiscoveryIsRefusedWithItsReason() throws {
        let catalog = try catalog()
        // A flickering light is explained by water, and the sea is the one
        // place in the library that has it.
        XCTAssertThrowsError(
            try OfflineStoryComposer().compose(
                catalog: catalog,
                intent: OfflineStoryIntent(
                    childName: "Yeliz",
                    settingID: ContentID("setting_coral_sea_001"),
                    discoveryID: ContentID("object_flickering_light_001"),
                    seed: "explained"))
        ) { error in
            XCTAssertTrue("\(error)".contains("explained"),
                          "The refusal must name the reason, not just fail: \(error)")
        }
    }

    /// Their F6, as a load-time report rather than a rule of thumb in a
    /// document. Not an assertion that the catalog is clean — a vocabulary
    /// legitimately runs ahead of its content — but that running ahead is
    /// visible instead of silent.
    func testAnUnexercisedVocabularyIsReported() throws {
        let report = CatalogIntegrityChecker().check(try catalog())
        let unexercised = report.issues(withCode: "unexercised_vocabulary")
        XCTAssertTrue(
            unexercised.contains { $0.message.contains("'hasWeather'") },
            "`hasWeather` is declared and no setting has it; that must be reported, not silent. "
            + "Got: \(unexercised.map(\.message))")
        XCTAssertTrue(report.isUsable, "An unexercised axis is a warning, never a blocker.")
    }
}

/// The `social` threshold, and the claim that had to be checked rather than
/// taken on trust.
final class SocialThresholdTests: XCTestCase {

    private func meadow() throws -> CatalogSetting {
        let catalog = try ContentCatalogLoader().load().catalog
        return try XCTUnwrap(catalog.settings.first { $0.id == ContentID("setting_festival_meadow_001") })
    }

    /// The axis was declared before anything exercised it, and the load-time
    /// report is what said so out loud. This is the content that answers it.
    func testSomewhereInTheLibraryOffersASocialThreshold() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        XCTAssertTrue(
            catalog.settings.contains { $0.thresholdKinds.contains(.social) },
            "A blueprint asking to be joined rather than crossed matches nothing.")
        let unexercised = CatalogIntegrityChecker().check(catalog)
            .issues(withCode: "unexercised_vocabulary")
        XCTAssertFalse(unexercised.contains { $0.message.contains("'social'") },
                       "Still reported unexercised: \(unexercised.map(\.message))")
    }

    /// A social threshold is a threshold in the sense the axis means — there is
    /// a line and people drew it — so both statements about that one fact have
    /// to agree, or the place is invisible to every blueprint that wants one.
    func testTheSocialThresholdIsStillDeclaredAsAThreshold() throws {
        let meadow = try meadow()
        XCTAssertTrue(meadow.traits.contains(.hasThreshold))
        XCTAssertFalse(meadow.traits.contains(.isHazardous),
                       "Family II forbids it; a joining story is daunting, never dangerous.")
    }

    /// The morphology was asserted to be "a solved shape, not a new one".
    /// Asserted is not verified: `hasPossessiveEnding` is the one property the
    /// renderer cannot infer from spelling, and getting it wrong is what put
    /// both correct and incorrect `'nde` spellings in the shipped corpus.
    func testTheMeadowInflectsTheWayItsRecordClaims() throws {
        let meadow = try meadow()
        let slots: [String: TurkishTextRenderer.Slot] = [
            "setting.name": .init(
                meadow.name,
                isProperNoun: meadow.isProperNoun,
                hasPossessiveEnding: meadow.hasPossessiveEnding,
                blocksSoftening: meadow.blocksSoftening)
        ]
        // The suffix is written after the token and re-spelled by the renderer;
        // an author writes the naive `'da` and gets the `'nda` the possessive
        // requires. That re-spelling is the whole point — it is why both the
        // correct and the incorrect form appear in the shipped corpus, where
        // the author generalised from the subset that happened to be right.
        let cases: [(String, String)] = [
            ("{{setting.name}}'da", "Şenlik Çayırı'nda"),
            ("{{setting.name}}'a", "Şenlik Çayırı'na"),
            ("{{setting.name}}'daki", "Şenlik Çayırı'ndaki")
        ]
        for (pattern, expected) in cases {
            let result = TurkishTextRenderer.render(pattern, slots: slots)
            XCTAssertTrue(result.isClean, "\(pattern): \(result.unrecognisedSuffixes)")
            XCTAssertEqual(result.text, expected)
        }
    }

    /// Reachability, not just existence: a place nothing can be bound alongside
    /// is a different kind of dead end from a place that does not exist.
    func testTheMeadowCanActuallyBePeopled() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let meadow = try meadow()
        let reachable = catalog.companions.filter {
            !$0.traits.isEmpty && TraitMatch.sharesHabitat($0.habitat, setting: meadow.habitat)
        }
        XCTAssertGreaterThanOrEqual(reachable.count, 4,
                                    "Reached: \(reachable.map(\.id.rawValue))")
        XCTAssertFalse(reachable.contains { $0.id == ContentID("companion_dolphin_pilot_001") },
                       "A dolphin in a meadow is the original content defect.")
    }
}

/// The modality axis, which existed in one direction only.
final class DiscoveryModalityTests: XCTestCase {

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    /// `emitsSignal` reads as though it settles how a thing is perceived and
    /// does not: a flickering light and a faint sound both signal. With only
    /// `isVisible` declared, a line built on *hearing* had nothing to require.
    func testSignallingIsNotAModality() throws {
        let objects = try catalog().objects.filter { $0.traits.contains(.emitsSignal) }
        XCTAssertGreaterThan(objects.count, 1, "Need at least two signallers to make the point.")
        XCTAssertTrue(objects.contains { $0.traits.contains(.isVisible) })
        XCTAssertTrue(objects.contains { $0.traits.contains(.isAudible) },
                      "Both kinds of signal must exist, or the axis is untested.")
    }

    /// A modality-less discovery is not neutral, it is both — and a half-built
    /// axis is worse than none, because `isVisible` makes it look handled.
    func testEverySelectableDiscoverySaysHowItIsPerceived() throws {
        let report = CatalogIntegrityChecker().check(try catalog())
        XCTAssertEqual(report.issues(withCode: "discovery_without_modality"), [])
    }

    /// The defect this came from, as a property: the thing the child finds on
    /// page 1 is perceived the same way on page 2, because it is the same
    /// thing. Pages that each read perfectly can still contradict each other,
    /// and only a rendered story shows it.
    func testNoStoryPerceivesItsDiscoveryTwoWays() throws {
        let catalog = try catalog()
        for seed in ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"] {
            let story = try OfflineStoryComposer().compose(
                catalog: catalog, intent: OfflineStoryIntent(childName: "Yeliz", seed: seed))
            let discovery = story.content.discovery
            let byID = Dictionary(
                uniqueKeysWithValues: catalog.templates.flatMap(\.variants).map { ($0.id, $0) })
            for page in story.pages {
                for variant in page.variantIDs.compactMap({ byID[$0] }) {
                    XCTAssertTrue(
                        variant.discoveryTraits.isSubset(of: discovery.traits),
                        "seed \(seed) p\(page.pageNumber): \(variant.id.rawValue) needs "
                        + "\(variant.discoveryTraits.map(\.rawValue).sorted()) but "
                        + "\(discovery.id.rawValue) offers "
                        + "\(discovery.traits.map(\.rawValue).sorted())")
                }
            }
        }
    }
}
