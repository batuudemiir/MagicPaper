import SwiftUI

struct MagicPaperPageTurnContainer<Page: View>: View {
    let theme: MP.ReadTheme
    
    /// The index of the currently active page.
    let leafIndex: Int
    /// The total number of leaves.
    let leafCount: Int
    
    /// Returns the view for a given leaf index.
    let page: (Int) -> Page
    
    /// Called when the user has explicitly completed a page turn gesture.
    let onTurnCompleted: (MagicPaperPageTurnDirection) -> Void
    
    /// Called when the user taps on the center of the page.
    let onTap: () -> Void
    
    @State private var state = MagicPaperPageTurnState()
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            
            ZStack {
                // Determine adjacent page index based on drag direction
                let adjacentIndex = getAdjacentIndex()
                
                MagicPaperPageTurnRenderer(
                    direction: state.direction ?? .forward,
                    progress: state.progress,
                    isTransitioning: state.phase == .dragging || state.phase == .completing || state.phase == .cancelling,
                    theme: theme,
                    currentPage: {
                        page(leafIndex)
                    },
                    adjacentPage: {
                        if let adjacentIndex = adjacentIndex {
                            page(adjacentIndex)
                        } else {
                            // If there is no adjacent page (e.g. dragging past bounds), just show background or current
                            Color.clear
                        }
                    }
                )
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        handleDragChanged(value: value, width: width)
                    }
                    .onEnded { value in
                        handleDragEnded(value: value, width: width)
                    }
            )
            .onTapGesture(coordinateSpace: .local) { location in
                handleTap(location: location, width: width)
            }
        }
    }
    
    private func getAdjacentIndex() -> Int? {
        guard let direction = state.direction else { return nil }
        
        if direction == .forward {
            return leafIndex + 1 < leafCount ? leafIndex + 1 : nil
        } else {
            return leafIndex - 1 >= 0 ? leafIndex - 1 : nil
        }
    }
    
    private func handleDragChanged(value: DragGesture.Value, width: CGFloat) {
        guard state.phase == .idle || state.phase == .dragging else { return }
        
        // Determine direction on first move if idle
        if state.phase == .idle {
            guard MagicPaperPageTurnGesture.isHorizontalDrag(translation: value.translation) else { return }
            
            let isForward = value.translation.width < 0
            if isForward && leafIndex >= leafCount - 1 { return } // Can't go forward from last
            if !isForward && leafIndex <= 0 { return } // Can't go backward from first
            
            state.direction = isForward ? .forward : .backward
            state.phase = .dragging
        }
        
        guard let direction = state.direction else { return }
        
        let rawProgress = MagicPaperPageTurnGesture.progress(translation: value.translation.width, totalWidth: width, direction: direction)
        
        // Prevent reverse dragging (progress < 0) from going visually backwards
        state.progress = max(0, rawProgress)
        
        // Haptic threshold check
        if state.progress >= MagicPaperPageTurnConfiguration.completionThreshold && !state.hapticTriggered {
            state.hapticTriggered = true
            MPHaptics.pageTurn()
        }
    }
    
    private func handleDragEnded(value: DragGesture.Value, width: CGFloat) {
        guard state.phase == .dragging, let direction = state.direction else { return }
        
        let velocity = value.velocity.width
        let shouldComplete = MagicPaperPageTurnGesture.shouldComplete(progress: state.progress, velocity: velocity, direction: direction)
        
        if shouldComplete {
            state.phase = .completing
            withAnimation(MP.M.page) {
                state.progress = 1.0
            }
            
            // Dispatch completion after animation
            // Using a slight delay matching the animation duration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.52) { // 0.52 matches MP.M.page duration approximately
                if state.phase == .completing {
                    onTurnCompleted(direction)
                    state.reset()
                }
            }
        } else {
            state.phase = .cancelling
            withAnimation(MP.M.easeOut) {
                state.progress = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { // 0.18 matches MP.M.easeOut
                if state.phase == .cancelling {
                    state.reset()
                }
            }
        }
    }
    
    private func handleTap(location: CGPoint, width: CGFloat) {
        let edgeTapWidth = width * MagicPaperPageTurnConfiguration.edgeTapWidthRatio
        
        if location.x < edgeTapWidth {
            // Left edge tap -> previous page
            if leafIndex > 0 {
                onTurnCompleted(.backward)
            }
        } else if location.x > width - edgeTapWidth {
            // Right edge tap -> next page
            if leafIndex < leafCount - 1 {
                onTurnCompleted(.forward)
            }
        } else {
            // Center tap
            onTap()
        }
    }
}
