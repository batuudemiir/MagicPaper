import Foundation

/// Bir Masal ailem karakteri kaç masalda göründü (FAZ 11).
///
/// Masalın kaydı (`StoryOrigin.familyCharacterID`) üzerinden sayar; adla değil.
/// Karakter yeniden adlandırılsa da sayaç doğru kalır. Okunamayan taslaklar
/// sayılmaz: çocuğun açıp okuyamadığı bir kitap "masalda göründü" sayılmaz.
enum FamilyCharacterAppearances {
    static func count(of characterID: UUID, in stories: [Story]) -> Int {
        let id = characterID.uuidString
        return stories.filter { $0.origin?.familyCharacterID == id && $0.isReadable }.count
    }
}
