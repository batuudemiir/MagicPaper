import UIKit
import SwiftUI

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
        UIFont(name: "Nunito-Black", size: size) ?? .systemFont(ofSize: size, weight: weight)
    }

    private static func bodyFont(_ size: CGFloat) -> UIFont {
        UIFont(name: "Nunito-SemiBold", size: size) ?? .systemFont(ofSize: size, weight: .medium)
    }

    private static let ink = UIColor(MPColor.textPrimary)
    private static let muted = UIColor(MPColor.textSecondary)
    private static let paper = UIColor(MPColor.readerDayBackground)

    /// Tek masalı PDF'e basar ve geçici dosya URL'si döndürür.
    static func makePDF(for story: Story) async -> URL? {
        await makePDF(stories: [story], fileName: fileName(for: story.title))
    }

    /// Birden çok masalı tek kitapta toplar (ebeveyn panelindeki dışa aktarma).
    ///
    /// Görselli kitabın sahneleri (B2) önce ana iş parçacığında görüntüye
    /// çevrilir — `ImageRenderer` bunu ister — sonra çizim burada, arka planda
    /// sürer.
    static func makePDF(stories: [Story], fileName: String) async -> URL? {
        guard !stories.isEmpty else { return nil }
        let scenes = await MainActor.run { sceneImages(for: stories) }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try renderer.writePDF(to: url) { context in
                for story in stories {
                    drawCover(story, context: context)
                    for (index, page) in story.pages.enumerated() {
                        drawPage(page, number: index + 1, total: story.pages.count,
                                 scene: scenes[page.id], context: context)
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

    /// Sahne genişliği, punto. Sayfa metin sütunuyla aynı.
    private static let sceneWidth: CGFloat = 420 - 40 * 2

    /// Sayfa kimliği → sahnenin görüntüsü. 300 dpi'ye yakın basılsın diye 4×.
    @MainActor
    private static func sceneImages(for stories: [Story]) -> [UUID: UIImage] {
        var images: [UUID: UIImage] = [:]
        for story in stories {
            for page in story.pages {
                guard let scene = ResolvedScene.resolve(page.scene, illustration: story.illustration),
                      let image = StorySceneView.renderImage(scene, width: sceneWidth, scale: 4) else { continue }
                images[page.id] = image
            }
        }
        return images
    }

    private static func drawPage(_ page: StoryPage, number: Int, total: Int, scene: UIImage? = nil,
                                 context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        UIColor.white.setFill()
        context.cgContext.fill(CGRect(origin: .zero, size: pageSize))

        let width = pageSize.width - margin * 2
        var y = margin

        // Görselli kitabın hazır sahnesi: sütun genişliğinde, 4:3.
        if let scene {
            let rect = CGRect(x: margin, y: y, width: width, height: width * 3 / 4)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 12)
            context.cgContext.saveGState()
            path.addClip()
            scene.draw(in: rect)
            context.cgContext.restoreGState()
            y += rect.height + 22
        } else if let file = page.imageUrl ?? page.imageFileName,
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
