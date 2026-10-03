import SwiftUI

/// The story creation experience: an intent, then a story.
///
/// Replaces the four-step wizard, which asked for a child, a type, a direction,
/// a world, a companion, and finally whether the story should be illustrated —
/// six decisions that made the product feel like a form.
///
/// The one required decision is the **mode** — Gelişelim, Maceraya Çıkalım,
/// Uyku Zamanı — or "Bana sürpriz yap", which lets MagicPaper pick the mode.
/// Idea cards are an optional second step under the mode ("Bana bırak" skips
/// them); a surprise skips them too, because the parent asked us to decide.
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

    @State private var phase: Phase = .mode
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

    private var profile: UserProfile? { profileManager.currentProfile }

    var body: some View {
        VStack(spacing: 0) {
            if showsHeader { header }
            content
        }
        .mpScreenBackground()
        .animation(MP.M.gated(MP.M.page), value: phase)
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
                MPStepDots(total: 3, current: step, labels: ["Hikâye", "Fikir", "Arkadaş"])
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

    private var stepIndex: Int? {
        switch phase {
        case .mode: return 0
        case .idea: return 1
        case .companion: return 2
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
            CompanionStep(ideaID: chosenIdeaID, mode: chosenMode, age: age, source: source) { companionID in
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
        // No ideas under this mode for this band: nothing to personalise, so
        // the step is skipped rather than shown with only "Bana bırak" on it.
        ideaStepShown = !ideas.isEmpty
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
                    companionID: chosenCompanionID
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
