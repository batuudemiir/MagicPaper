import SwiftUI
import WidgetKit

/// Küçük widget: bu hafta okunan akşamlar (40 · Widget'lar).
///
/// Teslimde "3/4" halkası vardı; haftalık bir hedef ve "1 kaldı" baskısı
/// CLAUDE.md §7'ye aykırı. Burada yalnızca okunan akşamların sayısı ve
/// haftanın yedi günü: Ana sayfadaki okuma şeridinin küçük hâli.
struct WeekWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: MPSurfaceStore.Kind.week, provider: SurfaceProvider()) { entry in
            WeekWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetCopy.weekName)
        .description(WidgetCopy.weekDescription)
        .supportedFamilies([.systemSmall])
    }
}

struct WeekWidgetView: View {
    let entry: SurfaceEntry

    private var days: [Bool] { entry.snapshot.week(at: entry.date) }
    private var count: Int { days.filter { $0 }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            Text(WidgetCopy.weekEyebrow)
                .mpText(.caption)
                .foregroundStyle(MPColor.textSecondary)
            Spacer(minLength: 0)
            if count > 0 {
                Text(WidgetCopy.weekCount(count))
                    .mpText(.display)
                    .foregroundStyle(MPColor.textPrimary)
                Text(WidgetCopy.weekUnit)
                    .mpText(.footnote)
                    .foregroundStyle(MPColor.textSecondary)
            } else {
                Text(WidgetCopy.weekStart)
                    .mpText(.callout)
                    .foregroundStyle(MPColor.textPrimary)
                    .lineLimit(3)
            }
            Spacer(minLength: 0)
            HStack(spacing: MPSpacing.xxs) {
                ForEach(days.indices, id: \.self) { i in
                    Circle()
                        .fill(days[i] ? MPWorldTone.peach.deep : MPColor.segmentTrack)
                        .frame(width: MPSpacing.md, height: MPSpacing.md)
                }
            }
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(MPColor.backgroundKid, for: .widget)
        .widgetURL(MPSurfaceLink.tonight.url)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WidgetCopy.weekAccessibility(count))
    }
}

#Preview(as: .systemSmall) {
    WeekWidget()
} timeline: {
    SurfaceEntry(date: .now, snapshot: .preview)
    SurfaceEntry(date: .now, snapshot: .empty)
}
