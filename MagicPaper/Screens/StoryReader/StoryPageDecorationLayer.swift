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

        Image(asset.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .opacity(p.opacity)
            .rotationEffect(p.rotation)
            .frame(width: size.width, height: size.height, alignment: p.alignment)
            .offset(p.offset)
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

                ForEach(MotifZone.allCases) { zone in
                    // debug visualization for zones could be more complex now, skip simple circles
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
