import Foundation

enum ReaderPageComposition: Equatable {
    case scene, spot, text
}

/// Metne ayrılan alan önce gelir. Kararlar kâğıttan ve gerçek görünüm
/// ölçülerinden çıkar; ekran veya çocuğun adı üzerinden tahmin yapılmaz.
enum ReaderPageLayout {
    static func seekFraction(page: Int, count: Int) -> Double {
        guard count > 1 else { return 0 }
        return Double(min(max(page, 0), count - 1)) / Double(count - 1)
    }

    static func sceneHeight(width: CGFloat, height: CGFloat, readPoints: CGFloat, accessibility: Bool) -> CGFloat {
        let fraction: CGFloat
        if accessibility { fraction = 0.20 }
        else if width > height { fraction = 0.26 }
        else if readPoints >= 26 { fraction = 0.34 }
        else { fraction = 0.40 }
        return max(0, min(width * 0.75, height * fraction))
    }

    /// Two control rows, their spacing and padding; safe-area insets belong to the host.
    static func bottomChromeClearance(accessibility: Bool, compactHeight: Bool = false) -> CGFloat {
        let upperRow = accessibility ? (compactHeight ? MPSize.minTouchHero : MP.S.tapMin * 3) : MP.S.tapMin
        return upperRow + MPSize.minTouchHero + MP.S.x2 * 2 + MP.S.x1
    }

    static func spotSize(width: CGFloat, height: CGFloat, accessibility: Bool) -> CGSize {
        spotHeaderSize(width: width, pageHeight: height, contentHeight: height,
                       accessibility: accessibility)
    }

    /// The page sets the desired footprint; the remaining text column bounds it.
    static func spotHeaderSize(width: CGFloat, pageHeight: CGFloat, contentHeight: CGFloat,
                               accessibility: Bool) -> CGSize {
        guard !accessibility, width > 0, pageHeight > 0,
              contentHeight >= MP.S.x10 * 3 else { return .zero }
        let landscape = width > pageHeight
        guard !landscape || contentHeight >= MP.S.x10 * 5 else { return .zero }
        let fraction: CGFloat = landscape ? 0.20 : 0.28
        return CGSize(width: min(width, MP.S.x10 * 5),
                      height: min(pageHeight * fraction, contentHeight * 0.45))
    }
}
