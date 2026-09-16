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
    /// document.
    ///
    /// Asked of a catalog built for the question, not of the shipped one. The
    /// first version named `hasWeather` as its example and passed until somebody
    /// gave a setting weather — a test that fails when the project improves is
    /// worse than no test, and it would have been "fixed" by picking whichever
    /// trait was still unexercised that week. What is being checked is the
    /// checker; whether the shipped catalog currently has gaps is a fact about
    /// content and belongs in its report, not in an assertion.
    func testAnUnexercisedVocabularyIsReported() throws {
        let declaring = try XCTUnwrap(
            try catalog().settings.first { $0.traits.contains(.canConceal) })
        let narrow = ContentCatalog(version: "test", settings: [declaring])

        let unexercised = CatalogIntegrityChecker().check(narrow)
            .issues(withCode: "unexercised_vocabulary")
        let named = Set(unexercised.compactMap { issue -> String? in
            SettingTrait.allCases.map(\.rawValue).first { issue.message.contains("'\($0)'") }
        })
        let missing = Set(SettingTrait.allCases.map(\.rawValue))
            .subtracting(declaring.traits.map(\.rawValue))

        XCTAssertEqual(named, missing,
                       "Every trait no record declares must be reported, and nothing else.")
        XCTAssertTrue(named.contains("isHazardous"),
                      "Sanity: this catalog has one setting and it is not hazardous.")
    }

    /// An unexercised axis is a warning, never a blocker — a vocabulary may
    /// legitimately run ahead of the content that will use it. What must not
    /// happen is that running ahead being silent.
    func testAnUnexercisedVocabularyNeverBlocksLoading() throws {
        XCTAssertTrue(CatalogIntegrityChecker().check(try catalog()).isUsable)
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

/// A blueprint no content can satisfy, which is the failure mode a walk over
/// bindings structurally cannot see.
///
/// A blueprint with no legal binding contributes **no cells**, so every
/// supply gate passes it by producing nothing. The failure is absence, and a
/// sweep measures what is there. Only asking each blueprint directly finds it.
final class BlueprintSatisfiabilityTests: XCTestCase {

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    /// `isFragile` was reported declared-but-unexercised in the same breath as
    /// `social`. `social` was one blueprint's gap and was closed as one; this
    /// was the same signal and it was a whole family — two blueprints, the
    /// entirety of Family VI, matching nothing at all.
    func testTheVocabularyThatWasReportedUnexercisedNowHasContent() throws {
        let objects = try catalog().objects
        XCTAssertTrue(objects.contains { $0.traits.contains(.isFragile) },
                      "Nothing is fragile; a blueprint asking for it selects nobody.")
        XCTAssertTrue(
            objects.contains { $0.traits.isSuperset(of: [.impliesPresence, .impliesNeed]) },
            "Nothing both implies a presence and implies a need, so a blueprint "
            + "asking for a trace of someone who needs something matches nothing.")
    }

    /// Every blueprint the catalog ships can actually be built, with room to
    /// vary. Asked of each blueprint rather than swept over content, because a
    /// blueprint that matches nothing is invisible to a sweep.
    func testEveryShippedBlueprintHasLegalBindings() throws {
        let catalog = try catalog()
        let binder = OfflineContentBinder()
        var counts: [String: Int] = [:]

        let settings = catalog.settings.filter { !$0.traits.isEmpty }
        let companions = catalog.companions.filter { !$0.traits.isEmpty }
        let objects = catalog.objects.filter { !$0.traits.isEmpty }

        for blueprint in catalog.blueprints where blueprint.isBeatAuthored {
            var legal = 0
            for setting in settings {
                for companion in companions {
                    for discovery in objects {
                        let intent = OfflineStoryIntent(
                            childName: "Yeliz", settingID: setting.id,
                            companionID: companion.id, discoveryID: discovery.id, seed: "sat")
                        if (try? binder.bind(
                            blueprint: blueprint, catalog: catalog, intent: intent)) != nil {
                            legal += 1
                        }
                    }
                }
            }
            counts[blueprint.id.rawValue] = legal
        }

        XCTAssertFalse(counts.isEmpty, "No beat-authored blueprint; nothing measured.")
        let starved = counts.filter { $0.value < 4 }.sorted { $0.key < $1.key }
        XCTAssertTrue(starved.isEmpty,
                      "Blueprints with fewer than four legal bindings — every child gets the "
                      + "same book, or no book: \(starved)")
    }
}

/// Adım 2'nin teklifleri, adım 1'in verdiği sözü tutabilmeli.
final class CompanionOfferTests: XCTestCase {

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    /// Teklif edilen her arkadaş, o teklifi mümkün kılan blueprint'te gerçekten
    /// bağlanabilmeli.
    ///
    /// Bu, akışı elle çalıştırırken görüldü: "Yardıma ihtiyacı olan birini
    /// bulalım" kartı, `needsCare` rolünü oynayamayan bir tilkiyi teklif
    /// ediyordu. Süzgeç yetenekleri kontrol ediyor, kadroyu atlıyordu — D2'den
    /// beri yarım kalmış bir kontrol. Çocuk o arkadaşı seçtiğinde blueprint onu
    /// kullanamıyor, motor başka bir şekle geçiyor ve kartın sözü sessizce
    /// başka bir hikâyeye dönüşüyor.
    func testEveryOfferedCompanionCanActuallyBeBound() throws {
        let catalog = try catalog()
        let selector = BlueprintSelector()
        let composer = OfflineStoryComposer()
        var unusable: [String] = []

        for idea in catalog.storyIdeas {
            let offered = selector.companionCandidates(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "", storyIdeaID: idea.id, seed: "offer"),
                idea: idea)
            XCTAssertFalse(offered.isEmpty, "\(idea.id.rawValue) hiç arkadaş teklif etmiyor.")

            for companion in offered {
                let intent = OfflineStoryIntent(
                    childName: "Yeliz", storyIdeaID: idea.id,
                    companionID: companion.id, seed: "offer")
                if (try? composer.compose(catalog: catalog, intent: intent)) == nil {
                    unusable.append("\(idea.id.rawValue) → \(companion.id.rawValue)")
                }
            }
        }

        XCTAssertTrue(unusable.isEmpty,
                      "Teklif edilip kullanılamayan arkadaşlar:\n  "
                      + unusable.joined(separator: "\n  "))
    }

    /// Ve teklif, kadroyu gerçekten daraltıyor olmalı — yoksa üstteki test
    /// hiçbir şey kanıtlamaz.
    func testCastingActuallyNarrowsTheOffer() throws {
        let catalog = try catalog()
        let selector = BlueprintSelector()
        let needsCare = try XCTUnwrap(
            catalog.storyIdeas.first { $0.id == ContentID("idea_someone_needs_us_001") })

        let offered = selector.companionCandidates(
            catalog: catalog,
            intent: OfflineStoryIntent(childName: "", storyIdeaID: needsCare.id, seed: "offer"),
            idea: needsCare)

        XCTAssertFalse(offered.contains { $0.id == ContentID("companion_fox_pilot_001") },
                       "Tilki bakıma muhtaç olanı oynayamaz; bu kart için teklif edilmemeli.")
        XCTAssertTrue(offered.contains { $0.castRoles.contains(.needsCare) },
                      "Oynayabilen biri teklif edilmeli.")
    }
}

/// Yaş, motorda modellenen bir şey — metin değil.
final class AgeBandingTests: XCTestCase {

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    /// Bantlar arasında okuma parametreleri gerçekten değişmeli. Hepsi aynıysa
    /// "yaş bandı" diye bir şey yok, yalnızca bir etiket var.
    func testTheBandsActuallyDiffer() {
        let young = AgeBand(lowerBound: 3, upperBound: 4)
        let mid = AgeBand(lowerBound: 5, upperBound: 7)
        let older = AgeBand(lowerBound: 8, upperBound: 10)

        XCTAssertLessThan(young.maxSentenceWords, mid.maxSentenceWords)
        XCTAssertLessThan(mid.maxSentenceWords, older.maxSentenceWords)
        XCTAssertLessThan(young.pageBudget.upper, mid.pageBudget.upper)
        XCTAssertLessThan(young.pageCount, older.pageCount)
    }

    /// Bugünkü korpus 5-7 bandına yazıldı; bandın söylediğiyle korpusun
    /// yazıldığı sayılar aynı olmalı, yoksa iki kaynak var demektir.
    func testTheShippedBandMatchesWhatTheCorpusWasWrittenTo() {
        let band = AgeBand(lowerBound: 5, upperBound: 6)
        XCTAssertEqual(band.pageBudget.lower, 18)
        XCTAssertEqual(band.pageBudget.upper, 38)
        XCTAssertEqual(band.pageCount, 8)
    }

    /// MLU tavan değil taban: 5-6 yaş ortalama sözce uzunluğu ~5 kelime ve
    /// cümle sınırı bunun belirgin biçimde üstünde olmalı. Altına inerse,
    /// birisi üretim ölçüsünü anlama sınırı sanmış demektir.
    func testSentenceLimitIsWellAboveWhatAChildProduces() {
        XCTAssertGreaterThan(AgeBand(lowerBound: 5, upperBound: 6).maxSentenceWords, 10)
    }

    /// İkinci katman gerektiren aileler daha yüksek bir taban istiyor.
    ///
    /// İkisi arasında fark İDDİA EDİLMİYOR: "revelation, insight'tan bir yaş
    /// daha büyük ister" gibi bir ayrımı kaynaklar söylemiyor, ve söylemediği
    /// için test de sormuyor. Bir testin sormadığı şey, kodun iddia etmediği
    /// şey olmalı.
    func testInferenceFamiliesAskForMoreYears() {
        for family in [NarrativeFamily.misreading, .unexplained] {
            XCTAssertGreaterThan(family.minimumAge, NarrativeFamily.appeal.minimumAge,
                                 "\(family.rawValue) ikinci katman iş istiyor.")
        }
        XCTAssertEqual(NarrativeFamily.misreading.minimumAge,
                       NarrativeFamily.unexplained.minimumAge,
                       "Aralarındaki farkı kaynaklar desteklemiyor.")
    }

    /// Ve gönderilen katalog kendi kuralına uyuyor.
    func testTheShippedCatalogFitsItsOwnBands() throws {
        let report = CatalogIntegrityChecker().check(try catalog())
        XCTAssertEqual(report.issues(withCode: "blueprint_below_family_age"), [])
    }
}


