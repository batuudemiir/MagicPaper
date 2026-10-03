import Foundation
import OSLog
import UIKit

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "CloudIllustrationPipeline")

enum CloudIllustrationError: Error, Equatable {
    /// `CloudIllustrationAccess` kapalı: bulut yoluna hiçbir şey gönderilmez.
    case disabled
}

/// Görsel bulut yolunun yardımcıları: çocuk fotoğrafını geçici yükleme,
/// sayfaları fal.ai ile çizme, sonucu diske indirme.
///
/// Hiçbir yönetici durumuna dokunmaz; sonuçları döndürür, çağıran uygular.
/// Her giriş noktası önce `CloudIllustrationAccess`'e bakar. Günlüklere
/// çocuk adı, istem metni, URL ya da masal metni yazılmaz.
enum CloudIllustrationPipeline {

    /// Bir sayfanın indirilmiş çizimi.
    struct PageImage: Equatable {
        let pageID: UUID
        let fileName: String
    }

    // MARK: - Child photo

    /// Fotoğraf yalnızca sayfalar çizilirken Storage'da durur.
    static func uploadChildPhoto(
        _ image: UIImage,
        defaults: UserDefaults = .standard
    ) async throws -> String {
        try requireAccess(defaults)
        return try await FirebaseImageUploader.shared.uploadImageToFirebase(image: image)
    }

    /// Silme bilerek bayrağa bağlı değil: bayrak yükleme sonrası kapansa bile
    /// yüklenmiş çocuk fotoğrafı silinebilmeli.
    static func deleteChildPhoto(at downloadURL: String) async {
        await FirebaseImageUploader.shared.deleteUploadedImage(at: downloadURL)
    }

    // MARK: - Illustration

    /// Sayfaları sırayla çizer ve diske indirir. Her tamamlanan sayfa için
    /// `onPage` çağrılır (çağıran ilerlemeyi kaydedebilsin); tümü dönüşte de
    /// verilir. Tek sayfanın başarısızlığı diğerlerini durdurmaz.
    @MainActor
    static func generateImages(
        for pages: [StoryPage],
        referencePhotoUrl: String,
        theme: StoryTheme,
        defaults: UserDefaults = .standard,
        onPage: (PageImage) -> Void
    ) async throws -> [PageImage] {
        try requireAccess(defaults)

        // Aynı seed = sayfalar arasında aynı karakter görünümü.
        let seed = Int.random(in: 1000...999999)
        var results: [PageImage] = []

        for page in pages {
            if let result = await drawPage(page, referencePhotoUrl: referencePhotoUrl, theme: theme, seed: seed) {
                results.append(result)
                onPage(result)
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        return results
    }

    // MARK: - Private

    private static func requireAccess(_ defaults: UserDefaults) throws {
        guard CloudIllustrationAccess.isEnabled(defaults: defaults) else {
            throw CloudIllustrationError.disabled
        }
    }

    private static func drawPage(
        _ page: StoryPage,
        referencePhotoUrl: String,
        theme: StoryTheme,
        seed: Int
    ) async -> PageImage? {
        do {
            let remoteUrl = try await FalAIImageGenerator.shared.generateImage(
                prompt: page.imagePrompt.isEmpty ? page.text : page.imagePrompt,
                referenceImageUrl: referencePhotoUrl,
                style: theme.rawValue,
                seed: seed
            )
            guard let fileName = await downloadAndSaveImage(from: remoteUrl, pageId: page.id) else { return nil }
            return PageImage(pageID: page.id, fileName: fileName)
        } catch {
            logger.error("Sayfa çizimi başarısız, sonraki sayfaya geçiliyor: \((error as NSError).code)")
            return nil
        }
    }

    private static func downloadAndSaveImage(from urlString: String, pageId: UUID) async -> String? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                logger.error("Çizim indirilemedi: HTTP \(http.statusCode)")
                return nil
            }
            return FileManagerService.shared.saveImage(data: data, fileName: "\(pageId.uuidString).jpg")
        } catch {
            logger.error("Çizim indirme hatası: \((error as NSError).code)")
            return nil
        }
    }
}
