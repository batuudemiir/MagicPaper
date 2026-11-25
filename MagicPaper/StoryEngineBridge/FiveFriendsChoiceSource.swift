import Foundation
import StoryEngine

/// The creation flow's source while the five-friends pilot is on (B5, K-C).
///
/// Everything is the legacy source's answer except the companion list: when
/// the router would let P56 write this request, "Masalda kimler olsun?" offers
/// the five friends in canonical order, all of them (no three-card cut, no
/// symbol de-duplication: each has its own portrait). Any request P56 cannot
/// carry (Masal ailem, a topic, an idea card, another age, a safety policy
/// before C3) gets today's list, so the card the parent sees is the story
/// they get.
///
/// Names and lines come from the app catalog's record for the same id; P56's
/// own `personality` is an authoring note, not screen copy.
@MainActor
struct FiveFriendsChoiceSource: StoryChoiceSource {
    private let base: any StoryChoiceSource
    private let router: StoryRuntimeRouter
    private let safety: @MainActor () -> ContentSafety?
    private let catalogChoice: @MainActor (String) -> CompanionChoice?

    init(base: any StoryChoiceSource,
         router: StoryRuntimeRouter = .shared,
         safety: @escaping @MainActor () -> ContentSafety? = { OfflineStoryService.shared.currentSafety },
         catalogChoice: @escaping @MainActor (String) -> CompanionChoice? = { OfflineStoryService.shared.companionChoice(id: $0) }) {
        self.base = base
        self.router = router
        self.safety = safety
        self.catalogChoice = catalogChoice
    }

    // MARK: - The five friends

    func companionChoices(
        forIdeaID ideaID: String?, mode: StoryMode?, age: Int?,
        topicID: String?, family: FamilyCharacter?
    ) -> [CompanionChoice] {
        p56Choices(ideaID: ideaID, mode: mode, age: age, topicID: topicID, family: family)
            ?? base.companionChoices(forIdeaID: ideaID, mode: mode, age: age, topicID: topicID, family: family)
    }

    func companionDisplayLimit(forIdeaID ideaID: String?, age: Int?, mode: StoryMode?,
                               topicID: String?, family: FamilyCharacter?) -> Int {
        p56Choices(ideaID: ideaID, mode: mode, age: age, topicID: topicID, family: family) == nil
            ? base.companionDisplayLimit(forIdeaID: ideaID, age: age, mode: mode, topicID: topicID, family: family)
            : 5
    }

    /// The friends P56 can really write this request with, in canonical order;
    /// nil sends the screen to the legacy list. Each friend is asked with its
    /// own id, so a friend whose books the safety policy filters out entirely
    /// in this mode is not offered (`companionIDs` knows no safety).
    private func p56Choices(ideaID: String?, mode: StoryMode?, age: Int?,
                            topicID: String?, family: FamilyCharacter?) -> [CompanionChoice]? {
        guard ideaID == nil, let mode, let age, let p56Mode = P56Mode(rawValue: mode.rawValue) else { return nil }
        let policy = safety()
        func decision(_ companionID: String?) -> StoryRuntimeDecision {
            router.decide(StoryRuntimeRequest(age: age, mode: mode, companionID: companionID, family: family,
                                              topicID: topicID, occasion: nil, safety: policy))
        }
        guard case .p56(let reference) = decision(nil).route, let package = router.package(for: reference) else {
            return nil
        }
        let ids = P56Support.companionIDs(age: age, mode: p56Mode, package: package).filter {
            if case .p56 = decision($0).route { return true } else { return false }
        }
        guard !ids.isEmpty else { return nil }
        return ids.map { id in
            catalogChoice(id) ?? CompanionChoice(
                id: id, name: package.companions.first { $0.id == id }?.name ?? id, kind: "", personality: "")
        }
    }

    // MARK: - Forwarded

    func authoredBands() -> [AgeBand] { base.authoredBands() }
    func availableModes(forAge age: Int) -> [StoryMode] { base.availableModes(forAge: age) }
    func topicChoices(forAge age: Int, mode: StoryMode) -> [StoryTopicChoice] { base.topicChoices(forAge: age, mode: mode) }
    func occasionChoices(forAge age: Int, mode: StoryMode) -> [String] { base.occasionChoices(forAge: age, mode: mode) }
    func ideaChoices(forAge age: Int, mode: StoryMode) -> [StoryIdeaChoice] { base.ideaChoices(forAge: age, mode: mode) }
    func companionChoices(forIdeaID ideaID: String?, mode: StoryMode?, age: Int?) -> [CompanionChoice] {
        base.companionChoices(forIdeaID: ideaID, mode: mode, age: age)
    }
    func availableFamilyRelations(mode: StoryMode?, age: Int) -> [FamilyRelationKind] {
        base.availableFamilyRelations(mode: mode, age: age)
    }
    func familyAnimalKindChoices() -> [FamilyAnimalKindChoice] { base.familyAnimalKindChoices() }
    func interestChoices() -> [InterestChoice] { base.interestChoices() }
    func resolveMode(strategy: StorySelectionStrategy, requested: StoryMode?,
                     forAge age: Int, recent: [StoryMode]) throws -> StoryMode {
        try base.resolveMode(strategy: strategy, requested: requested, forAge: age, recent: recent)
    }
}
