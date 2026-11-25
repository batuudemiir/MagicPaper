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
        guard let package = p56Package(ideaID: ideaID, mode: mode, age: age, topicID: topicID, family: family),
              let mode, let age, let p56Mode = P56Mode(rawValue: mode.rawValue) else {
            return base.companionChoices(forIdeaID: ideaID, mode: mode, age: age, topicID: topicID, family: family)
        }
        return P56Support.companionIDs(age: age, mode: p56Mode, package: package).map { id in
            catalogChoice(id) ?? CompanionChoice(
                id: id, name: package.companions.first { $0.id == id }?.name ?? id, kind: "", personality: "")
        }
    }

    func companionDisplayLimit(forIdeaID ideaID: String?, age: Int?, mode: StoryMode?,
                               topicID: String?, family: FamilyCharacter?) -> Int {
        p56Package(ideaID: ideaID, mode: mode, age: age, topicID: topicID, family: family) == nil
            ? base.companionDisplayLimit(forIdeaID: ideaID, age: age, mode: mode, topicID: topicID, family: family)
            : 5
    }

    /// The P56 package when P56 would write this request with no companion
    /// chosen yet; nil sends the screen to the legacy list.
    private func p56Package(ideaID: String?, mode: StoryMode?, age: Int?,
                            topicID: String?, family: FamilyCharacter?) -> P56Package? {
        guard ideaID == nil, let mode, let age else { return nil }
        let decision = router.decide(StoryRuntimeRequest(
            age: age, mode: mode, companionID: nil, family: family,
            topicID: topicID, occasion: nil, safety: safety()))
        guard case .p56(let reference) = decision.route else { return nil }
        return router.package(for: reference)
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
