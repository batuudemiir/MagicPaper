import SwiftUI
import StoryEngine

/// The story creation experience: an intent, then a story.
///
/// Replaces the four-step wizard, which asked for a child, a type, a direction,
/// a world, a companion, and finally whether the story should be illustrated —
/// six decisions that made the product feel like a form.
///
/// The one required decision is the **mode** — Uyku öncesi, Yeni şeyler
/// öğrenelim, Maceraya çıkalım — or "Bana sürpriz yap", which lets MagicPaper
/// pick the mode. Then "Masalda kimler olsun?". Idea cards sit behind a flag
/// (`StoryIdeaStepAccess`, off in every build); when they are on, a surprise
/// still skips them, because the parent asked us to decide.
///
/// A mode chosen on the home screen opens the flow at its second step: the
/// parent has already made the first decision there. "Back" then returns to
/// the modes, so it is never a dead end. The decisions themselves live in
/// `StoryCreationSteps`.
///
/// The child is not asked for: the app already has a current profile, and
/// `MainContentView` will not reach this screen without one.
struct StoryCreationFlow: View {

    /// Where the flow is. Linear on purpose — one decision per screen, which is
    /// also what makes it usable by a child later (§27).
    private enum Phase: Equatable {
        case mode
        case idea(StoryMode)
        case companion
        case preparing
        case cover(Story)
        /// Okuyucu akışın *içinde* açılır.
        ///
        /// Eskiden kapak `app.readerStory`'yi kurup kendi tam ekran sunumunu
        /// kapatıyordu, `ContentView` de ikinci bir tam ekran sunum açıyordu.
        /// Üst üste geçen iki tam ekran sunum, içlerinde ne animasyonlanırsa
        /// animasyonlansın, kitabın açılması gibi hissettirilemez. Aynı görünüm
        /// ağacında olunca kâğıt kesintisiz kalabiliyor (§13).
        case reading(Story)
        case failed
    }

    @EnvironmentObject private var app: MPAppState
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared

    @State private var phase: Phase
    /// Always one of the three modes once past step 1 — a surprise is resolved
    /// the moment it is chosen, so the companion step can already fit it.
    @State private var chosenMode: StoryMode?
    @State private var strategy: StorySelectionStrategy = .direct
    /// Whether step 2 was actually shown, so "back" from the companion step
    /// returns to where the parent really was.
    @State private var ideaStepShown = false
    /// Nil means "Bana bırak" or a surprise. Stable ids, never display text.
    @State private var chosenIdeaID: String?
    @State private var chosenCompanionID: String?
    /// Masal ailem (FAZ 11). Chosen on the companion step, optional, one at
    /// most. A surprise picks the mode, never the cast: this survives it.
    @State private var chosenFamilyID: UUID?
    @State private var familyCharacters: [FamilyCharacter] = []
    @State private var showsFamilyEditor = false
    /// Relations the chosen mode can carry for this child, computed once per
    /// mode rather than on every redraw: it walks every blueprint.
    @State private var familyRelations: Set<FamilyRelationKind> = []

    private var profile: UserProfile? { profileManager.currentProfile }

    /// - Parameter preset: a mode already chosen on the home screen.
    init(preset: StoryMode? = nil) {
        let age = ProfileManager.shared.currentProfile?.age ?? AgeBandResolver.mvp.upperBound
        let available = StoryChoiceSources.current.availableModes(forAge: age)
        switch StoryCreationSteps.openingPhase(preset: preset, available: available) {
        case .mode:
            _phase = State(initialValue: .mode)
            _chosenMode = State(initialValue: nil)
        case .companion(let mode):
            _phase = State(initialValue: .companion)
            _chosenMode = State(initialValue: mode)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if showsHeader { header }
            content
        }
        .mpScreenBackground()
        .animation(MP.M.gated(MP.M.page), value: phase)
        .overlay {
            if showsFamilyEditor, let profile {
                FamilyCharacterEditor(
                    childID: profile.id,
                    childName: profile.name,
                    source: source,
                    onClose: { showsFamilyEditor = false },
                    onSaved: { character in
                        reloadFamily()
                        // Just made for this story, so it comes along —
                        // unless this mode cannot carry its relation.
                        if familyRelations.contains(character.relation.kind) {
                            chosenFamilyID = character.id
                        }
                        showsFamilyEditor = false
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(MP.M.gated(MP.M.easeOut), value: showsFamilyEditor)
        .onAppear {
            reloadFamily()
            refreshFamilyRelations()
        }
        .onChange(of: chosenMode) { _, _ in refreshFamilyRelations() }
    }

    /// A mode change can make the chosen character's relation unavailable.
    /// The selection is cleared then, visibly (the chip is no longer
    /// selected), rather than kept and dropped silently at "Başla".
    private func refreshFamilyRelations() {
        familyRelations = Set(source.availableFamilyRelations(mode: chosenMode, age: age))
        if let character = familyCharacters.first(where: { $0.id == chosenFamilyID }),
           !familyRelations.contains(character.relation.kind) {
            chosenFamilyID = nil
        }
    }

    private func reloadFamily() {
        familyCharacters = profile.map { FamilyCharacterStore().characters(for: $0.id) } ?? []
        if let id = chosenFamilyID, !familyCharacters.contains(where: { $0.id == id }) {
            chosenFamilyID = nil
        }
    }

    /// Okuyucu açıkken akışın kendi başlık çubuğu yok: sayfa baştan başa kâğıt.
    private var showsHeader: Bool {
        if case .reading = phase { return false }
        return true
    }

    // MARK: - Chrome

    private var header: some View {
        HStack {
            MPIconButton(
                symbol: showsBack ? "chevron.left" : "xmark",
                label: showsBack ? "Geri" : "Kapat",
                action: goBack
            )
            Spacer(minLength: 0)
            if let step = stepIndex {
                MPStepDots(total: stepLabels.count, current: step, labels: stepLabels)
            }
            Spacer(minLength: 0)
            Color.clear.frame(width: 44, height: 44)
        }
        .mpGutter()
        .padding(.top, MP.S.x1)
    }

    private var showsBack: Bool {
        switch phase {
        case .idea, .companion: return true
        default: return false
        }
    }

    private var stepLabels: [String] { StoryCreationSteps.stepLabels(ideaStep: ideaStepShown) }

    private var stepIndex: Int? {
        switch phase {
        case .mode: return 0
        case .idea: return 1
        case .companion: return stepLabels.count - 1
        default: return nil
        }
    }

    private func goBack() {
        switch phase {
        case .companion:
            chosenCompanionID = nil
            if ideaStepShown, let mode = chosenMode {
                phase = .idea(mode)
            } else {
                resetToModes()
            }
        case .idea:
            resetToModes()
        default:
            dismiss()
        }
    }

    private func resetToModes() {
        chosenMode = nil
        chosenIdeaID = nil
        strategy = .direct
        ideaStepShown = false
        phase = .mode
    }

    // MARK: - Phases

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .mode:
            StoryModeStep(
                modes: source.availableModes(forAge: age),
                onChoose: chooseMode,
                onSurprise: surprise
            )
        case .idea(let mode):
            StoryIdeaStep(mode: mode, ideas: source.ideaChoices(forAge: age, mode: mode)) { ideaID in
                chosenIdeaID = ideaID
                phase = .companion
            }
        case .companion:
            CompanionStep(
                ideaID: chosenIdeaID, mode: chosenMode, age: age, source: source,
                familyCharacters: familyCharacters,
                availableRelations: familyRelations,
                selectedFamilyID: $chosenFamilyID,
                // Free text is a parent's surface: in child mode the child
                // picks from the characters the parent made, and cannot type.
                onAddFamily: app.isParentMode ? { showsFamilyEditor = true } : nil
            ) { companionID in
                chosenCompanionID = companionID
                begin()
            }
        case .preparing:
            StoryPreparationView()
        case .cover(let story):
            StoryCoverView(story: story, childName: profile?.name ?? "") {
                phase = .reading(story)
            }
            .transition(.opacity)

        case .reading(let story):
            // Yeni yapılmış masal her zaman ilk sayfadan açılır.
            StoryReaderView(story: story, startingPage: 0)
                .environmentObject(app)
                .transition(.opacity)
        case .failed:
            StoryCreationFailureView(
                onRetry: { resetToModes() },
                onClose: { dismiss() }
            )
        }
    }

    // MARK: - Choosing

    private var source: any StoryChoiceSource { StoryChoiceSources.current }

    /// The child's age. `MainContentView` never reaches this flow without a
    /// profile; the fallback is the MVP band's age only so previews render.
    private var age: Int { profile?.age ?? AgeBandResolver.mvp.upperBound }

    private func chooseMode(_ mode: StoryMode) {
        chosenMode = mode
        strategy = .direct
        chosenIdeaID = nil
        let ideas = source.ideaChoices(forAge: age, mode: mode)
        // Behind a flag, off in every build. With it on and no ideas under
        // this mode for this band, the step is still skipped rather than shown
        // with only "Bana bırak" on it.
        ideaStepShown = StoryCreationSteps.showsIdeaStep(hasIdeas: !ideas.isEmpty)
        phase = ideaStepShown ? .idea(mode) : .companion
    }

    /// "Bana sürpriz yap": MagicPaper picks the mode, looking at what this
    /// child read last so the surprise is not a repeat.
    private func surprise() {
        guard let profile else { return dismiss() }
        do {
            chosenMode = try source.resolveMode(
                strategy: .surprise,
                requested: nil,
                forAge: age,
                recent: storyManager.recentModes(for: profile)
            )
            strategy = .surprise
            chosenIdeaID = nil
            ideaStepShown = false
            phase = .companion
        } catch {
            print("❌ Sürpriz mod seçilemedi: \(storyFailureDetail(error))")
            phase = .failed
        }
    }

    // MARK: - Building

    /// The chosen Masal ailem character, if this mode can still carry it. A
    /// character chosen and then made unavailable by going back to another
    /// mode is dropped rather than failing the story.
    private var chosenFamily: FamilyCharacter? {
        guard let character = familyCharacters.first(where: { $0.id == chosenFamilyID }) else { return nil }
        return familyRelations.contains(character.relation.kind) ? character : nil
    }

    private func begin() {
        guard let profile else { return dismiss() }
        phase = .preparing

        Task {
            do {
                let story = try await storyManager.createStory(
                    for: profile,
                    mode: chosenMode,
                    strategy: strategy,
                    storyIdeaID: chosenIdeaID,
                    companionID: chosenCompanionID,
                    family: chosenFamily
                )
                // Composition takes milliseconds. The pause is the transition
                // doing its job (§19), not work being waited on — long enough
                // to read one line, short enough not to be a spinner.
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                phase = .cover(story)
            } catch {
                // §29: the detail goes to the log, never to the parent.
                print("❌ Hikâye üretilemedi: \(storyFailureDetail(error))")
                phase = .failed
            }
        }
    }
}
