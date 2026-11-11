import UIKit

/// Baskıya hazır PDF'in ölçüleri (Faz 12, basılı kitap pilotu).
///
/// Kesim boyu A5 (`MPStoryPDF.pageSize`); çevresinde 3 mm taşma payı, onun da
/// dışında kesim işaretlerinin durduğu boşluk. Kâğıt rengi taşma payının
/// sonuna kadar serilir, yazı ve sahne kesim kutusunun içinde kalır. PDF her
/// sayfada TrimBox ve BleedBox taşır; matbaa yazılımı kesimi oradan okur.
///
/// Renk RGB'dir: UIKit CMYK PDF yazamaz. CMYK'ya dönüşüm basım ortağının
/// ICC profiliyle onların tarafında yapılır (`docs/YAYINEVI.md`).
struct MPPrintSpec: Equatable {
    /// 3 mm, punto cinsinden.
    var bleed: CGFloat = 3 * 72 / 25.4
    /// Kesim işaretlerinin taşma payının dışında kapladığı alan.
    var slug: CGFloat = 18
    /// Kesim işaretinin uzunluğu.
    var markLength: CGFloat = 12

    static let a5 = MPPrintSpec()

    /// Çizimin kesim kutusuna kayması.
    var offset: CGFloat { bleed + slug }

    func mediaBox(trim: CGSize) -> CGRect {
        CGRect(x: 0, y: 0, width: trim.width + offset * 2, height: trim.height + offset * 2)
    }

    func trimBox(trim: CGSize) -> CGRect {
        CGRect(x: offset, y: offset, width: trim.width, height: trim.height)
    }

    /// Çizim kesim kutusuna kaydırılmadan önceki koordinatlarda.
    func bleedBox(trim: CGSize) -> CGRect {
        trimBox(trim: trim).insetBy(dx: -bleed, dy: -bleed)
    }

    /// `UIGraphicsPDFRendererContext.beginPage(withBounds:pageInfo:)` için.
    func pageInfo(trim: CGSize) -> [String: Any] {
        func box(_ rect: CGRect) -> Data {
            var value = rect
            return Data(bytes: &value, count: MemoryLayout<CGRect>.size)
        }
        return [
            kCGPDFContextTrimBox as String: box(trimBox(trim: trim)),
            kCGPDFContextBleedBox as String: box(bleedBox(trim: trim))
        ]
    }

    /// Dört köşede ikişer çizgi; taşma payının dışında, kesim çizgisi
    /// hizasında. Siyah değil kitabın mürekkep rengi (`MPColor.textPrimary`).
    func drawCropMarks(in context: CGContext, trim: CGSize) {
        let box = trimBox(trim: trim)
        context.saveGState()
        context.setStrokeColor(UIColor(MPColor.textPrimary).cgColor)
        context.setLineWidth(0.25)
        let gap = bleed + 2
        for x in [box.minX, box.maxX] {
            for y in [box.minY, box.maxY] {
                let outX: CGFloat = x == box.minX ? -1 : 1
                let outY: CGFloat = y == box.minY ? -1 : 1
                // Yatay işaret
                context.move(to: CGPoint(x: x + outX * gap, y: y))
                context.addLine(to: CGPoint(x: x + outX * (gap + markLength), y: y))
                // Dikey işaret
                context.move(to: CGPoint(x: x, y: y + outY * gap))
                context.addLine(to: CGPoint(x: x, y: y + outY * (gap + markLength)))
            }
        }
        context.strokePath()
        context.restoreGState()
    }
}
