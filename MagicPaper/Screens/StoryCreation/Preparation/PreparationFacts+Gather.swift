import Foundation

extension PreparationFacts {
    /// What the preparation screen shows about a story just built: the
    /// companion from the catalog, the child's story count from the library,
    /// bedtime from the parent's settings. Nothing new is stored.
    @MainActor
    static func gather(story: Story, profile: UserProfile, family: FamilyCharacter?,
                       isFirstRun: Bool) -> PreparationFacts {
        let service = OfflineStoryService.shared
        let companionID = story.origin?.companionID ?? ""
        let companion = service.companionName(id: companionID).map {
            Companion(name: $0, kind: service.companionKind(id: companionID) ?? "")
        }
        let ordinal = StoryGenerationManager.shared.stories.filter { $0.belongs(to: profile) }.count
        return PreparationFacts(
            story: story,
            childName: profile.name,
            companion: companion,
            familyName: family?.name,
            ordinal: ordinal,
            isFirstRun: isFirstRun,
            isBedtime: MPBedtime.isBedtime(settings: MPSettingsStore.shared)
        )
    }
}
