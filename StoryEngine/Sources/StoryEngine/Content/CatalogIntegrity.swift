import Foundation

/// How serious a catalog problem is.
///
/// The distinction earns its keep: the shipped catalog has real referential
/// faults (companions pointing at setting tags that do not exist, themes with no
/// templates). Treating those as fatal would make the engine unusable until the
/// content is rewritten; ignoring them is how a child ends up with a dolphin in
/// a forest. So they are reported, loudly, and the content work fixes them.
public enum CatalogIssueSeverity: String, Codable, Sendable, Hashable, Comparable {
    /// The catalog cannot be used at all.
    case fatal
    /// Usable, but this will produce incoherent stories if selection reaches it.
    case error
    /// Worth fixing; will not by itself break a story.
    case warning

    private var rank: Int {
        switch self {
        case .warning: return 0
        case .error: return 1
        case .fatal: return 2
        }
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rank < rhs.rank }
}

public struct CatalogIssue: Codable, Sendable, Hashable {
    public let severity: CatalogIssueSeverity
    public let code: String
    /// Which record the problem is in, when it is about one.
    public let recordID: ContentID?
    public let message: String

    public init(severity: CatalogIssueSeverity, code: String, recordID: ContentID? = nil, message: String) {
        self.severity = severity
        self.code = code
        self.recordID = recordID
        self.message = message
    }
}

/// What checking the catalog found.
public struct CatalogIntegrityReport: Codable, Sendable, Hashable {
    public let issues: [CatalogIssue]
    public let counts: [String: Int]

    public init(issues: [CatalogIssue], counts: [String: Int]) {
        self.issues = issues
        self.counts = counts
    }

    public var fatals: [CatalogIssue] { issues.filter { $0.severity == .fatal } }
    public var errors: [CatalogIssue] { issues.filter { $0.severity == .error } }
    public var warnings: [CatalogIssue] { issues.filter { $0.severity == .warning } }

    /// Whether the catalog can be used. Errors and warnings do not block; they
    /// describe content that needs work.
    public var isUsable: Bool { fatals.isEmpty }

    public func issues(withCode code: String) -> [CatalogIssue] {
        issues.filter { $0.code == code }
    }

    /// One-line summary for logs and the development catalog screen.
    public var summary: String {
        "\(counts["blueprints"] ?? 0) blueprints, "
            + "\(counts["templates"] ?? 0) templates — "
            + "\(fatals.count) fatal, \(errors.count) error, \(warnings.count) warning"
    }
}

/// Checks that a decoded catalog actually hangs together.
///
/// Every cross-record reference in this schema is by string. Nothing but an
/// explicit check stops a typo becoming a silent random substitution at runtime,
/// which is exactly the failure mode the current prototype has.
public struct CatalogIntegrityChecker: Sendable {
    public init() {}

    public func check(
        _ catalog: ContentCatalog,
        corpus: BeatCorpusLoader.Report? = nil
    ) -> CatalogIntegrityReport {
        var issues: [CatalogIssue] = []
        if let corpus { issues.append(contentsOf: checkCorpus(corpus)) }

        issues.append(contentsOf: checkNotEmpty(catalog))
        issues.append(contentsOf: checkDuplicateIDs(catalog))
        issues.append(contentsOf: checkSettingTagReferences(catalog))
        issues.append(contentsOf: checkThemeCoverage(catalog))
        issues.append(contentsOf: checkBlueprintRoleCoverage(catalog))
        issues.append(contentsOf: checkUnreachableTemplates(catalog))
        issues.append(contentsOf: checkVariants(catalog))
        issues.append(contentsOf: checkBlueprintShape(catalog))
        issues.append(contentsOf: checkBeatAuthoring(catalog))
        issues.append(contentsOf: checkBeatSequences(catalog))
        issues.append(contentsOf: checkBeatCoverage(catalog))
        issues.append(contentsOf: checkCasting(catalog))
        issues.append(contentsOf: checkThresholdKinds(catalog))
        issues.append(contentsOf: checkVocabularyCarriesInformation(catalog))
        issues.append(contentsOf: checkDiscoveryModality(catalog))

        return CatalogIntegrityReport(issues: issues, counts: catalog.recordCounts)
    }

    // MARK: - Checks

    private func checkNotEmpty(_ catalog: ContentCatalog) -> [CatalogIssue] {
        var issues: [CatalogIssue] = []
        if catalog.blueprints.isEmpty {
            issues.append(.init(severity: .fatal, code: "no_blueprints",
                                message: "The catalog contains no blueprints, so no story can be built."))
        }
        if catalog.templates.isEmpty {
            issues.append(.init(severity: .fatal, code: "no_templates",
                                message: "The catalog contains no page templates, so no page can be written."))
        }
        for (name, count) in catalog.recordCounts.sorted(by: { $0.key < $1.key })
        where count == 0 && !["blueprints", "templates"].contains(name) {
            issues.append(.init(severity: .warning, code: "empty_collection",
                                message: "No \(name) in the catalog."))
        }
        return issues
    }

    private func checkDuplicateIDs(_ catalog: ContentCatalog) -> [CatalogIssue] {
        func duplicates(_ ids: [ContentID], _ kind: String) -> [CatalogIssue] {
            var seen: Set<ContentID> = []
            var repeated: [ContentID] = []
            for id in ids where !seen.insert(id).inserted { repeated.append(id) }
            return repeated.map {
                .init(severity: .error, code: "duplicate_id", recordID: $0,
                      message: "Two \(kind) records share the id '\($0)'.")
            }
        }
        return duplicates(catalog.settings.map(\.id), "setting")
            + duplicates(catalog.companions.map(\.id), "companion")
            + duplicates(catalog.objects.map(\.id), "object")
            + duplicates(catalog.events.map(\.id), "event")
            + duplicates(catalog.challenges.map(\.id), "challenge")
            + duplicates(catalog.endings.map(\.id), "ending")
            + duplicates(catalog.templates.map(\.id), "template")
            + duplicates(catalog.blueprints.map(\.id), "blueprint")
    }

    /// Companions, events and challenges point at settings by **tag**. A tag no
    /// setting carries can never match, so that record is unreachable through
    /// that route.
    private func checkSettingTagReferences(_ catalog: ContentCatalog) -> [CatalogIssue] {
        let vocabulary = catalog.settingTagVocabulary
        var issues: [CatalogIssue] = []

        func check(_ id: ContentID, _ tags: [ContentTag], _ kind: String) {
            let orphans = tags.filter { !vocabulary.contains($0) }
            guard !orphans.isEmpty else { return }
            issues.append(.init(
                severity: .error, code: "orphan_setting_tag", recordID: id,
                message: "\(kind) '\(id)' expects setting tag(s) "
                    + orphans.map(\.rawValue).sorted().joined(separator: ", ")
                    + " that no setting declares."
            ))
        }

        catalog.companions.forEach { check($0.id, $0.compatibleSettingTags, "Companion") }
        catalog.events.forEach { check($0.id, $0.compatibleSettingTags, "Event") }
        catalog.challenges.forEach { check($0.id, $0.compatibleSettingTags, "Challenge") }
        return issues
    }

    /// A theme components claim but no template can write is a dead end: content
    /// exists for it, but no page could ever be produced.
    private func checkThemeCoverage(_ catalog: ContentCatalog) -> [CatalogIssue] {
        let templateThemes = Set(catalog.templates.flatMap(\.compatibleThemes))
        let uncovered = catalog.themeVocabulary.subtracting(templateThemes).sorted()
        return uncovered.map {
            .init(severity: .error, code: "theme_without_templates",
                  message: "Theme '\($0)' is used by content but no template can write it.")
        }
    }

    /// Every role a blueprint asks for must have at least one template.
    private func checkBlueprintRoleCoverage(_ catalog: ContentCatalog) -> [CatalogIssue] {
        let covered = Set(catalog.templates.map(\.role))
        return catalog.reachableRoles.subtracting(covered).sorted { $0.rawValue < $1.rawValue }.map {
            .init(severity: .fatal, code: "role_without_templates",
                  message: "Blueprints require role '\($0.rawValue)' but no template provides it.")
        }
    }

    /// Authored templates no blueprint can reach. Not broken, but it is work
    /// nobody will ever see.
    private func checkUnreachableTemplates(_ catalog: ContentCatalog) -> [CatalogIssue] {
        let reachable = catalog.reachableRoles
        let stranded = Set(catalog.templates.map(\.role)).subtracting(reachable)
        return stranded.sorted { $0.rawValue < $1.rawValue }.map { role in
            let count = catalog.templates(for: role).count
            return .init(severity: .warning, code: "unreachable_template",
                         message: "\(count) template(s) for role '\(role.rawValue)' are unreachable — no blueprint uses that role.")
        }
    }

    private func checkVariants(_ catalog: ContentCatalog) -> [CatalogIssue] {
        var issues: [CatalogIssue] = []
        for template in catalog.templates {
            if template.variants.isEmpty {
                issues.append(.init(severity: .error, code: "template_without_variants", recordID: template.id,
                                    message: "Template '\(template.id)' has no variants."))
            }
            for variant in template.variants {
                if variant.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    issues.append(.init(severity: .error, code: "empty_variant_text", recordID: variant.id,
                                        message: "Variant '\(variant.id)' has no text."))
                }
                // A slot present in the text but not declared will still be
                // filled, but the mismatch means the declaration is stale and
                // cannot be trusted for compatibility checks.
                let declared = Set(variant.requiredSlots)
                let actual = Set(variant.actualSlots)
                let undeclared = actual.subtracting(declared).map(\.rawValue).sorted()
                if !undeclared.isEmpty {
                    issues.append(.init(severity: .warning, code: "undeclared_slot", recordID: variant.id,
                                        message: "Variant '\(variant.id)' uses \(undeclared.joined(separator: ", ")) without declaring it."))
                }
                let unused = declared.subtracting(actual).map(\.rawValue).sorted()
                if !unused.isEmpty {
                    issues.append(.init(severity: .warning, code: "unused_declared_slot", recordID: variant.id,
                                        message: "Variant '\(variant.id)' declares \(unused.joined(separator: ", ")) but never uses it."))
                }
            }
        }
        return issues
    }

    /// How far the catalog has moved to the beat-driven model.
    ///
    /// Reported as errors rather than fatals deliberately: the pre-beat catalog
    /// must keep loading until authored replacements exist, but nothing about it
    /// is selectable under the new model, and that must be visible rather than
    /// discovered later.
    private func checkBeatAuthoring(_ catalog: ContentCatalog) -> [CatalogIssue] {
        var issues: [CatalogIssue] = []

        let unauthored = catalog.blueprints.filter { !$0.isBeatAuthored }
        if !unauthored.isEmpty {
            issues.append(.init(
                severity: .error, code: "blueprint_without_beats",
                message: "\(unauthored.count) of \(catalog.blueprints.count) blueprints declare no beats "
                    + "and cannot be selected under the beat-driven model."
            ))
        }

        let beatless = catalog.templates.filter { $0.realizesBeat == nil }
        if !beatless.isEmpty {
            issues.append(.init(
                severity: .error, code: "template_without_beat",
                message: "\(beatless.count) of \(catalog.templates.count) templates declare no realizesBeat "
                    + "and are unselectable; a variant that realizes no beat has nowhere to live."
            ))
        }

        for blueprint in catalog.blueprints where blueprint.family == nil {
            issues.append(.init(severity: .warning, code: "blueprint_without_family", recordID: blueprint.id,
                                message: "Blueprint '\(blueprint.id)' declares no narrative family; the diversity gate cannot read it."))
        }

        return issues
    }

    /// Beat files that were present and could not be read.
    ///
    /// **Fatal.** A corpus file that fails to decode — an unknown trait name is
    /// enough — used to be skipped with a printed warning, which meant the
    /// catalog silently got thinner and every story carried on being told from
    /// whatever was left. That is the same failure mode as the original
    /// `if validTemplates.isEmpty { validTemplates = roleTemplates }`: content
    /// disappearing without anyone being told. The corpus is authored and
    /// shipped, so a file that does not decode is a build defect, and a red
    /// build is the correct outcome.
    private func checkCorpus(_ report: BeatCorpusLoader.Report) -> [CatalogIssue] {
        report.skipped.map { detail in
            CatalogIssue(
                severity: .fatal, code: "beat_file_unreadable",
                message: "A beat corpus file could not be read and its prose is missing: \(detail)"
            )
        }
        + report.drifted.map { detail in
            CatalogIssue(
                severity: .error, code: "beat_file_drift",
                message: "A beat file's declared state disagrees with StoryBeat: \(detail)"
            )
        }
    }

    /// Runs the state rule over every beat-authored blueprint.
    ///
    /// This is what makes "page 7 resolves a conflict page 6 never raised" a
    /// build failure instead of something a reader notices.
    private func checkBeatSequences(_ catalog: ContentCatalog) -> [CatalogIssue] {
        let validator = BeatSequenceValidator()
        var issues: [CatalogIssue] = []

        for blueprint in catalog.blueprints where blueprint.isBeatAuthored {
            let result = validator.validate(
                blueprint.beatSlots,
                conflictMechanism: blueprint.family?.conflict
            )
            for issue in result.issues {
                // The validator now grades its own findings. A structural
                // violation still blocks loading; a liveness warning is carried
                // and counted, because an inert page makes a weaker book, not
                // an incoherent one.
                issues.append(.init(
                    severity: issue.severity == .fatal ? .fatal : .warning,
                    code: "beat_sequence_\(issue.code)", recordID: blueprint.id,
                    message: "Blueprint '\(blueprint.id)': \(issue.message)"
                ))
            }
        }
        return issues
    }

    /// Every beat a blueprint asks for must have a template that realizes it.
    /// A slot with no compatible variant is a named load-time error, never a
    /// silent fallback to "all templates".
    private func checkBeatCoverage(_ catalog: ContentCatalog) -> [CatalogIssue] {
        let realized = Set(catalog.templates.compactMap(\.realizesBeat))
        var required = Set<StoryBeat>()
        for blueprint in catalog.blueprints where blueprint.isBeatAuthored {
            required.formUnion(blueprint.beatSlots.flatMap(\.beats))
        }
        return required.subtracting(realized).sorted { $0.rawValue < $1.rawValue }.map {
            .init(severity: .fatal, code: "beat_without_templates",
                  message: "Blueprints require beat '\($0.rawValue)' but no template realizes it.")
        }
    }

    /// Casting has to have somewhere to land on both sides.
    ///
    /// Two ways it silently does not, both of which produce a story that fails
    /// at compose time rather than at load time — which is the wrong end:
    ///
    /// - a companion that is otherwise selectable but declares no part is
    ///   unusable for every corpus line that names one, and page 3 names one in
    ///   every blueprint;
    /// - a blueprint that casts a part nothing in the catalog can play selects
    ///   nobody, however well-argued the blueprint is.
    ///
    /// Reported as errors rather than fatals, because a catalog can be
    /// legitimately mid-migration and the rest of it still works.
    private func checkCasting(_ catalog: ContentCatalog) -> [CatalogIssue] {
        var issues: [CatalogIssue] = []

        // Trait-less records are already unselectable and say so elsewhere;
        // flagging them here as well would bury the ones that matter.
        for companion in catalog.companions
        where !companion.traits.isEmpty && companion.castRoles.isEmpty {
            issues.append(.init(
                severity: .error, code: "companion_without_cast_role", recordID: companion.id,
                message: "Companion '\(companion.id)' declares capabilities but no castable role, "
                    + "so no line written for a part can be given to it."
            ))
        }

        let castable = catalog.companions.reduce(into: Set<CompanionRole>()) {
            $0.formUnion($1.castRoles)
        }
        for blueprint in catalog.blueprints where !blueprint.requires.casting.isEmpty {
            let orphans = blueprint.requires.casting.subtracting(castable)
            guard orphans.count == blueprint.requires.casting.count else { continue }
            issues.append(.init(
                severity: .error, code: "uncastable_blueprint", recordID: blueprint.id,
                message: "Blueprint '\(blueprint.id)' casts the companion as "
                    + blueprint.requires.casting.map(\.rawValue).sorted().joined(separator: " or ")
                    + ", which no companion in the catalog can play."
            ))
        }
        return issues
    }

    /// `hasThreshold` and `thresholdKinds` are two statements about one fact,
    /// so they can drift — and the drift is silent in both directions.
    ///
    /// A place claiming a boundary but no kind cannot be written about: the
    /// corpus has to choose a verb, and there is nothing to choose from. A place
    /// declaring a kind but no boundary is invisible to every blueprint that
    /// asks for one, so the authoring is simply never used.
    private func checkThresholdKinds(_ catalog: ContentCatalog) -> [CatalogIssue] {
        var issues: [CatalogIssue] = []
        for setting in catalog.settings {
            let claims = setting.traits.contains(.hasThreshold)
            switch (claims, setting.thresholdKinds.isEmpty) {
            case (true, true):
                issues.append(.init(
                    severity: .error, code: "threshold_without_kind", recordID: setting.id,
                    message: "Setting '\(setting.id)' has a threshold but does not say what kind, "
                        + "so no line can name how it is crossed."))
            case (false, false):
                issues.append(.init(
                    severity: .error, code: "kind_without_threshold", recordID: setting.id,
                    message: "Setting '\(setting.id)' declares a threshold kind but not "
                        + "hasThreshold, so no blueprint asking for a threshold will ever see it."))
            default:
                continue
            }
        }
        return issues
    }

    /// A vocabulary member that almost every record holds, or that none holds,
    /// is not carrying information.
    ///
    /// Their F6, as a load-time report. The rule of thumb is theirs too: above
    /// roughly 60% a requirement selects nearly the whole library while looking
    /// selective — which is how one blueprint's *only* setting rule turned out
    /// to mean "any setting" — and at zero the axis exists but nothing exercises
    /// it, so a blueprint built on it selects nobody.
    ///
    /// Warnings, not errors. A vocabulary legitimately runs ahead of the content
    /// that will use it; what must not happen is that running ahead being
    /// invisible.
    private func checkVocabularyCarriesInformation(_ catalog: ContentCatalog) -> [CatalogIssue] {
        var issues: [CatalogIssue] = []

        func audit<Value: RawRepresentable & CaseIterable & Hashable>(
            _ axis: String, _ held: [Set<Value>]
        ) where Value.RawValue == String {
            // Records declaring nothing are unmigrated, not evidence about the
            // vocabulary; counting them would make every trait look rare.
            let declaring = held.filter { !$0.isEmpty }
            guard !declaring.isEmpty else { return }
            for value in Value.allCases.sorted(by: { $0.rawValue < $1.rawValue }) {
                let count = declaring.filter { $0.contains(value) }.count
                let share = Double(count) / Double(declaring.count)
                // "Nothing declares this" is a fact about the catalog and needs
                // no sample size. "Almost everything declares this" is a claim
                // about a distribution, and at four records it is noise — the
                // threshold-kind axis has three, where two-of-three would be
                // reported as uninformative and would not be.
                if count == 0 {
                    issues.append(.init(
                        severity: .warning, code: "unexercised_vocabulary",
                        message: "No \(axis) declares '\(value.rawValue)', so nothing can select on it."))
                } else if share > 0.6 && declaring.count >= 5 {
                    issues.append(.init(
                        severity: .warning, code: "uninformative_vocabulary",
                        message: "\(count) of \(declaring.count) \(axis) records declare "
                            + "'\(value.rawValue)'; a requirement naming it filters almost nothing."))
                }
            }
        }

        audit("setting", catalog.settings.map(\.traits))
        audit("companion", catalog.companions.map(\.traits))
        audit("discovery", catalog.objects.map(\.traits))
        audit("companion role", catalog.companions.map(\.castRoles))
        audit("threshold kind", catalog.settings.map(\.thresholdKinds))
        return issues
    }

    /// Every discovery says how it can be perceived.
    ///
    /// A modality-less discovery is not neutral, it is *both*: nothing stops a
    /// line built on hearing being offered to a light, and nothing stops a line
    /// built on looking being offered to a sound. `emitsSignal` reads as though
    /// it settles this and does not — a flickering light and a faint sound both
    /// signal. The rendered story then opens on a sound and examines a light on
    /// the next page, two pages that each read perfectly and contradict each
    /// other, which no per-line check can see.
    private func checkDiscoveryModality(_ catalog: ContentCatalog) -> [CatalogIssue] {
        catalog.objects
            .filter { !$0.traits.isEmpty && $0.traits.isDisjoint(with: [.isVisible, .isAudible]) }
            .map { object in
                .init(severity: .error, code: "discovery_without_modality", recordID: object.id,
                      message: "Discovery '\(object.id)' says neither that it can be seen nor "
                          + "that it can be heard, so lines written for either will be offered it.")
            }
    }

    private func checkBlueprintShape(_ catalog: ContentCatalog) -> [CatalogIssue] {
        var issues: [CatalogIssue] = []
        for blueprint in catalog.blueprints {
            if blueprint.pagePlan.count != blueprint.pageCount {
                issues.append(.init(severity: .error, code: "page_count_mismatch", recordID: blueprint.id,
                                    message: "Blueprint '\(blueprint.id)' declares \(blueprint.pageCount) pages but plans \(blueprint.pagePlan.count)."))
            }
            let numbers = blueprint.pagePlan.map(\.pageNumber).sorted()
            if numbers != Array(1...max(numbers.count, 1)) && !numbers.isEmpty {
                issues.append(.init(severity: .error, code: "page_numbers_not_contiguous", recordID: blueprint.id,
                                    message: "Blueprint '\(blueprint.id)' page numbers are \(numbers), not 1…\(numbers.count)."))
            }
            if blueprint.titlePatterns.isEmpty {
                issues.append(.init(severity: .warning, code: "no_title_patterns", recordID: blueprint.id,
                                    message: "Blueprint '\(blueprint.id)' has no title patterns, so its titles must be composed generically."))
            }
        }
        return issues
    }
}
