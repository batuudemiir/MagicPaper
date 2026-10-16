import SwiftUI

/// Masal atölyesi: the open notebook the story is written into.
///
/// Shows what the script has reached: the cast arrives, then the story's own
/// first sentence is inked. The cover replaces the notebook at the end (that
/// lives in `StoryPreparationView`, which owns the reveal).
struct PreparationNotebook: View {

    let facts: PreparationFacts?
    let beat: StoryPreparationScript.Beat
    /// The child's avatar colour for their name tag.
    var childColor: Color?
    /// How long the ink may take; the writing step can be shorter than
    /// `MP.M.inkDuration` in the short ritual.
    var inkDuration: Double = MP.M.inkDuration

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private func reached(_ b: StoryPreparationScript.Beat) -> Bool {
        let order: [StoryPreparationScript.Beat] = [.openBook, .cast, .ageFit, .modeTouch, .writing, .reread, .bind]
        return (order.firstIndex(of: beat) ?? 0) >= (order.firstIndex(of: b) ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MP.S.x5) {
            if let facts, reached(.cast) {
                MPFlowLayout(spacing: MP.S.x2) {
                    ForEach(Array(StoryPreparationScript.castNames(facts).enumerated()), id: \.offset) { index, name in
                        CastTag(name: name, color: index == 0 ? childColor : nil)
                            .transition(.opacity)
                    }
                }
                .accessibilityHidden(true)
            }

            if let facts, reached(.writing), !facts.firstSentence.isEmpty {
                InkLine(text: facts.firstSentence, duration: inkDuration, animated: !reduceMotion)
                    .transition(.opacity)
            }

            Spacer(minLength: 0)
        }
        .padding(MP.S.x6)
        .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
        .mpEdge(fill: MP.C.surfaceCard, edge: MP.C.edgeCard, radius: MP.R.card)
        .animation(MP.M.gated(MP.M.page) ?? MP.M.base, value: beat)
    }
}

/// A name in the cast: "Ela", "tilki Tarçın".
private struct CastTag: View {
    let name: String
    var color: Color?

    var body: some View {
        HStack(spacing: MP.S.x2) {
            if let color {
                Circle().fill(color)
                    .frame(width: MP.S.x3, height: MP.S.x3)
                    .accessibilityHidden(true)
            }
            Text(name)
                .font(MP.F.labelMD())
                .foregroundStyle(MP.C.brandInk)
        }
        .padding(.horizontal, MP.S.x4)
        .padding(.vertical, MP.S.x2)
        .background(MP.C.brandSoft, in: Capsule())
    }
}

/// One sentence written letter by letter. The whole sentence is laid out from
/// the start (the unwritten part is clear), so lines never reflow as it grows.
/// With Reduce Motion it appears whole, by crossfade.
struct InkLine: View {
    let text: String
    var duration: Double = MP.M.inkDuration
    var animated: Bool = true

    @State private var written = 0

    private var attributed: AttributedString {
        let characters = Array(text)
        let count = animated ? min(written, characters.count) : characters.count
        var shown = AttributedString(String(characters.prefix(count)))
        shown.foregroundColor = MP.C.textBody
        var rest = AttributedString(String(characters.dropFirst(count)))
        rest.foregroundColor = .clear
        return shown + rest
    }

    var body: some View {
        Text(attributed)
            .font(MP.F.read(MP.ReadSize.normal.points))
            .lineSpacing(MP.ReadSize.normal.lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(text)
            .task(id: text) {
                guard animated else { return }
                written = 0
                let characters = text.count
                guard characters > 0 else { return }
                let pause = duration / Double(characters)
                for step in 1...characters {
                    try? await Task.sleep(for: .seconds(pause))
                    if Task.isCancelled { return }
                    written = step
                }
            }
    }
}
