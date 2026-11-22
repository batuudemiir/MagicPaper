import CoreImage
import UIKit

/// Saç boyası (`kahraman.js` filtresi, 22 Kasım 2026): boyalı saç PNG'si önce
/// gri tonlanır (SVG `saturate 0`), sonra açıklığı dört duraklı renk tablosuyla
/// boyanır (SVG `feComponentTransfer table`). İkisi sRGB'de, filtredeki gibi.
/// Kestane rengi çizimin kendisidir, boyanmaz. Sonuç önbellekte: dolabın
/// küçük resimleri aynı saçı tekrar tekrar çizer.
enum HeroHairDye {
    private static let cache = NSCache<NSString, UIImage>()
    private static let context = CIContext(options: [.cacheIntermediates: false])
    private static let dimension = 32

    static func image(hair id: String, colors: [HeroRGB]) -> UIImage? {
        let key = ([id] + colors.map { "\(Int($0.r)),\(Int($0.g)),\(Int($0.b))" }).joined(separator: "|") as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard colors.count == 4,
              let source = UIImage(named: "HeroFigure/\(id)"),
              let input = CIImage(image: source),
              let filter = CIFilter(name: "CIColorCubeWithColorSpace"),
              let srgb = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        filter.setValue(input.unpremultiplyingAlpha(), forKey: kCIInputImageKey)
        filter.setValue(dimension, forKey: "inputCubeDimension")
        filter.setValue(cube(colors), forKey: "inputCubeData")
        filter.setValue(srgb, forKey: "inputColorSpace")
        guard let output = filter.outputImage?.premultiplyingAlpha(),
              let cg = context.createCGImage(output, from: input.extent) else { return nil }
        let image = UIImage(cgImage: cg, scale: source.scale, orientation: source.imageOrientation)
        cache.setObject(image, forKey: key)
        return image
    }

    /// Renk küpü: her (r, g, b) için açıklık L = 0.213 r + 0.715 g + 0.072 b,
    /// sonra L tabloda üç parçalı doğrusal aradeğerle boyanır. Alfa küpte 1;
    /// asıl alfa görüntüde korunur (önce çözülür, sonra yeniden çarpılır).
    static func cube(_ colors: [HeroRGB]) -> Data {
        let n = dimension
        var values = [Float](repeating: 0, count: n * n * n * 4)
        let table = colors.map { [Float($0.r / 255), Float($0.g / 255), Float($0.b / 255)] }
        var offset = 0
        for b in 0..<n {
            for g in 0..<n {
                for r in 0..<n {
                    let lum = 0.213 * Float(r) / Float(n - 1) + 0.715 * Float(g) / Float(n - 1) + 0.072 * Float(b) / Float(n - 1)
                    let l = min(max(lum, 0), 1)
                    let k = min(Int(l * 3), 2)
                    let t = l * 3 - Float(k)
                    for channel in 0..<3 {
                        values[offset + channel] = table[k][channel] + t * (table[k + 1][channel] - table[k][channel])
                    }
                    values[offset + 3] = 1
                    offset += 4
                }
            }
        }
        return values.withUnsafeBufferPointer { Data(buffer: $0) }
    }
}
