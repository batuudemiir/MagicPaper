import SwiftUI

/// Sayfanın süsleme katmanı.
///
/// Kod yalnızca yerleştirir: hangi görsel, nerede, ne ölçekte, ne kadar dönük,
/// ne opaklıkta (§34). Çizimin kendisi PNG olarak geliyor.
///
/// Katman metnin *altında* durur ve hiçbir dokunuşu yakalamaz — süs, okumanın
/// önüne geçemez.
struct StoryPageDecorationLayer: View {

    let context: StoryDecorationContext
    let tint: Color
    /// Geliştirici katmanı: bölgeleri, sınırları ve kimlikleri gösterir.
    var showsDebug: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var placements: [StoryDecorationPlacement] {
        StoryDecorationEngine().plan(context)
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                ForEach(placements) { placement in
                    if let asset = StoryDecorationCatalog.asset(id: placement.assetID) {
                        mark(asset, placement, in: size)
                    }
                }
                if showsDebug {
                    StoryDecorationDebugOverlay(context: context,
                                                placements: placements)
                }
            }
            .frame(width: size.width, height: size.height)
        }
        // Bütün katman erişilebilirlik ağacının dışında (§39): süsler
        // VoiceOver'a anlamsız duyuru olarak girmemeli.
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func mark(_ asset: StoryDecorationAsset,
                      _ p: StoryDecorationPlacement,
                      in size: CGSize) -> some View {
        let width = size.width * p.scale
        let anchor = p.zone.anchor
        let bleed = p.zone.bleed

        Image(asset.imageName)
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .frame(width: width)
            .foregroundStyle(tint)
            .opacity(p.opacity)
            .rotationEffect(p.rotation)
            .position(
                x: size.width * (anchor.x + p.jitter.width) + width * bleed.width,
                y: size.height * (anchor.y + p.jitter.height) + width * bleed.height
            )
    }
}

/// Geliştirici görselleştirmesi (§31).
///
/// Yalnızca hata ayıklamada: güvenli bölgeler, yerleşim çapaları ve varlık
/// kimlikleri. Kompozisyonu elle ayarlarken gözle görmek, sayısal değerlerle
/// uğraşmaktan çok daha hızlı.
struct StoryDecorationDebugOverlay: View {
    let context: StoryDecorationContext
    let placements: [StoryDecorationPlacement]

    var body: some View {
        GeometryReader { geo in
            let s = geo.size
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .strokeBorder(Color.red.opacity(0.75), lineWidth: 1)
                    .frame(width: s.width * context.textSafeRect.width,
                           height: s.height * context.textSafeRect.height)
                    .position(x: s.width * context.textSafeRect.midX,
                              y: s.height * context.textSafeRect.midY)

                if let illo = context.illustrationSafeRect {
                    Rectangle()
                        .strokeBorder(Color.blue.opacity(0.65), lineWidth: 1)
                        .frame(width: s.width * illo.width, height: s.height * illo.height)
                        .position(x: s.width * illo.midX, y: s.height * illo.midY)
                }

                ForEach(DecorationZone.allCases) { zone in
                    Circle()
                        .fill(Color.green.opacity(0.35))
                        .frame(width: 8, height: 8)
                        .position(x: s.width * zone.anchor.x, y: s.height * zone.anchor.y)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(context.environment.rawValue) · \(context.density.rawValue) · \(placements.count)")
                        .foregroundStyle(.red)
                    ForEach(placements) { p in
                        Text("\(p.assetID) @\(p.zone.rawValue)")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.system(size: 8, design: .monospaced))
                .padding(6)
            }
        }
    }
}
