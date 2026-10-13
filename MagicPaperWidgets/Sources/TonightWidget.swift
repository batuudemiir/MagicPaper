import SwiftUI
import WidgetKit

/// Küçük widget: "Bu akşamın masalı" (40 · Widget'lar).
///
/// Gece sahnesi ve üstünde masalın adı. Kural Ana sayfa kartıyla aynı
/// (`MPTonight`); dokununca kart neyi açıyorsa o açılır.
struct TonightWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: MPSurfaceStore.Kind.tonight, provider: SurfaceProvider()) { entry in
            TonightWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetCopy.tonightName)
        .description(WidgetCopy.tonightDescription)
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct TonightWidgetView: View {
    let entry: SurfaceEntry

    private var tonight: MPTonight? {
        entry.snapshot.hasChild ? entry.snapshot.tonight(at: entry.date) : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.xxs) {
            Spacer(minLength: 0)
            Text(tonight.map(WidgetCopy.eyebrow) ?? WidgetCopy.noChildEyebrow)
                .mpText(.caption)
                .foregroundStyle(MP.C.textOnArtMuted)
            Text(tonight.map(WidgetCopy.title) ?? WidgetCopy.noChildTitle)
                .mpText(.cardTitle)
                .foregroundStyle(MP.C.textOnArt)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
            if let detail = tonight.flatMap(WidgetCopy.detail) {
                Text(detail)
                    .mpText(.caption)
                    .foregroundStyle(MP.C.textOnArtMuted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(MPSpacing.lg)
        .background(alignment: .bottom) {
            // Resim üstü metnin karartması (`MP.Scrim`, `MPArtHero` ile aynı).
            VStack(spacing: 0) {
                MP.Scrim.feather.frame(height: MP.Scrim.featherHeight)
                MP.Scrim.solid.frame(height: MPSpacing.xxxl * 2)
            }
            .accessibilityHidden(true)
        }
        .containerBackground(for: .widget) {
            Image("Brand/sceneNight")
                .resizable()
                .scaledToFill()
                // Görselin kendi yuvarlak köşesi widget kenarına taşmasın.
                .scaleEffect(1.08)
                .accessibilityHidden(true)
        }
        .widgetURL(MPSurfaceLink.tonight.url)
        .accessibilityElement(children: .combine)
    }
}

#Preview(as: .systemSmall) {
    TonightWidget()
} timeline: {
    SurfaceEntry(date: .now, snapshot: .preview)
    SurfaceEntry(date: .now, snapshot: .empty)
}
