import SwiftUI
import StoryEngine

/// The story creation experience: two choices, then a story.
///
/// Replaces the four-step wizard, which asked for a child, a type, a direction,
/// a world, a companion, and finally whether the story should be illustrated —
/// six decisions that made the product feel like a form. Here the parent picks
/// how today's adventure begins and MagicPaper does the rest.
///
/// The child is not asked for: the app already has a current profile, and
/// `MainContentView` will not reach this screen without one.
struct StoryCreationFlow: View {

    /// Where the flow is. Linear on purpose — one decision per screen, which is
    /// also what makes it usable by a child later (§27).
    private enum Phase: Equatable {
        case idea
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

    @State private var phase: Phase = .idea
    /// Nil means the child chose "surprise me". Stable ids, never display text.
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
                MPStepDots(total: 2, current: step, labels: ["Hikâye", "Arkadaş"])
            }
            Spacer(minLength: 0)
            Color.clear.frame(width: 44, height: 44)
        }
        .mpGutter()
        .padding(.top, MP.S.x1)
    }

    private var showsBack: Bool {
        if case .companion = phase { return true }
        return false
    }

    private var stepIndex: Int? {
        switch phase {
        case .idea: return 0
        case .companion: return 1
        default: return nil
        }
    }

    private func goBack() {
        switch phase {
        case .companion:
            chosenCompanionID = nil
            phase = .idea
        default:
            dismiss()
        }
    }

    // MARK: - Phases

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .idea:
            StoryIdeaStep(age: profile?.age ?? 6) { ideaID in
                chosenIdeaID = ideaID
                phase = .companion
            }
        case .companion:
            CompanionStep(ideaID: chosenIdeaID) { companionID in
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
                onRetry: { phase = .idea },
                onClose: { dismiss() }
            )
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
                let detail = (error as? OfflineStoryService.Failure)?.detail
                    ?? String(describing: error)
                print("❌ Hikâye üretilemedi: \(detail)")
                phase = .failed
            }
        }
    }
}
