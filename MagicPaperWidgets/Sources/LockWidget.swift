import SwiftUI
import WidgetKit

/// Kilit ekranı widget'ları (40 · Widget'lar, "Kilit ekranı").
///
/// Kilit ekranı herkese açık: masal başlığı, çocuğun adı yazmaz. Yalnızca
/// yatma saati ve bu hafta okunan akşamlar.
struct LockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: MPSurfaceStore.Kind.lock, provider: SurfaceProvider()) { entry in
            LockWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetCopy.lockName)
        .description(WidgetCopy.lockDescription)
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct LockWidgetView: View {
    let entry: SurfaceEntry
    @Environment(\.widgetFamily) private var family

    private var count: Int { entry.snapshot.week(at: entry.date).filter { $0 }.count }

    var body: some View {
        content
            .containerBackground(for: .widget) { AccessoryWidgetBackground() }
            .widgetURL(MPSurfaceLink.tonight.url)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 0) {
                MPIcon("moon.fill", size: MP.G.md, weight: .semibold)
                    .accessibilityHidden(true)
                if let bedtime = entry.snapshot.bedtime {
                    Text(bedtime.clockLabel)
                        .mpText(.caption)
                        .minimumScaleFactor(0.7)
                        .accessibilityLabel("Yatma saati \(bedtime.clockLabel)")
                } else {
                    Text(WidgetCopy.weekCount(count))
                        .mpText(.headline)
                        .accessibilityLabel(WidgetCopy.weekAccessibility(count))
                }
            }
        case .accessoryInline:
            Label(WidgetCopy.weekLine(count), systemImage: "moon.fill")
        default:
            VStack(alignment: .leading, spacing: 0) {
                Text(WidgetCopy.weekEyebrow)
                    .mpText(.caption)
                    .foregroundStyle(.secondary)
                Text(WidgetCopy.weekLine(count))
                    .mpText(.cardTitle)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(WidgetCopy.weekAccessibility(count))
        }
    }
}

#Preview(as: .accessoryRectangular) {
    LockWidget()
} timeline: {
    SurfaceEntry(date: .now, snapshot: .preview)
}
