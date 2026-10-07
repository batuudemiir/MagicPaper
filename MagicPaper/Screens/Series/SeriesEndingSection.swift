import SwiftUI

/// The series part of a story's last leaf (FAZ 13).
///
/// "Devam ettir" for a story that can be continued; a calm line when another
/// series is open; where this episode stands; and, after the fifth, the quiet
/// "Seri tamamlandı" moment — no badge, no confetti, no count to beat.
/// The state comes from `SeriesManager`; this view only draws it.
struct SeriesEndingSection: View {

    let story: Story
    let theme: MP.ReadTheme
    let accent: Color

    @ObservedObject private var series = SeriesManager.shared
    @EnvironmentObject private var app: MPAppState

    var body: some View {
        switch series.endingState(for: story, atEnd: true) {
        case .none:
            EmptyView()
        case .offer:
            VStack(alignment: .leading, spacing: MP.S.x3) {
                Text(SeriesCopy.continueHint)
                    .font(MP.F.bodySM())
                    .foregroundStyle(theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                LegacyMPButton(title: SeriesCopy.continueButton, size: .lg, icon: "sparkles",
                         fullWidth: true) {
                    start()
                }
                .accessibilityHint(SeriesCopy.continueAccessibilityHint)
            }
        case .blocked:
            note(SeriesCopy.blocked(child: story.childName))
        case .started:
            note(SeriesCopy.started)
        case .episode(let number):
            VStack(alignment: .leading, spacing: MP.S.x1) {
                Text(SeriesCopy.episodeOf(number))
                    .font(MP.F.labelMD())
                    .foregroundStyle(theme.foreground)
                if number < SeriesCopy.episodeCount {
                    Text(SeriesCopy.nextEpisode)
                        .font(MP.F.bodySM())
                        .foregroundStyle(theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
        case .completed:
            VStack(alignment: .leading, spacing: MP.S.x2) {
                HStack(alignment: .firstTextBaseline, spacing: MP.S.x2) {
                    MPIcon("sparkles", size: MP.G.md, weight: .semibold)
                        .foregroundStyle(accent)
                        .accessibilityHidden(true)
                    Text(SeriesCopy.completedTitle)
                        .font(MP.F.displaySM())
                        .foregroundStyle(theme.foreground)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(SeriesCopy.completedBody)
                    .font(MP.F.bodySM())
                    .foregroundStyle(theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(MP.F.bodySM())
            .foregroundStyle(theme.muted)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func start() {
        do {
            try series.startSeries(from: story, readToEnd: true)
            MPHaptics.success()
            app.showToast(SeriesCopy.startedToast, symbol: "sparkles")
        } catch {
            app.showToast(SeriesCopy.startFailed, symbol: "xmark")
        }
    }
}
