import SwiftUI
import WidgetKit

/// Orta widget: devam eden seri (40 · Widget'lar, FAZ 13 serisi).
///
/// Ana sayfadaki seri kartının iki sakin durumu: bölüm hazır ya da yarın.
/// Geri sayım ve saat yok.
struct SeriesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: MPSurfaceStore.Kind.series, provider: SurfaceProvider()) { entry in
            SeriesWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetCopy.seriesName)
        .description(WidgetCopy.seriesDescription)
        .supportedFamilies([.systemMedium])
    }
}

struct SeriesWidgetView: View {
    let entry: SurfaceEntry

    var body: some View {
        HStack(spacing: MPSpacing.lg) {
            MPIcon("pawprint", size: MP.G.hero, weight: .semibold)
                .foregroundStyle(MPColor.textOnAction)
                .frame(maxWidth: 120, maxHeight: .infinity)
                .background(MPWorldTone.peach.deep, in: RoundedRectangle(cornerRadius: MPRadius.tile))
                .accessibilityHidden(true)
            if let series = entry.snapshot.series {
                details(series)
            } else {
                empty
            }
        }
        .containerBackground(MPColor.backgroundKid, for: .widget)
        .widgetURL(entry.snapshot.series == nil ? nil : MPSurfaceLink.series.url)
    }

    private func details(_ series: MPSurfaceSnapshot.Series) -> some View {
        let ready = series.isReady(at: entry.date)
        return VStack(alignment: .leading, spacing: MPSpacing.xxs) {
            Text(WidgetCopy.seriesEyebrow(series.episode, ready: ready))
                .mpText(.caption)
                .foregroundStyle(MPColor.textSecondary)
            Text(series.title)
                .mpText(.headline)
                .foregroundStyle(MPColor.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
            HStack(spacing: MPSpacing.xxs) {
                ForEach(0..<series.total, id: \.self) { i in
                    Capsule()
                        .fill(i < series.read ? MPWorldTone.peach.deep : MPColor.segmentTrack)
                        .frame(height: MPSpacing.xs)
                }
            }
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: MPSpacing.xxs) {
            Text(WidgetCopy.noSeriesTitle)
                .mpText(.cardTitle)
                .foregroundStyle(MPColor.textPrimary)
            Text(WidgetCopy.noSeriesBody)
                .mpText(.footnote)
                .foregroundStyle(MPColor.textSecondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview(as: .systemMedium) {
    SeriesWidget()
} timeline: {
    SurfaceEntry(date: .now, snapshot: .preview)
    SurfaceEntry(date: .now, snapshot: .empty)
}
