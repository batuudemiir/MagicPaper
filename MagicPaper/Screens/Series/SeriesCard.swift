import SwiftUI

/// The open series, on Home and in the Library (FAZ 13).
///
/// Two calm states: an episode is ready, or the next one opens after the one
/// before it is read. No countdown, no time, no "don't miss it" — the card is
/// where a family finds the next episode, not a reason to come back.
struct SeriesCard: View {

    let childID: UUID

    @ObservedObject private var series = SeriesManager.shared
    @ObservedObject private var library = StoryGenerationManager.shared
    @EnvironmentObject private var app: MPAppState

    var body: some View {
        switch series.cardState(for: childID) {
        case .ready(let storyID, let episode, let title):
            MPPressableCard(tone: .paper, padding: MP.S.x5, action: { open(storyID) }) {
                content(eyebrow: SeriesCopy.cardEyebrow, title: SeriesCopy.readyTitle(episode),
                        subtitle: SeriesCopy.cardSubtitle(title), note: nil, showsAction: true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(SeriesCopy.readyAccessibility(episode, title))
            .accessibilityAddTraits(.isButton)
        case .waiting(let episode, let title):
            MPCard(tone: .sunken, padding: MP.S.x5) {
                content(eyebrow: SeriesCopy.cardEyebrow, title: SeriesCopy.waitingTitle(episode),
                        subtitle: SeriesCopy.cardSubtitle(title), note: SeriesCopy.waitingNote,
                        showsAction: false)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(SeriesCopy.waitingAccessibility(episode, title))
        case nil:
            EmptyView()
        }
    }

    private func content(eyebrow: String, title: String, subtitle: String,
                         note: String?, showsAction: Bool) -> some View {
        HStack(alignment: .center, spacing: MP.S.x4) {
            VStack(alignment: .leading, spacing: MP.S.x1) {
                Text(eyebrow)
                    .font(MP.F.caption())
                    .tracking(1.1)
                    .foregroundStyle(MP.C.textMuted)
                Text(title)
                    .font(MP.F.displaySM())
                    .foregroundStyle(MP.C.textTitle)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(MP.F.bodySM(.semibold))
                    .foregroundStyle(MP.C.textBody)
                    .fixedSize(horizontal: false, vertical: true)
                if let note {
                    Text(note)
                        .font(MP.F.bodySM())
                        .foregroundStyle(MP.C.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            if showsAction {
                MPIcon("book", size: MP.G.lg, weight: .semibold)
                    .foregroundStyle(MP.C.brand)
                    .accessibilityHidden(true)
            }
        }
    }

    private func open(_ id: UUID) {
        // An episode deleted from the library before it was read comes back
        // here, not only on the next launch.
        series.refreshUnlocks(for: childID)
        guard let story = library.getStory(id: id) else { return }
        app.readerStory = story
    }
}
