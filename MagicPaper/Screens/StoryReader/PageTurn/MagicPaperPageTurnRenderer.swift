import SwiftUI

struct MagicPaperPageTurnRenderer<CurrentPage: View, AdjacentPage: View>: View {
    let direction: MagicPaperPageTurnDirection
    let progress: CGFloat
    let isTransitioning: Bool
    let theme: MP.ReadTheme
    
    let currentPage: CurrentPage
    let adjacentPage: AdjacentPage
    
    init(
        direction: MagicPaperPageTurnDirection,
        progress: CGFloat,
        isTransitioning: Bool,
        theme: MP.ReadTheme,
        @ViewBuilder currentPage: () -> CurrentPage,
        @ViewBuilder adjacentPage: () -> AdjacentPage
    ) {
        self.direction = direction
        self.progress = progress
        self.isTransitioning = isTransitioning
        self.theme = theme
        self.currentPage = currentPage()
        self.adjacentPage = adjacentPage()
    }
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            
            ZStack {
                // 1. NEXT PAGE (Background)
                adjacentPage
                    .frame(width: width, height: height)
                
                if isTransitioning {
                    let isForward = direction == .forward
                    
                    // foldX moves from width to 0 (forward) or 0 to width (backward)
                    let foldX: CGFloat = isForward 
                        ? width * (1 - progress)
                        : width * progress
                    
                    // 2. SHADOW CAST ON NEXT PAGE
                    // Cast from the fold line onto the revealed adjacent page
                    let shadowOpacity = sin(progress * .pi) * MagicPaperPageTurnConfiguration.shadowOpacityMaximum
                    
                    if isForward {
                        LinearGradient(
                            colors: [Color.black.opacity(shadowOpacity), Color.clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                        .frame(width: 40)
                        .position(x: foldX + 20, y: height / 2)
                    } else {
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(shadowOpacity)],
                            startPoint: .leading, endPoint: .trailing
                        )
                        .frame(width: 40)
                        .position(x: foldX - 20, y: height / 2)
                    }
                    
                    // 3. FLAT PART OF CURRENT PAGE
                    currentPage
                        .frame(width: width, height: height)
                        .mask(
                            Rectangle()
                                .frame(width: isForward ? foldX : width - foldX, height: height)
                                .position(x: isForward ? foldX / 2 : foldX + (width - foldX) / 2, y: height / 2)
                        )
                        // Fold inner shadow on the flat part
                        .overlay(
                            Group {
                                if isForward {
                                    LinearGradient(
                                        colors: [Color.clear, theme.spine.opacity(shadowOpacity * 1.5)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                    .frame(width: 30)
                                    .position(x: foldX - 15, y: height / 2)
                                } else {
                                    LinearGradient(
                                        colors: [theme.spine.opacity(shadowOpacity * 1.5), Color.clear],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                    .frame(width: 30)
                                    .position(x: foldX + 15, y: height / 2)
                                }
                            }
                        )
                    
                    // 4. TURNING PART OF CURRENT PAGE
                    let targetRotation = MagicPaperPageTurnConfiguration.maximumRotationDegrees
                    let rotationAngle = isForward ? -targetRotation * progress : targetRotation * progress
                    let anchorX = foldX / width
                    
                    // We switch to showing the back face when rotation passes 90 degrees
                    let isBackFaceVisible = progress > (90.0 / targetRotation)
                    
                    ZStack {
                        // The actual content of the turning part (visible when < 90 deg)
                        if !isBackFaceVisible {
                            currentPage
                                .frame(width: width, height: height)
                                // Fold highlight on the front of the turning part
                                .overlay(
                                    LinearGradient(
                                        colors: [Color.white.opacity(shadowOpacity * MagicPaperPageTurnConfiguration.highlightMaximumOpacity), Color.clear],
                                        startPoint: isForward ? .leading : .trailing,
                                        endPoint: isForward ? .trailing : .leading
                                    )
                                    .frame(width: 50)
                                    .position(x: isForward ? foldX + 25 : foldX - 25, y: height / 2)
                                )
                        } else {
                            // Back face: Paper texture
                            theme.paper
                                .frame(width: width, height: height)
                                // Ön yüzün mürekkebi arkadan soluk seçilir, gerçek
                                // kâğıttaki gibi. Aynı yaprak döndüğü için aynı
                                // yerde çizilir; dönüş onu kendiliğinden ters gösterir.
                                .overlay(
                                    currentPage
                                        .frame(width: width, height: height)
                                        .opacity(MagicPaperPageTurnConfiguration.backFaceInkOpacity)
                                        .allowsHitTesting(false)
                                        .accessibilityHidden(true)
                                )
                                .overlay(
                                    Group {
                                        if ReaderPaper.showsGrain {
                                            Image(uiImage: ReaderGrain.tile)
                                                .resizable(resizingMode: .tile)
                                                .opacity(theme.isDark ? 0.05 : 0.035)
                                                .blendMode(theme.isDark ? .plusLighter : .multiply)
                                                .allowsHitTesting(false)
                                        }
                                    }
                                )
                                // Shadow on the back face to simulate cylinder curve
                                .overlay(
                                    LinearGradient(
                                        colors: [theme.spine.opacity(shadowOpacity), Color.clear],
                                        startPoint: isForward ? .leading : .trailing,
                                        endPoint: isForward ? .trailing : .leading
                                    )
                                )
                        }
                    }
                    .mask(
                        Rectangle()
                            .frame(width: isForward ? width - foldX : foldX, height: height)
                            .position(x: isForward ? foldX + (width - foldX) / 2 : foldX / 2, y: height / 2)
                    )
                    // The correct SwiftUI way to rotate around a moving axis:
                    // Shift the axis to the origin (.leading), rotate, and shift back.
                    .offset(x: -foldX)
                    .rotation3DEffect(
                        .degrees(rotationAngle),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .leading,
                        perspective: MagicPaperPageTurnConfiguration.perspective
                    )
                    .offset(x: foldX)
                    
                } else {
                    currentPage
                        .frame(width: width, height: height)
                }
            }
        }
    }
}
