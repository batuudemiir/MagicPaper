import SwiftUI

#if DEBUG
struct MagicPaperPageTurnPreview: View {
    @State private var leafIndex: Int = 0
    let theme: MP.ReadTheme = .light
    
    // Mock pages for testing the rendering
    let leafCount = 5
    
    var body: some View {
        MagicPaperPageTurnContainer(
            theme: theme,
            leafIndex: leafIndex,
            leafCount: leafCount,
            page: { index in
                mockPage(for: index)
            },
            onTurnCompleted: { direction in
                if direction == .forward && leafIndex < leafCount - 1 {
                    leafIndex += 1
                } else if direction == .backward && leafIndex > 0 {
                    leafIndex -= 1
                }
            },
            onTap: {
                print("Center tapped: toggle controls")
            }
        )
        .overlay(alignment: .topTrailing) {
            Text("Page: \(leafIndex + 1) / \(leafCount)")
                .font(MP.F.caption())
                .padding(8)
                .background(Color.black.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
                .allowsHitTesting(false)
        }
    }
    
    @ViewBuilder
    private func mockPage(for index: Int) -> some View {
        ZStack {
            theme.paper.ignoresSafeArea()
            
            VStack(spacing: MP.S.x6) {
                Text(pageTitle(for: index))
                    .font(MP.F.displayMD())
                    .foregroundColor(theme.foreground)
                    .multilineTextAlignment(.center)
                    .padding(.top, MP.S.x10)
                
                if index % 2 == 1 {
                    // "Illustrated" page simulation
                    RoundedRectangle(cornerRadius: MP.R.md)
                        .fill(MP.Palette.yesim100)
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "tree.fill")
                                .font(.system(size: 80))
                                .foregroundColor(MP.Palette.yesim500)
                        )
                        .padding(.horizontal, MP.S.x6)
                }
                
                Text(pageBody(for: index))
                    .font(MP.F.bodyMD())
                    .foregroundColor(theme.body)
                    .lineSpacing(MP.ReadSize.normal.lineSpacing)
                    .padding(.horizontal, MP.S.x6)
                
                Spacer()
                
                Button(action: {
                    print("Interactive button on page \(index) tapped")
                }) {
                    Text("Interactive Element")
                        .font(MP.F.labelMD())
                        .foregroundColor(MP.C.textOnBrand)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(MP.C.brand)
                        .cornerRadius(MP.R.button)
                        .padding(.horizontal, MP.S.x6)
                }
                .padding(.bottom, MP.S.x10)
            }
        }
    }
    
    private func pageTitle(for index: Int) -> String {
        switch index {
        case 0: return "The Beginning"
        case 1: return "The Forest"
        case 2: return "A Long Journey"
        case 3: return "Almost There"
        case 4: return "The End"
        default: return "Page \(index)"
        }
    }
    
    private func pageBody(for index: Int) -> String {
        switch index {
        case 0: return "This is a sparse page to test how the interaction feels with very little content. Try swiping from the right edge."
        case 1: return "This page simulates an illustrated page. The texture and shadows should feel natural over the colored rectangle."
        case 2: return "This page contains a much longer paragraph. It is important to ensure that text remains readable and doesn't aggressively warp or distort during the page turn. The paper texture should remain completely stable while the page follows your finger."
        case 3: return "Another sparse page. Test slow drags, fast swipes, and cancellations here."
        case 4: return "The final page. Swiping forward from here should be prevented."
        default: return "Content for page \(index)."
        }
    }
}

// MARK: - Previews Matrix

struct MagicPaperPageTurnPreview_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Standard iPhone
            MagicPaperPageTurnPreview()
                .previewDisplayName("iPhone Standard")
            
            // iPhone SE
            MagicPaperPageTurnPreview()
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
                .previewDisplayName("iPhone SE")
            
            // iPhone Pro Max
            MagicPaperPageTurnPreview()
                .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro Max"))
                .previewDisplayName("iPhone Pro Max")
            
            // iPad
            MagicPaperPageTurnPreview()
                .previewDevice(PreviewDevice(rawValue: "iPad mini (6th generation)"))
                .previewDisplayName("iPad Mini")
        }
    }
}
#endif
