import UIKit

/// `.sheet(item:)` `Identifiable` istediği için üretilen PDF bu tiple taşınır.
struct MPExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

/// Masal → PDF motoru.
/// Tasarımda "Yazdır veya PDF indir" tanımlıydı ama prototipte yalnızca toast
/// gösteriliyordu; bu tip gerçek, paylaşılabilir bir kitap üretir.
enum MPStoryPDF {

    /// A5 dikey (kitap oranı), 72 dpi punto biriminde.
    private static let pageSize = CGSize(width: 420, height: 595)
    private static let margin: CGFloat = 40

    private static func displayFont(_ size: CGFloat, weight: UIFont.Weight = .bold) -> UIFont {
        UIFont(name: "Baloo2-Bold", size: size) ?? .systemFont(ofSize: size, weight: weight)
    }

    private static func bodyFont(_ size: CGFloat) -> UIFont {
        UIFont(name: "Nunito-SemiBold", size: size) ?? .systemFont(ofSize: size, weight: .medium)
    }

    private static let ink = UIColor(red: 0x2B / 255, green: 0x1D / 255, blue: 0x24 / 255, alpha: 1)
    private static let muted = UIColor(red: 0x6E / 255, green: 0x59 / 255, blue: 0x64 / 255, alpha: 1)
    private static let paper = UIColor(red: 0xFD / 255, green: 0xF6 / 255, blue: 0xEE / 255, alpha: 1)

    /// Tek masalı PDF'e basar ve geçici dosya URL'si döndürür.
    static func makePDF(for story: Story) -> URL? {
        makePDF(stories: [story], fileName: fileName(for: story.title))
    }

    /// Birden çok masalı tek kitapta toplar (ebeveyn panelindeki dışa aktarma).
    static func makePDF(stories: [Story], fileName: String) -> URL? {
        guard !stories.isEmpty else { return nil }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try renderer.writePDF(to: url) { context in
                for story in stories {
                    drawCover(story, context: context)
                    for (index, page) in story.pages.enumerated() {
                        drawPage(page, number: index + 1, total: story.pages.count, context: context)
                    }
                }
            }
            return url
        } catch {
            print("❌ PDF yazılamadı: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Sayfa çizimi

    private static func drawCover(_ story: Story, context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        paper.setFill()
        context.cgContext.fill(CGRect(origin: .zero, size: pageSize))

        let width = pageSize.width - margin * 2
        var y: CGFloat = 120

        y += draw(story.title, font: displayFont(30), color: ink,
                  in: CGRect(x: margin, y: y, width: width, height: 200), alignment: .center) + 16

        if !story.childName.isEmpty {
            y += draw("\(story.childName) için", font: bodyFont(15), color: muted,
                      in: CGRect(x: margin, y: y, width: width, height: 40), alignment: .center) + 8
        }

        _ = draw("\(story.pages.count) sayfa", font: bodyFont(13), color: muted,
                 in: CGRect(x: margin, y: y, width: width, height: 30), alignment: .center)

        _ = draw("MagicPaper", font: displayFont(13), color: muted,
                 in: CGRect(x: margin, y: pageSize.height - margin - 20,
                            width: width, height: 20), alignment: .center)
    }

    private static func drawPage(_ page: StoryPage, number: Int, total: Int,
                                 context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        UIColor.white.setFill()
        context.cgContext.fill(CGRect(origin: .zero, size: pageSize))

        let width = pageSize.width - margin * 2
        var y = margin

        // Sayfanın çizimi varsa üstte, kırpılmadan.
        if let file = page.imageUrl ?? page.imageFileName,
           let image = FileManagerService.shared.loadImage(fileName: file) {
            let side = min(width, 240)
            let rect = CGRect(x: (pageSize.width - side) / 2, y: y, width: side, height: side)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 18)
            context.cgContext.saveGState()
            path.addClip()
            image.draw(in: rect)
            context.cgContext.restoreGState()
            y += side + 22
        }

        if !page.title.isEmpty {
            y += draw(page.title, font: displayFont(17), color: ink,
                      in: CGRect(x: margin, y: y, width: width, height: 60), alignment: .left) + 10
        }

        let remaining = pageSize.height - y - margin - 24
        _ = draw(page.text, font: bodyFont(12.5), color: ink,
                 in: CGRect(x: margin, y: y, width: width, height: max(remaining, 40)),
                 alignment: .left, lineSpacing: 5)

        _ = draw("\(number) / \(total)", font: bodyFont(10), color: muted,
                 in: CGRect(x: margin, y: pageSize.height - margin, width: width, height: 16),
                 alignment: .center)
    }

    /// Metni verilen kutuya çizer, kapladığı yüksekliği döndürür.
    @discardableResult
    private static func draw(_ text: String, font: UIFont, color: UIColor,
                             in rect: CGRect, alignment: NSTextAlignment,
                             lineSpacing: CGFloat = 2) -> CGFloat {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineSpacing = lineSpacing
        paragraph.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: color, .paragraphStyle: paragraph
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let bounding = attributed.boundingRect(
            with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)

        attributed.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return min(ceil(bounding.height), rect.height)
    }

    /// Dosya adı — Türkçe karakterler ve boşluklar temizlenir.
    private static func fileName(for title: String) -> String {
        let base = title.folding(options: .diacriticInsensitive, locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        return (base.isEmpty ? "masal" : base) + ".pdf"
    }
}
