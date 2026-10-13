import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Uyku modu Live Activity'si (41 · Kilit ekranı, FAZ 19).
///
/// Kilit ekranında ve Dynamic Island'da: ay, "Uyku modu", kalan süre ve
/// Durdur. Masalın adı yazmaz (kilit ekranı herkese açık). Dokununca uyku
/// modu açık olan uygulamaya döner.
struct SleepLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MPSleepActivityAttributes.self) { context in
            SleepLockScreenView(state: context.state)
                .activityBackgroundTint(MPColor.backgroundNight)
                .activitySystemActionForegroundColor(MPColor.readerNightText)
                .widgetURL(MPSurfaceLink.sleep.url)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(WidgetCopy.sleepTitle).mpText(.callout)
                    } icon: {
                        SleepMoon()
                    }
                    .foregroundStyle(MPColor.readerNightText)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    SleepRemaining(state: context.state)
                        .mpText(.callout)
                        .foregroundStyle(MPColor.readerNightText)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(SleepStatus.text(context.state))
                            .mpText(.footnote)
                            .foregroundStyle(MPColor.readerNightSecondary)
                        Spacer()
                        SleepStopButton()
                    }
                }
            } compactLeading: {
                SleepMoon()
            } compactTrailing: {
                SleepRemaining(state: context.state)
                    .mpText(.caption)
                    .foregroundStyle(MPColor.readerNightText)
                    .frame(maxWidth: MP.G.display)
            } minimal: {
                SleepMoon()
            }
            .widgetURL(MPSurfaceLink.sleep.url)
        }
    }
}

private enum SleepStatus {
    static func text(_ state: MPSleepActivityAttributes.ContentState) -> String {
        if state.finished { return WidgetCopy.sleepFinished }
        return state.isPaused ? WidgetCopy.sleepPaused : WidgetCopy.sleepReading
    }
}

private struct SleepMoon: View {
    var body: some View {
        MPIcon("moon.fill", size: MP.G.md, weight: .semibold)
            .foregroundStyle(MPColor.brandStar)
            .accessibilityHidden(true)
    }
}

/// Kalan süre: okunurken kendiliğinden azalır, duraklayınca durur.
private struct SleepRemaining: View {
    let state: MPSleepActivityAttributes.ContentState

    var body: some View {
        if let paused = state.pausedRemaining {
            Text(Duration.seconds(paused), format: .time(pattern: .minuteSecond))
                .monospacedDigit()
        } else {
            Text(timerInterval: Date()...max(Date(), state.endsAt), countsDown: true)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct SleepStopButton: View {
    var body: some View {
        Button(intent: StopSleepModeIntent()) {
            Text(WidgetCopy.sleepStop)
                .mpText(.callout)
                .padding(.horizontal, MPSpacing.md)
        }
        .buttonStyle(.bordered)
        .tint(MPColor.readerNightText)
        .accessibilityLabel(WidgetCopy.sleepStopAccessibility)
    }
}

private struct SleepLockScreenView: View {
    let state: MPSleepActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            SleepMoon()
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                Text(WidgetCopy.sleepTitle)
                    .mpText(.cardTitle)
                    .foregroundStyle(MPColor.readerNightText)
                Text(SleepStatus.text(state))
                    .mpText(.footnote)
                    .foregroundStyle(MPColor.readerNightSecondary)
            }
            Spacer(minLength: MPSpacing.sm)
            VStack(alignment: .trailing, spacing: MPSpacing.xs) {
                if !state.finished {
                    SleepRemaining(state: state)
                        .mpText(.headline)
                        .foregroundStyle(MPColor.readerNightText)
                }
                SleepStopButton()
            }
        }
        .padding(MPSpacing.lg)
    }
}

#Preview("Kilit ekranı", as: .content, using: MPSleepActivityAttributes()) {
    SleepLiveActivity()
} contentStates: {
    MPSleepActivityAttributes.ContentState(endsAt: .now.addingTimeInterval(12 * 60))
    MPSleepActivityAttributes.ContentState(endsAt: .now, pausedRemaining: 8 * 60)
}
