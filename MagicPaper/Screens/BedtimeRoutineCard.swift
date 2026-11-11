import SwiftUI

/// Akşam sırası: diş, pijama, masal, ışık (Faz 11, `MPBedtimeRoutine`).
///
/// Bu akşamın penceresinde (`BedtimeStorySheet`) dokunulur; gece masal
/// sonunda yalnızca yankılanır (`interactive: false`). İşaret yalnızca renkle
/// verilmez: biten adımda onay simgesi ve VoiceOver'da "tamam" var. Sayı,
/// "kaldı" sözü ya da ilerleme çubuğu yok.
struct BedtimeRoutineCard: View {
    var interactive = true
    /// Gece kâğıdında masal sonu kendi renklerini verir.
    var foreground: Color = MPColor.textPrimary
    var muted: Color = MPColor.textSecondary

    @ObservedObject private var routine = MPBedtimeRoutine.shared
    @Environment(\.dynamicTypeSize) private var typeSize

    private var childID: UUID? { ProfileManager.shared.currentProfile?.id }

    var body: some View {
        let done = routine.done(for: childID)
        VStack(spacing: MPSpacing.sm) {
            Text("Akşam sırası").mpText(.cardTitle).foregroundStyle(foreground)
                .accessibilityAddTraits(.isHeader)
            let columns = Array(repeating: GridItem(.flexible(), spacing: MPSpacing.sm),
                                count: typeSize.isAccessibilitySize ? 2 : 4)
            LazyVGrid(columns: columns, spacing: MPSpacing.sm) {
                ForEach(MPBedtimeRoutine.Step.allCases) { step in
                    stepView(step, done: done.contains(step))
                }
            }
            Text(MPBedtimeRoutine.caption(for: done))
                .mpText(.footnote).foregroundStyle(muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .id(routine.revision)
    }

    @ViewBuilder
    private func stepView(_ step: MPBedtimeRoutine.Step, done: Bool) -> some View {
        let face = VStack(spacing: MPSpacing.xs) {
            ZStack(alignment: .bottomTrailing) {
                MPIcon(step.symbol, size: MP.G.md, weight: .semibold)
                    .foregroundStyle(done ? MPColor.textOnAction : MPColor.actionPrimary)
                    .frame(width: MPSize.chipHeightKid + MPSpacing.sm, height: MPSize.chipHeightKid + MPSpacing.sm)
                    .background(done ? MPColor.actionPrimary : MPWorldTone.lav.soft, in: Circle())
                if done {
                    MPIcon("checkmark.circle.fill", size: MP.G.sm, weight: .bold)
                        .foregroundStyle(MPColor.statusSuccess)
                        .background(MP.C.surfaceCard, in: Circle())
                }
            }
            Text(step.title).mpText(.footnote).foregroundStyle(foreground)
        }
        .frame(maxWidth: .infinity, minHeight: MPSize.minTouchKid)

        if interactive {
            Button {
                MPHaptics.tap()
                MPBedtimeRoutine.shared.toggle(step, for: childID)
            } label: { face }
            .buttonStyle(MPPressStyle())
            .accessibilityLabel(step.title)
            .accessibilityValue(done ? "Tamam" : "Henüz değil")
            .accessibilityHint(done ? "İşareti kaldırır" : "Tamam diye işaretler")
        } else {
            face
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(step.title), \(done ? "tamam" : "henüz değil")")
        }
    }
}

#Preview("Akşam sırası") {
    BedtimeRoutineCard().padding()
}
