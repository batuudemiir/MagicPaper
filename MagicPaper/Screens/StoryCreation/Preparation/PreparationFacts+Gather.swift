import Foundation

extension PreparationFacts {
    /// What the preparation screen shows about a story just built: the
    /// companion from the catalog, the story's place on the child's shelf,
    /// bedtime from the parent's settings. Nothing new is stored.
    @MainActor
    static func gather(story: Story, profile: UserProfile, family: FamilyCharacter?,
                       isFirstRun: Bool) -> PreparationFacts {
        let service = OfflineStoryService.shared
        let companionID = story.origin?.companionID ?? ""
        let companion = service.companionName(id: companionID).map {
            Companion(name: $0, kind: service.companionKind(id: companionID) ?? "")
        }
        // Künyedeki "12. masal" ile aynı sayı (`StoryColophon`).
        let ordinal = StoryColophon.ordinal(of: story, among: StoryGenerationManager.shared.stories)
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
