import Foundation
import StoryEngine

/// Masal ailem ekran metinlerinin tek kaynağı (FAZ 11).
///
/// Metinler geçici: İrem gözden geçirecek. Görünümler metni burada okur,
/// satır içine yazmaz; değişiklik yalnızca bu dosyada olur. Proje
/// `Localizable` kullanmıyor; kullanmaya başladığında anahtarlar buradan
/// taşınır.
enum FamilyCharacterCopy {

    // MARK: - Masal ailem sayfası

    static let screenTitle = "Masal ailem"
    static let profileRowTitle = "Masal ailem"
    static let profileRowSymbol = "person.2.fill"
    static let profileRowDescription = "Masallarda görünen kardeşler, arkadaşlar, dostlar"
    static let emptyTitle = "Masal ailesi henüz boş"
    static let emptyDescription = "Kardeşini, arkadaşını, evcil hayvanını ya da hayali arkadaşını ekle; masallarda onunla birlikte görünsün."
    static let addButton = "Yeni karakter"
    static let limitReached = "Bir çocuk için en fazla \(FamilyCharacter.maxPerChild) karakter eklenebilir."

    static func appearances(_ count: Int) -> String {
        count == 0 ? "Henüz bir masalda görünmedi" : "\(count) masalda"
    }

    static func rowAccessibility(name: String, relation: String, count: Int) -> String {
        "\(name), \(relation), \(appearances(count))"
    }

    // MARK: - Düzenleyici

    static let newTitle = "Yeni karakter"
    static let editTitle = "Karakteri düzenle"
    static let nameLabel = "Adı ne?"
    static let nameHint = "Masalda bu adla geçecek"
    static let namePlaceholder = "Örn. Ela"
    static let relationLabel = "Çocuğun nesi?"
    static let animalKindLabel = "Hangi hayvan?"
    static let save = "Kaydet"
    static let saveIncompleteHint = "Ad ve ilişki türü seçilince kaydedilir"
    static let remove = "Masal ailesinden çıkar"
    static let removeConfirmTitle = "Karakteri çıkar"
    static let removeConfirmButton = "Çıkar"
    static let cancel = "Vazgeç"
    static let saved = "Masal ailesine eklendi"
    static let updated = "Karakter güncellendi"
    static let removed = "Masal ailesinden çıkarıldı"
    static let saveFailed = "Kaydedilemedi, tekrar dener misin?"

    static func removeConfirmMessage(name: String) -> String {
        "\(name) masal ailesinden çıkarılacak. Yazılmış masallar olduğu gibi kalır."
    }

    static func rejection(_ rejection: FamilyNameValidator.Rejection) -> String {
        switch rejection {
        case .empty: return "Bir ad yazalım."
        case .tooShort: return "Ad en az \(FamilyNameValidator.minLength) harf olmalı."
        case .tooLong: return "Ad en fazla \(FamilyNameValidator.maxLength) harf olabilir."
        case .tooManyWords: return "En fazla \(FamilyNameValidator.maxWords) kelime yazalım."
        case .invalidCharacters: return "Yalnızca harf kullanalım; rakam, emoji ve işaret olmasın."
        case .noVowel: return "Bu ad masalda okunamaz; bir ünlü harf eksik."
        case .sameAsChild: return "Bu çocuğun kendi adı; başka bir ad seçelim."
        case .duplicate: return "Bu adla bir karakter zaten var."
        }
    }

    // MARK: - İlişki türleri

    static func relation(_ kind: FamilyRelationKind) -> String {
        switch kind {
        case .sibling: return "Kardeş"
        case .friend: return "Arkadaş"
        case .animal: return "Evcil hayvan"
        case .imaginary: return "Hayali arkadaş"
        }
    }

    static func relationSymbol(_ kind: FamilyRelationKind) -> String {
        switch kind {
        case .sibling: return "person.2.fill"
        case .friend: return "hand.wave.fill"
        case .animal: return "pawprint.fill"
        case .imaginary: return "sparkles"
        }
    }

    /// "Kardeş", ya da hayvansa türü: "Köpek".
    static func relationLine(_ relation: FamilyRelation, kinds: [FamilyAnimalKindChoice]) -> String {
        if let kindID = relation.animalKindID, let kind = kinds.first(where: { $0.id == kindID }) {
            return kind.name.capitalized(with: Locale(identifier: "tr_TR"))
        }
        return self.relation(relation.kind)
    }

    // MARK: - "Masalda kimler olsun?"

    static let stepFamilyQuestion = "Masal ailemden biri de gelsin mi?"
    static let stepFamilyHint = "İsteğe bağlı. Seçtiğin karakter masalın başında ve sonunda görünür."
    static let stepUnavailable = "Soluk olanlar bu masal türünde henüz yer alamıyor."
    static let stepUnavailableAccessibility = "Bu masal türünde henüz yer alamıyor"
    static let stepCompanionLabel = "Yol arkadaşı"
}
