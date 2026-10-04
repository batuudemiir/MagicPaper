import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "FamilyCharacterStore")

/// Masal ailem, çocuk başına, yalnızca cihazda (FAZ 11).
///
/// `Documents/StoryEngine/FamilyCharacters/<çocukUUID>.json`: çocuk başına bir
/// dosya, içinde o çocuğun listesi. `AvatarStore` ile aynı klasör kökü, atomik
/// yazma ve dosya koruması; farkı eşzamanlı olması — liste ekranda doğrudan
/// okunur ve yazılır.
///
/// Okuma kayıplıdır: daha yeni bir sürümün yazdığı (bilinmeyen ilişki türlü)
/// tek bir kayıt dosyanın geri kalanını götürmez. Log'a yalnızca sayı ve olay
/// yazılır; ad, çocuk kimliği ya da dosya yolu hiçbir zaman.
///
/// FAZ 16 bu dosyayı hesapla eşleyecek; kimlik ve `createdAt` bunun için sabit.
struct FamilyCharacterStore: Sendable {
    static let defaultSubdirectory = "FamilyCharacters"

    enum Failure: Error, Equatable {
        case limitReached
        case documentsUnavailable
        case writeFailed
    }

    private let subdirectory: String

    init(subdirectory: String = FamilyCharacterStore.defaultSubdirectory) {
        self.subdirectory = subdirectory
    }

    private struct File: Codable {
        var schemaVersion: Int = 1
        var characters: [Lossy]

        /// Bir kayıt; çözülemezse `nil`, dosya düşmez.
        struct Lossy: Codable {
            let value: FamilyCharacter?
            init(_ value: FamilyCharacter) { self.value = value }
            init(from decoder: Decoder) throws {
                value = try? FamilyCharacter(from: decoder)
            }
            func encode(to encoder: Encoder) throws {
                try value?.encode(to: encoder)
            }
        }
    }

    private func url(for childID: UUID) -> URL? {
        StoryEngineStorage.directory(subdirectory)?
            .appendingPathComponent("\(childID.uuidString).json")
    }

    /// Çocuğun karakterleri, eklenme sırasıyla.
    func characters(for childID: UUID) -> [FamilyCharacter] {
        guard let url = url(for: childID), FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        do {
            let file = try StoryEngineStorage.makeDecoder()
                .decode(File.self, from: Data(contentsOf: url))
            let values = file.characters.compactMap(\.value)
            let skipped = file.characters.count - values.count
            if skipped > 0 {
                logger.notice("Masal ailem: \(skipped, privacy: .private) kayıt okunamadı, atlandı")
            }
            return values
                .filter { $0.childID == childID }
                .sorted { $0.createdAt < $1.createdAt }
        } catch {
            logger.error("🛑 Masal ailem dosyası okunamadı")
            return []
        }
    }

    /// Ekler ya da aynı kimlikli kaydı değiştirir.
    func save(_ character: FamilyCharacter) throws {
        var list = characters(for: character.childID)
        if let index = list.firstIndex(where: { $0.id == character.id }) {
            list[index] = character
        } else {
            guard list.count < FamilyCharacter.maxPerChild else { throw Failure.limitReached }
            list.append(character)
        }
        try write(list, for: character.childID)
    }

    func delete(id: UUID, childID: UUID) throws {
        let list = characters(for: childID).filter { $0.id != id }
        try write(list, for: childID)
    }

    /// Profil silinirken: o çocuğun bütün karakterleri.
    func delete(for childID: UUID) {
        guard let url = url(for: childID) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// "Tüm verileri sil" için: klasörün tamamı.
    func eraseAll() {
        guard let url = StoryEngineStorage.directory(subdirectory) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    static func eraseAll(subdirectory: String = FamilyCharacterStore.defaultSubdirectory) {
        FamilyCharacterStore(subdirectory: subdirectory).eraseAll()
    }

    private func write(_ list: [FamilyCharacter], for childID: UUID) throws {
        guard let url = url(for: childID) else { throw Failure.documentsUnavailable }
        do {
            let data = try StoryEngineStorage.makeEncoder()
                .encode(File(characters: list.map(File.Lossy.init)))
            try StoryEngineStorage.write(data, to: url)
        } catch {
            logger.error("🛑 Masal ailem kaydedilemedi")
            throw Failure.writeFailed
        }
    }
}
