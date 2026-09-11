import Foundation
import CharacterEngine
import VisualSystem

/// References, counts and completeness. The checks that must pass before any
/// judgement about quality is worth making.
public struct StructuralValidator: DeterministicValidator {
    public let id = ValidatorID.structural
    public init() {}

    public func validate(_ context: ValidationContext) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        let story = context.story
        let sceneIDs = Set(story.scenes.map(\.id))
        let pages = context.orderedPages

        if pages.isEmpty {
            issues.append(issue("no_pages", .error, .story, "The story has no pages."))
            return issues
        }

        if story.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(issue("missing_title", .error, .story, "The story has no title."))
        }
        if story.characters.protagonist == nil {
            issues.append(issue("no_protagonist", .error, .story, "The story has no protagonist."))
        }

        if pages.map(\.index) != Array(0..<pages.count) {
            issues.append(issue("page_indices_broken", .error, .story, "Page indices are not contiguous from zero."))
        }

        let supported = context.template.template.constraints.supportedPageCounts
        if !supported.contains(pages.count) {
            issues.append(issue(
                "page_count_out_of_range", .error, .story,
                "\(pages.count) pages is outside the template's \(supported.lowerBound)–\(supported.upperBound)."
            ))
        }

        for page in pages {
            if !sceneIDs.contains(page.sceneID) {
                issues.append(issue("page_scene_missing", .error, .page(page.id), "Page \(page.index + 1) points at a scene that does not exist."))
            }
            if !page.hasText {
                issues.append(issue("page_empty", .error, .page(page.id), "Page \(page.index + 1) has no text."))
            }
            guard page.requiresImage else { continue }

            guard let assetID = page.visualAssetID else {
                issues.append(issue("page_no_image", .error, .page(page.id), "Page \(page.index + 1) needs an illustration but has none assigned."))
                continue
            }
            guard let asset = story.visualAsset(id: assetID) else {
                issues.append(issue("page_image_missing", .error, .page(page.id), "Page \(page.index + 1) points at an asset that does not exist."))
                continue
            }
            if !asset.isReady {
                issues.append(issue("image_not_ready", .error, .visualAsset(asset.id), "The illustration for page \(page.index + 1) is \(asset.state.rawValue)."))
            }
        }

        let usedScenes = Set(pages.map(\.sceneID))
        for scene in story.scenes where !usedScenes.contains(scene.id) {
            issues.append(issue("orphan_scene", .warning, .scene(scene.id), "Scene \(scene.index + 1) is not used by any page."))
        }

        return issues
    }
}

/// Catches the book repeating itself — the classic failure of writing pages
/// independently, and worth checking even though we no longer do that.
public struct RepetitionValidator: DeterministicValidator {
    public let id = ValidatorID.repetition
    public init() {}

    public func validate(_ context: ValidationContext) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        let rules = context.rules
        let pages = context.orderedPages
        guard pages.count > 1 else { return [] }

        var seenNGrams: [String: Int] = [:]
        var repeats: [String: Int] = [:]
        for page in pages {
            for gram in Set(TextMetrics.nGrams(page.text, size: rules.repetitionNGramSize)) {
                seenNGrams[gram, default: 0] += 1
            }
        }
        for (gram, count) in seenNGrams where count > 1 {
            repeats[gram] = count
        }
        if repeats.count > rules.maximumRepeatedNGrams {
            let worst = repeats.sorted { ($0.value, $0.key) > ($1.value, $1.key) }.prefix(3)
            issues.append(issue(
                "repeated_phrases", .warning, .story,
                "Phrases repeat across pages: \(worst.map { "\"\($0.key)\" ×\($0.value)" }.joined(separator: ", "))."
            ))
        }

        var openers: [String: [Int]] = [:]
        for page in pages {
            guard let sentence = TextMetrics.sentences(page.text).first,
                  let opener = TextMetrics.firstWord(ofSentence: sentence) else { continue }
            openers[opener, default: []].append(page.index)
        }
        for (opener, indices) in openers where indices.count > rules.maximumSharedSentenceOpeners {
            issues.append(issue(
                "repeated_openers", .warning, .story,
                "\(indices.count) pages open with \"\(opener)\"."
            ))
        }

        return issues
    }
}

/// The text half of the non-invention rule.
///
/// The prompt tells the model not to describe appearance; this checks that it
/// obeyed. Any appearance claim in a page, an outline beat or a compiled image
/// prompt that the character's identity does not authorize is an error, and
/// errors block publication.
public struct CharacterConsistencyValidator: DeterministicValidator {
    public let id = ValidatorID.characterConsistency
    public init() {}

    public func validate(_ context: ValidationContext) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        let story = context.story
        guard let protagonist = story.characters.protagonist else { return [] }

        for page in context.orderedPages {
            for violation in context.lexicon.violations(in: page.text, authorizedBy: protagonist.identity) {
                issues.append(issue(
                    "invented_appearance", .error, .page(page.id),
                    "Page \(page.index + 1) claims \"\(violation.phrase)\" (\(violation.category.rawValue)), "
                        + "which \(protagonist.displayName)'s character does not say."
                ))
            }

            if context.rules.requireProtagonistMentionPerPage, page.hasText {
                let normalizedText = DescriptorNormalization.normalize(page.text)
                let normalizedName = DescriptorNormalization.normalize(protagonist.displayName)
                let pronouns = protagonist.identity.pronouns
                let mentionsPronoun = [pronouns.subject, pronouns.object, pronouns.possessive]
                    .contains { DescriptorLexicon.contains(phrase: DescriptorNormalization.normalize($0), in: normalizedText, allowingSuffix: context.lexicon.allowsSuffixAttachment) }

                if !normalizedText.contains(normalizedName) && !mentionsPronoun {
                    issues.append(issue(
                        "protagonist_absent", .warning, .page(page.id),
                        "Page \(page.index + 1) never mentions \(protagonist.displayName)."
                    ))
                }
            }
        }

        for scene in story.scenes {
            for asset in scene.visualAssets {
                guard let constraints = asset.promptSnapshot else { continue }
                let prompt = (constraints.identityClauses + constraints.sceneClauses).joined(separator: " ")
                for violation in context.lexicon.violations(in: prompt, authorizedBy: protagonist.identity) {
                    issues.append(issue(
                        "invented_appearance_in_prompt", .error, .visualAsset(asset.id),
                        "An illustration prompt claims \"\(violation.phrase)\", which the character does not say."
                    ))
                }
            }
        }

        return issues
    }
}

/// Length, sentence complexity and safe vocabulary for the reader's age.
public struct AgeAppropriatenessValidator: DeterministicValidator {
    public let id = ValidatorID.ageAppropriateness
    public init() {}

    public func validate(_ context: ValidationContext) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []

        guard let band = context.ageBand else {
            issues.append(issue(
                "no_age_band", .warning, .story,
                "The template has no guidance for age \(context.request.ageYears)."
            ))
            return issues
        }

        for page in context.orderedPages {
            let words = page.wordCount
            // The page's own layout budget and the age band both apply; the
            // narrower of the two is what the reader actually needs.
            let minimum = max(band.minimumWordsPerPage, page.minimumWords)
            let maximum = min(band.maximumWordsPerPage, page.maximumWords)

            if words < minimum {
                issues.append(issue(
                    "page_too_short", .warning, .page(page.id),
                    "Page \(page.index + 1) has \(words) words; \(minimum) is the floor here."
                ))
            }
            if words > maximum {
                issues.append(issue(
                    "page_too_long", .warning, .page(page.id),
                    "Page \(page.index + 1) has \(words) words; \(maximum) is the ceiling here."
                ))
            }

            let longest = TextMetrics.longestSentenceWordCount(page.text)
            if longest > band.maximumSentenceWords {
                issues.append(issue(
                    "sentence_too_long", .warning, .page(page.id),
                    "Page \(page.index + 1) has a \(longest)-word sentence; \(band.maximumSentenceWords) is the ceiling for age \(context.request.ageYears)."
                ))
            }

            let normalized = DescriptorNormalization.normalize(page.text)
            for phrase in context.rules.bannedPhrases {
                let needle = DescriptorNormalization.normalize(phrase)
                guard DescriptorLexicon.contains(phrase: needle, in: normalized, allowingSuffix: context.lexicon.allowsSuffixAttachment) else { continue }
                issues.append(issue(
                    "banned_phrase", .error, .page(page.id),
                    "Page \(page.index + 1) contains \"\(phrase)\"."
                ))
            }

            if let protagonist = context.story.characters.protagonist {
                for excluded in protagonist.identity.doNotDepict {
                    let needle = DescriptorNormalization.normalize(excluded)
                    guard DescriptorLexicon.contains(phrase: needle, in: normalized, allowingSuffix: context.lexicon.allowsSuffixAttachment) else { continue }
                    issues.append(issue(
                        "do_not_depict", .error, .page(page.id),
                        "Page \(page.index + 1) mentions \"\(excluded)\", which this character must never be shown with."
                    ))
                }
            }
        }

        return issues
    }
}

/// Checks the instructions the image model was actually given.
///
/// The design system's forbidden clauses only protect a book if they survive
/// into every request; this is what notices when one does not.
public struct VisualSafetyValidator: DeterministicValidator {
    public let id = ValidatorID.visualSafety
    public init() {}

    public func validate(_ context: ValidationContext) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        let forbidden = context.template.visualStyle.illustrationStyle.forbiddenClauses

        for scene in context.story.scenes {
            for asset in scene.visualAssets {
                guard let constraints = asset.promptSnapshot else {
                    if !scene.pageIDs.isEmpty {
                        issues.append(issue(
                            "no_prompt_snapshot", .warning, .visualAsset(asset.id),
                            "An illustration has no record of what it was drawn from."
                        ))
                    }
                    continue
                }

                let negatives = Set(constraints.negativeClauses.map(DescriptorNormalization.normalize))
                let missing = forbidden.filter { !negatives.contains(DescriptorNormalization.normalize($0)) }
                if !missing.isEmpty {
                    issues.append(issue(
                        "missing_negative_clauses", .error, .visualAsset(asset.id),
                        "The illustration request omits required exclusions: \(missing.joined(separator: ", "))."
                    ))
                }

                // A forbidden clause that leaked into the positive list.
                //
                // Matched whole-clause, not as a substring: the composition
                // rule legitimately says "keep the lower area uncluttered for
                // text", and a word-level match would flag every page in the
                // book for the forbidden clause "text".
                let positiveClauses = Set(
                    (constraints.styleClauses + constraints.compositionClauses + constraints.paletteClauses
                        + constraints.sceneClauses + constraints.identityClauses)
                        .map(DescriptorNormalization.normalize)
                )
                for clause in forbidden where positiveClauses.contains(DescriptorNormalization.normalize(clause)) {
                    issues.append(issue(
                        "forbidden_clause_requested", .error, .visualAsset(asset.id),
                        "The illustration request asks for \"\(clause)\", which the style forbids."
                    ))
                }

                for excluded in context.story.characters.flatMap(\.identity.doNotDepict) {
                    let needle = DescriptorNormalization.normalize(excluded)
                    guard negatives.contains(needle) else {
                        issues.append(issue(
                            "do_not_depict_not_excluded", .error, .visualAsset(asset.id),
                            "\"\(excluded)\" is not excluded from the illustration request."
                        ))
                        continue
                    }
                }
            }
        }

        return issues
    }
}

// MARK: - Shared helper

/// Builds an issue without a validator id; `StoryValidator` stamps the id of
/// whichever validator produced it.
func issue(_ code: String, _ severity: ValidationSeverity, _ scope: ValidationScope, _ message: String) -> ValidationIssue {
    ValidationIssue(validatorID: "", code: code, severity: severity, scope: scope, message: message)
}
