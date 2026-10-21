import SwiftUI

/// Açılır pencerenin boyu.
enum MPSheetHeight: Equatable {
    /// İçeriğin boyu kadar (ölçülen yükseklik). Ölçüm gelene kadar yarım sayfa.
    case fitted(CGFloat)
    /// Yarım sayfa, yukarı çekince tam.
    case half
    /// Tam sayfa.
    case full
}

/// Uygulamanın açılır penceresi, iOS 26 düzeninde (21 Ekim 2026).
///
/// - Yüzey kâğıt, cam değil (CLAUDE.md, Derinlik: sheet cam olmaz).
/// - Köşe sistemin: iOS 26'da sheet cihazın köşesiyle eş merkezli çizilir;
///   elle verilen yarıçap bunu bozar, bu yüzden `presentationCornerRadius` yok.
/// - Tutamak her zaman görünür; kapat düğmesi gerekmez, aşağı çekmek kapatır.
/// - En büyük yazı boyutlarında her pencere tam sayfa açılır: içerik kesilmez.
struct MPSheetPresentation: ViewModifier {
    let height: MPSheetHeight
    let area: MPArea
    @Environment(\.dynamicTypeSize) private var typeSize

    func body(content: Content) -> some View {
        content
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
            .presentationBackground(area == .kid ? MPColor.backgroundKid : MPColor.backgroundParent)
    }

    private var detents: Set<PresentationDetent> {
        if typeSize.isAccessibilitySize { return [.large] }
        switch height {
        case .fitted(let h): return h > 0 ? [.height(h)] : [.medium]
        case .half: return [.medium, .large]
        case .full: return [.large]
        }
    }
}

extension View {
    /// Açılır pencerenin sunumu: kâğıt yüzey, sistem köşesi, görünür tutamak.
    func mpSheet(_ height: MPSheetHeight = .half, area: MPArea = .kid) -> some View {
        modifier(MPSheetPresentation(height: height, area: area))
    }

    /// İçeriğin boyunu ölçer; `mpSheet(.fitted(...))` için.
    func mpMeasureHeight(_ height: Binding<CGFloat>) -> some View {
        onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height.wrappedValue = $0 }
    }
}
