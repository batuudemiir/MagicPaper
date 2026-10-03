import XCTest
import UIKit

/// Test yardımcısı: bir `UIImage`'ın piksellerini RGBA olarak okur. Avatar ve
/// sahne çizim testleri kullanır.
struct TestBitmap {
    let width: Int, height: Int
    let data: [UInt8]   // RGBA, önceden çarpılmış

    init(_ image: UIImage) throws {
        let cg = try XCTUnwrap(image.cgImage)
        width = cg.width; height = cg.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let ctx = try XCTUnwrap(CGContext(
            data: &buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        data = buffer
    }

    /// (x, y) sol üstten.
    func pixel(_ x: Int, _ y: Int) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        let i = (y * width + x) * 4
        return (data[i], data[i + 1], data[i + 2], data[i + 3])
    }

    func opaque(_ x: Int, _ y: Int) -> Bool { pixel(x, y).a > 128 }

    /// Kaba siluet: `cols × rows` ızgarada dolu hücreler.
    func silhouette(cols: Int = 32, rows: Int = 48) -> [Bool] {
        (0..<rows).flatMap { r in
            (0..<cols).map { c in
                opaque(min(c * width / cols + width / cols / 2, width - 1),
                       min(r * height / rows + height / rows / 2, height - 1))
            }
        }
    }
}
