import SwiftUI

/// What the parent sees when a story could not be made.
///
/// §29: one sentence and a way forward. No `noBlueprintsFound`, no decode error,
/// no compatibility report — those are in the log, which is where someone can do
/// something with them. What matters here is that the flow is not a dead end,
/// which is what it used to be: the old path printed to the console and returned
/// the parent to a wizard with no explanation at all.
struct StoryCreationFailureView: View {

    let onRetry: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: MP.S.x3) {
                MPIcon("exclamationmark.triangle", size: 26, weight: .semibold)
                    .foregroundStyle(MP.C.reward)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: MP.R.md, style: .continuous)
                            .fill(MP.C.reward.mpMixedWithWhite(0.16))
                    )

                Text("Hikâyemizi hazırlarken küçük bir sorun oldu.")
                    .font(MP.F.displaySM())
                    .foregroundStyle(MP.C.textTitle)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Bir kez daha deneyelim.")
                    .font(MP.F.bodyMD())
                    .foregroundStyle(MP.C.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            VStack(spacing: MP.S.x2) {
                LegacyMPButton(title: "Tekrar deneyelim", size: .lg, icon: "arrow.clockwise", fullWidth: true) {
                    onRetry()
                }
                LegacyMPButton(title: "Şimdi değil", variant: .ghost, size: .lg, fullWidth: true) {
                    onClose()
                }
            }
            .padding(.bottom, MP.S.x3)
        }
        .mpGutter()
    }
}
