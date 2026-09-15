import SwiftUI

/// The moment between choosing and reading.
///
/// §18: never "Blueprint seçiliyor" or "Story Engine çalışıyor". The parent made
/// two choices and MagicPaper made the rest; this says that, in the product's
/// own voice.
///
/// It is also not a progress indicator. Composition is offline and finishes in
/// milliseconds, so there is nothing to report the progress *of* — a spinner
/// here would be theatre. What the time buys is a beat of anticipation, and the
/// lines advance on their own rather than tracking work.
struct StoryPreparationView: View {

    private static let lines = [
        "Bir macera bulduk…",
        "Bir arkadaş seçtik…",
        "Şimdi sayfalar açılıyor…"
    ]

    @State private var visible = 0

    var body: some View {
        VStack(alignment: .leading, spacing: MP.S.x5) {
            Spacer(minLength: 0)

            Text("Sen başlangıcı seçtin.\nGerisini biz hazırlıyoruz.")
                .font(MP.F.displayLG())
                .mpTightTracking(32)
                .foregroundStyle(MP.C.textTitle)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: MP.S.x3) {
                ForEach(Array(Self.lines.enumerated()), id: \.offset) { index, line in
                    HStack(spacing: MP.S.x3) {
                        MPIcon("sparkles", size: 15, weight: .bold)
                            .foregroundStyle(MP.C.brand)
                        Text(line)
                            .font(MP.F.bodyMD())
                            .foregroundStyle(MP.C.textMuted)
                    }
                    .opacity(index < visible ? 1 : 0)
                    .offset(y: index < visible ? 0 : 6)
                    .animation(MP.M.gated(MP.M.base), value: visible)
                }
            }

            Spacer(minLength: 0)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mpGutter()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Hikâyen hazırlanıyor.")
        .task {
            // Reduced motion gets the whole message at once rather than a
            // sequence it did not ask for.
            guard !UIAccessibility.isReduceMotionEnabled else {
                visible = Self.lines.count
                return
            }
            for step in 1...Self.lines.count {
                try? await Task.sleep(nanoseconds: 380_000_000)
                visible = step
            }
        }
    }
}
