import Foundation
import FirebaseStorage

/// Ailenin ses kayıtları Firebase Storage'da (FAZ 18):
/// `families/{fid}/voice/{storyID}/{page}.m4a`. Yalnızca ailenin üyeleri okur;
/// kaydeden ebeveynler yazar (`firebase/storage.rules`). İndirme URL'si
/// (kalıcı belirteç) hiç üretilmez: her okuma kurallardan geçer.
struct FirebaseVoiceRemote: VoiceRemote {
    private var storage: Storage { Storage.storage() }

    func upload(file: URL, to path: String) async throws {
        let metadata = StorageMetadata()
        metadata.contentType = "audio/mp4"
        _ = try await storage.reference(withPath: path).putFileAsync(from: file, metadata: metadata)
    }

    func download(path: String, to file: URL) async throws {
        _ = try await storage.reference(withPath: path).writeAsync(toFile: file)
    }

    func delete(path: String) async throws {
        try await storage.reference(withPath: path).delete()
    }
}
