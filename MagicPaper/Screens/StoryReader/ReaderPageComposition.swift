import Foundation

enum ReaderPageComposition: Equatable {
    case scene, spot, text
}

/// Metne ayrılan alan önce gelir. Kararlar kâğıttan ve gerçek görünüm
/// ölçülerinden çıkar; ekran veya çocuğun adı üzerinden tahmin yapılmaz.
enum ReaderPageLayout {
    static func sceneHeight(width: CGFloat, height: CGFloat, readPoints: CGFloat, accessibility: Bool) -> CGFloat {
        let fraction: CGFloat
        if accessibility { fraction = 0.20 }
        else if width > height { fraction = 0.26 }
        else if readPoints >= 26 { fraction = 0.34 }
        else { fraction = 0.40 }
        return max(0, min(width * 0.75, height * fraction))
    }

    static func spotSize(width: CGFloat, height: CGFloat, accessibility: Bool) -> CGSize {
        guard !accessibility, height >= MP.S.x10 * 3 else { return .zero }
        return CGSize(width: min(max(0, width), MP.S.x10 * 3),
                      height: min(MP.S.x10 * 2, height * 0.25))
    }
}
