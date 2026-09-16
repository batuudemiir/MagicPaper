import UIKit

/// Sayfa çizimlerini yükler.
///
/// Eski okuyucu `FileManagerService.shared.loadImage`'ı doğrudan `body`'nin
/// içinden çağırıyordu: her gövde yeniden değerlendirmesinde ana iş parçacığında
/// senkron disk okuması ve tam çözünürlüklü kod çözme — üstelik 170×170 puntoya
/// çizmek için. Ve gövde her sayfa çevirmede yeniden değerlendiriliyordu, çünkü
/// ilerleme kaydı `StoryGenerationManager.stories`'i yayımlıyor.
///
/// Parmağı takip eden bir kıvrımda bu, projedeki en büyük performans riskiydi.
/// Burada üç şey değişir: kod çözme ana iş parçacığının dışına çıkar, sonuç
/// saklanır, ve görüntü çizileceği boyuta indirgenir.
actor ReaderImageLoader {

    static let shared = ReaderImageLoader()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        // Bir masalda aynı anda en çok üç yaprak canlıdır; sınır cömert.
        cache.countLimit = 12
    }

    /// `fileName` için görüntü. Bulunamazsa `nil` — çağıran yer kâğıdı gösterir.
    func image(named fileName: String, targetPixelWidth: CGFloat) -> UIImage? {
        let key = "\(fileName)@\(Int(targetPixelWidth))" as NSString
        if let hit = cache.object(forKey: key) { return hit }

        guard let directory = FileManagerService.shared.getStoriesDirectoryURL() else {
            return nil
        }
        let url = directory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let downsampled = ReaderImageLoader.downsample(url, to: targetPixelWidth) else {
            return nil
        }

        cache.setObject(downsampled, forKey: key)
        return downsampled
    }

    /// Tam çözünürlüklü bir kareyi belleğe açmadan, çizileceği boyutta üretir.
    private static func downsample(_ url: URL, to pixelWidth: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
            return nil
        }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(pixelWidth, 1)
        ] as CFDictionary

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            return nil
        }
        return UIImage(cgImage: thumbnail).preparingForDisplay() ?? UIImage(cgImage: thumbnail)
    }
}
