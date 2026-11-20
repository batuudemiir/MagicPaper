import SwiftUI

/// Measures the complete narrative once per layout pass, with no measurement state.
/// The optional quiet space is used only when every measured line fits the viewport.
struct ReaderRhythmLayout: Layout {
    let gaps: [CGFloat]
    let quietIndices: Set<Int>
    let viewportHeight: CGFloat
    var trailing: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let plan = measurement(proposal: proposal, subviews: subviews)
        return CGSize(width: plan.width, height: plan.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let plan = measurement(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        var y = bounds.minY
        for index in subviews.indices {
            y += gap(at: index, extra: plan.extra)
            subviews[index].place(at: CGPoint(x: bounds.minX, y: y), anchor: .topLeading,
                                  proposal: ProposedViewSize(width: plan.width, height: plan.sizes[index].height))
            y += plan.sizes[index].height
        }
    }

    private func measurement(proposal: ProposedViewSize, subviews: Subviews)
        -> (width: CGFloat, height: CGFloat, sizes: [CGSize], extra: Bool) {
        let sizes = subviews.map { $0.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil)) }
        let width = proposal.width ?? sizes.map(\.width).max() ?? 0
        let ordinary = sizes.reduce(trailing) { $0 + $1.height }
            + subviews.indices.reduce(CGFloat.zero) { $0 + gap(at: $1, extra: false) }
        let optional = CGFloat(quietIndices.count) * MP.S.x6
        let extra = viewportHeight.isFinite && viewportHeight > 0 && ordinary + optional <= viewportHeight
        return (width, ordinary + (extra ? optional : 0), sizes, extra)
    }

    private func gap(at index: Int, extra: Bool) -> CGFloat {
        (gaps.indices.contains(index) ? gaps[index] : 0)
            + (extra && quietIndices.contains(index) ? MP.S.x6 : 0)
    }
}
