import Foundation

/// P56 has its own causal vocabulary; U3 never masquerades as legacy need/care beats.
public enum P56Beat: String, Codable, Hashable, Sendable {
    case settled_room
    case ritual_chosen
    case friend_listens
    case child_names_sound
    case soft_smile
    case attention_released
    case awake_rest
    case closed_calm
    case comfort_need
    case friend_preference
    case child_prepares
    case soft_trial
    case child_yields_space
    case one_memory_selected
    case friend_receives_memory
    case child_limits_telling
    case soft_shared_memory
    case story_released
    case sound_noticed
    case first_guess
    case friend_one_observation
    case child_predicts
    case observe_contact
    case child_infers
    case recheck
    case closed_result
    case partial_shape
    case first_view
    case friend_second_view
    case child_repositions
    case compare_views
    case child_combines
    case whole_seen
    case drop_noticed
    case first_observation
    case friend_waits
    case child_observation_plan
    case visible_change
    case child_compares
    case drop_falls
    case safe_goal
    case approach
    case friend_support
    case child_step_choice
    case first_step
    case child_crosses
    case goal_reached
    case closed_return
    case two_piece_goal
    case friend_contribution
    case child_orders
    case first_piece
    case child_completes
    case route_confirmed
    case personal_loss
    case last_seen_recalled
    case child_selects_route
    case retrace
    case child_recognizes
    case object_recovered
}

public enum P56Fact: String, Codable, Hashable, Sendable {
    case settled, ritualChosen, friendListened, soundNamed, calmAcknowledged, attentionReleased
    case comfortNeedKnown, preferenceKnown, comfortPrepared, comfortTried, spaceYielded
    case waitingSupportOffered
    case firstObservation, tentativeIdea, supportingObservation, childPlan, decisiveObservation, childSolution, verified
    case safeGoal, approachMade, friendContributionOffered, childChoice, firstStep, childCrossed, goalReached
    case piecesGoal, piecesOrdered, firstPiecePlaced, piecesCompleted, routeConfirmed
    case memorySelected, memoryShared, tellingLimited, memoryAcknowledged, memoryReleased, awakeRest, closed
    case lossKnown, lastSeenRemembered, routeChosen, rootRecognized, clothRecovered, clothPocketed
}

public struct P56CausalEvent: Codable, Hashable, Sendable {
    public let establishes: P56Fact
    public let requires: [P56Fact]
    public let actorIDs: [String]
    public let evidenceSourceID: String
    public let evidenceText: String
    public let evidence: P56CausalEvidence
    public let authoredEvidence: P56CausalEvidence
}

public struct P56NarrativeState: Codable, Hashable, Sendable {
    public let completed: [P56Beat]
    public let facts: [P56Fact]
    public let childOwnsResolution: Bool
    public let actualSleep: Bool
}

public struct P56Transition: Codable, Hashable, Sendable {
    public let beat: P56Beat
    public let before: P56NarrativeState
    public let after: P56NarrativeState
    public let actorIDs: [String]
    public let evidenceSourceID: String
    public let evidenceSHA256: String
    public let events: [P56CausalEvent]
}

public enum P56StructureValidator {
    /// Canonical order is code, independent of authored stateBefore/stateAfter assertions.
    static let sequences: [String: [P56Beat]] = [
        "U1": [.settled_room, .ritual_chosen, .friend_listens, .child_names_sound, .soft_smile, .attention_released, .awake_rest, .closed_calm],
        "U2": [.settled_room, .comfort_need, .friend_preference, .child_prepares, .soft_trial, .child_yields_space, .awake_rest, .closed_calm],
        "U3": [.settled_room, .one_memory_selected, .friend_receives_memory, .child_limits_telling, .soft_shared_memory, .story_released, .awake_rest, .closed_calm],
        "L1": [.sound_noticed, .first_guess, .friend_one_observation, .child_predicts, .observe_contact, .child_infers, .recheck, .closed_result],
        "L2": [.partial_shape, .first_view, .friend_second_view, .child_repositions, .compare_views, .child_combines, .whole_seen, .closed_result],
        "L3": [.drop_noticed, .first_observation, .friend_waits, .child_observation_plan, .visible_change, .child_compares, .drop_falls, .closed_result],
        "A1": [.safe_goal, .approach, .friend_support, .child_step_choice, .first_step, .child_crosses, .goal_reached, .closed_return],
        "A2": [.two_piece_goal, .approach, .friend_contribution, .child_orders, .first_piece, .child_completes, .route_confirmed, .closed_return],
        "A3": [.personal_loss, .last_seen_recalled, .friend_waits, .child_selects_route, .retrace, .child_recognizes, .object_recovered, .closed_return]
    ]
    static let childRoles: Set<P56Beat> = [
        .ritual_chosen, .child_names_sound, .attention_released, .child_prepares, .child_yields_space,
        .one_memory_selected, .child_limits_telling, .story_released, .child_predicts, .observe_contact,
        .child_infers, .recheck, .child_repositions, .compare_views, .child_combines, .child_observation_plan,
        .visible_change, .child_compares, .child_step_choice, .first_step, .child_crosses, .child_orders,
        .first_piece, .child_completes, .last_seen_recalled, .child_selects_route, .retrace,
        .child_recognizes, .object_recovered]
    static let friendRoles: Set<P56Beat> = [.friend_listens, .friend_preference, .friend_receives_memory,
        .friend_one_observation, .friend_second_view, .friend_waits, .friend_support, .friend_contribution]
    static let resolutions: Set<P56Beat> = [.attention_released, .child_yields_space, .story_released,
        .child_infers, .child_combines, .child_compares, .child_crosses, .child_completes, .object_recovered]

    public static func compile(_ book: P56Book) throws -> [P56Transition] {
        guard let expected = sequences[book.structureID], book.pages.count == 8 else {
            throw P56Error.invalidStructure("structure-or-page-count")
        }
        var state = P56NarrativeState(completed: [], facts: [], childOwnsResolution: false, actualSleep: false)
        var traces: [P56Transition] = []
        for (index, page) in book.pages.enumerated() {
            guard page.number == index + 1, page.beat == expected[index],
                  state.completed == Array(expected.prefix(index)) else {
                throw P56Error.invalidStructure("precondition-or-order")
            }
            let actors = childRoles.contains(page.beat) ? ["child"] :
                (friendRoles.contains(page.beat) ? [book.companionID] : ["child", book.companionID])
            guard page.actorIDs == actors else { throw P56Error.invalidStructure("actor-owns-action") }
            try validateEvidence(page, companionID: book.companionID)
            try validateCausalEvidence(page, book: book)
            let events = try causalEvents(page, book: book, state: state)
            let facts = state.facts + events.map(\.establishes)
            let next = P56NarrativeState(completed: state.completed + [page.beat], facts: facts,
                childOwnsResolution: state.childOwnsResolution || resolutions.contains(page.beat), actualSleep: false)
            traces.append(P56Transition(beat: page.beat, before: state, after: next, actorIDs: actors,
                evidenceSourceID: page.parentSourceID, evidenceSHA256: page.parentSHA256, events: events))
            state = next
        }
        guard state.childOwnsResolution else { throw P56Error.invalidStructure("child-resolution-missing") }
        return traces
    }

    // These facts are deliberately independent from legacy StoryBeat/state vocabulary.
    private static let factPaths: [String: [P56Fact]] = [
        "U1": [.settled, .ritualChosen, .friendListened, .soundNamed, .calmAcknowledged, .attentionReleased, .awakeRest, .closed],
        "U2": [.settled, .comfortNeedKnown, .preferenceKnown, .comfortPrepared, .comfortTried, .spaceYielded, .awakeRest, .closed],
        "U3": [.settled, .memorySelected, .memoryShared, .tellingLimited, .memoryAcknowledged, .memoryReleased, .awakeRest, .closed],
        "L1": [.firstObservation, .tentativeIdea, .supportingObservation, .childPlan, .decisiveObservation, .childSolution, .verified, .closed],
        "L2": [.firstObservation, .tentativeIdea, .supportingObservation, .childPlan, .decisiveObservation, .childSolution, .verified, .closed],
        "L3": [.firstObservation, .tentativeIdea, .waitingSupportOffered, .childPlan, .decisiveObservation, .childSolution, .verified, .closed],
        "A1": [.safeGoal, .approachMade, .friendContributionOffered, .childChoice, .firstStep, .childCrossed, .goalReached, .closed],
        "A2": [.piecesGoal, .approachMade, .friendContributionOffered, .piecesOrdered, .firstPiecePlaced, .piecesCompleted, .routeConfirmed, .closed],
        "A3": [.lossKnown, .lastSeenRemembered, .friendListened, .routeChosen, .rootRecognized, .clothRecovered, .clothPocketed, .closed]
    ]

    private static func causalEvents(_ page: P56TemplatePage, book: P56Book,
                                     state: P56NarrativeState) throws -> [P56CausalEvent] {
        guard let path = factPaths[book.structureID], path.indices.contains(page.number - 1) else {
            throw P56Error.invalidStructure("unknown-fact-path")
        }
        let fact = path[page.number - 1]
        let required = page.number == 1 ? [] : Array(path.prefix(page.number - 1))
        guard Set(required).isSubset(of: Set(state.facts)) else { throw P56Error.invalidStructure("missing-causal-evidence") }
        try validateTemporalFacts(page, book: book, fact: fact)
        // This is a page-level evidence event, not independently approved atomic annotation.
        let actors = [page.causalEvidence.actorID]
        return [P56CausalEvent(establishes: fact, requires: required, actorIDs: actors,
            evidenceSourceID: page.parentSourceID, evidenceText: page.causalEvidence.quote, evidence: page.causalEvidence, authoredEvidence: page.causalEvidence)]
    }

    private static func validateCausalEvidence(_ page: P56TemplatePage, book: P56Book) throws {
        let evidence = page.causalEvidence
        let companionRole = (friendRoles.contains(page.beat) && page.beat != .friend_receives_memory)
            || page.beat == .soft_trial || (book.structureID == "U1" && page.beat == .awake_rest)
        let expectedActor = companionRole ? book.companionID : "child"
        let expectedName = companionRole ? companionNames[book.companionID] : "Deniz"
        let attribution = book.pages.first { $0.parentSourceID == evidence.attributionSourceID }
        guard evidence.bookID == book.id, evidence.pageNumber == page.number,
              evidence.actorID == expectedActor, evidence.attributionQuote == expectedName,
              attribution?.parentText.contains(evidence.attributionQuote) == true,
              evidence.parentSourceID == page.parentSourceID, !evidence.quote.isEmpty,
              page.parentText.contains(evidence.quote),
              P56Digest.sha256(Data(evidence.quote.utf8)) == evidence.quoteSHA256 else {
            throw P56Error.invalidStructure("causal-actor-or-source-span")
        }
        if evidence.kind == .observedAbsence {
            guard book.structureID == "L1", book.companionID == "companion_city_cat_001",
                  page.beat == .friend_one_observation,
                  evidence.quote == "\"Yaprak değmeden önce ses duymadım,\" dedi." else {
                throw P56Error.invalidStructure("absence-observation")
            }
        }
    }

    private static let companionNames = ["companion_fox_pilot_001": "Tarçın",
        "companion_hedgehog_pilot_001": "Kestane", "companion_owl_pilot_001": "Yıldız",
        "companion_city_cat_001": "Simit", "companion_bear_001": "Böğürtlen"]

    private static func validateTemporalFacts(_ page: P56TemplatePage, book: P56Book, fact: P56Fact) throws {
        let subjects = page.semantics["subjects"]?.arrayValue ?? []
        if book.structureID == "U3" {
            let memory = subjects.filter { $0["subjectID"] == .string(book.discoveryID) }
            guard memory.allSatisfy({ $0["presence"] == .string("remembered") }),
                  (page.number == 1 || page.number == 8) || !memory.isEmpty else { throw P56Error.invalidStructure("memory-became-room-object") }
        }
        if book.structureID == "A3" {
            let cloth = subjects.first { $0["subjectID"] == .string(book.discoveryID) }
            if page.number < 6 {
                guard cloth?["presence"] == .string("intended") else { throw P56Error.invalidStructure("retrieval-before-recognition") }
            }
            if fact == .rootRecognized {
                let root = subjects.first { $0["subjectID"] == .string("pilot56_object_forked_root_v1") }
                guard root?["presence"] == .string("present") else { throw P56Error.invalidStructure("recognition-missing-visible-root") }
            }
            if fact == .clothRecovered || fact == .clothPocketed {
                let expected = fact == .clothRecovered ? "cloth-in-child-hand" : "cloth-in-child-pocket"
                guard cloth?["presence"] == .string("present"),
                      cloth?["states"]?.arrayValue?.contains(.string(expected)) == true else {
                    throw P56Error.invalidStructure("retrieval-evidence")
                }
            }
        }
    }

    private static func validateEvidence(_ page: P56TemplatePage, companionID: String) throws {
        let subjects = page.semantics["subjects"]?.arrayValue ?? []
        let present = subjects.filter { $0["presence"] == .string("present") }
        let presentIDs = Set(present.compactMap { $0["subjectID"]?.stringValue })
        guard presentIDs.contains("pilot56_synthetic_child_deniz"), presentIDs.contains(companionID),
              page.artHandoff["assetRuleApproval"] == .bool(false),
              page.artHandoff["runtimeArt"] == .null else {
            throw P56Error.invalidStructure("presence-or-art")
        }
        let actions = page.semantics["actions"]?.arrayValue ?? []
        guard !actions.isEmpty else { throw P56Error.invalidStructure("missing-source-evidence") }
        for action in actions {
            guard action["evidenceSourceID"] == .string(page.parentSourceID),
                  action["evidenceText"] == .string(page.parentText),
                  action["atomicActionMappingApproved"] == .bool(false),
                  let actors = action["actorSubjectIDs"]?.arrayValue,
                  !actors.isEmpty, actors.allSatisfy({ $0.stringValue.map(presentIDs.contains) ?? false }) else {
                throw P56Error.invalidStructure("contextual-evidence")
            }
        }
        for subject in subjects {
            let states = subject["states"]?.arrayValue ?? []
            guard !states.contains(.string("asleep")), !states.contains(.string("sleeping")) else {
                throw P56Error.invalidStructure("unsupported-actual-sleep")
            }
        }
    }
}
