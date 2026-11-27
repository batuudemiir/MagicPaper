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

    /// Üst kontrollerin (kapat, kalp, Aa) kapladığı yer ve altındaki nefes;
    /// metin bunun altından başlar. Güvenli alan bunun dışında.
    /// 26 Kasım 2026: 56 + 24 yerine kontrolün gerçek ölçüsü, metne yer kalsın.
    static let topChromeClearance: CGFloat = MPSpacing.xxs + MP.S.tapMin + MP.S.x4

    /// Alt kontrol çubuğu, iç boşluğuyla; güvenli alan taşıyıcıya ait.
    /// Olağan yazıda tek satır (geri · sayfa · ses · ileri; 26 Kasım 2026,
    /// kompakt okuyucu). En büyük yazı boyutlarında sayfa ve ses satırı ayrı kalır.
    static func bottomChromeClearance(accessibility: Bool, compactHeight: Bool = false) -> CGFloat {
        guard accessibility else { return MPSize.minTouchHero + MP.S.x2 * 2 }
        let upperRow = compactHeight ? MPSize.minTouchHero : MP.S.tapMin * 3
        return upperRow + MPSize.minTouchHero + MP.S.x2 * 2 + MP.S.x1
    }

    /// Yaprağın güvenli alanı okuyucununkinden kısa kalırsa (sayfa
    /// denetleyicisi yaprağa iletmezse) eksik kalan kadar. Uzun metin böylece
    /// sol üstteki kapat düğmesinin altına akmaz.
    static func missingTopInset(readerSafeTop: CGFloat, pageTop: CGFloat) -> CGFloat {
        max(0, readerSafeTop - max(pageTop, 0))
    }

    static func spotSize(width: CGFloat, height: CGFloat, accessibility: Bool) -> CGSize {
        spotHeaderSize(width: width, pageHeight: height, contentHeight: height,
                       accessibility: accessibility)
    }

    /// A scrollable page keeps the normal art footprint even when chrome or large text needs more room.
    static func scrollingSpotSize(width: CGFloat, pageHeight: CGFloat) -> CGSize {
        let nominalContent = pageHeight - topChromeClearance
            - bottomChromeClearance(accessibility: false)
        return spotHeaderSize(width: width, pageHeight: pageHeight,
                              contentHeight: max(nominalContent, MP.S.x10 * 5), accessibility: false)
    }

    static func spotNarrativeMinimumHeight(viewportHeight: CGFloat, artHeight: CGFloat) -> CGFloat {
        max(0, viewportHeight - artHeight - MP.S.x6)
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
