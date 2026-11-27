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

    /// The five in canonical order (`P56Support.companionIDs`), shown while the
    /// payload is still being read so the screen never waits for it.
    static let provisionalIDs = ["companion_fox_pilot_001", "companion_hedgehog_pilot_001",
                                 "companion_owl_pilot_001", "companion_city_cat_001", "companion_bear_001"]

    var isReady: Bool { router.isReady }
    func waitUntilReady() async { await router.waitUntilReady() }

    /// The friends P56 can really write this request with, in canonical order;
    /// nil sends the screen to the legacy list. Each friend is asked with its
    /// own id, so a friend whose books the safety policy filters out entirely
    /// in this mode is not offered (`companionIDs` knows no safety).
    ///
    /// Never waits (kod düzeltmeleri, 26 Kasım 2026): while the payload is
    /// still being read, a request whose shape P56 carries gets the five at
    /// once; the screen asks again when the source is ready, and a choice
    /// made before that waits for the final list (`isReady`).
    private func p56Choices(ideaID: String?, mode: StoryMode?, age: Int?,
                            topicID: String?, family: FamilyCharacter?) -> [CompanionChoice]? {
        guard ideaID == nil, let mode, let age, let p56Mode = P56Mode(rawValue: mode.rawValue) else { return nil }
        let policy = safety()
        func decision(_ companionID: String?) -> StoryRuntimeDecision? {
            router.decideIfReady(StoryRuntimeRequest(age: age, mode: mode, companionID: companionID, family: family,
                                                     topicID: topicID, occasion: nil, safety: policy))
        }
        guard let overall = decision(nil) else {
            // Henüz okunuyor: biçimi P56'ya uyan istek beşliyi hemen görür.
            guard family == nil, topicID == nil, (5...6).contains(age) else { return nil }
            return Self.provisionalIDs.map { id in
                catalogChoice(id) ?? CompanionChoice(id: id, name: id, kind: "", personality: "")
            }
        }
        guard case .p56(let reference) = overall.route, let package = router.package(for: reference) else {
            return nil
        }
        let ids = P56Support.companionIDs(age: age, mode: p56Mode, package: package).filter {
            if case .p56 = decision($0)?.route { return true } else { return false }
        }
        guard !ids.isEmpty else { return nil }
        return ids.map { id in
            catalogChoice(id) ?? CompanionChoice(
                id: id, name: package.companions.first { $0.id == id }?.name ?? id, kind: "", personality: "")
        }
    }

    // MARK: - Okul öncesi: önce arkadaş (26 Kasım 2026)

    /// Mod bilinmeden kurulan liste: P56'nın en az bir modda gerçekten
    /// yazabildiği arkadaşlar. Her mod ayrı sorulur, birleşim alınır.
    func pilotFriendChoices(age: Int) -> [CompanionChoice] {
        var seen = Set<String>()
        return base.availableModes(forAge: age).flatMap { mode in
            p56Choices(ideaID: nil, mode: mode, age: age, topicID: nil, family: nil) ?? []
        }.filter { seen.insert($0.id).inserted }
    }

    /// Bu arkadaşla (`nil`: Sürpriz, herhangi biriyle) P56'nın yazabildiği modlar.
    func pilotModes(forCompanionID companionID: String?, age: Int) -> [StoryMode] {
        base.availableModes(forAge: age).filter { mode in
            guard let ids = p56Choices(ideaID: nil, mode: mode, age: age, topicID: nil, family: nil)?.map(\.id)
            else { return false }
            guard let companionID else { return !ids.isEmpty }
            return ids.contains(companionID)
        }
    }

    // MARK: - Forwarded

    func legacyWritableCompanionIDs(mode: StoryMode, age: Int, topicID: String?) -> [String] {
        base.legacyWritableCompanionIDs(mode: mode, age: age, topicID: topicID)
    }

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
